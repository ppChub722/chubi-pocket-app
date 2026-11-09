import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_icon_button.dart';
import '../molecules/option_menu.dart';
import '../tokens/pp_forge_icons.dart';
import '../tokens/app_spacing.dart';
import 'option_sheet.dart';

class LanguageThemeBar extends StatelessWidget {
  const LanguageThemeBar({
    required this.languages,
    required this.languageCode,
    required this.onLanguage,
    required this.dark,
    required this.onToggleTheme,
    required this.lightTooltip,
    required this.darkTooltip,
    super.key,
  });

  final Map<String, String> languages;
  final String languageCode;
  final ValueChanged<String> onLanguage;

  final bool dark;
  final VoidCallback onToggleTheme;

  final String lightTooltip;
  final String darkTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OptionMenuAnchor<String>(
          selected: languageCode,
          onSelected: onLanguage,
          options: [
            for (final e in languages.entries)
              SheetOption(value: e.key, label: e.value),
          ],
          builder: (context, toggle) => PpForgeChip(
            label: languages[languageCode] ?? languageCode,
            icon: PpForgeIcons.language,
            trailing: PpForgeChipTrailing.dropdown,
            onTap: toggle,
          ),
        ),
        const SizedBox(width: PpForgeSpacing.sm),
        PpForgeIconButton(
          icon: dark ? PpForgeIcons.lightMode : PpForgeIcons.darkMode,
          tooltip: dark ? lightTooltip : darkTooltip,
          onPressed: onToggleTheme,
        ),
      ],
    );
  }
}
