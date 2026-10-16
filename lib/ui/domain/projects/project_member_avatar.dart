import 'package:flutter/material.dart';

import '../../icons/icon_code.dart';
import '../people/person_mark.dart';

/// A project member's own icon, else their initial — a thin skin over
/// [PersonMark]. Takes plain values (no member model).
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
