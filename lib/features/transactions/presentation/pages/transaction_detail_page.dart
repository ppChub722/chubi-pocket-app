import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../personal_debts/domain/debt_ledger.dart' show debtPersonKey;
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../personal_debts/presentation/debt_wiring.dart'
    show debtPersonPath;
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/paper.dart' show PaperView;
import '../../../pending/domain/pending_transaction.dart';
import '../../../recurring/data/recurring_link_repository.dart'
    show LinkCandidate;
import '../../data/transactions_repository.dart';
import '../../domain/link_draft.dart';
import '../../domain/refs.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../delete_results.dart';
import '../transaction_edit.dart';
import '../tx_rules.dart';
import '../save_failure.dart';
import '../paper_edit.dart';
import '../quick_create_bodies.dart';
import '../widgets/draft_form.dart';
import 'debt_entry_detail_page.dart';
import '../widgets/event_pick.dart';
import '../widgets/event_picker.dart';
import '../widgets/link_view.dart';
import '../widgets/quick_create_sheet.dart' show openPaperBill;
import '../widgets/recurring_link.dart';
import '../widgets/tx_compact_hero.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({
    required this.transactionId,
    this.startEditing = false,
    super.key,
  });

  final String transactionId;

  final bool startEditing;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _fetching = true;

  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final cached = context.read<TransactionsCubit>().byId(widget.transactionId);
    if (cached?.debtLink != null) {
      _fetching = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _fetching = true;
      _error = null;
    });
    ApiException? error;
    try {
      await context.read<TransactionsCubit>().refreshOne(widget.transactionId);
    } catch (e, st) {
      error = ApiException.from(e, st);
    }
    if (!mounted) return;
    setState(() {
      _fetching = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final tx = context.read<TransactionsCubit>().byId(widget.transactionId);
        // A debt and a repayment alike open the person-book entry's page
        // (owner 2026-11-05).
        final link = tx?.debtLink;
        if (link != null) return DebtEntryDetailPage(entryId: link.entryId);
        if (tx != null) {
          return _Loaded(
            tx: tx,
            fetching: _fetching,
            startEditing: widget.startEditing,
          );
        }
        final missing = _error?.statusCode == 404;
        return AppPage(
          topBar: AppTopBar(title: l.navTransactions, showBack: true),
          body: AsyncStateView.fallback(
            loading: _fetching,
            error: missing ? null : _error,
            onRetry: _fetch,
            notFound: EmptyView(
              icon: AppIcons.empty,
              title: l.transactionDetailNotFound,
              message: l.transactionDetailNotFoundMessage,
            ),
          ),
        );
      },
    );
  }
}

/// One bill, either kind, by its id alone (owner 2026-11-17: a paper is ONE
/// page from everywhere — the event, a notice, a debt's "มาจาก"): with my
/// transaction of it, that transaction's page; none yet, the same page
/// without my part, where "ลงรายการของฉันเลย" / "จดหนี้บิลนี้เลย" book it.
class BillPage extends StatefulWidget {
  const BillPage({required this.paperId, super.key});

