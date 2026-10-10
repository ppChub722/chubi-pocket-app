import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// The very bottom of a detail page: small muted record info, one item
/// per line (owner 2026-10-10, the transaction detail) —
///
///   บันทึกโดย มิ้นท์
///   บันทึกเมื่อ 10 ต.ค. 2026 14:05
///   แก้ไขล่าสุด 11 ต.ค. 2026 09:12
///
/// Empty [lines] render nothing.
class DetailMeta extends StatelessWidget {
  const DetailMeta({required this.lines, super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Text(
        lines.join('\n'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
