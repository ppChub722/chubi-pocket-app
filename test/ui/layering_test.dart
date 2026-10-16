import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layering of the app hub (owner 2026-10-12):
///
///   ../pp-forge (package:pp_forge)                        generic — the ppForge kit
///   lib/ui/domain                                         the app's own pieces (money, people, icons…)
///   lib/ui/ui.dart                                        THE GATE
///   lib/features/**                                       imports ONLY the gate
///
/// 1. A feature file imports nothing from lib/ui except `ui/ui.dart`.
/// 2. Generic pieces live in ppForge, which imports no app code (nor
///    go_router / flutter_bloc); lib/ui keeps only the gate, the App*
///    aliases and lib/ui/domain. Features reach ppForge through the gate.
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

  test('the kit lives in ppForge, not in lib/ui', () {
    const generic = [
      'tokens',
      'atoms',
      'molecules',
      'organisms',
      'templates',
      'icons',
    ];
    final back = [
      for (final layer in generic)
        if (Directory('lib/ui/$layer').existsSync()) 'lib/ui/$layer',
    ];
    expect(
      back,
      isEmpty,
      reason:
          'generic pieces belong in ../pp-forge/lib/src; app pieces in '
          'lib/ui/domain:\n${back.join('\n')}',
    );
  });

  test('ppForge stands alone — no app code, no app stack', () {
    const banned = [
      'package:chubi_pocket/',
      'package:flutter_bloc/',
      'package:go_router/',
    ];
    final bad = <String>[];
    for (final f in dartFiles('../pp-forge/lib')) {
      for (final i in importsOf(f)) {
        if (banned.any(i.startsWith)) bad.add('${norm(f.path)} → $i');
      }
    }
    expect(
      bad,
      isEmpty,
      reason:
          'the kit takes strings / data / behaviour as parameters or scopes '
          '(PpForgeConfig, PageExitScope):\n${bad.join('\n')}',
    );
    expect(lib.existsSync(), isTrue);
  });

  test('features reach ppForge through the gate', () {
    final bad = [
      for (final f in dartFiles('lib/features'))
        for (final i in importsOf(f))
          if (i.startsWith('package:pp_forge/')) '${norm(f.path)} → $i',
    ];
    expect(
      bad,
      isEmpty,
      reason: 'import ui/ui.dart instead:\n${bad.join('\n')}',
    );
  });
}
