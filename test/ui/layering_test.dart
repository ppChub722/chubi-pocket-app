import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layering of the app hub (owner 2026-10-12):
///
///   lib/ui/{tokens,atoms,molecules,organisms,templates}  generic — the future ppForge core
///   lib/ui/domain                                         the app's own pieces (money, people, icons…)
///   lib/ui/ui.dart                                        THE GATE
///   lib/features/**                                       imports ONLY the gate
///
/// 1. A feature file imports nothing from lib/ui except `ui/ui.dart`.
/// 2. A generic piece imports only other generic pieces, Flutter, intl and
///    google_fonts: no domain, gate, features, core, app shell, l10n, router or
///    bloc. Today's violations are listed in
///    `test/ui/generic_baseline.txt` and can only shrink: a NEW one fails, a
///    fixed one fails until it is removed from the baseline (so the list is
///    always the real debt). Regenerate with `UPDATE_BASELINE=1 flutter test`.
void main() {
  final lib = Directory('lib');

  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  List<String> importsOf(File f) => RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  ).allMatches(f.readAsStringSync()).map((m) => m.group(1)!).toList();

  String norm(String p) => p.replaceAll('\\', '/');

  test('features import only the gate (ui/ui.dart) from lib/ui', () {
    final bad = <String>[];
    for (final f in dartFiles('lib/features')) {
      for (final i in importsOf(f)) {
        final isUi = i.contains('/ui/') || i.startsWith('ui/');
        final isGate = i.endsWith('/ui/ui.dart') || i == 'ui/ui.dart';
        if (isUi && !isGate) bad.add('${norm(f.path)} → $i');
      }
    }
    expect(
      bad,
      isEmpty,
      reason: 'import ui/ui.dart instead:\n${bad.join('\n')}',
    );
  });

  test('generic layers import nothing of the app (ratchet)', () {
    // The generic kit is what moves into the ppForge package: it may import
    // only itself, Flutter and a few pure packages — never lib/ui/domain,
    // the gate, features, core, the app shell, l10n, the router or bloc.
    const generic = ['tokens', 'atoms', 'molecules', 'organisms', 'templates'];
    const allowedPackages = {'flutter', 'intl', 'google_fonts', 'characters'};
    final found = <String>{};
    for (final layer in generic) {
      final dir = Directory('lib/ui/$layer');
      if (!dir.existsSync()) continue;
      for (final f in dartFiles(dir.path)) {
        final from = norm(f.path);
        for (final i in importsOf(f)) {
          if (i.startsWith('dart:')) continue;
          if (i.startsWith('package:')) {
            final pkg = i.substring(8).split('/').first;
            if (allowedPackages.contains(pkg)) continue;
            found.add('$from → $i');
            continue;
          }
          final target = Uri.parse(from).resolve(i).path;
          final inGeneric = generic.any((g) => target.startsWith('lib/ui/$g/'));
          if (!inGeneric) found.add('$from → $i');
        }
      }
    }
    final baselineFile = File('test/ui/generic_baseline.txt');
    if (Platform.environment['UPDATE_BASELINE'] == '1' ||
        !baselineFile.existsSync()) {
      baselineFile.writeAsStringSync(
        '${(found.toList()..sort()).join('\n')}\n',
      );
    }
    final baseline = baselineFile
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toSet();
    expect(
      found.difference(baseline),
      isEmpty,
      reason:
          'new layering violation(s) — generic widgets take strings / data as parameters',
    );
    expect(
      baseline.difference(found),
      isEmpty,
      reason:
          'fixed — remove from test/ui/generic_baseline.txt (UPDATE_BASELINE=1)',
    );
    expect(lib.existsSync(), isTrue);
  });
}
