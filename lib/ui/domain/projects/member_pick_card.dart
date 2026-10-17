import 'package:flutter/material.dart';

import '../../molecules/pick_card.dart';
import '../../tokens/app/app_icons.dart';
import '../icons/icon_code.dart';
import 'project_member_avatar.dart';

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

  final String? name;
  final IconCode? iconCode;
  final String label;
  final String? placeholder;

  final String? errorText;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => PickCard(
    label: label,
    value: name,
    placeholder: placeholder,
    leading: name == null
        ? const PickCardEmptyIcon(AppIcons.member)
        : ProjectMemberAvatar(name: name!, iconCode: iconCode, size: 40),
    onTap: onTap,
    errorText: errorText,
  );
}
