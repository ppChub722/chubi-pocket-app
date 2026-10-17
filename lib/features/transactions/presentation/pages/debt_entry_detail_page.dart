import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../home/presentation/cubit/dashboard_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../save_failure.dart';
import '../widgets/account_picker_sheet.dart';
import '../widgets/debt_entry_form.dart';
import '../widgets/draft_form.dart';
import '../widgets/pick_chip_rows.dart';

/// The transaction detail page in DEBT MODE (owner 2026-10-12: a debt entry's
/// detail IS the tx detail page, opened from the debts side or from a tx row
/// that is an entry's wallet side). The same template and hero: Paid /
/// Received in place of the type, the PERSON card in place of the category,
/// the wallet card may be "ไม่ผูก" (ledger only), tags only with a wallet.
///
/// One call on open (GET /personal-debts/{id}: the entry, the person's
/// balance and the linked transaction); one on บันทึก (PUT) and one on ลบ
/// (DELETE, which takes the wallet transaction with it — the confirm names
/// both). Everything shown elsewhere is patched from the answers.
class DebtEntryDetailPage extends StatefulWidget {
  const DebtEntryDetailPage({required this.entryId, super.key});

  final String entryId;

  @override
  State<DebtEntryDetailPage> createState() => _DebtEntryDetailPageState();
}

