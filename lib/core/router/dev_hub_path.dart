import 'package:go_router/go_router.dart';

/// The dev hub (`/dev`, `/dev/...`) is a widget playground: no app-wide
/// error UI (offline banner, offline gating, update banner / gate, auth
/// redirects) shows there, so it works without a backend. Every global error
/// surface asks this one helper; hub demos that show an error widget build
/// it themselves and are not affected.
bool isDevHubPath(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  return path == '/dev' || path.startsWith('/dev/');
}

/// Whether the page on top is the dev hub. Reads the TOP route: a pushed
/// `/dev` (the secret unlock on login / settings) leaves the router's
/// `currentConfiguration.uri` on the page below it.
bool routerOnDevHub(GoRouter router) {
  final config = router.routerDelegate.currentConfiguration;
  if (config.isEmpty) return false;
  return isDevHubPath(router.state.uri.path);
}
