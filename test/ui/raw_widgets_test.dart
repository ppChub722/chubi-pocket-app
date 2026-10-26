import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet: `lib/features` uses the kit, not raw Material / hand-made styles;
/// `lib/ui` + `lib/app` use no raw Material buttons.
/// Counts per (file, pattern) may only go DOWN against
/// `raw_widgets_baseline.txt`. Fix a hit or, for a real exception, lower
/// nothing — ask Lead. After removing hits, shrink the baseline:
/// `UPDATE_BASELINE=1 fvm flutter test test/ui/raw_widgets_test.dart`.
void main() {
  const widgets = [
    'TextField',
    'TextFormField',
    'Card',
    'Switch',
    'Divider',
    'IconButton',
    'CircularProgressIndicator',
    'LinearProgressIndicator',
    'ElevatedButton',
    'OutlinedButton',
    'TextButton',
    'FilledButton',
    'ListTile',
    'SnackBar',
    'AlertDialog',
    'Chip',
    'ActionChip',
    'FilterChip',
    'ChoiceChip',
    'Checkbox',
    'Radio',
    'BoxDecoration',
    'TextStyle',
  ];
  final patterns = <String, RegExp>{
    for (final w in widgets)
      w: RegExp(
        '(?<![A-Za-z0-9_.])$w'
        r'\(',
      ),
    'showDatePicker': RegExp(r'\bshowDatePicker\('),
    'showTimePicker': RegExp(r'\bshowTimePicker\('),
    'Color(0x': RegExp(r'\bColor\(0x'),
    'Colors.': RegExp(r'(?<![A-Za-z0-9_])Colors\.'),
    'fontSize:': RegExp(r'\bfontSize:'),
  };
  final baselineFile = File('test/ui/raw_widgets_baseline.txt');
  // Real exceptions: `path|pattern|reason` per line — never counted.
  final allowFile = File('test/ui/raw_widgets_allow.txt');
  final allowed = {
    if (allowFile.existsSync())
      for (final l in allowFile.readAsLinesSync())
        if (l.trim().isNotEmpty && !l.startsWith('#'))
          l.split('|').take(2).join('|'),
  };

  // The kit and the shell build on raw Material, but a button is always
  // AppButton / AppIconButton, the only files that wrap Material's.
  const buttons = [
    'TextButton',
    'FilledButton',
    'OutlinedButton',
    'ElevatedButton',
    'IconButton',
    'FloatingActionButton',
  ];
  final buttonPatterns = <String, RegExp>{
    for (final w in buttons)
      w: RegExp(
        '(?<![A-Za-z0-9_.])$w'
        r'(\.[a-z]+)?\(',
      ),
  };
  const buttonOwners = {
    'lib/ui/atoms/app_button.dart',
    'lib/ui/atoms/app_icon_button.dart',
  };

  void scanDir(
    String dir,
    Map<String, RegExp> patterns,
    Map<String, int> out, {
    Set<String> skip = const {},
  }) {
    for (final f in Directory(dir).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart')) {
        continue;
      }
      final path = f.path.replaceAll(r'\', '/');
      if (skip.contains(path)) continue;
      for (final line in f.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final e in patterns.entries) {
          final n = e.value.allMatches(line).length;
          if (n > 0 && !allowed.contains('$path|${e.key}')) {
            out['$path|${e.key}'] = (out['$path|${e.key}'] ?? 0) + n;
          }
        }
      }
    }
  }

  Map<String, int> scan() {
    final out = <String, int>{};
    scanDir('lib/features', patterns, out);
    for (final dir in ['lib/ui', 'lib/app']) {
      scanDir(dir, buttonPatterns, out, skip: buttonOwners);
    }
    return out;
  }

  test('no new raw widgets in lib/features, no raw buttons in lib/ui + '
      'lib/app', () {
    final now = scan();
    if (Platform.environment['UPDATE_BASELINE'] == '1') {
      final keys = now.keys.toList()..sort();
      baselineFile.writeAsStringSync(
        '${[for (final k in keys) '$k|${now[k]}'].join('\n')}\n',
      );
      return;
    }
    final base = <String, int>{};
    for (final l in baselineFile.readAsLinesSync()) {
      if (l.trim().isEmpty) continue;
      final i = l.lastIndexOf('|');
      base[l.substring(0, i)] = int.parse(l.substring(i + 1));
    }
    final grew = [
      for (final e in now.entries)
        if (e.value > (base[e.key] ?? 0))
          '${e.key.replaceFirst('|', '  ')}: ${e.value} (baseline ${base[e.key] ?? 0})',
    ]..sort();
    expect(
      grew,
      isEmpty,
      reason:
          'Raw widgets / hand-made styles added in lib/features — use the '
          'kit (lib/ui/ui.dart) instead:\n${grew.join('\n')}',
    );
  });
}
