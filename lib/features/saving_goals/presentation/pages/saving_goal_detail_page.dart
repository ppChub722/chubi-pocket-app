import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_value_chip.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goal_status.dart';
import '../cubit/saving_goals_cubit.dart';

/// One saving goal — create (`/saving-goals/new`, [id] null), view
/// (`/saving-goals/:id`) and in-place edit ([startEditing] opens straight in
/// edit mode, for `/saving-goals/:id/edit`). Lifecycle is [EditModeMixin].
///
/// Header: icon + name + current amount, target, progress. Body: linked
/// wallet → target / allocation / deadline / description / note → stats
/// (locked while editing, absent on create). Edit mode ends with archive ·
/// delete.
///
/// **Spec quirks** baked in:
/// - `linked_account_id` is NOT editable (spec §3.4) — the wallet is picked
///   on create only.
/// - `allocation_pct` is optional on create — blank lets the server suggest
///   a default proportional to the wallet's other active goals.
/// - The icon uses [IconType.account] (no dedicated saving-goal pack yet).
class SavingGoalDetailPage extends StatefulWidget {
  const SavingGoalDetailPage({this.id, this.startEditing = false, super.key});

  /// Null = create.
  final String? id;

  /// Open an existing goal in edit mode.
  final bool startEditing;

  bool get isCreate => id == null;

  @override
  State<SavingGoalDetailPage> createState() => _SavingGoalDetailPageState();
}

/// Which text field a typing burst belongs to (undo grouping).
enum _Field { name, target, allocation, description, note }

