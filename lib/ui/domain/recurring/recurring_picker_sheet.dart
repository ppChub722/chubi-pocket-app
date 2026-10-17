import 'package:flutter/material.dart';

import '../../molecules/section_header.dart';
import '../../organisms/picker_sheet.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';

class RecurringPickRow {
  const RecurringPickRow({
    required this.id,
    required this.title,
    required this.leading,
    this.subtitle,
    this.amount,
    this.tone = MoneyTone.plain,
    this.trailingLabel,
  });

  final String id;
  final String title;
  final String? subtitle;
  final Widget leading;

  /// Null = no amount (show [trailingLabel] instead).
  final num? amount;
  final MoneyTone tone;
  final String? trailingLabel;
}

/// A titled group of [RecurringPickRow]s (as the BE / the wrapper grouped them;
/// the sheet never regroups or reorders).
class RecurringPickGroup {
  const RecurringPickGroup({required this.title, required this.rows});

  final String title;
  final List<RecurringPickRow> rows;
}

sealed class RecurringPickChoice {
  const RecurringPickChoice();
}

class RecurringPicked extends RecurringPickChoice {
  const RecurringPicked(this.id);

  final String id;
}

class RecurringCreateNew extends RecurringPickChoice {
  const RecurringCreateNew();
}

class RecurringPickerSheet extends StatelessWidget {
  const RecurringPickerSheet({
    required this.title,
    required this.groups,
    required this.createLabel,
    required this.emptyText,
    required this.onPicked,
    required this.onCreate,
    this.searchHint,
    this.selectedId,
    this.loading = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final String title;
  final String? searchHint;
  final List<RecurringPickGroup> groups;
  final String? selectedId;
  final String createLabel;

  final String emptyText;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final ValueChanged<String> onPicked;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PickerSheet(
      title: title,
      searchable: true,
      searchHint: searchHint,
      loading: loading,
      error: error,
      onRetry: onRetry,
      footer: PickerCreateRow(label: createLabel, onTap: onCreate),
      builder: (context, query) {
        bool match(RecurringPickRow r) =>
            query.isEmpty ||
            r.title.toLowerCase().contains(query) ||
            (r.subtitle?.toLowerCase().contains(query) ?? false);
        final visible = [
          for (final g in groups)
            (
              g.title,
              [
                for (final r in g.rows)
                  if (match(r)) r,
              ],
            ),
        ].where((g) => g.$2.isNotEmpty).toList();
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                emptyText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (groupTitle, rows) in visible) ...[
              if (visible.length > 1 || groupTitle.isNotEmpty)
                SectionHeader(title: groupTitle),
              for (final r in rows)
                PickerRow(
                  leading: r.leading,
                  title: r.title,
                  subtitle: r.subtitle,
                  selected: r.id == selectedId,
                  trailing: _trailing(context, r),
                  onTap: () => onPicked(r.id),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget? _trailing(BuildContext context, RecurringPickRow r) {
    final amount = r.amount;
    if (amount != null) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: MoneyText(amount, tone: r.tone),
      );
    }
    final label = r.trailingLabel;
    if (label == null) return null;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
