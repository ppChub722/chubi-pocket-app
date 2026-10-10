import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';
import '../core/constants/currencies.dart';
import '../core/theme/app_colors.dart';
import '../features/accounts/domain/account.dart';
import '../features/accounts/domain/account_type.dart';
import '../features/accounts/presentation/widgets/account_card.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../features/transactions/presentation/widgets/tx_compact_hero.dart';
import '../shared/icon_maker/icon_code.dart';
import '../shared/icon_maker/icon_display.dart';
import '../shared/icon_maker/icon_type.dart';
import '../shared/widgets/type_indicator.dart';
import '../shared/widgets/ui.dart';

/// The [CompactHeroBar] presets (owner 2026-10-11) for the gallery and the
/// Detail patterns tab. Not wired into real pages yet. When they are, these
/// move next to their pages (tx / wallet), fed from the real record.

/// tx: `[type chip] description [category chip] amount` — the real
/// preset, [txCompactHeroBar] (it lives next to the transaction detail
/// page, which uses it), with demo values.
CompactHeroBar compactHeroTx(
  BuildContext context, {
  bool isIncome = false,
  String description = 'ข้าวมันไก่',
  String category = 'อาหาร',
  IconCode categoryIcon = const IconCode(icon: 'food'),
  double amount = 1250,
  String currency = 'THB',
}) => txCompactHeroBar(
  context,
  type: isIncome ? TransactionType.income : TransactionType.expense,
  description: description,
  amount: amount,
  categoryName: category,
  categoryIcon: categoryIcon,
  symbol: Currencies.symbolOf(currency),
);

/// wallet: `(icon) name  balance`. The balance takes the wallet's accent,
/// or the liability token for a credit card / pay later.
CompactHeroBar compactHeroWallet(BuildContext context, Account account) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final color = account.type.isCredit
      ? palette.walletLiability
      : (account.iconCode?.accentColorFor(palette) ?? palette.primary);
  return CompactHeroBar(
    leading: AccountIconCircle(account: account, size: 28),
    title: Text(account.name),
    trailing: MoneyText(
      account.balance,
      symbol: Currencies.symbolOf(account.currency),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

const compactHeroDemoBank = Account(
  id: 'demo-bank',
  name: 'กสิกร ออมทรัพย์',
  type: AccountType.bank,
  balance: 48200,
  currency: 'THB',
);

const compactHeroDemoCard = Account(
  id: 'demo-card',
  name: 'บัตรเครดิต KTC ชื่อยาวมากจนต้องตัด',
  type: AccountType.creditCard,
  balance: -12450,
  currency: 'THB',
);

/// The presets, still (always shown), then a mini page that scrolls: the
/// bar shows once its hero has gone under the top line.
class CompactHeroDemo extends StatefulWidget {
  const CompactHeroDemo({super.key});

  @override
  State<CompactHeroDemo> createState() => _CompactHeroDemoState();
}

enum _Preset { tx, wallet, liability }

class _CompactHeroDemoState extends State<CompactHeroDemo> {
  _Preset _preset = _Preset.tx;
  final _heroKey = GlobalKey();

  CompactHeroBar _bar(BuildContext context, _Preset p) => switch (p) {
    _Preset.tx => compactHeroTx(context),
    _Preset.wallet => compactHeroWallet(context, compactHeroDemoBank),
    _Preset.liability => compactHeroWallet(context, compactHeroDemoCard),
  };

  Widget _hero(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final big = textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800);
    return switch (_preset) {
      _Preset.tx => HeaderCard(
        key: _heroKey,
        topRow: const [TypeIndicator(isIncome: false)],
        leading: const IconDisplay(type: IconType.category, size: 52),
        title: const Text('ข้าวมันไก่'),
        subtitle: const Text('อาหาร'),
        footer: MoneyText(1250, style: big?.copyWith(color: palette.expense)),
      ),
      _Preset.wallet || _Preset.liability => HeaderCard(
        key: _heroKey,
        leading: AccountIconCircle(
          account: _preset == _Preset.wallet
              ? compactHeroDemoBank
              : compactHeroDemoCard,
          size: 52,
        ),
        title: Text(
          _preset == _Preset.wallet
              ? compactHeroDemoBank.name
              : compactHeroDemoCard.name,
        ),
        footer: MoneyText(
          _preset == _Preset.wallet
              ? compactHeroDemoBank.balance
              : compactHeroDemoCard.balance,
          style: big,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in _Preset.values) ...[
          _bar(context, p),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        ChoicePillRow<_Preset>(
          values: _Preset.values,
          selected: _preset,
          label: (p) => switch (p) {
            _Preset.tx => 'รายการ',
            _Preset.wallet => 'กระเป๋า',
            _Preset.liability => 'บัตรเครดิต',
          },
          onSelected: (p) => setState(() => _preset = p),
        ),
        const SizedBox(height: AppSpacing.sm),
        // A mini detail page: scroll it until the hero leaves the top.
        Container(
          height: 320,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: CompactHeroScope(
            key: ValueKey(_preset),
            heroKey: _heroKey,
            top: 0,
            bar: _bar(context, _preset),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _hero(context),
                const SizedBox(height: HeroSpacing.after),
                SectionCard(
                  first: true,
                  children: [
                    for (var i = 1; i <= 12; i++)
                      DetailRow(label: 'แถว $i', trailing: Text('ค่า $i')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
