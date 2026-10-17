import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet (0.4.0, owner 2026-10-13: "every visual widget lives in the kit"):
/// counts, per file in `lib/features` and `lib/app`, the widget classes that
/// lay things out themselves — a non-page `StatelessWidget` / `State` whose
/// body builds Row / Column / Stack / Container / Padding … A page is wiring
/// (template + kit pieces + parameters); anything else that composes layout
/// belongs in `lib/ui` (audit: `ai/inbox/fe-a.md`, "Non-shared widgets audit").
///
/// Counts per file may only go DOWN against `feature_visuals_baseline.txt`
/// (`path<TAB>count`). A file above its baseline (or a new file with any)
/// fails: move the widget into the kit. After removing some, shrink the
/// baseline: `UPDATE_BASELINE=1 flutter test test/ui/feature_visuals_test.dart`.
///
/// Heuristic, on purpose: no analyzer, just text. Pages (`*Page`, `*Sheet`,
/// `*Dialog` and their State classes) are exempt.
void main() {
  test('no new feature-local layout widgets (ratchet)', () {
    final counts = _count();
    final baselineFile = File('test/ui/feature_visuals_baseline.txt');
    if (Platform.environment['UPDATE_BASELINE'] == '1' ||
        !baselineFile.existsSync()) {
      final lines = [for (final e in counts.entries) '${e.key}\t${e.value}']
        ..sort();
      baselineFile.writeAsStringSync('${lines.join('\n')}\n');
    }
    final baseline = <String, int>{};
    for (final line in baselineFile.readAsLinesSync()) {
      final parts = line.split('\t');
      if (parts.length == 2) baseline[parts[0]] = int.parse(parts[1]);
    }
    final over = <String>[];
    final stale = <String>[];
    for (final e in counts.entries) {
      final allowed = baseline[e.key] ?? 0;
      if (e.value > allowed) {
        over.add('${e.key}  layout widgets: ${e.value} (baseline $allowed)');
      } else if (e.value < allowed) {
        stale.add('${e.key}  ${e.value} < baseline $allowed');
      }
    }
    for (final k in baseline.keys) {
      if (!counts.containsKey(k)) stale.add('$k  gone (remove from baseline)');
    }
    expect(
      over,
      isEmpty,
      reason:
          'Feature code lays out widgets itself — move them into lib/ui '
          '(a page = template + kit pieces + parameters):\n${over.join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'Fewer than the baseline — shrink it: '
          'UPDATE_BASELINE=1 flutter test test/ui/feature_visuals_test.dart\n'
          '${stale.join('\n')}',
    );
  });
}

final _layout = RegExp(
  r'\b(Row|Column|Stack|Wrap|Container|Padding|Align|Center|Expanded|Flexible|'
  r'DecoratedBox|ListView|GridView|Positioned)\(',
);
final _classDecl = RegExp(
  r'^(?:abstract\s+)?class\s+(\w+)(?:<[^>]*>)?\s+extends\s+([\w<>?, ]+?)\s*(?:with\b[^{]*)?\{',
  multiLine: true,
);
final _widgetBases = RegExp(
  r'^(StatelessWidget|ConsumerWidget|State<\w+>|ConsumerState<\w+>)$',
);
final _exempt = RegExp(r'(Page|PageState|Sheet|SheetState|Dialog)$');

Map<String, int> _count() {
  final out = <String, int>{};
  for (final root in ['lib/features', 'lib/app']) {
    for (final f in Directory(root).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      final decls = _classDecl.allMatches(src).toList();
      var n = 0;
      for (var i = 0; i < decls.length; i++) {
        final m = decls[i];
        if (!_widgetBases.hasMatch(m.group(2)!.trim())) continue;
        final name = m.group(1)!;
        if (_exempt.hasMatch(name)) continue;
        final end = i + 1 < decls.length ? decls[i + 1].start : src.length;
        if (_layout.hasMatch(src.substring(m.start, end))) n++;
      }
      if (n > 0) out[f.path.replaceAll('\\', '/')] = n;
    }
  }
  return out;
}
