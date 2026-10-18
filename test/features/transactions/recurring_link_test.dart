import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_link_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/presentation/cubit/recurring_directory_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/recurring_link.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fake_sync.dart';

/// The รายการประจำ row of the "ผูกกับ" section: the picker (groups, search,
/// failing load), the link call and the amount question.
Map<String, dynamic> _setting(
  String id,
  String name, {
  double? amount,
  String type = 'expense',
}) => {
  'id': id,
  'name': name,
  'type': type,
  'amount': amount,
  'status': 'active',
  'start_date': '2026-09-16',
  'rule': {
    'freq': 'monthly',
    'interval': 1,
    'monthly': {'mode': 'day', 'day': 16},
  },
  'current_occurrence': {
    'item_id': 'item-$id',
    'date': '2026-10-16',
    'days_until': 0,
    'amount': amount,
    'status': amount == null ? 'not_created' : 'upcoming',
  },
};

/// `unlinkRecurringItem` answer: the occurrence, open again.
Map<String, dynamic> _openItem(String id) => {
  'id': id,
  'seq': 2,
  'total': 12,
  'date': '2026-10-16',
  'days_until': 0,
  'type': 'expense',
  'amount': 3023,
  'status': 'not_created',
  'tags': <dynamic>[],
};

class _FakeRepo implements RecurringLinkRepository {
  _FakeRepo({
    this.rows = const [],
    this.loadError,
    this.linkError,
    this.differs,
  });

  final List<Map<String, dynamic>> rows;
  final ApiException? loadError;
  final ApiException? linkError;

  /// (rule amount, tx amount) → amount_differs.
  final (double, double)? differs;
  final links = <String>[];
  final puts = <(String, double)>[];
  final unlinks = <String>[];
  ApiException? unlinkError;

  @override
  Future<RecurringItem> unlink(String itemId) async {
    unlinks.add(itemId);
    if (unlinkError != null) throw unlinkError!;
    return RecurringItem.fromJson(_openItem(itemId));
  }

  @override
  Future<LinkResult> link(String itemId, String transactionId) async {
    links.add('$itemId<-$transactionId');
    if (linkError != null) throw linkError!;
    return LinkResult(
      transaction: null,
      amountDiffers: differs != null,
      ruleAmount: differs?.$1,
      transactionAmount: differs?.$2 ?? 0,
    );
  }

  @override
  Future<void> updateAmount(String recurringId, double amount) async =>
      puts.add((recurringId, amount));
}

const _category = {'id': 'cat-1', 'name': 'Car', 'type': 'expense'};

/// The directory the picker reads: the fake's rows as the sync would land
/// them, or a failed sync.
final _directories = Expando<RecurringDirectoryCubit>();

RecurringDirectoryCubit _directory(_FakeRepo repo) {
  final held = _directories[repo];
  if (held != null) return held;
  final directory = RecurringDirectoryCubit(coordinator: testCoordinator());
  // A failing sync lands after the sheet opens (opening retries a failed one).
  if (repo.loadError == null) directory.applySync({'data': repo.rows});
  return _directories[repo] = directory;
}

