import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/idempotency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/paper.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/widgets/member_picker.dart';
import '../../../projects/presentation/widgets/project_common.dart'
    show memberAvatar;
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../recurring/data/recurring_link_repository.dart'
    show LinkCandidate;
import '../../../tags/domain/tag.dart';
import '../../domain/form_options.dart';
import '../../domain/link_draft.dart';
import '../../domain/refs.dart' show EmbeddedPerson;
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../paper_edit.dart';
import '../quick_create_bodies.dart';
import '../save_failure.dart';
import '../transaction_edit.dart';
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goals_overview.dart';
import 'debt_entry_form.dart';
import 'saving_entry_form.dart';
import 'draft_form.dart';
import 'event_pick.dart';
import 'event_picker.dart';
import 'recurring_link.dart';
import 'transaction_tile.dart';
import 'tx_summary_title.dart';

class EntrySheetAction {
  const EntrySheetAction({
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  final String label;
  final Future<bool> Function(PendingDraft draft) onPressed;

  final bool primary;
}

/// A chip above the form (ข้าม / จ่ายแล้ว / ผูกกับรายการที่มีอยู่). [onTap]
/// gets the sheet's context (a picker opens over it); true closes the sheet
/// as saved.
class EntrySheetChip {
  const EntrySheetChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Future<bool> Function(BuildContext sheetContext) onTap;
}

/// บันทึกในรายการ: [pick] chooses an existing transaction; nothing is written
/// until the main button, which then runs [apply] (true closes as saved).
class EntrySheetLink {
  const EntrySheetLink({required this.pick, required this.apply});

  final Future<Transaction?> Function(BuildContext sheetContext) pick;
  final Future<bool> Function(BuildContext sheetContext, Transaction tx) apply;
}

/// จ่ายแล้ว: a tick row (paid without a transaction). A change is written on
/// the main button by [apply] (with the form's edits); true closes as saved.
class EntrySheetPaid {
  const EntrySheetPaid({required this.initial, required this.apply});

  final bool initial;
  final Future<bool> Function(
    BuildContext sheetContext,
    bool paid,
    PendingDraft draft,
  )
  apply;
}

class EntrySheetConfig {
  const EntrySheetConfig({
    required this.title,
    required this.initial,
    required this.actions,
    this.onDelete,
    this.subtitle,
    this.chips = const [],
    this.barAction,
    this.link,
    this.createAction,
    this.paid,
    this.debtPerson,
  });

  final EntrySheetPaid? paid;

  /// A recurring หนี้ slot (0.4.1-2 K12): its person stands where the
  /// category is, and there are no tags. Null = a normal entry.
  final EmbeddedPerson? debtPerson;

  /// A tick row ([EntrySheetAction.label]); ticked, บันทึก runs this instead
  /// of the main action (an occurrence recorded now).
  final EntrySheetAction? createAction;

  final String title;
  final PendingDraft initial;
  final List<EntrySheetAction> actions;
  final Future<bool> Function()? onDelete;
  final String? subtitle;
  final List<EntrySheetChip> chips;

  /// A plain button at the bottom left (ข้าม / ยกเลิกจ่ายแล้ว).
  final EntrySheetChip? barAction;

  final EntrySheetLink? link;
}

Future<bool> showEntrySheet(
  BuildContext context, {
  required String title,
  required PendingDraft initial,
  required List<EntrySheetAction> actions,
  Future<bool> Function()? onDelete,
  String? subtitle,
  List<EntrySheetChip> chips = const [],
  EntrySheetChip? barAction,
  EntrySheetLink? link,
  EntrySheetAction? createAction,
  EntrySheetPaid? paid,
  EmbeddedPerson? debtPerson,
}) {
  assert(actions.isNotEmpty && actions.length <= 2, '1 or 2 actions');
  return showQuickCreateSheet(
    context,
    entry: EntrySheetConfig(
      title: title,
      initial: initial,
      actions: actions,
      onDelete: onDelete,
      subtitle: subtitle,
      chips: chips,
      barAction: barAction,
      link: link,
      createAction: createAction,
      paid: paid,
      debtPerson: debtPerson,
    ),
  );
}

/// Opens a committed tx for editing: its page in edit mode, a bill row too
/// (owner 2026-11-03: edit is the page, not a sheet).
void editTransaction(BuildContext context, String id) =>
    openPage(context, '/transactions/$id/edit');

Future<bool> showQuickCreateSheet(
  BuildContext context, {
  QuickCreatePreset? preset,
  ValueChanged<DebtEntryWriteResult>? onDebtSaved,
  ValueChanged<SavingWriteResult>? onSavingSaved,
  PendingTransaction? draft,
  Account? account,
  Account? toAccount,
  TransactionType? type,
  Category? category,
  Tag? tag,
  double? amount,
  DebtEntryDirection? debtDirection,
  DebtEntrySub? debtSub,
  EntrySheetConfig? entry,
  EventBillPreset? eventBill,
}) async {
  amount ??= eventBill?.amount;
  account ??= preset?.account;
  category ??= preset?.category;
  tag ??= preset?.tag;
  final options = context.read<TxFormOptionsCubit>();
  unawaited(options.loadIfNeeded());
  if (!context.mounted) return false;
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    sheetAnimationStyle: PpForgePageMotion.sheetStyle,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole shell, wherever it's opened from: inside a tab it would
    // sit under the floating nav (the tab body runs on beneath it).
    useRootNavigator: true,
    enableDrag: false,
    // The shell paints the sheet itself (the mode's wash).
    backgroundColor: QuickCreateSheetShell.modalBackground,
    builder: (sheetContext) {
      final sheet = _QuickCreateSheet(
        prefs: prefs,
        draft: draft,
        account: account,
        initialToAccount: toAccount,
        initialType: type,
        initialCategory: category,
        initialTag: tag,
        initialMode: preset?.mode ?? QuickCreateMode.tx,
        lockMode: preset != null,
        debtPerson: preset?.person == null
            ? null
            : DebtPick(
                key: debtPersonKey(
                  contactId: preset!.person!.contactId,
                  name: preset.person!.name,
                ),
                person: preset.person!,
              ),
        onDebtSaved: onDebtSaved,
        onSavingSaved: onSavingSaved,
        savingGoalId: preset?.goalId,
        entry: entry,
        initialAmount: amount ?? preset?.amount,
        initialDebtDirection: debtDirection ?? preset?.debtDirection,
        initialDebtSub: debtSub ?? preset?.debtSub,
        eventBill: eventBill,
      );
      return BlocProvider<TxFormOptionsCubit>.value(
        value: options,
        child: sheet,
      );
    },
  );
  return saved ?? false;
}

/// The event's add bill (owner 2026-11-03): quick create for ONE event,
/// fixed (its name where the mode tabs stand, "คืนเงิน" where "โอนเงิน"
/// stands). [payback] opens on "คืนเงิน" from [fromMemberId] to
/// [toMemberId] for [amount] (a summary line).
class EventBillPreset {
  const EventBillPreset({
    required this.project,
    this.payback = false,
    this.fromMemberId,
    this.toMemberId,
    this.amount,
    this.edit,
  });

  /// The bill's event; null = a split bill (only when editing one).
  final Project? project;
  final bool payback;
  final String? fromMemberId;
  final String? toMemberId;
  final double? amount;

  /// Editing this bill (the same form; owner 2026-11-03).
  final PaperView? edit;
}

/// Opens an existing bill (event or split) in the quick create form: loads
/// the paper (and its event) first. True = saved / left.
Future<bool> openPaperBill(
  BuildContext context,
  String paperId, {
  String? projectId,
}) async {
  final repo = context.read<ProjectsRepository>();
  final l = AppLocalizations.of(context)!;
  final PaperView paper;
  Project? project;
  try {
    paper = await repo.getPaper(paperId, projectId: projectId);
    final pid = paper.projectId;
    if (pid != null) project = await repo.get(pid);
  } on ApiException catch (e) {
    if (context.mounted) {
      showPpForgeSnackBar(context, errorText(l, e), tone: Tone.danger);
    }
    return false;
  }
  if (!context.mounted) return false;
  return showQuickCreateSheet(
    context,
    eventBill: EventBillPreset(
      project: project,
      edit: paper,
      payback: paper.isPayback,
    ),
  );
}

enum _CloseChoice { draft, keepEditing, discard }

/// The sheet's own picks beside the form, for an undo step.
typedef _SheetPicks = ({
  Account? account,
  Account? toAccount,
  Category? category,
  String? projectId,
  EventTarget? event,
  List<ProjectMember>? members,
  bool payback,
  String? from,
  String? to,
  LinkCandidate? recurring,
  Transaction? entryTx,
  Object? beforeEntryTx,
  bool entryCreate,
  bool entryPaid,
});

/// One undo step of the รายการ form: everything on it, so undo takes back
/// any action, a pick as much as a typed field.
@immutable
class _SheetDraft {
  const _SheetDraft(this.tx, this.bill, this.picks);

