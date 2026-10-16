import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// Events (projects) pieces: EventCard (+ EventTagRef), EventBillRow,
/// EventBillChildRow, PositionRow.
Widget buildEventsPage(BuildContext context) => const _EventsPage();

// Sample data (Thai, as the app shows it). Colours are theme tokens.
const _trip = IconCode(icon: 'flight', bgColors: ['@presetThemeColor1']);
const _party = IconCode(icon: 'nightlife', bgColors: ['@presetThemeColor2']);
const _work = IconCode(icon: 'work', bgColors: ['@presetThemeColor3']);
const _food = EventTagRef(
  'อาหาร',
  iconCode: IconCode(icon: 'restaurant', iconColors: ['@presetThemeColor2']),
);
const _stay = EventTagRef(
  'ที่พัก',
  iconCode: IconCode(icon: 'home', iconColors: ['@presetThemeColor3']),
);
const _travel = EventTagRef('เดินทาง');

class _EventsPage extends StatefulWidget {
  const _EventsPage();

  @override
  State<_EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<_EventsPage> {
  bool _billMarked = false;
  bool _childAMarked = true;
  bool _childBMarked = false;
  String? _lastTap;

  void _tapped(String what) => setState(() => _lastTap = what);

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'EventCard — the events list row',
          note:
              'Icon (IconDisplay, project fallback), name, status as a mini '
              'chip, optional description, my tags as mini chips, a meta '
              'caption with my signed net on the right, and the plan bar when '
              'the event has a plan. Hairline-separated rows, not boxes. '
              'dimmed = locked / archived (faded, still opens).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventCard(
                name: 'ทริปเชียงใหม่',
                iconCode: _trip,
                statusLabel: 'กำลังดำเนินการ',
                statusTone: PpForgeChipTone.success,
                meta: '4 คน · 1–5 ต.ค.',
                myNet: 1250,
                tags: const [_travel, _stay],
                onTap: () => _tapped('card: active'),
              ),
              const PpForgeDivider.row(),
              EventCard(
                name: 'ปาร์ตี้ปีใหม่',
                iconCode: _party,
                description: 'หารค่าอาหาร เครื่องดื่ม และสถานที่',
                statusLabel: 'วางแผน',
                statusTone: PpForgeChipTone.info,
                meta: '8 คน · 31 ธ.ค.',
                progress: 0.62,
                progressLabel: 'ใช้ไป ฿6,200 จาก ฿10,000',
                progressTrailing: '62%',
                myNet: 0,
                onTap: () => _tapped('card: planned'),
              ),
              const PpForgeDivider.row(),
              EventCard(
                name: 'งานสัมมนา',
                iconCode: _work,
                statusLabel: 'เกินงบ',
                statusTone: PpForgeChipTone.danger,
                meta: '3 คน · 12–13 ก.ย.',
                progress: 1.18,
                progressLabel: 'ใช้ไป ฿11,800 จาก ฿10,000',
                progressTrailing: '118%',
                myNet: -420.5,
                tags: const [_food],
                onTap: () => _tapped('card: negative net, over plan'),
              ),
              const PpForgeDivider.row(),
              EventCard(
                name: 'ทริปภูเก็ต (ปิดแล้ว)',
                statusLabel: 'ปิดแล้ว',
                meta: '5 คน · 2–4 ส.ค.',
                myNet: 300,
                dimmed: true,
                onTap: () => _tapped('card: locked'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'EventBillRow — a board bill',
          note:
              'TxRow geometry. Leading square tick = the resolve STATE '
              '(SelectCheck look, not a selection); a marked row fades. '
              'Event tags ride on line 1 as mini chips, each its own tap '
              '(onTagTap gets the chip context, or tagAnchorBuilder wraps it '
              'in a popover anchor). Line 2 = payer mark + name · date · '
              'summary, 🔗 when linked to my book. locked = inert + faded.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventBillRow(
                title: 'ค่าที่พัก',
                amount: -3600,
                marked: _billMarked,
                onTickTap: () => setState(() => _billMarked = !_billMarked),
                payerName: 'มาตาก',
                payerLevel: PersonLevel.linked,
                caption: 'วันนี้',
                summary: 'หาร 4',
                tags: const [_stay],
                tagAnchorBuilder: (context, i, chip) => OptionMenuAnchor<int>(
                  options: const [
                    SheetOption(value: 0, label: 'Only this tag'),
                    SheetOption(value: 1, label: 'Edit tag'),
                  ],
                  onSelected: (v) => _tapped('tag popover → $v'),
                  builder: (context, toggle) => chip(toggle),
                ),
                onTap: () => _tapped('bill: unresolved (tap tick)'),
              ),
              const PpForgeDivider.row(),
              EventBillRow(
                title: 'ข้าวเย็น',
                amount: -1280,
                marked: true,
                onTickTap: () => _tapped('bill: resolved tick'),
                payerName: 'ฉัน',
                payerLevel: PersonLevel.contact,
                caption: 'เมื่อวาน',
                linked: true,
                tags: const [_food, _travel],
                onTagTap: (_, i) => _tapped('tag $i tapped'),
                onTap: () => _tapped('bill: resolved'),
              ),
              const PpForgeDivider.row(),
              EventBillRow(
                title: 'ค่ารถตู้',
                amount: -2400,
                onTickTap: () => _tapped('never fires'),
                payerName: 'บีม',
                caption: '3 ต.ค.',
                tags: const [_travel],
                onTagTap: (_, _) => _tapped('never fires'),
                locked: true,
                onTap: () => _tapped('never fires'),
              ),
              const PpForgeDivider.row(),
              EventBillRow(
                title: 'เงินคืนจากโรงแรม',
                amount: 500,
                leading: IconTile(
                  icon: PpForgeIcons.income,
                  color: palette.income,
                ),
                payerName: 'มาตาก',
                payerLevel: PersonLevel.linked,
                caption: '4 ต.ค.',
                onTickTap: () => _tapped('income tick'),
                onTap: () => _tapped('bill: income with type glyph'),
              ),
            ],
          ),
        ),
        const HubDemo(
          title: 'EventBillRow(highlighted) — the bill a link opened',
          note:
              'Tx detail "อยู่ในอีเวนต์ ›" opens the board on this bill '
              '(/projects/<id>?bill=<id>): it scrolls into view and flashes a '
              'primary tint that fades (nothing under reduced motion).',
          child: _HighlightDemo(),
        ),
        HubDemo(
          title: 'EventBillRow + EventBillChildRow — splits',
          note:
              'children: the split lines, indented, each with its own tick '
              '(fades when marked) and a muted caption after the name.',
          child: EventBillRow(
            title: 'ค่าตั๋วเครื่องบิน',
            amount: -7200,
            payerName: 'ฉัน',
            payerLevel: PersonLevel.contact,
            caption: '1 ต.ค.',
            summary: 'หาร 3',
            tags: const [_travel],
            onTickTap: () => _tapped('parent tick'),
            onTap: () => _tapped('bill with children'),
            children: [
              EventBillChildRow(
                name: 'มาตาก',
                level: PersonLevel.linked,
                caption: 'จ่ายแล้ว',
                amount: 2400,
                marked: _childAMarked,
                onTickTap: () => setState(() => _childAMarked = !_childAMarked),
              ),
              EventBillChildRow(
                name: 'บีม',
                level: PersonLevel.contact,
                caption: 'ติด ฿2,400',
                amount: 2400,
                marked: _childBMarked,
                onTickTap: () => setState(() => _childBMarked = !_childBMarked),
              ),
              EventBillChildRow(
                name: 'ต้น',
                caption: 'ติด ฿2,400 (locked)',
                amount: 2400,
                locked: true,
                onTickTap: () => _tapped('never fires'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PositionRow — rankings and positions',
          note:
              'Leading mark, label, amount right and a thin share bar under '
              'them (replaces the summary tab\'s private bar row). tone '
              'signed for net positions: + = they\'re owed.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PositionRow(
                leading: PersonMark(
                  name: 'มาตาก',
                  level: PersonLevel.linked,
                  size: 28,
                ),
                label: 'มาตาก — owed',
                amount: 1250,
                tone: MoneyTone.signed,
                share: 0.55,
              ),
              const PositionRow(
                leading: PersonMark(
                  name: 'บีม',
                  level: PersonLevel.contact,
                  size: 28,
                  reserveLinkSlot: true,
                ),
                label: 'บีม — owes',
                amount: -830,
                tone: MoneyTone.signed,
                share: 0.3,
              ),
              const PositionRow(
                leading: PersonMark(
                  name: 'ต้น',
                  level: PersonLevel.name,
                  size: 28,
                  reserveLinkSlot: true,
                ),
                label: 'ต้น — settled',
                amount: 0,
                tone: MoneyTone.signed,
                share: 0.15,
              ),
              PositionRow(
                leading: IconTile(
                  icon: PpForgeIcons.tag,
                  color: palette.expense,
                  size: 28,
                ),
                label: 'อาหาร (top tag)',
                amount: 4200,
                share: 0.42,
                color: palette.expense,
                onTap: () => _tapped('position: tag'),
              ),
            ],
          ),
        ),
        HubPlayground(
          title: 'EventCard',
          note: 'Every option EventCard has.',
          controls: [
            const PlayText('name', initialValue: 'ทริปเชียงใหม่'),
            const PlayText('description', initialValue: ''),
            const PlayText('statusLabel', initialValue: 'กำลังดำเนินการ'),
            PlayChoice<PpForgeChipTone>('statusTone', [
              for (final t in PpForgeChipTone.values) (t.name, t),
            ], initial: PpForgeChipTone.success),
            const PlayBool('statusDot', initialValue: true),
            const PlayText('meta', initialValue: '4 คน · 1–5 ต.ค.'),
            const PlayNum('tags', min: 0, max: 3, initialValue: 1),
            const PlayBool('icon', initialValue: true),
            const PlayNum(
              'progress %',
              min: -1,
              max: 150,
              step: 10,
              initialValue: -1,
            ),
            const PlayNum(
              'myNet',
              min: -2000,
              max: 2000,
              step: 250,
              initialValue: 500,
            ),
            const PlayBool('show myNet', initialValue: true),
            const PlayBool('dimmed'),
          ],
          builder: (context, v) {
            final pct = v<double>('progress %');
            final desc = v<String>('description');
            final status = v<String>('statusLabel');
            return EventCard(
              name: v<String>('name'),
              iconCode: v<bool>('icon') ? _trip : null,
              description: desc.isEmpty ? null : desc,
              statusLabel: status.isEmpty ? null : status,
              statusTone: v<PpForgeChipTone>('statusTone'),
              statusDot: v<bool>('statusDot'),
              meta: v<String>('meta'),
              tags: const [
                _travel,
                _stay,
                _food,
              ].take(v<double>('tags').round()).toList(),
              progress: pct < 0 ? null : pct / 100,
              progressLabel: pct < 0 ? null : 'ใช้ไป ${pct.round()}% ของแผน',
              progressTrailing: pct < 0 ? null : '${pct.round()}%',
              myNet: v<bool>('show myNet') ? v<double>('myNet') : null,
              dimmed: v<bool>('dimmed'),
              onTap: () {},
            );
          },
        ),
        HubPlayground(
          title: 'EventBillRow',
          note: 'Every option EventBillRow has (children: see the demo above).',
          controls: [
            const PlayText('title', initialValue: 'ค่าที่พัก'),
            const PlayNum(
              'amount',
              min: -5000,
              max: 5000,
              step: 250,
              initialValue: -3600,
            ),
            PlayChoice<MoneyTone>('tone', [
              for (final t in MoneyTone.values) (t.name, t),
            ], initial: MoneyTone.signed),
            const PlayBool('marked'),
            const PlayBool('tick tappable', initialValue: true),
            const PlayBool('type glyph'),
            const PlayNum('tags', min: 0, max: 3, initialValue: 1),
            const PlayText('payerName', initialValue: 'มาตาก'),
            PlayChoice<PersonLevel>('payerLevel', [
              for (final l in PersonLevel.values) (l.name, l),
            ], initial: PersonLevel.linked),
            const PlayText('caption', initialValue: 'วันนี้'),
            const PlayText('summary', initialValue: 'หาร 4'),
            const PlayBool('linked'),
            const PlayBool('locked'),
          ],
          builder: (context, v) {
            final summary = v<String>('summary');
            return EventBillRow(
              title: v<String>('title'),
              amount: v<double>('amount'),
              tone: v<MoneyTone>('tone'),
              marked: v<bool>('marked'),
              onTickTap: v<bool>('tick tappable') ? () {} : null,
              leading: v<bool>('type glyph')
                  ? IconTile(icon: PpForgeIcons.expense, color: palette.expense)
                  : null,
              tags: const [
                _stay,
                _food,
                _travel,
              ].take(v<double>('tags').round()).toList(),
              onTagTap: (_, _) {},
              payerName: v<String>('payerName'),
              payerLevel: v<PersonLevel>('payerLevel'),
              caption: v<String>('caption'),
              summary: summary.isEmpty ? null : summary,
              linked: v<bool>('linked'),
              locked: v<bool>('locked'),
              onTap: () {},
            );
          },
        ),
        Text(
          'Last tap: ${_lastTap ?? '—'}',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HighlightDemo extends StatefulWidget {
  const _HighlightDemo();

  @override
  State<_HighlightDemo> createState() => _HighlightDemoState();
}

class _HighlightDemoState extends State<_HighlightDemo> {
  bool _on = false;

  Future<void> _play() async {
    setState(() => _on = false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (mounted) setState(() => _on = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventBillRow(
          title: 'ค่าที่พัก',
          amount: -3200,
          payerName: 'บี',
          caption: '12 ต.ค.',
          linked: true,
          highlighted: _on,
          onTap: () {},
        ),
        const SizedBox(height: PpForgeSpacing.sm),
        PpForgeButton(
          label: 'Play the highlight',
          variant: PpForgeButtonVariant.tonal,
          onPressed: _play,
        ),
      ],
    );
  }
}
