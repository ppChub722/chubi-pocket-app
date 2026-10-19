import 'package:chubi_pocket/hub/pages/domain_events_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Events pieces: EventCard, EventBillRow (+ child), PositionRow.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [colors]),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 400, child: Column(children: [child])),
      ),
    ),
  );

  Future<double> height(WidgetTester t, Widget child) async {
    await t.pumpWidget(host(child));
    return t.getSize(find.byWidget(child)).height;
  }

  Color? textColor(WidgetTester t, String text) =>
      t.widget<Text>(find.text(text)).style?.color;

  group('EventCard', () {
    testWidgets('shows name, status, meta, tags, plan and my net', (t) async {
      var taps = 0;
      await t.pumpWidget(
        host(
          EventCard(
            name: 'ทริป',
            description: 'หารค่าที่พัก',
            statusLabel: 'กำลังดำเนินการ',
            statusTone: AppChipTone.success,
            meta: '4 คน | 1–5 ต.ค.',
            tags: const [EventTagRef('อาหาร')],
            progress: 0.5,
            progressLabel: 'ใช้ไป ฿500 จาก ฿1,000',
            myNet: 120,
            onTap: () => taps++,
          ),
        ),
      );
      for (final s in [
        'ทริป',
        'หารค่าที่พัก',
        'กำลังดำเนินการ',
        '4 คน | 1–5 ต.ค.',
        'อาหาร',
        'ใช้ไป ฿500 จาก ฿1,000',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.byType(ProgressRow), findsOneWidget);
      expect(find.byType(MoneyText), findsOneWidget);
      expect(textColor(t, '+฿120.00'), colors.income);
      await t.tap(find.text('ทริป'));
      expect(taps, 1);
    });

    testWidgets('no plan / no net: no bar, no amount', (t) async {
      await t.pumpWidget(host(const EventCard(name: 'A')));
      expect(find.byType(ProgressRow), findsNothing);
      expect(find.byType(MoneyText), findsNothing);
    });

    testWidgets(
      'negative net is expense-tinted; dimmed fades and still opens',
      (t) async {
        var taps = 0;
        await t.pumpWidget(
          host(
            EventCard(name: 'B', myNet: -50, dimmed: true, onTap: () => taps++),
          ),
        );
        expect(textColor(t, '−฿50.00'), colors.expense);
        expect(
          find.ancestor(of: find.text('B'), matching: find.byType(Opacity)),
          findsOneWidget,
        );
        await t.tap(find.text('B'));
        expect(taps, 1);
      },
    );
  });

  group('EventBillRow', () {
    testWidgets('texts, tick tap, row tap and tag tap with its context', (
      t,
    ) async {
      var tick = 0, row = 0;
      BuildContext? tagContext;
      int? tagIndex;
      await t.pumpWidget(
        host(
          EventBillRow(
            title: 'ค่าที่พัก',
            amount: -3600,
            payerName: 'มาตาก',
            caption: 'วันนี้',
            summary: 'หาร 4',
            // Short labels: the test font draws every glyph 1 em wide.
            tags: const [EventTagRef('a'), EventTagRef('b')],
            onTagTap: (c, i) {
              tagContext = c;
              tagIndex = i;
            },
            onTickTap: () => tick++,
            onTap: () => row++,
          ),
        ),
      );
      expect(find.text('ค่าที่พัก'), findsOneWidget);
      expect(find.text('มาตาก | วันนี้ | หาร 4'), findsOneWidget);
      expect(find.byType(PersonMark), findsOneWidget);
      expect(textColor(t, '−฿3,600.00'), colors.expense);

      await t.tap(find.byType(SelectCheck));
      expect(tick, 1);
      expect(row, 0);

      await t.tap(find.text('b'));
      expect(tagIndex, 1);
      expect(tagContext, isNotNull);
      expect(
        find.ancestor(of: find.text('b'), matching: find.byType(AppChip)),
        findsOneWidget,
      );

      await t.tap(find.text('ค่าที่พัก'));
      expect(row, 1);
    });

    testWidgets('tagAnchorBuilder wraps each chip', (t) async {
      var opened = <int>[];
      await t.pumpWidget(
        host(
          EventBillRow(
            title: 'x',
            amount: 1,
            tags: const [EventTagRef('a'), EventTagRef('b')],
            tagAnchorBuilder: (context, i, chip) => KeyedSubtree(
              key: ValueKey('anchor$i'),
              child: chip(() => opened.add(i)),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('anchor0')), findsOneWidget);
      expect(find.byKey(const ValueKey('anchor1')), findsOneWidget);
      await t.tap(find.text('b'));
      expect(opened, [1]);
    });

    testWidgets('locked: no taps at all, faded', (t) async {
      var taps = 0;
      await t.pumpWidget(
        host(
          EventBillRow(
            title: 'ล็อก',
            amount: -10,
            tags: const [EventTagRef('t')],
            onTagTap: (_, _) => taps++,
            onTickTap: () => taps++,
            onTap: () => taps++,
            locked: true,
          ),
        ),
      );
      await t.tap(find.byType(SelectCheck), warnIfMissed: false);
      await t.tap(find.text('t'), warnIfMissed: false);
      await t.tap(find.text('ล็อก'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        find.ancestor(of: find.text('ล็อก'), matching: find.byType(Opacity)),
        findsOneWidget,
      );
    });

    testWidgets('marked: ticked and faded; null onTickTap is inert', (t) async {
      await t.pumpWidget(
        host(const EventBillRow(title: 'm', amount: 5, marked: true)),
      );
      expect(t.widget<SelectCheck>(find.byType(SelectCheck)).value, isTrue);
      expect(t.widget<SelectCheck>(find.byType(SelectCheck)).onTap, isNull);
      expect(
        find.ancestor(of: find.text('m'), matching: find.byType(Opacity)),
        findsOneWidget,
      );
      expect(textColor(t, '+฿5.00'), colors.income);
    });

    testWidgets('linked shows the link glyph', (t) async {
      await t.pumpWidget(
        host(const EventBillRow(title: 'l', amount: 1, linked: true)),
      );
      expect(find.byIcon(AppIcons.link), findsOneWidget);
    });

    testWidgets('children render under the row with their own ticks', (
      t,
    ) async {
      var childTicks = 0;
      await t.pumpWidget(
        host(
          EventBillRow(
            title: 'p',
            amount: -300,
            children: [
              EventBillChildRow(
                name: 'บีม',
                caption: 'ติด ฿120',
                amount: 120,
                onTickTap: () => childTicks++,
              ),
              const EventBillChildRow(name: 'ต้น', amount: 180, marked: true),
              EventBillChildRow(
                name: 'ล็อก',
                amount: 1,
                locked: true,
                onTickTap: () => childTicks++,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(SelectCheck), findsNWidgets(4));
      expect(
        find.textContaining('ติด ฿120', findRichText: true),
        findsOneWidget,
      );
      await t.tap(
        find.descendant(
          of: find.byType(EventBillChildRow).first,
          matching: find.byType(SelectCheck),
        ),
      );
      await t.tap(
        find.descendant(
          of: find.byType(EventBillChildRow).last,
          matching: find.byType(SelectCheck),
        ),
        warnIfMissed: false,
      );
      expect(childTicks, 1);
    });

    testWidgets('geometry: bill row (no children) = TxRow height', (t) async {
      final tx = await height(
        t,
        const TxRow(
          leading: SizedBox(width: 36, height: 36),
          title: 'Lunch',
          amount: -120,
          category: 'Food',
        ),
      );
      final bill = await height(
        t,
        const EventBillRow(
          title: 'Lunch',
          amount: -120,
          payerName: 'Lee',
          caption: 'Today',
          tags: [EventTagRef('food')],
          linked: true,
        ),
      );
      expect(bill, closeTo(tx, 1));
      final withGlyph = await height(
        t,
        const EventBillRow(
          title: 'Lunch',
          amount: -120,
          leading: SizedBox(width: 36, height: 36),
          payerName: 'Lee',
          payerLevel: PersonLevel.linked,
        ),
      );
      expect(withGlyph, closeTo(tx, 1));
    });
  });

  group('PositionRow', () {
    testWidgets('label, amount, share bar; signed tone tints by sign', (
      t,
    ) async {
      await t.pumpWidget(
        host(
          const Column(
            children: [
              PositionRow(
                leading: SizedBox(width: 28, height: 28),
                label: 'owed',
                amount: 100,
                share: 0.4,
                tone: MoneyTone.signed,
              ),
              PositionRow(
                label: 'owes',
                amount: -100,
                share: 0.2,
                tone: MoneyTone.signed,
              ),
              PositionRow(label: 'plain', amount: 50, share: 0.1),
            ],
          ),
        ),
      );
      expect(find.text('owed'), findsOneWidget);
      expect(textColor(t, '+฿100.00'), colors.income);
      expect(textColor(t, '−฿100.00'), colors.expense);
      expect(find.text('฿50.00'), findsOneWidget);
      expect(find.byType(ProgressRow), findsNWidgets(3));
      final bar = t.widget<ProgressRow>(find.byType(ProgressRow).first);
      expect(bar.value, 0.4);
      expect(bar.height, PositionRow.barHeight);
    });

    testWidgets('layout: label row on top, bar under it, both right of the '
        'leading', (t) async {
      const lead = SizedBox(width: 28, height: 28);
      await t.pumpWidget(
        host(
          const PositionRow(
            leading: lead,
            label: 'มาตาก',
            amount: 1250,
            share: 0.5,
          ),
        ),
      );
      final label = t.getRect(find.text('มาตาก'));
      final amount = t.getRect(find.text('฿1,250.00'));
      final bar = t.getRect(find.byType(ProgressRow));
      final leading = t.getRect(find.byWidget(lead));
      expect(bar.top, greaterThanOrEqualTo(label.bottom));
      expect(bar.left, closeTo(label.left, 0.5));
      expect(bar.right, closeTo(amount.right, 0.5));
      expect(label.left, greaterThan(leading.right));
      expect(amount.center.dy, closeTo(label.center.dy, 2));
    });

    testWidgets('onTap fires', (t) async {
      var taps = 0;
      await t.pumpWidget(
        host(PositionRow(label: 'x', amount: 1, share: 0, onTap: () => taps++)),
      );
      await t.tap(find.text('x'));
      expect(taps, 1);
    });
  });

  testWidgets('highlighted: a tint flashes, then fades away', (t) async {
    Widget row(bool on) =>
        host(EventBillRow(title: 'ค่าที่พัก', amount: -3200, highlighted: on));
    double tint() {
      final boxes = t.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(EventBillRow),
          matching: find.byType(DecoratedBox),
        ),
      );
      return boxes
          .map((b) => (b.decoration as BoxDecoration?)?.color?.a ?? 0)
          .fold<double>(0, (m, a) => a > m ? a : m);
    }

    await t.pumpWidget(row(false));
    await t.pump(const Duration(milliseconds: 100));
    expect(tint(), 0);
    await t.pumpWidget(row(true));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(tint(), greaterThan(0));
    await t.pump(const Duration(seconds: 2));
    expect(tint(), 0);
  });

  testWidgets('hub page builds, playgrounds open, no layout errors', (t) async {
    t.view.physicalSize = const Size(420 * 3, 4000 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.toString());
    addTearDown(() => FlutterError.onError = previous);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => AppUiConfig(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: buildEventsPage(context),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));
    for (final title in ['Customize | EventCard', 'Customize | EventBillRow']) {
      await t.ensureVisible(find.text(title));
      await t.tap(find.text(title));
      await t.pumpAndSettle();
    }
    expect(find.byType(EventCard), findsNWidgets(5));
    // 6 in the demos + the highlight demo.
    expect(find.byType(EventBillRow), findsNWidgets(7));
    t.takeException();
    expect(errors, isEmpty, reason: errors.join('\n---\n'));
  });
}
