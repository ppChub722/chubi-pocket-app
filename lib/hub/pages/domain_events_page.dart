import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'package:pp_forge_core/hub.dart';

/// Events (projects) pieces: EventListRow, EventTagRef, EventBillRow,
/// EventBillChildRow, SettleRow.
Widget buildEventsPage(BuildContext context) => const _EventsPage();

// Sample data (Thai, as the app shows it). Colours are theme tokens.
const _trip = PpForgeIconCode(icon: 'flight', bgColors: ['@presetThemeColor1']);
const _party = PpForgeIconCode(
  icon: 'nightlife',
  bgColors: ['@presetThemeColor2'],
);
const _work = PpForgeIconCode(icon: 'work', bgColors: ['@presetThemeColor3']);
const _food = EventTagRef(
  'อาหาร',
  iconCode: PpForgeIconCode(
    icon: 'restaurant',
    iconColors: ['@presetThemeColor2'],
  ),
);
const _stay = EventTagRef(
  'ที่พัก',
  iconCode: PpForgeIconCode(icon: 'home', iconColors: ['@presetThemeColor3']),
);
const _travel = EventTagRef('เดินทาง');

String _deleteTitle(String name) => 'ลบแท็ก $name?';

class _EventsPage extends StatefulWidget {
  const _EventsPage();

