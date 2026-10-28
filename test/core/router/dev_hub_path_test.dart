import 'package:chubi_pocket/core/router/dev_hub_path.dart';
import 'package:chubi_pocket/features/app_version/presentation/version_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the dev hub is /dev and everything under it', () {
    for (final p in ['/dev', '/dev/', '/dev/ui/molecules/row']) {
      expect(isDevHubPath(p), isTrue, reason: p);
    }
    expect(isDevHubPath('/dev/ui?tab=2#x'), isTrue);
    for (final p in [
      '/',
      '/devices',
      '/developer',
      '/auth/login',
      '/settings/dev',
    ]) {
      expect(isDevHubPath(p), isFalse, reason: p);
    }
  });

  test('the version gate never redirects the dev hub', () {
    expect(versionGateRedirect('/dev/ui', blocked: true), isNull);
    expect(versionGateRedirect('/devices', blocked: true), updateRequiredPath);
  });
}
