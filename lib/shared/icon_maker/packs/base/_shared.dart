import '../icon_pack.dart';

/// Shared background variants used by every base pack.
///
/// Defaults are theme tokens (`@presetThemeColor*`) — they resolve through
/// the active [AppColors] palette so a freshly-picked asset matches the
/// current theme. See `lib/shared/icon_maker/color_token.dart` for the
/// resolver and supported tokens.
const commonBaseBackgrounds = <IconPackItem>[
  IconPackItem(id: 'solid', colors: ['@presetThemeColor1']),
  IconPackItem(
    id: 'superGradientA',
    colors: ['@presetThemeColor1', '@presetThemeColor2'],
  ),
  // Self-shaded radial — same hue, lighter on top-left.
  IconPackItem(
    id: 'radialGlow',
    colors: ['@presetThemeColor1Lighter', '@presetThemeColor1'],
  ),
  // 3 hard-banded diagonal stripes.
  IconPackItem(
    id: 'stripedPatternDi',
    colors: [
      '@presetThemeColor1',
      '@presetThemeColor2',
      '@presetThemeColor3',
    ],
  ),
  // Preset sweep through ROYGBIV — no user-selectable colors.
  IconPackItem(id: 'rainbow', colors: []),
];

/// Shared border variants used by every base pack.
const commonBaseBorders = <IconPackItem>[
  IconPackItem(id: 'thin', colors: ['@presetThemeColorBorder']),
  IconPackItem(id: 'thick', colors: ['@presetThemeColorBorder']),
  IconPackItem(id: 'dashed', colors: ['@presetThemeColorBorder']),
];
