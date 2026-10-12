import 'dart:io';

import 'package:chubi_pocket/hub/hub_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// "The hub is the single source of truth": every public piece the gate
/// (`lib/ui/ui.dart`) exports must be listed in some hub page's `covers`.
/// Pieces not on a page yet are the debt in `test/ui/hub_uncovered_baseline.txt`
/// — it can only shrink (a new uncovered piece fails; a newly covered one fails
/// until it is removed from the file). Regenerate: `UPDATE_BASELINE=1 flutter test`.
void main() {
  test('every piece the gate exports is on a hub page (ratchet)', () {
    final pieces = <String>{};
    final decl = RegExp(
      r'^(?:(?:abstract|sealed|final|base|interface|mixin)\s+)*(?:class|enum|mixin|extension type)\s+([A-Z]\w*)|^extension\s+([A-Z]\w*)\s+on|^typedef\s+([A-Z]\w*)',
      multiLine: true,
    );
    final fn = RegExp(
      r'^(?:void|bool|int|double|String|Future<[^\n]*?>|[A-Z]\w*(?:<[^>\n]*>)?\??)\s+([a-z]\w*)(?:<[^>\n]*>)?\(',
      multiLine: true,
    );
    final exportRe = RegExp(r'''^export\s+['"]([^'"]+)['"]''', multiLine: true);
    // The gate and, recursively, every file it re-exports (barrels).
    final seen = <String>{};
    void visit(String path) {
      if (!seen.add(path)) return;
      final src = File(path).readAsStringSync();
      for (final m in decl.allMatches(src)) {
        pieces.add(m.group(1) ?? m.group(2) ?? m.group(3)!);
      }
      for (final m in fn.allMatches(src)) {
        pieces.add(m.group(1)!);
      }
      final dir = path.substring(0, path.lastIndexOf('/'));
      for (final m in exportRe.allMatches(src)) {
        final rel = m.group(1)!;
        if (rel.startsWith('package:') || rel.startsWith('dart:')) continue;
        visit(Uri.parse('$dir/').resolve(rel).path);
      }
    }

    visit('lib/ui/ui.dart');

    final covered = {for (final p in hubPages) ...p.covers};
    final uncovered = (pieces.difference(covered)).toList()..sort();

    final baselineFile = File('test/ui/hub_uncovered_baseline.txt');
    if (Platform.environment['UPDATE_BASELINE'] == '1' ||
        !baselineFile.existsSync()) {
      baselineFile.writeAsStringSync('${uncovered.join('\n')}\n');
    }
    final baseline = baselineFile
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toSet();
    expect(
      uncovered.toSet().difference(baseline),
      isEmpty,
      reason: 'new piece(s) with no hub page — add to a page’s `covers`',
    );
    expect(
      baseline.difference(uncovered.toSet()),
      isEmpty,
      reason: 'now covered — remove from the baseline (UPDATE_BASELINE=1)',
    );
    // Every `covers` entry must be a real piece (no typos).
    expect(
      covered.difference(pieces),
      isEmpty,
      reason: 'hub page lists a piece the gate does not export',
    );
  });
}
