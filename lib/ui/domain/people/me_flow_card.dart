import 'package:flutter/material.dart';

import '../../ui.dart';

/// The "ฉัน" end of a debt flow when no wallet is involved (owner
/// 2026-10-23): my avatar + name, in the app's colour. Money moving through a
/// wallet uses the wallet card instead.
class MeFlowCard extends StatelessWidget {
  const MeFlowCard({
    required this.label,
    required this.name,
    this.iconCode,
    super.key,
  });

  /// "ฉัน".
  final String label;
  final String name;
  final IconCode? iconCode;

  @override
  Widget build(BuildContext context) {
    return PickCard(
      reserveSubtitle: true,
      dense: true,
      label: label,
      value: name,
      leading: UserAvatar(
        displayName: name.isEmpty ? '?' : name,
        iconCode: iconCode,
        size: AvatarMetrics.sizeSmall,
      ),
      accent: Theme.of(context).colorScheme.primary,
      onTap: null,
    );
  }
}
