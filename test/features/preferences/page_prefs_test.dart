import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/preferences/page_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every server page id has a spec, and every choice has a default', () {
    expect(pagePrefPages.map((p) => p.id).toSet(), PagePrefIds.all.toSet());
    for (final p in pagePrefPages) {
      for (final f in p.fields) {
        if (!f.isSet) expect(f.options, isNotEmpty, reason: '${p.id}.${f.key}');
      }
    }
  });

  test('a stored pick reads back; unknown / missing = the default', () {
    final budgets = pagePrefPage(PagePrefIds.budgets);
    final sort = budgets.fields.firstWhere((f) => f.key == 'sort');
    expect(sort.pick({'sort': 'newest'}), 'newest');
    expect(sort.pick({'sort': 'gone_value'}), 'risk');
    expect(sort.pick(const {}), 'risk');
    expect(budgets.changed(const {}), isFalse);
    expect(budgets.changed({'sort': 'risk'}), isFalse, reason: 'the default');
    expect(budgets.changed({'sort': 'newest'}), isTrue);
  });

  test('remember-last: the newest pick wins, other keys stay, no-op = '
      'no call', () {
    final stored = <String, dynamic>{'sort': 'risk', 'filter': 'active'};
    expect(mergePagePref(stored, {'sort': 'newest'}), {
      'sort': 'newest',
      'filter': 'active',
    });
    expect(mergePagePref(stored, {'sort': 'risk'}), isNull);
    expect(mergePagePref(const {}, {'sort': 'risk'}), {'sort': 'risk'});
    // Sets compare by value: the same list again sends nothing.
    final cats = <String, dynamic>{
      'collapsed': ['a', 'b'],
    };
    expect(
      mergePagePref(cats, {
        'collapsed': ['a', 'b'],
      }),
      isNull,
    );
    expect(mergePagePref(cats, {'collapsed': <String>[]}), {
      'collapsed': <String>[],
    });
  });

  test('set fields read lists; an empty list is no change', () {
    final cats = pagePrefPage(PagePrefIds.categories);
    final collapsed = cats.fields.firstWhere((f) => f.key == 'collapsed');
    expect(collapsed.isSet, isTrue);
    expect(
      collapsed.picks({
        'collapsed': ['a', 'b'],
      }),
      ['a', 'b'],
    );
    expect(cats.changed({'collapsed': <String>[]}), isFalse);
    expect(
      cats.changed({
        'colors': ['red'],
      }),
      isTrue,
    );
  });
}
