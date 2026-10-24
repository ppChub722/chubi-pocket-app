import 'dart:io';

import 'package:chubi_pocket/hub/api/openapi_model.dart';
import 'package:chubi_pocket/hub/api/page_flows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Keeps the page-flow registry honest (lib/hub/api/page_flows.dart):
///  - every operationId a flow names exists in the BE spec;
///  - every endpoint the app calls is in some flow — the ones that are not are
///    the debt in `test/hub/api_flows_baseline.txt`, which can only shrink.
///    Regenerate: `UPDATE_BASELINE=1 flutter test test/hub`.
///
/// Skipped when the BE checkout isn't next to the app.
void main() {
  final file = File('../chubi-pocket-be/internal/apidoc/openapi.yaml');

  Object? plain(Object? v) => v is YamlMap
      ? {for (final e in v.entries) '${e.key}': plain(e.value)}
      : v is YamlList
      ? [for (final e in v) plain(e)]
      : v;

  String key(String method, String path) {
    final p = path
        .replaceAll(RegExp(r'\{[^}]*\}'), '{}')
        .replaceAll(RegExp(r'/+'), '/');
    return '${method.toUpperCase()} ${p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p}';
  }

  /// Every `dio.get/post/put/patch/delete('/path')` in lib/ (not the hub).
  Set<String> appCalls() {
    final re = RegExp(
      r'''dio\s*\.\s*(get|post|put|patch|delete)\s*(?:<(?:[^<>]|<(?:[^<>]|<[^<>]*>)*>)*>)?\s*\(\s*(?:'([^']+)'|"([^"]+)")''',
    );
    final out = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.replaceAll('\\', '/').startsWith('lib/hub/')) continue;
      for (final m in re.allMatches(f.readAsStringSync())) {
        final path = (m.group(2) ?? m.group(3))!.replaceAll(
          RegExp(r'\$\{[^}]*\}|\$\w+'),
          '{}',
        );
        out.add(key(m.group(1)!, path));
      }
    }
    return out;
  }

  late ApiDoc doc;
  setUpAll(() {
    final json = plain(loadYaml(file.readAsStringSync()))! as Map;
    doc = ApiDoc.parse(json.cast<String, dynamic>());
  });

  final skip = file.existsSync() ? false : 'BE checkout not found';

  test('every operationId in a flow exists in the spec', () {
    final ids = {for (final e in doc.endpoints) e.operationId};
    final missing = <String>[
      for (final f in pageFlows)
        for (final s in f.steps)
          for (final c in s.calls)
            if (c.inSpec && !ids.contains(c.operationId))
              '${f.page}: ${c.operationId}',
    ];
    expect(missing, isEmpty, reason: 'unknown operationId');
  }, skip: skip);

  test('every endpoint the app calls is in a flow (ratchet)', () {
    final byOp = {for (final e in doc.endpoints) e.operationId: e};
    final listed = <String>{
      for (final f in pageFlows)
        for (final s in f.steps)
          for (final c in s.calls)
            if (c.inSpec)
              if (byOp[c.operationId] case final e?)
                key(e.method, e.path)
              else
                key(c.method!, c.path!),
    };
    final missing = appCalls().difference(listed).toList()..sort();
    final baseline = File('test/hub/api_flows_baseline.txt');
    if (Platform.environment['UPDATE_BASELINE'] == '1' ||
        !baseline.existsSync()) {
      baseline.writeAsStringSync('${missing.join('\n')}\n');
    }
    final known = baseline
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toSet();
    expect(
      missing.toSet().difference(known),
      isEmpty,
      reason: 'the app calls an endpoint no page flow lists — add it',
    );
    expect(
      known.difference(missing.toSet()),
      isEmpty,
      reason:
          'now in a flow (or no longer called) — remove from the baseline '
          '(UPDATE_BASELINE=1)',
    );
  }, skip: skip);
}
