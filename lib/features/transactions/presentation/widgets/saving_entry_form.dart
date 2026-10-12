import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../domain/transaction_type.dart';
import '../cubit/tx_form_options_cubit.dart';
import 'account_picker_sheet.dart';
import 'pick_chip_rows.dart';

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

/// Quick create's ออม-mode body: the SAME EntryCard (a "🐷 ออม" badge in the
/// mode colour in place of the type chips, a note line in place of the
/// description), the from-wallet chip row, the target chip row (spare + the
/// user's active goals). Calls: the goals list once.
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

  final _walletOrder = ChipOrder();

  /// The user's active goals (the target chips), null while loading.
  List<SavingGoal>? _goals;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final o = await context.read<SavingGoalsRepository>().list();
      if (mounted) setState(() => _goals = o.goals);
    } catch (_) {
      // The spare chip still works; no goal chips.
      if (mounted) setState(() => _goals = const []);
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
    );
    if (r is AccountPickerSelected && mounted) _c.setAccount(r.account);
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

  Widget _walletRow(AppLocalizations l) => WalletChipRow(
    selectedId: _c.account?.id,
    onPick: _c.setAccount,
    onMore: _pickAccount,
    order: _walletOrder,
    pickLabel: l.savingEntryWalletRequired,
  );

  Widget _targetRow(AppLocalizations l) {
    final goals = _goals;
    return ChipRow(
      icon: AppIcons.savingGoal,
      chips: [
        AppChip(
          label: l.savingEntrySpare,
          selected: _c.goalId == null,
          onTap: () => _c.setGoal(null),
        ),
        if (goals == null)
          for (var i = 0; i < 2; i++)
            const SkeletonBox(width: 72, height: 28, borderRadius: 14),
        for (final g in goals ?? const <SavingGoal>[])
          AppChip(
            label: g.name,
            selected: _c.goalId == g.id,
            onTap: () => _c.setGoal(g.id),
          ),
      ],
    );
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
              label: '🐷 ${l.quickModeSaving}',
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
            walletRow: _walletRow(l),
            categoryRow: _targetRow(l),
          ),
        ],
      ),
    );
  }
}
