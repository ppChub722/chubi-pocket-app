import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

// The hub's own icon types — a host app declares its own the same way.
const _demoType = PpForgeIconType(
  'demo',
  fallbackIcon: Icons.category_outlined,
  basePack: basePackCategory,
);
const _demoTagType = PpForgeIconType(
  'demoTag',
  fallbackIcon: Icons.label_outline,
  basePack: basePackTag,
  iconOnly: true,
);
const _displayOnlyType = PpForgeIconType(
  'demoDisplayOnly',
  fallbackIcon: Icons.receipt_outlined,
);

/// Theme tokens follow the active theme; hex pins a colour.
const _tokenColors = (
  c1: '@presetThemeColor1',
  c2: '@presetThemeColor2',
  c3: '@presetThemeColor3',
  border: '@presetThemeColorBorder',
);
const _hexColors = (
  c1: '#E57373',
  c2: '#64B5F6',
  c3: '#FFB74D',
  border: '#424242',
);

/// An [IconCode] from the playground's choices.
IconCode _code({
  required String icon,
  required String? background,
  required String? border,
  required IconShape shape,
  bool hex = false,
}) {
  final c = hex ? _hexColors : _tokenColors;
  final bgColors = switch (background) {
    null || 'rainbow' => const <String>[],
    'solid' => [c.c1],
    'superGradientA' => [c.c1, c.c2],
    'radialGlow' => ['${c.c1}Lighter', c.c1],
    _ => [c.c1, c.c2, c.c3], // stripedPatternDi
  };
  return IconCode(
    icon: icon,
    // On a background the glyph sits in the "on icon" colour; alone it is
    // the main colour.
    iconColors: [background == null ? c.c1 : '@presetThemeColorOnIcon'],
    background: background,
    bgColors: hex && background == 'solid' ? [c.c1] : bgColors,
    border: border,
    borderColors: border == null ? const [] : [c.border],
    shape: shape == IconShape.circle ? null : shape.name,
  );
}

