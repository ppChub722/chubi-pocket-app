import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/router/app_router.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

/// Builds the REAL app router (every route, every shell tab) the way main()
/// does. GoRouter checks its whole configuration when it is built, so a route
/// registered twice fails here instead of as a blank app at start-up
/// (0.4.0-3: "personal-debt-entry" was added twice). The walk below says it
/// in plain words too: no two routes share a name or a full path.
void main() {
  test('the real router builds; route names and full paths are unique', () {
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    whenListen(auth, const Stream<AuthState>.empty());

    final router = buildAppRouter(auth);
    addTearDown(router.dispose);

    final names = <String, String>{};
    final paths = <String>{};
    final dupNames = <String>[];
    final dupPaths = <String>[];

    String join(String parent, String path) => path.startsWith('/')
        ? path
        : (parent.endsWith('/') ? '$parent$path' : '$parent/$path');

    void walk(List<RouteBase> routes, String parent) {
      for (final r in routes) {
        var here = parent;
        if (r is GoRoute) {
          here = join(parent, r.path);
          final name = r.name;
          if (name != null) {
            final seen = names[name];
            if (seen != null) dupNames.add('$name: $seen and $here');
            names[name] = here;
          }
          if (!paths.add(here)) dupPaths.add(here);
        }
        walk(r.routes, here);
      }
    }

    walk(router.configuration.routes, '');
    expect(names, isNotEmpty);
    expect(dupNames, isEmpty, reason: 'a route name registered twice');
    expect(dupPaths, isEmpty, reason: 'a route path registered twice');
    // The debt entry page has exactly one route (statement lines push it).
    expect(names['personal-debt-entry'], '/personal-debts/entries/:id');
  });

  test('a link into a settings page stacks it on the settings home', () {
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    whenListen(auth, const Stream<AuthState>.empty());
    final router = buildAppRouter(auth);
    addTearDown(router.dispose);

    // openPage from another tab `go`es here: back must land on การตั้งค่า.
    List<String?> stack(String location) => [
      for (final r
          in router.configuration.findMatch(Uri.parse(location)).routes)
        if (r is GoRoute) r.name,
    ];
    expect(stack('/settings/notifications'), [
      'settings',
      'settings-notifications',
    ]);
    expect(stack('/settings/page-prefs/tx'), [
      'settings',
      'settings-page-prefs',
      'settings-page-pref',
    ]);
    // The settings tab's first page (where it resets to) is its home.
    expect(stack('/settings'), ['settings']);
  });
}
