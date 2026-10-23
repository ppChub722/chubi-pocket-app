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
    required this.due,
  });

  /// กำหนดจ่าย, YYYY-MM-DD.
  final String? due;

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
    due: due,
  );

  @override
  List<Object?> get props => [
    due,
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
      ..amount.text = AmountInput.format(e.amount)
      ..description.text = e.description ?? ''
      ..note.text = e.note ?? ''
      ..date = e.date ?? DateTime.now()
      ..dueDate = e.dueDate
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
    due: _c.dueDate == null ? null : _ymd(_c.dueDate!),
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
      ..dueDate = w.due == null ? null : DateTime.parse(w.due!)
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
        next.due == w.due &&
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
      dueDate: w.due != o.due && w.due != null ? DateTime.parse(w.due!) : null,
      clearDueDate: w.due != o.due && w.due == null,
    );
    final repo = context.read<PersonalDebtsRepository>();
    setSaving(true);
    try {
      final r = await repo.updateEntry(_entry.id, update);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(working);
      _applyWrite(r);
      _say(l.quickSaved, Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(context, e, retry: _save);
    }
  }

  /// Wallet balances, the transactions list and this page follow the answer.
  void _applyWrite(DebtEntryWriteResult r) {
    context.read<AccountsCubit>().patchBalances(r.accountBalances);
    final txCubit = context.read<TransactionsCubit>();
    final tx = r.transaction;
    final oldTxId = widget.detail.transaction?.id;
    if (tx != null) {
      txCubit.patchRow(tx, afterWrite: true);
    } else if (oldTxId != null) {
      txCubit.dropRow(oldTxId);
    }
    widget.onChanged(
      DebtEntryDetail(entry: r.entry, balance: r.balance, transaction: tx),
    );
  }

  /// ผูกรายการ: the wallet first ("ไม่ระบุกระเป๋า" offered too, like quick
  /// create), then the BE makes the transaction. Cancel = nothing.
  Future<void> _linkTx() async {
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final picked = await AccountPicker.one(
      context,
      accounts: accounts,
      allowNone: true,
    );
    if (picked == null || !mounted) return;
    final wallet = picked is AccountPicked ? picked.account : null;
    if (isEditing) {
      if (wallet != null) _accounts[wallet.id] = wallet;
      _c
        ..setCreateTransaction(true)
        ..setAccount(wallet);
      return;
    }
    final repo = context.read<PersonalDebtsRepository>();
    setSaving(true);
    try {
      final r = await repo.updateEntry(
        _entry.id,
        DebtEntryUpdate(createTransaction: true, accountId: wallet?.id),
      );
      if (mounted) _applyWrite(r);
    } catch (e) {
      if (mounted) _say(_failed(e), Tone.danger);
    } finally {
      if (mounted) setSaving(false);
    }
  }

  bool _paidBusy = false;

  /// The ☑ in the hero: view mode saves at once, edit mode is part of the
  /// draft.
  Future<void> _togglePaid() async {
    if (isEditing) {
      _setPaid(!_paid);
      return;
    }
    if (_paidBusy) return;
    final next = !_paid;
    setState(() {
      _paid = next;
      _paidBusy = true;
    });
    try {
      final r = await context.read<PersonalDebtsRepository>().setPaid(
        _entry.id,
        next,
      );
      if (!mounted) return;
      widget.onChanged(
        DebtEntryDetail(
          entry: r.entry,
          balance: r.balance,
          transaction: widget.detail.transaction,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _paid = _entry.paid);
      _say(_failed(e), Tone.danger);
    } finally {
      if (mounted) setState(() => _paidBusy = false);
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

  /// The hero's first item: ☑ = จ่ายแล้ว, marked right here.
  Widget _paidBox(AppLocalizations l) {
    final theme = Theme.of(context);
    // Unpaid with a due date: the date (or how late it is) says more than
    // "ยังไม่จ่าย" (owner 2026-10-23).
    final due = _paid ? null : _c.dueDate;
    final now = DateTime.now();
    final late = due == null
        ? 0
        : DateTime(now.year, now.month, now.day)
              .difference(DateTime(due.year, due.month, due.day))
              .inDays;
    final overdue = late > 0;
    final status = _paid
        ? l.debtsPaidChip
        : due == null
        ? l.debtUnpaidLabel
        : overdue
        ? l.debtOverdueDays(late)
        : l.debtDueOn(_dayLabel(l, due));
    return GestureDetector(
      key: const ValueKey('debtPaidBox'),
      behavior: HitTestBehavior.opaque,
      // One save at a time: the circle spins and every tap waits.
      onTap: _paidBusy ? null : _togglePaid,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckCircleButton(
            checked: _paid,
            loading: _paidBusy,
            tooltip: l.debtsPaidChip,
            onChanged: (_) => _togglePaid(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: overdue ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown in italics when the entry has no description of its own.
  String _autoTitle(AppLocalizations l, DebtEntry e) => debtAutoTitle(
    l,
    direction: e.direction,
    isRepayment: e.isRepayment,
    name: _c.person?.person.name ?? widget.detail.balance.person.name,
  );

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

  /// The linked transaction as its wallet; none = a dashed ผูกรายการ. The
  /// transaction has no page of its own (this page is it), so the card opens
  /// the wallet; edit mode changes the wallet, × unlinks on save.
  Widget _txCard(AppLocalizations l) {
    final editing = isEditing;
    final linked = editing
        ? _c.createTransaction
        : widget.detail.transaction != null;
    if (!linked) {
      return PickCard(
        key: const ValueKey('debtTxCard'),
        label: l.transactionFormAccountLabel,
        placeholder: l.debtLinkTx,
        dense: true,
        reserveSubtitle: true,
        leading: const PickCardEmptyIcon(AppIcons.link, size: 32),
        editable: editing,
        onLongPress: editing ? null : () => enterEdit(),
        onTap: _linkTx,
      );
    }
    // The wallet's own card, as in quick create: its icon, colours, balance.
    final walletId = widget.detail.transaction?.account?.id;
    final picked = _c.account;
    // The loaded wallet has the icon colours and balance the ref lacks.
    Account? full;
    for (final a in context.watch<AccountsCubit>().state.accounts) {
      if (a.id == picked?.id) full = a;
    }
    final card = WalletPickCard(
      key: editing ? null : const ValueKey('debtTxCard'),
      account: full ?? picked,
      label: l.transactionFormAccountLabel,
      placeholder: l.debtNoWallet,
      dense: true,
      editable: editing,
      onLongPress: editing ? null : () => enterEdit(),
      onTap: editing
          ? _pickAccount
          : walletId == null
          ? null
          : () => openPage(context, '/accounts/$walletId'),
    );
    if (!editing) return card;
    // × small in the card's top-right corner, in the warning colour.
    return Stack(
      key: const ValueKey('debtTxCard'),
      fit: StackFit.passthrough,
      children: [
        card,
        PositionedDirectional(
          top: AppSpacing.xs,
          end: AppSpacing.xs,
          child: AppIconButton.flat(
            key: const ValueKey('debtUnlinkTx'),
            icon: AppIcons.close,
            iconSize: 16,
            dense: true,
            color: Tone.warning.color(context),
            tooltip: l.commonDelete,
            onPressed: () => _c.setCreateTransaction(false),
          ),
        ),
      ],
    );
  }

  /// กับใคร › and the wallet card (mock DebtEntry); a split's or an event's
  /// debt shows where it came from instead.
  Widget _cards(AppLocalizations l, String symbol) {
    final editable = isEditing && !_sourced;
    final p = _c.person;
    final canEditHere = !isEditing && !_sourced;
    final origin = _entry.origin;
    final personCard = PickCard(
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
      onLongPress: canEditHere ? () => enterEdit(then: _pickPerson) : null,
      onTap: editable
          ? _pickPerson
          : isEditing || p == null
          ? null
          : () => openPage(context, debtPersonPath(p.key)),
    );
    // Like quick create (owner 2026-10-23): my wallet ⇄ the person in the
    // money's direction; edit mode's arrow swaps it.
    if (!_sourced) {
      final mine = _txCard(l);
      final out = _c.direction == DebtEntryDirection.paid;
      return FlowCards(
        key: const ValueKey('debtFlow'),
        from: out ? mine : personCard,
        to: out ? personCard : mine,
        swapTooltip: l.quickSwap,
        onSwap: isEditing
            ? () => _c.setDirection(
                out ? DebtEntryDirection.received : DebtEntryDirection.paid,
              )
            : null,
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: personCard),
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
          ] else ...[
            // Alone it keeps the create form's half width.
            const SizedBox(width: AppSpacing.sm),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDue() async {
    final from = DateTime(_c.date.year, _c.date.month, _c.date.day);
    final r = await showAppDatePicker(
      context,
      initial: _c.dueDate ?? from,
      first: from,
      last: from.add(const Duration(days: 365 * 5)),
    );
    if (r is AppDatePicked && mounted) _c.setDueDate(r.date);
  }

  /// "กำหนดจ่าย" under โน้ต, like quick create's row; view mode shows it only
  /// when set.
  Widget _dueSection(AppLocalizations l, bool first) {
    final due = _c.dueDate;
    final Widget chip = !isEditing
        ? AppChip(label: _dayLabel(l, due!), icon: AppIcons.date)
        : due == null
        ? AppChip(
            label: l.debtDuePick,
            icon: AppIcons.add,
            tone: AppChipTone.primary,
            selected: true,
            dashed: true,
            onTap: _pickDue,
          )
        : AppChip(
            label: _dayLabel(l, due),
            icon: AppIcons.date,
            selected: true,
            dashed: true,
            inset: true,
            trailing: AppChipTrailing.remove,
            onRemove: () => _c.setDueDate(null),
            onTap: _pickDue,
          );
    return SectionCard(
      key: const ValueKey('debtDueRow'),
      first: first,
      children: [
        DetailRow(
          label: l.debtDueLabel,
          onLongPress: isEditing ? null : () => enterEdit(then: _pickDue),
          trailing: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: chip,
          ),
        ),
      ],
    );
  }

  String _failed(Object e) => e is ApiException
      ? e.message
      : AppLocalizations.of(context)!.errorUnknownMessage;

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
                      headerLeading: _paidBox(l),
                      // No direction chips: the flow cards' arrow says (and,
                      // in edit mode, swaps) it.
                      typeBadge: const SizedBox.shrink(),
                      amount: _c.amount,
                      title: _c.description,
                      // A recorded debt says what it was for; a repayment's
                      // and a split's text comes from the app.
                      titleReadOnly: e.isRepayment || _sourced,
                      titleLabel: l.debtOriginFieldLabel,
                      titlePlaceholder: _autoTitle(l, e),
                      dateLabel: _dayLabel(l, _c.date),
                      onPickDate: editing && !_sourced ? _pickDate : null,
                      symbol: symbol,
                      onEdit: () => enterEdit(),
                      onLongPressField: (f) => enterEdit(focus: f),
                      footer: _cards(l, symbol),
                    ),
                  ],
                ),
                tags: tags,
                sections: [
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
                  if (!e.isRepayment && (editing || _c.dueDate != null))
                    (first) => _dueSection(l, first),
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