class _SavingGoalDetailPageState extends State<SavingGoalDetailPage>
    with EditModeMixin<SavingGoalDetailPage, _GoalDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _allocationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// Last goal shown. After archive / delete the cubit drops it while this
  /// page is still animating away — keep painting it instead of flashing
  /// "not found".
  SavingGoal? _last;

  /// The goal the draft was last rebased on (deep-link arrival / refresh).
  SavingGoal? _seededFrom;

  /// [SavingGoalDetailPage.startEditing] on a goal that isn't loaded yet —
  /// enter edit mode once it arrives.
  bool _pendingEdit = false;

  /// Create: Save pressed without a wallet.
  bool _walletMissing = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      initDraft(const _GoalDraft(), editing: true);
    } else {
      final cached = context.read<SavingGoalsCubit>().byId(widget.id!);
      _seededFrom = cached;
      _last = cached;
      initDraft(
        cached == null ? const _GoalDraft() : _GoalDraft.from(cached),
        editing: widget.startEditing && cached != null,
      );
      _pendingEdit = widget.startEditing && cached == null;
    }
    onDraftRestored();
    // Deep links land here without the list ever loading; the wallet card
    // needs the accounts too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.isCreate) context.read<SavingGoalsCubit>().loadIfNeeded();
      context.read<AccountsCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _allocationCtrl.dispose();
    _descriptionCtrl.dispose();
    _noteCtrl.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  /// The goal arrived or changed in the cubit — rebase the draft (a no-op
  /// mid-edit) and honour a pending [SavingGoalDetailPage.startEditing].
  void _onGoalsChanged(BuildContext context, SavingGoalsState _) {
    if (widget.isCreate) return;
    final g = context.read<SavingGoalsCubit>().byId(widget.id!);
    if (g == null || g == _seededFrom) return;
    _seededFrom = g;
    resetDraft(_GoalDraft.from(g));
    if (_pendingEdit) {
      _pendingEdit = false;
      enterEdit();
    }
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => widget.isCreate;

  /// Back to the list — popping when possible, else (deep link) going there.
  @override
  void onDraftRestored() {
    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_nameCtrl, working.name);
    sync(_targetCtrl, working.target);
    sync(_allocationCtrl, working.allocation);
    sync(_descriptionCtrl, working.description);
    sync(_noteCtrl, working.note);
  }

  void _onText(_Field field, String v) =>
      applyTextChange(field, switch (field) {
        _Field.name => working.copyWith(name: v),
        _Field.target => working.copyWith(target: v),
        _Field.allocation => working.copyWith(allocation: v),
        _Field.description => working.copyWith(description: v),
        _Field.note => working.copyWith(note: v),
      });

  // ── Pickers ─────────────────────────────────────────────────────────

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.account,
      initial: working.iconCode,
      title: l.savingGoalFormIconLabel,
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      applyChange(working.copyWith(iconCode: result.iconCode));
    } else if (result is IconMakerRemoved) {
      applyChange(working.copyWith(clearIcon: true));
    }
  }

  void _enterEditThenOpenMaker() {
    enterEdit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openIconMaker();
    });
  }

  Future<void> _pickWallet(List<Account> accounts) async {
    final l = AppLocalizations.of(context)!;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selected: _accountById(working.accountId),
      title: l.savingGoalFormLinkedAccountLabel,
    );
    if (!mounted || r is! AccountPickerSelected) return;
    setState(() => _walletMissing = false);
    applyChange(working.copyWith(accountId: r.account.id));
  }

  /// Future dates only — but an existing past deadline stays pickable.
  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final current = working.deadline;
    final first = current != null && current.isBefore(now) ? current : now;
    final picked = await showAppDatePicker(
      context,
      initial: current ?? now.add(const Duration(days: 90)),
      first: first,
      last: DateTime(now.year + 20),
      clearable: current != null,
    );
    if (!mounted || picked == null) return;
    switch (picked) {
      case AppDatePicked(:final date):
        applyChange(working.copyWith(deadline: date));
      case AppDateCleared():
        applyChange(working.copyWith(clearDeadline: true));
    }
  }

  Account? _accountById(String? id) =>
      id == null ? null : context.read<AccountsCubit>().byId(id);

  // ── Save / archive / delete ─────────────────────────────────────────

  Future<void> _save(SavingGoal? goal) async {
    commitTextSession();
    final formOk = _formKey.currentState?.validate() ?? false;
    final walletOk = !widget.isCreate || working.accountId != null;
    if (!walletOk) setState(() => _walletMissing = true);
    if (!formOk || !walletOk) return;

    final cubit = context.read<SavingGoalsCubit>();
    final w = working;
    final description = w.description.trim();
    final note = w.note.trim();
    final allocation = double.tryParse(w.allocation.trim()) ?? 0;
    final deadline = w.deadline == null ? null : _isoDate(w.deadline!);
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (widget.isCreate) {
        final account = _accountById(w.accountId);
        await cubit.add(
          SavingGoal(
            id: 'draft',
            name: w.name.trim(),
            targetAmount: AmountInput.parse(w.target)!,
            linkedAccountId: w.accountId!,
            // 0 = omitted on the wire → the server suggests one.
            allocationPct: allocation,
            currency: account?.currency ?? 'THB',
            status: SavingGoalStatus.active,
            deadline: deadline,
            iconCode: w.iconCode,
            description: description.isEmpty ? null : description,
            note: note.isEmpty ? null : note,
          ),
        );
      } else {
        final g = goal!;
        await cubit.update(
          SavingGoal(
            id: g.id,
            name: w.name.trim(),
            targetAmount: AmountInput.parse(w.target)!,
            linkedAccountId: g.linkedAccountId,
            allocationPct: allocation > 0 ? allocation : g.allocationPct,
            currency: g.currency,
            status: g.status,
            deadline: deadline,
            iconCode: w.iconCode,
            description: description.isEmpty ? null : description,
            note: note.isEmpty ? null : note,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    if (widget.isCreate) {
      leavePage();
      return;
    }
    // The server's copy (recomputed progress etc.) becomes the baseline.
    final saved = cubit.byId(goal!.id);
    _seededFrom = saved;
    commitSaved(saved == null ? w.trimmed() : _GoalDraft.from(saved));
  }

  Future<void> _archive(SavingGoal g) {
    final l = AppLocalizations.of(context)!;
    return _confirmAndLeave(
      title: l.savingGoalArchiveConfirmTitle,
      body: l.savingGoalArchiveConfirmBody,
      action: l.savingGoalArchiveConfirmAction,
      run: (c) => c.archive(g.id),
    );
  }

  Future<void> _delete(SavingGoal g) {
    final l = AppLocalizations.of(context)!;
    return _confirmAndLeave(
      title: l.savingGoalDeleteConfirmTitle,
      body: l.savingGoalDeleteConfirmBody,
      action: l.savingGoalDeleteConfirmAction,
      run: (c) => c.remove(g.id),
    );
  }

  /// Confirm → run (archive / delete — either way the goal leaves the
  /// active list) → back to the list. [_last] keeps the page painted while
  /// it animates away.
  Future<void> _confirmAndLeave({
    required String title,
    required String body,
    required String action,
    required Future<void> Function(SavingGoalsCubit) run,
  }) async {
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: body,
      confirmLabel: action,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await run(context.read<SavingGoalsCubit>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    // Close edit mode without the discard prompt — the goal is gone.
    commitSaved(working);
    leavePage();
  }

  static String _isoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<SavingGoalsCubit, SavingGoalsState>(
      listener: _onGoalsChanged,
      builder: (context, state) {
        SavingGoal? goal;
        if (!widget.isCreate) {
          goal = context.read<SavingGoalsCubit>().byId(widget.id!) ?? _last;
          if (goal == null) return _fallback(l, state);
          _last = goal;
        }
        return _page(l, goal);
      },
    );
  }

  /// Not in the cache yet: skeleton while (about to be) loading, error +
  /// retry, and "not found" only once a load finished without it.
  Widget _fallback(AppLocalizations l, SavingGoalsState state) {
    return Scaffold(
      appBar: AppTopBar(title: l.savingGoalsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: AsyncStateView.fallback(
        loading:
            state.status == SavingGoalsStatus.initial ||
            state.status == SavingGoalsStatus.loading,
        error: state.error,
        onRetry: context.read<SavingGoalsCubit>().load,
        notFound: EmptyView(
          icon: AppIcons.empty,
          title: l.savingGoalDetailNotFound,
          message: l.savingGoalDetailNotFoundMessage,
        ),
      ),
    );
  }

  /// Titles never change with the mode (owner, QA T1): the goal's name in
  /// view and edit alike.
  String _title(AppLocalizations l, SavingGoal? goal) {
    if (widget.isCreate) return l.savingGoalFormTitle;
    return goal!.name;
  }

  Widget _page(AppLocalizations l, SavingGoal? goal) {
    final editing = isEditing;
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: _title(l, goal),
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: its context sees the floating bar's height.
          child: Builder(
            builder: (context) => DetailPageBody(
              onRefresh: widget.isCreate
                  ? null
                  : () => context.read<SavingGoalsCubit>().load(),
              physics: const AlwaysScrollableScrollPhysics(),
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              hero: _header(l, goal),
              sections: [
                (first) => _fields(l, goal, first),
                (first) => goal == null ? null : _stats(l, goal, first),
                (first) => _texts(l, first),
              ],
              // Archive · delete — edit only, always last (the top bar
              // carries no page actions).
              manage: editing && goal != null
                  ? ManageSection(
                      archiveLabel: l.savingGoalDetailArchive,
                      onArchive: isSaving ? null : () => _archive(goal),
                      deleteLabel: l.savingGoalDeleteThis,
                      onDelete: isSaving ? null : () => _delete(goal),
                    )
                  : null,
              metaLines: goal == null
                  ? const []
                  : detailMetaLines(
                      context,
                      createdAt: goal.createdAt,
                      updatedAt: goal.updatedAt,
                    ),
            ),
          ),
        ),
        bottomNavigationBar: editing
            ? editActionBar(onSave: () => _save(goal))
            : null,
      ),
    );
  }

  String _symbol(SavingGoal? goal) {
    if (goal != null) return Currencies.symbolOf(goal.currency);
    final account = _accountById(working.accountId);
    return Currencies.symbolOf(account?.currency ?? 'THB');
  }

  /// View: ✏️ chip → edit; long-press the icon → edit + maker. Edit: tap the
  /// icon → maker. Create has no progress yet, so no footer.
  Widget _header(AppLocalizations l, SavingGoal? goal) {
    final editing = isEditing;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = working.iconCode.tintFor(palette);
    final symbol = _symbol(goal);
    return HeaderCard(
      accent: accent,
      glyph: AppIcons.savingGoal,
      onEdit: editing ? null : enterEdit,
      topRow: [
        if (goal != null && goal.isCompleted)
          AppChip(
            label: l.savingGoalCompletedLabel,
            icon: AppIcons.success,
            tone: AppChipTone.success,
            selected: true,
          ),
      ],
      // EditableCircle keeps its footprint with or without onTap, so the
      // name never shifts between modes.
      leading: EditableCircle(
        size: 52,
        onTap: editing ? _openIconMaker : null,
        onLongPress: editing ? null : _enterEditThenOpenMaker,
        child: IconDisplay(
          type: IconType.account,
          size: 52,
          iconCode: working.iconCode,
        ),
      ),
      title: HeroNameInput(
        editing: editing,
        controller: _nameCtrl,
        focusNode: _nameFocus,
        hint: l.commonName,
        maxLength: TextLimits.name,
        onEnterEdit: () => enterEdit(focus: _nameFocus),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? l.savingGoalFormNameRequired
            : null,
      ),
      description: HeroDescription(
        controller: _descriptionCtrl,
        editing: editing,
        hint: l.commonDescription,
        maxLength: TextLimits.description,
        focusNode: _descriptionFocus,
        onEnterEdit: () => enterEdit(focus: _descriptionFocus),
        onChanged: (v) => _onText(_Field.description, v),
      ),
      footer: goal == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyText(
                  goal.currentAmount,
                  symbol: symbol,
                  style: AppTypography.of(
                    context,
                    AppTextRole.display,
                  )?.copyWith(color: accent),
                ),
                AppText(
                  l.savingGoalDetailOfTarget(
                    moneyString(context, goal.targetAmount, symbol: symbol),
                  ),
                  role: AppTextRole.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                ProgressRow(
                  value: goal.progressPct / 100,
                  color: accent,
                  trailing: '${goal.progressPct.toStringAsFixed(0)}%',
                ),
              ],
            ),
    );
  }

  /// The linked wallet row. Picked on create only (spec §3.4) — locked
  /// (🔒) while editing an existing goal.
  Widget _walletRow(AppLocalizations l, SavingGoal? goal) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final id = goal?.linkedAccountId ?? working.accountId;
        final account = id == null
            ? null
            : context.read<AccountsCubit>().byId(id);
        // Not among the active wallets (archived / still loading) — the
        // goal's embedded ref still names it.
        final name = account?.name ?? goal?.linkedAccount?.name;
        final iconCode = account?.iconCode ?? goal?.linkedAccount?.iconCode;
        final row = DetailRow.pick(
          label: l.savingGoalFormLinkedAccountLabel,
          valueChip: name == null
              ? null
              : walletValueChip(context, name: name, iconCode: iconCode),
          emptyText: l.quickEventNone,
          locked: goal != null && isEditing,
          onTap: goal == null ? () => _pickWallet(state.accounts) : null,
        );
        if (!_walletMissing || goal != null) return row;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppMessage(
                message: l.savingGoalFormAccountRequired,
                tone: Tone.danger,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fields(AppLocalizations l, SavingGoal? goal, bool first) {
    final editing = isEditing;
    final symbol = _symbol(goal);
    final deadline = working.deadline;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SectionCard(
      first: first,
      children: [
        _walletRow(l, goal),
        if (editing)
          DetailStacked(
            label: l.savingGoalFormTargetLabel,
            child: AmountInput(
              controller: _targetCtrl,
              currencySymbol: symbol,
              onChanged: (v) => _onText(_Field.target, v),
              validator: (v) {
                final n = AmountInput.parse(v);
                return (n == null || n <= 0)
                    ? l.savingGoalFormTargetInvalid
                    : null;
              },
            ),
          )
        else
          DetailRow(
            label: l.savingGoalFormTargetLabel,
            trailing: MoneyText(goal!.targetAmount, symbol: symbol),
          ),
        DetailRow(
          label: l.savingGoalFormAllocationLabel,
          trailing: editing
              ? AppInput(
                  type: AppInputType.percent,
                  decimals: 2,
                  dense: true,
                  controller: _allocationCtrl,
                  maxLength: 6,
                  // Blank on create = the server suggests a share.
                  hint: widget.isCreate ? l.savingGoalAllocationAuto : null,
                  onChanged: (v) => _onText(_Field.allocation, v),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null; // optional
                    final n = double.tryParse(t);
                    return (n == null || n <= 0 || n > 100)
                        ? l.savingGoalFormAllocationInvalid
                        : null;
                  },
                )
              : AppText('${working.allocation}%'),
        ),
        // Live in view mode too: picking a date enters edit mode.
        DetailRow(
          label: l.savingGoalFormDeadlineLabel,
          trailing: deadline == null
              ? DetailPlaceholder(l.savingGoalFormDeadlinePlaceholder)
              : AppText(DateFormatter.medium(deadline, locale: locale)),
          showChevron: true,
          onTap: () {
            // Empty in view mode: tapping starts adding it (edit + picker).
            if (!isEditing) enterEdit();
            _pickDeadline();
          },
        ),
      ],
    );
  }

  /// Note — stacked (label above); the template merges this into the top
  /// box after the rows and stats. (The description lives in the hero.)
  Widget _texts(AppLocalizations l, bool first) {
    final editing = isEditing;
    return SectionCard(
      first: first,
      children: [
        DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: editing,
            controller: _noteCtrl,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            viewHint: AppLocalizations.of(context)!.commonLongPressToEdit,
            onEnterEdit: () => enterEdit(focus: _noteFocus),
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ],
    );
  }

  /// Server-computed numbers — read-only, 🔒 while editing.
  Widget _stats(AppLocalizations l, SavingGoal g, bool first) {
    final symbol = Currencies.symbolOf(g.currency);
    return SectionCard(
      first: first,
      children: [
        DetailRow(
          locked: isEditing,
          label: l.savingGoalDetailRemaining,
          trailing: MoneyText(g.remainingAmount, symbol: symbol),
        ),
        if (g.daysRemaining != null)
          DetailRow(
            locked: isEditing,
            label: l.savingGoalDetailDaysRemaining,
            trailing: AppText(l.savingGoalDetailDaysValue(g.daysRemaining!)),
          ),
        if (g.requiredMonthly != null)
          DetailRow(
            locked: isEditing,
            label: l.savingGoalDetailRequiredMonthly,
            trailing: MoneyText(g.requiredMonthly!, symbol: symbol),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Immutable editing snapshot — drives dirty-check + undo history.
// ────────────────────────────────────────────────────────────────────

class _GoalDraft {
  const _GoalDraft({
    this.name = '',
    this.target = '',
    this.allocation = '',
    this.deadline,
    this.iconCode,
    this.description = '',
    this.note = '',
    this.accountId,
  });

  factory _GoalDraft.from(SavingGoal g) => _GoalDraft(
    name: g.name,
    target: AmountInput.format(g.targetAmount),
    allocation: _pct(g.allocationPct),
    deadline: g.deadline == null ? null : DateTime.tryParse(g.deadline!),
    iconCode: g.iconCode,
    description: g.description ?? '',
    note: g.note ?? '',
    accountId: g.linkedAccountId,
  );

  final String name;

  /// Formatted text, as in the fields.
  final String target;
  final String allocation;
  final DateTime? deadline;
  final IconCode? iconCode;
  final String description;
  final String note;

  /// Linked wallet — chosen on create only.
  final String? accountId;

  /// 25.0 → "25", 12.5 → "12.5".
  static String _pct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// What the server stores (text trimmed) — the post-save fallback baseline.
  _GoalDraft trimmed() => copyWith(
    name: name.trim(),
    allocation: allocation.trim(),
    description: description.trim(),
    note: note.trim(),
  );

  _GoalDraft copyWith({
    String? name,
    String? target,
    String? allocation,
    DateTime? deadline,
    bool clearDeadline = false,
    IconCode? iconCode,
    bool clearIcon = false,
    String? description,
    String? note,
    String? accountId,
  }) => _GoalDraft(
    name: name ?? this.name,
    target: target ?? this.target,
    allocation: allocation ?? this.allocation,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    description: description ?? this.description,
    note: note ?? this.note,
    accountId: accountId ?? this.accountId,
  );

  @override
  bool operator ==(Object other) =>
      other is _GoalDraft &&
      other.name == name &&
      other.target == target &&
      other.allocation == allocation &&
      other.deadline == deadline &&
      other.iconCode == iconCode &&
      other.description == description &&
      other.note == note &&
      other.accountId == accountId;

  @override
  int get hashCode => Object.hash(
    name,
    target,
    allocation,
    deadline,
    iconCode,
    description,
    note,
    accountId,
  );
}
