import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_chip.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.label,
    this.comingSoonLabel,
    this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;

  final String? comingSoonLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final badge = comingSoonLabel;
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        AppButton(
          label: label,
          onPressed: onPressed,
          loading: loading,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.large,
          expand: true,
        ),
        if (onPressed == null && badge != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: IgnorePointer(
              child: AppChip(
                label: badge,
                tone: AppChipTone.info,
                selected: true,
                size: ChipSize.mini,
              ),
            ),
          ),
      ],
    );
  }
}
