import 'package:flutter/material.dart';

import '../atoms/ui_config.dart';
import '../tokens/app_spacing.dart';
import '../../core/utils/date_formatter.dart';

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

List<String> detailMetaLines(
  BuildContext context, {
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final l = UiConfig.stringsOf(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  String stamp(DateTime d) =>
      '${DateFormatter.medium(d, locale: locale)} '
      '${DateFormatter.time(d, locale: locale)}';
  final edited =
      createdAt != null &&
      updatedAt != null &&
      updatedAt.difference(createdAt).inSeconds.abs() >= 60;
  return [
    if (createdAt != null) '${l.recordCreated} ${stamp(createdAt)}',
    if (edited) '${l.recordUpdated} ${stamp(updatedAt)}',
  ];
}
