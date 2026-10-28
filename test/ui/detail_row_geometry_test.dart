import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// AppRow plan step 0: the detail row's geometry, fill and opacity inside a
/// SectionCard, recorded at app main `8e28650` (before DetailRow moved onto
/// AppRow and became AppDetailRow). The rebuild must keep every value. One
/// meant change since: step 3b (owner 2026-10-28) turned detail values
/// primary, so `valueColor` went from FF2B1A21 (onSurface) to FFFF8FB1
/// (primary); a locked value is muted (onSurfaceVariant, FF6B5258) and the
/// empty placeholder keeps its own muted colour.
void main() {
  const rowKey = Key('row');
  const valueKey = Key('value');
  const leadingKey = Key('leading');
  final row = find.byKey(rowKey);
  final label = find.text('Label');
  void noop() {}

  Widget card(List<Widget> rows) => SectionCard(first: true, children: rows);

  Future<void> base(WidgetTester t, GeometrySnap s) async {
    s.rect('row', row);
    s.rect('label', label);
    s.opacity('opacity', label);
    s.textColor('labelColor', label);
    final r = t.getRect(row);
    await s.pixel('fill', Offset(r.left + 3, r.center.dy));
  }

  Future<void> withValue(WidgetTester t, GeometrySnap s) async {
    await base(t, s);
    s.rect('value', find.byKey(valueKey));
    s.textColor('valueColor', find.byKey(valueKey));
  }

  const value = Text('Value', key: valueKey);

  final cases = <String, GeometryCase>{
    'value': (
      build: () => card([
        const AppDetailRow(key: rowKey, label: 'Label', trailing: value),
      ]),
      measure: withValue,
    ),
    'icon': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          icon: AppIcons.info,
          label: 'Label',
          trailing: value,
        ),
      ]),
      measure: (t, s) async {
        await withValue(t, s);
        s.rect('icon', find.byIcon(AppIcons.info));
      },
    ),
    'leading': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          leading: AppIcon(AppIcons.archive, key: leadingKey),
          label: 'Label',
          trailing: value,
        ),
      ]),
      measure: (t, s) async {
        await withValue(t, s);
        s.rect('icon', find.byKey(leadingKey));
      },
    ),
    'emptySlot': (
      build: () => card([
        const AppDetailRow(icon: AppIcons.info, label: 'First'),
        const AppDetailRow(key: rowKey, label: 'Label', trailing: value),
      ]),
      measure: withValue,
    ),
    'lock': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          label: 'Label',
          trailing: value,
          locked: true,
        ),
      ]),
      measure: (t, s) async {
        await withValue(t, s);
        s.rect('lock', find.byIcon(AppIcons.lock));
      },
    ),
    'chevron': (
      build: () => card([
        AppDetailRow(
          key: rowKey,
          label: 'Label',
          trailing: value,
          showChevron: true,
          onTap: noop,
        ),
      ]),
      measure: (t, s) async {
        await withValue(t, s);
        s.rect('chevron', find.byIcon(AppIcons.chevronRight));
      },
    ),
    'pick': (
      build: () => card([
        AppDetailRow.pick(
          key: rowKey,
          label: 'Label',
          emptyText: 'Pick one',
          onTap: noop,
        ),
      ]),
      measure: (t, s) async {
        await base(t, s);
        s.rect('value', find.text('Pick one'));
        s.textColor('valueColor', find.text('Pick one'));
        s.rect('chevron', find.byIcon(AppIcons.chevronRight));
      },
    ),
    'helper': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          icon: AppIcons.info,
          label: 'Label',
          helper: 'Helper text under the label that is long enough to wrap',
          trailing: value,
        ),
      ]),
      measure: (t, s) async {
        await withValue(t, s);
        s.rect(
          'helper',
          find.text('Helper text under the label that is long enough to wrap'),
        );
      },
    ),
    'helperOneLine': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          label: 'Label',
          helper: 'Helper text under the label that is long enough to wrap',
          helperMaxLines: 1,
        ),
      ]),
      measure: (t, s) async {
        await base(t, s);
        s.rect(
          'helper',
          find.text('Helper text under the label that is long enough to wrap'),
        );
      },
    ),
    'error': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          label: 'Label',
          error: 'Error text',
          trailing: value,
        ),
      ]),
      measure: (t, s) async {
        await withValue(t, s);
        s.rect('error', find.text('Error text'));
        s.textColor('errorColor', find.text('Error text'));
      },
    ),
    'longValue': (
      build: () => card([
        const AppDetailRow(
          key: rowKey,
          icon: AppIcons.info,
          label: 'Label',
          trailing: Text(
            'A very long value that keeps going and going and going',
            key: valueKey,
          ),
        ),
      ]),
      measure: withValue,
    ),
  };

  geometryMatrix(cases, _expected);
}

