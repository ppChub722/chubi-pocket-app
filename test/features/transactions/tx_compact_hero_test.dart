import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/tx_compact_hero.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The transaction's compact hero bar (owner 2026-10-11): no type chip;
/// title = description ?? category; the category chip follows the
/// description after a "·", never repeating a category that is the title.
void main() {
  Future<void> pump(
    WidgetTester t, {
    required String description,
    String? category,
    TransactionType type = TransactionType.expense,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Scaffold(
          body: Builder(
            builder: (context) => txCompactHeroBar(
              context,
              type: type,
              description: description,
              amount: 1250,
              categoryName: category,
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets('description | category chip, amount on the right', (t) async {
    await pump(t, description: 'ข้าวมันไก่', category: 'อาหาร');
    expect(find.text('ข้าวมันไก่'), findsOneWidget);
    expect(find.text('|'), findsOneWidget);
    expect(find.widgetWithText(AppChip, 'อาหาร'), findsOneWidget);
    // No type chip.
    expect(find.text('รายจ่าย'), findsNothing);
  });

  testWidgets('no description: the category is the title, no chip', (t) async {
    await pump(t, description: '  ', category: 'อาหาร');
    expect(find.text('อาหาร'), findsOneWidget);
    expect(find.text('|'), findsNothing);
    expect(find.byType(AppChip), findsNothing);
  });

  testWidgets('no description, no category: the type names it', (t) async {
    await pump(t, description: '');
    expect(find.text('รายจ่าย'), findsOneWidget);
    expect(find.byType(AppChip), findsNothing);
  });

  testWidgets('a transfer: description only, never a category chip', (t) async {
    await pump(
      t,
      description: 'ย้ายเงิน',
      category: 'อาหาร',
      type: TransactionType.transfer,
    );
    expect(find.text('ย้ายเงิน'), findsOneWidget);
    expect(find.byType(AppChip), findsNothing);
  });
}
