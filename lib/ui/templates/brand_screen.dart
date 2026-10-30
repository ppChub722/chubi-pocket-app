import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// The page every screen with the brand logo is built on (splash, login,
/// register, Telegram pages, update required, start-up failure): the logo
/// sits at ONE y, [logoTop] below the safe top, at ONE size
/// ([BrandLogo.size]), whatever the form below it, the keyboard or a top bar
/// that extends behind the body. What sits under the logo scrolls.
///
/// [header] is the [BrandHeader] (logo first, then an optional name and
/// tagline); [children] follow it.
class BrandScreen extends StatelessWidget {
  const BrandScreen({
    required this.header,
    required this.children,
    this.maxWidth = 400,
    this.physics,
    super.key,
  });

  /// Distance from the system safe top to the logo.
  static const logoTop = 72.0;

  final Widget header;
  final List<Widget> children;
  final double maxWidth;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    // The system inset, not MediaQuery.padding: a top bar extended behind the
    // body (register, Telegram) must not move the logo.
    final safeTop = view.viewPadding.top / view.devicePixelRatio;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          physics: physics,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            safeTop + logoTop,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, ...children],
            ),
          ),
        ),
      ),
    );
  }
}
