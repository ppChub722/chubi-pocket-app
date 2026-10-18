import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/tags/domain/tag.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(
  String id,
  String name, {
  String? parent,
  int sort = 0,
  CategoryType type = CategoryType.expense,
  bool system = false,
}) => Category(
  id: id,
  name: name,
  type: type,
  parentId: parent,
  sortOrder: sort,
  isSystem: system,
);

Account _acc(
  String id, {
  AccountStatus status = AccountStatus.active,
  int sort = 0,
}) => Account(
  id: id,
  name: 'Wallet $id',
  type: AccountType.bank,
  balance: 10,
  currency: 'THB',
  status: status,
  sortOrder: sort,
);

Project _event(
  String id, {
  ProjectStatus status = ProjectStatus.active,
  MemberRole? role,
}) => Project(
  id: id,
  ownerUserId: 'u',
  name: 'Event $id',
  status: status,
  myRole: role,
);

void main() {
  test(
    'wallets: active only, in the cache order, with the default flagged',
    () {
      final o = TxFormOptions.fromCaches(
        accounts: [
          _acc('a'),
          _acc('b', status: AccountStatus.archived),
          _acc('c'),
        ],
        categories: const [],
        tags: const [],
        events: const [],
        defaultAccountId: 'c',
      );
      expect([for (final a in o.accounts) a.ref.id], ['a', 'c']);
      expect(o.accounts.last.isDefault, isTrue);
      expect(o.accounts.first.isDefault, isFalse);
      expect(o.defaultAccount?.id, 'c');
    },
  );

  test(
    'categories: own categories only, walked as a tree with depth and parent name',
    () {
      final o = TxFormOptions.fromCaches(
        accounts: const [],
        categories: [
          _cat('sys', 'Transfer', system: true),
          _cat('food', 'Food', sort: 1),
          _cat('coffee', 'Coffee', parent: 'food'),
          _cat('latte', 'Latte', parent: 'coffee'),
          _cat('deep', 'Too deep', parent: 'latte'),
          _cat('rent', 'Rent', sort: 0),
          _cat('pay', 'Salary', type: CategoryType.income),
        ],
        tags: const [],
        events: const [],
      );
      expect(
        [
          for (final c in o.categories)
            '${c.ref.id}:${c.depth}:${c.parentName}',
        ],
        [
          'rent:1:null',
          'food:1:null',
          'coffee:2:Food',
          'latte:3:Coffee',
          'pay:1:null',
        ],
      );
    },
  );

  test('tags keep the cached order; events keep what the caller passes', () {
    final o = TxFormOptions.fromCaches(
      accounts: const [],
      categories: const [],
      tags: const [
        Tag(id: 't1', name: 'b', usageCount: 5),
        Tag(id: 't2', name: 'a'),
      ],
      events: [_event('e1', role: MemberRole.contributor)],
      feeCategoryId: 'fee',
    );
    expect([for (final t in o.tags) t.id], ['t1', 't2']);
    expect(o.events.single.id, 'e1');
    expect(o.feeCategoryId, 'fee');
  });
}
