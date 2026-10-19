import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/data/contacts_repository.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/pages/contact_detail_page.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

/// `get` runs the REAL model parsing on [body], or fails like the network does.
class _Repo extends Fake implements ContactsRepository {
  Map<String, dynamic>? body;
  bool networkDown = false;
  int calls = 0;
  int previewCalls = 0;

  @override
  Future<ContactDetail> get(String id, {bool deletePreview = false}) async {
    if (deletePreview) previewCalls++;
    calls++;
    if (networkDown) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no connection');
    }
    return ContactDetail.fromJson({
      ...body!,
      if (deletePreview)
        'delete_preview': {
          'debt_records': 3,
          'event_members': 2,
          'linked': true,
        },
    });
  }
}

/// A contact as the BE sends it (linked user, resolved name / icon, unlinked
/// split names).
Map<String, dynamic> _prodContact() => {
  'id': 'c1',
  'name': 'Lee Cooper',
  'nickname': 'Coop',
  'show_nickname': true,
  'display_name': 'Lee Cooper',
  'email': 'lee@example.com',
  'phone': null,
  'description': 'Flatmate',
  'note': null,
  'icon_code': null,
  'linked_user': {
    'id': 'u9',
    'display_name': 'Lee',
    'username': 'lee',
    'email': 'lee@example.com',
    'icon_code': null,
  },
  'status': 'active',
  'last_used_at': '2026-10-10T08:00:00Z',
  'created_at': '2026-10-01T08:00:00Z',
  'updated_at': '2026-10-11T08:00:00Z',
  'unlinked_total': {'names': 1, 'records': 2},
  'delete_preview': null,
  'unlinked_names': [
    {'name': 'Cooper', 'count': 2},
  ],
};

void main() {
  late _Repo repo;
  late QuickCreateContext registry;

  setUp(() {
    repo = _Repo()..body = _prodContact();
    registry = QuickCreateContext();
  });

  tearDown(() => registry.dispose());

  Future<void> pump(WidgetTester t) async {
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final contacts = _Contacts();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => contacts.state).thenReturn(const ContactsState());
    await t.pumpWidget(
      RepositoryProvider<ContactsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<ContactsCubit>.value(value: contacts),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                ThemeRegistry.byId(
                  ThemeRegistry.defaultThemeId,
                ).colorsFor(Brightness.light),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(
              child: QuickCreateContextScope(registry: registry, child: child!),
            ),
            // The shell's Scaffold: where the page's snackbars land.
            home: const Scaffold(body: ContactDetailPage(id: 'c1')),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('prod-shaped JSON renders the contact', (t) async {
    await pump(t);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(DetailPageSkeleton), findsNothing);
    expect(find.text('Lee Cooper'), findsWidgets);
  });

  testWidgets('the + opens debt mode with this contact', (t) async {
    await pump(t);
    expect(
      registry.active(),
      const QuickCreatePreset.debt(
        person: EmbeddedPerson(
          name: 'Lee Cooper',
          contactId: 'c1',
          linked: true,
          linkedUserId: 'u9',
        ),
      ),
    );
    expect(registry.preset.mode, QuickCreateMode.debt);
  });

  testWidgets('network down → error + retry; retry loads the contact', (
    t,
  ) async {
    repo.networkDown = true;
    await pump(t);
    expect(find.byType(ErrorView), findsOneWidget);
    repo.networkDown = false;
    await t.tap(find.text('Retry'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Lee Cooper'), findsWidgets);
    expect(repo.calls, 2);
  });

  testWidgets('a malformed body (parse TypeError) → error + retry, not an '
      'endless skeleton', (t) async {
    repo.body = {'id': 'c1'}; // `name` / `display_name` missing
    await pump(t);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(DetailPageSkeleton), findsNothing);
  });

  testWidgets('view: link chip, 💸 next to ✏️, info rows, link section, no '
      '"show nickname" setting', (t) async {
    await pump(t);
    // A: the link state chip; B: name + description.
    expect(find.text('Linked with @lee'), findsOneWidget);
    expect(find.text('Flatmate'), findsOneWidget);
    expect(find.byIcon(AppIcons.debt), findsOneWidget);
    expect(find.byIcon(AppIcons.edit), findsOneWidget);
    // Info: set rows only (phone is null, so no row).
    expect(find.text('Nickname'), findsOneWidget);
    expect(find.text('Coop'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('lee@example.com'), findsOneWidget);
    expect(find.text('Phone'), findsNothing);
    // The nickname switch is an edit-mode setting only.
    expect(find.text('Show nickname'), findsNothing);
    expect(find.byType(EndZone), findsNothing);
    // Link section: linked → unlink + match names with the BE's counts.
    expect(find.text('Link account'), findsOneWidget);
    expect(find.text('Unlink'), findsOneWidget);
    expect(find.text('Send link request'), findsNothing);
    expect(
      find.text('1 names | 2 splits not linked to a contact'),
      findsOneWidget,
    );
    // The old "debts with this person" row is gone (it is the 💸 button).
    expect(find.text('Debts with this person'), findsNothing);
  });

  testWidgets('unlinked contact with an email offers a link request', (
    t,
  ) async {
    repo.body = {..._prodContact(), 'linked_user': null};
    await pump(t);
    expect(find.text('Not linked to an app user'), findsOneWidget);
    expect(find.text('Send link request'), findsOneWidget);
    expect(find.text('Unlink'), findsNothing);
  });

  testWidgets('unlinked contact without an email hides the request row', (
    t,
  ) async {
    repo.body = {..._prodContact(), 'linked_user': null, 'email': null};
    await pump(t);
    expect(find.text('Send link request'), findsNothing);
    expect(find.text('Match names in splits'), findsOneWidget);
  });

  testWidgets('edit mode: its own form, fields + setting + end zone; the '
      'link section is hidden', (t) async {
    repo.body = {..._prodContact(), 'linked_user': null};
    await pump(t);
    await t.tap(find.byIcon(AppIcons.edit));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(DetailTextField), findsNWidgets(3));
    expect(find.text('Show nickname'), findsOneWidget);
    expect(find.byType(EndZone), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Delete this contact'), findsOneWidget);
    expect(find.text('Link account'), findsNothing);
    expect(find.text('Send link request'), findsNothing);
    expect(find.byIcon(AppIcons.debt), findsNothing);
  });

  testWidgets('delete: ONE preview call, the confirm prints the BE numbers', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(t);
    await t.tap(find.byIcon(AppIcons.edit));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Delete this contact'));
    await t.pumpAndSettle();
    expect(repo.previewCalls, 1);
    expect(
      find.textContaining('3 debt records keep only the name'),
      findsOneWidget,
    );
    expect(find.textContaining('Member of 2 events'), findsOneWidget);
    expect(find.textContaining('Linked to an account'), findsOneWidget);
  });

  testWidgets('edit mode of a linked contact hides the email (it follows the '
      'account)', (t) async {
    await pump(t);
    await t.tap(find.byIcon(AppIcons.edit));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(DetailTextField), findsNWidgets(2));
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('a failed pull-to-refresh keeps the contact on screen', (
    t,
  ) async {
    await pump(t);
    repo.networkDown = true;
    await t.widget<PullToRefresh>(find.byType(PullToRefresh)).onRefresh();
    await t.pump();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Linked with @lee'), findsOneWidget);
    expect(find.text('lee@example.com'), findsOneWidget);
    expect(repo.calls, 2);
  });
}
