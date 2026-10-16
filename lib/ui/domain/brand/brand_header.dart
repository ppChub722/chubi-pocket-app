import 'package:flutter/material.dart';

import '../../debug/secret_tap.dart';
import 'package:pp_forge/pp_forge.dart';
import 'brand_logo.dart';

/// Logo · app name · tagline (the auth pages' header). [onSecretUnlock]: the
/// hidden dev entrance — tap the logo 5×. [compact]: a smaller logo and no
/// tagline (register).
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    required this.name,
    this.tagline,
    this.compact = false,
    this.onSecretUnlock,
    super.key,
  });

  final String name;
  final String? tagline;
  final bool compact;
  final VoidCallback? onSecretUnlock;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logo = BrandLogo(size: compact ? 56 : 88);
    return Column(
      children: [
        onSecretUnlock == null
            ? logo
            : SecretTapDetector(onUnlock: onSecretUnlock!, child: logo),
        const SizedBox(height: PpForgeSpacing.md),
        Text(
          name,
          style: (compact ? textTheme.titleLarge : textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (!compact && tagline != null) ...[
          const SizedBox(height: PpForgeSpacing.xs),
          Text(
            tagline!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
