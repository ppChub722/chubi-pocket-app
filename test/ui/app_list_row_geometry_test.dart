import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// AppRow plan step 0: AppListRow's geometry, fill and opacity, recorded at
/// app main `8e28650` (before AppListRow moved onto AppRow). The rebuild must
/// keep every value; a change here is a visual change to every list.
void main() {
  const leadingKey = Key('leading');
  const valueKey = Key('value');
  const footerKey = Key('footer');
  final row = find.byType(AppListRow);
  final title = find.text('Title text');
  void noop() {}

  Widget leading() => const SizedBox.square(key: leadingKey, dimension: 40);

  /// A footer that paints the row's hero accent (black outside a scope).
  Widget footer() => Builder(
    builder: (context) => SizedBox(
      key: footerKey,
      height: 6,
      child: ColoredBox(
        color: HeroColors.maybeOf(context)?.accent ?? const Color(0xFF000000),
      ),
    ),
  );

  Future<void> base(WidgetTester t, GeometrySnap s) async {
    s.rect('row', row);
    s.rect('leading', find.byKey(leadingKey));
    s.rect('title', title);
    s.opacity('opacity', title);
    final r = t.getRect(row);
    await s.pixel('fill', r.topLeft + const Offset(3, 3));
  }

  final cases = <String, GeometryCase>{
    'plain': (
      build: () => AppListRow(leading: leading(), title: 'Title text'),
      measure: base,
    ),
    'check': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        checked: true,
        onTap: noop,
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('check', find.byType(SelectCheck));
      },
    ),
    'markChipsStatus': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        titleMark: const ListRowMark(Icons.link, color: Color(0xFF00897B)),
        titleChips: const [ListRowChip('Chip A')],
        status: const ListRowChip('Status', tone: Tone.warning),
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('mark', find.byIcon(Icons.link));
        s.rect('chipA', find.text('Chip A'));
        s.rect('status', find.text('Status'));
      },
    ),
    'lines': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        line2: const ListRowLine(
          icon: Icons.repeat,
          parts: ['Line two', 'more'],
          glyphs: [ListRowGlyph(Icons.link, text: '2')],
        ),
        line3: const ListRowLine(parts: ['Line three']),
        alert: const ListRowAlert('Alert text'),
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('line2', find.text('Line two | more', findRichText: true));
        s.rect('line2icon', find.byIcon(Icons.repeat));
        s.rect('glyph', find.byIcon(Icons.link));
        s.rect('line3', find.text('Line three', findRichText: true));
        s.rect('alert', find.text('Alert text'));
      },
    ),
    'trailing': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        trailing: const ListRowTrailing.value(
          Text('1,234.00', key: valueKey),
          caption: 'Caption',
        ),
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('value', find.byKey(valueKey));
        s.rect('caption', find.text('Caption'));
      },
    ),
    'actions': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        trailing: const ListRowTrailing.text('Due'),
        actions: [
          ListRowAction.icon(Icons.edit, onTap: noop),
          ListRowAction.button(Icons.check, onTap: noop),
        ],
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('value', find.text('Due'));
        s.rect('action1', find.byIcon(Icons.edit));
        s.rect('action2', find.byIcon(Icons.check));
      },
    ),
    'footer': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        trailing: const ListRowTrailing.value(Text('99', key: valueKey)),
        footer: footer(),
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('value', find.byKey(valueKey));
        s.rect('footer', find.byKey(footerKey));
        await s.pixel('footerPx', t.getRect(find.byKey(footerKey)).center);
      },
    ),
    'indent': (
      build: () =>
          AppListRow(leading: leading(), title: 'Title text', indent: 24),
      measure: base,
    ),
    'dimmed': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        trailing: const ListRowTrailing.value(Text('99', key: valueKey)),
        dimmed: true,
        onTap: noop,
      ),
      measure: (t, s) async {
        await base(t, s);
        s.opacity('valueOpacity', find.byKey(valueKey));
      },
    ),
    'highlighted': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        highlighted: true,
        onTap: noop,
      ),
      measure: base,
    ),
    'accent': (
      build: () => AppListRow(
        leading: leading(),
        title: 'Title text',
        accent: const Color(0xFFFFC107),
        footer: footer(),
      ),
      measure: (t, s) async {
        await base(t, s);
        s.rect('footer', find.byKey(footerKey));
        await s.pixel('footerPx', t.getRect(find.byKey(footerKey)).center);
      },
    ),
  };

  geometryMatrix(cases, _expected);
}