/// `/dev/ui/icons/icon-maker` — the icon system: an [IconCode] (what the
/// server stores) drawn by [IconCodeWidget] / [IconDisplay], edited with
/// [showIconMakerSheet] from the packs of a [PpForgeIconType].
Widget buildIconMakerPage(BuildContext context) {
  final text = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;
  final iconMaker = PpForgeConfig.stringsOf(context).iconMaker;
  final shapeCode = _code(
    icon: 'savings',
    background: 'solid',
    border: null,
    shape: IconShape.circle,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubInApp(
        columns: 2,
        note:
            'The icon maker as the app opens it — tap Open, edit, then '
            '“Use this”: the result lands in the preview (the app saves it).',
        uses: [
          HubUse(
            label: 'full editor — icon, background, border',
            page: 'Category / account / project edit',
            child: _IconMakerTry(type: _demoType),
          ),
          HubUse(
            label: 'iconOnly type — glyph + tint',
            page: 'Tag edit',
            child: _IconMakerTry(type: _demoTagType),
          ),
          HubUse(
            label: 'recolour only (showIconPicker: false)',
            page: 'Bulk recolour of a selection',
            child: _IconMakerTry(type: _demoType, showIconPicker: false),
          ),
          HubUse(
            label: 're-icon only (showColorPicker: false)',
            page: 'Bulk re-icon of a selection',
            child: _IconMakerTry(type: _demoType, showColorPicker: false),
          ),
          HubUse(
            label: 'with “use default” (removeLabel)',
            page: 'Edit form of a thing with a custom icon',
            child: _IconMakerTry(
              type: _demoType,
              removeLabel: iconMaker.useDefault,
            ),
          ),
        ],
      ),

      HubPlayground(
        title: 'showIconMakerSheet',
        note:
            'The icon maker: pick from the type’s packs, recolour, reshape. '
            'It returns IconMakerSelected / IconMakerRemoved / null — the app '
            'saves the code. The preview below keeps the last result.',
        controls: [
          PlayChoice<PpForgeIconType>('type', [
            ('full (category pack)', _demoType),
            ('iconOnly (tag pack)', _demoTagType),
          ]),
          PlayChoice<IconMakerLayers>('layers', [
            for (final l in IconMakerLayers.values) (l.name, l),
          ]),
          const PlayBool('showIconPicker', initialValue: true),
          const PlayBool('showColorPicker', initialValue: true),
          const PlayBool('removeLabel (⋯ use default)'),
        ],
        builder: (context, v) => _IconMakerTry(
          type: v<PpForgeIconType>('type'),
          layers: v<IconMakerLayers>('layers'),
          showIconPicker: v<bool>('showIconPicker'),
          showColorPicker: v<bool>('showColorPicker'),
          removeLabel: v<bool>('removeLabel (⋯ use default)')
              ? iconMaker.useDefault
              : null,
        ),
      ),

      HubPlayground(
        title: 'IconCodeWidget',
        hug: Alignment.center,
        note:
            'Draws a stored IconCode: glyph, background pattern, border, '
            'shape. Colours are theme tokens (follow the toolbar theme) or '
            'pinned hex.',
        controls: [
          PlayChoice<String>('icon', [
            for (final id in const [
              'restaurant',
              'directions_car',
              'wallet',
              'flight',
              'home',
              'favorite',
            ])
              (id, id),
          ]),
          PlayChoice<String?>('background', [
            ('none (glyph only)', null),
            ('solid', 'solid'),
            ('superGradientA', 'superGradientA'),
            ('radialGlow', 'radialGlow'),
            ('stripedPatternDi', 'stripedPatternDi'),
            ('rainbow', 'rainbow'),
          ]),
          PlayChoice<String?>('border', [
            ('none', null),
            ('thin', 'thin'),
            ('thick', 'thick'),
            ('dashed', 'dashed'),
          ]),
          PlayChoice<IconShape>('shape', [
            for (final s in IconShape.values) (s.name, s),
          ]),
          const PlayBool('hex colours'),
          const PlayNum('size', min: 24, max: 120, step: 8, initialValue: 72),
        ],
        builder: (context, v) => IconCodeWidget(
          size: v<double>('size'),
          iconCode: _code(
            icon: v<String>('icon'),
            background: v<String?>('background'),
            border: v<String?>('border'),
            shape: v<IconShape>('shape'),
            hex: v<bool>('hex colours'),
          ),
        ),
      ),

      HubDemo(
        title: 'IconShape',
        note:
            'The background outline; the border follows it. Unknown or '
            'missing = circle, so old codes keep rendering.',
        child: HubRow(
          cells: [
            for (final s in IconShape.values)
              HubCell(
                caption: s.label(iconMaker),
                child: IconCodeWidget(
                  size: 48,
                  iconCode: shapeCode.copyWith(shape: s.name),
                ),
              ),
          ],
        ),
      ),

      HubDemo(
        title: 'Theme tokens vs hex',
        note:
            'Switch the theme in the toolbar: the token icon follows it, '
            'the hex icon stays put. resolveColor() turns either into a '
            'Color; isThemeToken() tells them apart.',
        child: HubRow(
          cells: [
            HubCell(
              caption: '@presetThemeColor1',
              child: IconCodeWidget(size: 56, iconCode: shapeCode),
            ),
            HubCell(
              caption: '#E57373',
              child: IconCodeWidget(
                size: 56,
                iconCode: _code(
                  icon: 'savings',
                  background: 'solid',
                  border: null,
                  shape: IconShape.circle,
                  hex: true,
                ),
              ),
            ),
          ],
        ),
      ),

      HubDemo(
        title: 'IconDisplay',
        note:
            'The universal icon on every screen: a code, or the type’s '
            'fallback. iconOnly types (tags) drop background + border at '
            'render time — the saved code keeps them.',
        child: HubRow(
          cells: [
            HubCell(
              caption: 'no code → fallback',
              child: IconDisplay(type: _demoType, size: 48),
            ),
            HubCell(
              caption: 'display-only type',
              child: IconDisplay(type: _displayOnlyType, size: 48),
            ),
            HubCell(
              caption: 'full type',
              child: IconDisplay(
                type: _demoType,
                size: 48,
                iconCode: shapeCode.copyWith(
                  border: 'thick',
                  borderColors: [_tokenColors.border],
                ),
              ),
            ),
            HubCell(
              caption: 'same code, iconOnly type',
              child: IconDisplay(
                type: _demoTagType,
                size: 48,
                iconCode: shapeCode.copyWith(
                  border: 'thick',
                  borderColors: [_tokenColors.border],
                ),
              ),
            ),
          ],
        ),
      ),

      HubDemo(
        title: 'BrandPalette',
        note: 'The 12 common colours (the icon maker’s “Common” row).',
        child: HubRow(
          cells: [
            for (final s in BrandPalette.all)
              HubCell(
                caption: s.id,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),

      HubDemo(
        title: 'Base packs',
        note:
            'What the icon maker offers per type (PpForgeIconType.basePack). '
            'Non-tag packs share commonBaseBackgrounds + commonBaseBorders. '
            'Extra packs: PackRegistry.registerExtra.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (name, pack) in const [
              ('basePackAccount', basePackAccount),
              ('basePackCategory', basePackCategory),
              ('basePackTag', basePackTag),
              ('basePackProject', basePackProject),
              ('basePackProjectTransaction', basePackProjectTransaction),
              ('basePackContact', basePackContact),
              ('basePackProjectMember', basePackProjectMember),
              ('basePackUserProfile', basePackUserProfile),
            ]) ...[
              Text(
                '$name — ${pack.icons.length} icons, '
                '${pack.backgrounds.length} backgrounds, '
                '${pack.borders.length} borders',
                style: text.labelLarge,
              ),
              const SizedBox(height: PpForgeSpacing.xs),
              Wrap(
                spacing: PpForgeSpacing.sm,
                runSpacing: PpForgeSpacing.sm,
                children: [
                  for (final item in pack.icons)
                    IconCodeWidget(
                      size: 32,
                      iconCode: IconCode(
                        icon: item.id,
                        iconColors: item.colors,
                        background: 'solid',
                        bgColors: const ['@presetThemeColorContainer'],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PpForgeSpacing.lg),
            ],
          ],
        ),
      ),

      HubDemo(
        title: 'IconRegistry',
        note:
            'Every stored icon id (IconRegistry.ids → IconData). Ids are '
            'saved on the server — never rename one.',
        child: Wrap(
          spacing: PpForgeSpacing.sm,
          runSpacing: PpForgeSpacing.sm,
          children: [
            for (final id in IconRegistry.ids)
              Tooltip(
                message: id,
                child: Icon(
                  IconRegistry.get(id),
                  size: 24,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// A preview + "Open" button that runs the real [showIconMakerSheet] and
/// keeps its last result.
class _IconMakerTry extends StatelessWidget {
  const _IconMakerTry({
    required this.type,
    this.layers = IconMakerLayers.all,
    this.showIconPicker = true,
    this.showColorPicker = true,
    this.removeLabel,
  });

  final PpForgeIconType type;
  final IconMakerLayers layers;
  final bool showIconPicker;
  final bool showColorPicker;
  final String? removeLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return HubStateful<IconCode?>(
      initial: null,
      builder: (context, code, set) => Column(
        children: [
          IconDisplay(type: type, size: 64, iconCode: code),
          const SizedBox(height: PpForgeSpacing.xs),
          Text(
            code == null ? 'no icon (fallback)' : '${code.toJson()}',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: PpForgeSpacing.sm),
          PpForgeButton(
            label: 'Open',
            icon: PpForgeIcons.edit,
            variant: PpForgeButtonVariant.tonal,
            // At least one picker tab must stay on.
            onPressed: !showIconPicker && !showColorPicker
                ? null
                : () async {
                    final result = await showIconMakerSheet(
                      context: context,
                      type: type,
                      initial: code,
                      showIcon: layers.icon,
                      showBackground: layers.background,
                      showBorder: layers.border,
                      showIconPicker: showIconPicker,
                      showColorPicker: showColorPicker,
                      removeLabel: removeLabel,
                    );
                    switch (result) {
                      case IconMakerSelected(:final iconCode):
                        set(iconCode);
                      case IconMakerRemoved():
                        set(null);
                      case null:
                        break;
                    }
                  },
          ),
        ],
      ),
    );
  }
}
