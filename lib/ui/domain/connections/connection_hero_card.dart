import 'package:flutter/material.dart';

import '../../molecules/hero_style.dart';
import '../../organisms/hero/app_hero_card.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import '../people/avatar.dart';
import '../people/avatar_data.dart';
import 'provider_logo.dart';

/// The connection page's hero (0.4.2 1b, one page for every app). Linked:
/// tinted with the [brand] colour, the app's picture (or its logo) at 56 px
/// with the logo as a badge, then the name, 🔗 [account] in the brand colour
/// and [linkedAtText] in grey. Not linked: a plain card, the grey logo, the
/// name and [notLinkedLabel].
class ConnectionHeroCard extends StatelessWidget {
  const ConnectionHeroCard({
    required this.name,
    required this.logoUrl,
    required this.linked,
    this.brand,
    this.photoUrl,
    this.account,
    this.linkedAtText,
    this.notLinkedLabel,
    super.key,
  });

  static const double pictureSize = 56;

  final String name;
  final String logoUrl;
  final bool linked;
  final Color? brand;
  final String? photoUrl;
  final String? account;

  /// "เชื่อมเมื่อ 28 ต.ค. 2026".
  final String? linkedAtText;
  final String? notLinkedLabel;

  @override
  Widget build(BuildContext context) {
    final brand = this.brand;
    final style = linked && brand != null
        ? HeroStyle.tinted(color: brand, glyph: AppIcons.link)
        : const HeroStyle.plain();
    return AppHeroCard(
      style: style,
      content: [
        _Identity(
          name: name,
          logoUrl: logoUrl,
          linked: linked,
          photoUrl: photoUrl,
          account: account,
          linkedAtText: linkedAtText,
          notLinkedLabel: notLinkedLabel,
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.logoUrl,
    required this.linked,
    required this.photoUrl,
    required this.account,
    required this.linkedAtText,
    required this.notLinkedLabel,
  });

  final String name;
  final String logoUrl;
  final bool linked;
  final String? photoUrl;
  final String? account;
  final String? linkedAtText;
  final String? notLinkedLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    final muted = hero?.muted ?? scheme.onSurfaceVariant;
    const size = ConnectionHeroCard.pictureSize;
    final photo = photoUrl;
    final Widget picture;
    if (!linked) {
      picture = ProviderLogo(url: logoUrl, name: name, size: size, grey: true);
    } else if (photo != null && photo.isNotEmpty) {
      picture = Avatar(
        AvatarData(
          kind: AvatarKind.photo,
          photoUrl: photo,
          initials: AvatarData.initialsOf(name),
          colors: [AvatarData.nameColorHex(name)],
        ),
        size: size,
        badge: ProviderLogo(url: logoUrl, name: name),
        badgeColor: scheme.surface,
        badgeEssential: true,
      );
    } else {
      picture = ProviderLogo(url: logoUrl, name: name, size: size);
    }
    final account = this.account;
    return Row(
      children: [
        picture,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (linked) ...[
                if (account != null && account.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        AppIcons.link,
                        size: 16,
                        color: hero?.accent ?? scheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Flexible(
                        child: Text(
                          account,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(
                            color: hero?.accent ?? scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (linkedAtText != null)
                  Text(
                    linkedAtText!,
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
              ] else if (notLinkedLabel != null)
                Text(
                  notLinkedLabel!,
                  style: text.bodyLarge?.copyWith(color: muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
