import 'dart:io';

import 'package:chubi_pocket/hub/hub_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// A piece is shown on ONE hub page (owner 2026-10-12: "no duplicates — the
/// same thing shown twice"). A piece listed in the `covers` of two pages is a
/// duplicate; the ones still to resolve are the debt in
/// `test/ui/hub_duplicates_baseline.txt` — it can only shrink.
/// Regenerate: `UPDATE_BASELINE=1 flutter test test/ui`.
void main() {
  test('no piece is covered by two hub pages (ratchet)', () {
    final where = <String, List<String>>{};
    for (final p in hubPages) {
      for (final c in p.covers) {
        (where[c] ??= []).add(p.id);
      }
    }
    final dups = [
      for (final e in where.entries)
        if (e.value.length > 1) '${e.key}: ${e.value.join(' , ')}',
    ]..sort();

    final file = File('test/ui/hub_duplicates_baseline.txt');
    if (Platform.environment['UPDATE_BASELINE'] == '1' || !file.existsSync()) {
      file.writeAsStringSync('${dups.join('\n')}\n');
    }
    final known = file
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toSet();
    expect(
      dups.toSet().difference(known),
      isEmpty,
      reason: 'a piece is on two hub pages — keep it on one',
    );
    expect(
      known.difference(dups.toSet()),
      isEmpty,
      reason: 'resolved — remove from the baseline (UPDATE_BASELINE=1)',
    );
  });
}
