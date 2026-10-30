import 'package:flutter/material.dart';

import '../../atoms/app_badge.dart';
import '../../atoms/app_radio_mark.dart';
import '../../atoms/ui_config.dart';
import '../../molecules/app_row.dart';
import '../../molecules/detail_rows.dart';

/// One place a profile picture can come from (0.4.2 1b): the edit page's
/// "รูปโปรไฟล์" radio list (ไอคอน · อัปโหลดเอง · one row per linked app)
/// and the connection page's `รูปจาก <App>` row. [selected] null = no radio.
/// [thumb] = a 36 px picture; [actions] = small buttons at the end (แก้ /
/// อัปเดต / ลบ), whose taps never pick the row. [comingSoon] = muted, no
/// taps, the "coming soon" badge.
class AvatarSourceRow extends StatelessWidget {
  const AvatarSourceRow({
    required this.title,
    this.subtitle,
    this.thumb,
    this.selected,
    this.actions = const [],
    this.comingSoon = false,
    this.onTap,
    super.key,
  });

  static const double thumbSize = 36;

  final String title;
  final String? subtitle;
  final Widget? thumb;
  final bool? selected;
  final List<Widget> actions;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final selected = this.selected;
    final subtitle = this.subtitle;
    return AppRow(
      density: AppRowDensity.detail,
      selector: selected == null
          ? null
          : AppRadioMark(selected: selected, enabled: !comingSoon),
      leading: thumb,
      leadingSize: thumb == null ? null : thumbSize,
      title: Text(title, style: detailLabelStyle(context)),
      subtitle: subtitle == null || subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
      trailing: comingSoon
          ? AppBadge(label: UiConfig.stringsOf(context).comingSoon)
          : null,
      actions: comingSoon ? const [] : actions,
      disabled: comingSoon,
      onTap: comingSoon ? null : onTap,
    );
  }
}
