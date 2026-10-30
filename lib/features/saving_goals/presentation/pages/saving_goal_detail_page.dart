import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../accounts/domain/account_type.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../recurring/domain/recurring.dart';
import '../../../recurring/presentation/cubit/recurring_directory_cubit.dart';
import '../../../recurring/presentation/recurring_rows.dart';
import '../widgets/saving_goal_picker.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_entry.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goals_overview.dart';
import '../cubit/saving_goal_cubit.dart';
import '../cubit/saving_goals_cubit.dart';
import '../saving_goal_delete_guard.dart';
import '../widgets/saving_goal_texts.dart';

class SavingGoalDetailPage extends StatefulWidget {
  const SavingGoalDetailPage({this.id, this.startEditing = false, super.key});

  final String? id;

  final bool startEditing;

  bool get isCreate => id == null;

  @override
  State<SavingGoalDetailPage> createState() => _SavingGoalDetailPageState();
}

enum _Field { name, target, description, note, opening }

enum _GoalTab { overview, entries }

class _SavingGoalDetailPageState extends State<SavingGoalDetailPage>
    with EditModeMixin<SavingGoalDetailPage, _GoalDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  SavingGoalCubit? _cubit;
  _GoalTab _tab = _GoalTab.overview;

  SavingGoal? _seededFrom;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cubit?.load();
        unawaited(context.read<RecurringDirectoryCubit>().loadIfNeeded());
      });
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
    _openingCtrl.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

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
    sync(_openingCtrl, working.opening);
  }

  void _onText(_Field field, String v) =>
      applyTextChange(field, switch (field) {
        _Field.name => working.copyWith(name: v),
        _Field.target => working.copyWith(target: v),
        _Field.description => working.copyWith(description: v),
        _Field.note => working.copyWith(note: v),
        _Field.opening => working.copyWith(opening: v),
      });

  /// The wallet sheet: a picked wallet, `(null)` for none, null when dismissed.
  Future<(SavingWalletRef?,)?> _pickWallet(SavingWalletRef? current) async {
    final l = AppLocalizations.of(context)!;
    final picked = await AccountPicker.one(
      context,
      selectedId: current?.id,
      allowNone: true,
      noneLabel: l.fpGoalsNoWallet,
      title: l.fpGoalsAutoFrom,
    );
    return switch (picked) {
      AccountPicked(:final account) => (
        SavingWalletRef(
          id: account.id,
          name: account.name,
          iconCode: account.iconCode,
          logoUrl: account.logoUrl,
          type: account.type.name,
          currency: account.currency,
        ),
      ),
      AccountPickedNone() => (null,),
      null => null,
    };
  }

  Future<void> _pickOpeningWallet() async {
    final r = await _pickWallet(working.openingWallet);
    if (r == null || !mounted) return;
    final (wallet,) = r;
    applyChange(
      wallet == null
          ? working.copyWith(clearOpeningWallet: true)
          : working.copyWith(openingWallet: wallet),
    );
  }

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

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final current = working.deadline;
    final first = current != null && current.isBefore(now) ? current : now;
    final picked = await AppDatePicker.show(
      context,
      title: AppLocalizations.of(context)!.savingGoalFormDeadlineLabel,
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

  Future<void> _save(SavingGoal? goal) async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    final description = w.description.trim();
    final note = w.note.trim();
    final draft = SavingGoal(
      id: goal?.id ?? 'draft',
      name: w.name.trim(),
      targetAmount: AmountInput.parse(w.target),
      currency: goal?.currency ?? '',
      deadline: w.deadline == null ? null : _isoDate(w.deadline!),
      iconCode: w.iconCode,
      description: description.isEmpty ? null : description,
      note: note.isEmpty ? null : note,
    );
    FocusScope.of(context).unfocus();
    setSaving(true);
    if (widget.isCreate) {
      await _create(draft, w);
      return;
    }
    try {
      await _cubit!.update(draft);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _snack(errorTextOf(context, e), tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final saved = _cubit!.state.detail?.goal;
    _seededFrom = saved;
    commitSaved(saved == null ? w.trimmed() : _GoalDraft.from(saved));
  }

  /// The goal first; then its starting amount. A failure after the goal
  /// exists is said once and the page still leaves.
  Future<void> _create(SavingGoal draft, _GoalDraft w) async {
    final l = AppLocalizations.of(context)!;
    final repo = context.read<SavingGoalsRepository>();
    final String id;
    try {
      id = (await repo.create(draft)).goal!.id;
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _snack(errorTextOf(context, e), tone: Tone.danger);
      return;
    }
    String? failed;
    try {
      final opening = AmountInput.parse(w.opening);
      if (opening != null && opening > 0) {
        await repo.addEntry(
          kind: SavingEntryKind.save,
          amount: opening,
          date: _isoDate(DateTime.now()),
          goalId: id,
          walletId: w.openingWallet?.id,
        );
      }
    } on ApiException catch (e) {
      failed = errorText(l, e);
    }
    if (!mounted) return;
    if (failed != null) {
      _snack(l.sgCreatedPartly(failed), tone: Tone.warning);
    } else {
      HapticFeedback.mediumImpact();
    }
    leavePage();
  }

  void _snack(String message, {Tone tone = Tone.neutral}) {
    final m = pageMessenger;
    if (m != null) {
      showAppSnackBarOn(m, message, tone: tone);
    } else if (mounted) {
      showAppSnackBar(context, message, tone: tone);
    }
  }

  Future<bool> _run(
    Future<void> Function() write, {
    String? Function(ApiException)? message,
  }) async {
    setSaving(true);
    try {
      await write();
    } on ApiException catch (e) {
      if (mounted) {
        setSaving(false);
        _snack(message?.call(e) ?? errorTextOf(context, e), tone: Tone.danger);
      }
      return false;
    }
    if (mounted) setSaving(false);
    return true;
  }

  Future<void> _archive(SavingGoal g) async {
    final l = AppLocalizations.of(context)!;
    final held = g.savedAmount;
    final ok = await showConfirmDialog(
      context,
      title: l.savingGoalArchiveConfirmTitle,
      message: held > 0
          ? l.fpGoalsArchiveConfirmBodyMoney(
              moneyString(
                context,
                held,
                symbol: context.readUserCurrencySymbol,
              ),
            )
          : l.fpGoalsArchiveConfirmBody,
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
    setSaving(true);
    final SavingDeletePreview? preview;
    try {
      preview = (await context.read<SavingGoalsRepository>().detail(
        _cubit!.id,
        deletePreview: true,
      )).deletePreview;
    } on ApiException catch (e) {
      if (mounted) {
        setSaving(false);
        _snack(errorTextOf(context, e), tone: Tone.danger);
      }
      return;
    }
    if (!mounted) return;
    setSaving(false);
    // A goal holding money cannot be deleted: say so, no confirm.
    if (deleteBlockedByMoney(preview)) {
      _snack(l.fpGoalsArchiveNeedsClose, tone: Tone.warning);
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l.savingGoalDeleteConfirmTitle,
      message: preview == null
          ? l.fpGoalsDeleteConfirmBody
          : l.fpM5GoalDeleteBody(preview.entries),
      confirmLabel: l.savingGoalDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final needsClose = l.fpGoalsArchiveNeedsClose;
    if (await _run(
          _cubit!.delete,
          message: (e) => deleteRefusedForMoney(e) ? needsClose : null,
        ) &&
        mounted) {
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
        for (final w in wallets)
          (wallet: w.wallet?.name ?? l.fpGoalsNoWallet, amount: w.amount),
      ],
      toSpareLabel: l.sgv2CloseToSpare,
      backToWalletsLabel: l.sgv2CloseToWallets,
      cancelLabel: l.sgv2Cancel,
    );
    if (choice == null || !mounted) return;
    final ok = await _run(
      () =>
          _cubit!.closeGoal(toWallets: choice == CloseGoalChoice.backToWallets),
    );
    if (!ok || !mounted) return;
    final closed = _cubit!.state.detail?.goal;
    _seededFrom = closed;
    if (closed != null) commitSaved(_GoalDraft.from(closed));
  }

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

  ({String name, double amount}) _bucket(
    AppLocalizations l,
    SavingGoalDetail d,
  ) {
    final g = d.goal;
    return g != null
        ? (name: g.name, amount: g.savedAmount)
        : (name: l.sgv2SpareName, amount: d.spare?.amount ?? 0);
  }

  static const _noWalletId = '';

  List<SavingSplit> _splitsOf(List<SavingMoveSplit> parts) => [
    for (final p in parts)
      SavingSplit(
        walletId: p.walletId == _noWalletId ? null : p.walletId,
        amount: p.amount,
      ),
  ];

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
            walletId: w.wallet?.id ?? _noWalletId,
            name: w.wallet?.name ?? l.fpGoalsNoWallet,
            amount: take,
            availableText: l.sgv2SplitHas(moneyString(context, w.amount)),
          );
        }(),
    ];
  }

  Future<List<SavingMoveSplit>?> _moveSheet(
    AppLocalizations l,
    SavingGoalDetail d, {
    required String title,
    required SavingMoveEnd to,
    required String saveLabel,
  }) {
    final b = _bucket(l, d);
    return showSavingMoveSheet(
      context,
      title: title,
      from: SavingMoveEnd(
        caption: l.sgv2MoveFrom,
        name: b.name,
        subtitle: moneyString(context, b.amount),
      ),
      to: to,
      amount: b.amount,
      splits: _splitRows(l, d.byWallet, b.amount),
      amountLabel: l.sgv2AmountLabel,
      splitTitle: l.sgv2SplitTitle,
      editLabel: l.sgv2SplitEdit,
      saveLabel: saveLabel,
      sumOkText: (s) => l.sgv2SumOk(moneyString(context, s)),
      sumOffText: (s, a) =>
          l.sgv2SumOff(moneyString(context, s), moneyString(context, a)),
      autoSplit: (v) => [
        for (final r in _splitRows(l, d.byWallet, v))
          (walletId: r.walletId, amount: r.amount),
      ],
      currencySymbol: context.readUserCurrencySymbol,
    );
  }

  Future<void> _withdraw(SavingGoalDetail d) async {
    final l = AppLocalizations.of(context)!;
    final parts = await _moveSheet(
      l,
      d,
      title: l.sgv2WithdrawTitle,
      to: SavingMoveEnd(caption: l.sgv2MoveTo, name: l.sgv2WalletsCard),
      saveLabel: l.sgv2WithdrawSave,
    );
    if (parts == null || !mounted) return;
    final total = parts.fold<double>(0, (s, p) => s + p.amount);
    await _run(
      () => _cubit!.addEntry(
        kind: SavingEntryKind.withdraw,
        amount: total,
        date: _isoDate(DateTime.now()),
        splits: _splitsOf(parts),
      ),
    );
  }

  Future<void> _move(SavingGoalDetail d) async {
    final l = AppLocalizations.of(context)!;
    final picked = await SavingGoalPicker.one(
      context,
      title: l.sgv2MovePick,
      allowSpare: !d.isSpare,
      excludeIds: {?d.goal?.id},
    );
    if (picked == null || !mounted) return;
    final toSpare = picked is SavingSparePicked;
    final target = picked.goalId;
    final targetName = switch (picked) {
      SavingGoalPicked(:final goal) => goal.name,
      SavingSparePicked() => l.sgv2SpareName,
    };
    final parts = await _moveSheet(
      l,
      d,
      title: l.sgv2MoveTitle,
      to: SavingMoveEnd(caption: l.sgv2MoveTo, name: targetName),
      saveLabel: l.sgv2MoveSave,
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
        splits: _splitsOf(parts),
      ),
    );
  }

  Future<void> _addSaving(SavingGoalDetail d) async {
    final saved = await showQuickCreateSheet(
      context,
      preset: d.goal == null
          ? const QuickCreatePreset.saving()
          : QuickCreatePreset.saving(goalId: d.goal!.id),
    );
    if (saved && mounted) {
      await _cubit!.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.isCreate) return _page(l, null, null);
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionsCubit, TransactionsState>(
          listenWhen: _bookMoved,
          listener: (_, _) => _reloadQuietly(),
        ),
        BlocListener<SavingGoalsCubit, SavingGoalsState>(
          listenWhen: (a, b) => a.overview != b.overview,
          listener: (_, _) => _reloadQuietly(),
        ),
      ],
      child: BlocProvider.value(
        value: _cubit!,
        child: BlocConsumer<SavingGoalCubit, SavingPageState>(
          listener: (context, state) {
            _onState(context, state);
            if (state.status == SavingPageStatus.error &&
                state.detail != null) {
              _snack(
                AppLocalizations.of(context)!.fpGoalsRefreshFailed,
                tone: Tone.danger,
              );
            }
          },
          builder: (context, state) {
            final d = state.detail;
            if (d == null) return _fallback(l, state);
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
    final goal = d?.goal;
    final spare = d != null && d.isSpare;
    final editing = isEditing && !spare;
    if (editing) _tab = _GoalTab.overview;
    final page = editScope(
      Scaffold(
        appBar: AppTopBar(
          // Titles never change with the mode.
          title: spare
              ? l.sgv2SpareTitle
              : (goal?.name ?? l.savingGoalFormTitle),
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          child: Builder(
            builder: (context) => d == null || editing
                ? _editBody(l, d, context)
                : _viewBody(l, d, s!),
          ),
        ),
        bottomNavigationBar: editing
            ? editActionBar(onSave: () => _save(goal))
            : null,
      ),
    );
    if (d == null) return page;
    return QuickCreatePresetScope(
      preset: goal == null
          ? const QuickCreatePreset.saving()
          : QuickCreatePreset.saving(goalId: goal.id),
      child: page,
    );
  }

  Widget _viewBody(AppLocalizations l, SavingGoalDetail d, SavingPageState s) {
    final goal = d.goal;
    final symbol = context.readUserCurrencySymbol;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = goal == null
        ? scheme.primary
        : goal.iconCode.tintFor(palette);
    final style = HeroStyle.tinted(color: accent, glyph: AppIcons.savingGoal);
    final saved = goal?.savedAmount ?? d.spare?.amount ?? 0;
    return TabbedDetailBody<_GoalTab>(
      hero: goal == null
          ? _spareHero(l, d, style, symbol)
          : _goalHero(l, goal, style, accent, symbol),
      belowHero: [?_actionBar(l, d)],
      compactBar: AppCompactHeroCard(
        style: style,
        leading: IconCodeWidget(
          iconCode: goal?.iconCode,
          size: 28,
          displayMode: IconDisplayMode.compact,
          fallbackIcon: AppIcons.savingGoal,
          fallbackColor: accent,
        ),
        title: Text(goal?.name ?? l.sgv2SpareTitle),
        trailing: MoneyText(saved, symbol: symbol),
      ),
      tabs: [
        AppTab(
          value: _GoalTab.overview,
          label: l.sgv2Overview,
          icon: AppIcons.pie,
        ),
        AppTab(
          value: _GoalTab.entries,
          label: l.sgv2Entries,
          icon: AppIcons.receipt,
        ),
      ],
      selected: _tab,
      onChanged: (t) => setState(() => _tab = t),
      tabBuilder: (context, t) => switch (t) {
        _GoalTab.overview => _overviewTab(l, d, accent, symbol),
        _GoalTab.entries => _entriesTab(l, d, s),
      },
    );
  }

  Widget _goalHero(
    AppLocalizations l,
    SavingGoal g,
    HeroStyle style,
    Color accent,
    String symbol,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(double v) => moneyString(context, v, symbol: symbol);
    final due = g.deadline == null ? null : DateTime.tryParse(g.deadline!);
    final days = g.daysRemaining;
    final target = g.targetAmount;
    if (target == null) return _ongoingHero(l, g, style, accent, symbol);
    final active = g.state == SavingGoalState.active;
    final reached = g.status == SavingStatus.reached || g.savedAmount >= target;
    final plan = g.monthPlan ?? 0;
    final short = g.monthShort ?? 0;
    final left = g.remainingAmount ?? target - g.savedAmount;
    final months = g.behindMonths ?? 0;
    final behind = active && !reached && g.status == SavingStatus.behind;
    final pace = active ? savingGoalPaceRatio(g) : null;
    final closed = g.closedAt;
    final box = due == null
        ? null
        : HeroInfoBox(
            key: const ValueKey('heroDue'),
            icon: AppIcons.savingGoal,
            title: l.sgv2DueOn(DateFormatter.medium(due, locale: locale)),
            subtitle: reached
                ? l.savingGoalCompletedLabel
                : days != null && days > 0
                ? l.fpGoalsDaysLeft(days)
                : null,
          );
    final description = HeroDescription(
      controller: _descriptionCtrl,
      editing: false,
      hint: l.commonDescription,
      maxLength: TextLimits.description,
      focusNode: _descriptionFocus,
      onEnterEdit: () => enterEdit(focus: _descriptionFocus),
    );
    final period = g.period?.current;
    List<HeroFact> factsOf(Color? warning) =>
        period != null && active && !reached
        // เป้าต่อรอบ: this period, its target, what's left, when it is done.
        ? [
            HeroFact(
              l.fpGoalsFactPeriodSaved,
              money(period.saved),
              icon: AppIcons.savings,
            ),
            HeroFact(
              l.fpGoalsFactPeriodTarget,
              money(period.target),
              icon: AppIcons.target,
            ),
            HeroFact(l.fpGoalsFactLeft, money(left), icon: AppIcons.hourglass),
            HeroFact(
              l.fpGoalsFactPeriodEta,
              DateFormatter.monthYear(period.etaDate, locale: locale),
              color: period.late ? warning : null,
              icon: AppIcons.date,
            ),
          ]
        : !active || reached
        ? [
            HeroFact(l.fpGoalsFactTarget, money(target), icon: AppIcons.target),
            if (reached && closed != null)
              HeroFact(
                l.fpGoalsFactReachedOn,
                DateFormatter.medium(closed, locale: locale),
                icon: AppIcons.date,
              ),
            if (!reached && left > 0)
              HeroFact(
                l.fpGoalsFactLeft,
                money(left),
                icon: AppIcons.hourglass,
              ),
          ]
        : [
            if (plan > 0) ...[
              HeroFact(
                l.fpGoalsTileSaved,
                '${money(g.monthSaved)} / ${money(plan)}',
                icon: AppIcons.savings,
              ),
              HeroFact(
                l.fpGoalsFactStillShort,
                money(short),
                color: short > 0 ? warning : null,
                icon: AppIcons.hourglass,
              ),
            ] else
              HeroFact(
                l.fpGoalsTileSaved,
                money(g.monthSaved),
                icon: AppIcons.savings,
              ),
            if (pace != null)
              HeroFact(
                l.fpGoalsFactShouldHave,
                money(target * pace),
                icon: AppIcons.trendingUp,
              ),
            HeroFact(l.fpGoalsFactLeft, money(left), icon: AppIcons.target),
          ];
    final chips = [
      if (active && reached)
        StatusChip(
          label: l.savingGoalCompletedLabel,
          kind: StatusKind.done,
          size: ChipSize.chip,
        ),
      if (active && !reached && period != null)
        period.short > 0.004
            ? StatusChip(
                label: l.fpGoalsChipPeriodShort(
                  money(period.short),
                  period.daysLeft,
                ),
                kind: StatusKind.warning,
                size: ChipSize.chip,
              )
            : StatusChip(
                label: l.fpGoalsChipPeriodDone,
                kind: StatusKind.active,
                size: ChipSize.chip,
              ),
      if (active && !reached && period == null) ...[
        if (short > 0)
          StatusChip(
            label: l.fpGoalsChipShort(money(short)),
            kind: StatusKind.warning,
            size: ChipSize.chip,
          )
        else if (plan > 0 || g.status == SavingStatus.onTrack)
          StatusChip(
            label: l.sgv2PaceOnTrack,
            kind: StatusKind.active,
            size: ChipSize.chip,
          ),
        if (behind)
          StatusChip(
            label: months > 0 ? l.fpGoalsChipLate(months) : l.fpGoalsBehind,
            kind: StatusKind.warning,
            size: ChipSize.chip,
          ),
      ],
    ];
    return AppHeroCard(
      style: style,
      header: active
          ? null
          : HeroHeader(leading: [?savingGoalStatusChip(l, g)]),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: HeroIdentity.iconSize,
            onLongPress: _enterEditThenOpenMaker,
            child: IconCodeWidget(
              iconCode: g.iconCode,
              size: HeroIdentity.iconSize,
              fallbackIcon: AppIcons.savingGoal,
              fallbackColor: accent,
            ),
          ),
          name: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          description: description,
          trailing: _heroTrailing(box),
        ),
        Builder(
          builder: (context) {
            final hero = HeroColors.maybeOf(context);
            return HeroRingRow(
              ring: (size) => HeroRing(
                size: size,
                stroke: 14,
                value: g.savedAmount / target,
                color: reached
                    ? hero?.success
                    : behind
                    ? hero?.warning
                    : null,
                label: l.fpGoalsSavedLabel,
                amount: MoneyText(g.savedAmount, symbol: symbol),
                target: l.fpGoalsRingOf(
                  money(target),
                  (g.progressPct ?? 0).round(),
                ),
              ),
              facts: factsOf(hero?.warning),
            );
          },
        ),
        if (chips.isNotEmpty) HeroChipRow(chips: chips),
      ],
    );
  }

  /// The hero's right side: an optional info box beside the edit button.
  Widget _heroTrailing(Widget? box) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ?box,
      if (box != null) const SizedBox(width: AppSpacing.sm),
      CardActionButton(
        key: const ValueKey('heroEdit'),
        icon: AppIcons.edit,
        tooltip: UiConfig.stringsOf(context).edit,
        onTap: enterEdit,
      ),
    ],
  );

  Widget _ongoingHero(
    AppLocalizations l,
    SavingGoal g,
    HeroStyle style,
    Color accent,
    String symbol,
  ) {
    final active = g.state == SavingGoalState.active;
    return AppHeroCard(
      style: style,
      header: active
          ? null
          : HeroHeader(leading: [?savingGoalStatusChip(l, g)]),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: HeroIdentity.iconSize,
            onLongPress: _enterEditThenOpenMaker,
            child: IconCodeWidget(
              iconCode: g.iconCode,
              size: HeroIdentity.iconSize,
              fallbackIcon: AppIcons.savingGoal,
              fallbackColor: accent,
            ),
          ),
          name: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          description: HeroDescription(
            controller: _descriptionCtrl,
            editing: false,
            hint: l.commonDescription,
            maxLength: TextLimits.description,
            focusNode: _descriptionFocus,
            onEnterEdit: () => enterEdit(focus: _descriptionFocus),
          ),
          trailing: _heroTrailing(null),
        ),
        HeroNumber(
          label: l.fpGoalsSavedLabel,
          value: MoneyText(g.savedAmount, symbol: symbol),
        ),
        if (active)
          HeroFactList(
            facts: [
              // As on a goal with a target: this month's saved / its plan
              // (the goal's saving rules).
              HeroFact(
                l.fpGoalsTileSaved,
                (g.monthPlan ?? 0) > 0
                    ? '${moneyString(context, g.monthSaved, symbol: symbol)}'
                          ' / ${moneyString(context, g.monthPlan!, symbol: symbol)}'
                    : moneyString(context, g.monthSaved, symbol: symbol),
                icon: AppIcons.savings,
              ),
            ],
          ),
      ],
    );
  }

  Widget _spareHero(
    AppLocalizations l,
    SavingGoalDetail d,
    HeroStyle style,
    String symbol,
  ) {
    final color = Theme.of(context).colorScheme.primary;
    return AppHeroCard(
      style: style,
      content: [
        HeroIdentity(
          icon: IconTile(icon: AppIcons.savingGoal, color: color, size: 40),
          description: AppText(l.sgv2SpareHint, role: AppTextRole.caption),
        ),
        HeroNumber(
          label: l.sgv2Spare,
          value: MoneyText(d.spare?.amount ?? 0, symbol: symbol),
        ),
      ],
    );
  }

  Widget? _actionBar(AppLocalizations l, SavingGoalDetail d) {
    final g = d.goal;
    final saved = g?.savedAmount ?? d.spare?.amount ?? 0;
    if (g != null && g.actions.restore) {
      return ActionBar(
        actions: [
          ActionBarItem(
            label: l.fpGoalsActionRestore,
            icon: AppIcons.refresh,
            primary: true,
            submits: true,
            onPressed: isSaving ? null : _restore,
          ),
        ],
      );
    }
    final a = g?.actions ?? const SavingGoalActions();
    final items = [
      if (a.save)
        ActionBarItem(
          label: l.fpGoalsActionSave,
          icon: AppIcons.savingDeposit,
          primary: true,
          submits: true,
          onPressed: isSaving ? null : () => _addSaving(d),
        ),
      if (a.withdraw && saved > 0)
        ActionBarItem(
          label: l.sgv2ActionWithdraw,
          icon: AppIcons.savingWithdraw,
          submits: true,
          onPressed: isSaving ? null : () => _withdraw(d),
        ),
      if (a.move && saved > 0)
        ActionBarItem(
          label: l.sgv2ActionMove,
          icon: AppIcons.savingAllocate,
          submits: true,
          onPressed: isSaving ? null : () => _move(d),
        ),
    ];
    return items.isEmpty ? null : ActionBar(actions: items);
  }

  Widget _overviewTab(
    AppLocalizations l,
    SavingGoalDetail d,
    Color accent,
    String symbol,
  ) {
    final g = d.goal;
    final settings = _recurring(l, d);
    final chart = _chart(l, d, accent, symbol);
    return ListPageBody(
      clearTopBar: false,
      loading: false,
      error: null,
      isEmpty: false,
      onRetry: _cubit!.load,
      empty: EmptyView.compact(message: l.sgv2EntriesEmpty),
      topInset: 0,
      children: [
        DetailSections(
          settings: settings,
          chart: chart,
          note: g == null
              ? null
              : NoteSection(
                  label: l.commonNote,
                  editing: false,
                  text: g.note,
                  hint: l.commonLongPressToEdit,
                  onLongPress: () => enterEdit(focus: _noteFocus),
                ),
        ),
        if (g != null)
          DetailMeta(
            lines: detailMetaLines(
              context,
              createdAt: g.createdAt,
              updatedAt: g.updatedAt,
            ),
          ),
      ],
    );
  }

  /// วางแผนการออม: a goal with a target sets its due date, its เป้าต่อรอบ
  /// and the periods here (each pick saves at once); then its saving
  /// recurring rules (the spare: the rules into no goal), the add row
  /// starting one with this goal already picked.
  Widget? _recurring(AppLocalizations l, SavingGoalDetail d) {
    final g = d.goal;
    if (g != null && g.state != SavingGoalState.active) return null;
    final goalId = g?.id;
    bool mine(Recurring r) =>
        r.isSaving &&
        r.goalId == goalId &&
        r.status != RecurringStatus.archived;
    final planned = g != null && g.targetAmount != null;
    return BlocBuilder<RecurringDirectoryCubit, RecurringDirectoryState>(
      buildWhen: (a, b) => a.rules != b.rules,
      builder: (context, dir) => SectionCard(
        title: g == null ? l.sgRecurringTitle : l.sgPlanTitle,
        description: g == null ? l.sgRecurringSpareCaption : null,
        children: [
          if (planned) ..._planRows(l, g),
          if (planned)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: AppText(l.sgRecurringLabel, role: AppTextRole.caption),
            ),
          for (final r in dir.rules)
            if (mine(r))
              RecurringRow(
                recurring: r,
                onTap: () => openPage(context, '/recurring/${r.id}'),
              ),
          DetailAddRow(
            label: l.sgAutoAdd,
            onTap: () => openPage(
              context,
              goalId == null
                  ? '/recurring/new?kind=saving&spare=1'
                  : '/recurring/new?kind=saving&goal=$goalId',
            ),
          ),
        ],
      ),
    );
  }

  /// วันที่ครบกำหนด, เป้าต่อรอบ, รอบ (once there is a target per period) and
  /// a warning when the recurring saves fall short of it.
  List<Widget> _planRows(AppLocalizations l, SavingGoal g) {
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    final due = g.deadline == null ? null : DateTime.tryParse(g.deadline!);
    final p = g.period;
    final now = p?.current;
    final plan = now?.plan ?? 0;
    return [
      AppDetailRow.pick(
        label: l.savingGoalFormDeadlineLabel,
        value: due == null ? null : _day(due),
        emptyText: l.savingGoalFormDeadlinePlaceholder,
        onTap: isSaving ? null : () => _pickDeadlineLive(g),
      ),
      AppDetailRow.pick(
        key: const ValueKey('goalPeriodAmount'),
        label: l.sgPeriodTarget,
        value: p == null ? null : money(p.amount),
        emptyText: l.sgPeriodNone,
        onTap: isSaving ? null : () => _pickPeriodAmount(g),
      ),
      if (p != null)
        AppDetailRow.pick(
          key: const ValueKey('goalPeriodRule'),
          label: l.sgPeriodRule,
          value: recurrenceLabel(l, _periodRule(p)),
          emptyText: '',
          onTap: isSaving ? null : () => _pickPeriodRule(g, p),
        ),
      if (now != null && plan + 0.004 < now.target)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: HintLine(
            icon: AppIcons.warning,
            text: l.sgPeriodPlanShort(money(plan), money(p!.amount)),
          ),
        ),
    ];
  }

  RecurrenceRule _periodRule(SavingPeriod p) => RecurrenceRule(
    freq: RecurrenceFreq.values.firstWhere(
      (f) => f.name == p.freq,
      orElse: () => RecurrenceFreq.monthly,
    ),
    interval: p.interval,
    start: p.anchor,
  );

  static String _ymdOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDeadlineLive(SavingGoal g) async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final current = g.deadline == null ? null : DateTime.tryParse(g.deadline!);
    final first = current != null && current.isBefore(now) ? current : now;
    final picked = await AppDatePicker.show(
      context,
      title: l.savingGoalFormDeadlineLabel,
      initial: current ?? now.add(const Duration(days: 90)),
      first: first,
      last: DateTime(now.year + 20),
      clearable: current != null,
    );
    if (!mounted || picked == null) return;
    final value = switch (picked) {
      AppDatePicked(:final date) => _ymdOf(date),
      AppDateCleared() => null,
    };
    await _run(() => _cubit!.patch({'deadline': value}));
  }

  Future<void> _pickPeriodAmount(SavingGoal g) async {
    final l = AppLocalizations.of(context)!;
    final r = await AppAmountSheet.show(
      context,
      title: l.sgPeriodTarget,
      label: l.sgPeriodTargetField,
      symbol: context.readUserCurrencySymbol,
      saveLabel: l.commonSave,
      initial: g.period?.amount,
      helper: l.sgPeriodHelper,
      clearLabel: l.sgPeriodClear,
    );
    if (!mounted || r == null) return;
    await _run(
      () => _cubit!.patch({'period_amount': r.cleared ? null : r.amount}),
    );
  }

  Future<void> _pickPeriodRule(SavingGoal g, SavingPeriod p) async {
    final l = AppLocalizations.of(context)!;
    final r = await AppRecurrenceSheet.show(
      context,
      initial: _periodRule(p),
      simple: true,
      showEnd: false,
      title: l.sgPeriodRule,
    );
    if (!mounted || r == null) return;
    await _run(
      () => _cubit!.patch({
        'period': {
          'freq': r.freq == RecurrenceFreq.dates ? 'monthly' : r.freq.name,
          'interval': r.interval < 1 ? 1 : r.interval,
          'anchor': _ymdOf(r.start),
        },
      }),
    );
  }

  Widget? _chart(
    AppLocalizations l,
    SavingGoalDetail d,
    Color accent,
    String symbol,
  ) {
    if (d.entries.items.length < 2 || d.history.isEmpty) return null;
    final g = d.goal;
    return ChartSection(
      title: l.sgv2ChartCaption,
      chart: SavingHistoryChart(
        actual: [for (final p in d.history) p.cumulative],
        target: g?.targetAmount ?? 0,
        showNeeded: false,
        color: accent,
        monthLabels: [for (final p in d.history) p.month.substring(5)],
        targetLabel: g?.targetAmount == null
            ? null
            : l.sgv2ChartTarget(
                moneyString(context, g!.targetAmount!, symbol: symbol),
              ),
        actualLegend: l.fpGoalsChartActual,
        plan: [for (final p in d.history) p.plan],
        planLegend: l.fpM5GoalsChartPlan,
      ),
    );
  }

  Widget _entriesTab(
    AppLocalizations l,
    SavingGoalDetail d,
    SavingPageState s,
  ) {
    final items = d.entries.items;
    return ListPageBody(
      clearTopBar: false,
      loading: false,
      error: null,
      isEmpty: items.isEmpty,
      onRetry: _cubit!.load,
      empty: EmptyView.compact(message: l.sgv2EntriesEmpty),
      hasMore: d.entries.hasMore,
      loadingMore: s.loadingMore,
      loadMoreError: s.moreError,
      onLoadMore: _cubit!.loadMoreEntries,
      rowCards: true,
      topInset: 0,
      children: _entryRows(l, d),
    );
  }

  /// The entries under a header per day, with the day's net for this goal (or
  /// the spare) beside it.
  List<Widget> _entryRows(AppLocalizations l, SavingGoalDetail d) {
    final goalId = d.goal?.id;
    bool here(SavingEndpoint p) => goalId == null
        ? p.type == SavingEndpointType.spare
        : p.type == SavingEndpointType.goal && p.id == goalId;
    double signed(SavingEntry e) => switch (e.kind) {
      SavingEntryKind.save => e.amount,
      SavingEntryKind.withdraw => -e.amount,
      SavingEntryKind.move =>
        here(e.to)
            ? e.amount
            : here(e.from)
            ? -e.amount
            : 0,
    };
    final days = <String, List<SavingEntry>>{};
    for (final e in d.entries.items) {
      days.putIfAbsent(e.date, () => []).add(e);
    }
    final locale = Localizations.localeOf(context).languageCode;
    return [
      for (final MapEntry(key: date, value: entries) in days.entries) ...[
        AppListHeader(
          title: switch (DateFormatter.parseDay(date)) {
            final day? => DateFormatter.friendly(
              day,
              today: l.commonToday,
              yesterday: l.commonYesterday,
              locale: locale,
            ),
            null => date,
          },
          trailing: ListHeaderTrailing.value(
            MoneyText(
              entries.fold<double>(0, (sum, e) => sum + signed(e)),
              tone: MoneyTone.signed,
            ),
          ),
        ),
        for (final e in entries) _entryRow(l, e),
      ],
    ];
  }

  /// A saving entry as a money row: in green, out red, a move grey. Line 2
  /// says only what this goal's page doesn't: the wallet, or a move's other
  /// goal.
  Widget _entryRow(AppLocalizations l, SavingEntry e) {
    String end(SavingEndpoint p) => switch (p.type) {
      SavingEndpointType.spare => l.sgv2SpareName,
      _ => p.name ?? '',
    };
    final wallet = e.wallet;
    final here = widget.id;
    final String? other = e.kind != SavingEntryKind.move
        ? null
        : e.to.id == here
        ? l.sgEntryFrom(end(e.from))
        : e.from.id == here
        ? l.sgEntryTo(end(e.to))
        : '${l.sgEntryFrom(end(e.from))} ${l.sgEntryTo(end(e.to))}';
    return TxListRow(
      key: ValueKey(e.id),
      kind: switch (e.kind) {
        SavingEntryKind.save => TxListKind.savingIn,
        SavingEntryKind.withdraw => TxListKind.savingOut,
        SavingEntryKind.move => TxListKind.savingMove,
      },
      title: _entryTitle(l, e),
      source: e.fromRecurring ? TxSource.recurring : null,
      wallet: other != null || wallet == null
          ? null
          : walletRowChip(
              context,
              name: wallet.name,
              iconCode: wallet.iconCode,
              type: AccountType.tryParse(wallet.type),
            ),
      parts: [?other],
      amount: switch (e.kind) {
        SavingEntryKind.save => MoneyText(e.amount, tone: MoneyTone.income),
        SavingEntryKind.withdraw => MoneyText(
          -e.amount,
          tone: MoneyTone.expense,
        ),
        SavingEntryKind.move => MoneyText(e.amount, tone: MoneyTone.plain),
      },
      onTap: isSaving ? null : () => _deleteEntry(e),
    );
  }

  String _entryTitle(AppLocalizations l, SavingEntry e) => switch (e.kind) {
    SavingEntryKind.save => l.sgv2KindSave,
    SavingEntryKind.withdraw => l.sgv2KindWithdraw,
    SavingEntryKind.move => l.sgv2KindMove,
  };

  Widget _editBody(AppLocalizations l, SavingGoalDetail? d, BuildContext ctx) {
    final goal = d?.goal;
    final symbol = context.readUserCurrencySymbol;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = working.iconCode.tintFor(palette);
    final barInset = MediaQuery.paddingOf(ctx).top;
    final bottom = AppSpacing.huge + MediaQuery.paddingOf(ctx).bottom;
    return DetailLayout(
      onRefresh: null,
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      hero: AppHeroCard(
        style: HeroStyle.tinted(color: accent, glyph: AppIcons.savingGoal),
        mode: HeroCardMode.edit,
        content: [
          HeroIdentity(
            icon: EditableCircle(
              size: 44,
              onTap: _openIconMaker,
              child: IconCodeWidget(
                iconCode: working.iconCode,
                size: 44,
                fallbackIcon: AppIcons.savingGoal,
                fallbackColor: accent,
              ),
            ),
            name: HeroNameInput(
              editing: true,
              controller: _nameCtrl,
              focusNode: _nameFocus,
              hint: l.commonName,
              maxLength: TextLimits.name,
              maxLines: 2,
              onChanged: (v) => _onText(_Field.name, v),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.savingGoalFormNameRequired
                  : null,
            ),
            description: HeroDescription(
              controller: _descriptionCtrl,
              editing: true,
              hint: l.commonDescription,
              maxLength: TextLimits.description,
              focusNode: _descriptionFocus,
              onChanged: (v) => _onText(_Field.description, v),
            ),
          ),
          HeroAmountField(
            controller: _targetCtrl,
            label: l.savingGoalFormTargetLabel,
            symbol: symbol,
            helper: l.savingGoalFormTargetOptionalHint,
            onChanged: (v) => _onText(_Field.target, v),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final n = AmountInput.parse(v);
              return (n == null || n <= 0)
                  ? l.savingGoalFormTargetInvalid
                  : null;
            },
          ),
        ],
      ),
      info: _planSection(l, symbol),
      note: NoteSection(
        label: l.commonNote,
        editing: true,
        controller: _noteCtrl,
        maxLength: TextLimits.note,
        editField: DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: true,
            controller: _noteCtrl,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            hint: l.fpGoalsNoteHint,
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ),
      endZone: goal == null ? null : _endZone(l, d!, goal),
      metaLines: goal == null
          ? const []
          : detailMetaLines(
              context,
              createdAt: goal.createdAt,
              updatedAt: goal.updatedAt,
            ),
    );
  }

  String _day(DateTime d) => DateFormatter.medium(
    d,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  Widget _walletChip(
    AppLocalizations l,
    SavingWalletRef? wallet, {
    VoidCallback? onTap,
  }) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final d = AccountType.tryParse(wallet?.type)?.iconDefault;
    return AppChip(
      label: wallet?.name ?? l.fpGoalsNoWallet,
      icon: d == null
          ? IconRegistry.get(wallet?.iconCode?.icon, fallback: AppIcons.wallet)
          : wallet?.iconCode.glyphOr(d),
      color: d == null
          ? wallet?.iconCode.tintFor(palette)
          : wallet?.iconCode.tintOr(d, palette),
      trailing: onTap == null ? AppChipTrailing.none : AppChipTrailing.dropdown,
      size: ChipSize.control,
      onTap: onTap,
    );
  }

  /// Edit / create: when it's due, and what it starts with (create only).
  Widget _planSection(AppLocalizations l, String symbol) {
    final w = working;
    final theme = Theme.of(context);
    return SectionCard(
      title: l.sgPlanSection,
      // Editing has the due date only; it says itself.
      description: widget.isCreate ? l.sgPlanSectionDesc : null,
      children: [
        AppDetailRow(
          label: l.savingGoalFormDeadlineLabel,
          trailing: Text(
            w.deadline == null
                ? l.savingGoalFormDeadlinePlaceholder
                : _day(w.deadline!),
          ),
          showChevron: true,
          onTap: _pickDeadline,
        ),
        if (widget.isCreate)
          DetailStacked(
            label: l.sgOpeningLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.sgOpeningHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppInput.card(
                        controller: _openingCtrl,
                        type: AppInputType.amount,
                        currencySymbol: symbol,
                        hint: '0',
                        onChanged: (v) => _onText(_Field.opening, v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _walletChip(l, w.openingWallet, onTap: _pickOpeningWallet),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget? _endZone(AppLocalizations l, SavingGoalDetail d, SavingGoal g) {
    final a = g.actions;
    final holds = g.savedAmount > 0;
    final actions = [
      if (a.close)
        EndZoneAction(
          kind: EndZoneKind.close,
          label: l.sgv2CloseGoal,
          consequence: l.fpGoalsCloseConsequence,
          onTap: isSaving ? null : () => _close(g, d.byWallet),
        ),
      if (!g.isArchived && a.archive)
        EndZoneAction(
          kind: EndZoneKind.archive,
          label: l.savingGoalDetailArchive,
          consequence: holds
              ? l.fpGoalsArchiveConsequenceMoney(
                  moneyString(
                    context,
                    g.savedAmount,
                    symbol: context.readUserCurrencySymbol,
                  ),
                )
              : l.fpGoalsArchiveConsequence,
          onTap: isSaving ? null : () => _archive(g),
        ),
      if (a.delete)
        EndZoneAction(
          kind: EndZoneKind.delete,
          label: l.savingGoalDeleteThis,
          consequence: l.fpGoalsDeleteConsequence,
          onTap: isSaving ? null : _delete,
        ),
    ];
    return actions.isEmpty ? null : EndZone(actions: actions);
  }
}

class _GoalDraft {
  const _GoalDraft({
    this.name = '',
    this.target = '',
    this.deadline,
    this.iconCode,
    this.description = '',
    this.note = '',
    this.opening = '',
    this.openingWallet,
  });

  factory _GoalDraft.from(SavingGoal g) => _GoalDraft(
    name: g.name,
    target: g.targetAmount == null ? '' : AmountInput.format(g.targetAmount!),
    deadline: g.deadline == null ? null : DateTime.tryParse(g.deadline!),
    iconCode: g.iconCode,
    description: g.description ?? '',
    note: g.note ?? '',
  );

  final String name;

  final String target;
  final DateTime? deadline;
  final IconCode? iconCode;
  final String description;
  final String note;

  /// Create only: the first entry, saved right after the goal.
  final String opening;
  final SavingWalletRef? openingWallet;

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
    String? opening,
    SavingWalletRef? openingWallet,
    bool clearOpeningWallet = false,
  }) => _GoalDraft(
    name: name ?? this.name,
    target: target ?? this.target,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    description: description ?? this.description,
    note: note ?? this.note,
    opening: opening ?? this.opening,
    openingWallet: clearOpeningWallet
        ? null
        : (openingWallet ?? this.openingWallet),
  );

  @override
  bool operator ==(Object other) =>
      other is _GoalDraft &&
      other.name == name &&
      other.target == target &&
      other.deadline == deadline &&
      other.iconCode == iconCode &&
      other.description == description &&
      other.note == note &&
      other.opening == opening &&
      other.openingWallet?.id == openingWallet?.id;

  @override
  int get hashCode => Object.hash(
    name,
    target,
    deadline,
    iconCode,
    description,
    note,
    opening,
    openingWallet?.id,
  );
}
