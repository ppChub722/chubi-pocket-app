import 'package:flutter/material.dart';

import 'app_top_bar.dart';
import 'fade_branch_container.dart';

class TabRootScaffold extends StatelessWidget {
  const TabRootScaffold({
    required this.body,
    this.title,
    this.topBar,
    super.key,
  });

  final String? title;
  final Widget body;

  final PreferredSizeWidget? topBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar ?? AppTopBar(title: title),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(child: body),
    );
  }
}
