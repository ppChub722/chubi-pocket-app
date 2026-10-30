import 'package:flutter/material.dart';

import '../../molecules/app_row.dart';
import '../../molecules/detail_rows.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/hero_colors.dart';
import '../people/avatar.dart';
import '../people/avatar_data.dart';
import 'provider_logo.dart';

/// How a connection row looks (the app maps its data onto it).
enum ConnectionRowState {
  /// Linked, the app gave a picture: the picture + the logo as a badge.
  linkedPhoto,

  /// Linked, no picture: the logo in colour.
  linkedLogo,

  /// Not linked: the logo in grey, "tap to link".
  unlinked,

  /// Not built yet ("coming soon"): muted, no taps.
  comingSoon,
}

/// One outside app on the profile page's "การเชื่อมต่อ" (0.4.2 1b), an
/// [AppDetailRow]: linked rows are tinted with the [brand] colour and show
/// 🔗 + the account in it; an unlinked row is grey with [notLinkedLabel].
class ConnectionRow extends StatelessWidget {
  const ConnectionRow({
    required this.name,
    required this.logoUrl,
    required this.state,
    this.brand,
    this.photoUrl,
    this.account,
    this.notLinkedLabel,
    this.tapToLinkLabel,
    this.onTap,
    super.key,
  });

  /// The leading slot (logo / picture), the same on every row.
  static const double leadingSize = 32;

  final String name;
  final String logoUrl;
  final ConnectionRowState state;

  /// The app's colour; null = the theme's primary.
  final Color? brand;

  /// [ConnectionRowState.linkedPhoto]: the picture's URL.
  final String? photoUrl;

  /// Linked: who it is in that app (`@username`).
  final String? account;
  final String? notLinkedLabel;
  final String? tapToLinkLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final logo = ProviderLogo(url: logoUrl, name: name, size: leadingSize);
    switch (state) {
      case ConnectionRowState.linkedPhoto:
      case ConnectionRowState.linkedLogo:
        final accent = HeroColors.from(Theme.of(context), brand).accent;
        final photo = photoUrl;
        final withPhoto =
            state == ConnectionRowState.linkedPhoto &&
            photo != null &&
            photo.isNotEmpty;
        return AppDetailRow(
          leading: withPhoto
              ? Avatar(
                  AvatarData(
                    kind: AvatarKind.photo,
                    photoUrl: photo,
                    initials: AvatarData.initialsOf(name),
                    colors: [AvatarData.nameColorHex(name)],
                  ),
                  size: leadingSize,
                )
              : logo,
          leadingSize: leadingSize,
          badge: withPhoto
              ? RowBadge.logo(ProviderLogo(url: logoUrl, name: name))
              : null,
          label: name,
          valueIcon: AppIcons.link,
          valueColor: accent,
          trailing: Text(
            account ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          accent: brand,
          tinted: true,
          showChevron: true,
          onTap: onTap,
        );
      case ConnectionRowState.unlinked:
        return AppDetailRow(
          leading: ProviderLogo(
            url: logoUrl,
            name: name,
            size: leadingSize,
            grey: true,
          ),
          leadingSize: leadingSize,
          label: name,
          helper: tapToLinkLabel,
          trailing: notLinkedLabel == null ? null : Text(notLinkedLabel!),
          valueColor: Theme.of(context).colorScheme.onSurfaceVariant,
          showChevron: true,
          onTap: onTap,
        );
      case ConnectionRowState.comingSoon:
        return AppDetailRow(
          leading: ProviderLogo(
            url: logoUrl,
            name: name,
            size: leadingSize,
            grey: true,
          ),
          leadingSize: leadingSize,
          label: name,
          comingSoon: true,
        );
    }
  }
}
