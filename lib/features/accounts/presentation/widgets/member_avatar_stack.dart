import 'package:flutter/material.dart';

import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/wallet_member.dart';

/// An overlapping avatar stack for wallet members — max [maxVisible]
/// avatars, then a "+N" overflow bubble (spec B2). Reuses [UserAvatar]
/// so icon-code avatars and initials fallbacks render identically to
/// the rest of the app.
class MemberAvatarStack extends StatelessWidget {
  const MemberAvatarStack({
    required this.members,
    this.size = 20,
    this.maxVisible = 3,
    super.key,
  });

  final List<WalletMember> members;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final visible = members.take(maxVisible).toList();
    final overflow = members.length - visible.length;
    final step = size * 0.7;
    final width =
        (overflow > 0 ? visible.length : visible.length - 1) * step + size;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              child: Tooltip(
                message: visible[i].displayName,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 1),
                  ),
                  child: UserAvatar(
                    displayName: visible[i].displayName,
                    iconCode: visible[i].iconCode,
                    size: size,
                  ),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * step,
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