  final PendingDraft tx;
  final BillState bill;
  final _SheetPicks picks;

  /// Only my own text fields differ from [o] (a typing burst).
  bool sameButText(_SheetDraft o) =>
      bill == o.bill &&
      picks == o.picks &&
      tx.type == o.tx.type &&
      tx.date == o.tx.date &&
      tx.accountId == o.tx.accountId &&
      tx.categoryId == o.tx.categoryId &&
      tx.transferToAccountId == o.tx.transferToAccountId &&
      listEquals(tx.tagIds, o.tx.tagIds);

  @override
  bool operator ==(Object other) =>
      other is _SheetDraft &&
      other.tx == tx &&
      other.bill == bill &&
      other.picks == picks;

  @override
  int get hashCode => Object.hash(tx, bill, picks);
}

class _QuickCreateSheet extends StatefulWidget {
  const _QuickCreateSheet({
    required this.prefs,
    this.draft,
    this.account,
    this.initialToAccount,
    this.initialType,
    this.initialCategory,
    this.initialTag,
    this.initialMode = QuickCreateMode.tx,
    this.lockMode = false,
    this.debtPerson,
    this.onDebtSaved,
    this.onSavingSaved,
    this.savingGoalId,
    this.entry,
    this.initialAmount,
    this.initialDebtDirection,
    this.initialDebtSub,
    this.eventBill,
  });
  final SharedPreferences prefs;

  final EventBillPreset? eventBill;

  final Account? account;

  final Account? initialToAccount;

  final TransactionType? initialType;

  final Category? initialCategory;

  final Tag? initialTag;

  final QuickCreateMode initialMode;

  /// The page the sheet opens from chose its mode (owner 2026-11-12): no
  /// tx / debt / saving tabs to switch.
  final bool lockMode;

  final DebtPick? debtPerson;
  final ValueChanged<DebtEntryWriteResult>? onDebtSaved;

  final ValueChanged<SavingWriteResult>? onSavingSaved;

  final String? savingGoalId;

  final EntrySheetConfig? entry;

  final double? initialAmount;
  final DebtEntryDirection? initialDebtDirection;
  final DebtEntrySub? initialDebtSub;

  /// Editing this pending draft instead of creating.
  final PendingTransaction? draft;

