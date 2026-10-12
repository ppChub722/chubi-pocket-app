import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/project.dart';
import 'project_common.dart';

/// Thin wrapper over [ProjectMemberPickCard]. A project member as a [PickCard] — the payer of a project row ("จ่ายโดย"),
/// with their avatar. Nothing picked → the dashed empty card. Use
/// [showMemberPicker] for the picker itself.
class MemberPickCard extends StatelessWidget {
  const MemberPickCard({
    required this.member,
    required this.label,
    required this.onTap,
    this.placeholder,
    this.errorText,
    super.key,
  });

  final ProjectMember? member;
  final String label;
  final String? placeholder;

  /// Error border + message (a save tried with nobody picked).
  final String? errorText;

  /// Null = fixed (e.g. the payer of a saved row).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ProjectMemberPickCard(
    name: member?.displayName,
    iconCode: member?.iconCode,
    label: label,
    placeholder: placeholder,
    errorText: errorText,
    onTap: onTap,
  );
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
        leading: memberAvatar(m, size: 28),
      ),
  ],
);
