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

  /// Adds a repayment line (a transaction, 0.4.0-3) to the statement.
  bool repayment = false;

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
        if (repayment)
          {
            ..._entry('t9', 'received', 82, 'Got back from Mom', withTx: true),
            'kind': 'repayment',
            'paid': null,
          },
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
    {..._person('n:gone', 'Gone', 0), 'open_count': 0},
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

  group('people list (mock DebtsList)', () {
    testWidgets('🔍 in the card; the search hidden until tapped; red dot', (
      t,
    ) async {
      await pump(t, const PersonalDebtsPage());
      final toggle = find.descendant(
        of: find.byType(AppHeroCard),
        matching: find.byType(ToolbarToggleButton),
      );
      expect(toggle, findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      CardActionButton button() => t.widget(
        find.descendant(
          of: find.byType(ToolbarToggleButton),
          matching: find.byType(CardActionButton),
        ),
      );
      expect(button().showDot, isFalse);
      await t.tap(toggle);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Mom');
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(button().showDot, isTrue);
    });

    testWidgets('open = no request; the hero (net, facts, chips) and ONE card '
        'of open people, oldest first, each with its age', (t) async {
      await pump(t, const PersonalDebtsPage());
      expect(repo.calls, isEmpty);
      // Tile + "หนี้สุทธิ | N คน" + the big net.
      expect(find.byType(HeroSummaryHead), findsOneWidget);
      expect(find.text('Net debts | 2 people'), findsOneWidget);
      // Facts: รอรับ / รอจ่าย / ค้างเกิน 30 วัน.
      expect(find.text('To receive | 1 people'), findsOneWidget);
      expect(find.text('To pay | 1 people'), findsOneWidget);
      expect(find.text('1 people'), findsOneWidget);
      // The filter chips with their counts.
      expect(find.byKey(const ValueKey('heroFilter:All')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('heroFilter:Open over 30 days')),
        findsOneWidget,
      );
      // The cleared person stays out; oldest first.
      final rows = t.widgetList<AppListRow>(find.byType(AppListRow)).toList();
      expect(rows.map((r) => r.title), ['Mom', 'Bank']);
      // Past 30 days the line is warned (a coloured span), else plain parts.
      expect(rows.first.line2?.spans, hasLength(1));
      expect(rows.last.line2?.parts, ['Owing for 6 days']);
      expect(registry.preset.mode, QuickCreateMode.debt);
    });

    testWidgets('the + beside 🔍 is debt mode (mock QuickCreateBtn)', (
      t,
    ) async {
      await pump(t, const PersonalDebtsPage());
      final add = t.widget<QuickCreateHeadButton>(
        find.descendant(
          of: find.byType(AppHeroCard),
          matching: find.byKey(const ValueKey('debtsAdd')),
        ),
      );
      expect(add.mode, QuickCreateMode.debt);
      expect(add.onPressed, isNotNull);
    });

    testWidgets('nobody open → the empty state with the จดหนี้ CTA', (t) async {
      directory.applySync({
        ..._peopleBody(),
        'data': [
          {..._person('n:gone', 'Gone', 0), 'open_count': 0},
        ],
      });
      await pump(t, const PersonalDebtsPage(), people: false);
      expect(find.text('No open debts'), findsOneWidget);
      final cta = t.widget<QuickCreateCtaButton>(
        find.byKey(const ValueKey('debtsEmptyAdd')),
      );
      expect(cta.mode, QuickCreateMode.debt);
      expect(cta.label, 'Add debt');
    });

    testWidgets('a chip filters at once, one at a time', (t) async {
      await pump(t, const PersonalDebtsPage());
      await t.tap(find.byKey(const ValueKey('heroFilter:To pay')));
      await t.pump();
      expect(find.byType(AppListRow), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('heroFilter:Open over 30 days')));
      await t.pump();
      expect(find.byType(AppListRow), findsOneWidget);
      expect(find.text('Mom'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('heroFilter:All')));
      await t.pump();
      expect(find.byType(AppListRow), findsNWidgets(2));
      expect(repo.calls, isEmpty);
    });

    testWidgets('the second line is the due date when set (overdue warned), '
        'else how long it has been open', (t) async {
      final now = DateTime.now();
      String ymd(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      directory.applySync({
        ..._peopleBody(),
        'data': [
          {
            ..._person('c:c1', 'Mom', 200, contactId: 'c1', days: 45),
            'next_due_date': ymd(now.subtract(const Duration(days: 3))),
          },
          {..._person('n:bank', 'Bank', -50, days: 6)},
        ],
      });
      await pump(t, const PersonalDebtsPage(), people: false);
      final rows = t.widgetList<AppListRow>(find.byType(AppListRow)).toList();
      final late = rows.first.line2!.spans.single as TextSpan;
      expect(late.text, '3 days overdue');
      expect(rows.last.line2?.parts, ['Owing for 6 days']);
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
      expect(find.byType(AppListRow), findsNothing);
      directory.applySync(_peopleBody());
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppListRow), findsNWidgets(2));
    });

    testWidgets('a failed reload keeps the rows on screen', (t) async {
      await pump(t, const PersonalDebtsPage());
      directory.syncFailed(
        const ApiException(code: 'INTERNAL', message: 'boom', statusCode: 500),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(AppListRow), findsNWidgets(2));
    });
  });

  group('person page (mock DebtPerson)', () {
    testWidgets('open = 1 call: hero sentence + amount, two buttons, the '
        'statement in day groups', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(repo.calls, ['person c:c1 cycle=current']);
      expect(find.byType(AppHeroCard), findsOneWidget);
      expect(find.text('Outstanding 6 days'), findsOneWidget);
      // "ลูกหนี้" + the big amount (the name is the hero's title).
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('debtSentence')),
          matching: find.text('Owes me'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('debtSentence')), findsOneWidget);
      // [ได้คืน ฿200] + [ทวง]; no message box any more.
      expect(find.text('Got back ฿200'), findsOneWidget);
      expect(find.text('Remind'), findsOneWidget);
      expect(find.byType(DebtSummaryMessageBox), findsNothing);
      expect(find.byType(AppTabBar), findsNothing);
      // One day: its header with the change, then the lines.
      expect(find.byType(DateGroupHeader), findsOneWidget);
      final header = t.widget<DateGroupHeader>(find.byType(DateGroupHeader));
      expect(header.note, 'up ฿200');
      expect(find.byType(AppListRow), findsNWidgets(2));
      expect(find.text('Lunch money'), findsOneWidget);
      // No description → the direction words; the wallet as a chip.
      expect(find.text('Received from Mom'), findsOneWidget);
      expect(find.text('from wallet Cash'), findsNothing);
      expect(find.text('All cleared Oct 5 | Earlier ▾'), findsOneWidget);
    });

    testWidgets('the earlier cycles load once, behind the divider', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      await t.tap(find.byKey(const ValueKey('earlierDivider')));
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, [
        'person c:c1 cycle=current',
        'entries cycle=earlier q=',
      ]);
      expect(find.text('Old repayment'), findsOneWidget);
      expect(find.text('Hide earlier ▴'), findsOneWidget);
      // Folding and opening again: no second call.
      await t.tap(find.byKey(const ValueKey('earlierDivider')));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Old repayment'), findsNothing);
      await t.tap(find.byKey(const ValueKey('earlierDivider')));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Old repayment'), findsOneWidget);
      expect(repo.calls, hasLength(2));
    });

    testWidgets('no earlier cycle → no divider', (t) async {
      repo.earlier = 0;
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(find.byKey(const ValueKey('earlierDivider')), findsNothing);
    });

    testWidgets('a settled person: the word, no settle button', (t) async {
      repo.personNet = 0;
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('debtSentence')),
          matching: find.text('Settled up'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('debtSettle')), findsNothing);
      expect(find.byKey(const ValueKey('debtShare')), findsOneWidget);
    });

    testWidgets('remind opens the share sheet with the BE text', (t) async {
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      await t.tap(find.byKey(const ValueKey('debtShare')));
      await t.pumpAndSettle();
      expect(find.byType(DebtShareSheet), findsOneWidget);
      expect(find.text('Remind Mom'), findsOneWidget);
      expect(find.byKey(const ValueKey('shareVariant0')), findsOneWidget);
      expect(find.textContaining('Summary with Mom'), findsWidgets);
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

    testWidgets('every statement line opens; a repayment has the cash icon '
        'and no paid pill', (t) async {
      repo.repayment = true;
      await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
      final rows = find.byType(AppListRow);
      expect(rows, findsNWidgets(3));
      for (final e in rows.evaluate()) {
        expect((e.widget as AppListRow).onTap, isNotNull);
      }
      final first = t.widget<AppListRow>(rows.first);
      expect(first.title, 'Got back from Mom');
      expect((first.leading as IconTile).icon, AppIcons.cash);
      expect(first.status, isNull);
      // The wallet is a chip by the title, not words in line 2.
      expect(first.titleChips.single.label, 'Cash');
      expect(first.line2, isNull);
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
      expect(find.byType(AppListRow), findsNothing);
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
      expect(find.byType(AppListRow), findsNWidgets(2));
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
