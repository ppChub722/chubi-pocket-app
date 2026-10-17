import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../../saving_goals/domain/saving_goals_overview.dart';
import '../../domain/transaction_type.dart';
import '../cubit/tx_form_options_cubit.dart';
import 'account_picker_sheet.dart';

/// The fields of quick create's ออม MODE (goals v2): an amount, the wallet it
/// comes from, where it goes (the spare bucket or a goal), a date and a note.
/// Saving is a notebook entry, never a transaction: the wallet balance does
/// not move.
class SavingEntryController extends ChangeNotifier {
  SavingEntryController({this.goalId}) {
    amount.addListener(notifyListeners);
    note.addListener(notifyListeners);
  }

  final amount = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();

  /// The wallet the money comes from (required to save).
  Account? account;

  /// The target goal; null = "ยังไม่จัดสรร" (spare).
  String? goalId;

  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  bool get hasKeyData => amountValue > 0 || note.text.trim().isNotEmpty;

  /// What the picked wallet still has free to save (null = not tracked /
  /// unknown).
  double? get available => account?.savings?.available;

  /// More than is free: a red, non-blocking warning (a notebook, not a bank).
  double get overBy {
    final a = available;
    if (a == null) return 0;
    final d = amountValue - a;
    return d > 0 ? d : 0;
  }

  void setAccount(Account? a) {
    account = a;
    notifyListeners();
  }

  void setGoal(String? id) {
    goalId = id;
    notifyListeners();
  }

  void setDate(DateTime d) {
    date = d;
    notifyListeners();
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }
}

/// Quick create's ออม-mode body: the SAME EntryCard (an "ออม" badge in the
/// planning colour in place of the type chips, a note line in place of the
/// description), the from-wallet chip row, the goal row ("+ เลือกเป้าหมาย", or
/// the chosen goal; ยังไม่จัดสรร = none chosen, picked in the card picker).
/// Calls: the goals list once.
class SavingEntryForm extends StatefulWidget {
  const SavingEntryForm({
    required this.controller,
    this.heroKey,
    this.autofocus = false,
    super.key,
  });

  final SavingEntryController controller;
  final GlobalKey? heroKey;
  final bool autofocus;

  @override
  State<SavingEntryForm> createState() => _SavingEntryFormState();
}

class _SavingEntryFormState extends State<SavingEntryForm> {
  SavingEntryController get _c => widget.controller;

