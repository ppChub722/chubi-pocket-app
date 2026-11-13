import 'package:flutter/material.dart';

import '../../debug/secret_tap.dart';
import 'brand_logo.dart';
import 'package:pp_forge_core/ui.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({this.name, this.tagline, this.onSecretUnlock, super.key});

  final String? name;
  final String? tagline;
  final VoidCallback? onSecretUnlock;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logo = BrandLogo();
    return Column(
      children: [
        onSecretUnlock == null
            ? logo
            : SecretTapDetector(onUnlock: onSecretUnlock!, child: logo),
        if (name != null) ...[
          const SizedBox(height: PpForgeSpacing.md),
          Text(
            name!,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (tagline != null) ...[
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
