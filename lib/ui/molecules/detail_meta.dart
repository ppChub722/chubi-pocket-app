import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../atoms/ui_config.dart';
import '../tokens/app_spacing.dart';

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
      padding: const EdgeInsets.only(top: PpForgeSpacing.xl),
      child: Text(
        lines.join('\n'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The record-info lines for a detail page — `บันทึกเมื่อ …` and, when it was
/// edited after it was made, `แก้ไขล่าสุด …` (the same wording as the
/// transaction detail). Pass them to [DetailMeta]; null dates leave a line
/// out.
List<String> detailMetaLines(
  BuildContext context, {
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final l = PpForgeConfig.stringsOf(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  String stamp(DateTime d) =>
      '${DateFormat.yMMMd(locale).format(d)} ${DateFormat.jm(locale).format(d)}';
  final edited =
      createdAt != null &&
      updatedAt != null &&
      updatedAt.difference(createdAt).inSeconds.abs() >= 60;
  return [
    if (createdAt != null) '${l.recordCreated} ${stamp(createdAt)}',
    if (edited) '${l.recordUpdated} ${stamp(updatedAt)}',
  ];
}
