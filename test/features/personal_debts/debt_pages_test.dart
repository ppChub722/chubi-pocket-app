import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/data/data_changes.dart' as changes;
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_people_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_person_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/pages/debt_person_page.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/pages/personal_debts_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/fake_sync.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Client extends Mock implements ApiClient {}

/// Answers from prod-shaped JSON (openapi.yaml, tag Debts); records calls.
class _Repo extends PersonalDebtsRepository {
  _Repo() : super(client: _Client());

  final calls = <String>[];
  Object? failPerson;

  /// The net the person page answers with (0 = a settled person).
  num personNet = 200;

  /// Earlier-cycle entries behind the fold.
  int earlier = 1;

  @override
  Future<DebtPersonDetail> person(
    String key, {
    int perPage = 30,
    DebtCycle cycle = DebtCycle.current,
  }) async {
    calls.add('person $key cycle=${cycle.wire}');
    final f = failPerson;
    if (f != null) {
      failPerson = null;
      throw f;
    }
    return DebtPersonDetail.fromJson({
      ..._person(key, 'Mom', personNet, contactId: 'c1', days: 6),
      'counts': {
        'entries': 2 + earlier,
        'money': 1,
        'current': 2,
        'earlier': earlier,
      },
      'items': [
        _entry('e1', 'paid', 300, 'Lunch money', withTx: true),
        _entry('e2', 'received', 100, null),
      ],
      'summary_message': {
        'text': 'Summary with Mom\n• Lunch money +300\nTotal 200',
        'entries': 2,
        'net': personNet,
      },
      'pagination': {'page': 1, 'per_page': 30, 'total': 2, 'total_pages': 1},
    });
  }

  @override
  Future<DebtEntriesPage> entries(
    String key, {
    DebtEntryQuery query = const DebtEntryQuery(),
    int page = 1,
    int perPage = 30,
    DebtCycle? cycle,
  }) async {
    calls.add('entries cycle=${cycle?.wire} q=${query.q}');
    return DebtEntriesPage.fromJson({
      'data': [_entry('old1', 'received', 200, 'Old repayment')],
      'pagination': {'page': 1, 'per_page': 30, 'total': 1, 'total_pages': 1},
    });
  }
}

Map<String, dynamic> _person(
  String key,
  String name,
  num net, {
  String? contactId,
  int? days,
}) => {
  'cleared_at': '2026-10-05',
  'days_outstanding': days,
  'key': key,
  'person': {
    'name': name,
    'contact_id': contactId,
    'icon_code': null,
    'linked': false,
    'linked_user_id': null,
  },
  'net': net,
  'open_count': 1,
  'entry_count': 2,
  'last_activity_at': '2026-10-12',
};

Map<String, dynamic> _peopleBody() => {
  'data': [
    _person('c:c1', 'Mom', 200, contactId: 'c1', days: 45),
    _person('n:bank', 'Bank', -50, days: 6),
    _person('n:gone', 'Gone', 0),
  ],
  'totals': <String, dynamic>{},
  'pagination': {'page': 1, 'per_page': 3, 'total': 3, 'total_pages': 1},
};

Map<String, dynamic> _entry(
  String id,
  String dir,
  num amount,
  String? description, {
  bool withTx = false,
}) => {
  'id': id,
  'key': 'c:c1',
  'direction': dir,
  'amount': amount,
  'date': '2026-10-12',
  'description': description,
  'note': null,
  'paid': false,
  'source': null,
  'transaction': withTx
      ? {
          'id': 'tx-$id',
          'account': {
            'id': 'a1',
            'name': 'Cash',
            'icon_code': null,
            'logo_url': null,
            'type': 'cash',
            'group': 'asset',
            'currency': 'THB',
            'archived': false,
          },
        }
      : null,
  'created_at': '2026-10-12T09:30:00Z',
  'in_current_cycle': !id.startsWith('old'),
  'updated_at': '2026-10-12T09:30:00Z',
};

