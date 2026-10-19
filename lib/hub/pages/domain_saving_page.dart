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
      leading: IconTile(icon: AppIcons.wallet, color: Color(0xFF16A34A)),
    ),
    SavingSplitRow(
      walletId: 'scb',
      name: 'SCB',
      availableText: 'Has ฿12,000',
      amount: 5000,
      leading: IconTile(icon: AppIcons.wallet, color: Color(0xFF7C3AED)),
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

  String? _pickedGoal;

  Future<void> _pickGoal() async {
    final purple = Theme.of(context).colorScheme.tertiary;
    final r = await showSavingGoalPickerSheet(
      context,
      title: 'Pick a goal',
      selectedId: _pickedGoal,
      items: [
        SavingGoalPick(
          id: null,
          name: 'Unallocated',
          icon: AppIcons.quickSaving,
          color: purple,
          amountText: '฿8,500',
          caption: 'Kept aside, in no goal yet',
        ),
        const SavingGoalPick(
          id: 'japan',
          name: 'Japan trip',
          icon: Icons.flight_outlined,
          color: Color(0xFF38BDF8),
          amountText: '฿52,000',
          targetText: '฿80,000',
          progress: 0.65,
          caption: '฿2,500 short this month',
        ),
        const SavingGoalPick(
          id: 'wedding',
          name: 'Wedding',
          icon: Icons.favorite_outline,
          color: Color(0xFFF472B6),
          amountText: '฿60,000',
          targetText: '฿200,000',
          progress: 0.3,
          caption: '2 months behind',
        ),
      ],
    );
    if (mounted && r != null) {
      setState(() {
        _pickedGoal = r.id;
        _result = 'Goal picker resolved: ${r.id ?? 'unallocated'}';
      });
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
    Widget box(Widget child) =>
        AppCard(padding: const EdgeInsets.all(AppSpacing.md), child: child);
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
          title: 'ChartSection — a headed detail box around one chart',
          note:
              'The goal page\'s "ยอดสะสม" box: green title + description over '
              'the rounded box, the chart inset inside. Shown only with two or '
              'more entries.',
          child: ChartSection(
            first: true,
            title: 'Cumulative savings',
            description: 'What is saved, month by month',
            chart: SavingHistoryChart(
              actual: actual,
              target: 80,
              showNeeded: false,
              monthLabels: months,
              targetLabel: 'Goal 80',
              tone: Tone.info,
              actualLegend: 'Saved',
            ),
          ),
        ),
        HubDemo(
          title: 'SavingHistoryChart.skeleton',
          child: box(const SavingHistoryChart.skeleton()),
        ),
        HubDemo(
          title: 'SavingTxRow — deposit | withdraw | allocate',
          note:
              'The saving-tx record (never a real tx): kind glyph | title | '
              'source chip | line 2 "wallet → bucket" or "bucket → wallet" | '
              'signed amount (accent + / muted −). Same row height as TxRow.',
          child: AppCard(
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
                  source: AppChip(label: 'Recurring', size: ChipSize.mini),
                  walletLabel: 'KBank',
                  to: 'Japan trip',
                  amount: 4000,
                ),
                SavingTxRow(
                  kind: SavingTxKind.withdraw,
                  title: 'Withdraw | hotel deposit',
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
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SavingTxRow(
                  kind: SavingTxKind.deposit,
                  draft: true,
                  title: 'Save for Japan trip',
                  walletLabel: 'KBank',
                  draftChips: [
                    AppChip(label: 'Saving', size: ChipSize.mini),
                    AppChip(label: 'Recurring', size: ChipSize.mini),
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
          title: 'SavingGoalRow — behind | on track | reached | archived',
          note:
              'A goals-list row (reference §2): icon | name | "ขาด ฿x" / ✓ | '
              'thick bar in the goal colour | "saved / target" | ETA badge '
              '(amber when behind, green on track / reached). No buttons; tap '
              'opens the goal. Every word is a param.',
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SavingGoalRow(
                  title: 'Wedding',
                  value: 0.3,
                  amountText: '฿60,000 / ฿200,000',
                  trailing: 'Short ฿2,500',
                  trailingTone: Tone.warning,
                  badge: 'Goal Aug 2029 | 2 months late',
                  badgeTone: Tone.warning,
                  onTap: () {},
                ),
                SavingGoalRow(
                  title: 'Japan trip',
                  value: 0.65,
                  amountText: '฿52,000 / ฿80,000',
                  trailing: '✓',
                  trailingTone: Tone.success,
                  badge: 'Goal Mar 2027',
                  onTap: () {},
                ),
                const SavingGoalRow(
                  title: 'Old goal',
                  value: 1,
                  amountText: '฿10,000 / ฿10,000',
                  badge: 'Archived',
                  badgeTone: Tone.neutral,
                  dimmed: true,
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'showSavingAutoSaveSheet',
          note:
              'The auto-saving sheet: amount | day of the month | the wallet '
              '(the app owns the wallet picker — "no wallet" is a valid '
              'source). Save is disabled until the amount is above zero. '
              'Resolves (amount, day, accountId) or null.',
          child: AppButton(
            label: 'Auto-saving sheet',
            variant: AppButtonVariant.outlined,
            onPressed: () async {
              final r = await showSavingAutoSaveSheet(
                context,
                title: 'Auto-saving',
                amountLabel: 'Amount',
                dayLabel: 'Day of the month',
                walletLabel: 'Take from',
                saveLabel: 'Save',
                amount: 5500,
                day: 25,
                wallet: const SavingAutoSaveWallet(label: 'No wallet'),
                onPickWallet: () async =>
                    const SavingAutoSaveWallet(id: 'kbank', label: 'KBank'),
              );
              if (mounted) {
                setState(
                  () => _result = r == null
                      ? 'Auto-saving sheet resolved: null'
                      : 'Auto-saving: ${r.amount} on day ${r.day} from ${r.accountId}',
                );
              }
            },
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
                icon: AppIcons.savingDeposit,
                primary: true,
                onPressed: () {},
              ),
              ActionBarItem(
                label: 'Withdraw',
                icon: AppIcons.savingWithdraw,
                onPressed: () {},
              ),
              ActionBarItem(
                label: 'Move',
                icon: AppIcons.savingAllocate,
                onPressed: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showSavingMoveSheet | showCloseGoalDialog',
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
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Move sheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _move(withdraw: false),
                  ),
                  AppButton(
                    label: 'Withdraw sheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _move(withdraw: true),
                  ),
                  AppButton(
                    label: 'Goal picker (cards)',
                    variant: AppButtonVariant.outlined,
                    onPressed: _pickGoal,
                  ),
                  AppButton(
                    label: 'Close goal dialog',
                    variant: AppButtonVariant.outlined,
                    onPressed: _close,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_result, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
