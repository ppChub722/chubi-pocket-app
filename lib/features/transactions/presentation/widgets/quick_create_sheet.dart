import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../../../projects/presentation/widgets/project_common.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../pending/presentation/pending_errors.dart';
import '../../../scheduled_transactions/domain/scheduled_transaction.dart';
import '../../../scheduled_transactions/presentation/cubit/scheduled_transactions_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../transaction_edit.dart';
import 'draft_form.dart';

/// Maps the pinned quick-create error codes (API §10) to friendly copy;
/// falls back to the BE message for anything unmapped.
String _eventErrorMessage(AppLocalizations l, ApiException e) {
  switch (e.code) {
    case 'TX_NOT_FOUND':
      return l.quickCreateErrorTxNotFound;
    case 'TX_ALREADY_IN_PROJECT':
      return l.quickCreateErrorTxAlreadyInProject;
    case 'VALIDATION_ERROR':
      return l.quickCreateErrorValidation;
    default:
      return e.message;
  }
}

/// The `+` quick create (owner design 2026-10-08). A near-full-height sheet
/// — never a new page:
///
///   type · big amount · category + wallet cards · date · note
///   ▸ รายละเอียดเพิ่ม (closed; tap to open): tags · หารกับ… · เพิ่มเข้าอีเวนต์
///
/// The fields are the shared [DraftForm] — the same one "เพิ่มร่าง" and
/// "แก้ร่าง" use. Save sits pinned above the keyboard. Scrolling past the
/// amount slides in a compact summary (type · amount · category) at the
/// top; tap it to scroll back. Closing with anything entered asks first.
///
/// Defaults: the last wallet used (else the first) and today.
/// "เพิ่มเข้าอีเวนต์" files the bill into a new event or an existing one
/// (POST /projects/quick or /projects/:id/bills). "บันทึกร่าง" parks it in
/// รอยืนยัน instead.
///
/// With [draft] the same sheet edits a pending draft (title "แก้ร่าง"):
/// "บันทึกร่าง" saves it back, "ยืนยันรายการนี้" submits it, "ทิ้ง" removes
/// it; the event tile is hidden (drafts don't go to events).
///
/// With [transaction] it edits a saved transaction (title "แก้ไขรายการ"):
/// one "บันทึก" button; the type is fixed, splits and events are hidden
/// (both are create-only), another member's row keeps its category, and an
/// ex-member's locked row is read-only.
///
/// With [project] it's event mode — a row on that project's board (no
/// wallet or category; payer, description, note, tags, member splits; see
/// [DraftEvent]). [projectRow] edits that row (its type and payer are
/// fixed). Saves through the project API.
///
/// With [scheduled] it's scheduled mode — a recurring / installment / loan
/// template (title "ตั้งรายการประจำ"; see [DraftSchedule]): variant, type,
/// amount, icon + name, category + wallet (both required), note, cycle,
/// next due date and the installment fields. [scheduledEntry] edits that
/// entry (title "แก้รายการประจำ"; variant and type fixed). One save button;
/// saves through [ScheduledTransactionsCubit].
///
/// [account] presets the wallet of a new transaction (adding from a
/// wallet's page) instead of the last-used one.
///
/// Returns true when something was saved.
Future<bool> showQuickCreateSheet(
  BuildContext context, {
  PendingTransaction? draft,
  Transaction? transaction,
  ProjectView? project,
  ProjectTxTree? projectRow,
  bool scheduled = false,
  ScheduledTransaction? scheduledEntry,
  Account? account,
}) async {
  assert(
    [
          draft,
          transaction,
          project,
          scheduled ? true : null,
        ].where((x) => x != null).length <=
        1,
  );
  assert(projectRow == null || project != null);
  assert(scheduledEntry == null || scheduled);
  final accounts = context.read<AccountsCubit>().loadIfNeeded();
  final categories = context.read<CategoriesCubit>().loadIfNeeded();
  context.read<TagsCubit>().loadIfNeeded();
  // Prefilling resolves wallet / category ids against the caches — wait
  // for them, or a cold start would open with both empty.
  if (draft != null || transaction != null || scheduledEntry != null) {
    await Future.wait([accounts, categories]);
  }
  if (!context.mounted) return false;
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole shell, wherever it's opened from: inside a tab it
    // would sit under the floating nav (the tab body runs on beneath it).
    useRootNavigator: true,
    // Drag-to-dismiss would skip the "discard?" question; the ✕, the
    // barrier and back all go through PopScope instead.
    enableDrag: false,
    builder: (_) => _QuickCreateSheet(
      prefs: prefs,
      draft: draft,
      transaction: transaction,
      project: project,
      projectRow: projectRow,
      scheduled: scheduled,
      scheduledEntry: scheduledEntry,
      account: account,
    ),
  );
  return saved ?? false;
}

