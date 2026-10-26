import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../../saving_goals/domain/saving_goals_overview.dart';
import '../../../saving_goals/presentation/widgets/saving_goal_picker.dart';
import '../../domain/transaction_type.dart';
import '../cubit/tx_form_options_cubit.dart';

class SavingEntryController extends ChangeNotifier {
  SavingEntryController({this.goalId}) {
    amount.addListener(notifyListeners);
    note.addListener(notifyListeners);
  }

  final amount = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();

  Account? account;

  String? goalId;

  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  bool get hasKeyData => amountValue > 0 || note.text.trim().isNotEmpty;

  double? get available => account?.savings?.available;

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
      if (mounted) setState(() => _overview = const SavingGoalsOverview());
    }
  }

  Future<void> _pickAccount() async {
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await AccountPicker.one(
      context,
      accounts: accounts,
      selectedId: _c.account?.id,
      allowNone: true,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _c.setAccount(r is AccountPicked ? r.account : null);
  }

  Future<void> _pickDate() async {
    final r = await AppDatePicker.show(
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

  Widget _walletCard(AppLocalizations l) => WalletPickCard(
    account: _c.account,
    label: l.transactionFormAccountLabel,
    placeholder: l.quickPickWallet,
    dense: true,
    editable: true,
    onTap: _pickAccount,
  );

  /// Where it goes: the chosen goal, else ยังไม่จัดสรร (the spare pool, which
  /// is a real choice, so it reads as picked).
  Widget _goalCard(AppLocalizations l) {
    SavingGoal? chosen;
    for (final g in _goals ?? const <SavingGoal>[]) {
      if (g.id == _c.goalId) chosen = g;
    }
    return SavingGoalPickCard(
      goal: chosen,
      spare: chosen == null,
      spareAmount: _overview?.spare.amount,
      label: l.savingEntryGoalLabel,
      placeholder: l.savingEntryPickGoal,
      spareLabel: l.savingEntrySpare,
      dense: true,
      editable: true,
      onTap: _pickGoal,
    );
  }

  Future<void> _pickGoal() async {
    final r = await SavingGoalPicker.one(
      context,
      selectedId: _c.goalId,
      spareSelected: _c.goalId == null,
      overview: _overview,
    );
    if (r != null && mounted) _c.setGoal(r.goalId);
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
