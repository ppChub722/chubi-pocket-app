import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_identifier.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountIdentifier', () {
    test('normalize keeps digits and hidden-digit marks; looksValid', () {
      expect(AccountIdentifier.normalize('123-4-52780-6'), '1234527806');
      expect(AccountIdentifier.normalize('xxx-x-x2780-x'), 'xxxxx2780x');
      expect(
        AccountIdentifier.normalize('4000 •••• **** 1234'),
        '4000xxxxxxxx1234',
      );
      expect(AccountIdentifier.looksValid('081 234 4464'), isTrue);
      expect(AccountIdentifier.looksValid('12a4'), isFalse);
      expect(AccountIdentifier.digitCount('xxxxx2780x'), 4);
    });

    test('json round trip; unknown kind reads as other', () {
      const id = AccountIdentifier(
        kind: IdentifierKind.bankAccount,
        value: '1234527806',
        bankCode: '004',
      );
      expect(AccountIdentifier.fromJson(id.toJson()), id);
      expect(
        AccountIdentifier.fromJson({'kind': 'iban', 'value': '1234'}).kind,
        IdentifierKind.other,
      );
    });
  });

  group('Account identifiers', () {
    final json = {
      'id': 'a1',
      'name': 'KBank',
      'type': 'bank',
      'balance': 0,
      'currency': 'THB',
      'identifiers': [
        {'kind': 'bank_account', 'value': 'xxxxx2780x', 'bank_code': '004'},
      ],
    };

    test('parsed from the API', () {
      final a = Account.fromJson(json);
      expect(a.identifiers.single.bankCode, '004');
    });

    test('update always sends the list (it replaces the stored one)', () {
      final a = Account.fromJson(json).copyWith(identifiers: const []);
      expect(a.toUpdateJson()['identifiers'], isEmpty);
      expect(
        Account.fromJson(json).toUpdateJson()['identifiers'],
        hasLength(1),
      );
    });

    test('create sends it only when there is one', () {
      final a = Account.fromJson(json);
      expect(a.toCreateJson().containsKey('identifiers'), isTrue);
      expect(
        a
            .copyWith(identifiers: const [])
            .toCreateJson()
            .containsKey('identifiers'),
        isFalse,
      );
    });
  });

  test('Account.fromJson parses savings (and null when absent)', () {
    Map<String, dynamic> savings({bool exceeds = false, bool tracked = true}) =>
        {
          'balance': 1000.0,
          'saved': exceeds ? 1300.0 : 800.0,
          'spare': 200.0,
          'available': tracked ? (exceeds ? -300.0 : 200.0) : null,
          'saved_exceeds_balance': exceeds,
          'over_by': exceeds ? 300.0 : 0.0,
          'buckets': [
            {
              'type': 'goal',
              'id': 'g1',
              'name': 'Japan trip',
              'icon_code': {'icon': 'flag', 'color': 'blue'},
              'amount': 600.0,
            },
            {
              'type': 'spare',
              'name': 'Spare',
              'icon_code': null,
              'amount': 200.0,
            },
          ],
        };
    Account wallet({Map<String, dynamic>? savings, bool track = true}) =>
        Account.fromJson({
      'id': 'w1',
      'name': 'KBank',
      'type': 'bank',
      'group': 'asset',
      'balance': 1000.0,
      'currency': 'THB',
      'icon_code': {'icon': 'bank', 'color': 'blue'},
      'status': 'active',
      'sort_order': 0,
      'my_role': 'owner',
      'can_edit': true,
      'is_shared': false,
      'track_balance': track,
      'savings': ?savings,
    });

    final s = wallet(savings: savings(exceeds: true)).savings!;
    expect(s.saved, 1300);
    expect(s.available, -300);
    expect(s.savedExceedsBalance, isTrue);
    expect(s.overBy, 300);
    expect(s.buckets, hasLength(2));
    expect(s.buckets.first.isGoal, isTrue);
    expect(s.buckets.first.id, 'g1');
    expect(s.buckets.last.isGoal, isFalse);
    expect(wallet().savings, isNull);
    expect(
      wallet(track: false, savings: savings(tracked: false)).savings!.available,
      isNull,
    );
  });

  test('User reads fee_category_id from preferences', () {
    final base = {
      'id': 'u1',
      'username': 'u',
      'display_name': 'U',
      'currency': 'THB',
    };
    expect(User.fromJson(base).feeCategoryId, isNull);
    expect(
      User.fromJson({
        ...base,
        'preferences': {'fee_category_id': 'c1'},
      }).feeCategoryId,
      'c1',
    );
    expect(
      User.fromJson({
        ...base,
        'preferences': {'fee_category_id': null},
      }).feeCategoryId,
      isNull,
    );
  });
}
