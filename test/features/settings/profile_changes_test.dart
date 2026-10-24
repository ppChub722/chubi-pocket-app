import 'package:chubi_pocket/features/settings/presentation/profile_changes.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile edit sends only what changed', () {
    const star = IconCode(icon: 'star');
    const bank = IconCode(icon: 'bank');
    for (final c in <({
      String name,
      String newName,
      String newEmail,
      IconCode? newIcon,
      String? wantName,
      String? wantEmail,
      IconCode? wantIcon,
      bool wantClear,
    })>[
      (
        name: 'nothing changed',
        newName: 'ppOnd',
        newEmail: 'ppond@example.com',
        newIcon: bank,
        wantName: null,
        wantEmail: null,
        wantIcon: null,
        wantClear: false,
      ),
      (
        name: 'name only, trimmed',
        newName: '  Pond ',
        newEmail: 'ppond@example.com',
        newIcon: bank,
        wantName: 'Pond',
        wantEmail: null,
        wantIcon: null,
        wantClear: false,
      ),
      (
        name: 'a blank email is not sent',
        newName: 'ppOnd',
        newEmail: '  ',
        newIcon: bank,
        wantName: null,
        wantEmail: null,
        wantIcon: null,
        wantClear: false,
      ),
      (
        name: 'new email, trimmed',
        newName: 'ppOnd',
        newEmail: ' p@example.com ',
        newIcon: bank,
        wantName: null,
        wantEmail: 'p@example.com',
        wantIcon: null,
        wantClear: false,
      ),
      (
        name: 'another icon',
        newName: 'ppOnd',
        newEmail: 'ppond@example.com',
        newIcon: star,
        wantName: null,
        wantEmail: null,
        wantIcon: star,
        wantClear: false,
      ),
      (
        name: 'icon removed',
        newName: 'ppOnd',
        newEmail: 'ppond@example.com',
        newIcon: null,
        wantName: null,
        wantEmail: null,
        wantIcon: null,
        wantClear: true,
      ),
    ]) {
      final r = profileChanges(
        name: c.newName,
        email: c.newEmail,
        iconCode: c.newIcon,
        originalName: 'ppOnd',
        originalEmail: 'ppond@example.com',
        originalIconCode: bank,
      );
      expect(r.displayName, c.wantName, reason: c.name);
      expect(r.email, c.wantEmail, reason: c.name);
      expect(r.iconCode, c.wantIcon, reason: c.name);
      expect(r.clearIconCode, c.wantClear, reason: c.name);
    }
    final fromNone = profileChanges(
      name: 'ppOnd',
      email: '',
      iconCode: star,
      originalName: 'ppOnd',
      originalEmail: '',
      originalIconCode: null,
    );
    expect(fromNone.iconCode, star, reason: 'first icon');
    expect(fromNone.clearIconCode, isFalse);
    expect(fromNone.email, isNull, reason: 'no email before or after');
  });
}