// ── Remembered defaults ───────────────────────────────────────────────

const _kLastAccount = 'quick.last_account_id';

enum _CloseChoice { draft, keepEditing, discard }

/// Where "เพิ่มเข้าอีเวนต์" files the bill.
sealed class _EventTarget {
  const _EventTarget();
}

class _NewEvent extends _EventTarget {
  const _NewEvent(this.name);
  final String name;
}

class _ExistingEvent extends _EventTarget {
  const _ExistingEvent(this.project);
  final Project project;
}

class _QuickCreateSheet extends StatefulWidget {
  const _QuickCreateSheet({
    required this.prefs,
    this.draft,
    this.transaction,
    this.project,
    this.projectRow,
    this.scheduled = false,
    this.scheduledEntry,
    this.account,
  });
  final SharedPreferences prefs;

  /// Preset wallet for a new transaction (else the last-used one).
  final Account? account;

  /// Editing this pending draft instead of creating.
  final PendingTransaction? draft;

  /// Editing this saved transaction instead of creating.
  final Transaction? transaction;

  /// Event mode: a row on this project's board.
  final ProjectView? project;

  /// Event mode, editing this row.
  final ProjectTxTree? projectRow;

  /// Scheduled mode: a recurring template.
  final bool scheduled;

  /// Scheduled mode, editing this entry.
  final ScheduledTransaction? scheduledEntry;

