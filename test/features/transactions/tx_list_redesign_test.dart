import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/tags/domain/tag.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/tx_list_filters.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo extends Fake implements TransactionsRepository {
  ListTotals? totals = const ListTotals(income: 100, expense: 40, net: 60);
  int lists = 0;
  TransactionMutationResult? next;

  @override
  Future<TransactionsPage> list({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? from,
    String? to,
    bool noWallet = false,
    String? q,
    List<String> tagIds = const [],
    bool includeChildren = false,
    bool uncategorized = false,
    int page = 1,
    int perPage = 20,
    String sort = 'date_desc',
  }) async {
    lists++;
    return TransactionsPage(
      transactions: const [],
      page: 1,
      perPage: perPage,
      total: 0,
      totalPages: 1,
      totals: totals,
    );
  }

  @override
  Future<TransactionMutationResult> create({
    required TransactionType type,
    String? accountId,
    required double amount,
    required String date,
    String? categoryId,
    String? description,
    String? note,
    String? transferToAccountId,
    List<Map<String, dynamic>>? splits,
    String? sourceProjectTransactionId,
  }) async => next!;
}

void main() {
  // ── The period ────────────────────────────────────────────────────

  group('TxPeriod', () {
    test('month: bounds, steps, forward stops at this month', () {
      final p = TxPeriod.month(DateTime(2026, 10, 15));
      expect(p.bounds, (from: '2026-10-01', to: '2026-10-31'));
      expect(p.step(-1), TxPeriod.month(DateTime(2026, 9)));
      expect(p.step(1)!.bounds.from, '2026-11-01');
      expect(p.canStepForward(DateTime(2026, 10, 20)), isFalse);
      expect(p.step(-1)!.canStepForward(DateTime(2026, 10, 20)), isTrue);
    });

    test('day: one day, steps across month / year ends, stops at today', () {
      final d = TxPeriod.day(DateTime(2026, 10, 10, 18, 30));
      expect(d.bounds, (from: '2026-10-10', to: '2026-10-10'));
      expect(d.step(-1)!.bounds.from, '2026-10-09');
      expect(
        TxPeriod.day(DateTime(2026, 10, 31)).step(1),
        TxPeriod.day(DateTime(2026, 11, 1)),
      );
      expect(
        TxPeriod.day(DateTime(2026, 1, 1)).step(-1)!.bounds.from,
        '2025-12-31',
      );
      expect(d.canStepForward(DateTime(2026, 10, 10, 23)), isFalse);
      expect(d.step(-1)!.canStepForward(DateTime(2026, 10, 10)), isTrue);
      expect(TxPeriod.of(TxPeriodKind.day, DateTime(2026, 10, 10)), d);
    });

    test('a month step crosses the year', () {
      final jan = TxPeriod.month(DateTime(2026, 1, 5));
      expect(jan.step(-1)!.bounds, (from: '2025-12-01', to: '2025-12-31'));
    });

    test('week: Monday to Sunday', () {
      // 2026-10-10 is a Saturday.
      final w = TxPeriod.week(DateTime(2026, 10, 10));
      expect(w.bounds, (from: '2026-10-05', to: '2026-10-11'));
      expect(w.step(1)!.bounds.from, '2026-10-12');
    });

    test('year', () {
      final y = TxPeriod.year(DateTime(2026, 6, 1));
      expect(y.bounds, (from: '2026-01-01', to: '2026-12-31'));
      expect(y.step(-1), TxPeriod.year(DateTime(2025)));
    });

    test('ทั้งหมด and a custom range have no neighbours', () {
      expect(TxPeriod.all.bounds, (from: null, to: null));
      expect(TxPeriod.all.step(1), isNull);
      final c = TxPeriod.custom(DateTime(2026, 10, 3), DateTime(2026, 10, 9));
      expect(c.bounds, (from: '2026-10-03', to: '2026-10-09'));
      expect(c.step(-1), isNull);
    });

    test('switching unit keeps the place', () {
      final week = TxPeriod.of(TxPeriodKind.week, DateTime(2026, 10, 1));
      expect(week.bounds.from, '2026-09-28');
      expect(
        TxPeriod.of(TxPeriodKind.month, week.start),
        TxPeriod.month(DateTime(2026, 9)),
      );
    });
  });

  // ── The filters ───────────────────────────────────────────────────

  test('sameFiltersAs ignores the period, sees tags in any order', () {
    final a = TxFilters(
      period: TxPeriod.month(DateTime(2026, 10)),
      tags: const [
        Tag(id: 't1', name: 'a'),
        Tag(id: 't2', name: 'b'),
      ],
    );
    final b = a.copyWith(
      period: TxPeriod.all,
      tags: const [
        Tag(id: 't2', name: 'b'),
        Tag(id: 't1', name: 'a'),
      ],
    );
    expect(a.sameFiltersAs(b), isTrue);
    expect(a.sameFiltersAs(b.copyWith(type: TransactionType.expense)), isFalse);
    expect(a.sameFiltersAs(b.copyWith(tags: const [])), isFalse);
  });

  test('wallet filters compare by wallet id', () {
    Account acc(String id) => Account.fromJson({
      'id': id,
      'name': id,
      'type': 'bank',
      'balance': 0,
      'currency': 'THB',
    });
    expect(TxOneWallet(acc('a')), TxOneWallet(acc('a')));
    expect(TxOneWallet(acc('a')) == TxOneWallet(acc('b')), isFalse);
    expect(const TxNoWallet() == const TxAnyWallet(), isFalse);
  });

  // ── Totals ────────────────────────────────────────────────────────

  test('ListTotals reads the BE shape; absent → null', () {
    final t = ListTotals.fromJson({
      'income': 12000.0,
      'expense': 8540,
      'net': 3460.0,
      'count': 57,
    })!;
    expect(t.income, 12000);
    expect(t.expense, 8540);
    expect(t.net, 3460);
    expect(t.count, 57);
    expect(ListTotals.fromJson(null), isNull);
  });

  test('the cubit keeps the totals; a write re-fetches them', () async {
    final repo = _Repo();
    final cubit = TransactionsCubit(repository: repo);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.totals?.net, 60);
    final before = repo.lists;
    repo.next = TransactionMutationResult.single(
      Transaction.fromJson({
        'id': 'n',
        'type': 'expense',
        'amount': 10,
        'date': '2026-10-10',
      }),
    );
    await cubit.add(
      type: TransactionType.expense,
      amount: 10,
      date: '2026-10-10',
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.lists, greaterThan(before));
  });

  test('no totals from the server → none in state', () async {
    final repo = _Repo()..totals = null;
    final cubit = TransactionsCubit(repository: repo);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.totals, isNull);
  });

  // ── The side sheet ────────────────────────────────────────────────

  group('showSideSheet', () {
    Future<Future<String?>> open(WidgetTester t) async {
      late Future<String?> result;
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => result = showSideSheet<String>(
                    context,
                    builder: (sheet) => SideSheetScaffold(
                      title: 'ตัวกรอง',
                      body: const Text('body'),
                      footer: TextButton(
                        onPressed: () => Navigator.of(sheet).pop('applied'),
                        child: const Text('apply'),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      return result;
    }

    testWidgets('slides in on the right, ~85% wide', (t) async {
      await open(t);
      final panel = t.getRect(find.byType(SideSheetScaffold));
      final screen = t.view.physicalSize / t.view.devicePixelRatio;
      expect(panel.right, closeTo(screen.width, 0.5));
      expect(
        panel.width,
        closeTo((screen.width * 0.85).clamp(0, 420).toDouble(), 0.5),
      );
    });

    testWidgets('resolves what it pops with', (t) async {
      final result = await open(t);
      await t.tap(find.text('apply'));
      await t.pumpAndSettle();
      expect(await result, 'applied');
    });

    testWidgets('a swipe to the right closes it', (t) async {
      final result = await open(t);
      await t.fling(find.text('body'), const Offset(300, 0), 1000);
      await t.pumpAndSettle();
      expect(find.text('body'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('tapping the scrim closes it', (t) async {
      await open(t);
      await t.tapAt(const Offset(10, 300));
      await t.pumpAndSettle();
      expect(find.text('body'), findsNothing);
    });
  });
}
