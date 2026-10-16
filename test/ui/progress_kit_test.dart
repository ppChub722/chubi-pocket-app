import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The budgets v2 / saving goals kit: the expected segment of ProgressRow,
/// ProgressCard (tone colours, % not clamped), the summary / hero footer,
/// BreakdownRow, StatGrid, the scope prompt, the default currency, DetailRow
/// errors, ListPageBody.rowGap and the simple recurrence editor.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Widget host(Widget child, {PpForgeStrings? strings}) {
    final app = MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [colors]),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
    return strings == null
        ? app
        : PpForgeConfig(strings: strings, errors: const _Errors(), child: app);
  }

  Future<void> wide(WidgetTester t) async {
    t.view.physicalSize = const Size(420, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('ProgressRow expected segment', () {
    test('segments clamp the total at 100%', () {
      final s = ProgressRow.segments(0.39, 0.09);
      expect(s.$1, 0.39);
      expect(s.$2, closeTo(0.48, 1e-9));
      expect(ProgressRow.segments(0.9, 0.4), (0.9, 1.0));
      expect(ProgressRow.segments(1.22, 0.1), (1.0, 1.0));
      expect(ProgressRow.segments(0, null), (0.0, 0.0));
    });

    testWidgets('geometry: used and expected widths follow the track', (
      t,
    ) async {
      await wide(t);
      await t.pumpWidget(
        host(
          const SizedBox(
            width: 400,
            child: ProgressRow(value: 0.4, expected: 0.2),
          ),
        ),
      );
      await t.pumpAndSettle();
      final track = t.getSize(find.byType(ClipRRect).first).width;
      final used = t.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('progressUsed')),
          matching: find.byType(ColoredBox),
        ),
      );
      final exp = t.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('progressExpected')),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(used.width, closeTo(track * 0.4, 0.5));
      expect(exp.width, closeTo(track * 0.6, 0.5));
    });

    testWidgets('no expected segment without expected', (t) async {
      await t.pumpWidget(host(const ProgressRow(value: 0.4)));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('progressExpected')), findsNothing);
    });
  });

  group('ProgressCard', () {
    testWidgets('bar clamps visually, the % text is not clamped', (t) async {
      await wide(t);
      await t.pumpWidget(
        host(
          const ProgressCard(
            title: 'Shopping',
            value: 1.22,
            tone: ProgressTone.danger,
            label: 'Used 4,860 of 4,000',
            overLabel: 'Over 860',
            percentText: '122%',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('122%'), findsOneWidget);
      expect(find.text('Over 860'), findsOneWidget);
      final track = t.getSize(find.byType(ClipRRect).first).width;
      expect(
        t
            .getSize(
              find.descendant(
                of: find.byKey(const ValueKey('progressUsed')),
                matching: find.byType(ColoredBox),
              ),
            )
            .width,
        closeTo(track, 0.5),
      );
    });

    testWidgets('tone colours the bar; neutral takes the entity tint', (
      t,
    ) async {
      await wide(t);
      Future<Color> barColor(ProgressTone tone, {IconCode? code}) async {
        await t.pumpWidget(
          host(
            ProgressCard(
              title: 'x',
              value: 0.5,
              tone: tone,
              iconCode: code,
              percentText: '50%',
            ),
          ),
        );
        await t.pumpAndSettle();
        final box = t.widget<ColoredBox>(
          find.descendant(
            of: find.byKey(const ValueKey('progressUsed')),
            matching: find.byType(ColoredBox),
          ),
        );
        return box.color;
      }

      expect(await barColor(ProgressTone.warning), colors.warning);
      expect(await barColor(ProgressTone.danger), colors.error);
      expect(await barColor(ProgressTone.success), colors.success);
      expect(
        await barColor(
          ProgressTone.neutral,
          code: const IconCode(icon: 'restaurant', iconColors: ['#F97316']),
        ),
        const Color(0xFFF97316),
      );
    });

    testWidgets('onTap, badge, struck label; compact has no tile', (t) async {
      await wide(t);
      var taps = 0;
      await t.pumpWidget(
        host(
          ProgressCard.compact(
            title: 'Oct 2026',
            value: 0.3,
            badge: const Text('this period'),
            label: '300 of 800',
            struckLabel: '600',
            onTap: () => taps++,
          ),
        ),
      );
      await t.tap(find.text('Oct 2026'));
      expect(taps, 1);
      expect(find.text('this period'), findsOneWidget);
      expect(find.byType(IconCodeWidget), findsNothing);
    });

    testWidgets('skeleton draws no text', (t) async {
      await wide(t);
      await t.pumpWidget(host(const ProgressCard.skeleton()));
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(Text), findsNothing);
      await t.pumpWidget(host(const ProgressSummary.skeleton()));
      expect(find.byType(SkeletonBox), findsWidgets);
      await t.pumpWidget(host(const ProgressHeroFooter.skeleton()));
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  testWidgets('ProgressSummary + hero footer show their texts', (t) async {
    await wide(t);
    await t.pumpWidget(
      host(
        const Column(
          children: [
            ProgressSummary(
              amount: 12400,
              caption: 'used',
              value: 0.62,
              percentText: '62%',
              footnote: 'left 7,600',
            ),
            ProgressHeroFooter(
              amount: 3120,
              subCaption: 'of 8,000',
              value: 0.39,
              expected: 0.09,
              legendUsed: 'used 39%',
              legendExpected: 'expected +720',
            ),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('฿12,400.00'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('left 7,600'), findsOneWidget);
    expect(find.text('฿3,120.00'), findsOneWidget);
    expect(find.text('expected +720'), findsOneWidget);
  });

  testWidgets('BreakdownRow: expected is muted with a +, bar is striped', (
    t,
  ) async {
    await wide(t);
    await t.pumpWidget(
      host(
        const Column(
          children: [
            BreakdownRow(label: 'Normal', amount: 100, value: 0.5),
            BreakdownRow(
              label: 'Ahead',
              amount: 50,
              expected: true,
              value: 0.2,
            ),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('+'), findsOneWidget);
    expect(find.byKey(const ValueKey('progressExpected')), findsOneWidget);
    expect(find.byKey(const ValueKey('progressUsed')), findsNWidgets(2));
  });

  testWidgets('StatGrid lays tiles in 2 columns', (t) async {
    await wide(t);
    await t.pumpWidget(
      host(
        const StatGrid(
          children: [
            StatTile(caption: 'a', value: '1'),
            StatTile(caption: 'b', value: '2', tone: Tone.warning),
            StatTile(caption: 'c', value: '3', tone: Tone.danger),
          ],
        ),
      ),
    );
    final a = t.getTopLeft(find.text('a'));
    final b = t.getTopLeft(find.text('b'));
    final c = t.getTopLeft(find.text('c'));
    expect(b.dx, greaterThan(a.dx + 50));
    expect(b.dy, a.dy);
    expect(c.dy, greaterThan(a.dy));
    expect(c.dx, a.dx);
  });

  testWidgets('SourceChips folds the overflow into +n', (t) async {
    await t.pumpWidget(
      host(
        const SourceChips(
          maxVisible: 2,
          items: [
            SourceChipItem('a'),
            SourceChipItem('b'),
            SourceChipItem('c'),
            SourceChipItem('d'),
          ],
        ),
      ),
    );
    expect(find.text('a'), findsOneWidget);
    expect(find.text('c'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
  });

  group('scope prompt', () {
    Future<EditScope? Function()> open(WidgetTester t) async {
      EditScope? result = EditScope.thisOne;
      var done = false;
      await t.pumpWidget(
        host(
          Builder(
            builder: (context) => PpForgeButton(
              label: 'open',
              onPressed: () async {
                result = await showScopePrompt(
                  context,
                  title: 'Apply to',
                  cancelLabel: 'Not yet',
                  followingLabel: 'This and following',
                  allLabel: 'All periods',
                );
                done = true;
              },
            ),
          ),
        ),
      );
      return () {
        expect(done, isTrue);
        return result;
      };
    }

    for (final (label, expected) in [
      ('This and following', EditScope.following),
      ('All periods', EditScope.all),
      ('Not yet', null),
    ]) {
      testWidgets('"$label" resolves $expected', (t) async {
        final result = await open(t);
        await t.pumpAndSettle();
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.tap(find.text(label));
        await t.pumpAndSettle();
        expect(result(), expected);
      });
    }
  });

  group('default currency', () {
    testWidgets(
      'MoneyText / moneyString follow PpForgeConfig, symbol overrides',
      (t) async {
        late String s;
        await t.pumpWidget(
          host(
            Builder(
              builder: (context) {
                s = moneyString(context, 5);
                return const Column(
                  children: [
                    MoneyText(1234.5),
                    MoneyText(1, symbol: r'$'),
                  ],
                );
              },
            ),
            strings: const PpForgeStrings(currencySymbol: '€'),
          ),
        );
        expect(find.text('€1,234.50'), findsOneWidget);
        expect(find.text(r'$1.00'), findsOneWidget);
        expect(s, '€5.00');
      },
    );

    testWidgets('no config = the baht default', (t) async {
      await t.pumpWidget(host(const MoneyText(2)));
      expect(find.text('฿2.00'), findsOneWidget);
    });
  });

  testWidgets('DetailRow shows its error under the label', (t) async {
    await t.pumpWidget(
      host(
        DetailRow.pick(
          label: 'Category',
          emptyText: 'none',
          error: 'Pick a category',
        ),
      ),
    );
    expect(find.text('Pick a category'), findsOneWidget);
    final style = t.widget<Text>(find.text('Pick a category')).style;
    expect(
      style?.color,
      Theme.of(t.element(find.byType(Scaffold))).colorScheme.error,
    );
  });

  testWidgets('ListPageBody rowGap spaces the cards', (t) async {
    t.view.physicalSize = const Size(420, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: () async {},
            empty: const EmptyView.compact(message: 'none'),
            rowGap: 10,
            children: const [
              SizedBox(height: 40, child: Text('one')),
              SizedBox(height: 40, child: Text('two')),
            ],
          ),
        ),
      ),
    );
    final gap =
        t.getTopLeft(find.text('two')).dy - t.getTopLeft(find.text('one')).dy;
    expect(gap, 50);
  });

  group('RecurrenceEditor simple', () {
    testWidgets('no weekday / monthly options; rule has none', (t) async {
      await wide(t);
      RecurrenceRule? last;
      final start = DateTime(2026, 10, 13);
      await t.pumpWidget(
        host(
          RecurrenceEditor(
            initial: RecurrenceRule(
              freq: RecurrenceFreq.weekly,
              start: start,
              weekdays: const {2, 4},
            ),
            simple: true,
            onChanged: (r) => last = r,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('recurWeekday1')), findsNothing);
      // Switch to monthly: still no day / Nth weekday chips.
      await t.tap(find.text('month'));
      await t.pumpAndSettle();
      expect(last?.freq, RecurrenceFreq.monthly);
      expect(last?.monthly, isNull);
      expect(last?.weekdays, isEmpty);
      await t.tap(find.text('week'));
      await t.pumpAndSettle();
      expect(last?.freq, RecurrenceFreq.weekly);
      expect(last?.weekdays, isEmpty);
    });
  });

  testWidgets('walletValueChip renders the wallet name', (t) async {
    await t.pumpWidget(
      host(
        Builder(
          builder: (context) => walletValueChip(context, name: 'KTC card'),
        ),
      ),
    );
    expect(find.text('KTC card'), findsOneWidget);
  });
}

class _Errors extends PpForgeErrors {
  const _Errors();

  @override
  PpForgeErrorInfo describe(Object error) => const PpForgeErrorInfo(
    icon: Icons.error_outline,
    title: 'x',
    message: 'y',
  );
}
