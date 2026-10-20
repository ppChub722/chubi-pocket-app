import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/project.dart';

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

  final String? errorText;

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
