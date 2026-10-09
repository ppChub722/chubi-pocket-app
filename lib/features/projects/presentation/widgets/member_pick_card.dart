import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/project.dart';
import 'project_common.dart';

/// A project member as a [PickCard] — the payer of a project row ("จ่ายโดย"),
/// with their avatar. Nothing picked → the dashed empty card. Use
/// [showMemberPicker] for the picker itself.
class MemberPickCard extends StatelessWidget {
  const MemberPickCard({
    required this.member,
    required this.label,
    required this.onTap,
    this.placeholder,
    super.key,
  });

  final ProjectMember? member;
  final String label;
  final String? placeholder;

  /// Null = fixed (e.g. the payer of a saved row).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = member;
    return PickCard(
      label: label,
      value: m?.displayName,
      placeholder: placeholder,
      leading: m == null
          ? const PickCardEmptyIcon(AppIcons.member)
          : ProjectMemberAvatar(member: m, size: 40),
      onTap: onTap,
    );
  }
}

/// Pick one of [members] (avatar + name). Null when dismissed.
Future<String?> showMemberPicker(
  BuildContext context, {
  required String title,
  required List<ProjectMember> members,
  String? selected,
}) => showOptionSheet<String>(
  context,
  title: title,
  selected: selected,
  options: [
    for (final m in members)
      SheetOption(
        value: m.id,
        label: m.displayName,
        leading: ProjectMemberAvatar(member: m, size: 28),
      ),
  ],
);
