import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';
import 'packs/pack_registry.dart';

/// The colours of the maker's "common colours" row.
const chubiCommonColors = <String>[
  '#00A389', // brand teal
  '#F06292', // brand pink
  '#1E293B',
  '#F0F9FF',
  '#EF4444',
  '#0EA5E9',
];

PpForgeIconMakerStrings chubiIconMakerStrings(AppLocalizations l) =>
    PpForgeIconMakerStrings(
      colorWheelTitle: l.colorPickerTitle,
      colorWheelUse: l.colorPickerUse,
      cancel: l.commonCancel,
      undo: l.commonUndo,
      commonColors: l.iconMakerCommonColors,
      customColors: l.iconMakerCustomColors,
      layerOff: l.iconMakerLayerOff,
      noMatch: l.iconMakerNoMatch,
      notRecolorable: l.iconMakerNotRecolorable,
      pattern: l.iconMakerPattern,
      pickColor: l.iconMakerPickColor,
      reset: l.iconMakerReset,
      resetConfirmBody: l.iconMakerResetConfirmBody,
      resetConfirmTitle: l.iconMakerResetConfirmTitle,
      resetSlot: l.iconMakerResetSlot,
      roleBackground: l.iconMakerRoleBackground,
      roleBorder: l.iconMakerRoleBorder,
      roleIcon: l.iconMakerRoleIcon,
      searchHint: l.iconMakerSearchHint,
      shape: l.iconMakerShape,
      tabColor: l.iconMakerTabColor,
      tabStyle: l.iconMakerTabStyle,
      themeColors: l.iconMakerThemeColors,
      title: l.iconMakerTitle,
      useDefault: l.iconMakerUseDefault,
      useThis: l.iconPickerUseThis,
      all: l.transactionsRangeAll,
      shapeLabel: (s) => switch (s) {
        PpForgeIconShape.circle => l.iconShapeCircle,
        PpForgeIconShape.squircle => l.iconShapeSquircle,
        PpForgeIconShape.rounded => l.iconShapeRounded,
        PpForgeIconShape.square => l.iconShapeSquare,
        PpForgeIconShape.leaf => l.iconShapeLeaf,
        PpForgeIconShape.drop => l.iconShapeDrop,
      },
    );

Future<PpForgeIconMakerResult?> showIconMakerSheet({
  required BuildContext context,
  required IconType type,
  PpForgeIconCode? initial,
  Widget? previewSubtitle,
  Widget Function(PpForgeIconCode)? previewBuilder,
  String? title,
  String? iconSectionLabel,
  String? colorSectionLabel,
  String? useThisLabel,
  String? removeLabel,
  bool showColorSection = true,
  bool showIcon = true,
  bool showBackground = true,
  bool showBorder = true,
  bool showIconPicker = true,
  bool showColorPicker = true,
  List<String> grantedPackIds = const [],
}) {
  return showPpForgeIconMaker(
    context: context,
    packs: PackRegistry.packs(type: type, grantedPackIds: grantedPackIds),
    strings: chubiIconMakerStrings(AppLocalizations.of(context)!),
    commonColors: chubiCommonColors,
    initial: initial,
    previewSubtitle: previewSubtitle,
    previewBuilder: previewBuilder,
    title: title,
    iconSectionLabel: iconSectionLabel,
    colorSectionLabel: colorSectionLabel,
    useThisLabel: useThisLabel,
    removeLabel: removeLabel,
    showColorSection: showColorSection,
    showIcon: showIcon,
    showBackground: showBackground,
    showBorder: showBorder,
    showIconPicker: showIconPicker,
    showColorPicker: showColorPicker,
  );
}

/// True when [backgroundId] is a background of [type] with no colour of its
/// own (rainbow, snowflake, wreath, starburst): the maker has nothing to
/// recolour, so a person's profile colours 1–3 are picked separately.
bool backgroundHasNoPickableColors(IconType type, String? backgroundId) {
  if (backgroundId == null) return false;
  for (final pack in PackRegistry.packs(type: type)) {
    for (final item in pack.backgrounds) {
      if (item.id == backgroundId) return item.colors.isEmpty;
    }
  }
  return false;
}
