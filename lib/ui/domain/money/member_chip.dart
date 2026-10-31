import 'package:flutter/material.dart';

import '../../../features/accounts/domain/wallet_member.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';

/// A shared wallet's members as one chip: the stacked avatars (+N past
/// [maxVisible]) in a pill as tall as the chips beside it.
class MemberChip extends StatelessWidget {
  const MemberChip({
    required this.members,
    this.maxVisible = 3,
    this.size,
    this.onTap,
    super.key,
  });

  final List<WalletMember> members;
  final int maxVisible;

  /// Null = the enclosing [ChipSizeScope], else chip size.
  final ChipSize? size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final height = ChipSizeScope.resolve(
      context,
      size,
      fallback: ChipSize.chip,
    ).heightOf(context);
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      button: onTap != null,
      label: AppLocalizations.of(context)!.walletMembersCount(members.length),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: hero?.soft ?? scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: hero?.line ?? scheme.outlineVariant),
        ),
        child: BusyLock(
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: MemberAvatarStack(
                members: members,
                size: height - 6,
                maxVisible: maxVisible,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
