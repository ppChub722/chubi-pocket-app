import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layering of the app hub (owner 2026-10-12):
///
///   lib/ui/{tokens,atoms,molecules,organisms,templates,icons}  generic — the future ppForge core
///   lib/ui/domain                                         the app's own pieces (money, people, icons…)
///   lib/ui/ui.dart                                        THE GATE
///   lib/features/**                                       imports ONLY the gate
///
/// 1. A feature file imports nothing from lib/ui except `ui/ui.dart`.
/// 2. A generic piece imports only the generic layers (plus Flutter and
///    neutral packages) — no core, features, app, l10n, hub, ui/domain,
///    go_router or flutter_bloc. It is what moves into the ppForge package.
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

  /// [import] as a path under lib/ (`ui/atoms/x.dart`), or null for a
  /// `dart:` / third-party package import.
  String? libPathOf(File from, String import) {
    if (import.startsWith('package:chubi_pocket/')) {
      return import.substring('package:chubi_pocket/'.length);
    }
    if (import.contains(':')) return null;
    final parts = norm(from.parent.path).split('/');
    for (final s in import.split('/')) {
      if (s == '..') {
        parts.removeLast();
      } else if (s != '.') {
        parts.add(s);
      }
    }
    final at = parts.indexOf('lib');
    return parts.skip(at + 1).join('/');
  }

  test('generic layers stand alone — the future ppForge package', () {
    const generic = [
      'tokens',
      'atoms',
      'molecules',
      'organisms',
      'templates',
      'icons',
    ];
    // Inside lib/, a generic piece may reach only the generic layers.
    const allowed = [
      'ui/tokens/',
      'ui/atoms/',
      'ui/molecules/',
      'ui/organisms/',
      'ui/templates/',
      'ui/icons/',
    ];
    // The app's own stack — never in the kit.
    const bannedPackages = ['package:flutter_bloc/', 'package:go_router/'];
    final bad = <String>[];
    for (final layer in generic) {
      final dir = Directory('lib/ui/$layer');
      if (!dir.existsSync()) continue;
      for (final f in dartFiles(dir.path)) {
        for (final i in importsOf(f)) {
          final target = libPathOf(f, i);
          final leaves = target != null && !allowed.any(target.startsWith);
          if (leaves || bannedPackages.any(i.startsWith)) {
            bad.add('${norm(f.path)} → ${target ?? i}');
          }
        }
      }
    }
    expect(
      bad,
      isEmpty,
      reason:
          'generic widgets take strings / data / behaviour as parameters or '
          'scopes (PpForgeConfig, PageExitScope); app pieces live in ui/domain:\n'
          '${bad.join('\n')}',
    );
    expect(lib.existsSync(), isTrue);
  });
}
