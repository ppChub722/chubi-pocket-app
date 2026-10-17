import 'package:flutter/material.dart';

import '../../../features/accounts/domain/wallet_member.dart';
import '../../ui.dart';

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
    return AvatarStack(
      people: [
        for (final m in members) PersonRef(name: m.name, iconCode: m.iconCode),
      ],
      size: size,
      maxVisible: maxVisible,
    );
  }
}
