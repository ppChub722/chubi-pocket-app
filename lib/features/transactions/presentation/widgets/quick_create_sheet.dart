import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
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
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../transaction_edit.dart';
import 'draft_form.dart';
import 'event_pick.dart';
import 'tx_summary_title.dart';

/// The `+` quick create (owner design 2026-10-08). A near-full-height sheet
/// — never a new page:
///
///   hero (type · amount · ค่าอะไร · date) · โน้ต · category + wallet cards
///   · tags (+ แท็กใหม่) · หารกับ… · เพิ่มเข้าอีเวนต์ — all shown, no toggle
///
/// Drag the handle / title row down to close. Closing asks first only when
/// there's something worth keeping (an amount or a description; an edit:
/// any change). Switching type keeps everything; the category is
/// remembered per type.
///
/// The fields are the shared [DraftForm] — the same one "เพิ่มร่าง" and
/// "แก้ร่าง" use. Save sits pinned above the keyboard. Once the hero's
/// amount scrolls out of view, the title row shows amount · category
/// instead of the title; tap it to scroll back.
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
/// A saved transaction isn't edited here — its detail page edits it in
/// place.
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
/// wallet's page) instead of the last-used one; [type] opens a new one on
/// that type (a wallet's ⇄ โอน → a transfer from it).
///
/// Returns true when something was saved.
Future<bool> showQuickCreateSheet(
  BuildContext context, {
  PendingTransaction? draft,
  ProjectView? project,
  ProjectTxTree? projectRow,
  bool scheduled = false,
  ScheduledTransaction? scheduledEntry,
  Account? account,
  TransactionType? type,
}) async {
  assert(
    [draft, project, scheduled ? true : null].where((x) => x != null).length <=
        1,
  );
  assert(projectRow == null || project != null);
  assert(scheduledEntry == null || scheduled);
  final accounts = context.read<AccountsCubit>().loadIfNeeded();
  final categories = context.read<CategoriesCubit>().loadIfNeeded();
  context.read<TagsCubit>().loadIfNeeded();
  // Prefilling resolves wallet / category ids against the caches — wait
  // for them, or a cold start would open with both empty.
  if (draft != null || scheduledEntry != null) {
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
    // The route's drag-to-dismiss would skip the "discard?" question —
    // the sheet drags itself instead (see _onDragEnd); ✕, the barrier and
    // back all go through PopScope.
    enableDrag: false,
    builder: (_) => _QuickCreateSheet(
      prefs: prefs,
      draft: draft,
      project: project,
      projectRow: projectRow,
      scheduled: scheduled,
      scheduledEntry: scheduledEntry,
      account: account,
      initialType: type,
    ),
  );
  return saved ?? false;
}

// ── Remembered defaults ───────────────────────────────────────────────

// The last wallet used: [StorageKeys.lastAccountId].

enum _CloseChoice { draft, keepEditing, discard }

class _QuickCreateSheet extends StatefulWidget {
  const _QuickCreateSheet({
    required this.prefs,
    this.draft,
    this.project,
    this.projectRow,
    this.scheduled = false,
    this.scheduledEntry,
    this.account,
    this.initialType,
  });
  final SharedPreferences prefs;

  /// Preset wallet for a new transaction (else the last-used one).
  final Account? account;

  /// A new transaction's type to start on (else expense).
  final TransactionType? initialType;

  /// Editing this pending draft instead of creating.
  final PendingTransaction? draft;

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

  EventTarget? _event;

  /// The event pick, unless it's a transfer (kept for switching back).
  EventTarget? get _activeEvent => typeCanJoinEvent(_c.type) ? _event : null;
  bool _saving = false;

  /// How far the sheet is dragged down by its handle / title row.
  double _drag = 0;
  bool _dragging = false;

  /// The hero card's amount is scrolled out of view → the title row shows
  /// the amount + category instead of the title.
  bool _collapsed = false;
  final _heroKey = GlobalKey();
  final _listKey = GlobalKey();

  bool get _editingDraft => widget.draft != null;

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

  /// A draft as first shown — after prefill, so the defaults it fills in
  /// (today, expense) for a draft without them don't count as edits.
  PendingDraft? _draftBaseline;

