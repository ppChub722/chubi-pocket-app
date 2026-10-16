import 'package:flutter/material.dart';
import 'package:pp_forge/hub.dart';

import '../../features/accounts/domain/account.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/accounts/presentation/widgets/account_card.dart';
import '../../features/accounts/presentation/widgets/wallet_compact_hero.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/transactions/presentation/widgets/tx_compact_hero.dart';
import '../../ui/ui.dart';

/// `/dev/ui/domain/bars` — chubiPocket's own heroes and compact hero bars,
/// built on ppForge's (see `/dev/ui/molecules/bars` for the kit pieces).
Widget buildDomainBarsPage(BuildContext context) => const _DomainBarsPage();

class _DomainBarsPage extends StatefulWidget {
  const _DomainBarsPage();

  @override
  State<_DomainBarsPage> createState() => _DomainBarsPageState();
}

class _DomainBarsPageState extends State<_DomainBarsPage> {
  final _heroAmount = TextEditingController(text: '1,250');
  final _heroTitle = TextEditingController(text: 'Chicken rice');
  static const _wallet = Account(
    id: 'w',
    name: 'KBank savings',
    type: AccountType.bank,
    balance: 48200,
    currency: 'THB',
  );

  @override
  void dispose() {
    _heroAmount.dispose();
    _heroTitle.dispose();
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: PpForgeSpacing.md);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          note:
              'The app’s own heroes and compact bars — HeroShell / '
              'CompactHeroBar from ppForge, filled with wallets and '
              'transactions.',
          uses: [
            HubUse(
              label: 'Hero — transaction (TxHeroCard)',
              page: 'Transaction detail, quick create',
              wide: true,
              child: TxHeroCard(
                type: TransactionType.expense,
                amount: _heroAmount,
                title: _heroTitle,
                dateLabel: 'Today',
                editing: false,
                inline: true,
                onEdit: () {},
              ),
            ),
            HubUse(
              label: 'Hero — wallet (own surface: wash + glyph, Adjust chip)',
              page: 'Account detail',
              wide: true,
              child: AccountCardSurface(
                account: _wallet,
                margin: EdgeInsets.zero,
                glyphSize: 132,
                child: HeroContent(
                  rows: [
                    HeroTopRow(
                      leading: [
                        PpForgeChip(
                          label: 'Bank',
                          icon: PpForgeIcons.bank,
                          color: scheme.primary,
                          selected: true,
                        ),
                      ],
                      trailing: [
                        PpForgeChip(
                          icon: PpForgeIcons.reset,
                          label: 'Adjust',
                          tone: PpForgeChipTone.primary,
                          selected: true,
                          onTap: () {},
                        ),
                        PpForgeIconButton(
                          icon: PpForgeIcons.edit,
                          size: HeroSpacing.controlHeight,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const AccountIconCircle(account: _wallet, size: 52),
                        const SizedBox(width: PpForgeSpacing.md),
                        Flexible(
                          child: Text('KBank savings', style: text.titleMedium),
                        ),
                      ],
                    ),
                    MoneyText(
                      48200,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'CompactHeroBar — transaction (txCompactHeroBar)',
              page: 'Transaction detail',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  txCompactHeroBar(
                    context,
                    type: TransactionType.expense,
                    description: 'Chicken rice',
                    amount: 1250,
                    categoryName: 'Food',
                    onTap: () {},
                  ),
                  _gap(),
                  txCompactHeroBar(
                    context,
                    type: TransactionType.income,
                    description: '',
                    amount: 30000,
                    categoryName: 'Salary',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'CompactHeroBar — wallet (walletCompactHero)',
              page: 'Account detail',
              wide: true,
              child: walletCompactHero(context, _wallet, onTap: () {}),
            ),
            HubUse(
              label: 'CompactHeroBar — wallet, balance not tracked',
              page: 'Account detail',
              wide: true,
              child: walletCompactHero(
                context,
                _wallet.copyWith(trackBalance: false),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
