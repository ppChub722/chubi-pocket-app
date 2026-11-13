import 'package:flutter/material.dart';

import '../people/avatar_data.dart';
import '../people/person_mark.dart';

class ProjectMemberAvatar extends StatelessWidget {
  const ProjectMemberAvatar({
    required this.avatar,
    this.level = PersonLevel.contact,
    this.size = 32,
    super.key,
  });

  /// The member's avatar (the model's `.avatar`).
  final AvatarData avatar;
  final PersonLevel level;
  final double size;

  @override
  Widget build(BuildContext context) =>
      PersonMark(level: level, avatar: avatar, size: size);
}
