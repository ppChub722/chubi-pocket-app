import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/notifications_inbox_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/pages/notifications_inbox_page.dart';
import 'package:chubi_pocket/features/preferences/page_prefs.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
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

  test('settings sections = the app grouping (เพิ่มเติม / nav bar): every '
      'page once, dashboard "soon"', () async {
    final l = await AppLocalizations.delegate.load(const Locale('th'));
    expect(
      [
        for (final g in pagePrefGroups)
          [g.title(l), for (final p in g.pages) p.id],
      ],
      [
        [
          l.moreGroupMain,
          'dashboard',
          PagePrefIds.transactions,
          PagePrefIds.wallets,
          PagePrefIds.pending,
          PagePrefIds.notifications,
        ],
        [
          l.moreGroupPlan,
          PagePrefIds.budgets,
          PagePrefIds.goals,
          PagePrefIds.recurring,
        ],
        [l.moreGroupOthers, PagePrefIds.debts, PagePrefIds.events],
        [
          l.moreGroupSetup,
          PagePrefIds.categories,
          PagePrefIds.tags,
          PagePrefIds.contacts,
        ],
      ],
    );
    final shown = [for (final g in pagePrefGroups) ...g.pages];
    expect(
      [
        for (final p in shown)
          if (p.soon) p.id,
      ],
      ['dashboard'],
    );
    // The More page / nav names.
    expect(
      [for (final p in shown) p.title(l)],
      [
        l.navDashboard,
        l.navTransactions,
        l.navAccounts,
        l.pendingTitle,
        l.notificationsTitle,
        l.moreBudgets,
        l.moreSavingGoals,
        l.moreRecurring,
        l.moreDebts,
        l.moreProjects,
        l.moreCategories,
        l.moreTags,
        l.moreContacts,
      ],
    );
  });

  test('the inbox opens on its remembered filter', () {
    expect(rememberedInboxFilter(const {}), InboxFilter.all);
    expect(rememberedInboxFilter({'filter': 'unread'}), InboxFilter.unread);
    expect(rememberedInboxFilter({'filter': 'gone'}), InboxFilter.all);
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
