import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../widgets/saving_goal_picker.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_entry.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goals_overview.dart';
import '../../domain/saving_plan_preview.dart';
import '../cubit/saving_goal_cubit.dart';
import '../cubit/saving_goals_cubit.dart';
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

const int _defaultAutoSaveDay = 25;

class _SavingGoalDetailPageState extends State<SavingGoalDetailPage>
    with EditModeMixin<SavingGoalDetailPage, _GoalDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _autoCtrls = <int, TextEditingController>{};
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
    _openingCtrl.dispose();
    for (final c in _autoCtrls.values) {
      c.dispose();
    }
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
    final keys = {for (final a in working.autos) a.key};
    _autoCtrls.removeWhere((k, c) {
      if (keys.contains(k)) return false;
      c.dispose();
      return true;
    });
    for (final a in working.autos) {
      final c = _autoCtrls[a.key];
      if (c != null) sync(c, a.amount);
    }
  }

  void _onText(_Field field, String v) =>
      applyTextChange(field, switch (field) {
        _Field.name => working.copyWith(name: v),
        _Field.target => working.copyWith(target: v),
        _Field.description => working.copyWith(description: v),
        _Field.note => working.copyWith(note: v),
        _Field.opening => working.copyWith(opening: v),
      });

  TextEditingController _autoCtrl(_AutoDraft a) => _autoCtrls.putIfAbsent(
    a.key,
    () => TextEditingController(text: a.amount),
  );

  void _changeAuto(_AutoDraft a, _AutoDraft next) => applyChange(
    working.copyWith(
      autos: [for (final x in working.autos) x.key == a.key ? next : x],
    ),
  );

  void _onAutoAmount(_AutoDraft a, String v) => applyTextChange(
    ('auto', a.key),
    working.copyWith(
      autos: [
        for (final x in working.autos)
          x.key == a.key ? x.copyWith(amount: v) : x,
      ],
    ),
  );

  /// A new line: monthly on the 25th, the first one carrying what the plan
  /// needs a month.
  _AutoDraft _newAuto() {
    final w = working;
    final target = AmountInput.parse(w.target);
    final needed = w.autos.isNotEmpty || target == null
        ? null
        : SavingPlanPreview.of(
            target: target,
            saved: _cubit?.state.detail?.goal?.savedAmount ?? 0,
            deadline: w.deadline,
          ).neededMonthly;
    return _AutoDraft(
      amount: needed == null ? '' : AmountInput.format(needed),
      rule: RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: _nextMonthDay(_defaultAutoSaveDay),
        monthly: const RecurrenceMonthly(
          mode: RecurrenceMonthlyMode.day,
          day: _defaultAutoSaveDay,
        ),
      ),
    );
  }

  void _toggleAutoDraft(bool on) => applyChange(
    working.copyWith(
      autoOn: on,
      autos: on && working.autos.isEmpty ? [_newAuto()] : null,
    ),
  );

  void _addAuto() =>
      applyChange(working.copyWith(autos: [...working.autos, _newAuto()]));

  void _removeAuto(_AutoDraft a) {
    final rest = [
      for (final x in working.autos)
        if (x.key != a.key) x,
    ];
    applyChange(working.copyWith(autos: rest, autoOn: rest.isNotEmpty));
  }

  Future<void> _pickAutoRule(_AutoDraft a) async {
    final r = await showRecurrenceSheet(context, initial: a.rule);
    if (r == null || !mounted || r == a.rule) return;
    _changeAuto(a, a.copyWith(rule: r));
  }

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

  Future<void> _pickAutoWallet(_AutoDraft a) async {
    final r = await _pickWallet(a.wallet);
    if (r == null || !mounted) return;
    final (wallet,) = r;
    _changeAuto(
      a,
      wallet == null
          ? a.copyWith(clearWallet: true)
          : a.copyWith(wallet: wallet),
    );
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

  Future<void> _save(SavingGoal? goal) async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    if (w.sentAutos.any((a) => (AmountInput.parse(a.amount) ?? 0) <= 0)) {
      _snack(
        AppLocalizations.of(context)!.sgAutoAmountInvalid,
        tone: Tone.danger,
      );
      return;
    }
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
      final before = original.sentAutos;
      final after = w.sentAutos;
      if (!listEquals(before, after)) {
        await _cubit!.setAutoSaves([for (final a in after) a.write()]);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _snack(e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final saved = _cubit!.state.detail?.goal;
    _seededFrom = saved;
    commitSaved(saved == null ? w.trimmed() : _GoalDraft.from(saved));
  }

  /// The goal first; then its starting amount and its auto-saves. A failure
  /// after the goal exists is said once and the page still leaves.
  Future<void> _create(SavingGoal draft, _GoalDraft w) async {
    final l = AppLocalizations.of(context)!;
    final repo = context.read<SavingGoalsRepository>();
    final String id;
    try {
      id = (await repo.create(draft)).goal!.id;
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _snack(e.message, tone: Tone.danger);
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
      if (w.sentAutos.isNotEmpty) {
        await repo.setAutoSaves(id, [for (final a in w.sentAutos) a.write()]);
      }
    } on ApiException catch (e) {
      failed = e.message;
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
        _snack(message?.call(e) ?? e.message, tone: Tone.danger);
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
        _snack(e.message, tone: Tone.danger);
      }
      return;
    }
    if (!mounted) return;
    setSaving(false);
    // A goal holding money cannot be deleted: say so, no confirm.
    if (preview != null && !preview.canDelete) {
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
          message: (e) => e.code == 'GOAL_HAS_SAVINGS' ? needsClose : null,
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

  Future<void> _toggleAuto(SavingGoalDetail d, bool on) async {
    if (!on) {
      await _run(_cubit!.clearAutoSave);
      return;
    }
    final plan = d.goal?.monthPlan ?? d.goal?.neededMonthly;
    if (plan == null || plan <= 0) {
      await _editAuto(d);
      return;
    }
    await _setAuto(amount: plan, day: _defaultAutoSaveDay);
  }

  Future<void> _setAuto({
    required double amount,
    required int day,
    String? accountId,
  }) => _run(
    () => _cubit!.setAutoSave(amount: amount, day: day, accountId: accountId),
  );

  Future<void> _editAuto(SavingGoalDetail d) async {
    final l = AppLocalizations.of(context)!;
    final auto = d.autoSave;
    final noWallet = SavingAutoSaveWallet(label: l.fpGoalsNoWallet);
    final r = await showSavingAutoSaveSheet(
      context,
      title: l.fpGoalsAutoSheetTitle,
      amountLabel: l.sgv2AmountLabel,
      dayLabel: l.fpGoalsAutoDay,
      walletLabel: l.fpGoalsAutoFrom,
      saveLabel: l.commonSave,
      amount: auto?.amount ?? d.goal?.monthPlan ?? d.goal?.neededMonthly ?? 0,
      day: auto?.day ?? _defaultAutoSaveDay,
      wallet: auto?.wallet == null
          ? noWallet
          : SavingAutoSaveWallet(
              id: auto!.wallet!.id,
              label: auto.wallet!.name,
            ),
      currencySymbol: context.readUserCurrencySymbol,
      onPickWallet: () async {
        final picked = await AccountPicker.one(
          context,
          selectedId: auto?.wallet?.id,
          allowNone: true,
          title: l.fpGoalsAutoFrom,
        );
        return switch (picked) {
          AccountPicked(:final account) => SavingAutoSaveWallet(
            id: account.id,
            label: account.name,
          ),
          AccountPickedNone() => noWallet,
          null => null,
        };
      },
    );
    if (r == null || !mounted) return;
    await _setAuto(amount: r.amount, day: r.day, accountId: r.accountId);
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
        AppTab(value: _GoalTab.overview, label: l.sgv2Overview),
        AppTab(value: _GoalTab.entries, label: l.sgv2Entries),
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
    List<HeroFact> factsOf(Color? warning) => !active || reached
        ? [
            HeroFact(
              l.fpGoalsFactTarget,
              money(target),
              icon: AppIcons.target,
            ),
            if (reached && closed != null)
              HeroFact(
                l.fpGoalsFactReachedOn,
                DateFormatter.medium(closed, locale: locale),
                icon: AppIcons.date,
              ),
            if (!reached && left > 0)
              HeroFact(l.fpGoalsFactLeft, money(left), icon: AppIcons.hourglass),
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
      if (active && !reached) ...[
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
            size: 40,
            onLongPress: _enterEditThenOpenMaker,
            child: IconCodeWidget(
              iconCode: g.iconCode,
              size: 40,
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
                marker: reached ? null : pace,
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
        if (chips.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: chips,
          ),
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
    String money(double v) => moneyString(context, v, symbol: symbol);
    final active = g.state == SavingGoalState.active;
    final autos = g.autoSaves;
    final rule = autos.length == 1 ? autos.first.rule : null;
    final monthly = autos.length == 1 && (rule == null || rule.monthly != null);
    return AppHeroCard(
      style: style,
      header: active
          ? null
          : HeroHeader(leading: [?savingGoalStatusChip(l, g)]),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: 40,
            onLongPress: _enterEditThenOpenMaker,
            child: IconCodeWidget(
              iconCode: g.iconCode,
              size: 40,
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
              HeroFact(
                l.fpGoalsTileSaved,
                money(g.monthSaved),
                icon: AppIcons.savings,
              ),
              if (monthly)
                HeroFact(
                  l.fpGoalsTileAuto,
                  l.fpGoalsPerMonth(money(autos.first.amount)),
                  icon: AppIcons.recurring,
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
    final settings = _settings(l, d, symbol);
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

  /// View: a goal's auto-saves listed as the edit page lists them, read-only.
  Widget _autoView(AppLocalizations l, SavingGoal g, String symbol) {
    final autos = [for (final a in g.autoSaves) _AutoDraft.from(a)];
    return SectionCard(
      children: [
        DetailRow(
          label: l.sgv2AutoSave,
          helper: autos.isEmpty ? l.sgAutoOffCaption : l.sgAutoOnCaption,
          onLongPress: enterEdit,
        ),
        for (final a in autos) _autoLine(l, a, symbol, editing: false),
        if (autos.isNotEmpty) const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget? _settings(AppLocalizations l, SavingGoalDetail d, String symbol) {
    final g = d.goal;
    if (g != null && g.state != SavingGoalState.active) return null;
    if (g != null) return _autoView(l, g, symbol);
    final auto = d.autoSave;
    return SettingsSection(
      title: l.settingsTitle,
      description: l.fpGoalsSettingsDesc,
      children: [
        SettingToggleRow(
          label: l.sgv2AutoSave,
          caption: auto == null
              ? l.fpGoalsAutoOffHint
              : savingAutoSaveCaption(context, l, auto, symbol),
          value: auto != null,
          onChanged: isSaving ? null : (on) => _toggleAuto(d, on),
        ),
        if (auto != null)
          SettingSummaryRow(
            label: l.fpGoalsAutoEdit,
            onTap: isSaving ? null : () => _editAuto(d),
          ),
      ],
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
        DateGroupHeader(
          label: switch (DateFormatter.parseDay(date)) {
            final day? => DateFormatter.friendly(
              day,
              today: l.commonToday,
              yesterday: l.commonYesterday,
              locale: locale,
            ),
            null => date,
          },
          total: entries.fold<double>(0, (sum, e) => sum + signed(e)),
        ),
        for (final e in entries) _entryRow(l, e),
      ],
    ];
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
      key: ValueKey(e.id),
      kind: kind,
      title: _entryTitle(l, e),
      amount: e.amount,
      walletLabel: e.wallet?.name ?? l.fpGoalsNoWallet,
      from: e.kind == SavingEntryKind.save ? null : end(e.from),
      to: e.kind == SavingEntryKind.withdraw ? null : end(e.to),
      source: e.fromRecurring
          ? AppChip(label: l.fpGoalsAutoTag, size: ChipSize.mini)
          : null,
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
    return AppChip(
      label: wallet?.name ?? l.fpGoalsNoWallet,
      icon: IconRegistry.get(wallet?.iconCode?.icon, fallback: AppIcons.wallet),
      color: wallet?.iconCode.tintFor(palette),
      trailing: onTap == null ? AppChipTrailing.none : AppChipTrailing.dropdown,
      size: ChipSize.control,
      onTap: onTap,
    );
  }

  /// Edit / create: when it's due, what it starts with (create only), and the
  /// auto-saves.
  Widget _planSection(AppLocalizations l, String symbol) {
    final w = working;
    final theme = Theme.of(context);
    return SectionCard(
      title: l.sgPlanSection,
      description: l.sgPlanSectionDesc,
      children: [
        DetailRow(
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
        SettingToggleRow(
          label: l.sgv2AutoSave,
          caption: w.autoOn ? l.sgAutoOnCaption : l.sgAutoOffCaption,
          value: w.autoOn,
          submits: false,
          onChanged: _toggleAutoDraft,
        ),
        if (w.autoOn) ...[
          for (final a in w.autos) _autoLine(l, a, symbol, editing: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                icon: AppIcons.add,
                label: l.sgAutoAdd,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.control,
                onPressed: _addAuto,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// One auto-save laid out like a split-bill row: the wallet, the amount,
  /// ✕; its round and next date under the name.
  Widget _autoLine(
    AppLocalizations l,
    _AutoDraft a,
    String symbol, {
    required bool editing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final next = a.nextDate == null ? null : DateTime.tryParse(a.nextDate!);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SplitRow(
            avatar: IconCodeWidget(
              iconCode: a.wallet?.iconCode,
              size: SplitRow.avatarSize,
              fallbackIcon: AppIcons.wallet,
              fallbackColor: scheme.onSurfaceVariant,
            ),
            name: SplitRowName.picked(
              a.wallet?.name ?? l.fpGoalsNoWallet,
              onTap: editing ? () => _pickAutoWallet(a) : null,
            ),
            amount: editing
                ? SizedBox(
                    width: 104,
                    height: SplitRow.height,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AppInput.card(
                        controller: _autoCtrl(a),
                        type: AppInputType.amount,
                        hint: '0',
                        onChanged: (v) => _onAutoAmount(a, v),
                      ),
                    ),
                  )
                : MoneyText(AmountInput.parse(a.amount) ?? 0, symbol: symbol),
            trailing: editing
                ? SplitRowAction(
                    icon: AppIcons.close,
                    tooltip: l.commonRemove,
                    onTap: () => _removeAuto(a),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: SplitRow.avatarSize + AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppChip(
                  label: recurrenceLabel(l, a.rule, showEnd: true),
                  icon: AppIcons.recurring,
                  tone: AppChipTone.primary,
                  trailing: editing
                      ? AppChipTrailing.dropdown
                      : AppChipTrailing.none,
                  size: ChipSize.chip,
                  onTap: editing ? () => _pickAutoRule(a) : null,
                ),
                AppChip(
                  label: next == null
                      ? l.sgAutoFirst(_day(a.rule.start))
                      : l.sgAutoNext(_day(next)),
                  icon: AppIcons.date,
                  size: ChipSize.chip,
                ),
              ],
            ),
          ),
        ],
      ),
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

/// One auto-save in the edit page; [key] ties it to its amount field.
class _AutoDraft {
  _AutoDraft({
    required this.amount,
    required this.rule,
    this.id,
    this.wallet,
    this.nextDate,
    int? key,
  }) : key = key ?? _nextKey++;

  static int _nextKey = 0;

  factory _AutoDraft.from(SavingAutoSave a) => _AutoDraft(
    id: a.id,
    amount: AmountInput.format(a.amount),
    wallet: a.wallet,
    rule:
        a.rule ??
        RecurrenceRule(
          freq: RecurrenceFreq.monthly,
          start: _nextMonthDay(a.day),
          monthly: RecurrenceMonthly(
            mode: RecurrenceMonthlyMode.day,
            day: a.day,
          ),
        ),
    nextDate: a.nextDate,
  );

  final int key;
  final String? id;
  final String amount;
  final SavingWalletRef? wallet;
  final RecurrenceRule rule;

  /// The BE's next date; dropped once the round changes.
  final String? nextDate;

  _AutoDraft copyWith({
    String? amount,
    SavingWalletRef? wallet,
    bool clearWallet = false,
    RecurrenceRule? rule,
  }) => _AutoDraft(
    key: key,
    id: id,
    amount: amount ?? this.amount,
    wallet: clearWallet ? null : (wallet ?? this.wallet),
    rule: rule ?? this.rule,
    nextDate: rule == null ? nextDate : null,
  );

  SavingAutoSaveWrite write() => SavingAutoSaveWrite(
    id: id,
    amount: AmountInput.parse(amount) ?? 0,
    rule: rule,
    accountId: wallet?.id,
  );

  @override
  bool operator ==(Object other) =>
      other is _AutoDraft &&
      other.id == id &&
      other.amount == amount &&
      other.wallet?.id == wallet?.id &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(id, amount, wallet?.id, rule);
}

/// The next [day] of a month on or after today (a short month: its last day).
DateTime _nextMonthDay(int day) {
  final now = DateTime.now();
  DateTime on(int y, int m) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day > last ? last : day);
  }

  final d = on(now.year, now.month);
  return d.isBefore(DateTime(now.year, now.month, now.day))
      ? on(now.year, now.month + 1)
      : d;
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
    this.autoOn = false,
    this.autos = const [],
  });

  factory _GoalDraft.from(SavingGoal g) => _GoalDraft(
    name: g.name,
    target: g.targetAmount == null ? '' : AmountInput.format(g.targetAmount!),
    deadline: g.deadline == null ? null : DateTime.tryParse(g.deadline!),
    iconCode: g.iconCode,
    description: g.description ?? '',
    note: g.note ?? '',
    autoOn: g.autoSaves.isNotEmpty,
    autos: [for (final a in g.autoSaves) _AutoDraft.from(a)],
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

  final bool autoOn;
  final List<_AutoDraft> autos;

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
    bool? autoOn,
    List<_AutoDraft>? autos,
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
    autoOn: autoOn ?? this.autoOn,
    autos: autos ?? this.autos,
  );

  /// What PUT …/auto-saves should hold.
  List<_AutoDraft> get sentAutos => autoOn ? autos : const [];

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
      other.openingWallet?.id == openingWallet?.id &&
      other.autoOn == autoOn &&
      listEquals(other.autos, autos);

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
    autoOn,
    Object.hashAll(autos),
  );
}
