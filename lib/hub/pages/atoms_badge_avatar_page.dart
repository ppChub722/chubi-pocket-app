import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'package:pp_forge_core/hub.dart';
import 'avatar_states_demo.dart';

/// `/dev/atoms/badge-avatar` — badge, avatars, corner badge, icon bubble.
Widget buildBadgeAvatarPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  List<(String, Color)> colors() => [
    ('primary', scheme.primary),
    ('tertiary', scheme.tertiary),
    ('error', scheme.error),
  ];
  const framed = PpForgeIconCode(
    icon: 'person',
    background: 'solid',
    bgColors: ['#26A69A'],
    border: 'thin',
    borderColors: ['#00796B'],
  );
  Widget left(Widget child) =>
      Align(alignment: Alignment.centerLeft, child: child);
  Widget wrap(List<Widget> children) => Wrap(
    spacing: PpForgeSpacing.sm,
    runSpacing: PpForgeSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      buildAvatarStates(context),
      HubInApp(
        columns: 2,
        note:
            'Every real combination side by side, each with the page that '
            'uses it.',
        uses: [
          HubUse(
            label: 'PpForgeBadge — allocation %',
            page: 'Saving goals list',
            child: left(const PpForgeBadge(label: '62%')),
          ),
          HubUse(
            label: 'PpForgeBadge — every tone',
            page: 'Roles, "no wallet"',
            child: wrap([
              for (final t in Tone.values) PpForgeBadge(label: t.name, tone: t),
            ]),
          ),
          const HubUse(
            label: 'PpForgeBadge — with icon',
            page: 'Counts, tags',
            child: Wrap(
              spacing: PpForgeSpacing.sm,
              runSpacing: PpForgeSpacing.sm,
              children: [
                PpForgeBadge(label: '3', icon: Icons.sell_outlined),
                PpForgeBadge(label: 'linked', icon: Icons.link, tone: Tone.primary),
              ],
            ),
          ),
          HubUse(
            label: 'PpForgeAvatar — initials (hashed colour)',
            page: 'Contacts, wallet members',
            child: wrap(const [
              PpForgeAvatar(name: 'Aom Chan'),
              PpForgeAvatar(name: 'Bee'),
              PpForgeAvatar(name: 'Dao Ploy'),
            ]),
          ),
          HubUse(
            label: 'PpForgeAvatar — empty name (neutral person)',
            page: 'Unnamed contact',
            child: left(const PpForgeAvatar(name: '')),
          ),
          HubUse(
            label: 'PpForgeAvatar.tinted — each colour',
            page: 'Projects (member marks)',
            child: wrap([
              for (final (_, c) in colors())
                PpForgeAvatar.tinted(name: 'Bee', color: c),
            ]),
          ),
          HubUse(
            label: 'PpForgeAvatar.label — "+N" overflow',
            page: 'Wallet member stack',
            child: left(const PpForgeAvatar.label('+3', size: 32)),
          ),
          HubUse(
            label: 'PpForgeAvatar.icon — a glyph',
            page: 'Generic person',
            child: left(PpForgeAvatar.icon(AppIcons.profile)),
          ),
          HubUse(
            label: 'Avatar — initials fallback',
            page: 'Profile, members',
            child: left(Avatar(AvatarData.forName('Aom Chan'))),
          ),
          HubUse(
            label: 'Avatar — icon maker',
            page: 'Profile, members',
            child: left(
              Avatar(AvatarData.forName('Aom Chan', iconCode: framed)),
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
            label: 'IconTile — solid circle, set glyph size',
            page: 'Contact detail (linked account mark)',
            child: left(
              IconTile(
                icon: AppIcons.link,
                color: scheme.primary,
                size: 28,
                glyphSize: 16,
                style: IconTileStyle.solid,
              ),
            ),
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
                child: PpForgeAvatar(name: 'Bee'),
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
                child: const PpForgeAvatar(name: 'Bee', size: 64),
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
                child: PpForgeAvatar(name: 'Bee', size: 32),
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
                child: PpForgeAvatar(name: 'Bee'),
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
                child: const PpForgeAvatar(name: 'Bee', size: 48),
              ),
            ),
          ),
          HubUse(
            label: 'EditableCircle — 64, onTap off',
            page: 'Read-only form',
            child: left(
              const EditableCircle(
                size: 64,
                child: PpForgeAvatar(name: 'Bee', size: 64),
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
        padding: const EdgeInsets.only(top: PpForgeSpacing.md),
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
      const SizedBox(height: PpForgeSpacing.md),
      const _HardLadder(),
      const SizedBox(height: PpForgeSpacing.xl),
      HubPlayground(
        title: 'PpForgeBadge',
        note:
            'A small rectangular label — roles, counts, "no wallet". Quieter '
            'than a status chip. Status words use PpForgeChip, not a badge.',
        controls: [
          PlayChoice<Tone>('tone', [for (final t in Tone.values) (t.name, t)]),
          const PlayText('label', initialValue: 'badge'),
          const PlayBool('icon'),
        ],
        builder: (context, v) => left(
          PpForgeBadge(
            label: v<String>('label'),
            tone: v<Tone>('tone'),
            icon: v<bool>('icon') ? Icons.sell_outlined : null,
          ),
        ),
      ),
      HubPlayground(
        title: 'PpForgeAvatar',
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
            'tinted' => PpForgeAvatar.tinted(
              name: name,
              color: v<Color>('color'),
              size: size,
            ),
            'icon' => PpForgeAvatar.icon(AppIcons.profile, size: size),
            'label' => PpForgeAvatar.label(name.isEmpty ? '+3' : name, size: size),
            _ => PpForgeAvatar(name: name, size: size),
          });
        },
      ),
      HubPlayground(
        title: 'Avatar (forName)',
        note:
            "A user's avatar: their chosen icon (icon maker) or, without "
            'one, an PpForgeAvatar of their initials.',
        controls: const [
          PlayText('displayName', initialValue: 'Aom Chan'),
          PlayBool('iconCode'),
          PlayNum('size', min: 16, max: 80, step: 4, initialValue: 40),
        ],
        builder: (context, v) => left(
          Avatar(
            AvatarData.forName(
              v<String>('displayName'),
              iconCode: v<bool>('iconCode') ? framed : null,
            ),
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
              child: PpForgeAvatar(name: 'Bee', size: size),
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
              child: PpForgeAvatar(name: 'Bee', size: size),
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
    const framed = PpForgeIconCode(
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
      padding: const EdgeInsets.only(bottom: PpForgeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: PpForgeSpacing.xs),
          Wrap(
            spacing: PpForgeSpacing.md,
            runSpacing: PpForgeSpacing.sm,
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
          'PpForgeAvatar — initials',
          (s) => PpForgeAvatar(name: 'Aom Chan', size: s),
        ),
        row(
          'PpForgeAvatar.tinted',
          (s) => PpForgeAvatar.tinted(name: 'Bee', color: scheme.primary, size: s),
        ),
        row('PpForgeAvatar.icon', (s) => PpForgeAvatar.icon(AppIcons.profile, size: s)),
        row('PpForgeAvatar.label', (s) => PpForgeAvatar.label('+3', size: s)),
        row(
          'Avatar — icon maker (frame + glyph)',
          (s) => Avatar(AvatarData.forName('Bee', iconCode: framed), size: s),
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
            child: PpForgeAvatar(name: 'Bee', size: s),
          ),
        ),
        row(
          'EditableCircle — pencil badge (never below 40)',
          (s) => EditableCircle(
            size: s,
            onTap: () {},
            child: PpForgeAvatar(name: 'Bee', size: s),
          ),
          sizes: const [40.0, 48.0, 64.0],
        ),
      ],
    );
  }
}

PpForgeIconCode _ic({
  String? icon = 'person',
  String? background = 'solid',
  List<String> bg = const ['#26A69A'],
  List<String> fg = const ['#FFFFFF'],
  String? border,
  List<String> borderColors = const [],
  String? shape,
}) => PpForgeIconCode(
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
final List<(String, PpForgeIconCode)> hubHardAvatarCases = _HardLadder._cases;

class _HardLadder extends StatelessWidget {
  const _HardLadder();

  static final _cases = <(String, PpForgeIconCode)>[
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
    Widget strip(PpForgeIconCode code, {required bool badge}) => Wrap(
      spacing: PpForgeSpacing.md,
      runSpacing: PpForgeSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final s in _sizes)
          HubCell(
            caption: '${s.round()}',
            child: badge
                ? CornerBadge(
                    size: s,
                    icon: AppIcons.link,
                    child: Avatar(
                      AvatarData.forName('Bee', iconCode: code),
                      size: s,
                    ),
                  )
                : Avatar(AvatarData.forName('Bee', iconCode: code), size: s),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, code) in _cases)
          Padding(
            padding: const EdgeInsets.only(bottom: PpForgeSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PpForgeSpacing.xs),
                strip(code, badge: false),
                const SizedBox(height: PpForgeSpacing.sm),
                strip(code, badge: true),
              ],
            ),
          ),
      ],
    );
  }
}
