import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// An inline question under the row it is about (0.4.0, the link's "update
/// the recurring amount too?"): the [message] and two buttons — [noLabel]
/// (outlined) and [yesLabel] (filled). Not a dialog: the answer is optional
/// and the card stays in the flow. [busy] disables both while the answer's
/// call runs; [yesLabel]'s button [submits] (off while offline).
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
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: noLabel,
                    variant: AppButtonVariant.outlined,
                    onPressed: busy ? null : onNo,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: yesLabel,
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
