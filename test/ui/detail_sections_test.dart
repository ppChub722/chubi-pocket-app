import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);
  Widget host(Widget child, {double width = 400, bool offline = false}) =>
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: ConnectionScope(
            offline: offline,
            reconnects: 0,
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(width: width, child: child),
              ),
            ),
          ),
        ),
      );

  const longValue =
      'A rather long address value that will not fit beside its label';

  testWidgets('InfoRow: short value stays on one row (DetailRow)', (t) async {
    await t.pumpWidget(
      host(
        const InfoBox(
          rows: [InfoRow(label: 'Currency', value: 'THB')],
        ),
      ),
    );
    expect(find.byType(DetailRow), findsOneWidget);
    expect(find.byType(DetailStacked), findsNothing);
  });

  testWidgets('InfoRow: long value stacks; wide host keeps it on one row', (
    t,
  ) async {
    const row = InfoBox(
      rows: [InfoRow(label: 'Note', value: 'Mid')],
    );
    await t.pumpWidget(host(row, width: 400));
    expect(find.byType(DetailRow), findsOneWidget);
    await t.pumpWidget(host(row, width: 150));
    expect(find.byType(DetailStacked), findsOneWidget);
    await t.pumpWidget(
      host(
        const InfoBox(
          rows: [InfoRow(label: 'Address', value: longValue)],
        ),
        width: 360,
      ),
    );
    expect(find.byType(DetailStacked), findsOneWidget);
    await t.pumpWidget(
      host(
        const InfoBox(
          rows: [InfoRow(label: 'Address', value: 'Bangkok, Thailand')],
        ),
        width: 800,
      ),
    );
    expect(find.byType(DetailRow), findsOneWidget);
  });

  testWidgets('SettingToggleRow calls back; offline disables submits', (
    t,
  ) async {
    bool? got;
    Widget toggle({bool offline = false, bool submits = true}) => host(
      SettingsSection(
        title: 'Settings',
        children: [
          SettingToggleRow(
            label: 'Show',
            value: false,
            submits: submits,
            onChanged: (v) => got = v,
          ),
        ],
      ),
      offline: offline,
    );
    await t.pumpWidget(toggle());
    await t.tap(find.byType(Switch));
    expect(got, isTrue);
    got = null;
    await t.pumpWidget(toggle(offline: true));
    await t.tap(find.byType(Switch), warnIfMissed: false);
    expect(got, isNull);
    await t.pumpWidget(toggle(offline: true, submits: false));
    await t.tap(find.byType(Switch));
    expect(got, isTrue);
  });

  testWidgets('EndZone shows close -> archive -> delete, offline disables', (
    t,
  ) async {
    final taps = <String>[];
    EndZoneAction a(EndZoneKind k, String l, {bool submits = true}) =>
        EndZoneAction(
          kind: k,
          label: l,
          consequence: 'c-$l',
          submits: submits,
          onTap: () => taps.add(l),
        );
    Widget zone({bool offline = false}) => host(
      EndZone(
        actions: [
          a(EndZoneKind.delete, 'Delete'),
          a(EndZoneKind.close, 'Close'),
          a(EndZoneKind.archive, 'Archive', submits: false),
        ],
      ),
      offline: offline,
    );
    await t.pumpWidget(zone());
    final y = [
      for (final l in ['Close', 'Archive', 'Delete'])
        t.getTopLeft(find.text(l)).dy,
    ];
    expect(y[0] < y[1] && y[1] < y[2], isTrue);
    expect(find.text('c-Close'), findsOneWidget);
    await t.pumpWidget(zone(offline: true));
    await t.tap(find.text('Close'), warnIfMissed: false);
    await t.tap(find.text('Delete'), warnIfMissed: false);
    expect(taps, isEmpty);
    await t.tap(find.text('Archive'));
    expect(taps, ['Archive']);
  });

  testWidgets('PeopleStrip, NoteSection, TagRow render and call back', (
    t,
  ) async {
    var invited = false;
    var longPressed = false;
    var added = false;
    await t.pumpWidget(
      host(
        Column(
          children: [
            PeopleStrip(
              title: 'People',
              inviteLabel: 'Invite',
              onInvite: () => invited = true,
              members: const [
                PeopleStripMember(
                  avatar: AppAvatar(name: 'Aom'),
                  name: 'Aom',
                  caption: 'owes 1',
                  tone: PeopleTone.negative,
                ),
              ],
            ),
            NoteSection(
              label: 'Note',
              editing: false,
              hint: 'Hold to edit',
              onLongPress: () => longPressed = true,
            ),
            TagRow(
              tags: const [AppChip(label: '#a', size: ChipSize.mini)],
              addLabel: 'Tag',
              onAdd: () => added = true,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Aom'), findsWidgets);
    expect(find.text('Hold to edit'), findsOneWidget);
    await t.tap(find.text('Invite'));
    await t.tap(find.text('Tag'));
    await t.longPress(find.text('Hold to edit'));
    expect(invited && added && longPressed, isTrue);
  });
}
