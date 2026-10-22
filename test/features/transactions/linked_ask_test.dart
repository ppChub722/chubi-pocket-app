import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/transaction_edit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(Map<String, dynamic> extra) => Transaction.fromJson({
  'id': 't1',
  'type': 'expense',
  'amount': 100,
  'date': '2026-10-22',
  ...extra,
});

const _copy = {
  'event_bill': {
    'event': {'id': 'p1', 'name': 'Trip'},
    'bill_id': 'b1',
    'linked': false,
    'kind': 'copy',
  },
};

/// Saving an edit of my tx tied to an event bill asks in the owner's words
/// (0.4.0-3 B3): "แก้ในอีเวนต์ด้วยไหม?" [แก้แค่ของฉัน] [แก้ทั้งคู่], my copy
/// too; a plain tx isn't asked.
void main() {
  late ({bool cancelled, bool? alsoUpdateLink}) answer;

  Future<void> ask(WidgetTester t, Transaction tx) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  answer = await askLinkedTxSave(context, tx),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  testWidgets('an event bill (my copy too): the event words; both = true', (
    t,
  ) async {
    await ask(t, _tx(_copy));
    expect(find.text('Change it in the event too?'), findsOneWidget);
    expect(find.text('Only mine'), findsOneWidget);
    await t.tap(find.text('Both'));
    await t.pumpAndSettle();
    expect(answer.cancelled, isFalse);
    expect(answer.alsoUpdateLink, isTrue);
  });

  testWidgets('only mine = false; cancel stops', (t) async {
    await ask(t, _tx(_copy));
    await t.tap(find.text('Only mine'));
    await t.pumpAndSettle();
    expect(answer.alsoUpdateLink, isFalse);
    await ask(t, _tx(_copy));
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    expect(answer.cancelled, isTrue);
  });

  testWidgets('a plain tx is not asked', (t) async {
    await ask(t, _tx(const {}));
    expect(find.byType(Dialog), findsNothing);
    expect(answer.cancelled, isFalse);
    expect(answer.alsoUpdateLink, isNull);
  });
}
