import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../../transactions/presentation/widgets/tx_hero_card.dart';
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
StatusPill debtStatusPill(BuildContext context, DebtStatus s) {
  final l = AppLocalizations.of(context)!;
  return switch (s) {
    DebtStatus.open => StatusPill(label: l.debtsStatusOpen, tone: Tone.warning),
    DebtStatus.settled => StatusPill(
      label: l.debtStatusSettled,
      tone: Tone.success,
    ),
    DebtStatus.cancelled => StatusPill(label: l.debtStatusCancelled),
  };
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
                  debtStatusPill(context, debt.status),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // Overpaid: the difference, owed the other way, flagged.
                if (debt.isOpen && debt.isOverpaid) ...[
                  StatusPill(label: l.debtOverpaid, tone: Tone.warning),
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
  if (accounts.state.accounts.isEmpty) await accounts.load();
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  final name = debt.counterpartyPersonName;
  final ok = await showAppSheet<bool>(
    context,
    title: debt.isOwedToMe
        ? l.debtSettleTitleReceive(name)
        : l.debtSettleTitlePay(name),
    builder: (_) => _SettleSheet(debt: debt, amount: amount, prefs: prefs),
  );
  return ok ?? false;
}

class _SettleSheet extends StatefulWidget {
  const _SettleSheet({required this.debt, required this.prefs, this.amount});
  final PersonalDebt debt;
  final SharedPreferences prefs;
  final double? amount;

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  late final _amount = TextEditingController(
    text: AmountField.format(
      // An overpaid debt has a negative outstanding — never an upper bound
      // below 0 (clamp would throw).
      (widget.amount ?? widget.debt.outstanding).clamp(
        0,
        math.max(0, widget.debt.outstanding),
      ),
    ),
  );

  final _description = TextEditingController();
  final _note = TextEditingController();

  /// null = no wallet (a floating transaction).
  Account? _account;
  DateTime _date = DateTime.now();
  bool _saving = false;

  /// Set by a failed confirm, shown under the amount.
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final accounts = context.read<AccountsCubit>().state.accounts;
    final last = widget.prefs.getString(StorageKeys.lastAccountId);
    _account =
        accounts.where((a) => a.id == last).firstOrNull ?? accounts.firstOrNull;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
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

  /// Amount within (0, outstanding]; null = fine.
  String? _amountProblem(AppLocalizations l, String symbol) {
    final n = AmountField.parse(_amount.text);
    final out = widget.debt.outstanding;
    if (n == null || n <= 0) return l.debtAmountRequired;
    if (n > out + 0.005) {
      return l.debtSettleOver(moneyString(context, out, symbol: symbol));
    }
    return null;
  }

  Future<void> _confirm() async {
    final l = AppLocalizations.of(context)!;
    final problem = _amountProblem(
      l,
      Currencies.symbolOf(widget.debt.currency),
    );
    setState(() => _amountError = problem);
    if (problem != null) return;
    final debts = context.read<PersonalDebtsCubit>();
    final accounts = context.read<AccountsCubit>();
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _saving = true);
    try {
      await debts.settle(
        widget.debt.id,
        accountId: _account?.id,
        amount: AmountField.parse(_amount.text),
        date: _ymd(_date),
        // Left blank → the server uses the debt's description.
        description: opt(_description),
        note: opt(_note),
      );
      final account = _account;
      if (account != null) {
        await widget.prefs.setString(StorageKeys.lastAccountId, account.id);
      }
      // A transaction was recorded (and maybe a wallet moved).
      await Future.wait([TransactionsCubit.bookChanged(), accounts.load()]);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        e.code == 'DEBT_OVERPAID'
            ? AppLocalizations.of(context)!.debtOverpaidCantSettle
            : e.message,
        tone: Tone.danger,
      );
    }
  }

  void _fill(double amount) {
    _amount.text = AmountField.format(amount);
    setState(() => _amountError = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final debt = widget.debt;
    final symbol = Currencies.symbolOf(debt.currency);
    final out = debt.outstanding;
    return Padding(
      // No keyboard inset here — AppSheetScaffold (showAppSheet) adds it.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TxHeroCard(
            // Money in for a debt owed to me, out for one I owe.
            type: debt.isOwedToMe
                ? TransactionType.income
                : TransactionType.expense,
            amount: _amount,
            amountLabel: l.debtOutstanding,
            amountError: _amountError,
            title: _description,
            // Left blank, the new row takes the debt's own description.
            titleHint: debt.description ?? l.txHeroTitleHint,
            dateLabel: DateFormatter.friendly(
              _date,
              today: l.commonToday,
              yesterday: l.commonYesterday,
              locale: Localizations.localeOf(context).languageCode,
            ),
            onPickDate: _pickDate,
            symbol: symbol,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ActionChip(
                label: Text(l.debtSettleAll),
                onPressed: () => _fill(out),
              ),
              ActionChip(
                label: Text(l.debtSettleHalf),
                onPressed: () => _fill((out / 2 * 100).roundToDouble() / 100),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WalletPickCard(
            account: _account,
            label: l.debtSettleAccount,
            placeholder: l.transactionFormAccountNone,
            onTap: _pickAccount,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _note,
            label: l.commonNote,
            prefixIcon: AppIcons.note,
            maxLines: 3,
            maxLength: TextLimits.note,
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
    );
  }
}
