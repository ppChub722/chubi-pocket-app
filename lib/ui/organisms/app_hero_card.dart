import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../molecules/hero_shell.dart';
import '../molecules/hero_style.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';

class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    required this.style,
    this.expanded,
    this.folded,
    this.open,
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.padding = const EdgeInsets.all(HeroSpacing.padding),
    this.rowGap = HeroSpacing.rowGap,
    super.key,
  }) : assert(
         expanded != null || folded != null,
         'AppHeroCard needs an expanded and / or a folded version',
       ),
       assert(
         (expanded != null && folded != null) == (open != null),
         'open goes with both versions, and only then',
       );

  final HeroStyle style;

  final List<Widget?>? expanded;

  /// The rows of the folded card (a floating pill); null = it can't fold.
  final List<Widget?>? folded;

  final ValueNotifier<bool>? open;

  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  /// Inside the card — [HeroSpacing.padding] all round unless a page needs it
  /// tighter ([HeroSpacing.tight]).
  final EdgeInsetsGeometry padding;

  final double rowGap;

  bool get _foldable => expanded != null && folded != null;

  @override
  Widget build(BuildContext context) {
    final notifier = open;
    if (!_foldable || notifier == null) {
      return _scope(
        context,
        isOpen: expanded != null,
        toggle: null,
        child: expanded != null ? _full(context) : _pill(context),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isOpen, _) => _scope(
        context,
        isOpen: isOpen,
        toggle: () => notifier.value = !isOpen,
        child: isOpen ? _full(context) : _pill(context),
      ),
    );
  }

  Widget _scope(
    BuildContext context, {
    required bool isOpen,
    required VoidCallback? toggle,
    required Widget child,
  }) => AppHeroFold(open: isOpen, toggle: toggle, child: child);

  Widget _content(List<Widget?> rows) =>
      HeroContent(rows: rows, padding: padding, rowGap: rowGap);

  Widget _full(BuildContext context) => HeroSurface(
    style: style,
    margin: margin,
    onTap: onTap,
    child: _content(expanded!),
  );

  Widget _pill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.xl);
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
          child: _content(folded!),
        ),
      ),
    );
  }
}

class AppHeroFold extends InheritedWidget {
  const AppHeroFold({
    required this.open,
    required this.toggle,
    required super.child,
    super.key,
  });

  final bool open;

  /// Null = the card can't fold (only one version).
  final VoidCallback? toggle;

  bool get canFold => toggle != null;

  static AppHeroFold? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppHeroFold>();

  @override
  bool updateShouldNotify(AppHeroFold old) =>
      open != old.open || canFold != old.canFold;
}

/// The ⌄ / ⌃ of an [AppHeroCard]: an [AppIconButton] without its frame, the
/// same size as the framed buttons beside it.
class AppHeroFoldButton extends StatelessWidget {
  const AppHeroFoldButton({super.key});

  @override
  Widget build(BuildContext context) {
    final fold = AppHeroFold.maybeOf(context);
    if (fold == null || !fold.canFold) return const SizedBox.shrink();
    return Semantics(
      expanded: fold.open,
      child: AppIconButton.bare(
        icon: fold.open ? AppIcons.collapse : AppIcons.expand,
        onPressed: fold.toggle,
      ),
    );
  }
}
