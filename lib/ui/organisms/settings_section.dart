import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_switch.dart';
import '../atoms/connection_scope.dart';
import '../molecules/detail_rows.dart';

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

class SettingDropdownRow extends StatelessWidget {
  const SettingDropdownRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.leading,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? helper;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => DetailRow(
    leading: leading,
    label: label,
    helper: helper,
    onTap: onTap,
    trailing: AppChip(
      label: value,
      tone: AppChipTone.primary,
      selected: true,
      trailing: AppChipTrailing.dropdown,
      dashed: onTap != null,
      onTap: onTap,
    ),
  );
}

class SettingSwitchViewRow extends StatelessWidget {
  const SettingSwitchViewRow({
    required this.label,
    required this.value,
    this.onLongPress,
    this.caption,
    super.key,
  });

  final String label;
  final String? caption;
  final bool value;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onLongPress: onLongPress,
    child: DetailRow(
      label: label,
      helper: caption,
      trailing: IgnorePointer(
        child: AppSwitch(value: value, onChanged: (_) {}, semanticLabel: label),
      ),
    ),
  );
}

class SettingSummaryRow extends StatelessWidget {
  const SettingSummaryRow({
    required this.label,
    required this.onTap,
    this.summary,
    this.error,
    super.key,
  });

  final String label;
  final String? summary;
  final VoidCallback? onTap;

  final String? error;

  @override
  Widget build(BuildContext context) => DetailRow(
    label: label,
    onTap: onTap,
    error: error,
    showChevron: true,
    trailing: summary == null
        ? null
        : Text(summary!, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}
