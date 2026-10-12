import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester t, Transaction tx) => t.pumpWidget(
  MaterialApp(
    theme: ThemeData(extensions: [sweetTheme.lightColors]),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // No BlocProvider anywhere: the row must read only its own refs.
    home: Scaffold(
      body: TransactionTile(transaction: tx, onTap: () {}),
    ),
  ),
);

void main() {
  testWidgets('icon, name and wallet come from the embedded refs', (t) async {
    await _pump(
      t,
      const Transaction(
        id: 't1',
        accountId: 'a1',
        type: TransactionType.expense,
        amount: 50,
        date: '2026-10-10',
        account: AccountRef(
          id: 'a1',
          name: 'KBank',
          iconCode: IconCode(icon: 'bank'),
        ),
        category: EmbeddedCategory(
          id: 'c1',
          name: 'Noodles',
          iconCode: IconCode(icon: 'food'),
          parentId: 'c0',
        ),
      ),
    );
    expect(find.text('Noodles'), findsOneWidget);
    expect(find.text('KBank'), findsOneWidget);
    final icons = t
        .widgetList<IconDisplay>(find.byType(IconDisplay))
        .map((w) => w.iconCode?.icon)
        .toList();
    expect(icons, containsAll(['food', 'bank']));
  });

  testWidgets('a system category is localized by its system_kind', (t) async {
    await _pump(
      t,
      const Transaction(
        id: 't2',
        accountId: 'a1',
        type: TransactionType.income,
        amount: 10,
        date: '2026-10-10',
        account: AccountRef(id: 'a1', name: 'Cash'),
        category: EmbeddedCategory(
          id: 'c2',
          name: 'Opening balance',
          type: CategoryType.income,
          isSystem: true,
          systemKind: 'OPENING_IN',
        ),
      ),
    );
    final l = AppLocalizations.of(t.element(find.byType(TransactionTile)))!;
    expect(find.text(l.categorySystemOpening), findsOneWidget);
  });
}
