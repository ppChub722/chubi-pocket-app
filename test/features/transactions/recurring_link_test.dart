import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_link_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/recurring_link.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

LinkCandidate _candidate(String id, String name, {double? amount}) {
  final j = _setting(id, name, amount: amount);
  return LinkCandidate(
    setting: Recurring.fromJson(j),
    occurrence: LinkOccurrence.fromJson(
      j['current_occurrence'] as Map<String, dynamic>,
    ),
  );
}

class _FakeRepo implements RecurringLinkRepository {
  _FakeRepo({
    this.rows = const [],
    this.loadError,
    this.linkError,
    this.differs,
  });

  final List<LinkCandidate> rows;
  final ApiException? loadError;
  final ApiException? linkError;

  /// (rule amount, tx amount) → amount_differs.
  final (double, double)? differs;
  final links = <String>[];
  final puts = <(String, double)>[];
  TransactionType? askedType;

  @override
  Future<List<LinkCandidate>> candidates(TransactionType type) async {
    askedType = type;
    if (loadError != null) throw loadError!;
    return rows;
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
        builder: (context, child) => AppUiConfig(child: child!),
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

  final rows = [_candidate('1', 'รถ', amount: 3023), _candidate('2', 'ค่าน้ำ')];

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
    expect(repo.askedType, TransactionType.expense);
    expect(find.text('ผูกกับรายการประจำ'), findsOneWidget);
    // Groups from the BE answer: recurring, then the reminders (no amount).
    expect(find.text('เตือนจ่าย'), findsOneWidget);
    expect(find.text('รอยอด'), findsOneWidget);
    expect(find.text('สร้างรายการประจำใหม่จากรายการนี้'), findsOneWidget);
    // Search filters on the loaded list.
    await t.enterText(find.byType(TextField), 'น้ำ');
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
