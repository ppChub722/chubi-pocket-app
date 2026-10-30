import 'package:flutter/material.dart';

import '../../features/accounts/domain/account_type.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';
import 'organisms_detail_section_page.dart' show DetailRowsDemo;

/// `/dev/ui/molecules/row` — the one row shell and its two presets:
/// Shell (AppRow) → List (AppListRow, a list item) → Detail (AppDetailRow, a
/// field of this record). AppListRow and AppDetailRow are AppRow presets.
Widget buildRowPage(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    HubSubheading(
      'Shell',
      note:
          'AppRow: padding, fill, ink, dim / disabled, leading slot + corner '
          'badge, trailing, actions, footer. Densities list / detail.',
    ),
    _RowShellPage(),
    HubSubheading(
      'List',
      note: 'AppListRow = AppRow (density list): an item in a list.',
    ),
    _ListRowPage(),
    HubSubheading(
      'Detail',
      note: 'AppDetailRow = AppRow (density detail): a field of this record.',
    ),
    _DetailPatternsPage(),
    DetailRowsDemo(),
  ],
);

class _RowShellPage extends StatelessWidget {
  const _RowShellPage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void noop() {}
    Widget tile(IconData icon) => IconTile(icon: icon, color: scheme.primary);
    Widget title(String t) =>
        Text(t, style: Theme.of(context).textTheme.bodyLarge);
    Widget sub(String t) => Text(
      t,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'Density: list vs detail',
          note:
              'list = 8 / 8 padding, the leading as big as the caller makes '
              'it (AppListRow). detail = 12 / 12, a 22 px muted icon, ink only '
              'while pressed (AppDetailRow). Same shell, own rhythm.',
          child: SectionCard(
            first: true,
            children: [
              AppRow(
                leading: tile(AppIcons.wallet),
                title: title('List density'),
                subtitle: sub('Line 2 sits 2 px under the title'),
                trailing: const Text('฿120'),
                onTap: noop,
              ),
              AppRow(
                density: AppRowDensity.detail,
                leading: const AppIcon(AppIcons.info),
                title: title('Detail density'),
                subtitle: sub('The helper sits 4 px under the label'),
                trailing: const Text('Value'),
                trailingMaxFraction: 0.5,
                chevron: true,
                onTap: noop,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Fill: highlighted, tinted (accent), plain',
          note:
              'highlighted = primary 8 %. tinted = the accent\'s soft wash '
              '(HeroColors.from: contrast-checked) and, in detail density, the '
              'leading icon in the accent. Inside a SectionCard the fill takes '
              'the cell\'s round corners (AppRowShape).',
          child: SectionCard(
            first: true,
            children: [
              AppRow(
                density: AppRowDensity.detail,
                leading: const AppIcon(AppIcons.link),
                title: title('Tinted (yellow accent)'),
                accent: const Color(0xFFFFEB3B),
                tinted: true,
                onTap: noop,
              ),
              AppRow(
                density: AppRowDensity.detail,
                leading: const AppIcon(AppIcons.category),
                title: title('Highlighted'),
                highlighted: true,
                onTap: noop,
              ),
              AppRow(
                density: AppRowDensity.detail,
                leading: const AppIcon(AppIcons.link),
                title: title('Tinted (brand blue)'),
                accent: const Color(0xFF229ED9),
                tinted: true,
                onTap: noop,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Dimmed, disabled, reserved leading',
          note:
              'dimmed = 55 %, still tappable. disabled = 38 %, no taps, no '
              'ink. reserveLeading keeps the icon\'s room so titles line up.',
          child: SectionCard(
            first: true,
            children: [
              AppRow(
                density: AppRowDensity.detail,
                leading: const AppIcon(AppIcons.archive),
                title: title('Dimmed'),
                dimmed: true,
                onTap: noop,
              ),
              AppRow(
                density: AppRowDensity.detail,
                leading: const AppIcon(AppIcons.download),
                title: title('Disabled'),
                disabled: true,
                onTap: noop,
              ),
              AppRow(
                density: AppRowDensity.detail,
                reserveLeading: true,
                title: title('No icon, room kept'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Badge, trailing icon, actions, footer, select',
          note:
              'RowBadge puts a CornerBadge on the leading at any size (an icon '
              'or RowBadge.logo with an image). trailingIcon = 16 px after the '
              'value. actions never pass taps to the row. footer spans from the '
              'title to the right.',
          child: SectionCard(
            first: true,
            children: [
              AppRow(
                leading: Avatar(AvatarData.forName('Pond'), size: 40),
                badge: const RowBadge(icon: AppIcons.link),
                title: title('Avatar with an icon badge'),
                trailing: const Text('@ppond'),
                trailingIcon: AppIcons.lock,
              ),
              AppRow(
                leading: tile(AppIcons.savings),
                title: title('Actions + footer'),
                actions: [
                  AppIconButton.flat(
                    icon: AppIcons.edit,
                    dense: true,
                    onPressed: noop,
                  ),
                ],
                footer: const LinearProgressIndicator(value: 0.6),
                onTap: noop,
              ),
              AppRow(
                selector: SelectCheck(value: true, onTap: noop),
                leading: tile(AppIcons.wallet),
                title: title('With a select check'),
                highlighted: true,
                onTap: noop,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'A badge never moves or resizes the leading',
          note:
              'Each pair: the same leading without and with a badge. The '
              'icon, logo and avatar keep their size and place; the badge only '
              'overlays the corner (test: app_row_badge_geometry_test).',
          child: SectionCard(
            first: true,
            children: [
              for (final (label, leading, size) in [
                ('Icon', const AppIcon(AppIcons.link), null),
                (
                  'Logo',
                  const SizedBox.square(
                    dimension: 32,
                    child: ColoredBox(color: Color(0xFF229ED9)),
                  ),
                  32.0,
                ),
                ('Avatar', Avatar(AvatarData.forName('Pond'), size: 32), 32.0),
              ])
                for (final badged in [false, true])
                  AppRow(
                    density: AppRowDensity.detail,
                    leading: leading,
                    leadingSize: size,
                    badge: badged ? const RowBadge(icon: AppIcons.check) : null,
                    title: title('$label${badged ? ' + badge' : ''}'),
                  ),
            ],
          ),
        ),
        HubPlayground(
          title: 'AppRow',
          controls: [
            PlayChoice<AppRowDensity>('density', [
              for (final d in AppRowDensity.values) (d.name, d),
            ]),
            const PlayText('title', initialValue: 'Telegram'),
            const PlayText('subtitle', initialValue: ''),
            const PlayText('trailing', initialValue: '@ppond'),
            const PlayBool('badge'),
            const PlayBool('trailingIcon'),
            const PlayBool('chevron', initialValue: true),
            const PlayBool('tinted'),
            const PlayBool('highlighted'),
            const PlayBool('dimmed'),
            const PlayBool('disabled'),
            const PlayNum('indent', min: 0, max: 48, step: 8, initialValue: 0),
          ],
          builder: (context, v) {
            final density = v<AppRowDensity>('density');
            final sub = v<String>('subtitle');
            final trailing = v<String>('trailing');
            return SectionCard(
              first: true,
              children: [
                AppRow(
                  density: density,
                  leading: density == AppRowDensity.detail
                      ? const AppIcon(AppIcons.link)
                      : tile(AppIcons.link),
                  badge: v<bool>('badge')
                      ? const RowBadge(icon: AppIcons.check)
                      : null,
                  leadingSize: density == AppRowDensity.detail ? 22 : 40,
                  title: title(v<String>('title')),
                  subtitle: sub.isEmpty ? null : Text(sub),
                  trailing: trailing.isEmpty ? null : Text(trailing),
                  trailingMaxFraction: 0.5,
                  trailingIcon: v<bool>('trailingIcon') ? AppIcons.lock : null,
                  chevron: v<bool>('chevron'),
                  accent: const Color(0xFF229ED9),
                  tinted: v<bool>('tinted'),
                  highlighted: v<bool>('highlighted'),
                  dimmed: v<bool>('dimmed'),
                  disabled: v<bool>('disabled'),
                  indent: v<double>('indent'),
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

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
                        hint: 'รอยอด',
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
          title: 'TxListRow: one row for every money item',
          note:
              'The same on รายการ, กระเป๋า, งบ, เป้าออม and the linked card: '
              'category icon (else the kind\'s) | source mark + title / wallet '
              '| parts / tags | amount. Savings take the money colours: in '
              'green, out red, a move grey.',
          child: _Card(
            rows: [
              TxListRow(
                kind: TxListKind.expense,
                title: 'ค่าเน็ตบ้าน ประจำเดือน',
                source: TxSource.recurring,
                wallet: walletRowChip(context, name: 'เงินในธนาคาร'),
                parts: const ['Communication'],
                tags: [tagSpan(context, 'บ้าน')],
                amount: const MoneyText(-599, tone: MoneyTone.signed),
              ),
              const TxListRow(
                kind: TxListKind.income,
                title: 'เงินเดือน',
                parts: ['Salary'],
                amount: MoneyText(41500, tone: MoneyTone.signed),
              ),
              const TxListRow(
                kind: TxListKind.savingIn,
                title: 'ออม',
                source: TxSource.recurring,
                amount: MoneyText(2000, tone: MoneyTone.income),
              ),
              const TxListRow(
                kind: TxListKind.savingOut,
                title: 'ถอน',
                amount: MoneyText(-500, tone: MoneyTone.expense),
              ),
              const TxListRow(
                kind: TxListKind.savingMove,
                title: 'จัดสรร',
                parts: ['จาก กองทุนฉุกเฉิน'],
                amount: MoneyText(1000, tone: MoneyTone.plain),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'titleMark: where a row came from (txSourceMark)',
          note:
              'A circle as tall as the title\'s letters, before it: รายการประจำ, '
              'ผ่อน, อีเวนต์, หนี้, รอยืนยัน. Rows show it instead of source '
              'chips / ↻ / 5/12; tags stay on the detail page.',
          child: _Card(
            rows: [
              for (final s in TxSource.values)
                AppListRow(
                  leading: tile(AppIcons.category, palette.warning),
                  title: s.name,
                  titleMark: txSourceMark(context, s),
                  line2: const ListRowLine(parts: ['Groceries']),
                  trailing: const ListRowTrailing.value(
                    MoneyText(-350, tone: MoneyTone.signed),
                  ),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'walletRowChip + tagSpan (lib/ui/domain)',
          note:
              'Layer-2 helpers every entity row uses, so wallets and tags look '
              'the same on every list. walletRowChip: a bare chip (no fill, no '
              'border), the wallet\'s icon and name in its own colour, made '
              'readable on the card; with no picked icon, its type\'s default '
              '(pass type); muted with no wallet — pass the "no '
              'wallet" label as the name. tagSpan: '
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
              for (final t in AccountType.values)
                AppListRow(
                  leading: tile(AppIcons.category, palette.info),
                  title: 'Not picked: the type\'s default',
                  titleChips: [
                    walletRowChip(
                      context,
                      name: accountTypeLabel(context, t),
                      type: t,
                    ),
                  ],
                  trailing: ListRowTrailing.value(money(-50)),
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
                header: const AppListHeader(
                  title: '21 ต.ค.',
                  trailing: ListHeaderTrailing.value(
                    MoneyText(-1149, tone: MoneyTone.signed),
                  ),
                ),
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
                header: const AppListHeader(
                  title: '22 ต.ค.',
                  trailing: ListHeaderTrailing.value(
                    MoneyText(-1068, tone: MoneyTone.signed),
                  ),
                ),
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
                        hint: 'รอยอด',
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
                        hint: 'รอยอด',
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

const _telegram = Color(0xFF229ED9);
const _line = Color(0xFF06C755);
const _google = Color(0xFF4285F4);

/// A stand-in for a brand logo image (the hub has no network): the real
/// rows get a PNG from the BE.
class _Logo extends StatelessWidget {
  const _Logo(this.icon, this.color);

  final IconData icon;
  final Color color;

  /// The same square as the avatar rows (a real logo PNG is drawn at it).
  static const size = 32.0;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Theme.of(context).colorScheme.surface),
        ),
      ),
    ),
  );
}

class _DetailPatternsPage extends StatelessWidget {
  const _DetailPatternsPage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final grey = scheme.outline;
    void noop() {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'Leading: icon, logo, avatar + badge',
          note:
              'A 22 px muted icon by default. A logo or an avatar sets leadingSize (one 32 px slot): same size and place with or without a badge. A '
              'badge (RowBadge.logo) shows at any size: the app that gave the '
              'picture.',
          child: SectionCard(
            first: true,
            title: 'Leading',
            children: [
              AppDetailRow(
                icon: AppIcons.info,
                label: 'Icon',
                trailing: const Text('Value'),
                onTap: noop,
                showChevron: true,
              ),
              AppDetailRow(
                leading: const _Logo(Icons.send, _telegram),
                leadingSize: _Logo.size,
                label: 'Logo',
                trailing: const Text('Telegram'),
              ),
              AppDetailRow(
                leading: Avatar(AvatarData.forName('Pond'), size: 32),
                leadingSize: _Logo.size,
                badge: const RowBadge.logo(_Logo(Icons.send, _telegram)),
                label: 'Avatar + logo badge',
                trailing: const Text('@ppond'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Connections: linked, not linked, coming soon',
          note:
              'Linked with a picture: the picture + the app logo as a badge, '
              'the row tinted in the brand colour, 🔗 before the username. '
              'Linked without a picture: the logo in colour. Not linked: the '
              'logo in grey, a muted value. Not built: comingSoon (38 %, no '
              'taps, the "coming soon" badge from UiStrings).',
          child: SectionCard(
            first: true,
            title: 'Connections',
            children: [
              AppDetailRow(
                leading: Avatar(AvatarData.forName('Pond'), size: 32),
                leadingSize: _Logo.size,
                badge: const RowBadge.logo(_Logo(Icons.send, _telegram)),
                label: 'Telegram',
                valueIcon: AppIcons.link,
                trailing: const Text('@ppond'),
                accent: _telegram,
                tinted: true,
                showChevron: true,
                onTap: noop,
                onLongPress: noop,
              ),
              AppDetailRow(
                leading: const _Logo(Icons.send, _telegram),
                leadingSize: _Logo.size,
                label: 'Telegram (no picture)',
                valueIcon: AppIcons.link,
                trailing: const Text('@ppond'),
                accent: _telegram,
                tinted: true,
                showChevron: true,
                onTap: noop,
              ),
              AppDetailRow(
                leading: _Logo(Icons.send, grey),
                leadingSize: _Logo.size,
                label: 'Telegram (not linked)',
                trailing: const Text('Not linked'),
                valueColor: scheme.onSurfaceVariant,
                showChevron: true,
                onTap: noop,
              ),
              AppDetailRow(
                leading: _Logo(Icons.chat_bubble, grey),
                leadingSize: _Logo.size,
                label: 'LINE',
                comingSoon: true,
              ),
              AppDetailRow(
                leading: _Logo(Icons.g_mobiledata, grey),
                leadingSize: _Logo.size,
                label: 'Google',
                comingSoon: true,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Value: colour, lock, chain, chevron',
          note:
              'The value is primary unless the row passes valueColor. locked '
              '= 🔒 after the value, and the value + lock take the theme\'s '
              'muted text token (onSurfaceVariant: per theme, light / dark). '
              'valueIcon = a 16 px icon before the value, in its colour. The '
              'value takes at most half the row.',
          child: SectionCard(
            first: true,
            title: 'Values',
            children: [
              const AppDetailRow(
                icon: AppIcons.profile,
                label: 'Username (locked)',
                trailing: Text('ppond'),
                locked: true,
              ),
              const AppDetailRow(
                icon: AppIcons.link,
                label: 'Linked account',
                valueIcon: AppIcons.link,
                trailing: Text('Aom'),
              ),
              AppDetailRow.pick(
                icon: AppIcons.category,
                label: 'Category',
                emptyText: 'Pick one',
                onTap: noop,
              ),
              const AppDetailRow(
                icon: AppIcons.info,
                label: 'A long value',
                trailing: Text(
                  'A value long enough to take half of the row and wrap',
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Permission status (valueColor by state)',
          note:
              'Granted / in use = primary (the default), not asked = muted, '
              'denied = the warning token.',
          child: SectionCard(
            first: true,
            title: 'Permissions',
            children: [
              AppDetailRow(
                icon: AppIcons.notifications,
                label: 'การแจ้งเตือน',
                trailing: const Text('อนุญาตแล้ว'),
                showChevron: true,
                onTap: noop,
              ),
              AppDetailRow(
                icon: Icons.photo_camera_outlined,
                label: 'กล้อง',
                trailing: const Text('ยังไม่ได้ขอ'),
                valueColor: scheme.onSurfaceVariant,
                showChevron: true,
                onTap: noop,
              ),
              AppDetailRow(
                icon: Icons.photo_library_outlined,
                label: 'รูปภาพ',
                trailing: const Text('ปฏิเสธไว้'),
                valueColor: palette.warning,
                showChevron: true,
                onTap: noop,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Tinted: first, middle, last',
          note:
              'A tinted row keeps the card\'s round corners at the top and '
              'bottom (the SectionCard hands its cell radius to the row). The '
              'yellow accent is darkened until it reads 3:1 on the surface.',
          child: SectionCard(
            first: true,
            children: [
              for (final (label, color) in const [
                ('Yellow', Color(0xFFFFEB3B)),
                ('LINE green', _line),
                ('Google blue', _google),
              ])
                AppDetailRow(
                  icon: AppIcons.link,
                  label: label,
                  trailing: const Text('Linked'),
                  accent: color,
                  tinted: true,
                  onTap: noop,
                ),
            ],
          ),
        ),
        HubPlayground(
          title: 'AppDetailRow',
          controls: [
            const PlayText('label', initialValue: 'Telegram'),
            const PlayText('trailing', initialValue: '@ppond'),
            const PlayText('helper', initialValue: ''),
            const PlayText('error', initialValue: ''),
            PlayChoice<String>('leading', const [
              ('icon', 'icon'),
              ('logo', 'logo'),
              ('avatar + badge', 'avatar'),
              ('none', 'none'),
            ]),
            PlayChoice<String>('valueColor', const [
              ('primary', 'primary'),
              ('muted', 'muted'),
              ('warning', 'warning'),
            ]),
            const PlayBool('valueIcon'),
            const PlayBool('locked'),
            const PlayBool('showChevron', initialValue: true),
            const PlayBool('tinted'),
            const PlayBool('comingSoon'),
          ],
          builder: (context, v) {
            String? text(String name) =>
                v<String>(name).isEmpty ? null : v<String>(name);
            final leading = v<String>('leading');
            return SectionCard(
              first: true,
              children: [
                AppDetailRow(
                  label: v<String>('label'),
                  trailing: text('trailing') == null
                      ? null
                      : Text(text('trailing')!),
                  helper: text('helper'),
                  error: text('error'),
                  icon: leading == 'icon' ? AppIcons.link : null,
                  leading: switch (leading) {
                    'logo' => const _Logo(Icons.send, _telegram),
                    'avatar' => Avatar(AvatarData.forName('Pond'), size: 32),
                    _ => null,
                  },
                  leadingSize: leading == 'icon' || leading == 'none'
                      ? null
                      : _Logo.size,
                  badge: leading == 'avatar'
                      ? const RowBadge.logo(_Logo(Icons.send, _telegram))
                      : null,
                  valueColor: switch (v<String>('valueColor')) {
                    'muted' => scheme.onSurfaceVariant,
                    'warning' => palette.warning,
                    _ => null,
                  },
                  valueIcon: v<bool>('valueIcon') ? AppIcons.link : null,
                  locked: v<bool>('locked'),
                  showChevron: v<bool>('showChevron'),
                  accent: _telegram,
                  tinted: v<bool>('tinted'),
                  comingSoon: v<bool>('comingSoon'),
                  onTap: noop,
                  onLongPress: noop,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