  /// Worth asking before closing (owner 2026-10-10): an edit asks when
  /// anything changed; a new entry only once it has an amount or a
  /// description (a scheduled one: a name) — anything less closes quietly.
  bool get _dirty => _isScheduled
      ? (_editingScheduled
            ? _c.scheduledSnapshot() != _scheduledBaseline
            : _hasKeyData)
      : _isEvent
      ? (_editingRow ? _c.eventSnapshot() != _eventBaseline : _hasKeyData)
      : _editingDraft
      ? _c.toDraft() != _draftBaseline
      : _hasKeyData;

  bool get _hasKeyData =>
      _c.amountValue > 0 ||
      _c.description.text.trim().isNotEmpty ||
      (_isScheduled && _c.schedule.name.text.trim().isNotEmpty);

  /// A new entry with nothing in it — its save buttons are off, and a save
  /// that slips through just closes (never an empty draft).
  bool get _isEmpty => !_editingDraft && !_c.hasContent && _event == null;

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
    if (problem == null && payer == null) {
      _c.flagMissingPayer();
      problem = l.projectTxPayerRequired;
    }
    if (problem != null || payer == null) {
      HapticFeedback.lightImpact();
      _toast(problem!);
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
      final c = _amountHidden();
      if (c != _collapsed) setState(() => _collapsed = c);
    });
    final type = widget.initialType;
    if (type != null) _c.setType(type);
    if (_isEvent) _initEvent();
    if (_isScheduled) _initScheduled();
    final p = widget.draft;
    if (p != null) {
      _c.prefill(
        p.draft,
        accounts: context.read<AccountsCubit>().state.accounts,
        categories: context.read<CategoriesCubit>().state.categories,
      );
      _draftBaseline = _c.toDraft();
    }
    // Typing / picking rebuilds the sheet (summary bar, close guard). A
    // switch to transfer keeps the event pick and splits, just unused, so
    // switching back finds them (owner 2026-10-10).
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// "บันทึกร่าง": park it in รอยืนยัน (new) or save the edits back.
  Future<void> _saveDraft() async {
    final l = AppLocalizations.of(context)!;
    if (_isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    if (!await _confirmIncompleteSplits()) return;
    if (!mounted) return;
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
      final result = await pending.submit([id]);
      final failed = result.failed[id];
      if (failed != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(pendingErrorText(l, failed));
        return;
      }
      await Future.wait([accounts.load(), TransactionsCubit.bookChanged()]);
      await _remember();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  /// Draft mode "ลบ": deletes the whole draft.
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
    final last = widget.prefs.getString(StorageKeys.lastAccountId);
    return accounts.where((a) => a.id == last).firstOrNull ?? accounts.first;
  }

  Future<void> _remember() async {
    final acc = _c.account;
    if (acc != null) {
      await widget.prefs.setString(StorageKeys.lastAccountId, acc.id);
    }
  }

  // ── Event ─────────────────────────────────────────────────────────

  Future<void> _pickEvent() async {
    final picked = await showEventTargetSheet(
      context,
      suggestedName: _suggestEventName(),
      selectedProjectId: switch (_event) {
        ExistingEventTarget(:final project) => project.id,
        _ => null,
      },
      useRootNavigator: false,
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

  /// Closing with something worth keeping ([_dirty]). One look in every
  /// mode (owner 2026-10-10): a short title, one line of context, labelled
  /// buttons. A new entry: [เก็บเป็นร่าง] (plain transactions only) ·
  /// [แก้ต่อ] · [ยกเลิกรายการนี้]. An edit: [แก้ต่อ] · [ยกเลิกการแก้ไข].
  Future<void> _confirmClose() async {
    final l = AppLocalizations.of(context)!;
    final editing = _editingDraft || _editingRow || _editingScheduled;
    final choice = await showChoiceDialog<_CloseChoice>(
      context,
      title: editing ? l.editDiscardTitle : l.quickUnsavedTitle,
      message: editing ? l.editDiscardMessage : l.quickUnsavedMessage,
      choices: [
        if (!editing && !_isEvent && !_isScheduled)
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

  /// Asks about half-filled split rows before saving ([confirmIncompleteSplits]).
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
    if (!_c.isTransfer) {
      final splitTotal = _c.splits
          .where((s) => s.isComplete)
          .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
      if (splitTotal > _c.amountValue + 0.005) return l.txSplitExceeds;
    }
    if (_activeEvent != null && _c.account == null) {
      return l.quickEventNeedsWallet;
    }
    return null;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    if (!await _confirmIncompleteSplits()) return;
    if (!mounted) return;
    final txCubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    final projects = context.read<ProjectsRepository>();
    final txRepo = context.read<TransactionsRepository>();
    final projectsCubit = context.read<ProjectsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final splits = _c.isTransfer
        ? const <Map<String, dynamic>>[]
        : _c.splits.where((s) => s.isComplete).map((s) => s.toJson()).toList();
    final description = _c.description.text.trim().isEmpty
        ? null
        : _c.description.text.trim();
    final note = _c.note.text.trim().isEmpty ? null : _c.note.text.trim();
    final event = _activeEvent;
    final type = _c.type;
    final amount = _c.amountValue;
    final account = _c.account;
    final tagIds = _c.tagIds.toList();

    setState(() => _saving = true);
    String? warn;
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
          NewEventTarget(:final name) => await projects.quickCreate(
            name: name,
            newTransaction: body,
          ),
          ExistingEventTarget(:final project) => await projects.addBills(
            project.id,
            newTransaction: body,
          ),
          // Only a saved row leaves an event (the detail page).
          RemoveFromEvent() => throw StateError('nothing to remove from'),
        };
        final txId = result.transactionId;
        if (txId != null && tagIds.isNotEmpty) {
          try {
            await txRepo.attachTags(transactionId: txId, tagIds: tagIds);
          } on ApiException {
            warn = l.txSavedTagsFailed;
          }
        }
        await TransactionsCubit.bookChanged();
        // The events list picks up a new event / bill — in place, no page.
        unawaited(projectsCubit.load());
      }
      await accounts.load();
      await _remember();
      // Stay where the user is: close + snackbar, never a tab switch or a
      // page push — an event bill too (owner 2026-10-10).
      navigator.pop(true);
      showAppSnackBarOn(
        messenger,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        event == null ? walletErrorMessage(l, e) : eventErrorMessage(l, e),
      );
    }
  }

  // ── Title-row summary ─────────────────────────────────────────────

  /// The hero's amount has scrolled up past the list's top edge. The
  /// amount ends the card's content (inline layout), so its bottom minus
  /// the card's padding is the line to watch.
  bool _amountHidden() {
    final hero = _heroKey.currentContext?.findRenderObject();
    final list = _listKey.currentContext?.findRenderObject();
    if (hero is! RenderBox || list is! RenderBox) return false;
    if (!hero.attached || !list.attached) return false;
    final amountBottom = hero
        .localToGlobal(Offset(0, hero.size.height - AppSpacing.md))
        .dy;
    return amountBottom < list.localToGlobal(Offset.zero).dy;
  }

  /// The keyboard height last build — growing means it just opened.
  double _lastInsets = 0;

  /// Scrolls the focused field into the list's view with room under it
  /// (a split row's amount sat half under the buttons on device).
  Future<void> _revealFocus() async {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (!mounted || focused == null || !_scroll.hasClients) return;
    // Only fields inside this list.
    if (Scrollable.maybeOf(focused)?.position != _scroll.position) return;
    final animate = !MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      focused,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
    );
    if (!mounted || !_scroll.hasClients || !focused.mounted) return;
    // A little more when it ended up at the very bottom, so the whole row
    // (and what's under it) shows.
    final field = focused.findRenderObject();
    final viewport = Scrollable.maybeOf(focused)?.context.findRenderObject();
    if (field is! RenderBox || viewport is! RenderBox) return;
    final gap =
        viewport.localToGlobal(Offset(0, viewport.size.height)).dy -
        field.localToGlobal(Offset(0, field.size.height)).dy;
    const room = 56.0;
    if (gap >= room) return;
    final p = _scroll.position;
    final to = (p.pixels + room - gap).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    if (to == p.pixels) return;
    if (animate) {
      await _scroll.animateTo(
        to,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(to);
    }
  }

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

  // ── Drag to dismiss ───────────────────────────────────────────────

  // The route's own drag would pop straight past PopScope (losing what
  // was typed), so the sheet drags itself and closes through maybePop —
  // the same unsaved-changes question as ✕ and back.

  void _onDragUpdate(DragUpdateDetails d) => setState(() {
    _dragging = true;
    _drag = math.max(0, _drag + d.delta.dy);
  });

  void _onDragEnd(DragEndDetails d) {
    final close = _drag > 120 || (d.primaryVelocity ?? 0) > 700;
    setState(() {
      _dragging = false;
      // Staying (or about to ask) → spring back; leaving → exit from here.
      if (!close || (_dirty && !_saving)) _drag = 0;
    });
    if (close) Navigator.of(context).maybePop();
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    // The keyboard came up (or grew): bring the focused field back into
    // view, clear of it and of the pinned buttons.
    if (insets > _lastInsets) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocus());
    }
    _lastInsets = insets;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _drag),
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, dy, sheet) =>
            Transform.translate(offset: Offset(0, dy), child: sheet),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.94,
          child: Padding(
            padding: EdgeInsets.only(bottom: insets),
            child: Column(
              children: [
                // Handle + title row: drag down to close.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
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
                            // The title, or — once the hero's amount has
                            // scrolled away — amount + category (tap: back
                            // to the top). Cross-fades in place; nothing
                            // floats over the form any more.
                            Expanded(
                              child: AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: AlignmentDirectional.centerStart,
                                  children: [...previous, ?current],
                                ),
                                child: _collapsed
                                    ? TxSummaryTitle(
                                        key: const ValueKey('summary'),
                                        type: _c.type,
                                        amount: _c.amountValue,
                                        category: _c.isTransfer
                                            ? null
                                            : _c.category,
                                        symbol: widget.project?.symbol ?? '฿',
                                        onTap: _scrollToTop,
                                      )
                                    : Text(
                                        key: const ValueKey('title'),
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
                                            : l.transactionFormTitleNew,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                              ),
                            ),
                            if (_editingDraft)
                              TextButton(
                                onPressed: _saving ? null : _discardDraft,
                                style: TextButton.styleFrom(
                                  foregroundColor: scheme.error,
                                ),
                                child: Text(l.commonDelete),
                              ),
                            IconButton(
                              tooltip: l.commonClose,
                              icon: const Icon(AppIcons.close),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: _listKey,
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      DraftForm(
                        controller: _c,
                        heroKey: _heroKey,
                        defaultAccount: _defaultAccount(accounts),
                        // A saved project row keeps its type.
                        typeLocked: _editingRow,
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
                        // The detail page's layout below the hero (owner
                        // 2026-10-10): โน้ต / หารกับ / อีเวนต์ sections.
                        sectioned: true,
                        eventPending: _activeEvent != null,
                        // Drafts don't go to events (submit is a plain
                        // create) — the row only exists when creating, for
                        // a type that can join one ([typeCanJoinEvent]).
                        trailingRows: [
                          if (!_editingDraft &&
                              !_isEvent &&
                              !_isScheduled &&
                              typeCanJoinEvent(_c.type))
                            SectionCard(
                              children: [
                                EventRow(
                                  name: eventTargetName(l, _event),
                                  onTap: _pickEvent,
                                  onClear: () => setState(() => _event = null),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pinned above the keyboard: draft (→ รอยืนยัน) · save for real.
                // Event / scheduled: one button — drafts are for one-off rows.
                // Pinned bars clear the gesture bar themselves — the sheet's
                // useSafeArea only covers the top.
                if (_isEvent || _isScheduled)
                  PinnedBar(
                    child: AppButton(
                      label: _isScheduled && !_editingScheduled
                          ? l.scheduledFormSave
                          : l.transactionFormSave,
                      expand: true,
                      loading: _saving,
                      onPressed: _isScheduled ? _saveScheduled : _saveEvent,
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
                            onPressed:
                                _saving || _activeEvent != null || _isEmpty
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
                            onPressed: _isEmpty
                                ? null
                                : (_editingDraft ? _submitDraft : _save),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
