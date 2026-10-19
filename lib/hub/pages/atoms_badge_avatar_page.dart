import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/atoms/badge-avatar` — badge, avatars, corner badge, icon bubble.
Widget buildBadgeAvatarPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  List<(String, Color)> colors() => [
    ('primary', scheme.primary),
    ('tertiary', scheme.tertiary),
    ('error', scheme.error),
  ];
  const framed = IconCode(
    icon: 'person',
    background: 'solid',
    bgColors: ['#26A69A'],
    border: 'thin',
    borderColors: ['#00796B'],
  );
  Widget left(Widget child) =>
      Align(alignment: Alignment.centerLeft, child: child);
  Widget wrap(List<Widget> children) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubInApp(
        columns: 2,
        note:
            'Every real combination side by side, each with the page that '
            'uses it.',
        uses: [
          HubUse(
            label: 'AppBadge — allocation %',
            page: 'Saving goals list',
            child: left(const AppBadge(label: '62%')),
          ),
          HubUse(
            label: 'AppBadge — every tone',
            page: 'Roles, "no wallet"',
            child: wrap([
              for (final t in Tone.values) AppBadge(label: t.name, tone: t),
            ]),
          ),
          const HubUse(
            label: 'AppBadge — with icon',
            page: 'Counts, tags',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppBadge(label: '3', icon: Icons.sell_outlined),
                AppBadge(label: 'linked', icon: Icons.link, tone: Tone.primary),
              ],
            ),
          ),
          HubUse(
            label: 'AppAvatar — initials (hashed colour)',
            page: 'Contacts, wallet members',
            child: wrap(const [
              AppAvatar(name: 'Aom Chan'),
              AppAvatar(name: 'Bee'),
              AppAvatar(name: 'Dao Ploy'),
            ]),
          ),
          HubUse(
            label: 'AppAvatar — empty name (neutral person)',
            page: 'Unnamed contact',
            child: left(const AppAvatar(name: '')),
          ),
          HubUse(
            label: 'AppAvatar.tinted — each colour',
            page: 'Projects (member marks)',
            child: wrap([
              for (final (_, c) in colors())
                AppAvatar.tinted(name: 'Bee', color: c),
            ]),
          ),
          HubUse(
            label: 'AppAvatar.label — "+N" overflow',
            page: 'Wallet member stack',
            child: left(const AppAvatar.label('+3', size: 32)),
          ),
          HubUse(
            label: 'AppAvatar.icon — a glyph',
            page: 'Generic person',
            child: left(AppAvatar.icon(AppIcons.profile)),
          ),
          HubUse(
            label: 'UserAvatar — initials fallback',
            page: 'Profile, members',
            child: left(const UserAvatar(displayName: 'Aom Chan')),
          ),
          HubUse(
            label: 'UserAvatar — icon maker',
            page: 'Profile, members',
            child: left(
              const UserAvatar(displayName: 'Aom Chan', iconCode: framed),
            ),
          ),
          HubUse(
            label: 'IconTile — circle | soft',
            page: 'List rows',
            child: wrap([
              for (final (_, c) in colors())
                IconTile(icon: AppIcons.income, color: c),
            ]),
          ),
          HubUse(
            label: 'IconTile — rounded | solid',
            page: 'More hub, dashboard tiles',
            child: wrap([
              for (final (_, c) in colors())
                IconTile(
                  icon: AppIcons.budget,
                  color: c,
                  size: 40,
                  shape: IconTileShape.rounded,
                  style: IconTileStyle.solid,
                ),
            ]),
          ),
          HubUse(
            label: 'IconTile — with a corner badge',
            page: 'Pending, project transactions',
            child: left(
              IconTile(
                icon: AppIcons.budget,
                color: scheme.primary,
                size: 40,
                badgeIcon: AppIcons.link,
              ),
            ),
          ),
          HubUse(
            label: 'CornerBadge — type / link mark (40)',
            page: 'Notifications, project transactions, account card',
            child: left(
              const CornerBadge(
                size: 40,
                icon: AppIcons.link,
                child: AppAvatar(name: 'Bee'),
              ),
            ),
          ),
          HubUse(
            label: 'CornerBadge — 64, tertiary',
            page: 'Account card',
            child: left(
              CornerBadge(
                size: 64,
                icon: AppIcons.link,
                color: scheme.tertiary,
                child: const AppAvatar(name: 'Bee', size: 64),
              ),
            ),
          ),
          HubUse(
            label: 'CornerBadge — under 40 (hidden)',
            page: 'Dense lists',
            child: left(
              const CornerBadge(
                size: 32,
                icon: AppIcons.link,
                child: AppAvatar(name: 'Bee', size: 32),
              ),
            ),
          ),
          HubUse(
            label: 'CornerBadge — show off (same footprint)',
            page: 'Unlinked rows',
            child: left(
              const CornerBadge(
                size: 40,
                icon: AppIcons.link,
                show: false,
                child: AppAvatar(name: 'Bee'),
              ),
            ),
          ),
          HubUse(
            label: 'EditableCircle — tap to change the icon',
            page: 'Category, contact, project, goal, profile, tag forms',
            child: left(
              EditableCircle(
                size: 48,
                onTap: () {},
                child: const AppAvatar(name: 'Bee', size: 48),
              ),
            ),
          ),
          HubUse(
            label: 'EditableCircle — 64, onTap off',
            page: 'Read-only form',
            child: left(
              const EditableCircle(
                size: 64,
                child: AppAvatar(name: 'Bee', size: 64),
              ),
            ),
          ),
        ],
      ),
      const HubSubheading(
        'In the app / size ladder',
        note:
            'The frame thickness and the frame-to-glyph padding scale with the '
            'size (AvatarMetrics): the smaller the avatar, the larger the '
            'glyph relative to it. Every framed avatar uses the ladder '
            '20 | 24 | 32 | 40 | 48 | 64.',
      ),
      const _Ladder(),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          'Icon Maker avatars — the hard cases',
          style: text.titleMedium,
        ),
      ),
      Text(
        'Custom frames, every shape, gradients and low-contrast colours at '
        '20 → 64, each without and with a corner badge (the badge only '
        'appears from 40 up). Judge whether the frame, the glyph and the '
        'shape hold up as the size drops.',
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.md),
      const _HardLadder(),
      const SizedBox(height: AppSpacing.xl),
      HubPlayground(
        title: 'AppBadge',
        note:
            'A small rectangular label — roles, counts, "no wallet". Quieter '
            'than a status chip. Status words use AppChip, not a badge.',
        controls: [
          PlayChoice<Tone>('tone', [for (final t in Tone.values) (t.name, t)]),
          const PlayText('label', initialValue: 'badge'),
          const PlayBool('icon'),
        ],
        builder: (context, v) => left(
          AppBadge(
            label: v<String>('label'),
            tone: v<Tone>('tone'),
            icon: v<bool>('icon') ? Icons.sell_outlined : null,
          ),
        ),
      ),
      HubPlayground(
        title: 'AppAvatar',
        note:
            'The one round avatar. initials = first letters of two words on a '
            'hashed colour (empty name = neutral person); tinted = first '
            'letter on a 28% wash of color; icon = a glyph; label = short text.',
        controls: [
          PlayChoice<String>('mode', [
            for (final m in const ['initials', 'tinted', 'icon', 'label'])
              (m, m),
          ]),
          const PlayText('name', initialValue: 'Aom Chan'),
          PlayChoice<Color>('color', colors()),
          const PlayNum('size', min: 16, max: 80, step: 4, initialValue: 40),
        ],
        builder: (context, v) {
          final size = v<double>('size');
          final name = v<String>('name');
          return left(switch (v<String>('mode')) {
            'tinted' => AppAvatar.tinted(
              name: name,
              color: v<Color>('color'),
              size: size,
            ),
            'icon' => AppAvatar.icon(AppIcons.profile, size: size),
            'label' => AppAvatar.label(name.isEmpty ? '+3' : name, size: size),
            _ => AppAvatar(name: name, size: size),
          });
        },
      ),
      HubPlayground(
        title: 'UserAvatar',
        note:
            "A user's avatar: their chosen icon (icon maker) or, without "
            'one, an AppAvatar of their initials.',
        controls: const [
          PlayText('displayName', initialValue: 'Aom Chan'),
          PlayBool('iconCode'),
          PlayNum('size', min: 16, max: 80, step: 4, initialValue: 40),
        ],
        builder: (context, v) => left(
          UserAvatar(
            displayName: v<String>('displayName'),
            iconCode: v<bool>('iconCode') ? framed : null,
            size: v<double>('size'),
          ),
        ),
      ),
      HubPlayground(
        title: 'IconTile',
        note:
            'A glyph in a coloured shape. circle + soft = the quiet list-row '
            'glyph; rounded + solid = the loud head of a tinted card. '
            'badgeIcon adds a CornerBadge (only from 40 up).',
        controls: [
          PlayChoice<IconTileShape>('shape', [
            for (final s in IconTileShape.values) (s.name, s),
          ]),
          PlayChoice<IconTileStyle>('style', [
            for (final s in IconTileStyle.values) (s.name, s),
          ]),
          PlayChoice<Color>('color', colors()),
          const PlayBool('badgeIcon'),
          const PlayNum('size', min: 16, max: 80, step: 4, initialValue: 40),
        ],
        builder: (context, v) => left(
          IconTile(
            icon: AppIcons.budget,
            color: v<Color>('color'),
            size: v<double>('size'),
            shape: v<IconTileShape>('shape'),
            style: v<IconTileStyle>('style'),
            badgeIcon: v<bool>('badgeIcon') ? AppIcons.link : null,
          ),
        ),
      ),
      HubPlayground(
        title: 'CornerBadge',
        note:
            "The round badge on an avatar's bottom-right corner. Scales with "
            'size; hidden under 40 unless essential; show off keeps the '
            'footprint.',
        controls: [
          const PlayNum('size', min: 16, max: 80, step: 4, initialValue: 48),
          const PlayBool('show', initialValue: true),
          const PlayBool('essential'),
          PlayChoice<Color?>('color', [
            ('primary (default)', null),
            ('tertiary', scheme.tertiary),
            ('error', scheme.error),
          ]),
        ],
        builder: (context, v) {
          final size = v<double>('size');
          return left(
            CornerBadge(
              size: size,
              icon: AppIcons.link,
              show: v<bool>('show'),
              essential: v<bool>('essential'),
              color: v<Color?>('color'),
              child: AppAvatar(name: 'Bee', size: size),
            ),
          );
        },
      ),
      HubPlayground(
        title: 'EditableCircle',
        note:
            'A tappable circle with the pencil badge. Never below 40; with '
            'onTap off it renders the child as-is with the same footprint.',
        controls: const [
          PlayNum('size', min: 40, max: 96, step: 8, initialValue: 56),
          PlayBool('onTap', initialValue: true),
        ],
        builder: (context, v) {
          final size = v<double>('size');
          return left(
            EditableCircle(
              size: size,
              onTap: v<bool>('onTap') ? () {} : null,
              child: AppAvatar(name: 'Bee', size: size),
            ),
          );
        },
      ),
    ],
  );
}

const _sizes = [20.0, 24.0, 32.0, 40.0, 48.0, 64.0];

class _Ladder extends StatelessWidget {
  const _Ladder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const framed = IconCode(
      icon: 'person',
      background: 'solid',
      bgColors: ['#26A69A'],
      border: 'thin',
      borderColors: ['#00796B'],
    );
    Widget row(
      String name,
      Widget Function(double s) build, {
      List<double> sizes = _sizes,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (final s in sizes)
                HubCell(caption: '${s.round()}', child: build(s)),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          'AppAvatar — initials',
          (s) => AppAvatar(name: 'Aom Chan', size: s),
        ),
        row(
          'AppAvatar.tinted',
          (s) => AppAvatar.tinted(name: 'Bee', color: scheme.primary, size: s),
        ),
        row('AppAvatar.icon', (s) => AppAvatar.icon(AppIcons.profile, size: s)),
        row('AppAvatar.label', (s) => AppAvatar.label('+3', size: s)),
        row(
          'UserAvatar — icon maker (frame + glyph)',
          (s) => UserAvatar(displayName: 'Bee', iconCode: framed, size: s),
        ),
        row(
          'IconTile — circle | soft',
          (s) =>
              IconTile(icon: AppIcons.income, color: scheme.primary, size: s),
        ),
        row(
          'IconTile — rounded | solid',
          (s) => IconTile(
            icon: AppIcons.budget,
            color: scheme.tertiary,
            size: s,
            shape: IconTileShape.rounded,
            style: IconTileStyle.solid,
          ),
        ),
        row(
          'PersonMark — contact',
          (s) => PersonMark(name: 'Bee', level: PersonLevel.contact, size: s),
        ),
        row(
          'CornerBadge — 🔗 (hidden below 40)',
          (s) => CornerBadge(
            size: s,
            icon: AppIcons.link,
            child: AppAvatar(name: 'Bee', size: s),
          ),
        ),
        row(
          'EditableCircle — pencil badge (never below 40)',
          (s) => EditableCircle(
            size: s,
            onTap: () {},
            child: AppAvatar(name: 'Bee', size: s),
          ),
          sizes: const [40.0, 48.0, 64.0],
        ),
      ],
    );
  }
}

IconCode _ic({
  String? icon = 'person',
  String? background = 'solid',
  List<String> bg = const ['#26A69A'],
  List<String> fg = const ['#FFFFFF'],
  String? border,
  List<String> borderColors = const [],
  String? shape,
}) => IconCode(
  icon: icon,
  iconColors: fg,
  background: background,
  bgColors: bg,
  border: border,
  borderColors: borderColors,
  shape: shape,
);

/// The Icon Maker hard cases (frames, shapes, gradients, low contrast) —
/// shared with the Button page's profile-chip demo.
final List<(String, IconCode)> hubHardAvatarCases = _HardLadder._cases;

class _HardLadder extends StatelessWidget {
  const _HardLadder();

  static final _cases = <(String, IconCode)>[
    ('thin frame', _ic(border: 'thin', borderColors: ['#00695C'])),
    ('thick frame', _ic(border: 'thick', borderColors: ['#00695C'])),
    (
      'frame, no background (ring + glyph)',
      _ic(
        background: null,
        bg: const [],
        fg: const ['#00695C'],
        border: 'thick',
        borderColors: ['#00695C'],
      ),
    ),
    (
      'glyph only (no background, no frame)',
      _ic(background: null, bg: const [], fg: const ['#00695C']),
    ),
    ('squircle', _ic(shape: 'squircle')),
    ('rounded', _ic(shape: 'rounded')),
    ('square', _ic(shape: 'square')),
    (
      'leaf + frame',
      _ic(shape: 'leaf', border: 'thick', borderColors: ['#00695C']),
    ),
    (
      'drop + frame',
      _ic(shape: 'drop', border: 'thin', borderColors: ['#00695C']),
    ),
    (
      'gradient (2 colours)',
      _ic(background: 'superGradientA', bg: const ['#FF7043', '#8E24AA']),
    ),
    (
      'radial glow + squircle',
      _ic(
        background: 'radialGlow',
        bg: const ['#FFEE58', '#E53935'],
        shape: 'squircle',
      ),
    ),
    (
      'stripes (3 colours) + frame',
      _ic(
        background: 'stripedPatternDi',
        bg: const ['#EF5350', '#FFFFFF', '#42A5F5'],
        fg: const ['#212121'],
        border: 'thick',
        borderColors: ['#212121'],
      ),
    ),
    ('rainbow', _ic(background: 'rainbow')),
    (
      'low contrast — white on yellow',
      _ic(bg: const ['#FFEE58'], fg: const ['#FFFFFF']),
    ),
    (
      'low contrast — grey on grey + frame',
      _ic(
        bg: const ['#BDBDBD'],
        fg: const ['#9E9E9E'],
        border: 'thin',
        borderColors: ['#9E9E9E'],
      ),
    ),
    (
      'no glyph (background only)',
      _ic(icon: null, border: 'thick', borderColors: ['#00695C']),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget strip(IconCode code, {required bool badge}) => Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final s in _sizes)
          HubCell(
            caption: '${s.round()}',
            child: badge
                ? CornerBadge(
                    size: s,
                    icon: AppIcons.link,
                    child: UserAvatar(
                      displayName: 'Bee',
                      iconCode: code,
                      size: s,
                    ),
                  )
                : UserAvatar(displayName: 'Bee', iconCode: code, size: s),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, code) in _cases)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                strip(code, badge: false),
                const SizedBox(height: AppSpacing.sm),
                strip(code, badge: true),
              ],
            ),
          ),
      ],
    );
  }
}
