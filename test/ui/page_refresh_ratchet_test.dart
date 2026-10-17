import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet (owner 2026-10-17, ground rule 7): every page re-runs its ONE page
/// call on pull AND whenever it is shown again (tab switch / page popped) —
/// built once in `PullToRefresh`, fed by the template's `onRefresh`. So a page
/// that builds a detail / dashboard template without `onRefresh:` has neither.
///
/// Counts per file may only go DOWN against `page_refresh_baseline.txt`
/// (`path<TAB>count`; a create-mode page passes `onRefresh: null` on purpose
/// and is fine — it still names the parameter). Regenerate after fixing:
/// `UPDATE_BASELINE=1 flutter test test/ui/page_refresh_ratchet_test.dart`.
/// (`ListPageBody` has a required `onRetry`, which is its refresh.)
void main() {
  test('every detail / dashboard page wires onRefresh (ratchet)', () {
    final counts = <String, int>{};
    final call = RegExp(
      r'\b(DetailPageBody|DetailLayout|DashboardPageBody|TabbedDetailBody)\(',
    );
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      var missing = 0;
      for (final m in call.allMatches(src)) {
        // Skip a declaration (`class X extends`, `const DetailLayout({`).
        final before = src.substring(0, m.start).trimRight();
        if (before.endsWith('extends') || before.endsWith('class')) continue;
        final body = _balanced(src, m.end - 1);
        if (body == null || body.contains('onRefresh')) continue;
        missing++;
      }
      if (missing > 0) counts[f.path.replaceAll('\\', '/')] = missing;
    }

    final baselineFile = File('test/ui/page_refresh_baseline.txt');
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
        over.add('${e.key}  without onRefresh: ${e.value} (baseline $allowed)');
      } else if (e.value < allowed) {
        stale.add('${e.key}  ${e.value} < baseline $allowed');
      }
    }
    for (final k in baseline.keys) {
      if (!counts.containsKey(k)) stale.add('$k  fixed (remove from baseline)');
    }
    expect(
      over,
      isEmpty,
      reason:
          'A page template without onRefresh has no pull-to-refresh and no '
          'refresh-on-show — pass the page\'s one load call:\n${over.join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'Fewer than the baseline — shrink it: UPDATE_BASELINE=1 flutter '
          'test test/ui/page_refresh_ratchet_test.dart\n${stale.join('\n')}',
    );
  });
}

/// The text between the `(` at [open] and its matching `)`, or null.
String? _balanced(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return s.substring(open, i + 1);
    }
  }
  return null;
}
