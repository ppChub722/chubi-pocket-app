import 'package:flutter/material.dart';

import '../../molecules/app_list_row.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/tone.dart';

/// One จัดการ line of an event: [fromName] owes [toName] [amount]. A line
/// with me in it ([mine]) has [onRecord] (จดเป็นหนี้) and, once recorded,
/// [recordedLabel]; the others are dimmed.
class SettleRow extends StatelessWidget {
  const SettleRow({
    required this.fromAvatar,
    required this.fromName,
    required this.toAvatar,
    required this.toName,
    required this.amount,
    this.mine = false,
    this.recordedLabel,
    this.onRecord,
    this.recordTooltip,
    this.onTap,
    super.key,
  });

  /// 32 px, the row's leading.
  final Widget fromAvatar;
  final String fromName;

  /// About 20 px, before [toName].
  final Widget toAvatar;
  final String toName;
  final Widget amount;
  final bool mine;
  final String? recordedLabel;
  final VoidCallback? onRecord;
  final String? recordTooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final recorded = recordedLabel;
    return AppListRow(
      leading: fromAvatar,
      titleField: Row(
        children: [
          Flexible(
            child: Text(
              fromName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(AppIcons.arrowForward, size: 16, color: muted),
          ),
          toAvatar,
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              toName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
      line2: recorded == null
          ? null
          : ListRowLine(
              lead: ListRowChip(
                recorded,
                icon: AppIcons.check,
                tone: Tone.success,
              ),
            ),
      trailing: ListRowTrailing.value(amount),
      actions: [
        if (onRecord != null)
          ListRowAction.button(
            AppIcons.bookIn,
            tooltip: recordTooltip,
            onTap: onRecord,
          ),
      ],
      dimmed: !mine,
      onTap: onTap,
    );
  }
}
