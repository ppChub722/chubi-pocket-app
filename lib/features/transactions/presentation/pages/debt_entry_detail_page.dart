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
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../save_failure.dart';
import '../widgets/debt_entry_form.dart';
import '../widgets/draft_form.dart';
import '../widgets/pick_chip_rows.dart';

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

  bool _restoring = false;

  final Map<String, DebtPick> _people = {};
  final Map<String, Account> _accounts = {};

  DebtEntry get _entry => widget.detail.entry;

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

  Future<void> _pickPerson() async {
    final p = await showDebtPersonPicker(context, selected: _c.person);
    if (p == null || !mounted) return;
    _people[p.key] = p;
    _c.setPerson(p);
  }

  Future<void> _pickAccount() async {
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await AccountPicker.one(
      context,
      accounts: accounts,
      selectedId: _c.account?.id,
      allowNone: true,
    );
    if (!mounted || r == null) return;
    final a = r is AccountPicked ? r.account : null;
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
    final next = await TagPicker.many(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next.ids);
  }

  void _setPaid(bool v) {
    setState(() => _paid = v);
    _onFormChanged();
  }

  void _say(String text, Tone tone) {
    final m = pageMessenger;
    if (m != null) showAppSnackBarOn(m, text, tone: tone);
  }

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
      createTransaction: _sourced ? null : w.createTx,
      accountId: w.createTx && (w.accountId != o.accountId || txChange)
          ? w.accountId
          : null,
      clearAccount:
          w.createTx && !txChange && o.accountId != null && w.accountId == null,
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
    final oldTxId = widget.detail.transaction?.id;
    setSaving(true);
    try {
      final r = await repo.updateEntry(_entry.id, update);
      accounts.patchBalances(r.accountBalances);
      final tx = r.transaction;
      if (tx != null) {
        txCubit.patchRow(tx, afterWrite: true);
      } else if (oldTxId != null) {
        txCubit.dropRow(oldTxId);
      }
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

  String _dayLabel(AppLocalizations l, DateTime d) => DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// Under the amount (mock DebtEntry): "รอรับจาก chalee ฿82" — this debt —
  /// and "✓ จ่ายแล้ว".
  Widget? _entryNote(AppLocalizations l, String symbol) {
    final p = _c.person;
    if (p == null) return null;
    final owedToMe = _c.direction == DebtEntryDirection.paid;
    final name = p.person.name;
    return DebtEntryNote(
      key: const ValueKey('debtEntryNote'),
      sentence: owedToMe ? l.debtPersonOwedFrom(name) : l.debtPersonOweTo(name),
      amount: MoneyText(_c.amountValue, symbol: symbol),
      color: debtStateColor(context, owedToMe: owedToMe),
      paidLabel: _paid ? l.debtPaidPill : null,
    );
  }

  /// "มาจาก (แบ่งบิล)" — the kind in words.
  String _originKind(AppLocalizations l, DebtOrigin o) => switch (o.kind) {
    'split' => l.debtOriginSplit,
    'paid_by' => l.debtOriginPaidBy,
    'partner' => l.debtOriginPartner,
    'event' => l.debtOriginEvent,
    _ => l.debtOriginCash,
  };

  /// Opens where the debt came from: its transaction, else its event.
  VoidCallback? _openOrigin(DebtOrigin o) {
    final tx = o.transactionId;
    if (tx != null) return () => openPage(context, '/transactions/$tx');
    final ev = o.eventId;
    if (ev != null) {
      final bill = o.billId;
      return () => openPage(
        context,
        bill == null ? '/projects/$ev' : '/projects/$ev?bill=$bill',
      );
    }
    return null;
  }

  /// กับใคร › and มาจาก › (mock DebtEntry). A debt has no wallet of its own:
  /// a cash loan's มาจาก card is its linked transaction.
  Widget _cards(AppLocalizations l, String symbol) {
    final editable = isEditing && !_sourced;
    final p = _c.person;
    final canEditHere = !isEditing && !_sourced;
    final origin = _entry.origin;
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
              reserveSubtitle: true,
              subtitle: debtNetSubtitle(
                context,
                l,
                isEditing ? p?.net : widget.detail.balance.net,
              ),
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
              onTap: editable
                  ? _pickPerson
                  : isEditing || p == null
                  ? null
                  : () => openPage(context, debtPersonPath(p.key)),
            ),
          ),
          if (origin != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Opacity(
                // Edit mode: shown, never changed here.
                opacity: isEditing ? 0.75 : 1,
                child: PickCard(
                  key: const ValueKey('debtOriginCard'),
                  label: l.debtOriginLabel(_originKind(l, origin)),
                  value: [
                    origin.title ?? '',
                    if (origin.amount != null)
                      moneyString(context, origin.amount!, symbol: symbol),
                  ].where((s) => s.isNotEmpty).join(' '),
                  placeholder: l.debtOriginLocked,
                  dense: true,
                  reserveSubtitle: true,
                  subtitle: isEditing ? Text(l.debtOriginLocked) : null,
                  leading: const PickCardEmptyIcon(AppIcons.receipt, size: 32),
                  onTap: isEditing ? null : _openOrigin(origin),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _walletHint(AppLocalizations l) => !_c.createTransaction
      ? l.debtEditWalletOff
      : _c.direction == DebtEntryDirection.paid
      ? l.debtEditWalletLend
      : l.debtEditWalletBorrow;

  /// Edit mode's box (mock DebtEntryEdit): money in / out of a wallet (+ the
  /// wallet), and the จ่ายแล้ว label.
  Widget _editBox(AppLocalizations l, bool first) => SectionCard(
    first: first,
    children: [
      if (!_sourced) ...[
        SettingToggleRow(
          label: l.debtMoneyMovedLabel,
          caption: _walletHint(l),
          value: _c.createTransaction,
          onChanged: _c.setCreateTransaction,
        ),
        if (_c.createTransaction)
          DetailRow(
            label: l.transactionFormAccountLabel,
            trailing: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppChip(
                key: const ValueKey('debtEditWallet'),
                label: _c.account?.name ?? l.quickPickWallet,
                icon: AppIcons.wallet,
                trailing: AppChipTrailing.dropdown,
                onTap: _pickAccount,
              ),
            ),
          ),
      ],
      SettingToggleRow(
        label: l.debtsPaidChip,
        caption: l.debtPaidHelper,
        value: _paid,
        onChanged: _setPaid,
      ),
    ],
  );

  /// View mode (bug B2): จ่ายแล้ว saves at once, no ✏️ needed.
  Widget _paidLive(AppLocalizations l, bool first) => SectionCard(
    first: first,
    children: [
      LiveSetting<bool>(
        value: _entry.paid,
        save: (on) async {
          final r = await context.read<PersonalDebtsRepository>().setPaid(
            _entry.id,
            on,
          );
          if (!mounted) return true;
          widget.onChanged(
            DebtEntryDetail(
              entry: r.entry,
              balance: r.balance,
              transaction: widget.detail.transaction,
            ),
          );
          return true;
        },
        failedMessage: (e) => e is ApiException
            ? e.message
            : AppLocalizations.of(context)!.errorUnknownMessage,
        builder: (context, value, onChanged) => SettingToggleRow(
          label: l.debtsPaidChip,
          caption: l.debtPaidHelper,
          value: value,
          onChanged: onChanged,
        ),
      ),
    ],
  );

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
                    TransactionHeroCard(
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
                      amountNote: _entryNote(l, symbol),
                      footer: _cards(l, symbol),
                    ),
                  ],
                ),
                tags: tags,
                sections: [
                  (first) => editing ? _editBox(l, first) : _paidLive(l, first),
                  (first) => NoteSection(
                    first: first,
                    label: l.commonNote,
                    editing: editing,
                    text: _c.note.text,
                    hint: l.commonLongPressToEdit,
                    onLongPress: () => enterEdit(),
                    editField: DetailTextField(
                      label: l.commonNote,
                      controller: _c.note,
                      editing: true,
                      maxLines: 5,
                      maxLength: TextLimits.note,
                      hint: l.debtNoteHint,
                    ),
                  ),
                  // An older BE without `origin`: the split source row.
                  if (source != null && e.origin == null)
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