void main() {
  late _Repo repo;
  late QuickCreateContext registry;
  late DebtDirectoryCubit directory;

  Future<void> pump(WidgetTester t, Widget page, {bool people = true}) async {
    if (people) directory.applySync(_peopleBody());
    // A phone in portrait: the error view's retry sits low on the page.
    t.view.physicalSize = const Size(400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    registry = QuickCreateContext();
    addTearDown(registry.dispose);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final contacts = _Contacts();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => contacts.state).thenReturn(const ContactsState());
    await t.pumpWidget(
      RepositoryProvider<PersonalDebtsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<ContactsCubit>.value(value: contacts),
            BlocProvider<DebtDirectoryCubit>.value(value: directory),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(
              child: QuickCreateContextScope(registry: registry, child: child!),
            ),
            home: page,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  setUp(() {
    repo = _Repo();
    directory = DebtDirectoryCubit(coordinator: testCoordinator());
    addTearDown(directory.close);
    ToolbarToggleState.resetAll();
  });

  group('people list', () {
    testWidgets('🔍 in the card; toolbar hidden until tapped; red dot', (
      t,
    ) async {
      await pump(t, const PersonalDebtsPage());
      final toggle = find.descendant(
        of: find.byType(AppHeroCard),
        matching: find.byType(ToolbarToggleButton),
      );
      expect(toggle, findsOneWidget);
      expect(find.byType(AppChip), findsNothing);
      CardActionButton button() => t.widget(
        find.descendant(
          of: find.byType(ToolbarToggleButton),
          matching: find.byType(CardActionButton),
        ),
      );
      expect(button().showDot, isFalse);
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(find.widgetWithText(AppChip, 'Show cleared'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Mom');
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(find.widgetWithText(AppChip, 'Show cleared'), findsNothing);
      expect(button().showDot, isTrue);
    });

    testWidgets('open = 1 call; tiles, alert, net line and rows from the BE', (
      t,
    ) async {
      await pump(t, const PersonalDebtsPage());
      expect(find.text('Total outstanding'), findsOneWidget);
      // The tiles carry the BE's people counts + amounts.
      expect(find.text('To receive | 1 people'), findsOneWidget);
      expect(find.text('To pay | 1 people'), findsOneWidget);
      expect(find.text('฿200'), findsWidgets);
      expect(find.text('฿50'), findsWidgets);
      // Both sides open → the BE's net line; the amber alert.
      expect(find.byType(DebtNetLine), findsOneWidget);
      expect(find.text('Over 30 days: 1 people'), findsOneWidget);
      // Rows: name + age (amber over 30) + the amount; nothing else.
      expect(find.byType(PersonBalanceRow), findsNWidgets(3));
      expect(find.text('Outstanding 45 days'), findsOneWidget);
      expect(find.text('Outstanding 6 days'), findsOneWidget);
      final rows = t.widgetList<PersonBalanceRow>(
        find.byType(PersonBalanceRow),
      );
      expect(rows.map((r) => r.subtitleWarn), [true, false, false]);
      expect(rows.every((r) => !r.showCaption), isTrue);
      expect(registry.preset.mode, QuickCreateMode.debt);
    });

    testWidgets('a tile filters by side at once; tap again clears', (t) async {
      await pump(t, const PersonalDebtsPage());
      await t.tap(find.text('To receive | 1 people'));
      await t.pump();
      expect(find.byType(PersonBalanceRow), findsOneWidget);
      expect(find.text('Mom'), findsOneWidget);
      await t.tap(find.text('To receive | 1 people'));
      await t.pump();
      expect(find.byType(PersonBalanceRow), findsNWidgets(3));
    });

    testWidgets('"Show cleared" turns all on, with no request', (t) async {
      await pump(t, const PersonalDebtsPage());
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(AppChip, 'Show cleared'));
      await t.pump();
      final cubit = t
          .element(find.byType(ListPageBody))
          .read<DebtPeopleCubit>();
      expect(cubit.state.all, isTrue);
      expect(repo.calls, isEmpty);
    });

    testWidgets('the sort chip sorts on the device', (t) async {
      await pump(t, const PersonalDebtsPage());
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Longest owed'));
      await t.pumpAndSettle();
      await t.tap(find.text('Largest'));
      await t.pump();
      final cubit = t
          .element(find.byType(ListPageBody))
          .read<DebtPeopleCubit>();
      expect(cubit.state.sort, DebtPeopleSort.amount);
      expect(repo.calls, isEmpty);
    });

    testWidgets('a failed load → full-page error; the sync landing fills it', (
      t,
    ) async {
      await pump(t, const PersonalDebtsPage(), people: false);
      directory.syncFailed(
        const ApiException(code: 'INTERNAL', message: 'boom', statusCode: 500),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(PersonBalanceRow), findsNothing);
      directory.applySync(_peopleBody());
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(PersonBalanceRow), findsNWidgets(3));
    });

    testWidgets('a failed reload keeps the rows on screen', (t) async {
      await pump(t, const PersonalDebtsPage());
      directory.syncFailed(
        const ApiException(code: 'INTERNAL', message: 'boom', statusCode: 500),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(PersonBalanceRow), findsNWidgets(3));
    });
  });

  group('person page', () {
    testWidgets('open = 1 call: hero, message box, current-cycle rows', (
      t,
    ) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(repo.calls, ['person c:c1 cycle=current']);
      // The hero: name, age, side pill + amount, the BE-built message.
      expect(find.byType(AppHeroCard), findsOneWidget);
      expect(find.text('Outstanding 6 days'), findsOneWidget);
      expect(find.byType(DebtAmountLine), findsOneWidget);
      expect(find.text('To receive'), findsOneWidget);
      expect(find.text('฿200'), findsOneWidget);
      expect(find.byType(DebtSummaryMessageBox), findsOneWidget);
      expect(find.textContaining('Summary with Mom'), findsOneWidget);
      // No tabs, no buttons under the card.
      expect(find.byType(AppTabBar), findsNothing);
      expect(find.text('Add entry'), findsNothing);
      // The statement: a cycle header, the entries, the earlier fold.
      expect(
        find.textContaining('Where the balance comes from | since cleared'),
        findsOneWidget,
      );
      expect(find.byType(LedgerRow), findsNWidgets(2));
      expect(find.text('Lunch money'), findsOneWidget);
      // No description → the direction fallback.
      expect(find.text('Received from Mom'), findsOneWidget);
      expect(find.text('Earlier cycles'), findsOneWidget);
    });

    testWidgets('the earlier cycles load once, on the fold first tap', (
      t,
    ) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      await t.tap(find.text('Earlier cycles'));
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, [
        'person c:c1 cycle=current',
        'entries cycle=earlier q=',
      ]);
      expect(find.text('Earlier cycle | cleared'), findsOneWidget);
      expect(find.text('Old repayment'), findsOneWidget);
      expect(find.text('Earlier cycles'), findsNothing);
    });

    testWidgets('no earlier cycle → no fold', (t) async {
      repo.earlier = 0;
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(find.text('Earlier cycles'), findsNothing);
    });

    testWidgets('a settled person: the word, no pill, no message box', (
      t,
    ) async {
      repo.personNet = 0;
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(find.text('Settled up'), findsOneWidget);
      expect(find.text('To receive'), findsNothing);
      expect(find.byType(DebtSummaryMessageBox), findsNothing);
    });

    testWidgets('🪪 only with a contact; 🔍 toggles the toolbar', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(find.byIcon(AppIcons.contact), findsOneWidget);
      expect(find.textContaining('Type:'), findsNothing);
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      expect(find.textContaining('Type:'), findsOneWidget);
    });

    testWidgets('quick create preset = debt + this person at once', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(registry.preset.mode, QuickCreateMode.debt);
      expect(registry.active()?.person?.contactId, 'c1');
    });

    testWidgets('a debts change re-runs the page call', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      await changes.DataChanges.instance.changed({changes.DataTable.debts});
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, [
        'person c:c1 cycle=current',
        'person c:c1 cycle=current',
      ]);
    });

    testWidgets('a failed load → full-page error', (t) async {
      repo.failPerson = const ApiException(
        code: 'INTERNAL',
        message: 'boom',
        statusCode: 500,
      );
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(LedgerRow), findsNothing);
    });

    testWidgets('a failed reload keeps the statement on screen', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      repo.failPerson = const ApiException(
        code: 'INTERNAL',
        message: 'boom',
        statusCode: 500,
      );
      await t.element(find.byType(AppHeroCard)).read<DebtPersonCubit>().load();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(LedgerRow), findsNWidgets(2));
    });

    testWidgets('a gone typed name (404) → not found, no error', (t) async {
      repo.failPerson = const ApiException(
        code: 'NOT_FOUND',
        message: 'not found',
        statusCode: 404,
      );
      await pump(t, const DebtPersonPage(personKey: 'n:gone', name: 'Gone'));
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(EmptyView), findsOneWidget);
    });
  });
}
