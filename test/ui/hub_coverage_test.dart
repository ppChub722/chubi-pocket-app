import 'dart:convert';
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
    // pp_forge_core's own pieces: real names for the typo check only (the
    // package's hub test covers them).
    final kitPieces = <String>{};
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
    final seen = <Uri>{};
    void visit(Uri file, Set<String> into) {
      if (!seen.add(file)) return;
      // The App* / Ui* names of pp_forge_core pieces: not pieces of their
      // own (the package's hub covers the real ones).
      if (file.path.endsWith('/app_aliases.dart')) return;
      final src = File.fromUri(file).readAsStringSync();
      for (final m in decl.allMatches(src)) {
        into.add(m.group(1) ?? m.group(2) ?? m.group(3)!);
      }
      for (final m in fn.allMatches(src)) {
        into.add(m.group(1)!);
      }
      for (final m in exportRe.allMatches(src)) {
        final rel = m.group(1)!;
        if (rel.startsWith('package:') || rel.startsWith('dart:')) continue;
        visit(file.resolve(rel), into);
      }
    }

    visit(Directory.current.uri.resolve('lib/ui/ui.dart'), pieces);
    // pp_forge_core's gate, wherever pub put it (path or git dependency).
    final config = Directory.current.uri.resolve(
      '.dart_tool/package_config.json',
    );
    final kit =
        ((jsonDecode(File.fromUri(config).readAsStringSync())
                    as Map)['packages']
                as List)
            .cast<Map>()
            .firstWhere((p) => p['name'] == 'pp_forge_core');
    final kitRoot = config.resolve('${kit['rootUri']}/');
    visit(
      kitRoot.resolve('${kit['packageUri']}').resolve('ui.dart'),
      kitPieces,
    );

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
    // Every `covers` entry of the app's pages must be a real piece (no
    // typos); the kit pages' entries are the package's own test.
    expect(
      {
        for (final p in appHubPages) ...p.covers,
      }.difference({...pieces, ...kitPieces}),
      isEmpty,
      reason: 'hub page lists a piece the gate does not export',
    );
  });
}
