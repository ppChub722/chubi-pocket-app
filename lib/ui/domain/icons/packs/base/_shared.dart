import '../icon_pack.dart';

const commonBaseBackgrounds = <IconPackItem>[
  IconPackItem(id: 'solid', colors: ['@presetThemeColor1']),
  IconPackItem(
    id: 'superGradientA',
    colors: ['@presetThemeColor1', '@presetThemeColor2'],
  ),
  IconPackItem(
    id: 'radialGlow',
    colors: ['@presetThemeColor1Lighter', '@presetThemeColor1'],
  ),
  IconPackItem(
    id: 'stripedPatternDi',
    colors: ['@presetThemeColor1', '@presetThemeColor2', '@presetThemeColor3'],
  ),
  IconPackItem(id: 'rainbow', colors: []),
];

const commonBaseBorders = <IconPackItem>[
  IconPackItem(id: 'thin', colors: ['@presetThemeColorBorder']),
  IconPackItem(id: 'thick', colors: ['@presetThemeColorBorder']),
  IconPackItem(id: 'dashed', colors: ['@presetThemeColorBorder']),
];
