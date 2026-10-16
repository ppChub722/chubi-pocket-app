import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_entry.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goals_overview.dart';
import '../cubit/saving_goal_cubit.dart';
import '../cubit/saving_goals_cubit.dart';
import '../widgets/saving_goal_texts.dart';

/// One saving goal — create (`/saving-goals/new`, [id] null), view
/// (`/saving-goals/:id`) and in-place edit ([startEditing]).
///
/// Open = ONE call (`GET /saving-goals/{id}`: goal + by-wallet + history +
/// entries); every button = ONE call whose answer replaces the state. A goal
/// is a name, a target and a deadline over a notebook of saving entries; no
/// wallet link and no % (goals v2).
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
enum _Field { name, target, description, note }

class _SavingGoalDetailPageState extends State<SavingGoalDetailPage>
    with EditModeMixin<SavingGoalDetailPage, _GoalDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  SavingGoalCubit? _cubit;

  /// The goal the draft was last rebased on (arrival / refresh).
  SavingGoal? _seededFrom;

  /// [SavingGoalDetailPage.startEditing] before the goal arrived.
  bool _pendingEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) {
      initDraft(const _GoalDraft(), editing: true);
    } else {
      _cubit = SavingGoalCubit(
        repository: context.read<SavingGoalsRepository>(),
        id: widget.id!,
      );
      initDraft(const _GoalDraft(), editing: false);
      _pendingEdit = widget.startEditing;
      WidgetsBinding.instance.addPostFrameCallback((_) => _cubit?.load());
    }
    onDraftRestored();
  }

  @override
  void dispose() {
    _cubit?.close();
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descriptionCtrl.dispose();
    _noteCtrl.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  /// The goal arrived or changed — rebase the draft (a no-op mid-edit) and
  /// honour a pending [SavingGoalDetailPage.startEditing].
  void _onState(BuildContext context, SavingPageState state) {
    final g = state.detail?.goal;
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

  @override
  void onDraftRestored() {
    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_nameCtrl, working.name);
    sync(_targetCtrl, working.target);
    sync(_descriptionCtrl, working.description);
    sync(_noteCtrl, working.note);
  }

  void _onText(_Field field, String v) =>
      applyTextChange(field, switch (field) {
        _Field.name => working.copyWith(name: v),
        _Field.target => working.copyWith(target: v),
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

  // ── Writes ──────────────────────────────────────────────────────────

  /// Tells the list (and through it Home) that savings changed.
  void _listChanged() =>
      context.read<SavingGoalsCubit>().markStale(silent: true);

  Future<void> _save(SavingGoal? goal) async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    final description = w.description.trim();
    final note = w.note.trim();
    final draft = SavingGoal(
      id: goal?.id ?? 'draft',
      name: w.name.trim(),
      targetAmount: AmountInput.parse(w.target)!,
      currency: goal?.currency ?? '',
      deadline: w.deadline == null ? null : _isoDate(w.deadline!),
      iconCode: w.iconCode,
      description: description.isEmpty ? null : description,
      note: note.isEmpty ? null : note,
    );
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (widget.isCreate) {
        await context.read<SavingGoalsRepository>().create(draft);
      } else {
        await _cubit!.update(draft);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _listChanged();
    if (widget.isCreate) {
      leavePage();
      return;
    }
    // The server's copy becomes the baseline.
    final saved = _cubit!.state.detail?.goal;
    _seededFrom = saved;
    commitSaved(saved == null ? w.trimmed() : _GoalDraft.from(saved));
  }

  /// Runs a write; shows the message on failure, keeps the page as is.
  Future<bool> _run(Future<void> Function() write) async {
    setSaving(true);
    try {
      await write();
    } on ApiException catch (e) {
      if (mounted) {
        setSaving(false);
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
      return false;
    }
    if (mounted) setSaving(false);
    _listChanged();
    return true;
  }

  Future<void> _archive() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.savingGoalArchiveConfirmTitle,
      message: l.savingGoalArchiveConfirmBody,
      confirmLabel: l.savingGoalArchiveConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    if (await _run(_cubit!.archive) && mounted) {
      commitSaved(working);
      leavePage();
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.savingGoalDeleteConfirmTitle,
      message: l.savingGoalDeleteConfirmBody,
      confirmLabel: l.savingGoalDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    if (await _run(_cubit!.delete) && mounted) {
      commitSaved(working);
      leavePage();
    }
  }

  Future<void> _restore() => _run(_cubit!.restore);

  Future<void> _close(SavingGoal g, List<SavingWalletShare> wallets) async {
    final l = AppLocalizations.of(context)!;
    final symbol = context.readUserCurrencySymbol;
    final choice = await showCloseGoalDialog(
      context,
      title: l.sgv2CloseTitle(g.name),
      message: l.sgv2CloseBody(
        moneyString(context, g.savedAmount, symbol: symbol),
      ),
      returnsTitle: l.sgv2ReturnsTitle,
      returns: [
        for (final w in wallets) (wallet: w.wallet.name, amount: w.amount),
      ],
      toSpareLabel: l.sgv2CloseToSpare,
      backToWalletsLabel: l.sgv2CloseToWallets,
      cancelLabel: l.sgv2Cancel,
    );
    if (choice == null || !mounted) return;
    await _run(
      () =>
          _cubit!.closeGoal(toWallets: choice == CloseGoalChoice.backToWallets),
    );
  }

  /// Tap an entry → confirm → delete (one call; the answer is the new page).
  Future<void> _deleteEntry(SavingEntry e) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: _entryTitle(l, e),
      message: moneyString(context, e.amount),
      confirmLabel: l.savingGoalDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(() => _cubit!.deleteEntry(e.id));
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
    if (widget.isCreate) return _page(l, null, null);
    return MultiBlocListener(
      listeners: [
        // A transaction write / a saving written elsewhere (the + sheet,
        // a pending draft): this page's figures moved — one reload.
        BlocListener<TransactionsCubit, TransactionsState>(
          listenWhen: _bookMoved,
          listener: (_, _) => _reloadQuietly(),
        ),
        BlocListener<SavingGoalsCubit, SavingGoalsState>(
          listenWhen: (a, b) => a.staleTick != b.staleTick,
          listener: (_, _) => _reloadQuietly(),
        ),
      ],
      child: BlocProvider.value(
        value: _cubit!,
        child: BlocConsumer<SavingGoalCubit, SavingPageState>(
          listener: _onState,
          builder: (context, state) {
            final d = state.detail;
            if (d == null) return _fallback(l, state);
            if (d.isSpare) return _spare(l, d, state);
            return _page(l, d, state);
          },
        ),
      ),
    );
  }

  static bool _bookMoved(TransactionsState a, TransactionsState b) =>
      a.revision != b.revision || !identical(a.transactions, b.transactions);

  void _reloadQuietly() {
    if (!mounted || isEditing || isSaving) return;
    _cubit?.load();
  }

  /// No data yet: skeleton on the first load, error + retry (never lose a
  /// loaded page to a failed refresh).
  Widget _fallback(AppLocalizations l, SavingPageState state) {
    return Scaffold(
      appBar: AppTopBar(title: l.savingGoalsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: AsyncStateView.fallback(
        loading: state.status == SavingPageStatus.loading,
        error: state.error,
        onRetry: _cubit!.load,
        notFound: EmptyView(
          icon: AppIcons.empty,
          title: l.savingGoalDetailNotFound,
          message: l.savingGoalDetailNotFoundMessage,
        ),
      ),
    );
  }

  Widget _page(AppLocalizations l, SavingGoalDetail? d, SavingPageState? s) {
    final editing = isEditing;
    final goal = d?.goal;
    final page = editScope(
      Scaffold(
        appBar: AppTopBar(
          // Titles never change with the mode.
          title: goal?.name ?? l.savingGoalFormTitle,
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          child: Builder(
            builder: (context) => DetailPageBody(
              onRefresh: widget.isCreate ? null : _cubit!.load,
              physics: const AlwaysScrollableScrollPhysics(),
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              hero: _header(l, goal),
              sections: [
                (first) => _basics(l, goal, first),
                (first) => d == null || editing ? null : _actions(l, d, first),
                (first) => d == null || editing ? null : _overview(l, d, first),
                (first) => d == null || editing ? null : _byWallet(l, d, first),
                (first) =>
                    d == null || editing ? null : _entries(l, d, s, first),
              ],
              manage: _manage(l, d),
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
    // The shell's centre + adds savings into THIS goal while it is on screen.
    if (goal == null) return page;
    return QuickCreatePresetScope(
      preset: QuickCreatePreset.saving(goalId: goal.id),
      child: page,
    );
  }

  Widget? _manage(AppLocalizations l, SavingGoalDetail? d) {
    final goal = d?.goal;
    if (goal == null) return null;
    final a = goal.actions;
    if (isEditing) {
      return ManageSection(
        archiveLabel: l.savingGoalDetailArchive,
        onArchive: isSaving || !a.archive ? null : _archive,
        deleteLabel: l.savingGoalDeleteThis,
        onDelete: isSaving || !a.delete ? null : _delete,
      );
    }
    // The BE says which of close / restore is allowed (thin FE).
    // TODO(kit): a plain button slot (ManageSection is edit-only).
    if (!a.close && !a.restore) return null;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: a.restore
          ? AppButton(
              label: l.sgv2Restore,
              variant: AppButtonVariant.outlined,
              expand: true,
              submits: true,
              onPressed: isSaving ? null : _restore,
            )
          : AppButton(
              label: l.sgv2CloseGoal,
              variant: AppButtonVariant.outlined,
              expand: true,
              submits: true,
              onPressed: isSaving ? null : () => _close(goal, d!.byWallet),
            ),
    );
  }

  /// The spare bucket page (GET /saving-goals/spare): total, by wallet, entries.
  Widget _spare(AppLocalizations l, SavingGoalDetail d, SavingPageState s) {
    final symbol = context.readUserCurrencySymbol;
    return Scaffold(
      appBar: AppTopBar(title: l.sgv2SpareTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: Builder(
        builder: (context) => DetailPageBody(
          onRefresh: _cubit!.load,
          topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
          bottomInset: AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
          hero: HeaderCard(
            accent: Theme.of(context).colorScheme.primary,
            glyph: AppIcons.savingGoal,
            leading: const Icon(AppIcons.savingGoal, size: 40),
            title: AppText(l.sgv2SpareTitle, role: AppTextRole.title),
            description: AppText(l.sgv2SpareHint, role: AppTextRole.caption),
            footer: MoneyText(
              d.spare?.amount ?? 0,
              symbol: symbol,
              style: AppTypography.of(context, AppTextRole.display),
            ),
          ),
          sections: [
            (first) => _byWallet(l, d, first),
            (first) => _entries(l, d, s, first),
          ],
        ),
      ),
    );
  }

  /// View: ✏️ chip → edit; long-press the icon → edit + maker. Edit: tap the
  /// icon → maker. Create has no progress yet, so no footer.
  Widget _header(AppLocalizations l, SavingGoal? goal) {
    final editing = isEditing;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = working.iconCode.tintFor(palette);
    final symbol = context.readUserCurrencySymbol;
    return HeaderCard(
      accent: accent,
      glyph: AppIcons.savingGoal,
      onEdit: editing ? null : enterEdit,
      topRow: [?goal == null ? null : savingGoalStatusChip(l, goal)],
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
          : ProgressHeroFooter(
              amount: goal.savedAmount,
              caption: l.savingGoalDetailOfTarget(
                moneyString(context, goal.targetAmount, symbol: symbol),
              ),
              value: goal.progressPct / 100,
              color: accent,
              tone: goal.isCompleted || goal.pace == SavingPace.reached
                  ? ProgressTone.success
                  : ProgressTone.neutral,
            ),
    );
  }

  /// Heading-less top box: target, deadline, auto-save, note.
  Widget _basics(AppLocalizations l, SavingGoal? goal, bool first) {
    final editing = isEditing;
    final symbol = context.readUserCurrencySymbol;
    final deadline = working.deadline;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SectionCard(
      first: first,
      children: [
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
        else if (goal != null)
          DetailRow(
            label: l.savingGoalFormTargetLabel,
            trailing: MoneyText(goal.targetAmount, symbol: symbol),
          ),
        // Live in view mode too: picking a date enters edit mode.
        DetailRow(
          label: l.savingGoalFormDeadlineLabel,
          trailing: deadline == null
              ? DetailPlaceholder(l.savingGoalFormDeadlinePlaceholder)
              : AppText(DateFormatter.medium(deadline, locale: locale)),
          showChevron: true,
          onTap: () {
            if (!isEditing) enterEdit();
            _pickDeadline();
          },
        ),
        DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: editing,
            controller: _noteCtrl,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            viewHint: l.commonLongPressToEdit,
            onEnterEdit: () => enterEdit(focus: _noteFocus),
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ],
    );
  }

  /// เพิ่มเงินออม / ถอน / ย้าย — one button = one sheet = one call. The BE's
  /// `actions` flags say which are allowed.
  Widget _actions(AppLocalizations l, SavingGoalDetail d, bool first) {
    final g = d.goal!;
    final a = g.actions;
    return ActionBar(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      actions: [
        ActionBarItem(
          label: l.sgv2ActionAdd,
          icon: AppIcons.savingDeposit,
          primary: true,
          submits: true,
          onPressed: a.save && !isSaving ? () => _addSaving(g) : null,
        ),
        ActionBarItem(
          label: l.sgv2ActionWithdraw,
          icon: AppIcons.savingWithdraw,
          submits: true,
          onPressed: a.withdraw && !isSaving ? () => _withdraw(d) : null,
        ),
        ActionBarItem(
          label: l.sgv2ActionMove,
          icon: AppIcons.savingAllocate,
          submits: true,
          onPressed: a.move && !isSaving ? () => _move(d) : null,
        ),
      ],
    );
  }

  /// Largest-first split of [amount] over the wallets that hold the money
  /// (instant feedback while typing; the BE recomputes when no split is sent).
  List<SavingSplitRow> _splitRows(
    AppLocalizations l,
    List<SavingWalletShare> wallets,
    double amount,
  ) {
    final sorted = [...wallets]..sort((a, b) => b.amount.compareTo(a.amount));
    var left = amount;
    return [
      for (final w in sorted)
        () {
          final take = left <= 0 ? 0.0 : (left < w.amount ? left : w.amount);
          left -= take;
          return SavingSplitRow(
            walletId: w.wallet.id,
            name: w.wallet.name,
            amount: take,
            availableText: l.sgv2SplitHas(moneyString(context, w.amount)),
          );
        }(),
    ];
  }

  Future<void> _withdraw(SavingGoalDetail d) async {
    final l = AppLocalizations.of(context)!;
    final g = d.goal!;
    final amount = g.savedAmount;
    final parts = await showSavingMoveSheet(
      context,
      title: l.sgv2WithdrawTitle,
      from: SavingMoveEnd(
        caption: l.sgv2MoveFrom,
        name: g.name,
        subtitle: moneyString(context, g.savedAmount),
      ),
      to: SavingMoveEnd(caption: l.sgv2MoveTo, name: l.sgv2WalletsCard),
      amount: amount,
      splits: _splitRows(l, d.byWallet, amount),
      amountLabel: l.sgv2AmountLabel,
      splitTitle: l.sgv2SplitTitle,
      editLabel: l.sgv2SplitEdit,
      saveLabel: l.sgv2WithdrawSave,
      sumOkText: (s) => l.sgv2SumOk(moneyString(context, s)),
      sumOffText: (s, a) =>
          l.sgv2SumOff(moneyString(context, s), moneyString(context, a)),
      autoSplit: (v) => [
        for (final r in _splitRows(l, d.byWallet, v))
          (walletId: r.walletId, amount: r.amount),
      ],
    );
    if (parts == null || !mounted) return;
    final total = parts.fold<double>(0, (s, p) => s + p.amount);
    await _run(
      () => _cubit!.addEntry(
        kind: SavingEntryKind.withdraw,
        amount: total,
        date: _isoDate(DateTime.now()),
        splits: [
          for (final p in parts)
            SavingSplit(walletId: p.walletId, amount: p.amount),
        ],
      ),
    );
  }

  Future<void> _move(SavingGoalDetail d) async {
    final l = AppLocalizations.of(context)!;
    final g = d.goal!;
    // Where to? The spare bucket or another goal — ONE list call on demand.
    final overview = await context.read<SavingGoalsRepository>().list();
    if (!mounted) return;
    final target = await showOptionSheet<String>(
      context,
      title: l.sgv2MovePick,
      options: [
        SheetOption(
          value: SavingGoalsRepository.spareId,
          label: l.sgv2SpareName,
        ),
        for (final o in overview.goals)
          if (o.id != g.id) SheetOption(value: o.id, label: o.name),
      ],
    );
    if (target == null || !mounted) return;
    final toSpare = target == SavingGoalsRepository.spareId;
    final targetName = toSpare
        ? l.sgv2SpareName
        : overview.goals.firstWhere((o) => o.id == target).name;
    final amount = g.savedAmount;
    final parts = await showSavingMoveSheet(
      context,
      title: l.sgv2MoveTitle,
      from: SavingMoveEnd(
        caption: l.sgv2MoveFrom,
        name: g.name,
        subtitle: moneyString(context, g.savedAmount),
      ),
      to: SavingMoveEnd(caption: l.sgv2MoveTo, name: targetName),
      amount: amount,
      splits: _splitRows(l, d.byWallet, amount),
      amountLabel: l.sgv2AmountLabel,
      splitTitle: l.sgv2SplitTitle,
      editLabel: l.sgv2SplitEdit,
      saveLabel: l.sgv2MoveSave,
      sumOkText: (s) => l.sgv2SumOk(moneyString(context, s)),
      sumOffText: (s, a) =>
          l.sgv2SumOff(moneyString(context, s), moneyString(context, a)),
      autoSplit: (v) => [
        for (final r in _splitRows(l, d.byWallet, v))
          (walletId: r.walletId, amount: r.amount),
      ],
    );
    if (parts == null || !mounted) return;
    final total = parts.fold<double>(0, (s, p) => s + p.amount);
    await _run(
      () => _cubit!.addEntry(
        kind: SavingEntryKind.move,
        amount: total,
        date: _isoDate(DateTime.now()),
        toGoalId: toSpare ? null : target,
        toSpare: toSpare,
        splits: [
          for (final p in parts)
            SavingSplit(walletId: p.walletId, amount: p.amount),
        ],
      ),
    );
  }

  /// The quick-create sheet in ออม mode, the goal preselected.
  Future<void> _addSaving(SavingGoal g) async {
    final saved = await showQuickCreateSheet(
      context,
      preset: QuickCreatePreset.saving(goalId: g.id),
    );
    if (saved && mounted) {
      _listChanged();
      await _cubit!.load();
    }
  }

  /// Needed / actual pace / ETA / time left (BE numbers), the milestones and
  /// the history chart.
  Widget _overview(AppLocalizations l, SavingGoalDetail d, bool first) {
    final g = d.goal!;
    final symbol = context.readUserCurrencySymbol;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final eta = g.etaDate == null ? null : DateTime.tryParse(g.etaDate!);
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = g.iconCode.tintFor(palette);
    String m(double v) => moneyString(context, v, symbol: symbol);
    final nextIdx = g.milestones.indexWhere((s) => !s.reached);
    final history = [for (final p in d.history) p.cumulative];
    final pace = g.paceMonthly ?? 0;
    // Months from the last actual point to the deadline / ETA, at the pace.
    final ahead = (g.daysRemaining ?? 0) > 0
        ? ((g.daysRemaining! / 30.44).ceil()).clamp(0, 24)
        : 0;
    final projection = <double>[
      if (pace > 0 && history.isNotEmpty && !g.isCompleted)
        for (var i = 1; i <= ahead; i++) history.last + pace * i,
    ];
    return SectionCard(
      first: first,
      title: l.sgv2Overview,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: StatGrid(
            children: [
              if (g.neededMonthly != null)
                StatTile(
                  caption: l.sgv2NeededMonthly,
                  value: m(g.neededMonthly!),
                ),
              if (g.paceMonthly != null)
                StatTile(caption: l.sgv2PaceMonthly, value: m(g.paceMonthly!)),
              if (eta != null)
                StatTile(
                  caption: l.sgv2Eta,
                  value: DateFormatter.medium(eta, locale: locale),
                  tone: g.pace == SavingPace.late ? Tone.warning : Tone.neutral,
                ),
              if (g.daysRemaining != null)
                StatTile(
                  caption: l.sgv2TimeLeft,
                  value: l.savingGoalDetailDaysValue(g.daysRemaining!),
                ),
            ],
          ),
        ),
        if (g.milestones.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: MilestoneRow(
              color: accent,
              steps: [
                for (final (i, s) in g.milestones.indexed)
                  MilestoneStep(
                    label: s.pct == 100 || i == nextIdx
                        ? m(s.amount)
                        : '${s.pct}%',
                    state: s.reached
                        ? MilestoneState.done
                        : (i == nextIdx
                              ? MilestoneState.next
                              : MilestoneState.todo),
                    glyph: s.reached ? '✓' : (s.pct == 100 ? '🏁' : '${s.pct}'),
                  ),
              ],
            ),
          ),
        if (history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SavingHistoryChart(
              actual: history,
              projection: projection,
              target: g.targetAmount,
              color: accent,
              monthLabels: [for (final p in d.history) p.month.substring(5)],
              caption: l.sgv2ChartCaption,
              targetLabel: l.sgv2ChartTarget(m(g.targetAmount)),
              actualLegend: l.sgv2ChartActual,
              neededLegend: l.sgv2ChartNeeded,
            ),
          ),
        DetailRow(
          label: l.sgv2AutoSave,
          trailing: DetailPlaceholder(
            d.autoSave.isEmpty ? l.sgv2AutoSaveNone : d.autoSave.first.name,
          ),
          showChevron: true,
          onTap: () => openPage(
            context,
            d.autoSave.isEmpty
                ? '/recurring/new?type=saving&goal=${g.id}'
                : '/recurring/${d.autoSave.first.recurringId}',
          ),
        ),
      ],
    );
  }

  Widget? _byWallet(AppLocalizations l, SavingGoalDetail d, bool first) {
    if (d.byWallet.isEmpty) return null;
    final symbol = context.readUserCurrencySymbol;
    return SectionCard(
      first: first,
      title: l.sgv2ByWallet,
      description: l.sgv2ByWalletHint,
      children: [
        for (final w in d.byWallet)
          BreakdownRow(
            label: w.wallet.name,
            leading: walletValueChip(
              context,
              name: '',
              iconCode: w.wallet.iconCode,
            ),
            amountText: moneyString(context, w.amount, symbol: symbol),
            value: w.sharePct / 100,
          ),
      ],
    );
  }

  Widget _entries(
    AppLocalizations l,
    SavingGoalDetail d,
    SavingPageState? s,
    bool first,
  ) {
    final items = d.entries.items;
    return SectionCard(
      first: first,
      title: l.sgv2Entries,
      dividers: true,
      children: [
        if (items.isEmpty)
          DetailPlaceholder(l.sgv2EntriesEmpty)
        else
          for (final e in items) _entryRow(l, e),
        if (d.entries.hasMore)
          AppButton(
            label: l.sgv2EntriesMore,
            variant: AppButtonVariant.text,
            loading: s?.loadingMore ?? false,
            onPressed: _cubit!.loadMoreEntries,
          ),
      ],
    );
  }

  Widget _entryRow(AppLocalizations l, SavingEntry e) {
    final kind = switch (e.kind) {
      SavingEntryKind.save => SavingTxKind.deposit,
      SavingEntryKind.withdraw => SavingTxKind.withdraw,
      SavingEntryKind.move => SavingTxKind.allocate,
    };
    String end(SavingEndpoint p) => switch (p.type) {
      SavingEndpointType.spare => l.sgv2SpareName,
      _ => p.name ?? '',
    };
    return SavingTxRow(
      kind: kind,
      title: _entryTitle(l, e),
      amount: e.amount,
      walletLabel: e.wallet.name,
      from: e.kind == SavingEntryKind.save ? null : end(e.from),
      to: e.kind == SavingEntryKind.withdraw ? null : end(e.to),
      onTap: isSaving ? null : () => _deleteEntry(e),
    );
  }

  String _entryTitle(AppLocalizations l, SavingEntry e) => switch (e.kind) {
    SavingEntryKind.save => l.sgv2KindSave,
    SavingEntryKind.withdraw => l.sgv2KindWithdraw,
    SavingEntryKind.move => l.sgv2KindMove,
  };
}

// ────────────────────────────────────────────────────────────────────
// Immutable editing snapshot — drives dirty-check + undo history.
// ────────────────────────────────────────────────────────────────────

class _GoalDraft {
  const _GoalDraft({
    this.name = '',
    this.target = '',
    this.deadline,
    this.iconCode,
    this.description = '',
    this.note = '',
  });

  factory _GoalDraft.from(SavingGoal g) => _GoalDraft(
    name: g.name,
    target: AmountInput.format(g.targetAmount),
    deadline: g.deadline == null ? null : DateTime.tryParse(g.deadline!),
    iconCode: g.iconCode,
    description: g.description ?? '',
    note: g.note ?? '',
  );

  final String name;

  /// Formatted text, as in the field.
  final String target;
  final DateTime? deadline;
  final IconCode? iconCode;
  final String description;
  final String note;

  /// What the server stores (text trimmed) — the post-save fallback baseline.
  _GoalDraft trimmed() => copyWith(
    name: name.trim(),
    description: description.trim(),
    note: note.trim(),
  );

  _GoalDraft copyWith({
    String? name,
    String? target,
    DateTime? deadline,
    bool clearDeadline = false,
    IconCode? iconCode,
    bool clearIcon = false,
    String? description,
    String? note,
  }) => _GoalDraft(
    name: name ?? this.name,
    target: target ?? this.target,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    description: description ?? this.description,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is _GoalDraft &&
      other.name == name &&
      other.target == target &&
      other.deadline == deadline &&
      other.iconCode == iconCode &&
      other.description == description &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(name, target, deadline, iconCode, description, note);
}