const _expected = <String, String>{
  'plain@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=00000000',
  'plain@320@1.3':
      'row=0,0,320,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=1.00 fill=00000000',
  'plain@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=00000000',
  'plain@420@1.3':
      'row=0,0,420,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=1.00 fill=00000000',
  'plain@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=00000000',
  'plain@800@1.3':
      'row=0,0,800,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=1.00 fill=00000000',
  'check@320@1.0':
      'row=0,0,320,56 leading=48,8,40,40 title=100,16,165,24 opacity=1.00 fill=14140B0E check=16,14,28,28',
  'check@320@1.3':
      'row=0,0,320,56 leading=48,8,40,40 title=100,12.5,204,31 opacity=1.00 fill=14140B0E check=16,14,28,28',
  'check@420@1.0':
      'row=0,0,420,56 leading=48,8,40,40 title=100,16,165,24 opacity=1.00 fill=14140B0E check=16,14,28,28',
  'check@420@1.3':
      'row=0,0,420,56 leading=48,8,40,40 title=100,12.5,213,31 opacity=1.00 fill=14140B0E check=16,14,28,28',
  'check@800@1.0':
      'row=0,0,800,56 leading=48,8,40,40 title=100,16,165,24 opacity=1.00 fill=14140B0E check=16,14,28,28',
  'check@800@1.3':
      'row=0,0,800,56 leading=48,8,40,40 title=100,12.5,213,31 opacity=1.00 fill=14140B0E check=16,14,28,28',
  'markChipsStatus@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=90.4,16,55.6,24 opacity=1.00 fill=00000000 mark=68,18.8,18.4,18.4 chipA=156,22,63,12 status=235,22,63,12',
  'markChipsStatus@320@1.3':
      'row=0,0,320,56 leading=16,8,40,40 title=95.9,12.5,14.1,31 opacity=1.00 fill=00000000 mark=68,16,23.9,23.9 chipA=120,20,81,16 status=217,20,81,16',
  'markChipsStatus@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=90.4,16,155.6,24 opacity=1.00 fill=00000000 mark=68,18.8,18.4,18.4 chipA=256,22,63,12 status=335,22,63,12',
  'markChipsStatus@420@1.3':
      'row=0,0,420,56 leading=16,8,40,40 title=95.9,12.5,114.1,31 opacity=1.00 fill=00000000 mark=68,16,23.9,23.9 chipA=220,20,81,16 status=317,20,81,16',
  'markChipsStatus@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=90.4,16,165,24 opacity=1.00 fill=00000000 mark=68,18.8,18.4,18.4 chipA=265.4,22,63,12 status=344.4,22,63,12',
  'markChipsStatus@800@1.3':
      'row=0,0,800,56 leading=16,8,40,40 title=95.9,12.5,213,31 opacity=1.00 fill=00000000 mark=68,16,23.9,23.9 chipA=318.9,20,81,16 status=415.9,20,81,16',
  'lines@320@1.0':
      'row=0,0,320,96 leading=16,28,40,40 title=68,8,165,24 opacity=1.00 fill=00000000 line2=84,34,185.6,16 line2icon=68,35,14,14 glyph=277.6,36,12,12 line3=68,52,124,16 alert=86,72,218,16',
  'lines@320@1.3':
      'row=0,0,320,118 leading=16,39,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 line2=84,41,182,21 line2icon=68,44.5,14,14 glyph=274,45.5,12,12 line3=68,64,160,21 alert=86,89,218,21',
  'lines@420@1.0':
      'row=0,0,420,96 leading=16,28,40,40 title=68,8,165,24 opacity=1.00 fill=00000000 line2=84,34,186,16 line2icon=68,35,14,14 glyph=278,36,12,12 line3=68,52,124,16 alert=86,72,318,16',
  'lines@420@1.3':
      'row=0,0,420,118 leading=16,39,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 line2=84,41,240,21 line2icon=68,44.5,14,14 glyph=332,45.5,12,12 line3=68,64,160,21 alert=86,89,318,21',
  'lines@800@1.0':
      'row=0,0,800,96 leading=16,28,40,40 title=68,8,165,24 opacity=1.00 fill=00000000 line2=84,34,186,16 line2icon=68,35,14,14 glyph=278,36,12,12 line3=68,52,124,16 alert=86,72,698,16',
  'lines@800@1.3':
      'row=0,0,800,118 leading=16,39,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 line2=84,41,240,21 line2icon=68,44.5,14,14 glyph=332,45.5,12,12 line3=68,64,160,21 alert=86,89,698,21',
  'trailing@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=68,16,115.2,24 opacity=1.00 fill=00000000 value=191.2,10,112.8,20 caption=217.2,30,86.8,16',
  'trailing@320@1.3':
      'row=0,0,320,63 leading=16,11.5,40,40 title=68,16,81.6,31 opacity=1.00 fill=00000000 value=157.6,8,146.4,26 caption=192,34,112,21',
  'trailing@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=00000000 value=291.2,10,112.8,20 caption=317.2,30,86.8,16',
  'trailing@420@1.3':
      'row=0,0,420,63 leading=16,11.5,40,40 title=68,16,181.6,31 opacity=1.00 fill=00000000 value=257.6,8,146.4,26 caption=292,34,112,21',
  'trailing@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=00000000 value=671.2,10,112.8,20 caption=697.2,30,86.8,16',
  'trailing@800@1.3':
      'row=0,0,800,63 leading=16,11.5,40,40 title=68,16,213,31 opacity=1.00 fill=00000000 value=637.6,8,146.4,26 caption=672,34,112,21',
  'actions@320@1.0':
      'row=0,0,320,64 leading=16,12,40,40 title=68,20,93.7,24 opacity=1.00 fill=00000000 value=169.7,22,42.3,20 action1=232,20,24,24 action2=276,18,28,28',
  'actions@320@1.3':
      'row=0,0,320,64 leading=16,12,40,40 title=68,16.5,81.1,31 opacity=1.00 fill=00000000 value=157.1,19,54.9,26 action1=232,20,24,24 action2=276,18,28,28',
  'actions@420@1.0':
      'row=0,0,420,64 leading=16,12,40,40 title=68,20,165,24 opacity=1.00 fill=00000000 value=269.7,22,42.3,20 action1=332,20,24,24 action2=376,18,28,28',
  'actions@420@1.3':
      'row=0,0,420,64 leading=16,12,40,40 title=68,16.5,181.1,31 opacity=1.00 fill=00000000 value=257.1,19,54.9,26 action1=332,20,24,24 action2=376,18,28,28',
  'actions@800@1.0':
      'row=0,0,800,64 leading=16,12,40,40 title=68,20,165,24 opacity=1.00 fill=00000000 value=649.7,22,42.3,20 action1=712,20,24,24 action2=756,18,28,28',
  'actions@800@1.3':
      'row=0,0,800,64 leading=16,12,40,40 title=68,16.5,213,31 opacity=1.00 fill=00000000 value=637.1,19,54.9,26 action1=712,20,24,24 action2=756,18,28,28',
  'footer@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=68,11,165,24 opacity=1.00 fill=00000000 value=275.8,13,28.2,20 footer=68,39,236,6 footerPx=FF000000',
  'footer@320@1.3':
      'row=0,0,320,57 leading=16,8.5,40,40 title=68,8,191.4,31 opacity=1.00 fill=00000000 value=267.4,10.5,36.6,26 footer=68,43,236,6 footerPx=FF000000',
  'footer@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=68,11,165,24 opacity=1.00 fill=00000000 value=375.8,13,28.2,20 footer=68,39,336,6 footerPx=FF000000',
  'footer@420@1.3':
      'row=0,0,420,57 leading=16,8.5,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 value=367.4,10.5,36.6,26 footer=68,43,336,6 footerPx=FF000000',
  'footer@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=68,11,165,24 opacity=1.00 fill=00000000 value=755.8,13,28.2,20 footer=68,39,716,6 footerPx=FF000000',
  'footer@800@1.3':
      'row=0,0,800,57 leading=16,8.5,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 value=747.4,10.5,36.6,26 footer=68,43,716,6 footerPx=FF000000',
  'indent@320@1.0':
      'row=0,0,320,56 leading=40,8,40,40 title=92,16,165,24 opacity=1.00 fill=00000000',
  'indent@320@1.3':
      'row=0,0,320,56 leading=40,8,40,40 title=92,12.5,212,31 opacity=1.00 fill=00000000',
  'indent@420@1.0':
      'row=0,0,420,56 leading=40,8,40,40 title=92,16,165,24 opacity=1.00 fill=00000000',
  'indent@420@1.3':
      'row=0,0,420,56 leading=40,8,40,40 title=92,12.5,213,31 opacity=1.00 fill=00000000',
  'indent@800@1.0':
      'row=0,0,800,56 leading=40,8,40,40 title=92,16,165,24 opacity=1.00 fill=00000000',
  'indent@800@1.3':
      'row=0,0,800,56 leading=40,8,40,40 title=92,12.5,213,31 opacity=1.00 fill=00000000',
  'dimmed@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=68,16,165,24 opacity=0.55 fill=00000000 valueOpacity=0.55',
  'dimmed@320@1.3':
      'row=0,0,320,56 leading=16,8,40,40 title=68,12.5,191.4,31 opacity=0.55 fill=00000000 valueOpacity=0.55',
  'dimmed@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=68,16,165,24 opacity=0.55 fill=00000000 valueOpacity=0.55',
  'dimmed@420@1.3':
      'row=0,0,420,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=0.55 fill=00000000 valueOpacity=0.55',
  'dimmed@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=68,16,165,24 opacity=0.55 fill=00000000 valueOpacity=0.55',
  'dimmed@800@1.3':
      'row=0,0,800,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=0.55 fill=00000000 valueOpacity=0.55',
  'highlighted@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=14140B0E',
  'highlighted@320@1.3':
      'row=0,0,320,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=1.00 fill=14140B0E',
  'highlighted@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=14140B0E',
  'highlighted@420@1.3':
      'row=0,0,420,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=1.00 fill=14140B0E',
  'highlighted@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=68,16,165,24 opacity=1.00 fill=14140B0E',
  'highlighted@800@1.3':
      'row=0,0,800,56 leading=16,8,40,40 title=68,12.5,213,31 opacity=1.00 fill=14140B0E',
  'accent@320@1.0':
      'row=0,0,320,56 leading=16,8,40,40 title=68,11,165,24 opacity=1.00 fill=00000000 footer=68,39,236,6 footerPx=FFB28705',
  'accent@320@1.3':
      'row=0,0,320,57 leading=16,8.5,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 footer=68,43,236,6 footerPx=FFB28705',
  'accent@420@1.0':
      'row=0,0,420,56 leading=16,8,40,40 title=68,11,165,24 opacity=1.00 fill=00000000 footer=68,39,336,6 footerPx=FFB28705',
  'accent@420@1.3':
      'row=0,0,420,57 leading=16,8.5,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 footer=68,43,336,6 footerPx=FFB28705',
  'accent@800@1.0':
      'row=0,0,800,56 leading=16,8,40,40 title=68,11,165,24 opacity=1.00 fill=00000000 footer=68,39,716,6 footerPx=FFB28705',
  'accent@800@1.3':
      'row=0,0,800,57 leading=16,8.5,40,40 title=68,8,213,31 opacity=1.00 fill=00000000 footer=68,43,716,6 footerPx=FFB28705',
};
