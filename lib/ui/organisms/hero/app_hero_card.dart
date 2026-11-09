import 'package:flutter/material.dart';

import '../../atoms/app_icon_button.dart';
import '../../molecules/hero_shell.dart';
import '../../molecules/hero_style.dart';
import '../../tokens/pp_forge_icons.dart';
import '../../tokens/hero_colors.dart';
import '../../tokens/hero_metrics.dart';

/// Pieces inside read it from [PpForgeHeroScope].
enum HeroCardMode { view, edit, create }

/// Header + content + footer on one surface and inset. Content alone can't
/// fold, folded alone can't expand; both fold, driven by [open].
class PpForgeHeroCard extends StatelessWidget {
  const PpForgeHeroCard({
    required this.style,
    this.mode = HeroCardMode.view,
    this.header,
    this.content,
    this.footer = const [],
    this.folded,
    this.open,
    this.margin = EdgeInsets.zero,
    this.onTap,
    super.key,
  }) : assert(
         content != null || folded != null,
         'PpForgeHeroCard needs content and / or a folded version',
       ),
       assert(
         (content != null && folded != null) == (open != null),
         'open goes with both versions, and only then',
       );

  final HeroStyle style;
  final HeroCardMode mode;
  final Widget? header;
  final List<Widget?>? content;
  final List<Widget?> footer;
  final List<Widget?>? folded;
  final ValueNotifier<bool>? open;
  final EdgeInsetsGeometry margin;

  final VoidCallback? onTap;

  bool get _foldable => content != null && folded != null;

  @override
  Widget build(BuildContext context) {
    final notifier = open;
    if (!_foldable || notifier == null) {
      final isOpen = content != null;
      return PpForgeHeroScope(
        mode: mode,
        open: isOpen,
        toggle: null,
        child: isOpen ? _full(context) : _pill(context),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isOpen, _) => PpForgeHeroScope(
        mode: mode,
        open: isOpen,
        toggle: () => notifier.value = !isOpen,
        child: isOpen ? _full(context) : _pill(context),
      ),
    );
  }

  Widget _full(BuildContext context) => HeroSurface(
    style: style,
    margin: margin,
    onTap: onTap,
    child: HeroContent(rows: [header, ...content!, ...footer]),
  );

  Widget _pill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(HeroMetrics.of(context).foldedRadius);
    return Padding(
      padding: margin,
      child: Material(
        color: scheme.surface,
        elevation: 1.5,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: HeroSurface(
          style: style,
          radius: radius,
          glyphSize: 56,
          onTap: onTap,
          child: HeroContent(rows: [header, ...folded!]),
        ),
      ),
    );
  }
}

/// What an [PpForgeHeroCard] tells the pieces inside it.
class PpForgeHeroScope extends InheritedWidget {
  const PpForgeHeroScope({
    required this.mode,
    required this.open,
    required this.toggle,
    required super.child,
    super.key,
  });

  final HeroCardMode mode;

  /// True = the expanded version is shown.
  final bool open;

  /// Null = the card can't fold (one version only).
  final VoidCallback? toggle;

  bool get canFold => toggle != null;
  bool get editing => mode != HeroCardMode.view;

  static PpForgeHeroScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PpForgeHeroScope>();

  /// The mode of the enclosing card; [HeroCardMode.view] outside one.
  static HeroCardMode modeOf(BuildContext context) =>
      maybeOf(context)?.mode ?? HeroCardMode.view;

  @override
  bool updateShouldNotify(PpForgeHeroScope old) =>
      mode != old.mode || open != old.open || canFold != old.canFold;
}

/// The ⌄ / ⌃ of an [PpForgeHeroCard] — [HeroHeader] places it; it draws nothing
/// when the card can't fold.
class PpForgeHeroFoldButton extends StatelessWidget {
  const PpForgeHeroFoldButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PpForgeHeroScope.maybeOf(context);
    if (scope == null || !scope.canFold) return const SizedBox.shrink();
    return Semantics(
      button: true,
      expanded: scope.open,
      child: PpForgeIconButton.bare(
        icon: scope.open ? PpForgeIcons.collapse : PpForgeIcons.expand,
        onPressed: scope.toggle,
        size: size,
        color: HeroColors.maybeOf(context)?.muted,
      ),
    );
  }

  /// The tap box; [HeroHeader] tucks it into the card's corner padding.
  static const double size = 36;
}
