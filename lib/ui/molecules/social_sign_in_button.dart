import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_chip.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

/// "Continue with Google": a large outlined, full-width button. [onPressed]
/// null = not wired yet → disabled with a [comingSoonLabel] badge at its end.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.label,
    this.comingSoonLabel,
    this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;

  /// The "coming soon" badge shown while [onPressed] is null.
  final String? comingSoonLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final badge = comingSoonLabel;
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        PpForgeButton(
          label: label,
          onPressed: onPressed,
          loading: loading,
          variant: PpForgeButtonVariant.outlined,
          size: PpForgeButtonSize.large,
          expand: true,
        ),
        if (onPressed == null && badge != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: PpForgeSpacing.md),
            child: IgnorePointer(
              child: PpForgeChip(
                label: badge,
                tone: PpForgeChipTone.info,
                selected: true,
                size: ChipSize.mini,
              ),
            ),
          ),
      ],
    );
  }
}
