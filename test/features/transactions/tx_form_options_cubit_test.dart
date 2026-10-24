import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/categories/data/categories_repository.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/project_directory_cubit.dart';
import 'package:chubi_pocket/features/tags/data/tags_repository.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/form_defaults_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/tx_form_options_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../shared/fake_sync.dart';

class _AccountsRepo extends Fake implements AccountsRepository {}

class _CategoriesRepo extends Fake implements CategoriesRepository {}

class _TagsRepo extends Fake implements TagsRepository {}

const _sample = <String, dynamic>{
  'accounts': [
    {
      'id': 'a1',
      'name': 'Cash',
      'type': 'cash',
      'balance': 120.5,
      'is_default': false,
    },
    {
      'id': 'a2',
      'name': 'Bank',
      'type': 'bank',
      'balance': 5000,
      'is_default': true,
    },
  ],
  'default_account_id': 'a2',
  'categories': [
    {
      'id': 'c1',
      'name': 'Food',
      'type': 'expense',
      'depth': 1,
      'sort_order': 1,
    },
    {
      'id': 'c2',
      'name': 'Lunch',
      'type': 'expense',
      'parent_id': 'c1',
      'parent_name': 'Food',
      'depth': 2,
      'sort_order': 2,
    },
  ],
  'tags': [
    {'id': 't1', 'name': 'trip', 'usage_count': 3},
  ],
  'events': [
    {'id': 'e1', 'name': 'Chiang Mai', 'status': 'active'},
  ],
  'fee_category_id': 'c9',
};

void main() {
  test('TxFormOptions.fromJson parses the sample', () {
    final o = TxFormOptions.fromJson(_sample);
    expect(o.accountList.map((a) => a.id), ['a1', 'a2']);
    expect(o.accountList.first.balance, 120.5);
    expect(o.defaultAccount?.id, 'a2');
    expect(o.categoryList.map((c) => c.id), ['c1', 'c2']);
    expect(o.categoryList.last.parentId, 'c1');
    expect(o.categories.last.parentName, 'Food');
    expect(o.tags.single.name, 'trip');
    expect(o.events.single.name, 'Chiang Mai');
    expect(o.feeCategoryId, 'c9');
  });

  group('derived from the caches', () {
    late AccountsCubit accounts;
    late CategoriesCubit categories;
    late TagsCubit tags;
    late ProjectDirectoryCubit projects;
    late FormDefaultsCubit defaults;
    late TxFormOptionsCubit cubit;

    void build() {
      final sync = testCoordinator();
      accounts = AccountsCubit(repository: _AccountsRepo(), coordinator: sync);
      categories = CategoriesCubit(
        repository: _CategoriesRepo(),
        coordinator: sync,
      );
      tags = TagsCubit(repository: _TagsRepo(), coordinator: sync);
      projects = ProjectDirectoryCubit(coordinator: sync);
      defaults = FormDefaultsCubit(coordinator: sync);
      cubit = TxFormOptionsCubit(
        accounts: accounts,
        categories: categories,
        tags: tags,
        projects: projects,
        defaults: defaults,
      );
    }

    Future<void> dispose() async {
      await cubit.close();
      await Future.wait([
        accounts.close(),
        categories.close(),
        tags.close(),
        projects.close(),
        defaults.close(),
      ]);
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    void fillAll() {
      accounts.applySync({
        'data': [
          for (final (i, a) in (_sample['accounts'] as List).indexed)
            {
              ...(a as Map<String, dynamic>),
              'currency': 'THB',
              'status': 'active',
              'sort_order': i,
            },
        ],
        'total': 2,
        'archived_count': 0,
      });
      categories.applySync({'data': _sample['categories']});
      tags.applySync({'data': _sample['tags']});
      projects.applySync({'data': const []});
      defaults.applySync({'default_account_id': 'a2', 'fee_category_id': 'c9'});
    }

    test('cubit state table', () async {
      final cases =
          <({String name, Future<Object?> Function() run, Object? expected})>[
            (
              name: 'there are no options until every cache has its data',
              run: () async {
                final loadingAtFirst = cubit.state.isLoading;
                accounts.applySync({'data': const [], 'total': 0});
                categories.applySync({'data': const []});
                tags.applySync({'data': const []});
                projects.applySync({'data': const []});
                return [
                  loadingAtFirst,
                  cubit.state.options == null,
                  cubit.state.isLoading,
                ];
              },
              expected: [true, true, true],
            ),
            (
              name:
                  'options appear once everything is loaded and follow the caches',
              run: () async {
                fillAll();
                await settle();
                final o = cubit.state.options!;
                final seen = [
                  cubit.state.status,
                  o.accountList.map((a) => a.id).toList(),
                  o.defaultAccountId,
                  o.feeCategoryId,
                  o.categories.map((c) => c.ref.id).toList(),
                  o.tags.single.name,
                ];

                accounts.patchBalances({'a1': 7});
                await settle();
                return [
                  ...seen,
                  cubit.state.options!.accountList.first.balance,
                ];
              },
              expected: [
                TxFormOptionsStatus.loaded,
                ['a1', 'a2'],
                'a2',
                'c9',
                ['c1', 'c2'],
                'trip',
                7,
              ],
            ),
            (
              name: 'a failing cache with nothing loaded yet shows its error',
              run: () async {
                accounts.syncFailed(
                  const ApiException(code: 'NETWORK', message: 'down'),
                );
                await settle();
                return [
                  cubit.state.status,
                  cubit.state.error?.code,
                  cubit.state.options == null,
                ];
              },
              expected: [TxFormOptionsStatus.error, 'NETWORK', true],
            ),
          ];
      for (final c in cases) {
        build();
        try {
          expect(await c.run(), c.expected, reason: c.name);
        } finally {
          await dispose();
        }
      }
    });
  });
}
