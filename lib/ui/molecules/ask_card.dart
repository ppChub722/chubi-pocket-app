import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/button_icon_kind.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class AskCard extends StatelessWidget {
  const AskCard({
    required this.message,
    required this.noLabel,
    required this.yesLabel,
    required this.onNo,
    required this.onYes,
    this.busy = false,
    super.key,
  });

  final String message;
  final String noLabel;
  final String yesLabel;
  final VoidCallback onNo;
  final VoidCallback onYes;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(PpForgeRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PpForgeSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: PpForgeSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: PpForgeButton(
                    label: noLabel,
                    kind: ButtonIconKind.cancel,
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: busy ? null : onNo,
                  ),
                ),
                const SizedBox(width: PpForgeSpacing.sm),
                Expanded(
                  child: PpForgeButton(
                    label: yesLabel,
                    kind: ButtonIconKind.confirm,
                    submits: true,
                    loading: busy,
                    onPressed: busy ? null : onYes,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