  /// The user's goals + the spare pool (the goal chips and the picker), null
  /// while loading.
  SavingGoalsOverview? _overview;
  List<SavingGoal>? get _goals => _overview?.goals;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final o = await context.read<SavingGoalsRepository>().list();
      if (mounted) setState(() => _overview = o);
    } catch (_) {
      // Saving to ยังไม่จัดสรร still works; no goal chips.
      if (mounted) setState(() => _overview = const SavingGoalsOverview());
    }
  }

  Future<void> _pickAccount() async {
    final l = AppLocalizations.of(context)!;
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selected: _c.account,
      title: l.transactionFormAccountLabel,
      // Saving needs no wallet: money kept outside the app goes to the goal.
      allowNone: true,
    );
    if (!mounted || r == null) return;
    _c.setAccount(r is AccountPickerSelected ? r.account : null);
  }

  Future<void> _pickDate() async {
    final r = await showAppDatePicker(
      context,
      initial: _c.date,
      first: DateTime(2000),
      last: DateTime.now().add(const Duration(days: 365)),
    );
    if (r is AppDatePicked) _c.setDate(r.date);
  }

  String _dayLabel(AppLocalizations l, DateTime d) => DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// "ว่าง ฿21,500" under the amount; red "เกินที่ว่าง …" when over (still allowed).
  Widget? _availableLine(AppLocalizations l, String symbol) {
    final a = _c.available;
    if (a == null) return null;
    if (_c.overBy > 0) {
      return AppText(
        l.savingEntryOverAvailable(
          moneyString(context, _c.overBy, symbol: symbol),
        ),
        role: AppTextRole.caption,
        color: Theme.of(context).colorScheme.error,
      );
    }
    return AppText(
      l.savingEntryAvailable(moneyString(context, a, symbol: symbol)),
      role: AppTextRole.caption,
    );
  }

  /// The wallet it comes from — optional (money kept outside the app counts
  /// for the goal only).
  Widget _walletCard(AppLocalizations l) => WalletPickCard(
    account: _c.account,
    label: l.transactionFormAccountLabel,
    placeholder: l.savingEntryWalletOptional,
    dense: true,
    twoLine: true,
    editable: true,
    onTap: _pickAccount,
  );

  /// Where it goes: the chosen goal, else ยังไม่จัดสรร (the spare pool, which
  /// is a real choice, so it reads as picked). Picked in the card picker — no
  /// suggested goals.
  Widget _goalCard(AppLocalizations l) {
    final palette = Theme.of(context).extension<AppColors>()!;
    SavingGoal? chosen;
    for (final g in _goals ?? const <SavingGoal>[]) {
      if (g.id == _c.goalId) chosen = g;
    }
    return PickCard(
      label: l.savingEntryGoalLabel,
      value: chosen?.name ?? l.savingEntrySpare,
      dense: true,
      editable: true,
      accent: chosen == null
          ? ModuleColors.of(context).planning
          : chosen.iconCode.tintFor(palette),
      leading: chosen == null
          ? const PickCardEmptyIcon(AppIcons.quickSaving, size: 32)
          : IconDisplay(
              type: IconType.category,
              size: 32,
              iconCode: chosen.iconCode,
            ),
      onTap: _pickGoal,
    );
  }

  /// The card picker: ยังไม่จัดสรร first, then the goals.
  Future<void> _pickGoal() async {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final planning = ModuleColors.of(context).planning;
    String money(double v) => moneyString(context, v, symbol: symbol);
    final overview = _overview;
    final r = await showSavingGoalPickerSheet(
      context,
      title: l.savingEntryPickGoal,
      selectedId: _c.goalId,
      items: [
        SavingGoalPick(
          id: null,
          name: l.savingEntrySpare,
          icon: AppIcons.quickSaving,
          color: planning,
          amountText: overview == null ? null : money(overview.spare.amount),
          caption: l.sgv2SpareHint,
        ),
        for (final g in overview?.goals ?? const <SavingGoal>[])
          SavingGoalPick(
            id: g.id,
            name: g.name,
            icon: IconRegistry.get(
              g.iconCode?.icon,
              fallback: AppIcons.savingGoal,
            ),
            color: g.iconCode.tintFor(palette),
            amountText: money(g.savedAmount),
            targetText: g.targetAmount == null ? null : money(g.targetAmount!),
            progress: g.targetAmount == null || g.targetAmount == 0
                ? null
                : g.savedAmount / g.targetAmount!,
            caption: (g.monthShort ?? 0) > 0
                ? l.fpGoalsMonthShortLine(money(g.monthShort!))
                : (g.status == SavingStatus.behind && (g.behindMonths ?? 0) > 0)
                ? l.sgv2PaceLate(g.behindMonths!)
                : null,
          ),
      ],
    );
    if (r != null && mounted) _c.setGoal(r.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EntryCard(
            key: widget.heroKey,
            // Saving has no income / expense: the badge replaces the chips.
            type: TransactionType.income,
            typeBadge: AppChip(
              label: l.quickModeSaving,
              icon: AppIcons.quickSaving,
              color: QuickCreateModeColors.of(context, QuickCreateMode.saving),
              selected: true,
            ),
            accentColor: QuickCreateModeColors.of(
              context,
              QuickCreateMode.saving,
            ),
            amount: _c.amount,
            title: _c.note,
            dateLabel: _dayLabel(l, _c.date),
            onPickDate: _pickDate,
            autofocus: widget.autofocus,
            symbol: symbol,
            amountNote: _availableLine(l, symbol),
            titleHint: l.savingTitleHint,
            flowRow: FlowCards(from: _walletCard(l), to: _goalCard(l)),
          ),
        ],
      ),
    );
  }
}