  @override
  State<_QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<_QuickCreateSheet> {
  final _c = DraftFormController();
  final _scroll = ScrollController();

  _EventTarget? _event;
  bool _saving = false;

  /// Scrolled past the amount → show the compact summary bar.
  bool _collapsed = false;
  static const _collapseAt = 170.0;

  bool get _editingDraft => widget.draft != null;
  bool get _editingTx => widget.transaction != null;

  /// Ex-member's row on a shared wallet — shown, not editable.
  bool get _locked => widget.transaction?.isLocked ?? false;

  /// The saved transaction as first loaded — what "changed?" compares to.
  PendingDraft? _txBaseline;
  String? _initialAccountId;
  String? _initialToAccountId;

  bool get _isEvent => widget.project != null;
  bool get _editingRow => widget.projectRow != null;

  /// Event mode: the fields as first shown, and the project's tags (from
  /// the loaded rows first, then the full list from the server).
  String? _eventBaseline;
  List<String> _eventTags = const [];
  late final List<String> _pastDescriptions = _mostUsed([
    for (final t in widget.project?.trees ?? const <ProjectTxTree>[])
      if ((t.parent.description ?? '').trim().isNotEmpty)
        t.parent.description!.trim(),
  ]);

  bool get _isScheduled => widget.scheduled;
  bool get _editingScheduled => widget.scheduledEntry != null;

  /// Scheduled mode: the fields as first shown.
  String? _scheduledBaseline;

  bool get _dirty => _isScheduled
      ? _c.scheduledSnapshot() != _scheduledBaseline
      : _isEvent
      ? _c.eventSnapshot() != _eventBaseline
      : _editingDraft
      ? _c.toDraft() != widget.draft!.draft
      : _editingTx
      ? !_locked && _c.toDraft() != _txBaseline
      : _c.hasContent || _event != null;

  /// Distinct values, most frequent first.
  static List<String> _mostUsed(Iterable<String> values) {
    final counts = <String, int>{};
    for (final v in values) {
      counts.update(v, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  void _initEvent() {
    final view = widget.project!;
    final row = widget.projectRow;
    if (row != null) {
      _c.prefillProjectRow(row);
    } else {
      _c.payerId = (view.me ?? view.currentMembers.firstOrNull)?.id;
    }
    _eventBaseline = _c.eventSnapshot();
    _eventTags = _mostUsed([for (final t in view.trees) ...t.parent.tags]);
    context
        .read<ProjectsRepository>()
        .listTags(view.project.id)
        .then((tags) {
          if (mounted) setState(() => _eventTags = tags);
        })
        .catchError((_) {}); // keep the local list
  }

  /// Event mode "บันทึก": create or update the project row.
  Future<void> _saveEvent() async {
    final l = AppLocalizations.of(context)!;
    final view = widget.project!;
    final amount = _c.amountValue;
    final payer = _c.payerId;
    String? problem;
    if (amount <= 0) {
      problem = l.projectTxAmountRequired;
    } else if (_c.memberSplitSum > amount + 0.005) {
      problem = l.projectTxSplitsOver(
        moneyString(context, _c.memberSplitSum, symbol: view.symbol),
      );
    }
    if (problem != null || payer == null) {
      HapticFeedback.lightImpact();
      if (problem != null) _toast(problem);
      return;
    }
    final repo = context.read<ProjectsRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final description = _c.description.text.trim();
    final note = _c.note.text.trim();
    final splits = [
      for (final s in _c.memberSplits)
        if (s.memberId != null && s.amountValue > 0)
          ProjectSplitInput(memberId: s.memberId!, amount: s.amountValue),
    ];
    setState(() => _saving = true);
    try {
      final row = widget.projectRow;
      if (row == null) {
        await repo.createTransaction(
          view.project.id,
          transactionMemberId: payer,
          type: _c.type == TransactionType.income ? 'income' : 'expense',
          amount: amount,
          currency: view.currency,
          date: _ymd(_c.date),
          description: description.isEmpty ? null : description,
          note: note.isEmpty ? null : note,
          tags: List.of(_c.tagNames),
          splits: splits,
        );
      } else {
        await repo.updateTransaction(
          view.project.id,
          row.parent.id,
          amount: amount,
          date: _ymd(_c.date),
          description: description,
          note: note,
          tags: List.of(_c.tagNames),
          splits: splits,
        );
      }
      HapticFeedback.mediumImpact();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  void _initScheduled() {
    final e = widget.scheduledEntry;
    if (e != null) {
      _c.prefillScheduled(
        e,
        accounts: context.read<AccountsCubit>().state.accounts,
        categories: context.read<CategoriesCubit>().state.categories,
      );
    }
    _scheduledBaseline = _c.scheduledSnapshot();
  }

  /// Scheduled mode "บันทึก": create or update the entry. Edits affect
  /// future cycles only (spec §2.5).
  Future<void> _saveScheduled() async {
    final l = AppLocalizations.of(context)!;
    final problem = _c.scheduledProblem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _c.schedule.revealErrors();
      _toast(problem);
      return;
    }
    final cubit = context.read<ScheduledTransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final initial = widget.scheduledEntry;
    final entry = _c.toScheduled(initial: initial);
    setState(() => _saving = true);
    try {
      if (initial == null) {
        await cubit.add(entry);
      } else {
        await cubit.update(entry);
      }
      HapticFeedback.mediumImpact();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > _collapseAt;
      if (c != _collapsed) setState(() => _collapsed = c);
    });
    if (_isEvent) _initEvent();
    if (_isScheduled) _initScheduled();
    final p = widget.draft;
    if (p != null) {
      _c.prefill(
        p.draft,
        accounts: context.read<AccountsCubit>().state.accounts,
        categories: context.read<CategoriesCubit>().state.categories,
      );
    }
    final t = widget.transaction;
    if (t != null) {
      _c.prefillTransaction(
        t,
        accounts: context.read<AccountsCubit>().state.accounts,
        categories: context.read<CategoriesCubit>().state.categories,
        // A transfer's other side is its sibling row in the same group.
        toAccount: transferOtherAccount(context, t),
      );
      _txBaseline = _c.toDraft();
      _initialAccountId = _c.account?.id;
      _initialToAccountId = _c.toAccount?.id;
    }
    // Typing / picking rebuilds the sheet (summary bar, close guard); a
    // transfer can't go to an event.
    _c.addListener(() {
      if (!mounted) return;
      setState(() {
        if (_c.isTransfer) _event = null;
      });
    });
  }

  /// "บันทึกร่าง": park it in รอยืนยัน (new) or save the edits back.
  Future<void> _saveDraft() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final d = _c.toDraft();
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
      _toast(e.message);
    }
  }

  /// Draft mode "ยืนยันรายการนี้": save the edits, then submit just this one.
  Future<void> _submitDraft() async {
    final l = AppLocalizations.of(context)!;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.draft!.id;
    setState(() => _saving = true);
    try {
      await pending.updateDraft(id, _c.toDraft());
      final result = await pending.submit([id]);
      final failed = result.failed[id];
      if (failed != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(pendingErrorText(l, failed));
        return;
      }
      await Future.wait([accounts.load(), txCubit.load()]);
      await _remember();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  /// Draft mode "ทิ้ง".
  Future<void> _discardDraft() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l.pendingDiscardTitle,
      confirmLabel: l.quickDiscardConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await pending.discard(widget.draft!.id);
      navigator.pop(true);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Wallet default: the one used last, else the first — re-evaluated until
  /// the user picks one, so a cold cache doesn't leave it empty.
  Account? _defaultAccount(List<Account> accounts) {
    final preset = widget.account;
    if (preset != null) {
      // The cached row when there is one (fresher balance).
      return accounts.where((a) => a.id == preset.id).firstOrNull ?? preset;
    }
    if (accounts.isEmpty) return null;
    final last = widget.prefs.getString(_kLastAccount);
    return accounts.where((a) => a.id == last).firstOrNull ?? accounts.first;
  }

  Future<void> _remember() async {
    final acc = _c.account;
    if (acc != null) await widget.prefs.setString(_kLastAccount, acc.id);
  }

  // ── Event ─────────────────────────────────────────────────────────

  Future<void> _pickEvent() async {
    final picked = await showAppSheet<_EventTarget>(
      context,
      title: AppLocalizations.of(context)!.quickAddToEvent,
      useRootNavigator: false,
      builder: (_) => _EventTargetSheet(suggestedName: _suggestEventName()),
    );
    if (picked != null && mounted) setState(() => _event = picked);
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
        ? '${l.quickEventDefaultName} · $date'
        : '${names.join(', ')} · $date';
  }

  // ── Close / save ──────────────────────────────────────────────────

  /// Closing with something entered: keep it as a draft, keep editing, or
  /// throw it away. (Editing a draft: keep editing or drop the changes.)
  Future<void> _confirmClose() async {
    final l = AppLocalizations.of(context)!;
    final choice = await showChoiceDialog<_CloseChoice>(
      context,
      title: _editingDraft ? l.pendingDropEditsTitle : l.quickDiscardTitle,
      message: _editingDraft
          ? l.pendingDropEditsMessage
          : l.quickDiscardMessage,
      choices: [
        if (!_editingDraft && !_editingTx && !_isEvent && !_isScheduled)
          DialogChoice(
            value: _CloseChoice.draft,
            label: l.pendingKeepAsDraft,
            variant: AppButtonVariant.primary,
          ),
        DialogChoice(
          value: _CloseChoice.keepEditing,
          label: l.quickDiscardKeep,
        ),
        DialogChoice(
          value: _CloseChoice.discard,
          label: l.quickDiscardConfirm,
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
    final splitTotal = _c.splits
        .where((s) => s.isComplete)
        .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
    if (splitTotal > _c.amountValue + 0.005) return l.txSplitExceeds;
    if (_event != null && _c.account == null) return l.quickEventNeedsWallet;
    return null;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final txCubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    final projects = context.read<ProjectsRepository>();
    final txRepo = context.read<TransactionsRepository>();
    final navigator = Navigator.of(context);
    final open = pageOpener(context);
    final messenger = ScaffoldMessenger.of(context);
    final splits = _c.splits
        .where((s) => s.isComplete)
        .map((s) => s.toJson())
        .toList();
    final description = _c.description.text.trim().isEmpty
        ? null
        : _c.description.text.trim();
    final note = _c.note.text.trim().isEmpty ? null : _c.note.text.trim();
    final event = _event;
    final type = _c.type;
    final amount = _c.amountValue;
    final account = _c.account;
    final tagIds = _c.tagIds.toList();

    setState(() => _saving = true);
    String? warn;
    String? openProject;
    try {
      if (event == null) {
        try {
          await txCubit.add(
            type: type,
            accountId: account?.id,
            amount: amount,
            date: _ymd(_c.date),
            categoryId: _c.isTransfer ? null : _c.category?.id,
            description: description,
            note: note,
            transferToAccountId: _c.isTransfer ? _c.toAccount?.id : null,
            tagIds: tagIds,
            splits: splits.isEmpty ? null : splits,
          );
        } on TagsAttachFailed {
          warn = l.txSavedTagsFailed; // saved — just the tags
        }
      } else {
        final body = <String, dynamic>{
          'type': type.toJson(),
          'amount': amount,
          'date': _ymd(_c.date),
          'account_id': ?account?.id,
          'category_id': ?_c.category?.id,
          'description': ?description,
          'note': ?note,
          if (splits.isNotEmpty) 'splits': splits,
        };
        final result = switch (event) {
          _NewEvent(:final name) => await projects.quickCreate(
            name: name,
            newTransaction: body,
          ),
          _ExistingEvent(:final project) => await projects.addBills(
            project.id,
            newTransaction: body,
          ),
        };
        openProject = result.project.id;
        final txId = result.transactionId;
        if (txId != null && tagIds.isNotEmpty) {
          try {
            await txRepo.attachTags(transactionId: txId, tagIds: tagIds);
          } on ApiException {
            warn = l.txSavedTagsFailed;
          }
        }
        await txCubit.load();
      }
      await accounts.load();
      await _remember();
      navigator.pop(true);
      showAppSnackBarOn(
        messenger,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
      if (openProject != null) open('/projects/$openProject');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        event == null ? walletErrorMessage(l, e) : _eventErrorMessage(l, e),
      );
    }
  }

  /// Edit mode "บันทึก": the same save as the detail page's in-place edit
  /// ([saveTransactionEdit]).
  Future<void> _saveEdit() async {
    final l = AppLocalizations.of(context)!;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final warn = await saveTransactionEdit(
        context,
        t: widget.transaction!,
        c: _c,
        initialAccountId: _initialAccountId,
        initialToAccountId: _initialToAccountId,
      );
      navigator.pop(true);
      showAppSnackBarOn(
        messenger,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(walletErrorMessage(l, e));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.94,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isScheduled
                            ? (_editingScheduled
                                  ? l.scheduledSheetTitleEdit
                                  : l.scheduledSheetTitleNew)
                            : _isEvent
                            ? (_editingRow
                                  ? l.projectTxEditTitle
                                  : l.projectTxNewTitle)
                            : _editingDraft
                            ? l.pendingEditTitle
                            : _editingTx
                            ? l.transactionFormTitleEdit
                            : l.transactionFormTitleNew,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_editingDraft)
                      TextButton(
                        onPressed: _saving ? null : _discardDraft,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                        ),
                        child: Text(l.quickDiscardConfirm),
                      ),
                    IconButton(
                      tooltip: l.commonClose,
                      icon: const Icon(AppIcons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      children: [
                        if (_locked) ...[
                          MessageBanner(
                            message: l.transactionFormLockedBanner,
                            tone: Tone.warning,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        DraftForm(
                          controller: _c,
                          defaultAccount: _defaultAccount(accounts),
                          // Saved rows: type, splits and events are
                          // create-only (the update API can't change them).
                          typeLocked: _editingTx || _editingRow,
                          allowSplits: !_editingTx,
                          event: _isEvent
                              ? DraftEvent(
                                  members: widget.project!.currentMembers,
                                  symbol: widget.project!.symbol,
                                  pastDescriptions: _pastDescriptions,
                                  tags: _eventTags,
                                )
                              : null,
                          schedule: _isScheduled
                              ? DraftSchedule(editing: _editingScheduled)
                              : null,
                          readOnly: _locked,
                          categoryLockedHint:
                              _editingTx && !widget.transaction!.canEditCategory
                              ? l.transactionFormCategoryAuthorOnlyHint
                              : null,
                          // Drafts don't go to events (submit is a plain
                          // create) — the tile only exists when creating.
                          extra:
                              _editingDraft ||
                                  _editingTx ||
                                  _isEvent ||
                                  _isScheduled
                              ? null
                              : _EventTile(
                                  target: _event,
                                  onTap: _pickEvent,
                                  onClear: () => setState(() => _event = null),
                                ),
                        ),
                      ],
                    ),
                    // Compact summary — slides in once the amount scrolls off.
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.xs,
                      child: IgnorePointer(
                        ignoring: !_collapsed,
                        child: AnimatedSlide(
                          offset: _collapsed
                              ? Offset.zero
                              : const Offset(0, -0.6),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _collapsed ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: _SummaryBar(
                              type: _c.type,
                              amount: _c.amountValue,
                              category: _c.category,
                              symbol: widget.project?.symbol ?? '฿',
                              onTap: () => _scroll.animateTo(
                                0,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pinned above the keyboard: draft (→ รอยืนยัน) · save for real.
              // Editing a saved row: just save. Locked row: nothing to save.
              // Scheduled: one button too — drafts are for one-off rows.
              // Pinned bars clear the gesture bar themselves — the sheet's
              // useSafeArea only covers the top.
              if (_editingTx || _isEvent || _isScheduled)
                PinnedBar(
                  child: AppButton(
                    label: _isScheduled && !_editingScheduled
                        ? l.scheduledFormSave
                        : l.transactionFormSave,
                    expand: true,
                    loading: _saving,
                    onPressed: _isScheduled
                        ? _saveScheduled
                        : _isEvent
                        ? _saveEvent
                        : _locked
                        ? null
                        : _saveEdit,
                  ),
                )
              else
                PinnedBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: l.pendingSaveDraft,
                          variant: AppButtonVariant.outlined,
                          expand: true,
                          // A draft can't go to an event.
                          onPressed: _saving || _event != null
                              ? null
                              : _saveDraft,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 3,
                        child: AppButton(
                          label: _editingDraft
                              ? l.pendingSubmitThis
                              : l.quickSave,
                          expand: true,
                          loading: _saving,
                          onPressed: _editingDraft ? _submitDraft : _save,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.target,
    required this.onTap,
    required this.onClear,
  });
  final _EventTarget? target;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = target;
    if (t == null) {
      return AddTile(
        label: l.quickAddToEvent,
        variant: AddTileVariant.row,
        icon: AppIcons.project,
        onTap: onTap,
      );
    }
    final name = switch (t) {
      _NewEvent(:final name) => l.quickEventNewNamed(name),
      _ExistingEvent(:final project) => project.name,
    };
    return DetailRow(
      leading: const Icon(AppIcons.project),
      label: l.quickEventLabel,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          IconButton(
            tooltip: l.quickEventRemove,
            icon: const Icon(AppIcons.clear, size: 18),
            onPressed: onClear,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Slides in at the top once the amount scrolls away.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.type,
    required this.amount,
    required this.category,
    required this.onTap,
    this.symbol = '฿',
  });
  final TransactionType type;
  final double amount;
  final Category? category;
  final VoidCallback onTap;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final typeLabel = switch (type) {
      TransactionType.expense => l.transactionTypeExpense,
      TransactionType.income => l.transactionTypeIncome,
      TransactionType.transfer => l.transactionTypeTransfer,
    };
    return Material(
      color: scheme.surface,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                typeLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MoneyText(
                  amount,
                  symbol: symbol,
                  tone: switch (type) {
                    TransactionType.expense => MoneyTone.expense,
                    TransactionType.income => MoneyTone.income,
                    TransactionType.transfer => MoneyTone.plain,
                  },
                  hideable: false,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (category != null)
                Chip(
                  label: Text(category!.name),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "เพิ่มเข้าอีเวนต์": a new event (named here) or one of my active ones.
class _EventTargetSheet extends StatefulWidget {
  const _EventTargetSheet({required this.suggestedName});
  final String suggestedName;

  @override
  State<_EventTargetSheet> createState() => _EventTargetSheetState();
}

class _EventTargetSheetState extends State<_EventTargetSheet> {
  late final _name = TextEditingController(text: widget.suggestedName);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectsCubit>().load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<ProjectsCubit>().state;
    final active = state.projects.where((p) => p.isActive).toList();
    // Title row, drag handle and keyboard inset come from [showAppSheet].
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l.quickEventNew,
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _name,
                  label: l.quickEventNameLabel,
                  maxLength: 100,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.quickEventCreate,
                onPressed: () {
                  final n = _name.text.trim();
                  if (n.isNotEmpty) Navigator.of(context).pop(_NewEvent(n));
                },
              ),
            ],
          ),
          SectionHeader(
            title: l.quickEventExisting,
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xs,
            ),
          ),
          if (state.status == ProjectsStatus.loading && active.isEmpty)
            // Row-shaped skeletons matching the event rows below.
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    SkeletonCircle(size: 24),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(child: SkeletonLine()),
                  ],
                ),
              )
          else if (active.isEmpty)
            Text(
              l.quickEventNoneYet,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in active)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(AppIcons.project),
                      title: Text(p.name),
                      trailing: const Icon(AppIcons.chevronRight),
                      onTap: () => Navigator.of(context).pop(_ExistingEvent(p)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