  @override
  State<_QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<_QuickCreateSheet> {
  final _c = DraftFormController();

  EventTarget? _event;

  /// The event's add bill: "คืนเงิน" picked, and who → who.
  bool _payback = false;
  String? _fromMemberId;
  String? _toMemberId;

  final _link = RecurringLinkHandle();

  /// The event pick, unless it's a transfer (kept for switching back).
  EventTarget? get _activeEvent => typeCanJoinEvent(_c.type) ? _event : null;
  bool _saving = false;

  /// Retry after a timeout sends the same keys: never saved twice (B2).
  final _idempotency = Idempotency();

  final _heroKey = GlobalKey();

  bool get _editingDraft => widget.draft != null;

  bool get _isSavingDraft => widget.draft?.isSaving ?? false;

  bool get _isEntry => widget.entry != null;

  bool get _draftLike => _editingDraft || _isEntry;

  /// A draft as first shown — after prefill, so the defaults it fills in
  /// (today, expense) for a draft without them don't count as edits.
  PendingDraft? _draftBaseline;

  bool get _dirty => _draftLike
      ? _draftBaseline != null &&
            _c.toDraft(keepIncomplete: true) != _draftBaseline
      : _paperEdit
      ? _paperBaseline != null && _paperSnapshot() != _paperBaseline
      : _hasKeyData;

  bool get _paperEdit => widget.eventBill?.edit != null;

  /// An edited bill as first shown (after prefill and the form options), so
  /// only a real change asks before closing.
  String? _paperBaseline;

  /// Everything an edit would send: the paper, my claim, the marks, the
  /// payback people.
  String _paperSnapshot() {
    final b = paperBodies(_c, _linkMode, personIds: _personIds);
    return jsonEncode([
      b?.paper,
      b?.myBooks,
      b?.skipMyBooks,
      b?.paidBack,
      _fromMemberId,
      _toMemberId,
      _c.amountValue,
      _c.account?.id,
    ]);
  }

  /// Takes [_paperBaseline] once the options are in and the prefill's
  /// post-frame fields (category, wallet) are set.
  void _snapPaperBaselineWhenReady() {
    void snap() => WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _paperBaseline = _paperSnapshot());
    });
    final opts = maybeTxFormOptions(context, watch: false);
    if (opts == null || !opts.state.isLoading) {
      snap();
      return;
    }
    opts.stream
        .firstWhere((s) => !s.isLoading)
        .then((_) => snap())
        .catchError((Object _) {});
  }

  bool get _hasKeyData =>
      _c.amountValue > 0 || _c.description.text.trim().isNotEmpty;

  /// A new entry with nothing in it — its save buttons are off, and a save that
  /// slips through just closes (never an empty draft).
  bool get _isEmpty => !_draftLike && !_c.hasContent && _event == null;

  @override
  void initState() {
    super.initState();
    _link.addListener(_onLinkChanged);
    // A new bill offers "จดหนี้บิลนี้เลย" (off: the event's lump) once it
    // has an event.
    if (!_draftLike) _c.link.eventBookDebts = false;
    final type = widget.initialType;
    if (type != null) _c.setType(type);
    final toAccount = widget.initialToAccount;
    if (toAccount != null) {
      _c
        ..setType(TransactionType.transfer)
        ..setToAccount(toAccount);
    }
    if (widget.initialAmount != null && widget.draft == null) {
      _c.amount.text = _amountText(widget.initialAmount);
    }
    final category = widget.initialCategory;
    if (category != null) {
      _c
        ..setType(
          category.type == CategoryType.income
              ? TransactionType.income
              : TransactionType.expense,
        )
        ..setCategory(category);
    }
    final tag = widget.initialTag;
    if (tag != null) {
      _c.knownTags[tag.id] = tag;
      _c.setTagIds({tag.id});
    }
    if (_draftLike) _prefillDraftWhenReady();
    final eventBill = widget.eventBill;
    if (eventBill != null) {
      final project = eventBill.project;
      final target = project == null ? null : ExistingEventTarget(project);
      _event = target;
      _payback = eventBill.payback;
      _fromMemberId = eventBill.fromMemberId;
      _toMemberId = eventBill.toMemberId;
      _c.setLinkMode(LinkMode.split, hasEvent: target != null);
      final edit = eventBill.edit;
      if (edit != null) {
        _prefillPaper(edit);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _snapPaperBaselineWhenReady();
        });
      }
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_loadEventMembers(target));
        });
      }
    }
    _c.addListener(() {
      if (mounted) setState(_track);
    });
    unawaited(_startHistory());
  }

  /// The รายการ form's undo steps; null until the form is filled in as
  /// first shown (options, prefill, default wallet), so none of that is one.
  EditDraft<_SheetDraft>? _history;
  bool _restoring = false;
  bool _batching = false;
  Timer? _typing;

  Future<void> _startHistory() async {
    final opts = maybeTxFormOptions(context, watch: false);
    if (opts != null && opts.state.isLoading) {
      try {
        await opts.stream.firstWhere((s) => !s.isLoading);
      } on Object {
        return;
      }
    }
    // The prefill lands, then the form's own first-frame fills.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _history != null) return;
    setState(() => _history = EditDraft(_snap()));
  }

  _SheetDraft _snap() =>
      _SheetDraft(_c.toDraft(keepIncomplete: true), _c.bill(), (
        account: _c.account,
        toAccount: _c.toAccount,
        category: _c.category,
        projectId: _c.projectId,
        event: _event,
        members: _eventMembers,
        payback: _payback,
        from: _fromMemberId,
        to: _toMemberId,
        recurring: _link.candidate,
        entryTx: _entryTx,
        beforeEntryTx: _beforeEntryTx,
        entryCreate: _entryCreate,
        entryPaid: _entryPaid,
      ));

  /// Records what just changed as an undo step (a typing burst is one).
  /// Call inside setState.
  void _track() {
    final h = _history;
    if (h == null || _restoring || _batching) return;
    final next = _snap();
    final w = h.working;
    if (next == w) return;
    if (next.sameButText(w)) {
      final field = next.tx.note != w.tx.note
          ? 'note'
          : next.tx.description != w.tx.description
          ? 'description'
          : 'amount';
      h.textChange(field, next);
      _typing?.cancel();
      _typing = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(h.commitSession);
      });
    } else {
      _typing?.cancel();
      h.change(next);
    }
  }

  /// Several changes as one step; [amend] folds them into the last step
  /// (what follows from it, not a new action).
  void _batch(void Function() fn, {bool amend = false}) {
    _batching = true;
    try {
      fn();
    } finally {
      _batching = false;
    }
    if (!mounted) return;
    setState(() {
      final h = _history;
      if (!amend) return _track();
      if (h != null && !_restoring) h.amend(_snap());
    });
  }

  bool get _canUndo => !_isDebt && !_isSaving && (_history?.canUndo ?? false);

  void _undo() {
    final h = _history;
    if (h == null || !h.canUndo) return;
    HapticFeedback.selectionClick();
    _typing?.cancel();
    h.undo();
    final d = h.working;
    final p = d.picks;
    _restoring = true;
    try {
      _c.restoreTransaction(
        d.tx,
        accounts: [?p.account, ?p.toAccount],
        categories: [?p.category],
      );
      _c.projectId = p.projectId;
      _c.restoreBill(d.bill);
      _link.restore(p.recurring);
    } finally {
      _restoring = false;
    }
    setState(() {
      _event = p.event;
      _eventMembers = p.members;
      _payback = p.payback;
      _fromMemberId = p.from;
      _toMemberId = p.to;
      _entryTx = p.entryTx;
      _beforeEntryTx =
          p.beforeEntryTx
              as ({
                String amount,
                DateTime date,
                Account? account,
                Category? category,
              })?;
      _entryCreate = p.entryCreate;
      _entryPaid = p.entryPaid;
    });
  }

  void _prefillDraftWhenReady() {
    final opts = maybeTxFormOptions(context, watch: false);
    if (opts == null || !opts.state.isLoading) {
      _prefillDraft();
      return;
    }
    opts.stream
        .firstWhere((s) => !s.isLoading)
        .then((_) {
          if (!mounted) return;
          _prefillDraft();
          setState(() {});
        })
        .catchError((Object _) {});
  }

  void _prefillDraft() {
    final entry = widget.entry;
    if (entry != null) {
      final options = maybeTxFormOptions(context, watch: false)?.state.options;
      _c.prefill(
        entry.initial,
        accounts: [
          ...?options?.accountList,
          if (options == null) ...context.read<AccountsCubit>().state.accounts,
        ],
        categories: [
          ...?options?.categoryList,
          if (options == null)
            ...context.read<CategoriesCubit>().state.categories,
        ],
      );
      _draftBaseline = _c.toDraft(keepIncomplete: true);
      return;
    }
    final p = widget.draft;
    if (p != null) {
      final options = maybeTxFormOptions(context, watch: false)?.state.options;
      final accounts = [
        ...?options?.accountList,
        if (options == null) ...context.read<AccountsCubit>().state.accounts,
      ];
      final categories = [
        ...?options?.categoryList,
        if (options == null)
          ...context.read<CategoriesCubit>().state.categories,
      ];
      final ra = p.resolved.account;
      if (ra != null && !accounts.any((a) => a.id == ra.id)) {
        accounts.add(ra.toAccount());
      }
      final rto = p.resolved.transferToAccount;
      if (rto != null && !accounts.any((a) => a.id == rto.id)) {
        accounts.add(rto.toAccount());
      }
      final rc = p.resolved.category;
      if (rc != null && !categories.any((c) => c.id == rc.id)) {
        categories.add(rc.toCategory());
      }
      if (p.isSaving) {
        _prefillSavingDraft(p, accounts);
        return;
      }
      _c.prefill(p.draft, accounts: accounts, categories: categories);
      // Reopens on the tab it was saved with (0.4.0-3).
      _c.prefillLinkFromDraft(p.draft, p.resolved);
      _draftBaseline = _c.toDraft(keepIncomplete: true);
    }
  }

  Future<void> _saveDraft() async {
    final l = AppLocalizations.of(context)!;
    if (_isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    if (!mounted) return;
    // A new entry saves the tab on screen; อีเวนต์ needs an event that
    // already exists (a draft can't make one).
    if (!_draftLike && DraftFormController.hasLinkTabs(_c.type)) {
      _c.link.mode ??= _linkMode;
    }
    final event = _activeEvent;
    if (_c.pickedTab == LinkMode.event && event is NewEventTarget) {
      HapticFeedback.lightImpact();
      _toast(l.txLinkDraftNeedsExistingEvent);
      return;
    }
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final d = _c.toDraft(
        keepIncomplete: true,
        eventProjectId: event is ExistingEventTarget ? event.project.id : null,
      );
      final p = widget.draft;
      if (p == null) {
        await pending.add([d]);
      } else {
        await pending.updateDraft(p.id, d);
      }
      await _remember();
      navigator.pop(true);
      showPpForgeSnackBarOn(
        messenger,
        l.pendingSavedAsDraft,
        tone: Tone.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveDraft);
    }
  }

  Future<void> _submitDraft() async {
    final l = AppLocalizations.of(context)!;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    if (!await _confirmIncompleteSplits()) return;
    if (!mounted) return;
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.draft!.id;
    setState(() => _saving = true);
    try {
      await pending.updateDraft(id, _c.toDraft());
      final result = await pending.submitOne(id);
      final failed = result.failed[id];
      if (failed != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(errorTextForCode(l, failed.code));
        return;
      }
      accounts.patchBalances(result.accountBalances);
      await _remember();
      navigator.pop(true);
      showPpForgeSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _submitDraft);
    }
  }

  String? _savBaseline;

  String _savSnapshot() => [
    _sav.amount.text,
    _sav.account?.id,
    _sav.goalId,
    _ymd(_sav.date),
    _sav.note.text,
  ].join('|');

  void _prefillSavingDraft(PendingTransaction p, List<Account> accounts) {
    final d = p.draft;
    _sav.amount.text = _amountText(d.amount);
    _sav.note.text = d.note ?? '';
    final date = d.date == null ? null : DateTime.tryParse(d.date!);
    if (date != null) _sav.date = date;
    _sav.goalId = d.goalId;
    final ra = p.resolved.account;
    if (ra != null && !accounts.any((a) => a.id == ra.id)) {
      accounts.add(ra.toAccount());
    }
    _sav.account = [
      ...context.read<AccountsCubit>().state.accounts,
      ...accounts,
    ].where((a) => a.id == d.accountId).firstOrNull;
    _draftBaseline = const PendingDraft(isSaving: true);
    _savBaseline = _savSnapshot();
  }

  PendingDraft _savingDraft() => PendingDraft(
    isSaving: true,
    goalId: _sav.goalId,
    amount: _sav.amountValue > 0 ? _sav.amountValue : null,
    accountId: _sav.account?.id,
    date: _ymd(_sav.date),
    note: _sav.note.text.trim().isEmpty ? null : _sav.note.text.trim(),
  );

  Future<void> _saveSavingDraft() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await pending.updateDraft(widget.draft!.id, _savingDraft());
      navigator.pop(true);
      showPpForgeSnackBarOn(
        messenger,
        l.pendingSavedAsDraft,
        tone: Tone.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveSavingDraft);
    }
  }

  Future<void> _submitSavingDraft() async {
    final l = AppLocalizations.of(context)!;
    final s = _sav;
    final problem = s.amountValue <= 0 ? l.quickAmountRequired : null;
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.draft!.id;
    setState(() => _saving = true);
    try {
      await pending.updateDraft(id, _savingDraft());
      final result = await pending.submitOne(id);
      final failed = result.failed[id];
      if (failed != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(errorTextForCode(l, failed.code));
        return;
      }
      accounts.patchBalances(result.accountBalances);
      navigator.pop(true);
      showPpForgeSnackBarOn(messenger, l.savingEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _submitSavingDraft);
    }
  }

  EntrySheetAction _entryAction({required bool primary}) {
    final actions = widget.entry!.actions;
    return actions.lastWhere((a) => a.primary, orElse: () => actions.last);
  }

  EntrySheetAction? get _entrySecondary {
    final actions = widget.entry?.actions ?? const [];
    if (actions.length < 2) return null;
    final main = _entryAction(primary: true);
    return actions.firstWhere((a) => !identical(a, main));
  }

  Future<void> _runEntryChip(EntrySheetChip chip) async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await chip.onTap(context);
    if (!mounted) return;
    if (ok) {
      navigator.pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  /// The transaction picked in บันทึกในรายการ (written on the main button),
  /// and the form's own values it covers in the hero meanwhile.
  Transaction? _entryTx;
  ({String amount, DateTime date, Account? account, Category? category})?
  _beforeEntryTx;

  Future<void> _pickEntryTx() async {
    final link = widget.entry?.link;
    if (link == null) return;
    final tx = await link.pick(context);
    if (tx == null || !mounted) return;
    final opts = maybeTxFormOptions(context, watch: false)?.state.options;
    final accounts =
        opts?.accountList ?? context.read<AccountsCubit>().state.accounts;
    final categories =
        opts?.categoryList ?? context.read<CategoriesCubit>().state.categories;
    _batch(() {
      _beforeEntryTx ??= (
        amount: _c.amount.text,
        date: _c.date,
        account: _c.account,
        category: _c.category,
      );
      _c.amount.text = AmountInput.format(tx.amount);
      _c.setDate(DateTime.tryParse(tx.date) ?? _c.date);
      _c.setAccount(
        accounts.where((a) => a.id == tx.accountId).firstOrNull ??
            tx.account?.toAccount(),
      );
      _c.setCategory(
        categories.where((c) => c.id == tx.categoryId).firstOrNull ??
            tx.category?.toCategory(),
      );
      _entryTx = tx;
    });
  }

  void _clearEntryTx() {
    _batch(() {
      final was = _beforeEntryTx;
      if (was != null) {
        _c.amount.text = was.amount;
        _c.setDate(was.date);
        _c.setAccount(was.account);
        _c.setCategory(was.category);
      }
      _entryTx = null;
      _beforeEntryTx = null;
    });
  }

  Future<void> _runEntryLink() async {
    final link = widget.entry!.link!;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await link.apply(context, _entryTx!);
    if (!mounted) return;
    if (ok) {
      navigator.pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  /// สร้างรายการใหม่ ticked: บันทึก records the transaction now.
  bool _entryCreate = false;

  /// จ่ายแล้ว as ticked now (written on บันทึก when it changed).
  late bool _entryPaid = widget.entry?.paid?.initial ?? false;

  bool get _entryPaidChanged {
    final paid = widget.entry?.paid;
    return paid != null && _entryPaid != paid.initial;
  }

  Future<void> _runEntryPaid() async {
    final paid = widget.entry!.paid!;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await paid.apply(context, _entryPaid, _c.toDraft());
    if (!mounted) return;
    if (ok) {
      navigator.pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  /// สร้างรายการใหม่ (a tick), บันทึกในรายการ and จ่ายแล้ว (a tick): each
  /// settles the occurrence, so each locks the others.
  Widget? _entryRows(AppLocalizations l) {
    final entry = widget.entry;
    if (entry == null) return null;
    final tx = _entryTx;
    final create = entry.createAction;
    final paid = entry.paid;
    final rows = <Widget>[
      if (create != null)
        DraftFieldRow(
          label: create.label,
          dense: true,
          child: SelectCheck(
            value: _entryCreate,
            onTap: _saving || tx != null || _entryPaid
                ? null
                : () => setState(() {
                    _entryCreate = !_entryCreate;
                    _track();
                  }),
          ),
        ),
      if (paid != null)
        DraftFieldRow(
          key: const ValueKey('entryPaidRow'),
          label: l.occurrenceMarkPaid,
          dense: true,
          child: SelectCheck(
            value: _entryPaid,
            onTap: _saving || tx != null || _entryCreate
                ? null
                : () => setState(() {
                    _entryPaid = !_entryPaid;
                    _track();
                  }),
          ),
        ),
      if (entry.link != null)
        DraftFieldRow(
          label: l.occurrenceRecordInTx,
          dense: true,
          child: tx == null
              ? PpForgeChip(
                  label: l.occurrenceLinkPick,
                  icon: AppIcons.add,
                  tone: PpForgeChipTone.primary,
                  selected: true,
                  dashed: true,
                  onTap: _saving || _entryCreate || _entryPaid
                      ? null
                      : _pickEntryTx,
                )
              // The picked one as its list row: tap picks again, ✕ takes it
              // off.
              : PickedRowFrame(
                  onTap: _saving ? null : _pickEntryTx,
                  onRemove: _saving ? null : _clearEntryTx,
                  removeTooltip: l.commonRemove,
                  child: TransactionTile(transaction: tx, showDate: true),
                ),
        ),
    ];
    if (rows.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: PpForgeSpacing.sm),
          r,
        ],
      ],
    );
  }

  Widget? _entryChips() {
    final chips = widget.entry?.chips ?? const [];
    if (chips.isEmpty) return null;
    return Wrap(
      spacing: PpForgeSpacing.sm,
      runSpacing: PpForgeSpacing.sm,
      children: [
        for (final c in chips)
          PpForgeChip(
            label: c.label,
            icon: c.icon,
            // Each one writes at once.
            enabled: !ConnectionScope.isOffline(context),
            onTap: _saving ? null : () => _runEntryChip(c),
          ),
      ],
    );
  }

  Future<void> _runEntry(EntrySheetAction action) async {
    final l = AppLocalizations.of(context)!;
    if (_c.amountValue <= 0) {
      HapticFeedback.lightImpact();
      _toast(l.quickAmountRequired);
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await action.onPressed(_c.toDraft());
    if (!mounted) return;
    if (ok) {
      navigator.pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteEntry() async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await widget.entry!.onDelete!();
    if (!mounted) return;
    if (ok) {
      navigator.pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _discardDraft() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l.pendingDiscardTitle,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _discardNow(pending, navigator);
  }

  Future<void> _discardNow(
    PendingCubit pending,
    NavigatorState navigator,
  ) async {
    setState(() => _saving = true);
    try {
      await pending.discard(widget.draft!.id);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: () => _discardNow(pending, navigator));
    }
  }

  @override
  void dispose() {
    _typing?.cancel();
    _c.dispose();
    _link.dispose();
    _debt.dispose();
    _sav.dispose();
    super.dispose();
  }

  late QuickCreateMode _mode = _isSavingDraft
      ? QuickCreateMode.saving
      : _canSwitchMode
      ? widget.initialMode
      : QuickCreateMode.tx;
  late final DebtEntryController _debt =
      DebtEntryController(
          person: widget.debtPerson,
          sub: widget.initialDebtSub ?? DebtEntrySub.record,
        )
        ..direction = widget.initialDebtDirection ?? DebtEntryDirection.paid
        ..account = widget.account
        ..amount.text = _amountText(widget.initialAmount)
        ..addListener(_onDebtChanged);

  late final SavingEntryController _sav =
      SavingEntryController(goalId: widget.savingGoalId)
        ..account = widget.account
        ..amount.text = _amountText(widget.initialAmount)
        ..addListener(_onDebtChanged);

  static String _amountText(double? v) => v == null || v <= 0
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  void _onDebtChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSwitchMode => !_draftLike && widget.eventBill == null;

  /// The mode's colour (sheet wash, hero card, mode tab) while the sheet
  /// creates something new; null elsewhere.
  Color? get _modeColor => widget.eventBill != null
      // An event's bill: the sheet takes the event's own colour (its icon's,
      // as on its page; owner 2026-11-03), as a mode takes its own; a split
      // bill the รายการ mode's.
      ? (widget.eventBill!.project == null
            ? QuickCreateModeColors.of(context, QuickCreateMode.tx)
            : _eventColor(widget.eventBill!.project!))
      : _canSwitchMode
      ? QuickCreateModeColors.of(context, _mode)
      : null;
  Color _eventColor(Project p) =>
      p.iconCode.tintFor(Theme.of(context).extension<PpForgeColors>()!);

  bool get _isDebt => _mode == QuickCreateMode.debt;
  bool get _isSaving => _mode == QuickCreateMode.saving;

  (TextEditingController, TextEditingController, TextEditingController?)
  _fieldsOf(QuickCreateMode m) => switch (m) {
    QuickCreateMode.debt => (_debt.amount, _debt.description, _debt.note),
    QuickCreateMode.saving => (_sav.amount, _sav.note, null),
    _ => (_c.amount, _c.description, _c.note),
  };

  DateTime _dateOf(QuickCreateMode m) => switch (m) {
    QuickCreateMode.debt => _debt.date,
    QuickCreateMode.saving => _sav.date,
    _ => _c.date,
  };

  void _setDateOf(QuickCreateMode m, DateTime d) {
    switch (m) {
      case QuickCreateMode.debt:
        _debt.setDate(d);
      case QuickCreateMode.saving:
        _sav.setDate(d);
      default:
        _c.setDate(d);
    }
  }

  /// The text carried into the รายการ form is part of the switch, not an
  /// undo step.
  void _switchMode(QuickCreateMode m) =>
      _batch(() => _switchModeNow(m), amend: true);

  void _switchModeNow(QuickCreateMode m) {
    if (m == _mode) return;
    final from = _fieldsOf(_mode);
    final to = _fieldsOf(m);
    // The debt tab's description is worked out by its form, and its amount may
    // be the open balance it filled in: neither is something typed, so neither
    // is carried to another tab (and no other tab's text is carried into it).
    final debtInvolved =
        _mode == QuickCreateMode.debt || m == QuickCreateMode.debt;
    if (!(_mode == QuickCreateMode.debt && _debt.amountIsAuto)) {
      to.$1.text = from.$1.text;
    }
    if (!debtInvolved) to.$2.text = from.$2.text;
    final toNote = to.$3;
    final fromNote = from.$3;
    if (toNote != null && fromNote != null) toNote.text = fromNote.text;
    _setDateOf(m, _dateOf(_mode));
    setState(() => _mode = m);
  }

  Widget _modeChips(AppLocalizations l) => Padding(
    padding: const EdgeInsets.only(bottom: PpForgeSpacing.sm),
    child: QuickCreateModeTabs(
      mode: _mode,
      labels: {
        QuickCreateMode.tx: l.quickModeTx,
        QuickCreateMode.debt: l.quickModeDebt,
        QuickCreateMode.saving: l.quickModeSaving,
      },
      onChanged: _saving ? null : _switchMode,
    ),
  );

  Future<void> _saveDebt() async {
    final l = AppLocalizations.of(context)!;
    final d = _debt;
    final person = d.person;
    // The person first: description and amount can be typed before picking.
    final problem = person == null
        ? l.debtCounterpartyRequired
        : d.amountValue <= 0
        ? l.quickAmountRequired
        : null;
    if (problem != null || person == null) {
      HapticFeedback.lightImpact();
      _toast(problem!);
      return;
    }
    // Settling more than what's open flips the side: say it once.
    if (d.repaying && d.overpays && !_overpayWarned) {
      _overpayWarned = true;
      final go = await showChoiceDialog<bool>(
        context,
        title: l.debtOverpayTitle,
        message: l.debtOverpayWarn(_debtAfterWords(l, d)),
        choices: [
          DialogChoice(
            value: true,
            label: l.debtOverpayConfirm,
            variant: PpForgeButtonVariant.primary,
          ),
          DialogChoice(value: false, label: l.debtOverpayEdit),
        ],
      );
      if (go != true || !mounted) return;
    }
    if (d.repaying) return _saveRepayment(d, person);
    final repo = context.read<PersonalDebtsRepository>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final debtDirectory = context.read<DebtDirectoryCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final body = debtRecordBody(d, person);
    setState(() => _saving = true);
    try {
      final r = await repo.createEntry(
        body.key,
        direction: body.direction,
        amount: body.amount,
        date: body.date,
        accountId: body.accountId,
        createTransaction: body.createTransaction,
        linkTransactionId: body.linkTransactionId,
        description: body.description,
        note: body.note,
        tagIds: body.tagIds,
        personName: body.personName,
        dueDate: body.dueDate,
      );
      accounts.patchBalances(r.accountBalances);
      final tx = r.transaction;
      if (tx != null) txCubit.patchRow(tx, afterWrite: true);
      widget.onDebtSaved?.call(r);
      debtDirectory.applyBalance(r.balance);
      navigator.pop(true);
      showPpForgeSnackBarOn(messenger, l.debtEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveDebt);
    }
  }

  bool _overpayWarned = false;

  /// "ลี กลายเป็นลูกหนี้ ฿40": the person's side after the settle (preview,
  /// else the app's own sum).
  String _debtAfterWords(AppLocalizations l, DebtEntryController d) {
    final after = d.preview?.after ?? d.netAfter ?? 0;
    if (after.abs() <= 0.004) return '✓ ${l.debtRepayCleared}';
    final money = moneyString(
      context,
      after.abs(),
      symbol: debtCurrencySymbol(context),
    );
    final name = d.person?.person.name ?? l.debtSomeone;
    final words = after > 0
        ? l.debtSummaryBecomesDebtor(name)
        : l.debtSummaryBecomesCreditor(name);
    return '$words $money';
  }

  /// จ่ายคืน / รับคืน: a person-book row (0.4.1-1 D3), its transaction as
  /// "บันทึกในรายการ" says; the answer patches the wallet, the transactions
  /// list and the debts list.
  Future<void> _saveRepayment(DebtEntryController d, DebtPick person) async {
    final l = AppLocalizations.of(context)!;
    final repo = context.read<PersonalDebtsRepository>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final debtDirectory = context.read<DebtDirectoryCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final body = debtRepaymentBody(d, person);
    setState(() => _saving = true);
    try {
      final r = await repo.createRepayment(
        body.key,
        kind: body.kind,
        amount: body.amount,
        accountId: body.accountId,
        createTransaction: body.createTransaction,
        linkTransactionId: body.linkTransactionId,
        date: body.date,
        description: body.description,
        note: body.note,
        tagIds: body.tagIds,
        markPaidIds: body.markPaidIds,
        markAllPaid: body.markAllPaid,
        personName: body.personName,
      );
      accounts.patchBalances(r.accountBalances);
      final tx = r.transaction;
      if (tx != null) txCubit.patchRow(tx, afterWrite: true);
      widget.onDebtSaved?.call(r);
      debtDirectory.applyBalance(r.balance);
      navigator.pop(true);
      showPpForgeSnackBarOn(messenger, l.debtEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveDebt);
    }
  }

  Future<void> _saveSaving() async {
    final l = AppLocalizations.of(context)!;
    final s = _sav;
    final problem = s.amountValue <= 0 ? l.quickAmountRequired : null;
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final repo = context.read<SavingGoalsRepository>();
    final accounts = context.read<AccountsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final body = savingSaveBody(s);
    setState(() => _saving = true);
    try {
      final r = await repo.addEntry(
        kind: body.kind,
        amount: body.amount,
        date: body.date,
        goalId: body.goalId,
        walletId: body.walletId,
        note: body.note,
      );
      accounts.patchSavings(r.walletSavings);
      widget.onSavingSaved?.call(r);
      navigator.pop(true);
      showPpForgeSnackBarOn(messenger, l.savingEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveSaving);
    }
  }

  /// A หนี้ slot's person, read-only (the setting decides it), where the
  /// category card would be.
  Widget? _debtPersonCard(AppLocalizations l) {
    final p = widget.entry?.debtPerson;
    if (p == null) return null;
    return PickCard(
      label: l.debtPersonPickerTitle,
      value: p.name,
      placeholder: l.debtPickPerson,
      dense: true,
      editable: false,
      onTap: null,
      leading: PersonMark(
        level: debtPersonLevel(p),
        avatar: p.avatar,
        size: 32,
      ),
    );
  }

  Account? _defaultAccount(List<Account> accounts, {TxFormOptions? options}) {
    final preset = widget.account;
    if (preset != null) {
      return accounts.where((a) => a.id == preset.id).firstOrNull ?? preset;
    }
    if (accounts.isEmpty) return null;
    final fromServer = options?.defaultAccount;
    if (fromServer != null) return fromServer;
    final last = widget.prefs.getString(StorageKeys.lastAccountId);
    return accounts.where((a) => a.id == last).firstOrNull ?? accounts.first;
  }

  Future<void> _remember() async {
    final acc = _c.account;
    if (acc != null) {
      await widget.prefs.setString(StorageKeys.lastAccountId, acc.id);
    }
  }

  void _onLinkChanged() {
    if (mounted) setState(_track);
  }

  Future<void> _pickRecurring() => _link.choose(
    context,
    type: _c.type,
    categoryId: _c.isTransfer ? null : _c.category?.id,
    amount: _c.amountValue > 0 ? _c.amountValue : null,
    txDate: _c.date,
    createRoute: recurringCreateRoute(
      type: _c.type,
      amount: _c.amountValue,
      categoryId: _c.isTransfer ? null : _c.category?.id,
      accountId: _c.account?.id,
      name: _c.description.text,
    ),
  );

  Future<String?> _linkAfterCreate(String? txId) async {
    if (txId == null || _link.candidateFor(_c.type) == null) return null;
    String? warn;
    final r = await _link.link(context, txId, error: (m) => warn = m);
    if (r == null || !mounted) return warn;
    await askRecurringAmountAfterCreate(
      context,
      _link,
      error: (m) => warn = m,
      done: (_) {},
    );
    return warn;
  }

  Future<void> _pickEvent() async {
    final picked = await EventPicker.one(
      context,
      suggestedName: _suggestEventName(),
      selectedProjectId: switch (_event) {
        ExistingEventTarget(:final project) => project.id,
        _ => null,
      },
      showClosed: false,
      useRootNavigator: false,
    );
    if (picked != null && mounted) {
      _batch(() {
        _event = picked;
        _eventMembers = null;
        _c.eventChanged(hasEvent: true);
      });
      unawaited(_loadEventMembers(picked));
    }
  }

  /// The picked existing event's members: who in the bill is "ใหม่ ·
  /// เพิ่มเข้าอีเวนต์" (be-A: members carry my `contact_id`). One call per
  /// pick; a failure just leaves the tags off.
  List<ProjectMember>? _eventMembers;

  Future<void> _loadEventMembers(EventTarget target) async {
    _eventMembers = null;
    if (target is! ExistingEventTarget) return;
    final projects = context.read<ProjectsRepository>();
    try {
      final members = await projects.listMembers(target.project.id);
      if (!mounted || !identical(_event, target)) return;
      // Part of the event pick: undo takes them back with it.
      _batch(() {
        _eventMembers = members;
        // The event's people join a new bill (after whoever is already in
        // it); an edited bill keeps its own people.
        if (widget.eventBill?.edit == null) {
          _c.addPeople(DraftFormController.peopleOfMembers(members));
        }
      }, amend: true);
    } on ApiException {
      // No tags; the save still adds whoever isn't a member.
    }
  }

  /// The bill being edited (owner 2026-11-03: the same form as quick
  /// create); null = a new entry.
  late final PaperEditSession? _paperSession = switch (widget.eventBill?.edit) {
    final p? => PaperEditSession(p),
    null => null,
  };

  Map<String, String> get _personIds => _paperSession?.personIds ?? const {};

  void _prefillPaper(PaperView p) {
    final session = _paperSession!;
    session.prefill(context, _c);
    if (p.isPayback) {
      _fromMemberId = session.fromMemberId;
      _toMemberId = session.toMemberId;
    }
  }

  /// Saves the edited bill (the shared session), then closes.
  Future<void> _saveEdit(AppLocalizations l, PaperView edit) async {
    final projects = context.read<ProjectsRepository>();
    final txs = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    String? warn;
    try {
      final ok = await _paperSession!.save(
        projects: projects,
        txs: txs,
        c: _c,
        mode: _linkMode,
      );
      if (!ok) {
        if (!mounted) return;
        setState(() => _saving = false);
        HapticFeedback.lightImpact();
        _toast(l.evbPaybackNeedsPeople);
        return;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.code == 'BILL_CHANGED') {
        warn = l.evbBillChangedReopen;
      } else {
        showSaveFailure(context, e, retry: _save, message: errorText(l, e));
        return;
      }
    }
    navigator.pop(true);
    showPpForgeSnackBarOn(
      messenger,
      warn ?? l.quickSaved,
      tone: warn == null ? Tone.success : Tone.warning,
    );
  }

  /// ออกจากบิล: keep my books of it as plain records, or delete them.
  Future<void> _leaveBill(PaperView edit) async {
    final l = AppLocalizations.of(context)!;
    final keep = await showActionSheet<bool>(
      context,
      header: ActionSheetHeader(title: l.evbLeaveTitle),
      actions: [
        SheetAction(
          value: true,
          icon: AppIcons.save,
          label: l.evbLeaveKeepBooks,
        ),
        SheetAction(
          value: false,
          icon: AppIcons.delete,
          label: l.evbLeaveDeleteBooks,
          destructive: true,
        ),
      ],
    );
    if (keep == null || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await context.read<ProjectsRepository>().leavePaper(
        edit.id,
        projectId: edit.projectId,
        keepBooks: keep,
      );
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) _toast(errorText(l, e));
    }
  }

  /// "คืนเงิน" on an event: a payback paper (who paid = the whole amount,
  /// who got it = a share of it); my book takes the wallet when I'm in it.
  Future<void> _savePayback(AppLocalizations l) async {
    final from = _member(_fromMemberId);
    final to = _member(_toMemberId);
    final amount = _c.amountValue;
    if (from == null || to == null || from.id == to.id || amount <= 0) {
      HapticFeedback.lightImpact();
      _toast(l.evbPaybackNeedsPeople);
      return;
    }
    final projects = context.read<ProjectsRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final d = _c.date;
    String two(int n) => n.toString().padLeft(2, '0');
    final edit = widget.eventBill!.edit;
    // An edit keeps the two rows (by member).
    String? rowOf(String memberId) =>
        edit?.people.where((p) => p.memberId == memberId).firstOrNull?.id;
    final paper = {
      'type': 'payback',
      'payback_kind': 'payback',
      'amount': amount,
      'date': '${d.year}-${two(d.month)}-${two(d.day)}',
      'split_mode': 'custom',
      'people': [
        {
          'member_id': from.id,
          'person_id': ?rowOf(from.id),
          'paid': amount,
          'share': 0,
        },
        {
          'member_id': to.id,
          'person_id': ?rowOf(to.id),
          'paid': 0,
          'share': amount,
        },
      ],
    };
    setState(() => _saving = true);
    try {
      await _idempotency.run(
        () => edit != null
            ? projects.updatePaper(
                edit.id,
                projectId: edit.projectId,
                paper: paper,
                version: edit.version,
              )
            : projects.createPaper(
                projectId: widget.eventBill!.project!.id,
                paper: paper,
                myBooks: {'account_id': _c.account?.id},
              ),
      );
      navigator.pop(true);
      showPpForgeSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _save, message: errorText(l, e));
    }
  }

  ProjectMember? _member(String? id) =>
      _eventMembers?.where((m) => m.id == id).firstOrNull;

  /// "คืนเงิน" on an event's bill: who paid whom back, as the transfer's
  /// from → to cards (members of the event).
  Widget _paybackCard(AppLocalizations l) {
    Widget card(String? id, String label, ValueChanged<String> set) {
      final m = _member(id);
      return PickCard(
        label: label,
        value: m?.displayName,
        placeholder: l.quickEventNone,
        leading: m == null
            ? const PpForgeIcon(AppIcons.member)
            : memberAvatar(m, size: 32),
        dense: true,
        editable: true,
        onTap: () async {
          final members = _eventMembers;
          if (members == null) return;
          final picked = await EventMemberPicker.one(
            context,
            members: members,
            selectedId: id,
            title: label,
          );
          if (picked != null && mounted) {
            setState(() {
              set(picked.id);
              _track();
            });
          }
        },
      );
    }

    return FlowCards(
      from: card(_fromMemberId, l.quickFrom, (id) => _fromMemberId = id),
      to: card(_toMemberId, l.quickTo, (id) => _toMemberId = id),
      swapTooltip: l.quickSwap,
      onSwap: () => setState(() {
        final from = _fromMemberId;
        _fromMemberId = _toMemberId;
        _toMemberId = from;
        _track();
      }),
    );
  }

  bool Function(LinkPerson p)? get _isEventMember {
    final members = _eventMembers;
    if (members == null || _event is! ExistingEventTarget) return null;
    return (p) => members.any(
      (m) => p.isMember(
        name: m.displayName,
        contactId: m.contactId,
        userId: m.userId,
      ),
    );
  }

  String _suggestEventName() {
    final l = AppLocalizations.of(context)!;
    final names = _c.splits
        .where((s) => s.personName.trim().isNotEmpty)
        .map((s) => s.personName.trim())
        .toList();
    final date = DateFormatter.medium(
      _c.date,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    return names.isEmpty
        ? '${l.quickEventDefaultName} | $date'
        : '${names.join(', ')} | $date';
  }

  Future<void> _confirmClose() async {
    final l = AppLocalizations.of(context)!;
    final editing = _draftLike || _paperEdit;
    final choice = await showChoiceDialog<_CloseChoice>(
      context,
      title: editing ? l.editDiscardTitle : l.quickUnsavedTitle,
      message: editing ? l.editDiscardMessage : l.quickUnsavedMessage,
      choices: [
        // An event bill has no draft (owner 2026-11-03).
        if (!editing && widget.eventBill == null)
          DialogChoice(
            value: _CloseChoice.draft,
            label: l.pendingKeepAsDraft,
            variant: PpForgeButtonVariant.primary,
          ),
        DialogChoice(value: _CloseChoice.keepEditing, label: l.editKeepEditing),
        DialogChoice(
          value: _CloseChoice.discard,
          label: editing ? l.editDiscardConfirm : l.quickDiscardEntry,
          variant: PpForgeButtonVariant.destructive,
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case _CloseChoice.draft:
        await _saveDraft();
      case _CloseChoice.discard:
        Navigator.of(context).pop(false);
      case _CloseChoice.keepEditing || null:
        break;
    }
  }

  Future<bool> _confirmIncompleteSplits() =>
      confirmIncompleteSplits(context, _c);

  void _toast(String msg) =>
      showPpForgeSnackBar(context, msg, tone: Tone.danger);

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Every rule the server would reject, said here first.
  String? _problem(AppLocalizations l) {
    if (_c.amountValue <= 0) return l.quickAmountRequired;
    if (_c.isTransfer) {
      final from = _c.account, to = _c.toAccount;
      // One side is enough: from only = ถอนเงิน, to only = เพิ่มเงิน.
      if (from == null && to == null) return l.txTransferNeedsOneWallet;
      if (!_transferOneSide && (from == null || to == null)) {
        return l.txTransferNeedsTo;
      }
      if (from != null && to != null && from.id == to.id) {
        return l.txTransferSameWallet;
      }
    }
    final mode = _linkMode;
    if (!_c.isTransfer && mode == LinkMode.split) {
      final splitTotal = _c.splits
          .where((s) => s.isComplete)
          .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
      if (splitTotal > _c.amountValue + 0.005) return l.txSplitExceeds;
      if (!_c.splitsBalanced) return l.txSplitUnbalanced;
    }
    if (!_c.isTransfer && mode == LinkMode.paid) {
      if (_c.link.paidBy == null) return l.txLinkModeNeedsPayer;
      if (!_c.linkBalanced(mode)) return l.txLinkModeUnbalanced;
      if (_c.saveAmountFor(mode) <= 0) return l.quickAmountRequired;
    }
    if (!_c.isTransfer &&
        mode != LinkMode.personal &&
        _c.markedWithoutName(mode)) {
      return l.debtCounterpartyRequired;
    }
    if (!_c.isTransfer &&
        mode == LinkMode.split &&
        _c.account == null &&
        _c.paidBackShares(event: false).isNotEmpty) {
      return l.txPaidBackNeedsWallet;
    }
    if (!_c.isTransfer && mode == LinkMode.event) {
      if (!_hasEvent) return l.txLinkModeNeedsEvent;
      if (_c.pickedTab != null && !_c.linkBalanced(mode)) {
        return l.txLinkModeUnbalanced;
      }
    }
    if (_c.account == null &&
        !_c.isTransfer &&
        mode == LinkMode.event &&
        _c.linkSave(mode).useWallet) {
      return l.quickEventNeedsWallet;
    }
    return null;
  }

  /// The ผูกกับ tab in use (inferred until one is picked).
  LinkMode get _linkMode => _c.linkMode(hasEvent: _hasEvent);

  /// A draft / an edit keeps its event on the form; a new entry on the sheet.
  bool get _hasEvent =>
      _draftLike ? _c.projectId != null : _activeEvent != null;

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    if (widget.eventBill != null && _payback) return _savePayback(l);
    if (widget.eventBill?.edit case final edit?) return _saveEdit(l, edit);
    // The tab on screen is what's saved, picked or not (the tabs show for
    // an expense / income here).
    if (DraftFormController.hasLinkTabs(_c.type)) _c.link.mode ??= _linkMode;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    // Half-typed แบ่ง rows matter only when แบ่ง is what's saved.
    final otherTab = _c.pickedTab != null && _linkMode != LinkMode.split;
    if (!otherTab && !await _confirmIncompleteSplits()) return;
    if (!mounted) return;
    final txCubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    final projects = context.read<ProjectsRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Only the active ผูกกับ tab is saved (owner 2026-10-21).
    final mode = _linkMode;
    final event = mode == LinkMode.event && !_c.isTransfer
        ? _activeEvent
        : null;
    final txBody = txCreateBody(_c, mode);
    // แบ่ง = ONE paper (paper model): a split bill, or an event bill when an
    // event is picked. The paper, my claim and every member's copy in one
    // call; the rows / wallets / debts follow the answer's effects.
    final paper = mode == LinkMode.event && event == null
        ? null
        : paperBodies(_c, mode);

    setState(() => _saving = true);
    String? warn;
    String? newTxId;
    try {
      await _idempotency.run(() async {
        if (paper != null) {
          final result = await projects.createPaper(
            projectId: switch (event) {
              ExistingEventTarget(:final project) => project.id,
              _ => null,
            },
            // A new event is made with its first bill, in the same call.
            newEvent: switch (event) {
              NewEventTarget(:final name) => name,
              _ => null,
            },
            paper: paper.paper,
            myBooks: paper.myBooks,
            skipMyBooks: paper.skipMyBooks,
          );
          newTxId = result.transactionId;
          // "คืนแล้ว" is a mark on the paper, set once the people exist.
          try {
            for (final i in paper.paidBack) {
              if (i >= result.personIds.length) continue;
              await projects.markPaperPaidBack(
                result.paperId,
                result.personIds[i],
                projectId: result.projectId,
              );
            }
          } on ApiException catch (e) {
            warn = errorText(l, e);
          }
        } else {
          final saved = await txCubit.add(
            type: txBody.type,
            accountId: txBody.accountId,
            amount: txBody.amount,
            date: txBody.date,
            categoryId: txBody.categoryId,
            description: txBody.description,
            note: txBody.note,
            transferToAccountId: txBody.transferToAccountId,
            tagIds: txBody.tagIds,
          );
          accounts.patchBalances(saved.accountBalances);
          newTxId = saved.rows.firstOrNull?.id;
        }
        warn ??= await _linkAfterCreate(newTxId);
      });
      await _remember();
      navigator.pop(true);
      showPpForgeSnackBarOn(
        messenger,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _save, message: errorText(l, e));
    }
  }

  bool get _summaryTitle => !_draftLike;

  /// A new transfer or a draft's may have one wallet only; a recurring
  /// occurrence keeps both.
  bool get _transferOneSide => !_isEntry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final opts = maybeTxFormOptions(context);
    final optState = opts?.state;
    final options = optState?.options;
    final accounts = opts == null
        ? context.watch<AccountsCubit>().state.accounts
        : (options?.accountList ?? const <Account>[]);
    // Options not here yet: saving now would drop the wallet and category.
    final waiting = opts != null && options == null;

    return QuickCreateSheetShell(
      heroKey: _heroKey,
      title: _isEntry
          ? widget.entry!.title
          : _paperEdit
          ? l.transactionFormTitleEdit
          : _editingDraft
          ? l.pendingEditTitle
          : _isDebt
          ? l.quickCreateBtnDebt
          : _isSaving
          ? l.quickCreateBtnSaving
          : l.transactionFormTitleNew,
      tint: _modeColor,
      subtitle: widget.entry?.subtitle,
      headerBar: _entryChips(),
      summaryBuilder: _summaryTitle && !_isDebt && !_isSaving
          ? (scrollToTop) => TxSummaryTitle(
              type: _c.type,
              amount: _c.amountValue,
              category: _c.isTransfer ? null : _c.category,
              onTap: scrollToTop,
            )
          : null,
      closeTooltip: l.commonClose,
      deleteTooltip: widget.eventBill?.edit != null
          ? l.evbLeaveTitle
          : l.commonDelete,
      onDelete: widget.eventBill?.edit != null
          ? (widget.eventBill!.edit!.canLeave
                ? () => _leaveBill(widget.eventBill!.edit!)
                : null)
          : _isEntry
          ? (widget.entry!.onDelete == null ? null : _deleteEntry)
          : _editingDraft
          ? _discardDraft
          : null,
      saving: _saving,
      dirty: _isSavingDraft
          ? _savBaseline != null && _savSnapshot() != _savBaseline
          : _isDebt
          ? _debt.hasKeyData
          : _isSaving
          ? _sav.hasKeyData
          : _dirty,
      onCloseBlocked: _confirmClose,
      onUndo: _canUndo ? _undo : null,
      undoTooltip: l.commonUndo,
      barActionLabel: widget.entry?.barAction?.label,
      barActionIcon: widget.entry?.barAction?.icon,
      draftIcon: _isEntry ? AppIcons.save : null,
      saveIcon: _isEntry ? AppIcons.save : null,
      onBarAction: widget.entry?.barAction == null
          ? null
          : () => _runEntryChip(widget.entry!.barAction!),
      // One word for every entry: บันทึก records, links or keeps the edits.
      saveLabel: _isEntry
          ? _entryAction(primary: true).label
          : (_editingDraft ? l.pendingSubmitThis : l.quickSave),
      // A picked transaction settles the occurrence: no draft save beside it.
      draftLabel: _isEntry
          ? (_entryTx != null ? null : _entrySecondary?.label)
          : _isDebt ||
                widget.eventBill != null ||
                (_isSaving && !_isSavingDraft)
          ? null
          : l.pendingSaveDraft,
      onSave: _isEntry
          ? (waiting
                ? null
                : _entryTx != null
                ? _runEntryLink
                : _entryPaidChanged
                ? _runEntryPaid
                : _entryCreate && widget.entry!.createAction != null
                ? () => _runEntry(widget.entry!.createAction!)
                : () => _runEntry(_entryAction(primary: true)))
          : _isSavingDraft
          ? _submitSavingDraft
          : _isDebt
          ? _saveDebt
          : _isSaving
          ? _saveSaving
          : (_isEmpty || waiting
                ? null
                : (_editingDraft ? _submitDraft : _save)),
      // A draft can't go to an event.
      onSaveDraft: _isEntry
          ? (_entrySecondary == null || _saving || waiting
                ? null
                : () => _runEntry(_entrySecondary!))
          : _isSavingDraft
          ? (_saving ? null : _saveSavingDraft)
          : _isDebt ||
                _isSaving ||
                // An event's bill is saved on the event, never as a draft.
                widget.eventBill != null ||
                _saving ||
                // A draft keeps every tab's data (0.4.0-3); only a new event
                // is refused, with a word, on the tap.
                _isEmpty ||
                waiting
          ? null
          : _saveDraft,
      body: _withModes(
        l,
        () => waiting && optState!.status == TxFormOptionsStatus.error
            ? Padding(
                padding: const EdgeInsets.only(top: PpForgeSpacing.xl),
                child: ErrorView(error: optState.error!, onRetry: opts.load),
              )
            : _draftLike && _draftBaseline == null
            ? const EntryCardSkeleton()
            : DraftForm(
                heroKey: _heroKey,
                accentColor: _modeColor,
                chipLayout: _draftLike,
                chipRows: true,
                controller: _c,
                defaultAccount: _defaultAccount(accounts, options: options),
                // An entry keeps its type: the occurrence API takes none.
                typeLocked: _isEntry,
                // An entry saves a PendingDraft: no splits there.
                allowSplits: !_isEntry,
                transferOneSide: _transferOneSide,
                rowAboveNote: _isEntry ? _entryRows(l) : null,
                debtPersonCard: _debtPersonCard(l),
                heroLocked: _entryTx != null,
                // An occurrence keeps no event: its section saved nothing.
                linkSections: !_isEntry,
                eventPending: _activeEvent != null,
                // ผูกกับ (0.4.0-3): a new expense; the form shows the tabs.
                linkTabs: !_draftLike || _editingDraft,
                linkEventIsNew: _event is NewEventTarget,
                linkIsEventMember: _isEventMember,
                recurringSlot: widget.eventBill == null
                    ? _recurringSlot(l)
                    : null,
                eventBill: widget.eventBill == null
                    ? null
                    : EventBillForm(
                        payback: _payback,
                        onPayback: (v) => setState(() {
                          _payback = v;
                          _track();
                        }),
                        paybackCard: _paybackCard(l),
                      ),
                eventSlot: !_draftLike && typeCanJoinEvent(_c.type)
                    ? SplitEventSlot(
                        name: eventTargetName(l, _event),
                        onTap: _pickEvent,
                        onClear: _event == null
                            ? null
                            : () => _batch(() {
                                _event = null;
                                _c.eventChanged(hasEvent: false);
                              }),
                      )
                    : null,
              ),
      ),
    );
  }

  SplitRecurringSlot? _recurringSlot(AppLocalizations l) {
    if (_draftLike) return null;
    return _link.slot(
      context,
      type: _c.type,
      onTap: _pickRecurring,
      onClear: _link.clear,
      error: _toast,
      done: _toast,
    );
  }

  Widget _withModes(AppLocalizations l, Widget Function() txBody) {
    if (_isSavingDraft) {
      return _draftBaseline == null
          ? const EntryCardSkeleton()
          : SavingEntryForm(controller: _sav, heroKey: _heroKey);
    }
    final eventBill = widget.eventBill;
    if (eventBill != null) {
      // Where the mode tabs stand: the event, fixed.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: PpForgeSpacing.sm),
            child: QuickCreateContextBar(
              caption: eventBill.project == null ? null : l.quickEventLabel,
              label: eventBill.project?.name ?? l.evbSplitBill,
              icon: eventBill.project == null
                  ? AppIcons.split
                  : AppIcons.project,
              color: _modeColor!,
            ),
          ),
          txBody(),
        ],
      );
    }
    if (!_canSwitchMode) {
      return txBody();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.lockMode) _modeChips(l),
        if (_isDebt)
          DebtEntryForm(controller: _debt, heroKey: _heroKey, autofocus: true)
        else if (_isSaving)
          SavingEntryForm(controller: _sav, heroKey: _heroKey, autofocus: true)
        else
          txBody(),
      ],
    );
  }
}
