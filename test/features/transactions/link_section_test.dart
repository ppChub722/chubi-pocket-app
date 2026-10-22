import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/link_section.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

const _lee = LinkPerson(name: 'Lee', contactId: 'c2');

final _wallet = Account.fromJson({
  'id': 'w1',
  'name': 'Cash',
  'type': 'cash',
  'balance': 500,
  'currency': 'THB',
});

/// Quick create's "ผูกกับ" tabs (0.4.0-3 S3, variant B): the tabs row, one
/// card per tab, the bill label, my share, the dimmed wallet. 320 and 390.
void main() {
  late DraftFormController c;

  setUp(() {
    c = DraftFormController()
      ..amount.text = '123'
      ..setAccount(_wallet);
  });
  tearDown(() => c.dispose());

  Future<void> pump(WidgetTester t, double width, {String? event}) {
    t.view.physicalSize = Size(width * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final accounts = _Accounts();
    final categories = _Categories();
    final contacts = _Contacts();
    final tags = _Tags();
    final auth = _Auth();
    when(() => accounts.state).thenReturn(AccountsState(accounts: [_wallet]));
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => contacts.state).thenReturn(const ContactsState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    for (final loader in [
      accounts.loadIfNeeded,
      categories.loadIfNeeded,
      contacts.loadIfNeeded,
      tags.loadIfNeeded,
    ]) {
      when(loader).thenAnswer((_) async {});
    }
    return t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountsCubit>.value(value: accounts),
          BlocProvider<CategoriesCubit>.value(value: categories),
          BlocProvider<ContactsCubit>.value(value: contacts),
          BlocProvider<TagsCubit>.value(value: tags),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) => AppUiConfig(child: child!),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                DraftForm(
                  controller: c,
                  autofocus: false,
                  chipRows: true,
                  linkTabs: true,
                  eventSlot: SplitEventSlot(name: event, onTap: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  WalletPickCard wallet(WidgetTester t) =>
      t.widget<WalletPickCard>(find.byType(WalletPickCard));

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linkModeBar')),
        matching: find.text(label),
      ),
    );
    await _settle(t);
  }

  for (final width in [320.0, 390.0]) {
    group('at $width', () {
      testWidgets('every tab lays out: one row, inside the screen', (t) async {
        await pump(t, width);
        await _settle(t);
        final bar = find.byKey(const ValueKey('linkModeBar'));
        expect(bar, findsOneWidget);
        // "ผูกกับ" and the pills share ONE row.
        final label = find.descendant(of: bar, matching: find.text('Link'));
        final pills = find.descendant(
          of: bar,
          matching: find.byType(AppTabBar<LinkMode>),
        );
        expect(t.getCenter(label).dy, closeTo(t.getCenter(pills).dy, 1));
        for (final name in ['Split', 'Paid for me', 'Event', 'Just me']) {
          await tab(t, name);
          expect(t.takeException(), isNull, reason: name);
          for (final card in find.byType(ShareCard).evaluate()) {
            final r = t.getRect(find.byWidget(card.widget));
            expect(r.left, greaterThanOrEqualTo(16 - 0.5), reason: name);
            expect(r.right, lessThanOrEqualTo(width - 16 + 0.5), reason: name);
          }
        }
      });
    });
  }

  testWidgets('ส่วนตัว: no card, the amount says จำนวนเงิน, no share line', (
    t,
  ) async {
    await pump(t, 390);
    await _settle(t);
    expect(find.byType(ShareCard), findsNothing);
    expect(find.text('Bill'), findsNothing);
    expect(wallet(t).muted, isFalse);
    expect(wallet(t).note, isNull);
  });

  testWidgets('แบ่ง: the card with ฉัน + people, status, "Bill" on top', (
    t,
  ) async {
    c.setSplits([SplitDraft(personName: 'Boss', owedAmount: 41)]);
    await pump(t, 390);
    await _settle(t);
    // People in the form → แบ่ง until a tab is picked.
    expect(find.byType(SplitsSection), findsOneWidget);
    expect(find.text('Split with'), findsOneWidget);
    expect(find.text('Bill'), findsOneWidget);
    expect(find.byType(AutoToggleChip), findsOneWidget);
    expect(find.text('✓ All split'), findsOneWidget);
  });

  testWidgets('จ่ายแทน: pick → ✓; part paid → my wallet pays the rest', (
    t,
  ) async {
    await pump(t, 390);
    await _settle(t);
    await tab(t, 'Paid for me');
    expect(find.text('I paid (from my wallet)'), findsOneWidget);
    expect(find.text('Pick who paid'), findsOneWidget);

    c.setPaidBy(_lee);
    await _settle(t);
    expect(find.text('Lee'), findsOneWidget);
    expect(find.text('✓ Fully paid'), findsOneWidget);
    expect(wallet(t).muted, isTrue);
    expect(wallet(t).note, 'Not from your wallet');

    c.setPaidAmount(13);
    await _settle(t);
    expect(c.link.myPaid(123), 110);
    expect(find.text('✓ Fully paid'), findsOneWidget);
    expect(wallet(t).muted, isFalse);
    expect(wallet(t).note, contains('from this wallet'));

    // Mine typed off auto: the status shows the gap.
    c.setMyPaid(100);
    await _settle(t);
    expect(find.textContaining('short'), findsOneWidget);
  });

  testWidgets('จ่ายแทน → อีเวนต์: that person pays; the event chip leads', (
    t,
  ) async {
    await pump(t, 390, event: 'Khao Yai');
    await _settle(t);
    // An event in the form → อีเวนต์ until a tab is picked.
    expect(find.byKey(const ValueKey('linkCardEvent')), findsOneWidget);
    await tab(t, 'Paid for me');
    c.setPaidBy(_lee);
    await _settle(t);
    await tab(t, 'Event');
    expect(c.link.eventPayer, _lee);
    final card = find.byKey(const ValueKey('linkCardEvent'));
    expect(
      find.descendant(of: card, matching: find.byType(EventPickChip)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Khao Yai')),
      findsOneWidget,
    );
    expect(find.text('Who paid'), findsOneWidget);
    expect(find.text("Who's in the bill"), findsOneWidget);
    // Lee pays and is in the bill: half each, ฉัน on A.
    expect(c.myShareFor(LinkMode.event), 61.5);
    expect(wallet(t).muted, isTrue);
    expect(find.text('✓ All split'), findsOneWidget);
  });

  testWidgets('a new event tags its people "ใหม่ · เพิ่มเข้าอีเวนต์"', (
    t,
  ) async {
    c.setSplits([SplitDraft(personName: 'Boss', owedAmount: 20)]);
    await pump(t, 390, event: 'Trip');
    // Rebuild with the new-event flag.
    await t.pumpWidget(const SizedBox());
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<AuthCubit>.value(
            value: _authAs(),
            child: LinkSection(
              controller: c..setLinkMode(LinkMode.event, hasEvent: true),
              event: const SplitEventSlot(name: 'Trip'),
              eventIsNew: true,
            ),
          ),
        ),
      ),
    );
    await _settle(t);
    expect(find.text('New · joins the event'), findsOneWidget);
  });

  testWidgets('an existing event tags only the people not in it yet', (
    t,
  ) async {
    c.setSplits([
      SplitDraft(personName: 'Boss', owedAmount: 20),
      SplitDraft(personName: 'Ann', owedAmount: 20),
    ]);
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<AuthCubit>.value(
            value: _authAs(),
            child: ListView(
              children: [
                LinkSection(
                  controller: c..setLinkMode(LinkMode.event, hasEvent: true),
                  event: const SplitEventSlot(name: 'Trip'),
                  // Boss is already in the event (a typed member).
                  isEventMember: (p) => p.isMember(name: 'boss'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _settle(t);
    expect(find.text('New · joins the event'), findsOneWidget);
  });

  testWidgets('income keeps the old section (no tabs)', (t) async {
    c.setType(TransactionType.income);
    await pump(t, 390);
    await _settle(t);
    expect(find.byKey(const ValueKey('linkModeBar')), findsNothing);
  });
}

_Auth _authAs() {
  final auth = _Auth();
  when(() => auth.state).thenReturn(
    const AuthAuthenticated(
      User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
    ),
  );
  return auth;
}

/// The form keeps a looping animation (loading chips), so no pumpAndSettle.
Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}
