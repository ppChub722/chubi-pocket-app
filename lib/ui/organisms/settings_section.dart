import 'package:flutter/material.dart';

import '../atoms/app_switch.dart';
import '../atoms/connection_scope.dart';
import '../molecules/detail_rows.dart';

/// A headed settings group: [title] (the caller's string, e.g. "Settings"), a
/// one-line [description], then the rows ([SettingToggleRow] /
/// [SettingSummaryRow]) in one box.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.description,
    this.first = false,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final bool first;

  @override
  Widget build(BuildContext context) => SectionCard(
    first: first,
    title: title,
    description: description,
    children: children,
  );
}

/// A live switch row: [label] with its [caption] under it, the switch at the
/// end. [onChanged] null = disabled. A toggle that sends to the server
/// ([submits], default true) is also disabled while offline.
class SettingToggleRow extends StatelessWidget {
  const SettingToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
    this.submits = true,
    super.key,
  });

  final String label;
  final String? caption;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool submits;

  @override
  Widget build(BuildContext context) {
    final off =
        onChanged == null || (submits && ConnectionScope.isOffline(context));
    final cb = off ? null : onChanged;
    return DetailRow(
      label: label,
      helper: caption,
      onTap: cb == null ? null : () => cb(!value),
      trailing: AppSwitch(value: value, onChanged: cb, semanticLabel: label),
    );
  }
}

/// A row that opens its setting: [label] left, the current [summary] right, ›.
class SettingSummaryRow extends StatelessWidget {
  const SettingSummaryRow({
    required this.label,
    required this.onTap,
    this.summary,
    super.key,
  });

  final String label;
  final String? summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DetailRow(
    label: label,
    onTap: onTap,
    showChevron: true,
    trailing: summary == null
        ? null
        : Text(summary!, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}
