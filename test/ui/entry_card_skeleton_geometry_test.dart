import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The quick create / draft first-load skeleton has the real EntryCard's
/// geometry (owner 2026-10-13: skeletons mirror the real layout): the same
/// height, and its rows on the same y, at text scale 1.0 and 1.3.
void main() {
  Future<Rect> rectOf(
    WidgetTester t,
    Widget child, {
    required double scale,
  }) async {
    final key = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeBuilder.build(
          theme: ThemeRegistry.byId(ThemeRegistry.defaultThemeId),
          font: FontRegistry.inter,
          brightness: Brightness.light,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: AppUiConfig(child: c!),
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 412,
              child: KeyedSubtree(key: key, child: child),
            ),
          ),
        ),
      ),
    );
    return t.getRect(find.byKey(key));
  }

  Widget chipRow(IconData icon, List<String> labels) => Row(
    children: [
      PpForgeIcon(icon, size: PpForgeIconSize.md),
      for (final l in labels) PpForgeChip(label: l, onTap: () {}),
    ],
  );

  for (final scale in [1.0, 1.3]) {
    testWidgets('EntryCardSkeleton = the real EntryCard (scale $scale)', (
      t,
    ) async {
      final real = await rectOf(
        t,
        EntryCard(
          type: TransactionType.expense,
          amount: TextEditingController(text: '120'),
          title: TextEditingController(text: 'ข้าว'),
          dateLabel: 'วันนี้',
          onTypeChanged: (_) {},
          onPickDate: () {},
          walletRow: chipRow(PpForgeIcons.wallet, ['เงินสด', 'กสิกร']),
          categoryRow: chipRow(PpForgeIcons.category, ['อาหาร', 'เดินทาง']),
        ),
        scale: scale,
      );
      final skel = await rectOf(t, const EntryCardSkeleton(), scale: scale);
      expect(skel.height, closeTo(real.height, 1));
    });
  }
}