class _DebtEntryDetailPageState extends State<DebtEntryDetailPage> {
  DebtEntryDetail? _detail;
  ApiException? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await context.read<PersonalDebtsRepository>().getEntry(
        widget.entryId,
      );
      if (mounted) setState(() => _detail = d);
    } catch (e, st) {
      if (mounted) setState(() => _error = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = _detail;
    if (d != null) {
      return _DebtEntryView(
        detail: d,
        onChanged: (next) => setState(() => _detail = next),
        onRefresh: _load,
      );
    }
    final missing = _error?.statusCode == 404;
    return Scaffold(
      appBar: AppTopBar(title: l.debtEntryTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: AsyncStateView.fallback(
        loading: _loading,
        error: missing ? null : _error,
        onRetry: _load,
        notFound: EmptyView(
          icon: AppIcons.empty,
          title: l.debtEntryNotFound,
          message: '',
        ),
      ),
    );
  }
}

/// What the page edits (Equatable: dirty check + undo).
class _DebtDraft extends Equatable {
  const _DebtDraft({
    required this.direction,
    required this.amount,
    required this.description,
    required this.note,
    required this.date,
    required this.accountId,
    required this.personKey,
    required this.tagIds,
    required this.paid,
    required this.createTx,
  });

  final DebtEntryDirection direction;
  final String amount;
  final String description;
  final String note;
  final String date;
  final String? accountId;
  final String personKey;
  final List<String> tagIds;
  final bool paid;

  /// Also written as a transaction ("สร้างรายการด้วย").
  final bool createTx;

  _DebtDraft copyWith({bool? paid}) => _DebtDraft(
    direction: direction,
    amount: amount,
    description: description,
    note: note,
    date: date,
    accountId: accountId,
    personKey: personKey,
    tagIds: tagIds,
    paid: paid ?? this.paid,
    createTx: createTx,
  );

  @override
  List<Object?> get props => [
    direction,
    amount,
    description,
    note,
    date,
    accountId,
    personKey,
    tagIds,
    paid,
    createTx,
  ];
}

class _DebtEntryView extends StatefulWidget {
  const _DebtEntryView({
    required this.detail,
    required this.onChanged,
    required this.onRefresh,
  });

  final DebtEntryDetail detail;
  final ValueChanged<DebtEntryDetail> onChanged;
  final Future<void> Function() onRefresh;

  @override
  State<_DebtEntryView> createState() => _DebtEntryViewState();
}

class _DebtEntryViewState extends State<_DebtEntryView>
    with EditModeMixin<_DebtEntryView, _DebtDraft> {
  final _c = DebtEntryController();
  final _heroKey = GlobalKey();
  bool _paid = false;

  /// Pushing a draft into the fields — not a user edit.
  bool _restoring = false;

  /// Every person / wallet the form has shown, by key / id (undo restores
  /// them).
  final Map<String, DebtPick> _people = {};
  final Map<String, Account> _accounts = {};

  DebtEntry get _entry => widget.detail.entry;

  /// A split-sourced entry: only description / note / paid change.
  bool get _sourced => _entry.source != null;

  @override
  void initState() {
    super.initState();
    _prefill();
    initDraft(_snap());
    _c.addListener(_onFormChanged);
  }

  @override
  void didUpdateWidget(_DebtEntryView old) {
    super.didUpdateWidget(old);
    if (old.detail != widget.detail && !isEditing) {
      _prefill();
      resetDraft(_snap());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _prefill() {
    final d = widget.detail;
    final e = d.entry;
    final tx = d.transaction;
    final key = e.key ?? d.balance.key;
    // The balance before this entry, so the result line shows the new one.
    final contribution = e.direction == DebtEntryDirection.paid
        ? e.amount
        : -e.amount;
    final pick = DebtPick(
      key: key,
      person: d.balance.person,
      net: d.balance.net - contribution,
    );
    _people[key] = pick;
    final account = tx?.account?.toAccount();
    if (account != null) _accounts[account.id] = account;
    _restoring = true;
    _c
      ..direction = e.direction
      ..amount.text = _amountText(e.amount)
      ..description.text = e.description ?? ''
      ..note.text = e.note ?? ''
      ..date = e.date ?? DateTime.now()
      ..account = account
      ..setPerson(pick)
      ..knownTags.clear()
      ..tagIds.clear();
    for (final t in tx?.tags ?? const []) {
      _c.knownTags[t.id] = t.asTag;
      _c.tagIds.add(t.id);
    }
    _paid = e.paid;
    // A transaction exists exactly when the entry has one (wallet or not).
    _c.createTransaction = tx != null;
    _restoring = false;
  }

  static String _amountText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  _DebtDraft _snap() => _DebtDraft(
    direction: _c.direction,
    amount: _c.amount.text,
    description: _c.description.text,
    note: _c.note.text,
    date: _ymd(_c.date),
    accountId: _c.account?.id,
    personKey: _c.person?.key ?? '',
    tagIds: (_c.tagIds.toList()..sort()),
    paid: _paid,
    createTx: _c.createTransaction,
  );

  @override
  void onDraftRestored() {
    final w = working;
    _restoring = true;
    _c
      ..direction = w.direction
      ..amount.text = w.amount
      ..description.text = w.description
      ..note.text = w.note
      ..date = DateTime.parse(w.date)
      ..account = w.accountId == null ? null : _accounts[w.accountId]
      ..setPerson(_people[w.personKey])
      ..setTagIds(w.tagIds.toSet());
    _paid = w.paid;
    _c.createTransaction = w.createTx;
    _restoring = false;
    setState(() {});
  }

  void _onFormChanged() {
    if (_restoring) return;
    final next = _snap();
    final w = working;
    if (next == w) return;
    final textOnly =
        next.direction == w.direction &&
        next.date == w.date &&
        next.accountId == w.accountId &&
        next.personKey == w.personKey &&
        next.paid == w.paid &&
        next.createTx == w.createTx &&
        next.tagIds.join() == w.tagIds.join();
    if (textOnly) {
      final field = next.note != w.note
          ? 'note'
          : next.description != w.description
          ? 'description'
          : 'amount';
      applyTextChange(field, next);
    } else {
      applyChange(next);
    }
  }

  // ── Pickers ───────────────────────────────────────────────────────

  Future<void> _pickPerson() async {
    final p = await showDebtPersonPicker(context, selected: _c.person);
    if (p == null || !mounted) return;
    _people[p.key] = p;
    _c.setPerson(p);
  }

  Future<void> _pickAccount() async {
    final l = AppLocalizations.of(context)!;
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selected: _c.account,
      title: l.transactionFormAccountLabel,
      allowNone: true,
    );
    if (!mounted || r == null) return;
    final a = r is AccountPickerSelected ? r.account : null;
    if (a != null) _accounts[a.id] = a;
    _c.setAccount(a);
  }

  Future<void> _pickDate() async {
    final r = await showAppDatePicker(
      context,
      initial: _c.date,
      first: DateTime(2000),
      last: DateTime.now().add(const Duration(days: 365)),
    );
    if (r is AppDatePicked) _c.setDate(r.date);
  }

  Future<void> _moreTags() async {
    final next = await showTagPickerSheet(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next);
  }

  void _setPaid(bool v) {
    setState(() => _paid = v);
    _onFormChanged();
  }

  /// Snackbars float above this page's own action bar ([pageMessenger]).
  void _say(String text, Tone tone) {
    final m = pageMessenger;
    if (m != null) showAppSnackBarOn(m, text, tone: tone);
  }

  // ── Save / delete ─────────────────────────────────────────────────

  /// ONE PUT with only what changed; the answer patches every cache.
  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    commitTextSession();
    if (_c.amountValue <= 0) {
      HapticFeedback.lightImpact();
      _say(l.quickAmountRequired, Tone.danger);
      return;
    }
    final o = original;
    final w = working;
    final pick = _people[w.personKey];
    final txChange = w.createTx != o.createTx;
    final update = DebtEntryUpdate(
      direction: w.direction != o.direction ? w.direction : null,
      amount: w.amount != o.amount ? _c.amountValue : null,
      date: w.date != o.date ? _c.date : null,
      // The transaction is the switch's (a split-sourced entry has none to
      // change); the wallet and tags only matter while it is on.
      createTransaction: _sourced ? null : w.createTx,
      accountId: w.createTx && (w.accountId != o.accountId || txChange)
          ? w.accountId
          : null,
      clearAccount:
          w.createTx &&
          !txChange &&
          o.accountId != null &&
          w.accountId == null,
      description: w.description != o.description ? w.description.trim() : null,
      note: w.note != o.note ? w.note.trim() : null,
      paid: w.paid != o.paid ? w.paid : null,
      tagIds:
          w.createTx &&
              (w.tagIds.join() != o.tagIds.join() ||
                  (txChange && w.tagIds.isNotEmpty))
          ? w.tagIds
          : null,
      key: w.personKey != o.personKey ? w.personKey : null,
      personName: w.personKey != o.personKey ? pick?.typedName : null,
    );
    final repo = context.read<PersonalDebtsRepository>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final dashboard = context.read<DashboardCubit>();
    final oldTxId = widget.detail.transaction?.id;
    setSaving(true);
    try {
      final r = await repo.updateEntry(_entry.id, update);
      accounts.patchBalances(r.accountBalances);
      final tx = r.transaction;
      if (tx != null) {
        txCubit.patchRow(tx, afterWrite: true);
      } else if (oldTxId != null) {
        // Made ledger-only: its wallet transaction is gone.
        txCubit.dropRow(oldTxId);
      }
      dashboard.markStale();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(working);
      widget.onChanged(
        DebtEntryDetail(entry: r.entry, balance: r.balance, transaction: tx),
      );
      _say(l.quickSaved, Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(context, e, retry: _save);
    }
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context)!;
    final wallet = widget.detail.transaction?.account?.name;
    final ok = await showConfirmDialog(
      context,
      title: l.debtEntryDeleteTitle,
      message: wallet != null
          ? l.debtDeleteBothMessage(wallet)
          : l.debtDeleteLedgerMessage(widget.detail.balance.person.name),
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = context.read<PersonalDebtsRepository>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final dashboard = context.read<DashboardCubit>();
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    setSaving(true);
    try {
      final r = await repo.deleteEntry(_entry.id);
      accounts.patchBalances(r.accountBalances);
      final txId = r.transactionId;
      if (txId != null) txCubit.dropRow(txId);
      dashboard.markStale();
      showAppSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
      if (router == null) {
        navigator.maybePop();
      } else if (router.canPop()) {
        router.pop();
      } else {
        back?.call();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(context, e, retry: _confirmDelete);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  String _dayLabel(AppLocalizations l, DateTime d) => DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// View: where the person stands now; edit: where they'll stand.
  Widget? _balanceLine(AppLocalizations l, String symbol) {
    final p = _c.person;
    if (p == null) return null;
    final net = isEditing ? _c.netAfter : widget.detail.balance.net;
    if (net == null) return null;
    final name = p.person.name;
    final money = moneyString(context, net.abs(), symbol: symbol);
    final result = net > 0.004
        ? '${l.debtTheyOweYou(name)} $money'
        : net < -0.004
        ? '${l.debtYouOwe(name)} $money'
        : l.debtSettledLabel;
    return AppText(
      isEditing ? l.debtResultAfter(result) : l.debtBalanceNow(result),
      role: AppTextRole.caption,
    );
  }

  /// View mode: tapping a changeable card only says how to edit.
  void _longPressHint() =>
      _say(AppLocalizations.of(context)!.commonLongPressToEdit, Tone.info);

  Widget _cards(AppLocalizations l) {
    final editable = isEditing && !_sourced;
    final p = _c.person;
    final canEditHere = !isEditing && !_sourced;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PickCard(
              label: l.debtPersonPickerTitle,
              value: p?.person.name,
              placeholder: l.debtPickPerson,
              dense: true,
              leading: p == null
                  ? const PickCardEmptyIcon(AppIcons.contact, size: 32)
                  : PersonMark(
                      name: p.person.name,
                      level: debtPersonLevel(p.person),
                      iconCode: p.person.iconCode,
                      size: 32,
                    ),
              editable: editable,
              onLongPress: canEditHere
                  ? () => enterEdit(then: _pickPerson)
                  : null,
              // View: the person's page; edit: the picker.
              onTap: editable
                  ? _pickPerson
                  : isEditing || p == null
                  ? null
                  : () => openPage(context, debtPersonPath(p.key)),
            ),
          ),
          // Ledger only: no wallet card.
          if (_c.createTransaction) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: WalletPickCard(
                account: _c.account,
                label: l.transactionFormAccountLabel,
                placeholder: l.quickPickWallet,
                dense: true,
                editable: editable,
                onLongPress: canEditHere
                    ? () => enterEdit(then: _pickAccount)
                    : null,
                onTap: editable
                    ? _pickAccount
                    : canEditHere
                    ? _longPressHint
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    final editing = isEditing;
    final e = _entry;
    final source = e.source;
    final tags = !_c.createTransaction
        ? null
        : editing && !_sourced
        ? TagChipRow(
            selected: _c.tagIds,
            onRemove: _c.toggleTag,
            onMore: _moreTags,
            known: _c.knownTags,
          )
        : _c.tagIds.isEmpty
        ? null
        : TxTagStrip(
            tags: [
              for (final id in _c.tagIds)
                if (_c.knownTags[id] != null) _c.knownTags[id]!,
            ],
          );
    return editScope(
      SavingOverlay(
        saving: isSaving,
        child: Scaffold(
          appBar: AppTopBar(
            title: l.debtEntryTitle,
            showBack: true,
            editing: editing,
            onBack: handleBack,
          ),
          extendBodyBehindAppBar: true,
          body: Builder(
            builder: (context) => ListenableBuilder(
              listenable: _c,
              builder: (context, _) => DetailPageBody(
                onRefresh: widget.onRefresh,
                physics: const AlwaysScrollableScrollPhysics(),
                topInset: MediaQuery.paddingOf(context).top + AppSpacing.md,
                bottomInset: 96 + MediaQuery.paddingOf(context).bottom,
                hero: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_sourced && editing) ...[
                      AppMessage(
                        message: l.debtSourceHint(source?.title ?? ''),
                        tone: Tone.info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TxHeroCard(
                      key: _heroKey,
                      debt: true,
                      inline: true,
                      editing: editing,
                      amountLocked: _sourced,
                      type: _c.direction == DebtEntryDirection.paid
                          ? TransactionType.expense
                          : TransactionType.income,
                      onTypeChanged: editing && !_sourced
                          ? (t) => _c.setDirection(
                              t == TransactionType.income
                                  ? DebtEntryDirection.received
                                  : DebtEntryDirection.paid,
                            )
                          : null,
                      amount: _c.amount,
                      title: _c.description,
                      titlePlaceholder: e.direction == DebtEntryDirection.paid
                          ? l.debtsDirPaid
                          : l.debtsDirReceived,
                      dateLabel: _dayLabel(l, _c.date),
                      onPickDate: editing && !_sourced ? _pickDate : null,
                      symbol: symbol,
                      onEdit: () => enterEdit(),
                      onLongPressField: (f) => enterEdit(focus: f),
                      amountNote: _balanceLine(l, symbol),
                      footer: _cards(l),
                    ),
                  ],
                ),
                tags: tags,
                sections: [
                  (first) => SectionCard(
                    first: first,
                    children: [
                      DetailRow(
                        label: l.debtsPaidChip,
                        trailing: AppSwitch(
                          value: _paid,
                          onChanged: editing ? _setPaid : null,
                        ),
                      ),
                      DetailTextField(
                        label: l.commonNote,
                        controller: _c.note,
                        editing: editing,
                        maxLines: 5,
                        maxLength: TextLimits.note,
                        hint: l.txNoteAddHint,
                        placeholderWhenEmpty: true,
                        onEnterEdit: () => enterEdit(),
                      ),
                      // A split-sourced entry keeps what it is.
                      if (!_sourced)
                        DetailRow(
                          label: l.debtCreateTxLabel,
                          helper: l.debtCreateTxHint,
                          // The whole row toggles it (while editing).
                          onTap: editing
                              ? () => _c.setCreateTransaction(
                                  !_c.createTransaction,
                                )
                              : null,
                          trailing: AppSwitch(
                            value: _c.createTransaction,
                            onChanged: editing ? _c.setCreateTransaction : null,
                          ),
                        ),
                    ],
                  ),
                  if (source != null)
                    (first) => SectionCard(
                      first: first,
                      children: [
                        DetailRow(
                          label: l.debtSourceRowLabel,
                          helper: source.title,
                          showChevron:
                              !editing &&
                              source.id != null &&
                              source.kind != 'partner',
                          onTap:
                              editing ||
                                  source.id == null ||
                                  source.kind == 'partner'
                              ? null
                              : () => openPage(
                                  context,
                                  source.kind == 'event'
                                      ? '/projects/${source.id}'
                                      : '/transactions/${source.id}',
                                ),
                        ),
                      ],
                    ),
                ],
                manage: editing
                    ? ManageSection(
                        deleteLabel: l.debtEntryDelete,
                        onDelete: isSaving ? null : _confirmDelete,
                      )
                    : null,
                metaLines: detailMetaLines(
                  context,
                  createdAt: e.createdAt,
                  updatedAt: e.updatedAt,
                ),
              ),
            ),
          ),
          bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
        ),
      ),
    );
  }
}
