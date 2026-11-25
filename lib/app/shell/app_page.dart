import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'app_top_bar.dart';
import 'fade_branch_container.dart';

/// Every screen with a top bar is an [AppPage] (owner 2026-11-25): the
/// kit's [PpForgePage] frame with the app's top bar and the shell's tab
/// switch. The body runs under the top bar and clears it inside its own
/// scroll padding (the templates do); a scan test keeps pages off a bare
/// Scaffold.
class AppPage extends StatelessWidget {
  const AppPage({
    required this.body,
    this.title,
    this.topBar,
    this.bottomBar,
    this.floatingActionButton,
    super.key,
  });

  /// The title of the default [AppTopBar]; ignored when [topBar] is given.
  final String? title;

  final PreferredSizeWidget? topBar;
  final Widget body;
  final Widget? bottomBar;
  final Widget? floatingActionButton;

  /// A plain scroll view's padding when no template fits: it clears the top
  /// bar and the bottom inset inside the scroll, so the content runs on
  /// under the bar. [context] must sit inside the page body.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double side = PpForgeSpacing.md,
    double top = PpForgeSpacing.md,
    double bottom = PpForgeSpacing.xxl,
  }) {
    final inset = MediaQuery.paddingOf(context);
    return EdgeInsets.fromLTRB(
      side,
      inset.top + top,
      side,
      inset.bottom + bottom,
    );
  }

  @override
  Widget build(BuildContext context) => PpForgePage(
    topBar: topBar ?? AppTopBar(title: title),
    body: TabSwitchBody(child: body),
    bottomBar: bottomBar,
    floatingActionButton: floatingActionButton,
  );
}
