import 'package:chubi_pocket/core/network/network_recorder.dart';
import 'package:chubi_pocket/hub/hub_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pp_forge/hub.dart';

/// The page at `<level or section>/<slug>` — what the router resolves.
HubPage? hubPageFor(String group, String slug) => hubPages
    .where(
      (p) =>
          p.slug == slug && (p.level.name == group || p.level.section == group),
    )
    .firstOrNull;

void main() {
  group('hub URLs', () {
    test('UI pages live under /dev/ui/<level>/<slug>', () {
      final p = hubPageFor('atoms', 'card')!;
      expect(p.path, '/dev/ui/atoms/card');
    });

    test('api / labs / debug pages live under /dev/<section>/<slug>', () {
      expect(hubPageFor('debug', 'network')!.path, '/dev/debug/network');
      expect(hubPageFor('debug', 'cache')!.path, '/dev/debug/cache');
      expect(hubPageFor('api', 'pages')!.path, '/dev/api/pages');
      expect(hubPageFor('labs', 'imports')!.path, '/dev/labs/imports');
    });

    test('theme is gone from Debug (it is the toolbar now)', () {
      expect(hubPageFor('debug', 'theme'), isNull);
    });

    test('every page path is unique', () {
      final paths = hubPages.map((p) => p.path).toList();
      expect(paths.toSet().length, paths.length);
    });
  });

  group('NetworkCall', () {
    test('ids collapse so one endpoint groups together', () {
      expect(
        NetworkCall.normalizePath(
          '/accounts/3f2b1c4e-1111-2222-3333-444455556666/members',
        ),
        '/accounts/:id/members',
      );
      expect(
        NetworkCall.normalizePath('/transactions/42'),
        '/transactions/:id',
      );
      expect(NetworkCall.normalizePath('/accounts'), '/accounts');
    });
  });
}
