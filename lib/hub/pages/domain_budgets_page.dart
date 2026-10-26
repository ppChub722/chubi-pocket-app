import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/domain/budgets` — the budget-only pieces: the source chips, the
/// scope prompt, the simple period editor (RecurrenceEditor `simple`), the
/// field error under a DetailRow, the wallet value chip and the card-list
/// gap of ListPageBody. The shared progress pieces are on Domain → Progress.
Widget buildBudgetsPage(BuildContext context) => const _BudgetsPage();

class _BudgetsPage extends StatefulWidget {
  const _BudgetsPage();

  @override
  State<_BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<_BudgetsPage> {
  String _picked = '—';
  String _limit = '—';
  RecurrenceRule _rule = RecurrenceRule(
    freq: RecurrenceFreq.monthly,
    start: DateTime(2026, 10, 1),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'SourceChip / SourceChips — what feeds the budget',
          note:
              'Mini soft pills: a kind of money (tone) or an entity (its own '
              'colour + icon). SourceChips folds the rest into "+n".',
          child: HubRow(
            cells: [
              const HubCell(
                caption: 'kinds',
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    SourceChip('ปกติ'),
                    SourceChip('อีเวนต์', tone: AppChipTone.info),
                    SourceChip('รายการประจำ', tone: AppChipTone.primary),
                    SourceChip('รอยืนยัน', tone: AppChipTone.warning),
                  ],
                ),
              ),
              HubCell(
                caption: 'entities, maxVisible 3',
                child: SizedBox(
                  width: 300,
                  child: SourceChips(
                    maxVisible: 3,
                    items: [
                      const SourceChipItem(
                        'อาหาร',
                        icon: Icons.restaurant,
                        color: Colors.orange,
                      ),
                      const SourceChipItem(
                        'เดินทาง',
                        icon: Icons.commute,
                        color: Colors.blue,
                      ),
                      const SourceChipItem('บัตร KTC', icon: Icons.credit_card),
                      const SourceChipItem('เที่ยว'),
                      const SourceChipItem('ของใช้'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showScopePrompt — "this and following / all / not yet"',
          note:
              'Like showLinkedPrompt: labels are params; resolves '
              'EditScope.following / EditScope.all, or null.',
          child: Row(
            children: [
              AppButton(
                label: 'Open prompt',
                variant: AppButtonVariant.outlined,
                onPressed: () async {
                  final r = await showScopePrompt(
                    context,
                    title: 'ใช้การตั้งค่าใหม่กับ',
                    cancelLabel: 'ยังก่อน',
                    followingLabel: 'รอบนี้และถัดไป',
                    allLabel: 'ทุกรอบ',
                  );
                  if (mounted) setState(() => _picked = '${r?.name}');
                },
              ),
              const SizedBox(width: AppSpacing.md),
              Text('→ $_picked'),
            ],
          ),
        ),
        HubDemo(
          title:
              'RecurrenceEditor(simple: true) / AppRecurrenceSheet.show(simple:)',
          note:
              'The budget period: "every N day | week | month | year" and the '
              'end. No weekday toggles, no monthly day / Nth weekday; the '
              'rule has weekdays empty and monthly null.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 340,
                child: RecurrenceEditor(
                  initial: _rule,
                  simple: true,
                  onChanged: (r) => _rule = r,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Open as sheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await AppRecurrenceSheet.show(
                        context,
                        initial: _rule,
                        simple: true,
                      );
                      if (r != null && mounted) setState(() => _rule = r);
                    },
                  ),
                  // A saving goal's รอบ: no end (the goal ends it), its own title.
                  AppButton(
                    label: 'Goal period (showEnd: false, title)',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await AppRecurrenceSheet.show(
                        context,
                        initial: _rule,
                        simple: true,
                        showEnd: false,
                        title: 'รอบ',
                      );
                      if (r != null && mounted) setState(() => _rule = r);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DetailRow(error:) / DetailRow.pick(error:)',
          note:
              'A field error under the label (required / server message), in '
              'the error colour — replaces a hand-made Column + AppMessage.',
          child: Column(
            children: [
              DetailRow.pick(
                label: 'หมวดหมู่',
                emptyText: 'ไม่ได้เลือก',
                error: 'เลือกอย่างน้อย 1 หมวด',
                onTap: () {},
              ),
              const AppDivider.row(),
              DetailRow.pick(
                label: 'กระเป๋า',
                emptyText: 'ไม่ได้เลือก',
                valueChip: walletValueChip(context, name: 'บัญชีออมทรัพย์'),
                onTap: () {},
              ),
              const AppDivider.row(),
              // Several entities: the chips wrap, right-aligned.
              DetailRow.pick(
                label: 'หมวดหมู่',
                emptyText: 'ไม่ได้เลือก',
                valueChips: const [
                  AppChip(label: 'อาหาร', selected: true),
                  AppChip(label: 'เดินทาง', selected: true),
                  AppChip(label: 'ของใช้ในบ้าน', selected: true),
                  AppChip(label: 'บันเทิง', selected: true),
                ],
                onTap: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showPeriodLimitSheet — one period\'s own limit',
          note:
              'Title = the budget, subtitle = which period (others stay), '
              'tiles งบปกติ / ใช้ไปแล้ว, the amount, "↺ ใช้งบปกติ" (while the '
              'period has its own amount) and a note. An amount equal to the '
              'base is the base; save is on once something changed. Resolves '
              'PeriodLimitResult (amount null = back to base, + which fields '
              'changed), or null.',
          child: Row(
            children: [
              AppButton(
                label: 'Open sheet',
                variant: AppButtonVariant.outlined,
                onPressed: () async {
                  final r = await showPeriodLimitSheet(
                    context,
                    title: 'เงินสดในกระเป๋า',
                    subtitle: 'แก้เฉพาะรอบ ต.ค. 2026 | รอบอื่นไม่เปลี่ยน',
                    baseCaption: 'งบปกติ',
                    baseValue: '฿2,500',
                    usedCaption: 'ใช้ไป',
                    usedValue: '฿1,550',
                    amountLabel: 'งบรอบนี้',
                    noteLabel: 'โน้ต',
                    noteHint: 'เช่น เดือนนี้มีงานแต่ง',
                    saveLabel: 'บันทึก',
                    symbol: '฿',
                    amount: 4000,
                    baseAmount: 2500,
                    overridden: true,
                    note: 'งานแต่ง',
                    resetLabel: '↺ ใช้งบปกติ (฿2,500)',
                  );
                  if (mounted) {
                    setState(
                      () => _limit = r == null
                          ? 'cancelled'
                          : '${r.amountChanged ? (r.amount ?? 'base') : '='} / '
                                '${r.noteChanged ? (r.note ?? '—') : '='}',
                    );
                  }
                },
              ),
              const SizedBox(width: AppSpacing.md),
              Text('→ $_limit'),
            ],
          ),
        ),
        HubDemo(
          title: 'walletValueChip — a wallet as a value chip',
          note:
              'Moved into the kit (ui/domain/money): `[icon] name` in the '
              'wallet\'s colour, for DetailRow.pick(valueChip:).',
          child: Align(
            alignment: Alignment.centerLeft,
            child: walletValueChip(
              context,
              name: 'บัตร KTC',
              iconCode: const IconCode(
                icon: 'credit_card',
                iconColors: ['#0284C7'],
              ),
            ),
          ),
        ),
        const HubDemo(
          title: 'ListPageBody(rowGap:)',
          note:
              'Card-list mode: rowGap > 0 puts that space between the '
              'children (cards, boxed rows) so a page needs no SizedBox; '
              'ignored with rowDividers. See Templates → List page.',
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}
