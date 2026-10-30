import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/organisms/hero-card` — the 0.4.0 detail hero (rows A–G as one API),
/// its edit variant, and the DetailLayout slot order.
Widget buildHeroCardPage(BuildContext context) => const _HeroCardPage();

class _HeroCardPage extends StatefulWidget {
  const _HeroCardPage();

  @override
  State<_HeroCardPage> createState() => _HeroCardPageState();
}

class _HeroCardPageState extends State<_HeroCardPage> {
  final _name = TextEditingController(text: 'Groceries');
  final _desc = TextEditingController(text: 'Fresh food and drinks');
  final _amount = TextEditingController(text: '80,000');

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = palette.expense;
    final style = HeroStyle.tinted(color: tint, glyph: AppIcons.category);
    final blue = const Color(0xFF0EA5E9);
    final blueStyle = HeroStyle.tinted(color: blue, glyph: AppIcons.savingGoal);
    final avatar = IconDisplay(
      type: IconType.category,
      size: 40,
      iconCode: const IconCode(bgColors: ['#7E57C2', '#26A69A']),
    );
    Widget desc(String s) => Text(
      s,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final toggle = AppListToolbarState.local();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'Detail hero — category (A chips | slot ✏️ | B | C number)',
          note:
              'Name lives in the top bar; the card shows icon + description. '
              'C: label link + the big number in a semantic colour.',
          child: AppHeroCard(
            style: style,
            header: HeroHeader(
              leading: [
                AppChip(
                  label: 'รายจ่าย',
                  icon: AppIcons.expense,
                  color: palette.expense,
                  selected: true,
                ),
              ],
              onEdit: () {},
            ),
            content: [
              HeroIdentity(
                icon: avatar,
                description: desc('Fresh food and drinks'),
              ),
              HeroNumber(
                label: 'ต.ค. ใช้ไป | 12 รายการ ›',
                onLabelTap: () {},
                color: palette.expense,
                value: const MoneyText(5100, hideable: false),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Detail hero — goal (D 25-50-75 ticks | E tiles | F alert)',
          note:
              'Links → 🔍 → ✏️ in the slot. The bar has 25/50/75 ticks; three '
              'tappable tiles; one amber alert line.',
          child: AppHeroCard(
            style: blueStyle,
            header: HeroHeader(
              leading: const [AppChip(label: 'ตามแผน', selected: true)],
              actions: [AppListToolbarToggle(state: toggle)],
              onEdit: () {},
            ),
            content: [
              HeroIdentity(icon: avatar, description: desc('7 days in Tokyo')),
              const HeroNumber(
                label: 'ออมแล้ว',
                target: '/ ฿80,000 | 65%',
                value: MoneyText(52000, hideable: false),
              ),
              HeroBar(
                value: 0.65,
                color: blue,
                ticks: const [0.25, 0.5, 0.75],
                left: 'ครบ 15 มี.ค. 2027',
                right: 'อีก 149 วัน',
              ),
              HeroAlert(text: 'เดือนนี้ยังขาดอีก ฿2,500', onTap: () {}),
              const HeroValueLine(
                label: 'รายรับรวม',
                value: MoneyText(500, tone: MoneyTone.income),
              ),
            ],
            footer: [
              for (final List<Widget> tiles in [
                const [
                  _DemoTile('เดือนนี้ขาด', '฿2,500'),
                  _DemoTile('ออมแล้ว', '฿3,000'),
                  _DemoTile('ต้องออม/เดือน', '฿5,500'),
                ],
              ])
                if (tiles.isNotEmpty) HeroTiles(children: tiles),
            ],
          ),
        ),
        HubDemo(
          title: 'Detail hero — budget (D pace tick) / wallet (D split)',
          child: Column(
            children: [
              AppHeroCard(
                style: blueStyle,
                header: HeroHeader(
                  leading: const [AppChip(label: 'รายปี', selected: true)],
                  onEdit: () {},
                ),
                content: [
                  HeroIdentity(
                    icon: avatar,
                    description: desc('Buffet all year'),
                  ),
                  const HeroNumber(
                    label: 'ยังใช้ได้',
                    target: '/ ฿10,000',
                    value: MoneyText(10000, hideable: false),
                  ),
                  HeroBar(
                    value: 0.2,
                    marker: 0.79,
                    left: 'ใช้ ฿2,000',
                    right: '20%',
                  ),
                  desc('นับ: อาหาร | เตือนที่ 80%'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppHeroCard(
                style: style,
                header: HeroHeader(
                  leading: const [
                    AppChip(label: 'บัญชีธนาคาร', selected: true),
                  ],
                  onEdit: () {},
                ),
                content: [
                  HeroIdentity(icon: avatar, description: desc('Main wallet')),
                  const HeroNumber(
                    label: 'ใช้ได้',
                    value: MoneyText(8000, hideable: false),
                  ),
                  HeroBar.split(
                    parts: [(0.8, palette.success), (0.2, palette.warning)],
                    left: 'ใช้ได้ ฿8,000',
                    right: 'ออมไว้ ฿2,000',
                  ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Detail hero — people (name + fact), embedded slot',
          child: AppHeroCard(
            style: blueStyle,
            header: HeroHeader(
              leading: [
                AppChip(label: 'รอรับ', color: palette.income, selected: true),
              ],
              onEdit: () {},
            ),
            content: [
              HeroIdentity(
                icon: avatar,
                name: const Text('Mint'),
                fact: const Text('ล่าสุด 5 ต.ค.'),
              ),
              HeroNumber(
                label: 'รอรับ',
                color: palette.income,
                value: const MoneyText(1250, hideable: false),
              ),
              const Text('ข้อความสรุปถึงเพื่อน'),
            ],
          ),
        ),
        HubDemo(
          title: 'Detail hero — edit variant',
          note:
              'Editable chips as dropdowns, icon ✎, underlined name / '
              'description, outlined amount on the tint. Rows D–G, the slot '
              'and the settings line are hidden.',
          child: AppHeroCard(
            style: blueStyle,
            mode: HeroCardMode.edit,
            header: HeroHeader(
              leading: const [
                AppChip(
                  label: 'ตามแผน',
                  trailing: AppChipTrailing.dropdown,
                  selected: true,
                ),
              ],
            ),
            content: [
              HeroIdentity(
                icon: EditableCircle(size: 44, onTap: () {}, child: avatar),
                name: HeroNameInput(
                  editing: true,
                  controller: _name,
                  hint: 'ชื่อ',
                ),
                description: HeroDescription(
                  controller: _desc,
                  editing: true,
                  hint: 'คำอธิบาย',
                ),
              ),
              HeroAmountField(
                controller: _amount,
                label: 'ยอดเป้าหมาย',
                accent: blue,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DetailLayout — slot order',
          note:
              'hero → tags → actions → info → settings → people → note → '
              'records → end zone → meta. Pages fill slots; DetailSections is '
              'the same body for inside a tab (overview).',
          child: SizedBox(
            height: 220,
            child: DetailLayout(
              topInset: 0,
              hero: AppHeroCard(
                style: style,
                content: [
                  HeroIdentity(icon: avatar, description: desc('hero')),
                ],
              ),
              tags: const Text('tags'),
              info: const Text('info'),
              settings: const Text('settings'),
              note: const Text('note'),
              // Several pieces in the records slot: DetailRecords spaces them.
              records: const DetailRecords(
                children: [Text('filter row'), Text('records')],
              ),
              metaLines: const ['บันทึกเมื่อ …'],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}
