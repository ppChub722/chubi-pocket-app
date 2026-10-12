import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/pages/debt_person_page.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/pages/personal_debts_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Client extends Mock implements ApiClient {}

/// Answers from prod-shaped JSON (openapi.yaml, tag Debts); records calls.
class _Repo extends PersonalDebtsRepository {
  _Repo() : super(client: _Client());

  final calls = <String>[];
  Object? failPeople;
  Object? failPerson;

  @override
  Future<DebtPeoplePage> listPeople({
    int page = 1,
    int perPage = 30,
    String? q,
    bool all = false,
    NetSide? side,
  }) async {
    calls.add('people all=$all');
    final f = failPeople;
    if (f != null) {
      failPeople = null;
      throw f;
    }
    return DebtPeoplePage.fromJson({
      'data': [
        _person('c:c1', 'Mom', 200, contactId: 'c1'),
        _person('n:bank', 'Bank', -50),
      ],
      'totals': {'owed_to_me': 200, 'i_owe': 50, 'net': 150, 'open_count': 2},
      'pagination': {'page': 1, 'per_page': 30, 'total': 2, 'total_pages': 1},
    });
  }

  @override
  Future<DebtPersonDetail> person(String key, {int perPage = 30}) async {
    calls.add('person $key');
    final f = failPerson;
    if (f != null) {
      failPerson = null;
      throw f;
    }
    return DebtPersonDetail.fromJson({
      ..._person(key, 'Mom', 200, contactId: 'c1'),
      'counts': {'entries': 2, 'money': 1},
      'items': [
        _entry('e1', 'paid', 300, 'Lunch money', withTx: true),
        _entry('e2', 'received', 100, null),
      ],
      'pagination': {'page': 1, 'per_page': 30, 'total': 2, 'total_pages': 1},
    });
  }

  @override
  Future<DebtEntriesPage> entries(
    String key, {
    DebtEntryQuery query = const DebtEntryQuery(),
    int page = 1,
    int perPage = 30,
  }) async {
    calls.add('entries money=${query.moneyOnly}');
    return DebtEntriesPage.fromJson({
      'data': [_entry('e1', 'paid', 300, 'Lunch money', withTx: true)],
      'pagination': {'page': 1, 'per_page': 30, 'total': 1, 'total_pages': 1},
    });
  }
}

Map<String, dynamic> _person(
  String key,
  String name,
  num net, {
  String? contactId,
}) => {
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
  'updated_at': '2026-10-12T09:30:00Z',
};

void main() {
  late _Repo repo;
  late QuickCreateContext registry;

  Future<void> pump(WidgetTester t, Widget page) async {
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

  setUp(() => repo = _Repo());

  group('people list', () {
    testWidgets('open = 1 call; rows + totals from the BE', (t) async {
      await pump(t, const PersonalDebtsPage());
      expect(repo.calls, ['people all=false']);
      expect(find.byType(DebtSummaryCard), findsOneWidget);
      expect(find.byType(PersonBalanceRow), findsNWidgets(2));
      expect(find.text('Mom'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(registry.preset.mode, QuickCreateMode.debt);
    });

    testWidgets('"All" chip = 1 call with all=true', (t) async {
      await pump(t, const PersonalDebtsPage());
      await t.tap(find.widgetWithText(AppChip, 'All'));
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls.last, 'people all=true');
    });

    testWidgets('a failed load → full-page error; retry loads', (t) async {
      repo.failPeople = const ApiException(
        code: 'INTERNAL',
        message: 'boom',
        statusCode: 500,
      );
      await pump(t, const PersonalDebtsPage());
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(PersonBalanceRow), findsNothing);
      await t.tap(
        find.descendant(
          of: find.byType(ErrorView),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(PersonBalanceRow), findsNWidgets(2));
    });
  });

  group('person page', () {
    testWidgets('open = 1 call: hero, button, timeline rows', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(repo.calls, ['person c:c1']);
      expect(find.byType(NetBalance), findsOneWidget);
      expect(find.text('Add entry'), findsOneWidget);
      expect(find.byType(LedgerRow), findsNWidgets(2));
      expect(find.text('Lunch money'), findsOneWidget);
      // No description → the direction fallback.
      expect(find.text('Received from Mom'), findsOneWidget);
    });

    testWidgets('quick create preset = debt + this person at once', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(registry.preset.mode, QuickCreateMode.debt);
      expect(registry.active()?.person?.contactId, 'c1');
    });

    testWidgets('the payments tab loads once, on its first open', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      await t.tap(find.text('Payments'));
      await t.pumpAndSettle();
      expect(repo.calls, ['person c:c1', 'entries money=true']);
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
