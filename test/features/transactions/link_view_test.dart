import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/link_view.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

/// A จ่ายแทน row as the BE answers it (B1): bill 123, Lee paid 13.
final _paidJson = {
  'id': 't1',
  'type': 'expense',
  'amount': 123,
  'date': '2026-10-21',
  'link_mode': 'paid',
  'wallet_amount': 110,
  'paid_by': {
    'debt_id': 'd1',
    'key': 'c:c2',
    'person': {'name': 'Lee', 'contact_id': 'c2', 'linked': false},
    'amount': 13,
    'my_paid': 110,
    'source': 'me',
    'paid': false,
  },
};

/// My copy of an event bill Lee paid (B2): bill 300, three of us.
final _eventJson = {
  'id': 't2',
  'type': 'expense',
  'amount': 100,
  'date': '2026-10-21',
  'link_mode': 'event',
  'event_bill': {
    'event': {'id': 'p1', 'name': 'Khao Yai'},
    'bill_id': 'b1',
    'linked': false,
    'payer': {
      'id': 'm2',
      'user_id': null,
      'name': 'Lee',
      'icon_code': null,
      'is_me': false,
    },
    'bill_amount': 300,
    'members': [
      {
        'member': {
          'id': 'm2',
          'user_id': null,
          'name': 'Lee',
          'icon_code': null,
          'is_me': false,
        },
        'share': 100,
      },
      {
        'member': {
          'id': 'm1',
          'user_id': 'u1',
          'name': 'Me',
          'icon_code': null,
          'is_me': true,
        },
        'share': 100,
      },
      {
        'member': {
          'id': 'm3',
          'user_id': null,
          'name': 'Boss',
          'icon_code': null,
          'is_me': false,
        },
        'share': 100,
      },
    ],
  },
};

void main() {
  group('read (B1 / B2)', () {
    test('a จ่ายแทน row', () {
      final tx = Transaction.fromJson(_paidJson);
      expect(tx.linkMode, LinkMode.paid);
      expect(tx.walletAmount, 110);
      final p = tx.paidBy!;
      expect(p.person.name, 'Lee');
      expect(p.amount, 13);
      expect(p.myPaid, 110);
      expect(p.fromPartner, isFalse);
      expect(p.key, 'c:c2');
    });

    test('an event bill someone else paid', () {
      final tx = Transaction.fromJson(_eventJson);
      expect(tx.linkMode, LinkMode.event);
      final bill = tx.eventBill!;
      expect(bill.linked, isFalse);
      expect(bill.payer!.name, 'Lee');
      expect(bill.billAmount, 300);
      expect(bill.members, hasLength(3));
      expect(bill.members![1].member.isMe, isTrue);
    });

    test('B3: kind, in_sync, differences; the preview; person_balances', () {
      final bill = EventBillLink.fromJson({
        'event': {'id': 'p1', 'name': 'X'},
        'bill_id': 'b1',
        'linked': true,
        'kind': 'origin',
        'in_sync': false,
        'differences': [
          {'field': 'amount', 'mine': 100, 'event': 120},
        ],
      });
      expect(bill.isOrigin, isTrue);
      expect(bill.inSync, isFalse);
      expect(bill.differences.single.field, 'amount');
      final p = TxEditPreview.fromJson({
        'preview': true,
        'rows': <Object>[],
        'people': [
          {
            'key': 'n:bee',
            'person': {'name': 'Bee'},
            'before': 100,
            'after': 0,
            'delta': -100,
          },
        ],
        'wallets': [
          {'account_id': 'w1', 'before': 700, 'after': 750, 'delta': 50},
        ],
      });
      expect(p.people.single.name, 'Bee');
      expect(p.wallets.single.after, 750);
      final w = TransactionWriteResult.fromJson({
        'rows': <Object>[],
        'account_balances': <Object>[],
        'person_balances': [
          {
            'key': 'n:bee',
            'person': {'name': 'Bee'},
            'net': 0,
          },
        ],
      });
      expect(w.personBalances.single.key, 'n:bee');
    });

    test('a list row (no B1 / B2 data) still reads', () {
      final tx = Transaction.fromJson({
        'id': 't3',
        'type': 'expense',
        'amount': 5,
        'date': '2026-10-21',
        'event_bill': {
          'event': {'id': 'p1', 'name': 'X'},
          'bill_id': 'b1',
          'linked': true,
          'payer': null,
          'bill_amount': 0,
          'members': null,
        },
      });
      expect(tx.linkMode, isNull);
      expect(tx.paidBy, isNull);
      expect(tx.eventBill!.payer, isNull);
      expect(tx.eventBill!.members, isNull);
    });
  });

  Future<void> pump(WidgetTester t, Map<String, dynamic> json) {
    final auth = _Auth();
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    return t.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: LinkViewRows(tx: Transaction.fromJson(json))),
        ),
      ),
    );
  }

  testWidgets('จ่ายแทน: one summary row; › opens the card read-only', (
    t,
  ) async {
    await pump(t, _paidJson);
    final row = find.byKey(const ValueKey('linkViewPaid'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.textContaining('Lee')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('I paid')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('linkViewEvent')), findsNothing);
    await t.tap(row);
    await t.pumpAndSettle();
    final card = find.byKey(const ValueKey('linkViewPaidCard'));
    expect(card, findsOneWidget);
    expect(find.text('✓ Fully paid'), findsOneWidget);
    // Read-only: no amount box takes input.
    for (final f in t.widgetList<ShareAmountField>(
      find.descendant(of: card, matching: find.byType(ShareAmountField)),
    )) {
      expect(f.onChanged, isNull);
    }
  });

  testWidgets('อีเวนต์: "Lee paid | 3 people"; › shows payer + shares', (
    t,
  ) async {
    await pump(t, _eventJson);
    final row = find.byKey(const ValueKey('linkViewEvent'));
    expect(
      find.descendant(of: row, matching: find.textContaining('Lee paid')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('3 people')),
      findsOneWidget,
    );
    await t.tap(row);
    await t.pumpAndSettle();
    final card = find.byKey(const ValueKey('linkViewEventCard'));
    expect(
      find.descendant(of: card, matching: find.text('Khao Yai')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Boss')),
      findsOneWidget,
    );
  });

  testWidgets('a plain tx shows nothing', (t) async {
    await pump(t, {
      'id': 't4',
      'type': 'expense',
      'amount': 5,
      'date': '2026-10-21',
    });
    expect(find.byType(InfoBox), findsNothing);
  });
}
