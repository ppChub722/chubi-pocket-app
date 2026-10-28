import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/widgets/event_bill_sheet.dart'
    show openEventBill;
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../pending/presentation/pending_errors.dart';
import '../../../tags/domain/tag.dart';
import '../../domain/form_options.dart';
import '../../domain/link_draft.dart';
import '../../domain/refs.dart' show EmbeddedPerson;
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../delete_results.dart';
import '../event_book_body.dart';
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

/// Opens a committed tx for editing (0.4.1-2 SA1, the one router): its
/// shared bill's form when the BE says so ([txEditsAsBill]), the quick
/// create sheet when it is a plain one ([txEditsInSheet]), else its detail
/// page. True = saved or deleted in a sheet.
Future<bool> editTransaction(BuildContext context, String id) async {
  final cubit = context.read<TransactionsCubit>();
  var tx = cubit.byId(id);
  if (tx == null) {
    try {
      tx = await cubit.refreshOne(id);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
      return false;
    }
  }
  if (!context.mounted) return false;
  final bill = tx.eventBill;
  if (bill != null && txEditsAsBill(tx)) {
    return openEventBill(context, bill.billId);
  }
  if (!txEditsInSheet(tx)) {
    openPage(context, '/transactions/$id');
    return false;
  }
  return showQuickCreateSheet(context, editTransaction: tx);
}

Future<bool> showQuickCreateSheet(
  BuildContext context, {
  Transaction? editTransaction,
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
}) async {
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
        editTransaction: editTransaction,
        draft: draft,
        account: account,
        initialToAccount: toAccount,
        initialType: type,
        initialCategory: category,
        initialTag: tag,
        initialMode: preset?.mode ?? QuickCreateMode.tx,
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
      );
      return BlocProvider<TxFormOptionsCubit>.value(
        value: options,
        child: sheet,
      );
    },
  );
  return saved ?? false;
}

enum _CloseChoice { draft, keepEditing, discard }

class _QuickCreateSheet extends StatefulWidget {
  const _QuickCreateSheet({
    required this.prefs,
    this.editTransaction,
    this.draft,
    this.account,
    this.initialToAccount,
    this.initialType,
    this.initialCategory,
    this.initialTag,
    this.initialMode = QuickCreateMode.tx,
    this.debtPerson,
    this.onDebtSaved,
    this.onSavingSaved,
    this.savingGoalId,
    this.entry,
    this.initialAmount,
    this.initialDebtDirection,
    this.initialDebtSub,
  });
  final SharedPreferences prefs;

  final Account? account;

  final Account? initialToAccount;

  final TransactionType? initialType;

  final Category? initialCategory;

  final Tag? initialTag;

  final QuickCreateMode initialMode;

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

  /// Editing this committed (plain) tx instead of creating.
  final Transaction? editTransaction;

  @override
  State<_QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<_QuickCreateSheet> {
  final _c = DraftFormController();

  EventTarget? _event;

  final _link = RecurringLinkHandle();

  /// The event pick, unless it's a transfer (kept for switching back).
  EventTarget? get _activeEvent => typeCanJoinEvent(_c.type) ? _event : null;
  bool _saving = false;

  final _heroKey = GlobalKey();

  bool get _editingDraft => widget.draft != null;

  bool get _isSavingDraft => widget.draft?.isSaving ?? false;

  bool get _isEntry => widget.entry != null;

  bool get _isEditTx => widget.editTransaction != null;

  bool get _draftLike => _editingDraft || _isEntry || _isEditTx;

  /// A draft as first shown — after prefill, so the defaults it fills in
  /// (today, expense) for a draft without them don't count as edits.
  PendingDraft? _draftBaseline;

  bool get _dirty => _draftLike
      ? _draftBaseline != null &&
            (_c.toDraft(keepIncomplete: true) != _draftBaseline ||
                _linkEdit.changed)
      : _hasKeyData;

  /// Editing a saved tx: the ผูกกับ tabs, as on tx detail (owner: the SAME
  /// form everywhere; 0.4.0-3 B3).
  late final _linkEdit = LinkEditSession(_c);

  bool get _hasKeyData =>
      _c.amountValue > 0 || _c.description.text.trim().isNotEmpty;

  /// A new entry with nothing in it — its save buttons are off, and a save that
  /// slips through just closes (never an empty draft).
  bool get _isEmpty => !_draftLike && !_c.hasContent && _event == null;

  @override
  void initState() {
    super.initState();
    _link.addListener(_onLinkChanged);
    // A new bill offers "จดหนี้ด้วย" (on) once it has an event.
    if (!_draftLike) _c.link.eventBookDebts = true;
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
    _c.addListener(() {
      if (mounted) setState(() {});
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
    final tx = widget.editTransaction;
    if (tx != null) {
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
      final account = tx.account;
      if (account != null && !accounts.any((a) => a.id == account.id)) {
        accounts.add(account.toAccount());
      }
      final category = tx.category;
      if (category != null && !categories.any((c) => c.id == category.id)) {
        categories.add(category.toCategory());
      }
      _c.prefillTransaction(tx, accounts: accounts, categories: categories);
      _linkEdit.start(tx);
      _draftBaseline = _c.toDraft(keepIncomplete: true);
      return;
    }
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
      showAppSnackBarOn(messenger, l.pendingSavedAsDraft, tone: Tone.success);
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
        _toast(pendingErrorText(l, failed));
        return;
      }
      accounts.patchBalances(result.accountBalances);
      await _remember();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
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
      showAppSnackBarOn(messenger, l.pendingSavedAsDraft, tone: Tone.success);
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
        _toast(pendingErrorText(l, failed));
        return;
      }
      accounts.patchBalances(result.accountBalances);
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.savingEntrySaved, tone: Tone.success);
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
    _beforeEntryTx ??= (
      amount: _c.amount.text,
      date: _c.date,
      account: _c.account,
      category: _c.category,
    );
    final opts = maybeTxFormOptions(context, watch: false)?.state.options;
    final accounts =
        opts?.accountList ?? context.read<AccountsCubit>().state.accounts;
    final categories =
        opts?.categoryList ?? context.read<CategoriesCubit>().state.categories;
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
    setState(() => _entryTx = tx);
  }

