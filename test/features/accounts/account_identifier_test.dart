import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_identifier.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountIdentifier', () {
    test('normalize keeps digits and hidden-digit marks', () {
      expect(AccountIdentifier.normalize('123-4-52780-6'), '1234527806');
      expect(AccountIdentifier.normalize('xxx-x-x2780-x'), 'xxxxx2780x');
      expect(
        AccountIdentifier.normalize('4000 •••• **** 1234'),
        '4000xxxxxxxx1234',
      );
    });

    test('looksValid / digitCount', () {
      expect(AccountIdentifier.looksValid('081 234 4464'), isTrue);
      expect(AccountIdentifier.looksValid('12a4'), isFalse);
      expect(AccountIdentifier.digitCount('xxxxx2780x'), 4);
    });

    test('formatted groups by kind and length; masked shows the last 4', () {
      const bank = AccountIdentifier(
        kind: IdentifierKind.bankAccount,
        value: '1234527806',
      );
      expect(bank.formatted, '123-4-52780-6');
      expect(bank.masked, '•••• 7806');
      const slip = AccountIdentifier(
        kind: IdentifierKind.other,
        value: 'xxxxx2780x',
      );
      expect(slip.formatted, 'xxxxx2780x');
      expect(slip.masked, '•••• 2780');
      const phone = AccountIdentifier(
        kind: IdentifierKind.promptPay,
        value: '0812344464',
      );
      expect(phone.formatted, '081-234-4464');
      const card = AccountIdentifier(
        kind: IdentifierKind.card,
        value: '4000123412341234',
      );
      expect(card.formatted, '4000 1234 1234 1234');
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
