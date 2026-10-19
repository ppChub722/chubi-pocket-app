import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// Money pieces: MoneyText, MoneyVisibilityToggle, MoneyListTile,
/// DateGroupHeader, CurrencyTile. (IconTile is on Atoms → Badge & avatar,
/// SummaryStats on Organisms → Section & hero.)
Widget buildMoneyPage(BuildContext context) => const _MoneyPage();

class _MoneyPage extends StatefulWidget {
  const _MoneyPage();

  @override
  State<_MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<_MoneyPage> {
  String _currency = 'USD';

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'MoneyText — tones',
          note:
              'The only way an amount reaches the screen. Tone decides colour '
              'and sign; signed reads both from the amount itself.',
          child: HubRow(
            cells: [
              HubCell(caption: 'plain 1250.5', child: const MoneyText(1250.5)),
              HubCell(caption: 'plain -80', child: const MoneyText(-80)),
              HubCell(
                caption: 'income 1250.5',
                child: const MoneyText(1250.5, tone: MoneyTone.income),
              ),
              HubCell(
                caption: 'expense 540',
                child: const MoneyText(540, tone: MoneyTone.expense),
              ),
              HubCell(
                caption: 'signed +300',
                child: const MoneyText(300, tone: MoneyTone.signed),
              ),
              HubCell(
                caption: 'signed -300',
                child: const MoneyText(-300, tone: MoneyTone.signed),
              ),
              HubCell(
                caption: 'signed 0 (no sign / colour)',
                child: const MoneyText(0, tone: MoneyTone.signed),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'MoneyText — symbol and styles',
          note:
              'symbol swaps the currency glyph; style sets the size. '
              'hideable: false keeps an amount visible even under privacy.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'symbol \$',
                child: const MoneyText(
                  1999.99,
                  symbol: '\$',
                  tone: MoneyTone.income,
                ),
              ),
              HubCell(
                caption: 'symbol €',
                child: const MoneyText(
                  42,
                  symbol: '€',
                  tone: MoneyTone.expense,
                ),
              ),
              HubCell(
                caption: 'big (headlineMedium)',
                child: MoneyText(
                  12345.67,
                  tone: MoneyTone.signed,
                  style: text.headlineMedium,
                ),
              ),
              HubCell(
                caption: 'small (labelSmall)',
                child: MoneyText(
                  12.5,
                  tone: MoneyTone.expense,
                  style: text.labelSmall,
                ),
              ),
              HubCell(
                caption: 'hideable: false',
                child: const MoneyText(777, hideable: false),
              ),
              HubCell(
                caption: 'textAlign center, in a box',
                child: const SizedBox(
                  width: 120,
                  child: MoneyText(88, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'MoneyDecimals — formatMoneyWith',
          note:
              'The user picks the decimals in settings: always, never, or '
              'auto (only when there is a fraction).',
          child: HubRow(
            cells: [
              for (final d in MoneyDecimals.values)
                HubCell(
                  caption: d.name,
                  child: Text(
                    '${formatMoneyWith(MoneyStyle(decimals: d), 1000, symbol: '฿')}'
                    ' | ${formatMoneyWith(MoneyStyle(decimals: d), 99.5, symbol: '฿')}',
                  ),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'MoneyText — hidden (privacy) vs shown',
          note:
              'kMoneyPrivacyEnabled is a const false right now, so amounts '
              'never hide and the toggle renders nothing. The hidden look is '
              'the symbol plus four bullets, drawn below as static text.',
          child: HubRow(
            cells: [
              const HubCell(
                caption: 'shown',
                child: MoneyText(1250.5, tone: MoneyTone.income),
              ),
              const HubCell(
                caption: 'hidden (static look)',
                child: AppText('฿••••', role: AppTextRole.money),
              ),
              const HubCell(
                caption: 'MoneyVisibilityToggle (empty while off)',
                child: MoneyVisibilityToggle(),
              ),
              const HubCell(
                caption: 'MoneyVisibilityToggle size 32',
                child: MoneyVisibilityToggle(size: 32),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'MoneyListTile — dimmed',
          note: 'dimmed: faded (archived / cancelled / settled rows).',
          child: Column(
            children: [
              MoneyListTile(
                leading: const AppIcon(AppIcons.cash),
                title: 'Salary',
                amount: 32000,
                onTap: () {},
              ),
              MoneyListTile(
                leading: const AppIcon(AppIcons.cash),
                title: 'Old subscription (cancelled)',
                amount: -199,
                dimmed: true,
                onTap: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DateGroupHeader + MoneyListTile',
          note:
              'A grouped list: date header with net total, income / expense '
              'rows, caption under the amount, footer line, a row with a '
              'warning, and a tappable row.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DateGroupHeader(label: 'Today', total: 4460),
              MoneyListTile(
                leading: IconTile(icon: AppIcons.cash, color: palette.income),
                title: 'Salary',
                subtitle: const Text('Main bank'),
                amount: 5000,
              ),
              MoneyListTile(
                leading: IconTile(
                  icon: AppIcons.expense,
                  color: palette.expense,
                ),
                title: 'Lunch',
                subtitle: const Text('Cash'),
                footer: const Text('#food  #work'),
                amount: -540,
                amountCaption: 'split 3',
                onTap: () {},
              ),
              const AppDivider.row(),
              const DateGroupHeader(label: 'Yesterday'),
              MoneyListTile(
                leading: IconTile(icon: AppIcons.debt, color: scheme.primary),
                title: 'Owed by Alex',
                subtitle: Row(
                  children: [
                    Icon(AppIcons.warning, color: palette.warning),
                    const SizedBox(width: AppSpacing.xs),
                    const Flexible(
                      child: Text(
                        'Overdue 5 days',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                amount: 300,
                amountCaption: 'owes you',
              ),
              MoneyListTile(
                leading: IconTile(
                  icon: AppIcons.transfer,
                  color: scheme.secondary,
                ),
                title: 'Transfer to savings',
                amount: 1000,
              ),
              MoneyListTile(
                leading: IconTile(
                  icon: AppIcons.expense,
                  color: palette.expense,
                ),
                title: 'Forced expense tone',
                amount: 120,
                tone: MoneyTone.expense,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'CurrencyTile',
          note:
              'A DetailRow picker that opens a popover of currencies. '
              'onChanged: null is the locked read-only look (after create).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CurrencyTile(
                value: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
              const AppDivider.row(),
              const CurrencyTile(value: 'THB', onChanged: null),
              const AppDivider.row(),
              CurrencyTile(
                value: 'EUR',
                label: 'Account currency',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