  void _clearEntryTx() {
    final was = _beforeEntryTx;
    if (was != null) {
      _c.amount.text = was.amount;
      _c.setDate(was.date);
      _c.setAccount(was.account);
      _c.setCategory(was.category);
    }
    setState(() {
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
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SelectCheck(
              value: _entryCreate,
              onTap: _saving || tx != null || _entryPaid
                  ? null
                  : () => setState(() => _entryCreate = !_entryCreate),
            ),
          ),
        ),
      if (paid != null)
        DraftFieldRow(
          key: const ValueKey('entryPaidRow'),
          label: l.occurrenceMarkPaid,
          dense: true,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SelectCheck(
              value: _entryPaid,
              onTap: _saving || tx != null || _entryCreate
                  ? null
                  : () => setState(() => _entryPaid = !_entryPaid),
            ),
          ),
        ),
      if (entry.link != null)
        DraftFieldRow(
          label: l.occurrenceRecordInTx,
          dense: true,
          child: tx == null
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppChip(
                    label: l.occurrenceLinkPick,
                    icon: AppIcons.add,
                    tone: AppChipTone.primary,
                    selected: true,
                    dashed: true,
                    onTap: _saving || _entryCreate || _entryPaid
                        ? null
                        : _pickEntryTx,
                  ),
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
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          r,
        ],
      ],
    );
  }

  Widget? _entryChips() {
    final chips = widget.entry?.chips ?? const [];
    if (chips.isEmpty) return null;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final c in chips)
          AppChip(
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

  Future<void> _saveEditTx() async {
    final l = AppLocalizations.of(context)!;
    final tx = widget.editTransaction!;
    final problem = transactionEditProblem(
      l,
      _c,
      splitsEditable: false,
      checkSplits: _linkEdit.onSplitTab,
      savedAmount: widget.editTransaction?.amount,
    );
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    // A ผูกกับ tab switch: preview + ONE confirm, then it rides in the PUT.
    final changed = _linkEdit.changed;
    final link = changed
        ? await _linkEdit.prepare(
            context,
            t: tx,
            event: _event,
            initialAccountId: tx.accountId,
            accounts: [
              ...?maybeTxFormOptions(
                context,
                watch: false,
              )?.state.options?.accountList,
              ?tx.account?.toAccount(),
            ],
            retry: _saveEditTx,
          )
        : null;
    if (changed && link == null) return;
    if (!mounted) return;
    final ask = await askLinkedTxSave(context, tx);
    if (ask.cancelled || !mounted) return;
    final alsoUpdateLink = ask.alsoUpdateLink;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final outcome = await saveTransactionEdit(
        context,
        t: tx,
        c: _c,
        initialAccountId: tx.accountId,
        initialToAccountId: null,
        alsoUpdateLink: alsoUpdateLink,
        link: link,
      );
      HapticFeedback.mediumImpact();
      navigator.pop(true);
      showAppSnackBarOn(
        messenger,
        outcome.warning ?? l.quickSaved,
        tone: outcome.warning == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(
        context,
        e,
        retry: _saveEditTx,
        message: splitErrorMessage(l, e) ?? walletErrorMessage(l, e),
      );
    }
  }

  /// A recurring slot the tx filled is skipped by the server (R2): no ask.
  Future<void> _deleteEditTx() async {
    final l = AppLocalizations.of(context)!;
    final tx = widget.editTransaction!;
    final ok = await showConfirmDialog(
      context,
      title: l.transactionDetailDeleteConfirmTitle,
      message: l.transactionDetailDeleteConfirmBody,
      confirmLabel: l.transactionDetailDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final txCubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final result = await txCubit.remove(tx.id);
      applyTxDeleteResult(result, accounts: accounts);
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _deleteEditTx);
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

  bool get _canSwitchMode => !_draftLike;

  /// The mode's colour (sheet wash, hero card, mode tab) while the sheet
  /// creates something new; null elsewhere.
  Color? get _modeColor =>
      _canSwitchMode ? QuickCreateModeColors.of(context, _mode) : null;
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

  void _switchMode(QuickCreateMode m) {
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
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            variant: AppButtonVariant.primary,
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
      showAppSnackBarOn(messenger, l.debtEntrySaved, tone: Tone.success);
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
      showAppSnackBarOn(messenger, l.debtEntrySaved, tone: Tone.success);
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
      showAppSnackBarOn(messenger, l.savingEntrySaved, tone: Tone.success);
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
        name: p.name,
        level: debtPersonLevel(p),
        iconCode: p.iconCode,
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
    if (mounted) setState(() {});
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
      setState(() => _event = picked);
      _c.eventChanged(hasEvent: true);
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
      setState(() => _eventMembers = members);
      // The event's people join the bill (after whoever is already in it).
      _c.addPeople(DraftFormController.peopleOfMembers(members));
    } on ApiException {
      // No tags; the save still adds whoever isn't a member.
    }
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
    final editing = _draftLike;
    final choice = await showChoiceDialog<_CloseChoice>(
      context,
      title: editing ? l.editDiscardTitle : l.quickUnsavedTitle,
      message: editing ? l.editDiscardMessage : l.quickUnsavedMessage,
      choices: [
        if (!editing)
          DialogChoice(
            value: _CloseChoice.draft,
            label: l.pendingKeepAsDraft,
            variant: AppButtonVariant.primary,
          ),
        DialogChoice(value: _CloseChoice.keepEditing, label: l.editKeepEditing),
        DialogChoice(
          value: _CloseChoice.discard,
          label: editing ? l.editDiscardConfirm : l.quickDiscardEntry,
          variant: AppButtonVariant.destructive,
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

  void _toast(String msg) => showAppSnackBar(context, msg, tone: Tone.danger);

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Every rule the server would reject, said here first.
  String? _problem(AppLocalizations l) {
    if (_c.amountValue <= 0) return l.quickAmountRequired;
    if (_c.isTransfer) {
      if (_c.account == null || _c.toAccount == null) {
        return l.txTransferNeedsTo;
      }
      if (_c.account!.id == _c.toAccount!.id) return l.txTransferSameWallet;
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
    final tagIds = _c.tagIds.toList();
    final txBody = txCreateBody(_c, mode);
    // แบ่ง / จ่ายแทน = a split bill (0.4.1-2 SA7): ONE call books the bill,
    // "คืนแล้ว", my tx and debts, and every member's copy.
    final splitBill = event == null ? splitBookBodies(_c, mode) : null;
    // "คืนแล้ว" on a plain แบ่ง (no split bill): paid back at once.
    final backShares =
        event == null && splitBill == null && mode == LinkMode.split
        ? _c.paidBackShares(event: false)
        : const <({LinkPerson person, double amount})>[];
    final debts = context.read<PersonalDebtsRepository>();
    final debtDirectory = context.read<DebtDirectoryCubit>();
    final date = _c.date;

    setState(() => _saving = true);
    String? warn;
    String? newTxId;
    try {
      if (splitBill != null) {
        final result = await projects.bookEventBill(
          split: true,
          bill: splitBill.bill,
          myBooks: splitBill.myBooks,
        );
        newTxId = result.transactionId;
      } else if (event == null) {
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
          splits: txBody.splits,
          link: txBody.link,
        );
        accounts.patchBalances(saved.accountBalances);
        newTxId = saved.rows.firstOrNull?.id;
      } else {
        // ONE call, ONE DB transaction (0.4.1-1 E8): the bill, the
        // "คืนแล้ว" paybacks, my tx, "จดหนี้ด้วย" and its repayments; the
        // wallets / people / rows follow the answer's effects (B2).
        final body = eventBookBodies(_c, tagIds: tagIds);
        final result = await projects.bookEventBill(
          projectId: switch (event) {
            ExistingEventTarget(:final project) => project.id,
            _ => null,
          },
          newEvent: switch (event) {
            NewEventTarget(:final name) => newEventBody(name),
            _ => null,
          },
          bill: body.bill,
          myBooks: body.myBooks,
        );
        newTxId = result.transactionId;
      }
      if (backShares.isNotEmpty) {
        warn ??= await _repayNow(
          debts,
          debtDirectory,
          accounts,
          txCubit,
          backShares,
          accountId: txBody.accountId,
          date: date,
        );
      }
      warn ??= await _linkAfterCreate(newTxId);
      await _remember();
      navigator.pop(true);
      showAppSnackBarOn(
        messenger,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(
        context,
        e,
        retry: _save,
        message: event == null && splitBill == null
            ? walletErrorMessage(l, e)
            : eventErrorMessage(l, e),
      );
    }
  }

  /// แบ่ง, I paid: each one marked "คืนแล้ว" has the debt just made paid back
  /// into the wallet. A failure after the bill is saved is said as a warning.
  Future<String?> _repayNow(
    PersonalDebtsRepository debts,
    DebtDirectoryCubit directory,
    AccountsCubit accounts,
    TransactionsCubit txCubit,
    List<({LinkPerson person, double amount})> rows, {
    required String? accountId,
    required DateTime date,
  }) async {
    final l = AppLocalizations.of(context)!;
    try {
      for (final r in rows) {
        final p = r.person;
        final res = await debts.createRepayment(
          _debtKey(p),
          kind: DebtRepaymentKind.receive,
          amount: r.amount,
          accountId: accountId,
          // Into the wallet now: a transaction, as before 0.4.1-1 D3.
          createTransaction: true,
          date: date,
          personName: p.name,
        );
        accounts.patchBalances(res.accountBalances);
        final tx = res.transaction;
        if (tx != null) txCubit.patchRow(tx, afterWrite: true);
        directory.applyBalance(res.balance);
      }
      return null;
    } on ApiException catch (e) {
      return walletErrorMessage(l, e);
    }
  }

  static String _debtKey(LinkPerson p) => p.contactId != null
      ? debtPersonKey(contactId: p.contactId)
      : debtPersonKey(name: p.name);

  bool get _summaryTitle => !_draftLike;

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
          : _isEditTx
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
      deleteTooltip: l.commonDelete,
      onDelete: _isEntry
          ? (widget.entry!.onDelete == null ? null : _deleteEntry)
          : _isEditTx
          ? _deleteEditTx
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
          : _isEditTx
          ? l.transactionFormSave
          : (_editingDraft ? l.pendingSubmitThis : l.quickSave),
      // A picked transaction settles the occurrence: no draft save beside it.
      draftLabel: _isEntry
          ? (_entryTx != null ? null : _entrySecondary?.label)
          : _isEditTx || _isDebt || (_isSaving && !_isSavingDraft)
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
          : _isEditTx
          ? (waiting || _draftBaseline == null ? null : _saveEditTx)
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
                padding: const EdgeInsets.only(top: AppSpacing.xl),
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
                typeLocked: _isEditTx || _isEntry,
                // An entry saves a PendingDraft: no splits there.
                allowSplits: !_isEditTx && !_isEntry,
                rowAboveNote: _isEntry ? _entryRows(l) : null,
                debtPersonCard: _debtPersonCard(l),
                heroLocked: _entryTx != null,
                // An occurrence keeps no event: its section saved nothing.
                linkSections: !_isEntry,
                eventPending: _activeEvent != null,
                // ผูกกับ (0.4.0-3): a new expense; the form shows the tabs.
                linkTabs: !_draftLike || _linkEdit.active || _editingDraft,
                linkEventIsNew: _event is NewEventTarget,
                linkIsEventMember: _isEventMember,
                recurringSlot: _recurringSlot(l),
                eventSlot:
                    (!_draftLike || _linkEdit.active) &&
                        typeCanJoinEvent(_c.type)
                    ? SplitEventSlot(
                        name: eventTargetName(l, _event),
                        onTap: _pickEvent,
                        onClear: _event == null
                            ? null
                            : () {
                                setState(() => _event = null);
                                _c.eventChanged(hasEvent: false);
                              },
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
    if (!_canSwitchMode) {
      return txBody();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _modeChips(l),
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
