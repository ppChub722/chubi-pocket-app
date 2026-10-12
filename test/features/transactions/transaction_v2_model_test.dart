import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _account(String id, String name) => {
  'id': id,
  'name': name,
  'icon_code': {
    'icon': 'wallet',
    'bgColors': ['#112233'],
  },
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
  'logo_url': 'https://x/logo.png',
};

Map<String, dynamic> _row({
  String id = 't1',
  String type = 'expense',
  String kind = 'TRANSFER_OUT',
  Map<String, dynamic>? peer,
}) => {
  'id': id,
  'type': type,
  'amount': 250,
  'date': '2026-10-12',
  'currency': 'THB',
  'account': _account('a1', 'KBank'),
  'category': {
    'id': 'c1',
    'name': 'Food',
    'type': 'expense',
    'icon_code': {'icon': 'food'},
    'is_system': true,
    'system_kind': kind,
    'parent_id': 'c0',
  },
  'project': {'id': 'p1', 'name': 'Trip', 'status': 'active'},
  'counterparty': {
    'entry_id': 'e1',
    'key': 'n:bee',
    'person': {
      'name': 'Bee',
      'contact_id': null,
      'icon_code': null,
      'linked': false,
      'linked_user_id': null,
    },
    'direction': 'received',
    'paid': true,
  },
  'split_count': 1,
  'splits': [
    {
      'debt_id': 'd1',
      'person': {
        'name': 'Bee',
        'contact_id': 'k1',
        'linked': true,
        'linked_user_id': 'u2',
      },
      'amount': 100,
      'settled_amount': 40,
      'direction': 'i_owe',
    },
  ],
  'transfer_peer': ?peer,
};

void main() {
  test('Transaction.fromJson reads the embedded v2 refs', () {
    final t = Transaction.fromJson(_row());
    expect(t.accountId, 'a1');
    expect(t.categoryId, 'c1');
    expect(t.projectId, 'p1');
    expect(t.currency, 'THB');
    expect(t.isDebtEntry, isTrue);
    expect(t.counterparty?.entryId, 'e1');
    expect(t.counterparty?.key, 'n:bee');
    expect(t.counterparty?.paid, isTrue);

    final a = t.account!;
    expect(a.name, 'KBank');
    expect(a.type, AccountType.bank);
    expect(a.iconCode?.icon, 'wallet');
    expect(a.logoUrl, 'https://x/logo.png');
    expect(a.isLiability, isFalse);

    final c = t.category!;
    expect(c.type, CategoryType.expense);
    expect(c.iconCode?.icon, 'food');
    expect(c.isSystem, isTrue);
    expect(c.systemKind, 'TRANSFER_OUT');
    expect(c.parentId, 'c0');

    expect(t.project, const EventRef(id: 'p1', name: 'Trip'));

    final s = t.splits.single;
    expect(s.person.name, 'Bee');
    expect(s.personName, 'Bee');
    expect(s.contactId, 'k1');
    expect(s.person.linked, isTrue);
    expect(s.person.linkedUserId, 'u2');
    expect(s.owedToMe, isFalse);
    expect(s.outstanding, 60);
  });

  test('no refs on the wire → null ids', () {
    final t = Transaction.fromJson({
      'id': 'n',
      'type': 'income',
      'amount': 1,
      'date': '2026-10-12',
    });
    expect(t.accountId, isNull);
    expect(t.categoryId, isNull);
    expect(t.projectId, isNull);
    expect(t.isDebtEntry, isFalse);
    expect(t.transferPeer, isNull);
  });

  test('transfer direction comes from transfer_peer', () {
    final out = Transaction.fromJson(
      _row(
        type: 'transfer',
        kind: 'TRANSFER_IN', // the peer wins over the category kind
        peer: {
          'id': 't2',
          'direction': 'out',
          'account': _account('a2', 'Cash'),
        },
      ),
    );
    expect(out.transferPeer!.id, 't2');
    expect(out.transferPeer!.account.id, 'a2');
    expect(out.isTransferOut, isTrue);
    expect(out.isTransferIn, isFalse);
    expect(out.signedAmount, -250);

    final inn = Transaction.fromJson(
      _row(
        type: 'transfer',
        peer: {
          'id': 't2',
          'direction': 'in',
          'account': _account('a2', 'Cash'),
        },
      ),
    );
    expect(inn.isTransferIn, isTrue);
    expect(inn.isTransferOut, isFalse);
    expect(inn.signedAmount, 250);
  });

  test('TransactionWriteResult parses rows and account_balances', () {
    final r = TransactionWriteResult.fromJson({
      'rows': [
        _row(
          type: 'transfer',
          peer: {
            'id': 't2',
            'direction': 'in',
            'account': _account('a2', 'Cash'),
          },
        ),
        _row(id: 't2', type: 'transfer', kind: 'TRANSFER_IN'),
      ],
      'account_balances': [
        {'account_id': 'a1', 'balance': 750},
        {'account_id': 'a2', 'balance': 1250.5},
      ],
    });
    expect(r.rows, hasLength(2));
    expect(r.isTransfer, isTrue);
    expect(r.primary.id, 't1');
    expect(r.accountBalances, {'a1': 750.0, 'a2': 1250.5});
  });

  test('DeleteTransactionResult parses id and balances', () {
    final r = DeleteTransactionResult.fromJson({
      'id': 't9',
      'account_balances': [
        {'account_id': 'a1', 'balance': 1000},
      ],
    });
    expect(r.id, 't9');
    expect(r.accountBalances, {'a1': 1000.0});
    expect(
      DeleteTransactionResult.fromJson({'id': 'x'}).accountBalances,
      isEmpty,
    );
  });

  test('WalletBalance.mapOf', () {
    expect(WalletBalance.mapOf(null), isEmpty);
    expect(WalletBalance.mapOf(const []), isEmpty);
    expect(
      WalletBalance.mapOf([
        {'account_id': 'a', 'balance': 1},
        {'account_id': 'b', 'balance': -2.5},
      ]),
      {'a': 1.0, 'b': -2.5},
    );
    expect(
      WalletBalance.fromJson({'account_id': 'a', 'balance': 3}),
      const WalletBalance(accountId: 'a', balance: 3),
    );
  });
}
