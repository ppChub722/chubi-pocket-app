import 'package:flutter/material.dart';

import 'app_top_bar.dart';
import 'fade_branch_container.dart';

/// Scaffold for a tab's root page (dashboard, transactions, wallets, more).
///
/// The [AppTopBar] is transparent and the body extends behind it, so content
/// scrolls underneath the floating chips. Scaffold folds the bar height into
/// `MediaQuery.paddingOf(context).top` — the body pads its first item with
/// it. A null [title] shows no title chip (the เพิ่มเติม hub).
class TabRootScaffold extends StatelessWidget {
  const TabRootScaffold({
    required this.body,
    this.title,
    this.topBar,
    super.key,
  });

  final String? title;
  final Widget body;

  /// Replaces the default `AppTopBar(title:)` (e.g. an edit-mode bar).
  final PreferredSizeWidget? topBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar ?? AppTopBar(title: title),
      extendBodyBehindAppBar: true,
      // Only the body animates on a tab switch — the bar stays put.
      body: TabSwitchBody(child: body),
    );
  }
}
