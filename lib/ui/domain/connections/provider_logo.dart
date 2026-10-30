import 'package:flutter/material.dart';

import '../../atoms/server_image.dart';
import '../../tokens/app_spacing.dart';

/// An outside app's logo (0.4.2 1b): the BE's `logo_url` (a 96 px PNG,
/// cached by its `?v=`) drawn through [ServerImageScope]. [grey] = the app is
/// not linked: the logo in the theme's grey (luminance kept, so a white
/// glyph on a coloured disc still reads). A load error shows the first
/// letter of [name] on a plain disc.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    required this.url,
    this.name = '',
    this.size = 32,
    this.grey = false,
    super.key,
  });

  final String url;

  /// The app's name: the fallback letter and the semantics label.
  final String name;
  final double size;
  final bool grey;

  /// Luminance only (Rec. 709), alpha kept.
  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget fallback() => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.characters.firstOrNull?.toUpperCase() ?? '',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.45,
        ),
      ),
    );
    Widget logo = url.isEmpty
        ? fallback()
        : Image(
            image: ServerImageScope.providerOf(context, url),
            width: size,
            height: size,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            semanticLabel: name.isEmpty ? null : name,
            errorBuilder: (_, _, _) => fallback(),
          );
    if (grey) {
      logo = Opacity(
        opacity: 0.55,
        child: ColorFiltered(colorFilter: _greyscale, child: logo),
      );
    }
    return SizedBox.square(dimension: size, child: logo);
  }
}

/// The logos of the apps a person linked, in a row (the settings profile
/// card's third line). Empty → nothing.
class ProviderLogoStrip extends StatelessWidget {
  const ProviderLogoStrip({required this.logos, this.size = 20, super.key});

  /// `(logo_url, name)` per linked app, in display order.
  final List<(String url, String name)> logos;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (logos.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (url, name) in logos)
          ProviderLogo(url: url, name: name, size: size),
      ],
    );
  }
}
