import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/ui/molecules/list-row` — the one data row of every list.
Widget buildListRowPage(BuildContext context) => const _ListRowPage();

class _ListRowPage extends StatefulWidget {
  const _ListRowPage();

  @override
  State<_ListRowPage> createState() => _ListRowPageState();
}

class _ListRowPageState extends State<_ListRowPage> {
  double? _water = 214;
  final _picked = <String>{'spotify'};

  void _toggle(String id) => setState(() {
    if (!_picked.remove(id)) _picked.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final bank = ListRowChip(
      'เงินในธนาคาร',
      icon: AppIcons.bank,
      color: scheme.primary,
      bare: true,
    );
    final cash = ListRowChip(
      'เงินเงินเงิน',
      icon: AppIcons.cash,
      color: palette.expense,
      bare: true,
    );
    const saving = ListRowChip(
      'บัญชีออมทรัพย์',
      icon: AppIcons.savings,
      bare: true,
    );
    const noWallet = ListRowChip(
      'ไม่ระบุกระเป๋า',
      icon: AppIcons.noWallet,
      bare: true,
    );
    TextSpan tag(String t, Color c) => TextSpan(
      text: '#$t',
      style: TextStyle(color: c, fontWeight: FontWeight.w600),
    );
    Widget tile(IconData icon, Color color) =>
        IconTile(icon: icon, color: color);
    Widget money(num v) => MoneyText(v, tone: MoneyTone.signed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'AppListRow',
          note:
              'Every chip is a mini AppChip built from a ListRowChip. Line 2 '
              'is always one text line tall. Taps on actions never reach '
              'onTap. The row knows no domain: money comes in through '
              'ListRowTrailing.value, words as strings.',
          controls: [
            const PlayText('title', initialValue: 'Grab Food'),
            PlayChoice<int>('titleMaxLines', const [('1', 1), ('2', 2)]),
            PlayChoice<String>('titleChips', const [
              ('filled', 'filled'),
              ('outlined', 'outlined'),
              ('none label', 'none'),
              ('two', 'two'),
              ('off', 'off'),
            ]),
            PlayChoice<String>('status', const [
              ('off', 'off'),
              ('primary', 'primary'),
              ('warning', 'warning'),
              ('neutral', 'neutral'),
            ]),
            PlayChoice<String>('line2.lead', const [
              ('off', 'off'),
              ('info', 'info'),
              ('primary', 'primary'),
            ]),
            PlayChoice<int>('line2.parts', const [
              ('0', 0),
              ('1', 1),
              ('2', 2),
            ], initial: 1),
            const PlayBool('line2.icon'),
            const PlayBool('line2.spans'),
            const PlayBool('line2.glyphs'),
            PlayChoice<String>('trailing', const [
              ('value', 'value'),
              ('text', 'text'),
              ('text warning', 'warn'),
              ('off', 'off'),
            ]),
            const PlayBool('trailing.caption'),
            PlayChoice<String>('actions', const [
              ('off', 'off'),
              ('button', 'button'),
              ('amount + button', 'field'),
              ('menu', 'menu'),
            ]),
            const PlayBool('alert'),
            const PlayBool('footer'),
            PlayChoice<bool?>('checked', const [
              ('off', null),
              ('false', false),
              ('true', true),
            ]),
            const PlayBool('dimmed'),
            const PlayBool('highlighted'),
            const PlayNum('indent', min: 0, max: 32, step: 8, initialValue: 0),
          ],
          builder: (context, v) {
            final caption = v<bool>('trailing.caption') ? 'รอยืนยัน' : null;
            final captionTone = caption == null ? null : Tone.warning;
            return _Card(
              rows: [
                AppListRow(
                  leading: tile(AppIcons.expense, palette.expense),
                  title: v<String>('title'),
                  titleMaxLines: v<int>('titleMaxLines'),
                  titleChips: switch (v<String>('titleChips')) {
                    'filled' => [bank],
                    'outlined' => const [saving],
                    'none' => const [noWallet],
                    'two' => [bank, const ListRowChip('อัตโนมัติ')],
                    _ => const [],
                  },
                  status: switch (v<String>('status')) {
                    'primary' => const ListRowChip(
                      'อีก 3 วัน',
                      tone: Tone.primary,
                    ),
                    'warning' => const ListRowChip(
                      'พัก',
                      tone: Tone.warning,
                      icon: AppIcons.pause,
                    ),
                    'neutral' => const ListRowChip(
                      'จ่ายแล้ว',
                      icon: AppIcons.check,
                    ),
                    _ => null,
                  },
                  line2: ListRowLine(
                    lead: switch (v<String>('line2.lead')) {
                      'info' => const ListRowChip(
                        'SMS',
                        tone: Tone.info,
                        selected: true,
                      ),
                      'primary' => const ListRowChip(
                        'จดเอง',
                        tone: Tone.primary,
                        selected: true,
                      ),
                      _ => null,
                    },
                    icon: v<bool>('line2.icon') ? AppIcons.recurring : null,
                    parts: const [
                      'Food Delivery',
                      'เมื่อวาน',
                    ].take(v<int>('line2.parts')).toList(),
                    spans: v<bool>('line2.spans')
                        ? [
                            tag('ทริปเชียงใหม่', palette.info),
                            tag('งาน', palette.success),
                          ]
                        : const [],
                    glyphs: v<bool>('line2.glyphs')
                        ? const [
                            ListRowGlyph(AppIcons.progress, text: '3/10'),
                            ListRowGlyph(AppIcons.link),
                            ListRowGlyph(AppIcons.shared, text: '3'),
                          ]
                        : const [],
                  ),
                  trailing: switch (v<String>('trailing')) {
                    'value' => ListRowTrailing.value(
                      money(-350),
                      caption: caption,
                      captionTone: captionTone,
                    ),
                    'text' => ListRowTrailing.text(
                      '12 รายการ',
                      caption: caption,
                      captionTone: captionTone,
                    ),
                    'warn' => ListRowTrailing.text(
                      'รอใส่ยอด',
                      tone: Tone.warning,
                      caption: caption,
                      captionTone: captionTone,
                    ),
                    _ => null,
                  },
                  actions: switch (v<String>('actions')) {
                    'button' => [
                      ListRowAction.button(
                        AppIcons.check,
                        tooltip: 'ยืนยัน',
                        onTap: () {},
                      ),
                    ],
                    'field' => [
                      ListRowAction.amount(
                        value: null,
                        hint: 'รอใส่ยอด',
                        onChanged: (_) {},
                      ),
                      ListRowAction.button(
                        AppIcons.check,
                        tooltip: 'ยืนยัน',
                        onTap: () {},
                      ),
                    ],
                    'menu' => [
                      ListRowAction.menu<String>(
                        tooltip: 'More',
                        options: const [
                          SheetOption(
                            value: 'rename',
                            label: 'เปลี่ยนชื่อ',
                            leading: AppIcon(AppIcons.edit),
                          ),
                          SheetOption(
                            value: 'delete',
                            label: 'ลบ',
                            leading: AppIcon(AppIcons.delete),
                            destructive: true,
                          ),
                        ],
                        onSelected: (_) {},
                      ),
                    ],
                    _ => const [],
                  },
                  alert: v<bool>('alert')
                      ? const ListRowAlert('ยังไม่ได้เลือกหมวด')
                      : null,
                  footer: v<bool>('footer')
                      ? const ProgressRow(value: 0.62, expected: 0.5)
                      : null,
                  checked: v<bool?>('checked'),
                  onCheck: () {},
                  dimmed: v<bool>('dimmed'),
                  highlighted: v<bool>('highlighted'),
                  indent: v<double>('indent'),
                  onTap: () {},
                ),
              ],
            );
          },
        ),
        HubDemo(
          title: 'walletRowChip + tagSpan (lib/ui/domain)',
          note:
              'Layer-2 helpers every entity row uses, so wallets and tags look '
              'the same on every list. walletRowChip: a bare chip (no fill, no '
              'border), the wallet\'s icon and name in its own colour, made '
              'readable on the card; muted without a colour; pass the "no '
              'wallet" label as the name when there is none. tagSpan: '
              '#name in the tag\'s icon colour, for ListRowLine.spans.',
          child: _Card(
            rows: [
              AppListRow(
                leading: tile(AppIcons.category, palette.warning),
                title: 'Filled wallet',
                titleChips: [
                  walletRowChip(
                    context,
                    name: 'เงินในธนาคาร',
                    iconCode: const IconCode(
                      icon: 'account_balance',
                      background: 'solid',
                      bgColors: ['#F06292'],
                      iconColors: ['#FFFFFF'],
                    ),
                  ),
                ],
                line2: ListRowLine(
                  parts: const ['Food'],
                  spans: [
                    tagSpan(
                      context,
                      'งาน',
                      iconCode: const IconCode(iconColors: ['#26A69A']),
                    ),
                    tagSpan(context, 'ไม่มีสี'),
                  ],
                ),
                trailing: ListRowTrailing.value(money(-120)),
              ),
              AppListRow(
                leading: tile(AppIcons.category, palette.info),
                title: 'Wallet without a colour',
                titleChips: [
                  walletRowChip(
                    context,
                    name: 'บัญชีออมทรัพย์',
                    iconCode: const IconCode(
                      icon: 'savings',
                      iconColors: ['#F06292'],
                    ),
                  ),
                ],
                trailing: ListRowTrailing.value(money(-80)),
              ),
              AppListRow(
                leading: tile(AppIcons.category, palette.error),
                title: 'No wallet',
                titleChips: [walletRowChip(context, name: 'ไม่ระบุกระเป๋า')],
                trailing: ListRowTrailing.value(money(-900)),
              ),
            ],
          ),
        ),
        HubInApp(
          note:
              'Today\'s lists redrawn with AppListRow, before any page moves '
              'over. Data is made up.',
          uses: [
            HubUse(
              label: 'Wallet chip, category | tags, shared glyph + head count',
              page: 'Transactions (TransactionTile)',
              child: _Card(
                header: const DateGroupHeader(label: '21 ต.ค.', total: -1149),
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.category, palette.warning),
                    title: 'กาแฟ + ขนม',
                    titleChips: [cash],
                    line2: const ListRowLine(parts: ['Dining / Take-away']),
                    trailing: ListRowTrailing.value(money(-120)),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'Spotify ประจำเดือน ต.ค. 2026',
                    titleChips: [bank],
                    line2: ListRowLine(
                      parts: const ['Subscriptions'],
                      spans: [tag('งาน', palette.success)],
                    ),
                    trailing: ListRowTrailing.value(money(-129)),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: tile(AppIcons.category, palette.error),
                    title: 'ตั๋วหนัง (ฝนจ่ายให้)',
                    titleChips: const [noWallet],
                    line2: const ListRowLine(
                      parts: ['Entertainment'],
                      glyphs: [ListRowGlyph(AppIcons.shared, text: '2')],
                    ),
                    trailing: ListRowTrailing.value(money(-900)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Select check, source chip, alert',
              page: 'Pending',
              child: _Card(
                rows: [
                  AppListRow(
                    checked: _picked.contains('sb'),
                    onCheck: () => _toggle('sb'),
                    leading: tile(AppIcons.category, palette.warning),
                    title: 'Starbucks',
                    titleChips: [bank],
                    line2: ListRowLine(
                      lead: const ListRowChip(
                        'SMS',
                        tone: Tone.info,
                        selected: true,
                      ),
                      parts: const ['Coffee'],
                      spans: [tag('งาน', palette.success)],
                    ),
                    trailing: ListRowTrailing.value(money(-165)),
                    onTap: () {},
                  ),
                  AppListRow(
                    checked: _picked.contains('tf'),
                    onCheck: () => _toggle('tf'),
                    leading: tile(AppIcons.expense, palette.expense),
                    title: 'โอนเงิน 305.00',
                    titleChips: [cash],
                    line2: const ListRowLine(
                      lead: ListRowChip(
                        'จดเอง',
                        tone: Tone.primary,
                        selected: true,
                      ),
                    ),
                    trailing: ListRowTrailing.value(money(-305)),
                    alert: const ListRowAlert('ยังไม่ได้เลือกหมวด'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Source chip, recurring glyph, expected = dimmed',
              page: 'Budget detail',
              child: _Card(
                header: const DateGroupHeader(label: '22 ต.ค.', total: -1068),
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.category, palette.success),
                    title: 'Lotus’s',
                    titleChips: [bank],
                    line2: ListRowLine(
                      parts: const ['Groceries'],
                      spans: [tag('บ้าน', palette.info)],
                    ),
                    trailing: ListRowTrailing.value(money(-649)),
                    onTap: () {},
                  ),
                  AppListRow(
                    dimmed: true,
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'Netflix',
                    titleChips: const [noWallet],
                    line2: const ListRowLine(
                      lead: ListRowChip('รายการประจำ'),
                      parts: ['Subscriptions'],
                      glyphs: [ListRowGlyph(AppIcons.progress, text: '8')],
                    ),
                    trailing: ListRowTrailing.value(money(-419)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label:
                  'Due chip, icon before the text, paused = dimmed, no amount',
              page: 'Recurring list (RecurringRow)',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'ผ่อน iPhone',
                    titleChips: [bank],
                    line2: const ListRowLine(
                      lead: ListRowChip('อีก 9 วัน', tone: Tone.primary),
                      icon: AppIcons.recurring,
                      parts: ['ทุกเดือน'],
                      glyphs: [ListRowGlyph(AppIcons.progress, text: '3/10')],
                    ),
                    trailing: ListRowTrailing.value(money(-2990)),
                    onTap: () {},
                  ),
                  AppListRow(
                    dimmed: true,
                    leading: tile(AppIcons.recurring, palette.warning),
                    title: 'ค่าไฟ',
                    status: const ListRowChip(
                      'พัก',
                      tone: Tone.warning,
                      icon: AppIcons.pause,
                    ),
                    line2: const ListRowLine(
                      icon: AppIcons.recurring,
                      parts: ['ทุกเดือน'],
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Select check, value + ✓, field + ✓',
              page: 'Recurring · ต้องจัดการ (DueBoxes)',
              child: _Card(
                rows: [
                  AppListRow(
                    checked: _picked.contains('spotify'),
                    onCheck: () => _toggle('spotify'),
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'Spotify',
                    titleChips: [bank],
                    line2: const ListRowLine(
                      lead: ListRowChip(
                        'รอยืนยัน',
                        tone: Tone.warning,
                        selected: true,
                      ),
                      parts: ['พ. 22 ต.ค.'],
                    ),
                    trailing: ListRowTrailing.value(money(-129)),
                    actions: [
                      ListRowAction.button(
                        AppIcons.check,
                        tooltip: 'ยืนยัน',
                        onTap: () {},
                      ),
                    ],
                    onTap: () {},
                  ),
                  AppListRow(
                    checked: _picked.contains('power'),
                    onCheck: () => _toggle('power'),
                    leading: tile(AppIcons.recurring, palette.warning),
                    title: 'ค่าไฟ',
                    titleChips: [cash],
                    line2: const ListRowLine(
                      lead: ListRowChip(
                        'รอใส่ยอด',
                        tone: Tone.warning,
                        selected: true,
                      ),
                      parts: ['เฉลี่ย ฿1,180'],
                    ),
                    actions: [
                      ListRowAction.amount(
                        key: const ValueKey('power'),
                        value: null,
                        hint: 'รอใส่ยอด',
                        onChanged: (_) {},
                      ),
                      ListRowAction.button(
                        AppIcons.check,
                        tooltip: 'ยืนยัน',
                        onTap: () {},
                      ),
                    ],
                    onTap: () {},
                  ),
                  AppListRow(
                    checked: _picked.contains('water'),
                    onCheck: () => _toggle('water'),
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'ค่าน้ำ',
                    titleChips: [cash],
                    line2: const ListRowLine(
                      lead: ListRowChip(
                        'รอใส่ยอด',
                        tone: Tone.warning,
                        selected: true,
                      ),
                    ),
                    actions: [
                      ListRowAction.amount(
                        key: const ValueKey('water'),
                        value: _water,
                        hint: 'รอใส่ยอด',
                        onChanged: (v) => _water = v,
                      ),
                      ListRowAction.button(
                        AppIcons.check,
                        tooltip: 'ยืนยัน',
                        onTap: () {},
                      ),
                    ],
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Caption under the value, value + ✓, done = dimmed',
              page: 'Recurring · month list',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'Netflix',
                    titleChips: [bank],
                    line2: const ListRowLine(parts: ['ส. 25 ต.ค.']),
                    trailing: ListRowTrailing.value(
                      money(-419),
                      caption: 'พรุ่งนี้',
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'ผ่อน iPhone',
                    titleChips: [bank],
                    line2: const ListRowLine(
                      lead: ListRowChip(
                        'รอยืนยัน',
                        tone: Tone.warning,
                        selected: true,
                      ),
                      parts: ['ศ. 24 ต.ค.'],
                      glyphs: [ListRowGlyph(AppIcons.progress, text: '3/10')],
                    ),
                    trailing: ListRowTrailing.value(money(-2990)),
                    actions: [
                      ListRowAction.button(
                        AppIcons.check,
                        tooltip: 'ยืนยัน',
                        onTap: () {},
                      ),
                    ],
                    onTap: () {},
                  ),
                  AppListRow(
                    dimmed: true,
                    leading: tile(AppIcons.recurring, palette.info),
                    title: 'เน็ตบ้าน',
                    titleChips: [bank],
                    line2: const ListRowLine(
                      lead: ListRowChip('จ่ายแล้ว'),
                      parts: ['จ. 6 ต.ค.'],
                    ),
                    trailing: ListRowTrailing.value(money(-599)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Two-line title, waiting text in warning',
              page: 'Recurring detail · occurrences',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: DateTile(date: DateTime(2026, 10, 26)),
                    title: 'Spotify ประจำเดือน ต.ค. 2026',
                    titleMaxLines: 2,
                    titleChips: [bank],
                    line2: const ListRowLine(lead: ListRowChip('อัตโนมัติ')),
                    trailing: ListRowTrailing.value(
                      money(-129),
                      caption: 'รอยืนยัน',
                      captionTone: Tone.warning,
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: DateTile(date: DateTime(2026, 11, 5)),
                    title: 'ค่าไฟ ประจำเดือน พ.ย. 2026',
                    titleMaxLines: 2,
                    titleChips: [cash],
                    trailing: const ListRowTrailing.text(
                      'รอใส่ยอด',
                      tone: Tone.warning,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Person leading, warning span, paid chip',
              page: 'Debts · people / statement',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: const PersonMark(
                      name: 'ฝน',
                      level: PersonLevel.contact,
                      size: 36,
                    ),
                    title: 'ฝน',
                    line2: const ListRowLine(parts: ['ค้าง 12 วัน']),
                    trailing: ListRowTrailing.value(
                      const MoneyText(900, tone: MoneyTone.income),
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: const PersonMark(
                      name: 'บอส',
                      level: PersonLevel.linked,
                      size: 36,
                      linkOnCorner: true,
                    ),
                    title: 'บอส',
                    line2: ListRowLine(
                      spans: [
                        TextSpan(
                          text: 'ค้าง 45 วัน',
                          style: TextStyle(
                            color: Tone.warning.color(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: ListRowTrailing.value(
                      const MoneyText(2400, tone: MoneyTone.income),
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: tile(AppIcons.debt, scheme.tertiary),
                    title: 'ตั๋วหนัง',
                    status: const ListRowChip('จ่ายแล้ว', icon: AppIcons.check),
                    line2: const ListRowLine(parts: ['หารบิล ฿1,800']),
                    trailing: ListRowTrailing.value(
                      const MoneyText(900, tone: MoneyTone.income),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'ListRowLine.custom: wallet → bucket',
              page: 'Saving goal · history',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.savingDeposit, palette.income),
                    title: 'ออม',
                    line2: ListRowLine.custom(
                      Row(
                        children: [
                          Flexible(
                            child: AppChip(
                              label: 'เงินในธนาคาร',
                              icon: AppIcons.bank,
                              fill: scheme.primary,
                              onFill: scheme.onPrimary,
                              size: ChipSize.mini,
                            ),
                          ),
                          const Flexible(
                            child: Text(
                              '  →  เที่ยวญี่ปุ่น',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: ListRowTrailing.value(money(2000)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label:
                  'accent: the row\'s own colour reaches pieces inside (the '
                  'installment chain), like an AppHeroCard',
              page: 'Recurring · installments',
              child: _Card(
                rows: [
                  for (final (name, color, paid, total) in [
                    ('ผ่อนประกันรถ', palette.info, 5, 10),
                    ('ผ่อน iPhone 17', scheme.primary, 4, 12),
                    ('ผ่อนโซฟา', palette.warning, 6, 6),
                  ])
                    AppListRow(
                      accent: color,
                      leading: tile(AppIcons.recurring, color),
                      title: name,
                      line2: ListRowLine(
                        lead: walletRowChip(context, name: 'เงินในธนาคาร'),
                        icon: AppIcons.recurring,
                        parts: const ['ทุกวันที่ 18'],
                        glyphs: [
                          ListRowGlyph(AppIcons.progress, text: '$paid/$total'),
                        ],
                      ),
                      trailing: ListRowTrailing.value(money(-2150)),
                      footer: OccurrenceChain(
                        dots: [
                          for (var i = 0; i < total; i++)
                            i < paid
                                ? ChainDot.paid
                                : i == paid
                                ? ChainDot.current
                                : ChainDot.future,
                        ],
                      ),
                      onTap: () {},
                    ),
                ],
              ),
            ),
            HubUse(
              label: 'Footer (budget bar), ⋯ menu action',
              page: 'Events list / event tags',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.project, palette.info),
                    title: 'ทริปเชียงใหม่',
                    line2: const ListRowLine(parts: ['5 คน', '12–15 พ.ย.']),
                    trailing: ListRowTrailing.value(money(-12400)),
                    footer: const ProgressRow(
                      value: 0.62,
                      expected: 0.5,
                      label: 'งบ ฿20,000',
                    ),
                    onTap: () {},
                  ),
                  AppListRow(
                    leading: tile(AppIcons.tag, palette.success),
                    title: 'ค่าที่พัก',
                    line2: const ListRowLine(parts: ['8 บิล']),
                    actions: [
                      ListRowAction.menu<String>(
                        tooltip: 'More',
                        options: const [
                          SheetOption(
                            value: 'rename',
                            label: 'เปลี่ยนชื่อ',
                            leading: AppIcon(AppIcons.edit),
                          ),
                          SheetOption(
                            value: 'delete',
                            label: 'ลบ',
                            leading: AppIcon(AppIcons.delete),
                            destructive: true,
                          ),
                        ],
                        onSelected: (_) {},
                      ),
                    ],
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Indent (sub-item), select, count as text',
              page: 'Categories / tags / contacts',
              child: _Card(
                rows: [
                  AppListRow(
                    leading: tile(AppIcons.category, palette.warning),
                    title: 'Dining',
                    line2: const ListRowLine(parts: ['หมวดย่อย 4']),
                    trailing: const ListRowTrailing.text('12 รายการ'),
                    onTap: () {},
                  ),
                  AppListRow(
                    indent: 28,
                    leading: tile(AppIcons.category, palette.warning),
                    title: 'Food Delivery',
                    trailing: const ListRowTrailing.text('7 รายการ'),
                    onTap: () {},
                  ),
                  AppListRow(
                    checked: _picked.contains('ent'),
                    onCheck: () => _toggle('ent'),
                    leading: tile(AppIcons.category, palette.error),
                    title: 'Entertainment',
                    trailing: const ListRowTrailing.text('3 รายการ'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.rows, this.header});

  final List<Widget> rows;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        AppCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              children: [
                for (final (i, r) in rows.indexed) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: line),
                  r,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
