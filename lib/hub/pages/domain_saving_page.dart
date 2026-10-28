import 'package:flutter/material.dart';

import '../../features/saving_goals/domain/saving_goal.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/saving` — saving goals v2 pieces: MilestoneRow,
/// SavingHistoryChart, SavingMoveSheet (history rows: Molecules › Row),
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

  String? _pickedGoal = 'japan';

  List<SavingGoalPick> _goals() => [
    SavingGoalPick(
      id: null,
      name: 'Unallocated',
      icon: AppIcons.quickSaving,
      color: Theme.of(context).colorScheme.tertiary,
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
  ];

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
          title: 'SavingGoalPickCard — where a saving goes',
          note:
              'The "to" tile beside a WalletPickCard (FlowCards): a goal = its '
              'icon, name and saved / target; ยังไม่จัดสรร = a real choice, '
              'drawn as picked with what it holds; nothing yet = dashed "+ '
              'เลือกเป้าหมาย" (a new ออมเงิน recurring). Used by the saving '
              'form and the ออมเงิน recurring page.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (goal, spare) in [
                (
                  const SavingGoal(
                    id: 'g1',
                    name: 'MacBook',
                    currency: 'THB',
                    targetAmount: 55000,
                    savedAmount: 17000,
                  ),
                  false,
                ),
                (null, true),
                (null, false),
              ])
                SizedBox(
                  width: 180,
                  child: SavingGoalPickCard(
                    goal: goal,
                    spare: spare,
                    spareAmount: 2400,
                    label: 'Saving goal',
                    placeholder: 'Pick a goal',
                    spareLabel: 'Unallocated',
                    dense: true,
                    editable: true,
                    onTap: () {},
                  ),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'Saving goal row — AppListRow + ProgressRow.fillLabel',
          note:
              'The goals list: name + "ช้ากว่าแผน" | "ภายใน <deadline>" | '
              'saved (or "ครบแล้ว ✓") over "เป้า <target>" | bar with the % on '
              'the fill\'s end. A goal without a target has no bar.',
          child: Builder(
            builder: (context) {
              final palette = Theme.of(context).extension<AppColors>()!;
              Widget icon(IconData i) => IconCodeWidget(
                iconCode: null,
                size: 36,
                displayMode: IconDisplayMode.compact,
                fallbackIcon: i,
                fallbackColor: palette.info,
              );
              return SectionCard(
                first: true,
                children: [
                  AppListRow(
                    leading: icon(AppIcons.savingGoal),
                    title: 'ซื้อ MacBook',
                    status: const ListRowChip('ช้ากว่าแผน', tone: Tone.warning),
                    line2: const ListRowLine(parts: ['ภายใน 31 ธ.ค. 2026']),
                    trailing: const ListRowTrailing.value(
                      Text('฿17,000'),
                      caption: 'เป้า ฿55,000',
                    ),
                    footer: ProgressRow(
                      value: 0.31,
                      color: palette.warning,
                      fillLabel: '31%',
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: icon(AppIcons.savingGoal),
                    title: 'ของขวัญวันเกิดแม่',
                    line2: const ListRowLine(parts: ['ภายใน 15 พ.ย. 2026']),
                    trailing: const ListRowTrailing.text(
                      'ครบแล้ว ✓',
                      tone: Tone.success,
                      caption: 'เป้า ฿3,000',
                    ),
                    footer: ProgressRow(
                      value: 1,
                      color: palette.info,
                      fillLabel: '100%',
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: icon(AppIcons.savingGoal),
                    title: 'เงินสำรองฉุกเฉิน',
                    line2: const ListRowLine(parts: ['ออมต่อเนื่อง']),
                    trailing: const ListRowTrailing.value(
                      Text('฿12,000'),
                      caption: 'เดือนนี้ +฿1,000',
                    ),
                    onTap: () {},
                  ),
                ],
              );
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
        HubDemo(
          title: 'SavingGoalCard',
          note:
              'One goal as a card (the goal picker\'s card layout): name, '
              'amount / target, progress and a caption. Picked = tinted with '
              'a solid border, else a dashed one. Tap to pick.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final g in _goals())
                SizedBox(
                  width: 180,
                  child: SavingGoalCard(
                    pick: g,
                    selected: g.id == _pickedGoal,
                    onTap: () => setState(() => _pickedGoal = g.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
