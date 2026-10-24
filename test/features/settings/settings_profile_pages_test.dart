import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /users/me` as prod answers (with `default_account` and
/// `auto_copy_own_event_bills`).
Map<String, dynamic> _meJson({
  Map<String, dynamic>? defaultAccount = const {
    'id': 'w1',
    'name': 'Doraemon',
    'icon_code': {'icon': 'bank', 'color': 'blue'},
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
  'auto_copy_own_event_bills': true,
  'notification_summary': {'on': 9, 'auto': 2},
  'preferences': {
    'timezone': null,
    'theme': null,
    'language': null,
    'fee_category_id': null,
  },
  'created_at': '2026-09-16T03:00:00Z',
  'updated_at': '2026-10-06T08:59:00Z',
};

void main() {
  test('User parses the prod-shaped /users/me (default_account, auto copy)', () {
    final u = User.fromJson(_meJson());
    expect(u.defaultAccount?.id, 'w1');
    expect(u.defaultAccount?.name, 'Doraemon');
    expect(u.autoCopyOwnEventBills, isTrue);
    final none = User.fromJson(_meJson(defaultAccount: null));
    expect(none.defaultAccount, isNull);
    expect(u.notificationSummary?.on, 9);
    expect(u.notificationSummary?.auto, 2);
    final bare = Map<String, dynamic>.of(_meJson())
      ..remove('notification_summary');
    expect(User.fromJson(bare).notificationSummary, isNull);
  });
}
