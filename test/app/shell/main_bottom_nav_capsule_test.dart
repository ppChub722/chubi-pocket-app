import 'package:chubi_pocket/app/shell/main_bottom_nav.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The centre create button (owner 2026-10-22, mock QuickCreateBtn) at 320
/// and 390, Thai: a 48-high capsule (icon + บันทึก / จดหนี้ / ออมเงิน) in the
/// mode's colour, centred in its own slot — never over the tabs beside it.
/// Plus the in-page + and the empty-state CTA wear the mode colour.
void main() {
  Future<void> pump(WidgetTester t, double width, Widget child) {
    t.view.physicalSize = Size(width * 3, 400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    return t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      ),
    );
  }

  for (final width in [320.0, 390.0]) {
    for (final (mode, word) in [
      (QuickCreateMode.tx, 'บันทึก'),
      (QuickCreateMode.debt, 'จดหนี้'),
      (QuickCreateMode.saving, 'ออมเงิน'),
    ]) {
      testWidgets('at $width, ${mode.name}: the capsule fits its slot', (
        t,
      ) async {
        var taps = 0;
        await pump(
          t,
          width,
          MainBottomNav(
            currentIndex: 1,
            addMode: mode,
            onTabSelected: (_) {},
            onAddPressed: () => taps++,
            onMorePressed: () {},
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final button = find.byType(QuickCreateButton);
        final rect = t.getRect(button);
        expect(rect.height, QuickCreateButton.capsuleHeight);
        expect(find.text(word), findsOneWidget);
        // Centred on the screen; clear of the tab before and after it.
        expect(rect.center.dx, closeTo(width / 2, 0.5));
        final before = t.getRect(find.text('รายการ').first);
        final after = t.getRect(find.text('กระเป๋า').first);
        expect(rect.left, greaterThan(before.right));
        expect(rect.right, lessThan(after.left));
        // The mode's colour.
        final fill = t
            .widget<Material>(
              find.descendant(of: button, matching: find.byType(Material)),
            )
            .color;
        expect(fill, QuickCreateModeColors.of(t.element(button), mode));
        await t.tap(button);
        expect(taps, 1);
      });
    }
  }

  testWidgets('the head + and the CTA wear the mode colour', (t) async {
    var head = 0;
    var cta = 0;
    await pump(
      t,
      390,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickCreateHeadButton(
            mode: QuickCreateMode.debt,
            onPressed: () => head++,
          ),
          QuickCreateCtaButton(
            mode: QuickCreateMode.debt,
            label: 'จดหนี้',
            onPressed: () => cta++,
          ),
        ],
      ),
    );
    final debt = QuickCreateModeColors.of(
      t.element(find.byType(QuickCreateHeadButton)),
      QuickCreateMode.debt,
    );
    final plus = t.widget<AppIcon>(
      find.descendant(
        of: find.byType(QuickCreateHeadButton),
        matching: find.byType(AppIcon),
      ),
    );
    expect(plus.color, debt);
    final ctaTheme = Theme.of(
      t.element(
        find.descendant(
          of: find.byType(QuickCreateCtaButton),
          matching: find.byType(AppButton),
        ),
      ),
    );
    expect(ctaTheme.colorScheme.primary, debt);
    await t.tap(find.byType(QuickCreateHeadButton));
    await t.tap(find.text('จดหนี้'));
    expect((head, cta), (1, 1));
  });
}
