import 'package:flutter/material.dart';

import '../../atoms/app_icon_button.dart';
import '../../molecules/hero_shell.dart';
import '../../molecules/hero_style.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/hero_metrics.dart';

/// What the hero is doing: showing a record, editing it, or creating one.
/// The pieces inside read it from [AppHeroScope] (the ✏️ only shows in
/// [view], a name turns into its input in [edit] / [create]).
enum HeroCardMode { view, edit, create }

/// THE hero card (owner 2026-10-18): one surface, one inset, three parts.
///
///   [header]   context + controls ([HeroHeader]: chips left, actions right;
///              the card adds ✏️ and ⌃ itself)
///   [content]  what the page shows — hub pieces only, laid out by the page
///   [footer]   what the user can do next (tiles, actions) — hub pieces only
///
/// Versions: [content] alone = it can't fold; [folded] alone = it can't
/// expand (a floating pill); both = it folds, [open] says which shows. The
/// folded version is [header] + [folded] (no footer). One version is drawn
/// at a time, both in the same inset, so nothing moves when it toggles.
///
/// Spacing comes from the theme ([HeroMetrics]); a page never pads it.
class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    required this.style,
    this.mode = HeroCardMode.view,
    this.header,
    this.content,
    this.footer = const [],
    this.folded,
    this.open,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.onTap,
    super.key,
  }) : assert(
         content != null || folded != null,
         'AppHeroCard needs content and / or a folded version',
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

  /// Null = [HeroMetrics.padding]. Only for a card that hasn't moved to the
  /// theme's inset yet.
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  bool get _foldable => content != null && folded != null;

  @override
  Widget build(BuildContext context) {
    final notifier = open;
    if (!_foldable || notifier == null) {
      final isOpen = content != null;
      return AppHeroScope(
        mode: mode,
        open: isOpen,
        toggle: null,
        child: isOpen ? _full(context) : _pill(context),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isOpen, _) => AppHeroScope(
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
    child: HeroContent(
      padding: padding,
      rows: [header, ...content!, ...footer],
    ),
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
          child: HeroContent(padding: padding, rows: [header, ...folded!]),
        ),
      ),
    );
  }
}

/// What an [AppHeroCard] tells the pieces inside it.
class AppHeroScope extends InheritedWidget {
  const AppHeroScope({
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

  static AppHeroScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppHeroScope>();

  /// The mode of the enclosing card; [HeroCardMode.view] outside one.
  static HeroCardMode modeOf(BuildContext context) =>
      maybeOf(context)?.mode ?? HeroCardMode.view;

  @override
  bool updateShouldNotify(AppHeroScope old) =>
      mode != old.mode || open != old.open || canFold != old.canFold;
}

/// The ⌄ / ⌃ of an [AppHeroCard] — [HeroHeader] places it; it draws nothing
/// when the card can't fold.
class AppHeroFoldButton extends StatelessWidget {
  const AppHeroFoldButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppHeroScope.maybeOf(context);
    if (scope == null || !scope.canFold) return const SizedBox.shrink();
    return Semantics(
      expanded: scope.open,
      child: AppIconButton.bare(
        icon: scope.open ? AppIcons.collapse : AppIcons.expand,
        onPressed: scope.toggle,
      ),
    );
  }
}
