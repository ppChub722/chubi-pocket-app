import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The hero's two fields (description · amount) in create / edit: their NAME
/// labels share one top and their UNDERLINES share one y, in every state
/// (empty / filled / focused), both languages and at text scale 1.0 and 1.3.
/// Measured on the DRAWN pixels (the owner's screenshots showed 3-10 px
/// offsets that widget rects did not).
enum _Which { hero, entry }

enum _State { empty, filled, focusTitle, focusAmount }

void main() {
  for (final which in _Which.values) {
    for (final lang in const ['th', 'en']) {
      for (final scale in const [1.0, 1.3]) {
        for (final state in _State.values) {
          testWidgets('${which.name} · $lang · ×$scale · ${state.name}', (
            t,
          ) async {
            final amount = TextEditingController();
            final title = TextEditingController();
            final amountFocus = FocusNode();
            final titleFocus = FocusNode();
            addTearDown(() {
              amount.dispose();
              title.dispose();
              amountFocus.dispose();
              titleFocus.dispose();
            });
            if (state != _State.empty) {
              amount.text = '1,250';
              title.text = 'ข้าวมันไก่';
            }
            final key = GlobalKey();
            final card = switch (which) {
              _Which.hero => TxHeroCard(
                type: TransactionType.expense,
                amount: amount,
                title: title,
                amountFocus: amountFocus,
                titleFocus: titleFocus,
                dateLabel: 'x',
                inline: true,
              ),
              _Which.entry => EntryCard(
                type: TransactionType.expense,
                amount: amount,
                title: title,
                amountFocus: amountFocus,
                titleFocus: titleFocus,
                dateLabel: 'x',
                walletRow: const SizedBox(height: 32),
                categoryRow: const SizedBox(height: 32),
              ),
            };
            await t.pumpWidget(
              MaterialApp(
                theme: ThemeData(extensions: [sweetTheme.lightColors]),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale(lang),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: key,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: card,
                      ),
                    ),
                  ),
                ),
              ),
            );
            if (state == _State.focusTitle) titleFocus.requestFocus();
            if (state == _State.focusAmount) amountFocus.requestFocus();
            await t.pumpAndSettle();

            final l = AppLocalizations.of(t.element(find.byType(TxHeroCard)))!;
            // 1. the two NAME labels share one top.
            final descTop = t.getTopLeft(find.text(l.commonDescription)).dy;
            final amountTop = t
                .getTopLeft(find.text(l.transactionFormAmountLabel))
                .dy;
            expect(descTop, closeTo(amountTop, 0.5), reason: 'label tops');

            // 2. the DRAWN underlines share one y.
            final fields = find.byType(AppInput);
            expect(fields, findsNWidgets(2));
            final image = (await t.runAsync(() async {
              final b =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              return b.toImage(pixelRatio: 1);
            }))!;
            final data = (await t.runAsync(() => image.toByteData()))!;
            final scheme = Theme.of(
              t.element(find.byType(TxHeroCard)),
            ).colorScheme;
            final accent = txTypeColor(
              t.element(find.byType(TxHeroCard)),
              TransactionType.expense,
            );
            Color idle() =>
                state == _State.empty ? scheme.outlineVariant : scheme.outline;
            Color colorOf(int field) {
              final focused =
                  (field == 0 && state == _State.focusTitle) ||
                  (field == 1 && state == _State.focusAmount);
              return focused ? accent : idle();
            }

            int lowest(int field) {
              final r = t.getRect(fields.at(field));
              final want = colorOf(field).toARGB32();
              final x = (r.left + 12).round();
              var hit = -1;
              for (
                var y = r.top.round();
                y < r.bottom.round() + 4 && y < image.height;
                y++
              ) {
                final o = (y * image.width + x) * 4;
                final c = Color.fromARGB(
                  data.getUint8(o + 3),
                  data.getUint8(o),
                  data.getUint8(o + 1),
                  data.getUint8(o + 2),
                );
                if (c.toARGB32() == want) hit = y;
              }
              return hit;
            }

            final titleLine = lowest(0);
            final amountLine = lowest(1);
            expect(titleLine, greaterThan(0), reason: 'title underline');
            expect(amountLine, greaterThan(0), reason: 'amount underline');
            expect(titleLine, amountLine, reason: 'underline y');
          });
        }
      }
    }
  }
}
