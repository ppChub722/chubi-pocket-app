import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';

/// "ค้างอยู่ / คืนครบแล้ว / ยกเลิก".
AppChip debtStatusChip(
  BuildContext context,
  DebtStatus s, {
  ChipSize size = ChipSize.control,
}) {
  final l = AppLocalizations.of(context)!;
  final (String label, AppChipTone tone) = switch (s) {
    DebtStatus.open => (l.debtsStatusOpen, AppChipTone.warning),
    DebtStatus.settled => (l.debtStatusSettled, AppChipTone.success),
    DebtStatus.cancelled => (l.debtStatusCancelled, AppChipTone.neutral),
  };
  return AppChip(
    label: label,
    dot: true,
    tone: tone,
    selected: true,
    size: size,
  );
}

/// One debt as a row on the person's page (the name is the page) — the
/// description (what for) on top when there is one, then direction + date;
/// progress for open ones, and the outstanding (open) or full (closed)
/// amount tinted by who owes whom. The note stays on the detail page.
class DebtTile extends StatelessWidget {
  const DebtTile({required this.debt, super.key});

  final PersonalDebt debt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final symbol = Currencies.symbolOf(debt.currency);
    final dir = debt.isOwedToMe ? l.debtsOwedToMe : l.debtsIOwe;
    final description = debt.description?.trim() ?? '';
    final meta = [
      dir,
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
                  child: description.isEmpty
                      ? Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium,
                            ),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (!debt.isOpen) ...[
                  debtStatusChip(context, debt.status, size: ChipSize.chip),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // Overpaid: the difference, owed the other way, flagged.
                if (debt.isOpen && debt.isOverpaid) ...[
                  AppChip(
                    label: l.debtOverpaid,
                    dot: true,
                    tone: AppChipTone.warning,
                    selected: true,
                    size: ChipSize.chip,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                MoneyText(
                  debt.isOpen ? debt.outstanding.abs() : debt.amount,
                  symbol: symbol,
                  tone: debt.isOpen
                      ? ((debt.isOwedToMe != debt.isOverpaid)
                            ? MoneyTone.income
                            : MoneyTone.expense)
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
/// "รับเงินคืน / จ่ายคืน" — the quick-create look (owner 2026-10-10): the
/// transaction hero (amount ≤ outstanding · คำอธิบาย, blank = the debt's ·
/// date) with ทั้งหมด / ครึ่งหนึ่ง quick fills, the wallet card (or
/// "ไม่ผูกกระเป๋า" → a floating row) and an optional โน้ต. Always records a
/// transaction — income for owed_to_me, expense for i_owe (contract §7).
/// The wallet starts at the last one used, like quick create.
///
/// [amount] pre-fills the field (e.g. from a "จ่ายแล้ว" notification).
/// Returns true when saved.
Future<bool> showSettleDebtSheet(
  BuildContext context,
  PersonalDebt debt, {
  double? amount,
}) async {
  final l = AppLocalizations.of(context)!;
  final accounts = context.read<AccountsCubit>();
  final debts = context.read<PersonalDebtsCubit>();
  if (accounts.state.accounts.isEmpty) await accounts.load();
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  final name = debt.counterpartyPersonName;
  final symbol = Currencies.symbolOf(debt.currency);
  final locale = Localizations.localeOf(context).languageCode;
  final all = accounts.state.accounts;
  final last = prefs.getString(StorageKeys.lastAccountId);
  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final result = await showSettleSheet(
    context,
    data: SettleSheetData(
      isReceive: debt.isOwedToMe,
      outstanding: debt.outstanding,
      symbol: symbol,
      description: debt.description,
      initialAmount: amount,
    ),
    labels: SettleSheetLabels(
      title: debt.isOwedToMe
          ? l.debtSettleTitleReceive(name)
          : l.debtSettleTitlePay(name),
      confirm: l.debtSettleConfirm,
      amountLabel: l.debtOutstanding,
      amountRequired: l.debtAmountRequired,
      amountOver: l.debtSettleOver,
      all: l.debtSettleAll,
      half: l.debtSettleHalf,
      noteLabel: l.commonNote,
      descriptionHint: l.txHeroTitleHint,
      formatDate: (d) => DateFormatter.friendly(
        d,
        today: l.commonToday,
        yesterday: l.commonYesterday,
        locale: locale,
      ),
    ),
    // The wallet starts at the last one used, like quick create.
    initialAccount:
        all.where((a) => a.id == last).firstOrNull ?? all.firstOrNull,
    walletField: (ctx, selected, onChanged) => WalletPickCard(
      account: selected,
      label: l.debtSettleAccount,
      placeholder: l.transactionFormAccountNone,
      onTap: () async {
        final r = await showAccountPickerSheet(
          context: ctx,
          accounts: accounts.state.accounts,
          selected: selected,
          title: l.debtSettleAccount,
          allowNone: true,
        );
        if (r is AccountPickerSelected) onChanged(r.account);
        if (r is AccountPickerCleared) onChanged(null);
      },
    ),
    onConfirm: (r) async {
      try {
        final settled = await debts.settle(
          debt.id,
          accountId: r.account?.id,
          amount: r.amount,
          date: ymd(r.date),
          // Left blank → the server uses the debt's description.
          description: r.description,
          note: r.note,
        );
        final account = r.account;
        if (account != null) {
          await prefs.setString(StorageKeys.lastAccountId, account.id);
        }
        // A transaction was recorded: the wallets' new balances come with the
        // answer; the tx lists re-fetch.
        accounts.patchBalances(settled.accountBalances);
        await TransactionsCubit.bookChanged();
        return null;
      } on ApiException catch (e) {
        return e.code == 'DEBT_OVERPAID' ? l.debtOverpaidCantSettle : e.message;
      }
    },
  );
  return result != null;
}
