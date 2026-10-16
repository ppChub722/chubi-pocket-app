import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/saving` — saving goals v2 pieces: MilestoneRow,
/// SavingHistoryChart, SavingTxRow (+ draft), SavingMoveSheet,
/// CloseGoalDialog and the 3-button action row under a goal's hero.
Widget buildDomainSavingPage(BuildContext context) => const _SavingPage();

class _SavingPage extends StatefulWidget {
  const _SavingPage();

  @override
  State<_SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<_SavingPage> {
  String _result = '—';

  static List<SavingSplitRow> _rows() => const [
    SavingSplitRow(
      walletId: 'kbank',
      name: 'KBank',
      availableText: 'Has ฿40,000',
      amount: 40000,
      leading: IconTile(icon: PpForgeIcons.wallet, color: Color(0xFF16A34A)),
    ),
    SavingSplitRow(
      walletId: 'scb',
      name: 'SCB',
      availableText: 'Has ฿12,000',
      amount: 5000,
      leading: IconTile(icon: PpForgeIcons.wallet, color: Color(0xFF7C3AED)),
    ),
  ];

  /// Largest-first over the two demo wallets.
  static List<SavingMoveSplit> _auto(double amount) {
    final a = amount.clamp(0, 40000).toDouble();
    final b = (amount - a).clamp(0, 12000).toDouble();
    return [(walletId: 'kbank', amount: a), (walletId: 'scb', amount: b)];
  }

  Future<void> _move({required bool withdraw}) async {
    final r = await showSavingMoveSheet(
      context,
      title: withdraw ? 'Withdraw savings' : 'Move savings',
      from: const SavingMoveEnd(
        caption: 'From',
        name: 'Japan trip',
        subtitle: '฿52,000',
      ),
      to: withdraw
          ? const SavingMoveEnd(
              caption: 'To',
              name: 'Wallets',
              subtitle: 'KBank, SCB',
            )
          : const SavingMoveEnd(
              caption: 'To',
              name: 'Car down payment',
              subtitle: '฿96,000',
            ),
      amount: 45000,
      splits: _rows(),
      amountLabel: 'Amount',
      splitTitle: 'Split by wallet (automatic)',
      editLabel: 'Edit',
      saveLabel: withdraw ? 'Withdraw' : 'Move',
      sumOkText: (s) => 'Total ${AmountInput.format(s)} ✓',
      sumOffText: (s, a) =>
          'Total ${AmountInput.format(s)} ≠ ${AmountInput.format(a)}',
      autoSplit: _auto,
    );
    if (mounted) {
      setState(
        () => _result = r == null
            ? 'Sheet resolved: null'
            : 'Sheet resolved: ${r.map((e) => '${e.walletId}=${e.amount}').join(', ')}',
      );
    }
  }

  Future<void> _close() async {
    final v = await showCloseGoalDialog(
      context,
      title: 'Close goal "Japan trip"',
      message: 'Savings ฿52,000 go where?',
      returnsTitle: 'If it goes back to the wallets',
      returns: const [
        (wallet: 'KBank', amount: 40000),
        (wallet: 'SCB', amount: 12000),
      ],
      toSpareLabel: 'Into unallocated',
      backToWalletsLabel: 'Back to the wallets',
      cancelLabel: 'Cancel',
    );
    if (mounted) setState(() => _result = 'Dialog resolved: $v');
  }

  @override
  Widget build(BuildContext context) {
    const months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const actual = <double>[10, 16, 22, 28, 34, 40];
    const projection = <double>[44, 48];
    Widget box(Widget child) => PpForgeCard(
      padding: const EdgeInsets.all(PpForgeSpacing.md),
      child: child,
    );
    final tint = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'MilestoneRow — 25 / 50 / 75 / 100 %',
          note:
              'n equal steps, each a glyph disc + caption: done = filled, '
              'next = ringed + bold caption, todo = grey. The caller works '
              'out the states and passes plain strings.',
          child: box(
            MilestoneRow(
              color: tint,
              steps: const [
                MilestoneStep(
                  label: '25%',
                  state: MilestoneState.done,
                  glyph: '✓',
                ),
                MilestoneStep(
                  label: '50%',
                  state: MilestoneState.done,
                  glyph: '✓',
                ),
                MilestoneStep(
                  label: '฿60,000',
                  state: MilestoneState.next,
                  glyph: '75',
                ),
                MilestoneStep(
                  label: '100%',
                  state: MilestoneState.todo,
                  glyph: '🏁',
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'SavingHistoryChart',
          note:
              'actual = cumulative per month (solid); projection = the real '
              'pace after the last actual month (dashed); needed line = dotted '
              'from now to the deadline at the target; target = dashed '
              'horizontal. Tone-aware (warning when behind). Drawn with a '
              'CustomPainter; empty series is safe; .skeleton while loading.',
          child: HubPlayground(
            title: 'SavingHistoryChart',
            controls: [
              PlayChoice<Tone>('tone', [
                for (final t in Tone.values) (t.name, t),
              ], initial: Tone.info),
              const PlayBool('showNeeded', initialValue: true),
              const PlayBool('projection', initialValue: true),
              const PlayBool('empty'),
            ],
            builder: (context, v) => box(
              SavingHistoryChart(
                actual: v<bool>('empty') ? const [] : actual,
                projection: v<bool>('projection') && !v<bool>('empty')
                    ? projection
                    : const [],
                target: 80,
                showNeeded: v<bool>('showNeeded'),
                monthLabels: months,
                targetLabel: 'Goal 80',
                tone: v<Tone>('tone'),
                caption: 'Saved so far (k ฿)',
                actualLegend: 'Saved / at pace',
                neededLegend: 'Needed pace',
              ),
            ),
          ),
        ),
        HubDemo(
          title: 'SavingHistoryChart.skeleton',
          child: box(const SavingHistoryChart.skeleton()),
        ),
        HubDemo(
          title: 'SavingTxRow — deposit · withdraw · allocate',
          note:
              'The saving-tx record (never a real tx): kind glyph · title · '
              'source chip · line 2 "wallet → bucket" or "bucket → wallet" · '
              'signed amount (accent + / muted −). Same row height as TxRow.',
          child: PpForgeCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SavingTxRow(
                  kind: SavingTxKind.deposit,
                  title: 'Saved to goal',
                  walletLabel: 'KBank',
                  to: 'Japan trip',
                  amount: 4000,
                ),
                SavingTxRow(
                  kind: SavingTxKind.deposit,
                  title: 'Recurring saving',
                  source: PpForgeChip(label: 'Recurring', size: ChipSize.mini),
                  walletLabel: 'KBank',
                  to: 'Japan trip',
                  amount: 4000,
                ),
                SavingTxRow(
                  kind: SavingTxKind.withdraw,
                  title: 'Withdraw · hotel deposit',
                  from: 'Japan trip',
                  walletLabel: 'SCB',
                  amount: 3000,
                ),
                SavingTxRow(
                  kind: SavingTxKind.allocate,
                  title: 'Allocate',
                  walletLabel: 'KBank',
                  from: 'Unallocated',
                  to: 'Japan trip',
                  amount: 6000,
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'SavingTxRow — draft (pending list) and dimmed',
          note:
              'draft: the 🐷 row of the pending list — wallet chip up after '
              'the title, line 2 = kind / source chips + the target, outlined '
              'glyph, slightly faded; same height. dimmed = archived.',
          child: PpForgeCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SavingTxRow(
                  kind: SavingTxKind.deposit,
                  draft: true,
                  title: 'Save for Japan trip',
                  walletLabel: 'KBank',
                  draftChips: [
                    PpForgeChip(label: 'Saving', size: ChipSize.mini),
                    PpForgeChip(label: 'Recurring', size: ChipSize.mini),
                  ],
                  to: 'Japan trip',
                  amount: 4000,
                ),
                SavingTxRow(
                  kind: SavingTxKind.deposit,
                  dimmed: true,
                  title: 'Saved to goal',
                  walletLabel: 'KBank',
                  to: 'Old goal',
                  amount: 1000,
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'Goal action row — ActionBar under the hero',
          note:
              'No new piece: ActionBar (2–4 equal buttons, first = primary) '
              'goes right under the goal hero, like the wallet page. Add '
              'savings / Withdraw / Move.',
          child: ActionBar(
            actions: [
              ActionBarItem(
                label: 'Add savings',
                icon: PpForgeIcons.savingDeposit,
                primary: true,
                onPressed: () {},
              ),
              ActionBarItem(
                label: 'Withdraw',
                icon: PpForgeIcons.savingWithdraw,
                onPressed: () {},
              ),
              ActionBarItem(
                label: 'Move',
                icon: PpForgeIcons.savingAllocate,
                onPressed: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showSavingMoveSheet · showCloseGoalDialog',
          note:
              'Move: from → to cards, amount, the caller\'s auto split per '
              'wallet (editable behind ✏️), a sum check, save disabled until '
              'the parts add up. Withdraw reuses it (the "to" card is the '
              'wallets). Close: where the money goes — unallocated or back '
              'to each wallet. Both resolve plain values / null.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: PpForgeSpacing.sm,
                runSpacing: PpForgeSpacing.sm,
                children: [
                  PpForgeButton(
                    label: 'Move sheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () => _move(withdraw: false),
                  ),
                  PpForgeButton(
                    label: 'Withdraw sheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () => _move(withdraw: true),
                  ),
                  PpForgeButton(
                    label: 'Close goal dialog',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: _close,
                  ),
                ],
              ),
              const SizedBox(height: PpForgeSpacing.sm),
              Text(_result, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
