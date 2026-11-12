import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

/// How a page wants the shell's centre create button to look: its word,
/// colour and icon. A page that gives none gets the plain "บันทึก" button.
@immutable
class QuickCreateLook {
  const QuickCreateLook({required this.word, required this.color, this.icon});

  /// The debt pages' button (จดหนี้, the debt colour, the debt icon).
  factory QuickCreateLook.debt(BuildContext context) => QuickCreateLook(
    word: AppLocalizations.of(context)!.quickCreateBtnDebt,
    color: QuickCreateModeColors.of(context, QuickCreateMode.debt),
    icon: quickCreateModeIcon(QuickCreateMode.debt),
  );

  /// The saving pages' button (ออมเงิน, the saving colour, the saving icon).
  factory QuickCreateLook.saving(BuildContext context) => QuickCreateLook(
    word: AppLocalizations.of(context)!.quickCreateBtnSaving,
    color: QuickCreateModeColors.of(context, QuickCreateMode.saving),
    icon: quickCreateModeIcon(QuickCreateMode.saving),
  );

  /// A list page's button (owner 2026-11-12): "เพิ่ม" in its module's
  /// [color] and [icon]; it goes to that module's create page.
  factory QuickCreateLook.add(
    BuildContext context, {
    required Color color,
    required IconData icon,
  }) => QuickCreateLook(
    word: AppLocalizations.of(context)!.quickCreateBtnAdd,
    color: color,
    icon: icon,
  );

  final String word;
  final Color color;
  final IconData? icon;
}
