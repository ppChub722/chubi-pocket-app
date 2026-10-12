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
/// 2. A generic piece must not import features, the localisation strings or
///    the network layer. Today's violations are listed in
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

  test('generic layers do not import features / l10n / network (ratchet)', () {
    const generic = ['tokens', 'atoms', 'molecules', 'organisms', 'templates'];
    final found = <String>{};
    for (final layer in generic) {
      final dir = Directory('lib/ui/$layer');
      if (!dir.existsSync()) continue;
      for (final f in dartFiles(dir.path)) {
        // tokens/app = the app's own values (themes, money colours, Thai
        // currency names) — not part of the generic core.
        if (norm(f.path).contains('/tokens/app/')) continue;
        for (final i in importsOf(f)) {
          final n = norm(i);
          if (n.contains('/features/') ||
              n.contains('l10n/gen/app_localizations') ||
              n.contains('/core/network/')) {
            found.add(
              '${norm(f.path)} → ${n.split('/').skip(n.contains('package:') ? 0 : 0).where((s) => s != '..' && s != '.').join('/')}',
            );
          }
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
