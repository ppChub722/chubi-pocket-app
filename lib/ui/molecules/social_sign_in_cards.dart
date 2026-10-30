import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

/// One outside sign-in on the login / register page.
class SocialSignInOption {
  const SocialSignInOption({
    required this.label,
    required this.logo,
    this.onPressed,
    this.loading = false,
  });

  final String label;

  /// The app's logo (about 40 px).
  final Widget logo;

  /// Null = not wired yet: the card is dimmed and carries the badge.
  final VoidCallback? onPressed;
  final bool loading;
}

/// The outside sign-ins as cards in a row (3 columns, owner mock
/// 2026-10-30): the app's logo over its name. A card with no [onPressed] is
/// dimmed with [comingSoonLabel] under it, so every card has the same height.
class SocialSignInCards extends StatelessWidget {
  const SocialSignInCards({
    required this.options,
    required this.comingSoonLabel,
    super.key,
  });

  final List<SocialSignInOption> options;
  final String comingSoonLabel;

  static const double minHeight = 104;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Card(option: o, comingSoonLabel: comingSoonLabel),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.option, required this.comingSoonLabel});

  final SocialSignInOption option;
  final String comingSoonLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final soon = option.onPressed == null;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      enabled: !soon,
      label: option.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: soon ? 0.6 : 1,
        child: Material(
          color: soon ? scheme.surfaceContainerHighest : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: option.loading ? null : option.onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: SocialSignInCards.minHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: option.loading
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : option.logo,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // Always there (hidden when wired) so the cards match.
                    Visibility(
                      visible: soon,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: IgnorePointer(
                        child: AppChip(
                          label: comingSoonLabel,
                          tone: AppChipTone.info,
                          selected: true,
                          size: ChipSize.mini,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
