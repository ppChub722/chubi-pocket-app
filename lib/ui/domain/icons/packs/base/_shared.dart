import 'package:pp_forge_core/ui.dart';

const commonBaseBackgrounds = <PpForgeIconPackItem>[
  PpForgeIconPackItem(id: 'solid', colors: ['@presetThemeColor1']),
  PpForgeIconPackItem(
    id: 'superGradientA',
    colors: ['@presetThemeColor1', '@presetThemeColor2'],
  ),
  PpForgeIconPackItem(
    id: 'radialGlow',
    colors: ['@presetThemeColor1Lighter', '@presetThemeColor1'],
  ),
  PpForgeIconPackItem(
    id: 'stripedPatternDi',
    colors: ['@presetThemeColor1', '@presetThemeColor2', '@presetThemeColor3'],
  ),
  PpForgeIconPackItem(id: 'rainbow', colors: []),
];

const commonBaseBorders = <PpForgeIconPackItem>[
  PpForgeIconPackItem(id: 'thin', colors: ['@presetThemeColorBorder']),
  PpForgeIconPackItem(id: 'thick', colors: ['@presetThemeColorBorder']),
  PpForgeIconPackItem(id: 'dashed', colors: ['@presetThemeColorBorder']),
];