const _expected = <String, String>{
  'value@320@1.0':
      'row=0,0,320,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=221.5,12,82.5,24 valueColor=FFFF8FB1',
  'value@320@1.3':
      'row=0,0,320,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=197.5,12,106.5,31 valueColor=FFFF8FB1',
  'value@420@1.0':
      'row=0,0,420,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=321.5,12,82.5,24 valueColor=FFFF8FB1',
  'value@420@1.3':
      'row=0,0,420,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=297.5,12,106.5,31 valueColor=FFFF8FB1',
  'value@800@1.0':
      'row=0,0,800,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=701.5,12,82.5,24 valueColor=FFFF8FB1',
  'value@800@1.3':
      'row=0,0,800,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=677.5,12,106.5,31 valueColor=FFFF8FB1',
  'icon@320@1.0':
      'row=0,0,320,48 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=221.5,12,82.5,24 valueColor=FFFF8FB1 icon=16,13,22,22',
  'icon@320@1.3':
      'row=0,0,320,55 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=197.5,12,106.5,31 valueColor=FFFF8FB1 icon=16,16.5,22,22',
  'icon@420@1.0':
      'row=0,0,420,48 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=321.5,12,82.5,24 valueColor=FFFF8FB1 icon=16,13,22,22',
  'icon@420@1.3':
      'row=0,0,420,55 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=297.5,12,106.5,31 valueColor=FFFF8FB1 icon=16,16.5,22,22',
  'icon@800@1.0':
      'row=0,0,800,48 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=701.5,12,82.5,24 valueColor=FFFF8FB1 icon=16,13,22,22',
  'icon@800@1.3':
      'row=0,0,800,55 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=677.5,12,106.5,31 valueColor=FFFF8FB1 icon=16,16.5,22,22',
  'leading@320@1.0':
      'row=0,0,320,48 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=221.5,12,82.5,24 valueColor=FFFF8FB1 icon=16,13,22,22',
  'leading@320@1.3':
      'row=0,0,320,55 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=197.5,12,106.5,31 valueColor=FFFF8FB1 icon=16,16.5,22,22',
  'leading@420@1.0':
      'row=0,0,420,48 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=321.5,12,82.5,24 valueColor=FFFF8FB1 icon=16,13,22,22',
  'leading@420@1.3':
      'row=0,0,420,55 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=297.5,12,106.5,31 valueColor=FFFF8FB1 icon=16,16.5,22,22',
  'leading@800@1.0':
      'row=0,0,800,48 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=701.5,12,82.5,24 valueColor=FFFF8FB1 icon=16,13,22,22',
  'leading@800@1.3':
      'row=0,0,800,55 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=677.5,12,106.5,31 valueColor=FFFF8FB1 icon=16,16.5,22,22',
  'emptySlot@320@1.0':
      'row=0,50,320,48 label=50,62,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=221.5,62,82.5,24 valueColor=FFFF8FB1',
  'emptySlot@320@1.3':
      'row=0,57,320,55 label=50,69,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=197.5,69,106.5,31 valueColor=FFFF8FB1',
  'emptySlot@420@1.0':
      'row=0,50,420,48 label=50,62,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=321.5,62,82.5,24 valueColor=FFFF8FB1',
  'emptySlot@420@1.3':
      'row=0,57,420,55 label=50,69,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=297.5,69,106.5,31 valueColor=FFFF8FB1',
  'emptySlot@800@1.0':
      'row=0,50,800,48 label=50,62,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=701.5,62,82.5,24 valueColor=FFFF8FB1',
  'emptySlot@800@1.3':
      'row=0,57,800,55 label=50,69,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=677.5,69,106.5,31 valueColor=FFFF8FB1',
  'lock@320@1.0':
      'row=0,0,320,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=201.5,12,82.5,24 valueColor=FF6B5258 lock=288,16,16,16',
  'lock@320@1.3':
      'row=0,0,320,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=177.5,12,106.5,31 valueColor=FF6B5258 lock=288,19.5,16,16',
  'lock@420@1.0':
      'row=0,0,420,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=301.5,12,82.5,24 valueColor=FF6B5258 lock=388,16,16,16',
  'lock@420@1.3':
      'row=0,0,420,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=277.5,12,106.5,31 valueColor=FF6B5258 lock=388,19.5,16,16',
  'lock@800@1.0':
      'row=0,0,800,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=681.5,12,82.5,24 valueColor=FF6B5258 lock=768,16,16,16',
  'lock@800@1.3':
      'row=0,0,800,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=657.5,12,106.5,31 valueColor=FF6B5258 lock=768,19.5,16,16',
  'chevron@320@1.0':
      'row=0,0,320,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=193.5,12,82.5,24 valueColor=FFFF8FB1 chevron=280,12,24,24',
  'chevron@320@1.3':
      'row=0,0,320,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=169.5,12,106.5,31 valueColor=FFFF8FB1 chevron=280,15.5,24,24',
  'chevron@420@1.0':
      'row=0,0,420,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=293.5,12,82.5,24 valueColor=FFFF8FB1 chevron=380,12,24,24',
  'chevron@420@1.3':
      'row=0,0,420,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=269.5,12,106.5,31 valueColor=FFFF8FB1 chevron=380,15.5,24,24',
  'chevron@800@1.0':
      'row=0,0,800,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=673.5,12,82.5,24 valueColor=FFFF8FB1 chevron=760,12,24,24',
  'chevron@800@1.3':
      'row=0,0,800,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=649.5,12,106.5,31 valueColor=FFFF8FB1 chevron=760,15.5,24,24',
  'pick@320@1.0':
      'row=0,0,320,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=144,12,132,24 valueColor=996B5258 chevron=280,12,24,24',
  'pick@320@1.3':
      'row=0,0,320,86 label=16,12,104,62 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=132,27.5,144,31 valueColor=996B5258 chevron=280,31,24,24',
  'pick@420@1.0':
      'row=0,0,420,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=244,12,132,24 valueColor=996B5258 chevron=380,12,24,24',
  'pick@420@1.3':
      'row=0,0,420,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=205.6,12,170.4,31 valueColor=996B5258 chevron=380,15.5,24,24',
  'pick@800@1.0':
      'row=0,0,800,48 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=624,12,132,24 valueColor=996B5258 chevron=760,12,24,24',
  'pick@800@1.3':
      'row=0,0,800,55 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=585.6,12,170.4,31 valueColor=996B5258 chevron=760,15.5,24,24',
  'helper@320@1.0':
      'row=0,0,320,148 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=221.5,62,82.5,24 valueColor=FFFF8FB1 helper=50,40,159.5,96',
  'helper@320@1.3':
      'row=0,0,320,248 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=197.5,108.5,106.5,31 valueColor=FFFF8FB1 helper=50,47,135.5,189',
  'helper@420@1.0':
      'row=0,0,420,100 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=321.5,38,82.5,24 valueColor=FFFF8FB1 helper=50,40,259.5,48',
  'helper@420@1.3':
      'row=0,0,420,164 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=297.5,66.5,106.5,31 valueColor=FFFF8FB1 helper=50,47,235.5,105',
  'helper@800@1.0':
      'row=0,0,800,84 label=50,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=701.5,30,82.5,24 valueColor=FFFF8FB1 helper=50,40,639.5,32',
  'helper@800@1.3':
      'row=0,0,800,101 label=50,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=677.5,35,106.5,31 valueColor=FFFF8FB1 helper=50,47,615.5,42',
  'helperOneLine@320@1.0':
      'row=0,0,320,68 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF helper=16,40,288,16',
  'helperOneLine@320@1.3':
      'row=0,0,320,80 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF helper=16,47,288,21',
  'helperOneLine@420@1.0':
      'row=0,0,420,68 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF helper=16,40,388,16',
  'helperOneLine@420@1.3':
      'row=0,0,420,80 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF helper=16,47,388,21',
  'helperOneLine@800@1.0':
      'row=0,0,800,68 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF helper=16,40,682,16',
  'helperOneLine@800@1.3':
      'row=0,0,800,80 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF helper=16,47,768,21',
  'error@320@1.0':
      'row=0,0,320,68 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=221.5,22,82.5,24 valueColor=FFFF8FB1 error=16,40,124,16 errorColor=FFE11D63',
  'error@320@1.3':
      'row=0,0,320,80 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=197.5,24.5,106.5,31 valueColor=FFFF8FB1 error=16,47,160,21 errorColor=FFE11D63',
  'error@420@1.0':
      'row=0,0,420,68 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=321.5,22,82.5,24 valueColor=FFFF8FB1 error=16,40,124,16 errorColor=FFE11D63',
  'error@420@1.3':
      'row=0,0,420,80 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=297.5,24.5,106.5,31 valueColor=FFFF8FB1 error=16,47,160,21 errorColor=FFE11D63',
  'error@800@1.0':
      'row=0,0,800,68 label=16,12,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=701.5,22,82.5,24 valueColor=FFFF8FB1 error=16,40,124,16 errorColor=FFE11D63',
  'error@800@1.3':
      'row=0,0,800,80 label=16,12,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=677.5,24.5,106.5,31 valueColor=FFFF8FB1 error=16,47,160,21 errorColor=FFE11D63',
  'longValue@320@1.0':
      'row=0,0,320,264 label=50,120,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=160,12,144,240 valueColor=FFFF8FB1',
  'longValue@320@1.3':
      'row=0,0,320,334 label=50,136,98,62 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=160,12,144,310 valueColor=FFFF8FB1',
  'longValue@420@1.0':
      'row=0,0,420,144 label=50,60,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=210,12,194,120 valueColor=FFFF8FB1',
  'longValue@420@1.3':
      'row=0,0,420,272 label=50,120.5,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=210,12,194,248 valueColor=FFFF8FB1',
  'longValue@800@1.0':
      'row=0,0,800,96 label=50,36,80.8,24 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=400,12,384,72 valueColor=FFFF8FB1',
  'longValue@800@1.3':
      'row=0,0,800,148 label=50,58.5,104.8,31 opacity=1.00 labelColor=FF2B1A21 fill=FFFFFFFF value=400,12,384,124 valueColor=FFFF8FB1',
};
