import 'package:flutter/material.dart';

import '../../molecules/pick_card.dart';
import '../../tokens/app/app_icons.dart';
import '../../icons/icon_code.dart';
import 'project_member_avatar.dart';

/// A project member as a [PickCard] — the payer of a project row, with their
/// avatar. [name] null → the dashed empty card. Strings come from the caller.
class ProjectMemberPickCard extends StatelessWidget {
  const ProjectMemberPickCard({
    required this.name,
    required this.label,
    required this.onTap,
    this.iconCode,
    this.placeholder,
    this.errorText,
    super.key,
  });

  /// The picked member's name; null = nobody picked.
  final String? name;
  final IconCode? iconCode;
  final String label;
  final String? placeholder;

  /// Error border + message (a save tried with nobody picked).
  final String? errorText;

  /// Null = fixed (e.g. the payer of a saved row).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => PickCard(
    label: label,
    value: name,
    placeholder: placeholder,
    leading: name == null
        ? const PickCardEmptyIcon(PpForgeIcons.member)
        : ProjectMemberAvatar(name: name!, iconCode: iconCode, size: 40),
    onTap: onTap,
    errorText: errorText,
  );
}
