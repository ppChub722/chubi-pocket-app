import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens a tab-layer page (e.g. `/contacts/:id`, `/accounts/:id`) from an
/// overlay-layer page (settings, notifications).
///
/// Overlay pages sit on the root navigator ABOVE the shell, so a plain
/// `push` of a tab route would land underneath them, out of sight. This
/// closes the overlay stack first, then pushes onto the active tab — back
/// from the target returns to where the user was before opening the
/// overlay.
void pushFromOverlay(BuildContext context, String location, {Object? extra}) {
  final router = GoRouter.of(context);
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  router.push(location, extra: extra);
}
