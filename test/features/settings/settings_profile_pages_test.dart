import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/preferences/page_prefs.dart';
import 'package:chubi_pocket/features/settings/presentation/pages/settings_page_prefs_page.dart';
import 'package:chubi_pocket/features/settings/presentation/settings_labels.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /users/me` as the 0.4.1-2 BE answers (BE-3 spec: server preferences,
/// page_prefs, the two auto-sync switches, fee_category, summary {on, total}).
Map<String, dynamic> _meJson({
  Map<String, dynamic>? defaultAccount = const {
    'id': 'w1',
    'name': 'Doraemon',
    'icon_code': {'icon': 'bank', 'color': 'blue'},
  },
  Map<String, dynamic> preferences = const {
    'timezone': null,
    'theme_mode': 'dark',
    'theme_id': 'sweet',
    'language': 'en',
    'font_th': 'Mitr',
    'font_en': null,
    'fee_category_id': 'c9',
    'money_style': 'plus_minus',
    'money_decimals': null,
    'page_prefs': {
      'budgets': {'filter': 'active', 'sort': 'near_limit'},
    },
  },
}) => {
  'id': 'u1',
  'username': 'ppond',
  'email': 'ppond@example.com',
  'email_verified_at': null,
  'display_name': 'ppOnd',
  'currency': 'THB',
  'icon_code': null,
  'status': 'active',
  'default_account': defaultAccount,
  'auto_sync_events': true,
  'auto_sync_debts': false,
  'auto_accept_events': false,
  'auto_accept_debts': true,
  'fee_category': {
    'id': 'c9',
    'name': 'ค่าธรรมเนียม',
    'type': 'expense',
    'icon_code': null,
    'is_system': false,
    'system_kind': null,
    'parent_id': null,
  },
  'notification_summary': {'on': 9, 'total': 12},
  'preferences': preferences,
  'created_at': '2026-09-16T03:00:00Z',
  'updated_at': '2026-10-06T08:59:00Z',
};

void main() {
  test('User parses the prod-shaped /users/me', () {
    final u = User.fromJson(_meJson());
    expect(u.defaultAccount?.id, 'w1');
    expect(u.defaultAccount?.name, 'Doraemon');
    expect(u.autoSyncEvents, isTrue);
    expect(u.autoSyncDebts, isFalse);
    expect(u.autoAcceptEvents, isFalse);
    expect(u.autoAcceptDebts, isTrue);
    expect(u.feeCategoryId, 'c9');
    expect(u.feeCategory?.name, 'ค่าธรรมเนียม');
    expect(u.notificationSummary?.on, 9);
    expect(u.notificationSummary?.total, 12);
    expect(u.themeMode, 'dark');
    expect(u.themeId, 'sweet');
    expect(u.language, 'en');
    expect(u.fontTh, 'Mitr');
    expect(u.fontEn, isNull, reason: 'null = never saved: the app fills it');
    expect(u.pagePref(PagePrefIds.budgets), {
      'filter': 'active',
      'sort': 'near_limit',
    });
    expect(u.pagePref(PagePrefIds.wallets), isEmpty);
  });

  test('missing keys: switches default on, no summary, no prefs', () {
    final none = User.fromJson(
      Map<String, dynamic>.of(_meJson(defaultAccount: null, preferences: {}))
        ..remove('notification_summary')
        ..remove('auto_sync_events')
        ..remove('auto_sync_debts')
        ..remove('auto_accept_events')
        ..remove('auto_accept_debts')
        ..remove('fee_category'),
    );
    expect(none.defaultAccount, isNull);
    expect(none.notificationSummary, isNull);
    expect(none.autoSyncEvents && none.autoSyncDebts, isTrue);
    // Owner defaults: accept new event bills on, new split bills off.
    expect(none.autoAcceptEvents, isTrue);
    expect(none.autoAcceptDebts, isFalse);
    expect(none.feeCategory, isNull);
    expect(none.themeMode, isNull);
    expect(none.pagePrefs, isEmpty);
  });

  test('home summaries: notifications count the four auto switches; page '
      'prefs show bare values', () {
    final l = lookupAppLocalizations(const Locale('th'));
    final u = User.fromJson(_meJson());
    // sync events on, sync debts off, accept events off, accept debts on
    expect(autoOnCount(u), 2);
    expect(
      notificationsSummary(l, u),
      'แจ้ง 9 จาก 12 เรื่อง | อัตโนมัติ 2 เรื่อง',
    );
    final budgets = pagePrefPage(PagePrefIds.budgets);
    final line = pagePrefSummary(l, budgets, u.pagePref(PagePrefIds.budgets))!;
    expect(line, isNot(contains(':')), reason: 'no "เรียง:" prefix');
    expect(line.split(' | '), hasLength(budgets.fields.length));
    // A page of sets only, all empty: nothing to show.
    final categories = pagePrefPage(PagePrefIds.categories);
    expect(pagePrefSummary(l, categories, const {}), isNull);
    expect(
      pagePrefSummary(l, categories, const {
        'collapsed': ['a', 'b', 'c'],
      }),
      '${l.pagePrefCollapsed} 3',
    );
  });
}
