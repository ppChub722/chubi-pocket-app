import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [sweetTheme.lightColors]),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _groups = [
  RecurringPickGroup(
    title: 'Recurring',
    rows: [
      RecurringPickRow(
        id: 'a',
        title: 'Car loan',
        subtitle: 'Every 16th',
        leading: Icon(Icons.repeat),
        amount: 3023,
        tone: MoneyTone.expense,
      ),
      RecurringPickRow(
        id: 'c',
        title: 'Netflix',
        leading: Icon(Icons.repeat),
        amount: 419,
      ),
    ],
  ),
  RecurringPickGroup(
    title: 'Reminders',
    rows: [
      RecurringPickRow(
        id: 'b',
        title: 'Water bill',
        leading: Icon(Icons.notifications),
        trailingLabel: 'Amount pending',
      ),
    ],
  ),
];

/// An [AppIconButton] keeps a faded ✓ for its "done" state; only count the rest.
Iterable<Element> rowChecks() => find
    .byIcon(Icons.check)
    .evaluate()
    .where((e) => e.findAncestorWidgetOfExactType<AppIconButton>() == null);

void main() {
  RecurringPickerSheet sheet({
    String? selected,
    List<RecurringPickGroup> groups = _groups,
    bool loading = false,
    Object? error,
    ValueChanged<String>? onPicked,
    VoidCallback? onCreate,
    VoidCallback? onRetry,
  }) => RecurringPickerSheet(
    title: 'Link',
    groups: groups,
    selectedId: selected,
    createLabel: 'Create new',
    emptyText: 'Nothing',
    loading: loading,
    error: error,
    onRetry: onRetry,
    onPicked: onPicked ?? (_) {},
    onCreate: onCreate ?? () {},
  );

  testWidgets('groups with headers, amounts and the pending-amount label', (
    t,
  ) async {
    await t.pumpWidget(host(sheet()));
    expect(find.text('Recurring'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Car loan'), findsOneWidget);
    expect(find.text('Every 16th'), findsOneWidget);
    expect(find.text('Amount pending'), findsOneWidget);
    expect(find.byType(MoneyText), findsNWidgets(2));
    expect(find.text('Create new'), findsOneWidget);
  });

  testWidgets('tap picks the row id; the footer asks to create', (t) async {
    String? picked;
    var created = 0;
    await t.pumpWidget(
      host(sheet(onPicked: (id) => picked = id, onCreate: () => created++)),
    );
    await t.tap(find.text('Water bill'));
    expect(picked, 'b');
    await t.tap(find.text('Create new'));
    expect(created, 1);
  });

  testWidgets('selection is a highlight, never a check', (t) async {
    await t.pumpWidget(host(sheet(selected: 'a')));
    final rows = t.widgetList<PickerRow>(find.byType(PickerRow)).toList();
    expect(rows.where((r) => r.selected).map((r) => r.title), ['Car loan']);
    expect(rowChecks(), isEmpty);
  });

  testWidgets('search filters by title and drops empty groups', (t) async {
    await t.pumpWidget(host(sheet()));
    await t.tap(find.byIcon(AppIcons.search));
    await t.pump();
    await t.enterText(find.byType(TextField), 'net');
    await t.pump();
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Car loan'), findsNothing);
    expect(find.text('Reminders'), findsNothing);
    await t.enterText(find.byType(TextField), 'zzz');
    await t.pump();
    expect(find.text('Nothing'), findsOneWidget);
  });

  testWidgets('failing load shows the retry', (t) async {
    var retried = 0;
    await t.pumpWidget(
      host(sheet(error: Exception('boom'), onRetry: () => retried++)),
    );
    expect(find.text('Car loan'), findsNothing);
    final view = t.widget<ErrorView>(find.byType(ErrorView));
    view.onRetry!();
    expect(retried, 1);
  });
}