void main() {
  final messages = <String>[];

  Future<RecurringLinkHandle> pump(WidgetTester t, _FakeRepo repo) async {
    messages.clear();
    final handle = RecurringLinkHandle(repository: repo);
    addTearDown(handle.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        builder: (context, child) =>
            BlocProvider<RecurringDirectoryCubit>.value(
              value: _directory(repo),
              child: AppUiConfig(child: child!),
            ),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: handle,
            builder: (context, _) => SingleChildScrollView(
              child: SplitEventSection(
                first: true,
                variant: SplitEventVariant.compact,
                recurring: handle.slot(
                  context,
                  type: TransactionType.expense,
                  onTap: () => handle.choose(
                    context,
                    type: TransactionType.expense,
                    createRoute: '/recurring/new',
                  ),
                  onClear: handle.clear,
                  error: messages.add,
                  done: messages.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return handle;
  }

  final rows = [_setting('1', 'รถ', amount: 3023), _setting('2', 'ค่าน้ำ')];

  Future<void> pickCar(WidgetTester t, RecurringLinkHandle h) async {
    await t.tap(find.text('เลือกรายการประจำ'));
    await t.pumpAndSettle();
    await t.tap(find.text('รถ'));
    await t.pumpAndSettle();
  }

  Future<LinkResult?> link(WidgetTester t, RecurringLinkHandle h) async {
    final ctx = t.element(find.byType(SplitEventSection));
    final r = await t.runAsync(() => h.link(ctx, 'tx-1', error: messages.add));
    await t.pump();
    return r;
  }

  testWidgets('empty row: add chip; picker groups, reminder, search, pick', (
    t,
  ) async {
    final repo = _FakeRepo(rows: rows);
    await pump(t, repo);
    expect(find.text('รายการประจำ'), findsOneWidget);
    expect(find.text('เลือกรายการประจำ'), findsOneWidget);
    await t.tap(find.text('เลือกรายการประจำ'));
    await t.pumpAndSettle();
    expect(find.text('ผูกกับรายการประจำ'), findsOneWidget);
    // Groups from the BE answer: recurring, then the reminders (no amount).
    expect(find.text('เตือนจ่าย'), findsOneWidget);
    expect(find.text('รอยอด'), findsOneWidget);
    expect(find.text('สร้างรายการประจำใหม่จากรายการนี้'), findsOneWidget);
    // Search (behind the sheet's 🔍) filters on the loaded list.
    await t.tap(find.byIcon(AppIcons.search).last);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'น้ำ');
    await t.pump();
    expect(find.text('รถ'), findsNothing);
    expect(find.text('ค่าน้ำ'), findsOneWidget);
    // Picking fills the row with "name · งวด date".
    await t.tap(find.text('ค่าน้ำ'));
    await t.pumpAndSettle();
    expect(find.textContaining('ค่าน้ำ · งวด'), findsOneWidget);
    expect(find.text('เลือกรายการประจำ'), findsNothing);
  });

  testWidgets('failing load: the error with a retry, nothing picked', (
    t,
  ) async {
    final repo = _FakeRepo(
      loadError: const ApiException(code: 'INTERNAL', message: 'boom'),
    );
    await pump(t, repo);
    await t.tap(find.text('เลือกรายการประจำ'));
    // The open starts a load: a skeleton, which never settles.
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    _directory(repo).syncFailed(repo.loadError!);
    await t.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('รถ'), findsNothing);
  });

  testWidgets('amount differs: ไม่ต้อง = no PUT, link kept', (t) async {
    final repo = _FakeRepo(rows: rows, differs: (3023, 3100));
    final h = await pump(t, repo);
    await pickCar(t, h);
    await link(t, h);
    expect(repo.links, ['item-1<-tx-1']);
    expect(
      t.widget<AskCard>(find.byType(AskCard)).message,
      'ยอดไม่ตรงกับที่ตั้งไว้ (฿3,023.00 → ฿3,100.00) อัปเดตยอดรายการประจำด้วยไหม?',
    );
    await t.tap(find.text('ไม่ต้อง'));
    await t.pump();
    expect(repo.puts, isEmpty);
    expect(find.byType(AskCard), findsNothing);
    expect(find.textContaining('รถ · งวด'), findsOneWidget);
  });

  testWidgets('amount differs: อัปเดต = one PUT with the tx amount', (t) async {
    final repo = _FakeRepo(rows: rows, differs: (3023, 3100));
    final h = await pump(t, repo);
    await pickCar(t, h);
    await link(t, h);
    await t.tap(find.text('อัปเดต'));
    await t.pumpAndSettle();
    expect(repo.puts, [('1', 3100.0)]);
    expect(messages, ['อัปเดตยอดรายการประจำแล้ว']);
    expect(find.byType(AskCard), findsNothing);
    expect(find.textContaining('รถ · งวด'), findsOneWidget);
  });

  testWidgets('same amount: no question', (t) async {
    final repo = _FakeRepo(rows: rows);
    final h = await pump(t, repo);
    await pickCar(t, h);
    await link(t, h);
    expect(find.byType(AskCard), findsNothing);
  });

  testWidgets('409 ITEM_ALREADY_LINKED: its own message, no question', (
    t,
  ) async {
    final repo = _FakeRepo(
      rows: rows,
      linkError: const ApiException(
        code: 'ITEM_ALREADY_LINKED',
        message: 'x',
        statusCode: 409,
      ),
    );
    final h = await pump(t, repo);
    await pickCar(t, h);
    final r = await link(t, h);
    expect(r, isNull);
    expect(messages, ['งวดนี้ผูกไปแล้ว (หรือรายการนี้ผูกอยู่แล้ว)']);
    expect(find.byType(AskCard), findsNothing);
  });

  testWidgets('likely rows form the FIRST group and leave their own group', (
    t,
  ) async {
    final repo = _FakeRepo(
      rows: [
        {..._setting('1', 'รถ', amount: 3023), 'category': _category},
        _setting('2', 'ค่าน้ำ'),
        _setting('3', 'ค่าไฟ', amount: 900),
      ],
    );
    final handle = RecurringLinkHandle(repository: repo);
    addTearDown(handle.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        builder: (context, child) =>
            BlocProvider<RecurringDirectoryCubit>.value(
              value: _directory(repo),
              child: AppUiConfig(child: child!),
            ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => handle.choose(
                context,
                type: TransactionType.expense,
                createRoute: '/recurring/new',
                categoryId: 'cat-1',
                amount: 3100,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    // The hints (category, amount) pick the likely ones on the device.
    final likely = t.getTopLeft(find.text('น่าจะใช่')).dy;
    final recurring = t.getTopLeft(find.text('รายการประจำ').first).dy;
    final reminders = t.getTopLeft(find.text('เตือนจ่าย')).dy;
    final car = t.getTopLeft(find.text('รถ')).dy;
    final power = t.getTopLeft(find.text('ค่าไฟ')).dy;
    final water = t.getTopLeft(find.text('ค่าน้ำ')).dy;
    expect(likely < car && car < recurring, isTrue);
    expect(recurring < power && power < reminders, isTrue);
    expect(reminders < water, isTrue);
    // One row, one place.
    expect(find.text('รถ'), findsOneWidget);
  });

  testWidgets('saved link ✕: ONE unlink call, then the row callback', (
    t,
  ) async {
    final repo = _FakeRepo();
    final handle = RecurringLinkHandle(repository: repo);
    addTearDown(handle.dispose);
    var unlinked = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        builder: (context, child) =>
            BlocProvider<RecurringDirectoryCubit>.value(
              value: _directory(repo),
              child: AppUiConfig(child: child!),
            ),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: handle,
            builder: (context, _) => SplitEventSection(
              first: true,
              variant: SplitEventVariant.compact,
              recurring: handle.slot(
                context,
                type: TransactionType.expense,
                linkedName: 'รถ',
                onUnlink: () => handle.unlinkNow(
                  context,
                  'item-1',
                  onUnlinked: () => unlinked++,
                  error: messages.add,
                ),
                error: messages.add,
                done: messages.add,
              ),
            ),
          ),
        ),
      ),
    );
    messages.clear();
    await t.tap(find.byIcon(AppIcons.close).first);
    await t.pumpAndSettle();
    expect(repo.unlinks, ['item-1']);
    expect(unlinked, 1);
    expect(messages, isEmpty);
  });

  testWidgets('unlink failure: message, row callback not run', (t) async {
    final repo = _FakeRepo()
      ..unlinkError = const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'no linked transaction',
        statusCode: 400,
      );
    final handle = RecurringLinkHandle(repository: repo);
    addTearDown(handle.dispose);
    var unlinked = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        builder: (context, child) =>
            BlocProvider<RecurringDirectoryCubit>.value(
              value: _directory(repo),
              child: AppUiConfig(child: child!),
            ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => handle.unlinkNow(
                context,
                'item-1',
                onUnlinked: () => unlinked++,
                error: messages.add,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    messages.clear();
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(unlinked, 0);
    expect(messages, ['no linked transaction']);
  });

  test('a pick of another type is not offered for this one', () {
    final h = RecurringLinkHandle(repository: _FakeRepo());
    addTearDown(h.dispose);
    expect(h.candidateFor(TransactionType.income), isNull);
  });

  test('recurringCreateRoute carries the prefill', () {
    final r = recurringCreateRoute(
      type: TransactionType.expense,
      amount: 3100,
      categoryId: 'c1',
      accountId: 'a1',
      name: ' Car ',
    );
    final u = Uri.parse(r);
    expect(u.path, '/recurring/new');
    expect(u.queryParameters, {
      'type': 'expense',
      'amount': '3100.0',
      'category': 'c1',
      'account': 'a1',
      'name': 'Car',
    });
  });
}
