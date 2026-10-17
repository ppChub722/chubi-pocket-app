import 'package:flutter/material.dart';

import '../icons/icon_code.dart';
import '../people/person_mark.dart';

class ProjectMemberAvatar extends StatelessWidget {
  const ProjectMemberAvatar({
    required this.name,
    this.iconCode,
    this.level = PersonLevel.contact,
    this.size = 32,
    super.key,
  });

  final String name;
  final IconCode? iconCode;
  final PersonLevel level;
  final double size;

  @override
  Widget build(BuildContext context) =>
      PersonMark(name: name, level: level, iconCode: iconCode, size: size);
}
