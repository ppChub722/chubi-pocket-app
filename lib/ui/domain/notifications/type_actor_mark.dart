import 'package:flutter/material.dart';

import 'package:pp_forge_ui/pp_forge_ui.dart';
import '../people/avatar.dart';
import '../people/avatar_data.dart';

/// A notification's leading (owner 2026-11-04): the type's icon is the big
/// circle and the person who did it a half-size avatar on its bottom-right
/// corner, set off by a ring of the surface colour.
class TypeActorMark extends StatelessWidget {
  const TypeActorMark({
    required this.icon,
    required this.color,
    required this.actor,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color color;
  final AvatarData actor;
  final double size;

  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconTile(icon: icon, color: color, size: size),
          Positioned(
            right: -_ring * 2,
            bottom: -_ring * 2,
            child: Container(
              padding: const EdgeInsets.all(_ring),
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
              child: Avatar(actor, size: size / 2),
            ),
          ),
        ],
      ),
    );
  }
}
