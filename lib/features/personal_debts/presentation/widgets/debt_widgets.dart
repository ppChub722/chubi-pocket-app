import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';

/// Avatar for a debt counterparty — the API doesn't send icons, so a linked
/// contact's icon is looked up in [ContactsCubit] (contract §7 will add it).
class DebtAvatar extends StatelessWidget {
  const DebtAvatar({
    required this.contactId,
    required this.name,
    this.size = 40,
    super.key,
  });

  final String? contactId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final contacts = context.select<ContactsCubit, List>(
      (c) => c.state.contacts,
    );
    final match = contactId == null
        ? null
        : contacts.where((c) => c.id == contactId).firstOrNull;
    return UserAvatar(
      displayName: name.isEmpty ? '?' : name,
      iconCode: match?.effectiveIconCode,
      size: size,
    );
  }
}

/// "ค้างอยู่ / คืนครบแล้ว / ยกเลิก".
StatusPill debtStatusPill(
  BuildContext context,
  DebtStatus s, {
  bool dense = false,
}) {
  final l = AppLocalizations.of(context)!;
  return switch (s) {
    DebtStatus.open => StatusPill(
      label: l.debtsStatusOpen,
      tone: Tone.warning,
      dense: dense,
    ),
    DebtStatus.settled => StatusPill(
      label: l.debtStatusSettled,
      tone: Tone.success,
      dense: dense,
    ),
    DebtStatus.cancelled => StatusPill(
      label: l.debtStatusCancelled,
      dense: dense,
    ),
  };
}

/// One debt as a row — direction + note, progress for open ones, and the
/// outstanding (open) or full (closed) amount tinted by who owes whom.
class DebtTile extends StatelessWidget {
  const DebtTile({required this.debt, super.key});

  final PersonalDebt debt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final symbol = Currencies.symbolOf(debt.currency);
    final dir = debt.isOwedToMe ? l.debtsOwedToMe : l.debtsIOwe;
    final subtitle = [
      dir,
      if (debt.note?.isNotEmpty ?? false) debt.note!,
      if (debt.createdAt != null)
        DateFormatter.friendly(
          debt.createdAt!,
          today: l.commonToday,
          yesterday: l.commonYesterday,
          locale: Localizations.localeOf(context).languageCode,
        ),
    ].join(' · ');
    return InkWell(
      onTap: () => context.push('/personal-debts/${debt.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (!debt.isOpen) ...[
                  debtStatusPill(context, debt.status, dense: true),
                  const SizedBox(width: AppSpacing.sm),
                ],
                MoneyText(
                  debt.isOpen ? debt.outstanding : debt.amount,
                  symbol: symbol,
                  tone: debt.isOpen
                      ? (debt.isOwedToMe ? MoneyTone.income : MoneyTone.expense)
                      : MoneyTone.plain,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: debt.isOpen ? null : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (debt.isOpen && debt.settledAmount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              ProgressRow(
                value: debt.amount == 0 ? 0 : debt.settledAmount / debt.amount,
                label: l.debtProgress(
                  moneyString(context, debt.settledAmount, symbol: symbol),
                  moneyString(context, debt.amount, symbol: symbol),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Settle sheet — replaces the old two-dialog flow (§11).
// ────────────────────────────────────────────────────────────────────

/// "รับเงินคืน / จ่ายคืน". Amount (≤ outstanding) with ทั้งหมด / ครึ่งหนึ่ง,
/// wallet (or "ไม่ผูกกระเป๋า" → a floating row) and date. Always records a
/// transaction — income for owed_to_me, expense for i_owe (contract §7).
/// [amount] pre-fills the field (e.g. from a "จ่ายแล้ว" notification).
/// Returns true when saved.
Future<bool> showSettleDebtSheet(
  BuildContext context,
  PersonalDebt debt, {
  double? amount,
}) async {
  final l = AppLocalizations.of(context)!;
  final accounts = context.read<AccountsCubit>();
  if (accounts.state.accounts.isEmpty) await accounts.load();
  if (!context.mounted) return false;
  final name = debt.counterpartyPersonName;
  final ok = await showAppSheet<bool>(
    context,
    title: debt.isOwedToMe
        ? l.debtSettleTitleReceive(name)
        : l.debtSettleTitlePay(name),
    builder: (_) => _SettleSheet(debt: debt, amount: amount),
  );
  return ok ?? false;
}

class _SettleSheet extends StatefulWidget {
  const _SettleSheet({required this.debt, this.amount});
  final PersonalDebt debt;
  final double? amount;

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: AmountField.format(
      (widget.amount ?? widget.debt.outstanding).clamp(
        0,
        widget.debt.outstanding,
      ),
    ),
  );

  /// null = no wallet (a floating transaction).
  Account? _account;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final accounts = context.read<AccountsCubit>().state.accounts;
    _account = accounts.isEmpty ? null : accounts.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickAccount() async {
    final l = AppLocalizations.of(context)!;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: context.read<AccountsCubit>().state.accounts,
      selected: _account,
      title: l.debtSettleAccount,
      allowNone: true,
    );
    if (r is AccountPickerSelected) setState(() => _account = r.account);
    if (r is AccountPickerCleared) setState(() => _account = null);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final debts = context.read<PersonalDebtsCubit>();
    final tx = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    setState(() => _saving = true);
    try {
      await debts.settle(
        widget.debt.id,
        accountId: _account?.id,
        amount: AmountField.parse(_amount.text),
        date: _ymd(_date),
      );
      // A transaction was recorded (and maybe a wallet moved).
      await Future.wait([tx.load(), accounts.load()]);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final debt = widget.debt;
    final symbol = Currencies.symbolOf(debt.currency);
    final out = debt.outstanding;
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountField(
              controller: _amount,
              label: l.debtOutstanding,
              currencySymbol: symbol,
              quickFills: [
                AmountQuickFill(label: l.debtSettleAll, amount: out),
                AmountQuickFill(
                  label: l.debtSettleHalf,
                  amount: (out / 2 * 100).roundToDouble() / 100,
                ),
              ],
              validator: (v) {
                final n = AmountField.parse(v);
                if (n == null || n <= 0) return l.debtAmountRequired;
                if (n > out + 0.005) {
                  return l.debtSettleOver(
                    moneyString(context, out, symbol: symbol),
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            PickerTile(
              label: l.debtSettleAccount,
              value: _account?.name ?? l.transactionFormAccountNone,
              leading: Icon(
                _account == null ? AppIcons.noWallet : AppIcons.bank,
              ),
              onTap: _pickAccount,
            ),
            const SizedBox(height: AppSpacing.sm),
            PickerTile(
              label: l.debtSettleDate,
              value: DateFormatter.friendly(
                _date,
                today: l.commonToday,
                yesterday: l.commonYesterday,
                locale: Localizations.localeOf(context).languageCode,
              ),
              leading: const Icon(AppIcons.date),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.debtSettleConfirm,
              icon: AppIcons.settle,
              expand: true,
              loading: _saving,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