  @override
  State<_EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<_EventsPage> {
  bool _billMarked = false;
  bool _childAMarked = true;
  bool _childBMarked = false;
  bool _bookDebt = true;
  bool _bookTx = false;
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
          title: 'EventListRow — the 0.4.0 events list row',
          note:
              'Built on PpForgeListRow. Icon, name + a mini 👥 N chip (members) + '
              'an optional status chip (เกินงบ), meta on line 2 (dates | my '
              'share) and my '
              'position at the right: ได้คืน (green, +) / ต้องจ่าย (red, −); '
              'settled shows my share with เคลียร์แล้ว. footer = a full-width '
              'budget bar (ProgressRow). dimmed = ended and settled. The list '
              'page puts these in a SectionCard per status.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventListRow(
                name: 'ทริปญี่ปุ่น',
                iconCode: _trip,
                members: 4,
                meta: const ['1–9 พ.ย.', 'ส่วนฉัน ฿10,700'],
                amount: 8250,
                tone: MoneyTone.income,
                caption: 'ได้คืน',
                footer: const ProgressRow(
                  value: 0.86,
                  height: 6,
                  label: 'ใช้ไป ฿42,800 จากงบ ฿50,000',
                  trailing: 'เหลือ ฿7,200',
                ),
                onTap: () => _tapped('row: owed'),
              ),
              const PpForgeDivider.row(),
              EventListRow(
                name: 'งานสัมมนา',
                iconCode: _work,
                members: 6,
                status: const ListRowChip('เกินงบ', tone: Tone.danger),
                meta: const ['12–13 ก.ย.', 'ส่วนฉัน ฿3,000'],
                amount: 420,
                tone: MoneyTone.expense,
                caption: 'ต้องจ่าย',
                footer: const ProgressRow(
                  value: 1.18,
                  height: 6,
                  label: 'ใช้ไป ฿11,800 จากงบ ฿10,000',
                  trailing: 'เกินงบ ฿1,800',
                ),
                onTap: () => _tapped('row: owe'),
              ),
              const PpForgeDivider.row(),
              EventListRow(
                name: 'ปาร์ตี้ปีใหม่',
                iconCode: _party,
                members: 3,
                meta: const ['10 ต.ค.'],
                amount: 3589,
                caption: 'เคลียร์แล้ว',
                onTap: () => _tapped('row: even'),
              ),
              const PpForgeDivider.row(),
              const EventListRow(
                name: 'ทริปภูเก็ต',
                members: 3,
                meta: ['2–4 ส.ค.'],
                amount: 3000,
                caption: 'เคลียร์แล้ว',
                dimmed: true,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'EventTagsSheet — จัดการแท็กอีเวนต์',
          note:
              'Presentational: every write is a callback (here: a log line). '
              'Rows with a ⋯ menu (rename | icon / colour | import to my tags '
              '| delete), "+ add", "import all". The name / icon / delete '
              'steps open from the sheet.',
          child: PpForgeButton(
            label: 'เปิดชีต',
            variant: PpForgeButtonVariant.tonal,
            onPressed: () => showPpForgeSheetCustom<void>(
              context,
              builder: (_) => EventTagsSheet(
                tags: const [
                  EventTagItem(
                    id: 't1',
                    name: 'อาหาร',
                    subtitle: '5 บิล | มีในแท็กของฉันแล้ว',
                    canImport: false,
                  ),
                  EventTagItem(id: 't2', name: 'ที่พัก', subtitle: '2 บิล'),
                  EventTagItem(id: 't3', name: 'เดินทาง', subtitle: '0 บิล'),
                ],
                labels: const EventTagsLabels(
                  title: 'แท็กอีเวนต์ | ใช้ร่วมกับสมาชิก',
                  add: 'เพิ่มแท็กอีเวนต์',
                  importAll: 'นำเข้าทั้งหมดไปแท็กของฉัน',
                  rename: 'เปลี่ยนชื่อ',
                  restyle: 'เปลี่ยนไอคอน/สี',
                  importOne: 'นำเข้าแท็กของฉัน',
                  delete: 'ลบ',
                  nameLabel: 'ชื่อแท็ก',
                  addTitle: 'แท็กอีเวนต์ใหม่',
                  renameTitle: 'เปลี่ยนชื่อแท็ก',
                  save: 'บันทึก',
                  restyleTitle: 'ไอคอนแท็ก',
                  deleteTitle: _deleteTitle,
                  deleteBody: 'บิลที่ใช้อยู่จะหลุดแท็กนี้',
                  deleteConfirm: 'ลบ',
                  empty: 'ยังไม่มีแท็กอีเวนต์',
                ),
                onAdd: (n) => _tapped('tags: add $n'),
                onRename: (id, n) => _tapped('tags: rename $id → $n'),
                onRestyle: (id, _) => _tapped('tags: restyle $id'),
                onImport: (id) => _tapped('tags: import $id'),
                onDelete: (id) => _tapped('tags: delete $id'),
                onImportAll: () => _tapped('tags: import all'),
              ),
            ),
          ),
        ),
        HubDemo(
          title: 'EventBillRow — a board bill',
          note:
              'PpForgeListRow geometry. Leading square tick = the resolve STATE '
              '(SelectCheck look, not a selection); a marked row fades. '
              'Event tags ride on line 1 as mini chips, each its own tap '
              '(onTagTap gets the chip context, or tagAnchorBuilder wraps it '
              'in a popover anchor). Line 2 = payer mark + name | date | '
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
                payerAvatar: AvatarData.forName('มาตาก'),
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
                payerAvatar: AvatarData.forName('ฉัน'),
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
                payerAvatar: AvatarData.forName('บีม'),
              ),
              const PpForgeDivider.row(),
              EventBillRow(
                title: 'เงินคืนจากโรงแรม',
                amount: 500,
                leading: IconTile(icon: AppIcons.income, color: palette.income),
                payerName: 'มาตาก',
                payerLevel: PersonLevel.linked,
                caption: '4 ต.ค.',
                onTickTap: () => _tapped('income tick'),
                onTap: () => _tapped('bill: income with type glyph'),
                payerAvatar: AvatarData.forName('มาตาก'),
              ),
              const PpForgeDivider.row(),
              // 0.4.1-2 multi-payer: 2+ payers → "จ่าย: A ฿700 | B ฿500".
              EventBillRow(
                title: 'ค่าเรือ',
                amount: -1200,
                tick: false,
                payerName: 'ลี',
                payerVerb: 'จ่าย',
                payers: [
                  EventBillPayer(
                    name: 'ลี',
                    amount: '฿700',
                    level: PersonLevel.linked,
                    avatar: AvatarData.forName('ลี'),
                  ),
                  EventBillPayer(
                    name: 'ปอนด์',
                    amount: '฿500',
                    avatar: AvatarData.forName('ปอนด์'),
                  ),
                ],
                tags: const [_travel],
                onTap: () => _tapped('bill: two payers'),
                payerAvatar: AvatarData.forName('ลี'),
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
            payerAvatar: AvatarData.forName('ฉัน'),
            children: [
              EventBillChildRow(
                name: 'มาตาก',
                level: PersonLevel.linked,
                caption: 'จ่ายแล้ว',
                amount: 2400,
                marked: _childAMarked,
                onTickTap: () => setState(() => _childAMarked = !_childAMarked),
                avatar: AvatarData.forName('มาตาก'),
              ),
              EventBillChildRow(
                name: 'บีม',
                level: PersonLevel.contact,
                caption: 'ติด ฿2,400',
                amount: 2400,
                marked: _childBMarked,
                onTickTap: () => setState(() => _childBMarked = !_childBMarked),
                avatar: AvatarData.forName('บีม'),
              ),
              EventBillChildRow(
                name: 'ต้น',
                caption: 'ติด ฿2,400 (locked)',
                amount: 2400,
                locked: true,
                onTickTap: () => _tapped('never fires'),
                avatar: AvatarData.forName('ต้น'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'EventBillRow(tick: false) — the event book',
          note:
              'The event book: no tick boxes. payerVerb makes line 2 '
              '"**ฝน** จ่าย". My part not fully in my books: mine (a tint that '
              'stays) + onAction ⤓ (on my split left of the amount; on the '
              'payer line at its end when I paid); badge = ✓ chips for what is '
              'booked. A payback is a row of its own: leading ⇄, "from → to", '
              'amountColor = the planning colour.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventBillRow(
                tick: false,
                title: 'กาแฟดอยช้าง',
                amount: -640,
                payerName: 'ฝน',
                payerVerb: 'จ่าย',
                onTap: () => _tapped('book bill'),
                payerAvatar: AvatarData.forName('ฝน'),
                children: [
                  EventBillChildRow(
                    tick: false,
                    name: 'ฉัน',
                    amount: 160,
                    mine: true,
                    onAction: () => _tapped('ลงบัญชี'),
                    actionTooltip: 'ลงบัญชี',
                    badge: const EventBookedChips(labels: ['ลงรายการ']),
                    onTap: () => _tapped('my part'),
                    avatar: AvatarData.forName('ฉัน'),
                  ),
                  EventBillChildRow(
                    tick: false,
                    name: 'ต้น',
                    amount: 160,
                    onTap: () => _tapped('their part'),
                    avatar: AvatarData.forName('ต้น'),
                  ),
                ],
              ),
              const PpForgeDivider.row(),
              EventBillRow(
                tick: false,
                leading: IconTile(
                  icon: AppIcons.transfer,
                  color: ModuleColors.of(context).planning,
                  size: 28,
                ),
                title: 'ต้น → ฉัน',
                amount: 300,
                amountColor: ModuleColors.of(context).planning,
                caption: 'จ่ายคืน | จดโดย ฉัน',
                onTap: () => _tapped('payback'),
                payerAvatar: null,
              ),
              const PpForgeDivider.row(),
              EventBillRow(
                tick: false,
                title: 'ค่าที่พัก',
                amount: -3000,
                payerName: 'ฉัน',
                payerVerb: 'จ่าย',
                mine: true,
                onAction: () => _tapped('ลงบัญชี (I paid)'),
                actionTooltip: 'ลงบัญชี',
                onTap: () => _tapped('book bill'),
                payerAvatar: AvatarData.forName('ฉัน'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'SettleRow — an event\'s จัดการ line',
          note:
              'from → to + amount. A line with me in it: ⤓ จดเป็นหนี้ '
              '(onRecord) and, once recorded, a ✓ chip; the others are '
              'dimmed. A tap records the payback in the event.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettleRow(
                fromAvatar: const PersonMark(
                  level: PersonLevel.name,
                  size: 32,
                  avatar: null,
                ),
                fromName: 'เบียร์',
                toAvatar: const PersonMark(
                  level: PersonLevel.name,
                  size: 20,
                  avatar: null,
                ),
                toName: 'ฉัน',
                amount: const MoneyText(3230),
                mine: true,
                onRecord: () => _tapped('จดเป็นหนี้'),
                recordTooltip: 'จดเป็นหนี้',
                onTap: () => _tapped('payback'),
              ),
              SettleRow(
                fromAvatar: const PersonMark(
                  level: PersonLevel.name,
                  size: 32,
                  avatar: null,
                ),
                fromName: 'ฉัน',
                toAvatar: const PersonMark(
                  level: PersonLevel.name,
                  size: 20,
                  avatar: null,
                ),
                toName: 'ต้น',
                amount: const MoneyText(120),
                mine: true,
                recordedLabel: 'จดแล้ว',
                onRecord: () => _tapped('จดเป็นหนี้ again'),
                recordTooltip: 'จดเป็นหนี้',
              ),
              SettleRow(
                fromAvatar: const PersonMark(
                  level: PersonLevel.name,
                  size: 32,
                  avatar: null,
                ),
                fromName: 'ฝน',
                toAvatar: const PersonMark(
                  level: PersonLevel.name,
                  size: 20,
                  avatar: null,
                ),
                toName: 'เบียร์',
                amount: const MoneyText(500),
                onTap: () => _tapped('payback (not mine)'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'BookOptionCard — where my part of a bill goes',
          note:
              'The event bill sheet\'s "ลงบัญชีของฉันด้วย": one card per '
              'book (หนี้ / รายการ). Ticked = primary border + wash, and the '
              'child (person, result box, pickers) opens under it.',
          child: StatefulBuilder(
            builder: (context, set) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookOptionCard(
                  icon: AppIcons.debt,
                  title: 'หนี้',
                  subtitle: 'ฉันค้าง ฝน',
                  amount: const MoneyText(160),
                  checked: _bookDebt,
                  onChanged: (v) => set(() => _bookDebt = v),
                  child: const DebtResultBox(
                    nowLabel: 'ฝน ตอนนี้',
                    before: 'เจ้าหนี้ ฿340',
                    afterLabel: 'หลังบันทึก',
                    after: 'เจ้าหนี้ ฿500',
                    walletLabel: 'กระเป๋า',
                    walletValue: 'ไม่เปลี่ยน',
                  ),
                ),
                const SizedBox(height: PpForgeSpacing.sm),
                BookOptionCard(
                  icon: AppIcons.receipt,
                  title: 'รายการ',
                  subtitle: 'รายจ่ายส่วนของฉัน',
                  amount: const MoneyText(160),
                  checked: _bookTx,
                  onChanged: (v) => set(() => _bookTx = v),
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'BillDebtSummary — the debts a bill save moves (SA5)',
          note:
              'The bill form, before saving: each person my debts move with, '
              'from the BE preview (before → after + เพิ่มหนี้ / ลดหนี้), and '
              'the people marked คืนแล้ว. Dimmed while a newer preview loads.',
          child: BillDebtSummary(
            lines: [
              BillDebtLine(
                avatar: PersonMark(level: PersonLevel.name, avatar: null),
                name: 'ฝน',
                state: 'ไม่มีหนี้ → ลูกหนี้ ฿300',
                chip: 'เพิ่มหนี้ ฿300',
              ),
              BillDebtLine(
                avatar: PersonMark(
                  level: PersonLevel.contact,
                  avatar: AvatarData.forName('เบียร์'),
                ),
                name: 'เบียร์',
                state: 'ลูกหนี้ ฿120 → ลูกหนี้ ฿420',
                chip: 'เพิ่มหนี้ ฿300',
              ),
              BillDebtLine(
                avatar: PersonMark(level: PersonLevel.name, avatar: null),
                name: 'ต้น',
                chip: 'คืนแล้ว',
                chipTone: PpForgeChipTone.success,
              ),
            ],
          ),
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
                  ? IconTile(icon: AppIcons.expense, color: palette.expense)
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
              payerAvatar: AvatarData.forName(v<String>('payerName')),
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
          payerAvatar: AvatarData.forName('บี'),
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
