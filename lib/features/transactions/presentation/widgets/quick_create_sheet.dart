import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../home/presentation/cubit/dashboard_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/cubit/debt_book.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../../../projects/presentation/widgets/project_common.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../pending/presentation/pending_errors.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../data/transactions_repository.dart';
import '../../domain/form_options.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../save_failure.dart';
import '../transaction_edit.dart';
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_entry.dart';
import '../../../saving_goals/domain/saving_goals_overview.dart';
import '../../../saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'debt_entry_form.dart';
import 'saving_entry_form.dart';
import 'draft_form.dart';
import 'event_pick.dart';
import 'recurring_link.dart';
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
/// "แก้ร่าง" use. Save sits pinned above the keyboard. The title never
/// changes while scrolling (owner 2026-10-11) — except a NEW transaction's: once
/// the hero's amount has scrolled out of view (typing with the keyboard
/// up), the title row shows amount · category instead; tap it to scroll back
/// (owner 2026-10-11, "like before").
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
/// [account] presets the wallet of a new transaction (adding from a
/// wallet's page) instead of the last-used one; [type] opens a new one on
/// that type (a wallet's ⇄ โอน → a transfer from it). [category] presets a
/// new transaction's category (and its type: expense / income) — the +
/// over a category's page; [tag] presets one tag — the + over a tag's page.
///
/// [preset] = the same per-page default the shell's + uses
/// ([QuickCreatePreset]: mode + wallet / category / tag / person); its
/// fields fill in where [account] / [category] / [tag] are not given. A
/// page's own button opens quick create with it, e.g. the debts person
/// page: `showQuickCreateSheet(context, preset: QuickCreatePreset.debt(person: p))`.
///
/// One footer button of [showEntrySheet]: [onPressed] gets the edited body
/// and does the ONE call; true = saved (the sheet closes), false = it
/// failed (the sheet stays, typed input kept — the caller says why).
class EntrySheetAction {
  const EntrySheetAction({
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  final String label;
  final Future<bool> Function(PendingDraft draft) onPressed;

  /// The main button (filled); the other one is outlined.
  final bool primary;
}

/// The settings of [showEntrySheet] (call that, not [showQuickCreateSheet]).
class EntrySheetConfig {
  const EntrySheetConfig({
    required this.title,
    required this.initial,
    required this.actions,
    this.onDelete,
  });

  final String title;
  final PendingDraft initial;
  final List<EntrySheetAction> actions;
  final Future<bool> Function()? onDelete;
}

/// Edit ONE item in the quick-form look (owner 2026-10-13: an upcoming /
/// produced recurring item, a pending draft): the EntryCard (type · date ·
/// description · amount · wallet · category), tags, note — any date. The
/// caller owns the save: 1–2 [actions] (the last is the main button, e.g.
/// [บันทึก], or [รอยืนยัน] [บันทึกเลย]) each get the edited body. [onDelete]
/// adds the 🗑 (true = done, closes). The pickers come from the form options
/// (one call; the EntryCard skeleton shows until they land). Returns true
/// when an action (or delete) went through.
Future<bool> showEntrySheet(
  BuildContext context, {
  required String title,
  required PendingDraft initial,
  required List<EntrySheetAction> actions,
  Future<bool> Function()? onDelete,
}) {
  assert(actions.isNotEmpty && actions.length <= 2, '1 or 2 actions');
  return showQuickCreateSheet(
    context,
    entry: EntrySheetConfig(
      title: title,
      initial: initial,
      actions: actions,
      onDelete: onDelete,
    ),
  );
}

/// Debt mode (owner 2026-10-12): a debt preset opens it with the person;
/// the mode chips at the top switch a new entry between รายการ / หนี้.
/// [onDebtSaved] gets the write response of a saved debt entry (the debts
/// pages patch from it — no re-fetch). [onEventSaved] likewise gets an
/// event row's write answer ([EventPatch]: the board, totals, tags).
///
/// Returns true when something was saved.
Future<bool> showQuickCreateSheet(
  BuildContext context, {
  QuickCreatePreset? preset,
  ValueChanged<DebtEntryWriteResult>? onDebtSaved,
  ValueChanged<SavingWriteResult>? onSavingSaved,
  ValueChanged<EventPatch>? onEventSaved,
  PendingTransaction? draft,
  ProjectView? project,
  ProjectTxTree? projectRow,
  Account? account,
  Account? toAccount,
  TransactionType? type,
  Category? category,
  Tag? tag,
  double? amount,
  DebtEntryDirection? debtDirection,
  EntrySheetConfig? entry,
}) async {
  assert(draft == null || project == null);
  assert(projectRow == null || project != null);
  account ??= preset?.account;
  category ??= preset?.category;
  tag ??= preset?.tag;
  // A new transaction AND a draft edit read their pickers from ONE call
  // (form options, one per open: fresh balances). Event rows still use the
  // app-wide caches.
  final fromOptions = project == null;
  TxFormOptionsCubit? options;
  if (fromOptions) {
    options = TxFormOptionsCubit(context.read<TransactionsRepository>());
    // The sheet opens at once. A draft shows the EntryCard skeleton until
    // the options are here, then prefills from them (a failure falls back
    // to the draft's own resolved refs, the sheet shows retry).
    unawaited(options.load());
  } else {
    context.read<AccountsCubit>().loadIfNeeded();
    context.read<CategoriesCubit>().loadIfNeeded();
    context.read<TagsCubit>().loadIfNeeded();
  }
  if (!context.mounted) {
    unawaited(options?.close());
    return false;
  }
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
    builder: (sheetContext) {
      final sheet = _QuickCreateSheet(
        prefs: prefs,
        draft: draft,
        project: project,
        projectRow: projectRow,
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
        onEventSaved: onEventSaved,
        entry: entry,
        initialAmount: amount,
        initialDebtDirection: debtDirection ?? preset?.debtDirection,
      );
      if (options == null) return sheet;
      return BlocProvider<TxFormOptionsCubit>.value(
        value: options,
        child: sheet,
      );
    },
  );
  unawaited(options?.close());
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
    this.onEventSaved,
    this.entry,
    this.initialAmount,
    this.initialDebtDirection,
  });
  final SharedPreferences prefs;

  /// Preset wallet for a new transaction (else the last-used one).
  final Account? account;

  /// A transfer's destination to start on (a card's ชำระบัตร).
  final Account? initialToAccount;

  /// A new transaction's type to start on (else expense).
  final TransactionType? initialType;

  /// A new transaction's preset category (its type follows).
  final Category? initialCategory;

  /// A new transaction's preset tag.
  final Tag? initialTag;

  /// รายการ or หนี้ to open in (a new entry only).
  final QuickCreateMode initialMode;

  /// Debt mode's preset person.
  final DebtPick? debtPerson;
  final ValueChanged<DebtEntryWriteResult>? onDebtSaved;

  /// ออม mode: the write answer of a saved saving entry.
  final ValueChanged<SavingWriteResult>? onSavingSaved;

  /// ออม mode's preset target goal (null = spare).
  final String? savingGoalId;
  final ValueChanged<EventPatch>? onEventSaved;

  /// [showEntrySheet]: edit one item, the caller saves.
  final EntrySheetConfig? entry;

  /// A new entry's amount (e.g. "บันทึกรับเงิน" from what they paid).
  final double? initialAmount;
  final DebtEntryDirection? initialDebtDirection;

  /// Editing this pending draft instead of creating.
  final PendingTransaction? draft;

  /// Event mode: a row on this project's board.
  final ProjectView? project;

  /// Event mode, editing this row.
  final ProjectTxTree? projectRow;

  @override
  State<_QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<_QuickCreateSheet> {
  final _c = DraftFormController();

  EventTarget? _event;

  /// The รายการประจำ pick: held until the transaction exists, then linked.
  final _link = RecurringLinkHandle();

  /// The event pick, unless it's a transfer (kept for switching back).
  EventTarget? get _activeEvent => typeCanJoinEvent(_c.type) ? _event : null;
  bool _saving = false;

  /// The hero card key: the shell watches it to swap the title row for the
  /// amount · category summary once the amount scrolls away.
  final _heroKey = GlobalKey();

  bool get _editingDraft => widget.draft != null;

  /// A pending 🐷 saving draft: the ออม form, prefilled, confirmed from here.
  bool get _isSavingDraft => widget.draft?.isSaving ?? false;

  /// [showEntrySheet]: one item, the caller's actions save it.
  bool get _isEntry => widget.entry != null;

  /// A draft or an entry: prefilled from a body, its baseline decides dirty.
  bool get _draftLike => _editingDraft || _isEntry;

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

  /// A draft as first shown — after prefill, so the defaults it fills in
  /// (today, expense) for a draft without them don't count as edits.
  PendingDraft? _draftBaseline;

  /// Worth asking before closing (owner 2026-10-10): an edit asks when
  /// anything changed; a new entry only once it has an amount or a
  /// description — anything less closes quietly.
  bool get _dirty => _isEvent
      ? (_editingRow ? _c.eventSnapshot() != _eventBaseline : _hasKeyData)
      : _draftLike
      // Not prefilled yet (the skeleton): nothing to lose.
      ? _draftBaseline != null &&
            _c.toDraft(keepIncomplete: true) != _draftBaseline
      : _hasKeyData;

  bool get _hasKeyData =>
      _c.amountValue > 0 || _c.description.text.trim().isNotEmpty;

  /// A new entry with nothing in it — its save buttons are off, and a save
  /// that slips through just closes (never an empty draft).
  bool get _isEmpty => !_draftLike && !_c.hasContent && _event == null;

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
        moneyString(
          context,
          _c.memberSplitSum,
          symbol: context.readUserCurrencySymbol,
        ),
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
    // My OWN bill made from my transaction (the BE sends source_tx only to
    // its owner): ask whether the tx changes too (owner 2026-10-13: linked
    // by prompt, not sync). Another member's edit just saves (BE notifies).
    var alsoUpdateLink = false;
    if (widget.projectRow?.parent.sourceTx != null) {
      final choice = await showLinkedPrompt(
        context,
        title: l.linkedSaveTitle,
        cancelLabel: l.linkedCancel,
        thisSideLabel: l.linkedSaveThisOnly,
        bothSidesLabel: l.linkedSaveBoth,
      );
      if (choice == null || !mounted) return;
      alsoUpdateLink = choice == LinkedChoice.bothSides;
    }
    setState(() => _saving = true);
    try {
      // Bills take EVENT tags by id (owner 2026-10-12): a name the event
      // doesn't have yet becomes an event tag first.
      final tagIds = <String>[];
      for (final name in _c.tagNames) {
        tagIds.add(
          view.eventTag(name)?.id ??
              (await repo.createEventTag(view.project.id, name)).id,
        );
      }
      final row = widget.projectRow;
      final EventPatch patch;
      if (row == null) {
        patch = await repo.createTransaction(
          view.project.id,
          transactionMemberId: payer,
          type: _c.type == TransactionType.income ? 'income' : 'expense',
          amount: amount,
          date: _ymd(_c.date),
          description: description.isEmpty ? null : description,
          note: note.isEmpty ? null : note,
          tagIds: tagIds,
          splits: splits,
        );
      } else {
        patch = await repo.updateTransaction(
          view.project.id,
          row.parent.id,
          amount: amount,
          date: _ymd(_c.date),
          description: description,
          note: note,
          tagIds: tagIds,
          splits: splits,
          alsoUpdateLink: alsoUpdateLink,
        );
      }
      widget.onEventSaved?.call(patch);
      HapticFeedback.mediumImpact();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveEvent);
    }
  }

  @override
  void initState() {
    super.initState();
    _link.addListener(_onLinkChanged);
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
    if (_isEvent) _initEvent();
    if (_draftLike) _prefillDraftWhenReady();
    // Typing / picking rebuilds the sheet (summary bar, close guard). A
    // switch to transfer keeps the event pick and splits, just unused, so
    // switching back finds them (owner 2026-10-10).
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// A draft fills the form from the form options: at once when they're
  /// here (or failed: the draft's own resolved refs), else as soon as they
  /// land — the EntryCard skeleton shows until then.
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
        // Closed before answering (the sheet went away).
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
      // The pickers' options (one call), plus what the draft itself carries
      // resolved, so an archived wallet / category still shows.
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
      _draftBaseline = _c.toDraft(keepIncomplete: true);
    }
  }

  /// "บันทึกร่าง": park it in รอยืนยัน (new) or save the edits back.
  Future<void> _saveDraft() async {
    final l = AppLocalizations.of(context)!;
    if (_isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    // A draft keeps half-filled splits for later — no question, no balance
    // check (confirming needs them whole).
    if (!mounted) return;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final d = _c.toDraft(keepIncomplete: true);
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
      final result = await pending.submitOne(id);
      final failed = result.failed[id];
      if (failed != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(pendingErrorText(l, failed));
        return;
      }
      accounts.patchBalances(result.accountBalances);
      await TransactionsCubit.bookChanged();
      await _remember();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.quickSaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _submitDraft);
    }
  }

  // ── Saving draft (🐷 pending) ─────────────────────────────────────

  /// The saving form as first shown — its baseline decides dirty.
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
    // The ออม form lists the app-wide wallets (with their savings).
    _sav.account = [
      ...context.read<AccountsCubit>().state.accounts,
      ...accounts,
    ].where((a) => a.id == d.accountId).firstOrNull;
    // Not null: the sheet's skeleton / dirty gates look at it.
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

  /// Saving draft "บันทึกร่าง": keep the edits in รอยืนยัน.
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

  /// Saving draft "ยืนยันรายการนี้": save the edits, then submit this one.
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
    final goals = context.read<SavingGoalsCubit>();
    final dashboard = context.read<DashboardCubit>();
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
      goals.markStale();
      dashboard.markStale();
      await TransactionsCubit.bookChanged();
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.savingEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _submitSavingDraft);
    }
  }

  /// Draft mode "ลบ": deletes the whole draft.
  /// [showEntrySheet]'s main action (the last primary one, else the last).
  EntrySheetAction _entryAction({required bool primary}) {
    final actions = widget.entry!.actions;
    return actions.lastWhere((a) => a.primary, orElse: () => actions.last);
  }

  /// The other action of a two-button entry sheet, if any.
  EntrySheetAction? get _entrySecondary {
    final actions = widget.entry?.actions ?? const [];
    if (actions.length < 2) return null;
    final main = _entryAction(primary: true);
    return actions.firstWhere((a) => !identical(a, main));
  }

  /// Runs a caller's action with the edited body; closes on success.
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
    _c.dispose();
    _link.dispose();
    _debt.dispose();
    _sav.dispose();
    super.dispose();
  }

  // ── Debt mode ─────────────────────────────────────────────────────

  /// รายการ / หนี้ — only a new plain entry switches (not a draft or an
  /// event row).
  late QuickCreateMode _mode = _isSavingDraft
      ? QuickCreateMode.saving
      : _canSwitchMode
      ? widget.initialMode
      : QuickCreateMode.tx;
  late final DebtEntryController _debt =
      DebtEntryController(person: widget.debtPerson)
        ..direction = widget.initialDebtDirection ?? DebtEntryDirection.paid
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

  bool get _canSwitchMode => !_draftLike && !_isEvent;
  bool get _isDebt => _mode == QuickCreateMode.debt;
  bool get _isSaving => _mode == QuickCreateMode.saving;

  /// (amount, description, note) of a mode's form — saving has one text, its note.
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

  /// Switching keeps what was typed: amount, description, note, date.
  void _switchMode(QuickCreateMode m) {
    if (m == _mode) return;
    final from = _fieldsOf(_mode);
    final to = _fieldsOf(m);
    to.$1.text = from.$1.text;
    to.$2.text = from.$2.text;
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

  /// Debt mode "บันทึก": ONE call (the entry + its wallet tx + the paid
  /// labels); everything shown is patched from the answer.
  Future<void> _saveDebt() async {
    final l = AppLocalizations.of(context)!;
    final d = _debt;
    final person = d.person;
    final problem = d.amountValue <= 0
        ? l.quickAmountRequired
        : person == null
        ? l.debtCounterpartyRequired
        : null;
    if (problem != null || person == null) {
      HapticFeedback.lightImpact();
      _toast(problem!);
      return;
    }
    final repo = context.read<PersonalDebtsRepository>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final dashboard = context.read<DashboardCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _saving = true);
    try {
      final r = await repo.createEntry(
        person.key,
        direction: d.direction,
        amount: d.amountValue,
        date: d.date,
        // Ledger only: no wallet, no tags. Else a transaction, with or
        // without a wallet.
        accountId: d.createTransaction ? d.account?.id : null,
        createTransaction: d.createTransaction,
        description: text(d.description),
        note: text(d.note),
        tagIds: d.createTransaction ? d.tagIds.toList() : null,
        markPaidIds: d.markPaidIds.isEmpty ? null : d.markPaidIds.toList(),
        personName: person.typedName,
      );
      accounts.patchBalances(r.accountBalances);
      final tx = r.transaction;
      if (tx != null) txCubit.patchRow(tx, afterWrite: true);
      // Home's debts tile.
      dashboard.markStale();
      widget.onDebtSaved?.call(r);
      // Every live debts cubit (people list, an open person page) patches
      // itself, whichever page opened the sheet.
      DebtBook.entrySaved(r);
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.debtEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveDebt);
    }
  }

  /// ออม mode "บันทึก": ONE call; the touched wallets' savings are patched
  /// from the answer (no wallet balance moves — it is a notebook entry).
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
    final goals = context.read<SavingGoalsCubit>();
    final dashboard = context.read<DashboardCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final d = s.date;
    final iso =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final note = s.note.text.trim();
    setState(() => _saving = true);
    try {
      final r = await repo.addEntry(
        kind: SavingEntryKind.save,
        amount: s.amountValue,
        date: iso,
        goalId: s.goalId,
        walletId: s.account?.id,
        note: note.isEmpty ? null : note,
      );
      accounts.patchSavings(r.walletSavings);
      goals.markStale();
      dashboard.markStale();
      widget.onSavingSaved?.call(r);
      navigator.pop(true);
      showAppSnackBarOn(messenger, l.savingEntrySaved, tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: _saveSaving);
    }
  }

  /// Wallet default: the one used last, else the first — re-evaluated until
  /// the user picks one, so a cold cache doesn't leave it empty.
  Account? _defaultAccount(List<Account> accounts, {TxFormOptions? options}) {
    final preset = widget.account;
    if (preset != null) {
      // The cached row when there is one (fresher balance).
      return accounts.where((a) => a.id == preset.id).firstOrNull ?? preset;
    }
    if (accounts.isEmpty) return null;
    // The server's default wallet (form options) — no local "last used".
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

  // ── Recurring link ────────────────────────────────────────────────

  void _onLinkChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickRecurring() => _link.choose(
    context,
    type: _c.type,
    categoryId: _c.isTransfer ? null : _c.category?.id,
    amount: _c.amountValue > 0 ? _c.amountValue : null,
    createRoute: recurringCreateRoute(
      type: _c.type,
      amount: _c.amountValue,
      categoryId: _c.isTransfer ? null : _c.category?.id,
      accountId: _c.account?.id,
      name: _c.description.text,
    ),
  );

  /// Right after the create: the link call for the new [txId] (one extra
  /// call), then the amount question as a dialog. Returns a warning text when
  /// the link failed (the transaction is saved either way).
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
    final editing = _draftLike || _editingRow;
    final choice = await showChoiceDialog<_CloseChoice>(
      context,
      title: editing ? l.editDiscardTitle : l.quickUnsavedTitle,
      message: editing ? l.editDiscardMessage : l.quickUnsavedMessage,
      choices: [
        if (!editing && !_isEvent)
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
      // ฉัน + the people must make the amount exactly (owner 2026-10-11).
      if (!_c.splitsBalanced) return l.txSplitUnbalanced;
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
    var savedAsUpcoming = false;
    String? newTxId;
    try {
      if (event == null) {
        // ONE call (API v2): tags + splits ride in the create body, and the
        // answer carries the wallets' new balances — patched in place, no
        // GET /accounts after a save.
        final saved = await txCubit.add(
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
        accounts.patchBalances(saved.accountBalances);
        newTxId = saved.rows.firstOrNull?.id;
        // A date after today: an upcoming item, not a transaction.
        if (saved.isUpcoming) savedAsUpcoming = true;
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
        newTxId = txId;
        if (txId != null && tagIds.isNotEmpty) {
          try {
            await txRepo.setTags(txId, tagIds);
          } on ApiException {
            warn = l.txSavedTagsFailed;
          }
        }
        await TransactionsCubit.bookChanged();
        // The events list picks up a new event / bill — in place, no page.
        unawaited(projectsCubit.load());
        // The answer carries the new bill's wallet balance: patched in place.
        accounts.patchBalances(result.accountBalances);
      }
      warn ??= await _linkAfterCreate(newTxId);
      await _remember();
      // Stay where the user is: close + snackbar, never a tab switch or a
      // page push — an event bill too (owner 2026-10-10).
      navigator.pop(true);
      showAppSnackBarOn(
        messenger,
        warn ?? (savedAsUpcoming ? l.txSavedAsUpcoming : l.quickSaved),
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(
        context,
        e,
        retry: _save,
        message: event == null
            ? walletErrorMessage(l, e)
            : eventErrorMessage(l, e),
      );
    }
  }

  // ── Title-row summary ─────────────────────────────────────────────

  /// Only a new transaction swaps its title for the amount.
  bool get _summaryTitle => !_draftLike && !_isEvent;

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // A new plain transaction reads wallets from the form options (one
    // call); the other modes from the app-wide cache.
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
      title: _isEvent
          ? (_editingRow ? l.projectTxEditTitle : l.projectTxNewTitle)
          : _isEntry
          ? widget.entry!.title
          : _editingDraft
          ? l.pendingEditTitle
          : l.transactionFormTitleNew,
      // Only a new transaction swaps its title for the amount · category.
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
      // Event rows: one button — drafts are for one-off rows.
      saveLabel: _isEntry
          ? _entryAction(primary: true).label
          : _isEvent
          ? l.transactionFormSave
          : (_editingDraft ? l.pendingSubmitThis : l.quickSave),
      // Debt entries have no drafts.
      draftLabel: _isEntry
          ? _entrySecondary?.label
          : _isEvent || _isDebt || (_isSaving && !_isSavingDraft)
          ? null
          : l.pendingSaveDraft,
      onSave: _isEntry
          ? (waiting ? null : () => _runEntry(_entryAction(primary: true)))
          : _isSavingDraft
          ? _submitSavingDraft
          : _isDebt
          ? _saveDebt
          : _isSaving
          ? _saveSaving
          : _isEvent
          ? _saveEvent
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
                _activeEvent != null ||
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
            // A draft's first load: the EntryCard's skeleton until it's
            // prefilled (a new transaction shows the real card at once, so
            // typing can start; only its chip rows wait).
            : _draftLike && _draftBaseline == null
            ? const EntryCardSkeleton()
            : DraftForm(
                heroKey: _heroKey,
                // The pending drafts layout: chip rows, collapsible
                // หารกับ / อีเวนต์.
                chipLayout: _draftLike,
                // The entry card (wallet · category chip rows inside it),
                // tags outside: new transactions and drafts alike.
                chipRows: true,
                // A date after today → "รายการล่วงหน้า · จะเข้ารอยืนยัน…"
                // (owner 2026-10-13). No link here: leaving the sheet would
                // drop what's typed.
                upcomingHint: !_draftLike && !_isEvent,
                controller: _c,
                defaultAccount: _defaultAccount(accounts, options: options),
                // A saved project row keeps its type.
                typeLocked: _editingRow,
                event: _isEvent
                    ? DraftEvent(
                        members: widget.project!.currentMembers,
                        symbol: context.readUserCurrencySymbol,
                        pastDescriptions: _pastDescriptions,
                        tags: _eventTags,
                      )
                    : null,
                eventPending: _activeEvent != null,
                // The one "แบ่งรายการ" section, open (the heading
                // collapses it). Drafts keep their own event; here
                // the อีเวนต์ row only exists when creating, for a
                // type that can join one ([typeCanJoinEvent]).
                recurringSlot: _recurringSlot(l),
                eventSlot: !_draftLike && !_isEvent && typeCanJoinEvent(_c.type)
                    ? SplitEventSlot(
                        name: eventTargetName(l, _event),
                        onTap: _pickEvent,
                        onClear: _event == null
                            ? null
                            : () => setState(() => _event = null),
                      )
                    : null,
              ),
      ),
    );
  }

  /// The รายการประจำ row — a new transaction only (not a draft / event row).
  SplitRecurringSlot? _recurringSlot(AppLocalizations l) {
    if (_draftLike || _isEvent) return null;
    return _link.slot(
      context,
      type: _c.type,
      onTap: _pickRecurring,
      onClear: _link.clear,
      error: _toast,
      done: _toast,
    );
  }

  /// The mode chips on top (a new entry only), then the mode's body: the
  /// debt form, or [txBody].
  Widget _withModes(AppLocalizations l, Widget Function() txBody) {
    if (_isSavingDraft) {
      // A saving draft: the ออม form only, no mode chips.
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
