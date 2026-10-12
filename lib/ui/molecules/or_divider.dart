import 'package:flutter/material.dart';

import '../atoms/app_divider.dart';
import '../tokens/app_spacing.dart';

/// "────  or  ────" between a form and the other ways to continue. [label] is the
/// word ("หรือ"); the page passes its own string.
class OrDivider extends StatelessWidget {
  const OrDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(child: AppDivider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const Expanded(child: AppDivider()),
      ],
    );
  }
}