  final String paperId;

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  PaperView? _paper;
  bool _loading = true;
  ApiException? _error;

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
    PaperView? paper;
    ApiException? error;
    try {
      paper = await context.read<ProjectsRepository>().getPaper(widget.paperId);
    } catch (e, st) {
      error = ApiException.from(e, st);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      if (paper != null) _paper = paper;
    });
    // A payback not in my book yet: its sheet (where it is booked), then
    // back. Booked, it is my repayment's page (build).
    if (paper != null &&
        paper.isPayback &&
        paper.myTransactionId == null &&
        paper.myDebtIds.isEmpty) {
      final nav = Navigator.of(context);
      await openPaperBill(context, paper.id);
      if (mounted && nav.canPop()) nav.pop();
    }
  }

  /// The page's row while I have no transaction of the bill: the bill's own
  /// fields, no wallet / category of mine.
  static Transaction _unbookedRow(PaperView p) => Transaction(
    id: '',
    accountId: null,
    type: p.type == 'income' ? TransactionType.income : TransactionType.expense,
    amount: p.amount,
    date: p.date,
    description: p.description,
    eventBill: EventBillLink(
      event:
          p.event ??
          EventRef(id: p.id, name: p.description ?? '', kind: 'split'),
      billId: p.id,
      linked: true,
      billAmount: p.amount,
      editInBill: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _paper;
    final txId = p?.myTransactionId;
    if (txId != null) {
      return TransactionDetailPage(key: ValueKey(txId), transactionId: txId);
    }
    // A payback is a repayment (owner 2026-11-17): booked, my repayment's
    // page.
    final repayment = p != null && p.isPayback ? p.myDebtIds.firstOrNull : null;
    if (repayment != null) {
      return DebtEntryDetailPage(key: ValueKey(repayment), entryId: repayment);
    }
    if (p != null && !p.isPayback) {
      return _Loaded(
        key: ValueKey('${p.id}:${p.version}'),
        tx: _unbookedRow(p),
        paper: p,
        onReload: _load,
      );
    }
    final missing = _error?.statusCode == 404;
    return AppPage(
      topBar: AppTopBar(title: l.navTransactions, showBack: true),
      body: AsyncStateView.fallback(
        loading: _loading || p != null,
        error: missing ? null : _error,
        onRetry: _load,
        notFound: EmptyView(
          icon: AppIcons.empty,
          title: l.transactionDetailNotFound,
          message: l.transactionDetailNotFoundMessage,
        ),
      ),
    );
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({
    required this.tx,
    this.fetching = false,
    this.startEditing = false,
    this.paper,
    this.onReload,
    super.key,
  });
  final Transaction tx;
  final bool fetching;
  final bool startEditing;

  /// A bill with no transaction of mine yet ([BillPage]): [tx] is made from
  /// it; a save books what the switches ask, then [onReload].
  final PaperView? paper;
  final Future<void> Function()? onReload;

  @override
  State<_Loaded> createState() => _LoadedState();
}

/// One undo step of this page (owner 2026-11-04: undo tracks every action):
/// my row's fields, the bill (people, shares, payer, marks), the event change,
/// the recurring pick and its unlink.
@immutable
class _TxDraft {
  const _TxDraft({
    required this.tx,
    required this.bill,
    required this.event,
    required this.unlink,
    required this.recurring,
  });

  final PendingDraft tx;
  final BillState bill;
  final EventTarget? event;
  final bool unlink;
  final LinkCandidate? recurring;

  /// Only my row's text fields differ from [o] (a typing session).
  bool sameButText(_TxDraft o) =>
      bill == o.bill &&
      identical(event, o.event) &&
      unlink == o.unlink &&
      identical(recurring, o.recurring) &&
      tx.type == o.tx.type &&
      tx.date == o.tx.date &&
      tx.accountId == o.tx.accountId &&
      tx.categoryId == o.tx.categoryId &&
      tx.transferToAccountId == o.tx.transferToAccountId &&
      listEquals(tx.tagIds, o.tx.tagIds);

  @override
  bool operator ==(Object other) =>
      other is _TxDraft &&
      other.tx == tx &&
      other.bill == bill &&
      identical(other.event, event) &&
      other.unlink == unlink &&
      identical(other.recurring, recurring);

  @override
  int get hashCode => Object.hash(tx, bill, unlink);
}

class _LoadedState extends State<_Loaded>
    with EditModeMixin<_Loaded, _TxDraft> {
  final _c = DraftFormController();

  late Transaction _edited;

  String? _initialAccountId;
  String? _initialToAccountId;

  bool _restoring = false;

  final _scroll = ScrollController();

  /// The รายการประจำ row: a pick / unlink is held and sent on บันทึก.
  final _link = RecurringLinkHandle();
  final _heroKey = GlobalKey();

  EventTarget? _eventChange;

  bool _pendingUnlink = false;

  @override
  bool get canEdit {
    final tx = widget.tx;
    // A one-sided system row (deposit / withdraw) is editable.
    if (tx.category?.isOneSided ?? false) {
      return !tx.isLocked;
    }
    final isSystemRow =
        tx.type != TransactionType.transfer && (tx.category?.isSystem ?? false);
    return !isSystemRow && !tx.isLocked;
  }

  @override
  bool get isDirty =>
      super.isDirty ||
      _eventChange != null ||
      _pendingUnlink ||
      _link.candidateFor(_edited.type) != null ||
      (_billBaseline != null && _billSnapshot() != _billBaseline);

  @override
  void cancelEdit() {
    _eventChange = null;
    _pendingUnlink = false;
    _link.clear();
    super.cancelEdit();
    _reload();
  }

  // ── แบ่ง (owner 2026-11-03): the quick-create card on this page ─────────
  /// The bill this row is my book of, as read for the form; null = a plain
  /// row (or not loaded yet).
  PaperEditSession? _paper;

  /// The row is my book of a bill (its card shows once [_paper] is read).
  bool get _inBill => widget.tx.eventBill != null;

  /// A bill with no transaction of mine yet ([BillPage]).
  bool get _unbooked => widget.paper != null;

  /// The bill as sent when opened, to skip its PUT when only my books
  /// change (I may book a bill I can't edit).
  String? _paperBodyBaseline;

  String? _paperBody() {
    final paper = _paper;
    if (paper == null) return null;
    final b = paperBodies(
      _c,
      _mode,
      personIds: paper.personIds,
      mePersonId: paper.paper.me?.id,
    );
    return jsonEncode(b?.paper);
  }

  /// A switch flipped while viewing: edit, then flip it.
  void _switchInEdit(VoidCallback flip) {
    if (isEditing) {
      flip();
    } else {
      _enterEdit(then: flip);
    }
  }

  /// The แบ่ง card: a money row of mine, or my book of a bill.
  bool get _linkTabs =>
      _inBill ||
      (canEdit &&
          txCanEditSplits(_edited) &&
          DraftFormController.hasLinkTabs(_edited.type));

  /// The bill part of the form as opened (the switch, people, shares,
  /// marks, event), to tell a change.
  String? _billBaseline;

  /// The event of my bill now (an event bill's; a split bill has none).
  String? get _billEventId => switch (widget.tx.eventBill?.event) {
    final e? when !e.isSplit => e.id,
    _ => null,
  };

  /// The form has an event: the saved one unless changed.
  bool get _hasEvent => switch (_eventChange) {
    null => _billEventId != null,
    RemoveFromEvent() => false,
    _ => true,
  };

  LinkMode get _mode => _c.linkMode(hasEvent: _hasEvent);

  String _billSnapshot() {
    final mode = _mode;
    final b = paperBodies(_c, mode, personIds: _paper?.personIds ?? const {});
    return jsonEncode([
      mode.name,
      b?.paper['people'],
      b?.paper['split_mode'],
      b?.paidBack,
      _c.link.eventBookDebts,
      _c.link.eventBookMine,
    ]);
  }

  /// The bill as GET /transactions/{id} brought it (one call, owner
  /// 2026-11-04), else read on its own (a row from a list).
  Future<void> _loadPaper() async {
    final bill = widget.tx.eventBill;
    if (bill == null) return;
    try {
      final p =
          widget.paper ??
          switch (widget.tx.paperJson) {
            final j? => PaperView.fromJson(j),
            null => await context.read<ProjectsRepository>().getPaper(
              bill.billId,
            ),
          };
      if (!mounted) return;
      setState(() => _paper = PaperEditSession(p));
      if (!isEditing) _reload();
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  /// "อัปเดตตามอีเวนต์": my linked tx takes the bill as it is now.
  Future<void> _applyEvent() async {
    final l = AppLocalizations.of(context)!;
    final projects = context.read<ProjectsRepository>();
    final txCubit = context.read<TransactionsCubit>();
    try {
      await projects.syncMyTransaction(widget.tx.id);
      await txCubit.refreshOne(widget.tx.id);
      _say(l.txLinkApplied, tone: Tone.success);
    } on ApiException catch (e) {
      _say(errorText(l, e));
    }
  }

  Future<void> _pickEvent() async {
    final l = AppLocalizations.of(context)!;
    final current = _billEventId;
    final description = _c.description.text.trim();
    final date = DateFormatter.medium(
      _c.date,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final picked = await EventPicker.one(
      context,
      suggestedName:
          '${description.isEmpty ? l.quickEventDefaultName : description}'
          ' | $date',
      currentProjectId: current,
      selectedProjectId: switch (_eventChange) {
        ExistingEventTarget(:final project) => project.id,
        _ => null,
      },
    );
    if (picked == null || !mounted) return;
    setState(
      () => _eventChange = switch (picked) {
        RemoveFromEvent() when current == null => null,
        ExistingEventTarget(:final project) when project.id == current => null,
        _ => picked,
      },
    );
    _c.eventChanged(hasEvent: _hasEvent);
  }

  void _clearEvent() {
    setState(
      () =>
          _eventChange = _billEventId == null ? null : const RemoveFromEvent(),
    );
    _c.eventChanged(hasEvent: _hasEvent);
  }

  /// The event row's name: my bill's event (a split bill has none).
  String? _eventName(AppLocalizations l, Transaction tx) =>
      switch (_eventChange) {
        null => _billEventId == null ? null : tx.eventBill?.event.name,
        final change => eventTargetName(l, change),
      };

  @override
  void initState() {
    super.initState();
    _link.addListener(_onLinkChanged);
    // Not booked yet: the bill is here already, so the first frame has it.
    if (widget.paper case final p?) _paper = PaperEditSession(p);
    _prefill();
    initDraft(_draft());
    _c.addListener(_onFormChanged);
    if (widget.startEditing && canEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterEdit();
      });
    } else if (_inBill && (widget.tx.paperJson != null || !widget.fetching)) {
      // Still fetching a list row: the fetched row brings its bill.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPaper());
    }
  }

  /// Edit on this page (owner 2026-11-03), a bill row too: its card turns
  /// editable once the bill is read.
  Future<void> _enterEdit({FocusNode? focus, VoidCallback? then}) async {
    if (_inBill && _paper == null) {
      await _loadPaper();
      if (!mounted || isEditing || _paper == null) return;
    }
    enterEdit(focus: focus, then: then);
  }

  void _longPressHint() => _say(
    AppLocalizations.of(context)!.commonLongPressToEdit,
    tone: Tone.info,
  );

  void _scrollToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void didUpdateWidget(_Loaded old) {
    super.didUpdateWidget(old);
    // Refreshed underneath (pull, another page, a save) — rebase unless
    // editing. A bill row reads its bill first, then rebases on both.
    if (isEditing) return;
    if (old.tx == widget.tx) {
      // The fetch failed (same row): read the bill on its own.
      if (old.fetching && !widget.fetching && _inBill && _paper == null) {
        unawaited(_loadPaper());
      }
      return;
    }
    if (_inBill) {
      unawaited(_loadPaper());
    } else {
      _paper = null;
      _reload();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    _link.dispose();
    super.dispose();
  }

  void _onLinkChanged() {
    if (!mounted) return;
    // A recurring pick while editing is an undo step too.
    if (!_restoring && isEditing) _onFormChanged();
    setState(() {});
  }

  void _say(String message, {Tone tone = Tone.danger}) {
    if (mounted) showPpForgeSnackBar(context, message, tone: tone);
  }

  Future<void> _linkRecurring() async {
    final tx = _edited;
    final linked = _pendingUnlink ? null : widget.tx.recurringItem;
    await _link.choose(
      context,
      type: tx.type,
      categoryId: tx.type == TransactionType.transfer ? null : tx.categoryId,
      amount: tx.amount > 0 ? tx.amount : null,
      txDate: DateTime.tryParse(tx.date),
      txId: tx.id,
      linkedRuleId: linked?.recurringId,
      linkedItemId: linked?.itemId,
      createRoute: recurringCreateRoute(
        type: tx.type,
        amount: tx.amount,
        categoryId: tx.categoryId,
        accountId: tx.accountId,
        name: tx.description,
      ),
    );
  }

  void _dropRecurring() {
    if (_link.candidateFor(_edited.type) != null) {
      _link.clear();
    } else {
      setState(() => _pendingUnlink = true);
      _onFormChanged();
    }
  }

  Future<void> _applyRecurringChange(
    TransactionsCubit txCubit,
    AccountsCubit accounts,
  ) async {
    final item = widget.tx.recurringItem;
    final cached = widget.tx;
    final unlinked = _pendingUnlink && item != null;
    if (unlinked) {
      await _link.unlinkNow(
        context,
        item,
        onUnlinked: () => txCubit.patchRow(
          cached.copyWith(clearRecurringItem: true),
          afterWrite: true,
        ),
        error: _say,
      );
    }
    _pendingUnlink = false;
    if (!mounted) return;
    if (_link.candidateFor(_edited.type) != null) {
      await _link.linkNow(
        context,
        _edited.id,
        onLinked: (fresh, balances) {
          txCubit.patchRow(fresh, afterWrite: true);
          accounts.patchBalances(balances);
        },
        error: _say,
        replace: item != null && !unlinked,
      );
      _link.clearChoice();
    }
  }

  ({Transaction edited, AccountRef? other}) _transferView(Transaction tx) {
    final peer = tx.transferPeer;
    final mine = tx.account;
    if (tx.type != TransactionType.transfer || peer == null) {
      return (edited: tx, other: null);
    }
    if (tx.isTransferIn && mine != null) {
      return (
        edited: tx.copyWith(
          id: peer.id,
          accountId: peer.account.id,
          account: peer.account,
          transferPeer: TransferPeer(id: tx.id, isOut: false, account: mine),
        ),
        other: mine,
      );
    }
    return (edited: tx, other: peer.account);
  }

  List<Account> _accountPool(Iterable<AccountRef?> embedded) {
    final base =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final ids = {for (final a in base) a.id};
    return [
      ...base,
      for (final a in embedded)
        if (a != null && ids.add(a.id)) a.toAccount(),
    ];
  }

  List<Category> _categoryPool(EmbeddedCategory? embedded) {
    final base =
        maybeTxFormOptions(
          context,
          watch: false,
        )?.state.options?.categoryList ??
        context.read<CategoriesCubit>().state.categories;
    return [
      ...base,
      if (embedded != null && !base.any((c) => c.id == embedded.id))
        embedded.toCategory(),
    ];
  }

  void _prefill() {
    final tx = widget.tx;
    final view = _transferView(tx);
    final edited = view.edited;
    _edited = edited;
    _restoring = true;
    _c.tagIds.clear();
    _c.knownTags.clear();
    _c.prefillTransaction(
      edited,
      accounts: _accountPool([edited.account, view.other]),
      categories: _categoryPool(edited.category),
      toAccount: view.other?.toAccount(),
    );
    _restoring = false;
    _initialAccountId = _c.account?.id;
    _initialToAccountId = _c.toAccount?.id;
    // My bill into the แบ่ง card (its amount is the bill's; my share shows
    // under it); a plain row starts with แบ่ง off.
    final paper = _paper;
    if (paper != null) {
      _paper = PaperEditSession(paper.paper);
      _restoring = true;
      _paper!.prefill(context, _c);
      _restoring = false;
    } else {
      _c.setLinkMode(LinkMode.personal, hasEvent: false);
    }
    _eventChange = null;
    _billBaseline = _linkTabs ? _billSnapshot() : null;
    _paperBodyBaseline = _paperBody();
    _billOn = _mode != LinkMode.personal;
  }

  /// แบ่ง on as last seen, to catch the switch flipping.
  bool _billOn = false;

  static String _amountText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Owner 2026-11-03: on my bill row the amount field follows the switch
  /// in view: off → my row's own amount, on → the bill's; a typed amount
  /// (neither) stays.
  void _swapBillAmount() {
    final on = _mode != LinkMode.personal;
    if (on == _billOn) return;
    _billOn = on;
    final paper = _paper;
    if (paper == null || !isEditing) return;
    final from = on ? _edited.amount : paper.paper.amount;
    final to = on ? paper.paper.amount : _edited.amount;
    final typed = double.tryParse(_c.amount.text.replaceAll(',', ''));
    if (typed != null && (typed - from).abs() >= 0.005) return;
    _c.amount.text = _amountText(to);
  }

  void _reload() {
    _prefill();
    resetDraft(_draft());
  }

  _TxDraft _draft() => _TxDraft(
    tx: _c.toDraft(),
    bill: _c.bill(),
    event: _eventChange,
    unlink: _pendingUnlink,
    recurring: _link.candidate,
  );

  @override
  void onDraftRestored() {
    _restoring = true;
    final w = working;
    final view = _transferView(widget.tx);
    _c.restoreTransaction(
      w.tx,
      accounts: _accountPool([view.edited.account, view.other]),
      categories: _categoryPool(view.edited.category),
    );
    _eventChange = w.event;
    _pendingUnlink = w.unlink;
    _link.restore(w.recurring);
    _c.restoreBill(w.bill);
    _billOn = _mode != LinkMode.personal;
    _restoring = false;
  }

  void _onFormChanged() {
    if (_restoring) return;
    _swapBillAmount();
    final next = _draft();
    final w = working;
    if (next == w) {
      if (_linkTabs && isEditing) setState(() {});
      return;
    }
    if (next.sameButText(w)) {
      final field = next.tx.note != w.tx.note
          ? 'note'
          : next.tx.description != w.tx.description
          ? 'description'
          : 'amount';
      applyTextChange(field, next);
    } else {
      applyChange(next);
    }
  }

  /// บันทึก (owner 2026-11-03): my row's own fields, then the แบ่ง card,
  /// all at once:
  /// - a plain row with แบ่ง on → a new bill whose my-book is this row;
  /// - my bill row → the bill (version-checked) + my fields + marks;
  /// - my bill row with แบ่ง off → I leave the bill, the row stays plain
  ///   (the last one out deletes it).
  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    commitTextSession();
    final mode = _linkTabs ? _mode : LinkMode.personal;
    final bill = mode != LinkMode.personal;
    final paper = _paper;
    final problem = transactionEditProblem(
      l,
      _c,
      splitsEditable: false,
      checkSplits: false,
      savedAmount: _edited.amount,
    );
    if (problem != null) {
      HapticFeedback.lightImpact();
      showPpForgeSnackBar(context, problem, tone: Tone.danger);
      return;
    }
    if (bill && !_c.linkBalanced(mode)) {
      HapticFeedback.lightImpact();
      showPpForgeSnackBar(context, l.txLinkModeUnbalanced, tone: Tone.danger);
      return;
    }
    if (_unbooked && !bill) {
      // แบ่ง off on a bill I have no part of yet: leave it.
      await _deleteNow(context, l);
      return;
    }
    setSaving(true);
    final projects = context.read<ProjectsRepository>();
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final txRepo = context.read<TransactionsRepository>();
    String? warn;
    try {
      if (paper != null && bill) {
        // My bill: the bill and my own fields in one session; then a moved
        // event.
        final ok = await paper.save(
          projects: projects,
          txs: txCubit,
          c: _c,
          mode: mode,
          billChanged: !_unbooked || _paperBody() != _paperBodyBaseline,
        );
        if (!ok) {
          if (!mounted) return;
          setSaving(false);
          showPpForgeSnackBar(
            context,
            l.evbPaybackNeedsPeople,
            tone: Tone.danger,
          );
          return;
        }
        final change = _eventChange;
        if (_unbooked && change is RemoveFromEvent) {
          // No transaction of mine to unlink: the bill leaves its event.
          await projects.movePaper(paper.paper.id, fromProjectId: _billEventId);
        } else if (change != null) {
          await applyEventChange(
            projects,
            txRepo: txRepo,
            txId: _edited.id,
            amount: _edited.amount,
            currentProjectId: _billEventId,
            change: change,
            billId: paper.paper.id,
          );
        }
      } else {
        if (paper != null) {
          // แบ่ง off: out of the bill, my row kept.
          await projects.leavePaper(
            paper.paper.id,
            projectId: paper.paper.projectId,
            keepBooks: true,
          );
          if (!mounted) return;
        }
        final outcome = await saveTransactionEdit(
          context,
          t: _edited,
          c: _c,
          initialAccountId: _initialAccountId,
          initialToAccountId: _initialToAccountId,
        );
        warn = outcome.warning;
        if (bill) {
          // แบ่ง on: a new bill around this row (my book = this row).
          final body = paperBodies(_c, mode);
          if (body != null) {
            final event = _eventChange;
            final created = await projects.createPaper(
              projectId: event is ExistingEventTarget ? event.project.id : null,
              newEvent: event is NewEventTarget ? event.name : null,
              paper: body.paper,
              myBooks: {...body.myBooks, 'transaction_id': _edited.id},
            );
            await PaperEditSession.markPaidBack(
              projects,
              paperId: created.paperId,
              projectId: created.projectId,
              personIds: created.personIds,
              paidBack: body.paidBack,
            );
          }
        }
      }
      if (!mounted) return;
      if (_unbooked) {
        // Booked now (or the bill changed): the bill page reads it again and
        // shows my transaction's page once there is one.
        HapticFeedback.mediumImpact();
        commitSaved(working);
        showPpForgeSnackBar(context, l.quickSaved, tone: Tone.success);
        await widget.onReload?.call();
        return;
      }
      await _applyRecurringChange(txCubit, accountsCubit);
      try {
        await txCubit.refreshOne(_edited.id, afterWrite: true);
      } on ApiException {
        // Keep the cached row.
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(working);
      // The form already shows what was saved: keep that look (no flash of
      // a plain row) while the bill is read again; the held picks are sent.
      _eventChange = null;
      _pendingUnlink = false;
      _link.restore(null);
      resetDraft(_draft());
      _billBaseline = _linkTabs ? _billSnapshot() : null;
      if (!bill) {
        _paper = null;
        _reload();
      }
      // A bill: the refreshed row brings it (didUpdateWidget).
      showPpForgeSnackBar(
        context,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(
        context,
        e,
        retry: _save,
        message: e.code == 'BILL_CHANGED'
            ? l.evbBillChangedReopen
            : errorText(l, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tx = widget.tx;
    // A debt or a repayment of the person book opens its own page; only an
    // older repayment row with no person is left here, a read-only system row.
    final isSystemRow =
        tx.type != TransactionType.transfer &&
        (tx.category?.isSystem ?? false) &&
        !(tx.category?.isOneSided ?? false);
    final isRepayment =
        isSystemRow && !tx.isLocked && (tx.category?.isDebtRepayment ?? false);
    // แบ่ง is edited on this page (owner 2026-11-03): a plain money row of
    // mine, or my bill row once the bill is read (and I may edit it).
    final canEditSplits =
        canEdit && _linkTabs && (!_inBill || (_paper?.paper.canEdit ?? false));
    final editing = isEditing;
    final created = tx.createdAt;
    final updated = tx.updatedAt;
    // An event bill opens on the event's board.
    final bill = tx.eventBill;
    final billEventId = _billEventId;
    void openProject() =>
        openPage(context, '/projects/$billEventId?bill=${bill?.billId}');

    final SplitEventSlot? eventSlot;
    final SplitRecurringSlot? recurringSlot;
    // The recurring link: the saved one (unless its removal is held), else a
    // held pick.
    final recurringItem = _unbooked ? null : tx.recurringItem;
    final savedLink = _pendingUnlink || recurringItem == null
        ? null
        : recurringItem;
    final recurringName = savedLink?.label(l.quickUpcomingHintTitle);
    void openRecurring() {
      final id = savedLink?.recurringId;
      if (id != null) openPage(context, '/recurring/$id');
    }

    if (editing) {
      eventSlot = SplitEventSlot(
        name: _eventName(l, tx),
        onTap: _pickEvent,
        onClear: _eventName(l, tx) == null ? null : _clearEvent,
      );
      recurringSlot = canEdit && !_unbooked
          ? _link.slot(
              context,
              type: _edited.type,
              linkedName: recurringName,
              onOpenLinked: null,
              onTap: _linkRecurring,
              onClear: _dropRecurring,
              onUnlink: _dropRecurring,
              error: _say,
              done: (m) => _say(m, tone: Tone.success),
            )
          : null;
    } else {
      final eventName = _eventName(l, tx);
      eventSlot = SplitEventSlot(
        name: eventName,
        onTap: eventName == null ? null : openProject,
        editing: false,
      );
      recurringSlot = recurringItem == null
          ? null
          : _link.slot(
              context,
              type: _edited.type,
              linkedName: recurringName,
              onOpenLinked: openRecurring,
              onTap: _longPressHint,
              editing: false,
              onLongPress: canEdit
                  ? () => _enterEdit(then: _linkRecurring)
                  : null,
              error: _say,
              done: (m) => _say(m, tone: Tone.success),
            );
    }

    // The bill page (owner 2026-11-17): the event as its own card, in its
    // colour; none yet = "เพิ่มในอีเวนต์".
    final eventName = _eventName(l, tx);
    final Widget? eventCard = _linkTabs && tx.type != TransactionType.transfer
        ? EventSectionCard(
            name: eventName,
            iconCode: switch (_eventChange) {
              ExistingEventTarget(:final project) => project.iconCode,
              null when billEventId != null => bill?.event.iconCode,
              _ => null,
            },
            editing: editing,
            locked: !canEdit,
            onTap: editing
                ? _pickEvent
                : eventName != null
                ? openProject
                : () => _enterEdit(then: _pickEvent),
            onClear: editing && eventName != null ? _clearEvent : null,
          )
        : null;
    // My books of the bill as switches, also while viewing: "จดหนี้บิลนี้เลย"
    // (an event bill) on the แบ่ง card, "ลงรายการของฉันเลย" on mine. Once
    // booked they stay on (nothing to undo here).
    final billPaper = _paper?.paper;
    final debts = _c.link.eventBookDebts;
    final Widget? debtsRow =
        billPaper != null && _mode == LinkMode.event && debts != null
        ? LinkSwitchRow(
            key: const ValueKey('linkBookDebtRow'),
            label: l.txLinkBookDebt,
            value: debts,
            onChanged: billPaper.myDebtIds.isNotEmpty || !canEdit
                ? null
                : (v) => _switchInEdit(() => _c.setEventBookDebts(v)),
          )
        : null;
    final Widget? mineRow = billPaper != null && !billPaper.isPayback
        ? LinkSwitchRow(
            key: const ValueKey('linkBookMineRow'),
            label: l.txLinkBookMine,
            value: _c.link.eventBookMine,
            onChanged: _unbooked && canEdit
                ? (v) => _switchInEdit(() => _c.setEventBookMine(v))
                : null,
          )
        : null;

    final metaLines = [
      if (tx.createdBy != null)
        l.txDetailMetaRecordedBy(tx.createdBy!.displayName),
      ...detailMetaLines(context, createdAt: created, updatedAt: updated),
    ];

    return editScope(
      BusyScope(
        busy: isSaving,
        child: AppPage(
          topBar: AppTopBar(
            title: _titleForType(l, tx.type),
            showBack: true,
            editing: editing,
            onBack: handleBack,
          ),
          body: Builder(
            builder: (context) {
              return CompactHeroScope(
                heroKey: _heroKey,
                bar: _compactBar(context),
                child: DetailPageBody(
                  onRefresh: () async {
                    try {
                      await context.read<TransactionsCubit>().refreshOne(tx.id);
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        showErrorSnackBar(context, e);
                      }
                    }
                  },
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  topInset:
                      MediaQuery.paddingOf(context).top + PpForgeSpacing.md,
                  bottomInset: 96 + MediaQuery.paddingOf(context).bottom,
                  // The form renders hero -> note -> tags -> the headed
                  // "แบ่งรายการ" section itself, so it is the whole hero.
                  hero: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isSystemRow) ...[
                        PpForgeMessage(
                          message: isRepayment
                              ? l.txDetailRepaymentBanner
                              : l.transactionDetailSystemRowBanner,
                          tone: Tone.info,
                        ),
                        const SizedBox(height: PpForgeSpacing.md),
                      ] else if (tx.isLocked) ...[
                        PpForgeMessage(
                          message: l.transactionFormLockedBanner,
                          tone: Tone.warning,
                        ),
                        const SizedBox(height: PpForgeSpacing.md),
                      ],
                      DraftForm(
                        controller: _c,
                        heroKey: _heroKey,
                        autofocus: false,
                        privateNote: widget.tx.privateNote,
                        // The type can't change after saving.
                        typeLocked: true,
                        // Quick create's cards (owner 2026-11-03).
                        detailCards: true,
                        allowSplits: canEditSplits,
                        editing: editing,
                        categoryLockedHint: _edited.canEditCategory
                            ? null
                            : l.transactionFormCategoryAuthorOnlyHint,
                        onEdit: canEdit ? _enterEdit : null,
                        onEnterEdit: canEdit
                            ? (f) => _enterEdit(focus: f)
                            : null,
                        onViewTap: _longPressHint,
                        eventSlot: eventSlot,
                        recurringSlot: recurringSlot,
                        linkTabs: _linkTabs,
                        linkEventIsNew: _eventChange is NewEventTarget,
                        eventPending:
                            _eventChange is NewEventTarget ||
                            _eventChange is ExistingEventTarget,
                        eventCard: eventCard,
                        debtsRow: debtsRow,
                        mineRow: mineRow,
                        myRows: !_unbooked || _c.link.eventBookMine,
                        // A name opens that person's debts (all of them,
                        // not this bill's piece).
                        onOpenPerson: editing || !_inBill
                            ? null
                            : (p) => openPage(
                                context,
                                debtPersonPath(
                                  debtPersonKey(
                                    contactId: p.contactId,
                                    name: p.name,
                                  ),
                                ),
                              ),
                      ),
                      // My row differs from its bill: "อัปเดตตาม".
                      if (!editing && !_unbooked)
                        LinkViewRows(
                          tx: tx,
                          onApplyEvent: canEdit ? _applyEvent : null,
                        ),
                    ],
                  ),
                  sections: const [],
                  manage: _unbooked
                      ? (editing && (billPaper?.canLeave ?? false)
                            ? ManageSection(
                                deleteLabel: l.evbLeaveTitle,
                                onDelete: isSaving
                                    ? null
                                    : () => _confirmDelete(context, l),
                              )
                            : null)
                      : (editing && canEdit) || isRepayment
                      ? ManageSection(
                          deleteLabel: l.transactionDeleteThis,
                          deleteConsequence: l.transactionDeleteConsequence,
                          onDelete: isSaving
                              ? null
                              : () => _confirmDelete(
                                  context,
                                  l,
                                  repayment: isRepayment,
                                ),
                        )
                      : null,
                  metaLines: metaLines,
                ),
              );
            },
          ),
          bottomBar: editing ? editActionBar(onSave: _save) : null,
        ),
      ),
    );
  }

  PpForgeCompactHeroCard _compactBar(BuildContext context) {
    final category = _c.isTransfer ? null : _c.category;
    return txCompactHeroBar(
      context,
      type: _c.type,
      description: _c.description.text,
      amount: _c.amountValue,
      categoryName: category == null
          ? _c.foreignCategoryName
          : categoryDisplayName(AppLocalizations.of(context)!, category),
      categoryIcon:
          category?.iconCode ??
          (category == null ? null : widget.tx.category?.iconCode),
      onTap: _scrollToTop,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l, {
    bool repayment = false,
  }) async {
    // 0.4.1-1: deleting my tx asks nothing about its links. A recurring
    // slot it filled is skipped (R2); an event bill stays, only my tx leaves
    // it (rule f).
    final tx = widget.tx;
    final isTransfer = tx.type == TransactionType.transfer;
    if (_unbooked) {
      // Nothing of mine to delete: I only leave the bill.
      final leave = await showConfirmDialog(
        context,
        title: l.evbLeaveTitle,
        confirmLabel: l.evbLeaveTitle,
        destructive: true,
      );
      if (leave && context.mounted) await _deleteNow(context, l);
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: isTransfer
          ? l.transactionDetailDeleteConfirmTitleTransfer
          : l.transactionDetailDeleteConfirmTitle,
      message: repayment
          ? l.txDetailDeleteRepaymentBody(moneyString(context, tx.amount))
          : isTransfer
          ? l.transactionDetailDeleteConfirmBodyTransfer
          : l.transactionDetailDeleteConfirmBody,
      confirmLabel: l.transactionDetailDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await _deleteNow(context, l, repayment: repayment);
  }

  Future<void> _deleteNow(
    BuildContext context,
    AppLocalizations l, {
    bool repayment = false,
  }) async {
    final tx = widget.tx;
    final router = GoRouter.of(context);
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final debts = DebtDirectoryCubit.maybeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    final projects = context.read<ProjectsRepository>();
    final bill = tx.eventBill;
    setSaving(true);
    try {
      if (bill != null) {
        // My bill row (owner 2026-11-03): leave the bill with my books
        // deleted; the last one out deletes the bill. The row rides effects.
        await projects.leavePaper(
          bill.billId,
          projectId: bill.event.isSplit ? null : bill.event.id,
          keepBooks: false,
        );
        if (!_unbooked) txCubit.dropRow(tx.id);
      } else {
        final result = await txCubit.remove(tx.id);
        applyTxDeleteResult(result, accounts: accountsCubit, debts: debts);
      }
      showPpForgeSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
      if (router.canPop()) {
        router.pop();
      } else {
        back?.call();
      }
    } on ApiException catch (e) {
      if (!mounted || !context.mounted) return;
      setSaving(false);
      showSaveFailure(
        context,
        e,
        retry: () => _deleteNow(context, l, repayment: repayment),
      );
    }
  }
}

String _titleForType(AppLocalizations l, TransactionType t) => switch (t) {
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};
