import 'dart:convert';
import 'dart:io';

import 'package:chubi_pocket/hub/api/openapi_model.dart';
import 'package:chubi_pocket/hub/api/page_flows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// The API hub's ratchet, like the UI hub's: the BE's spec
/// (`chubi-pocket-be/internal/apidoc/openapi.yaml`, served as
/// `/api/v1/openapi.json`) must parse, every `$ref` must resolve, every
/// endpoint needs a summary and a module, and every endpoint must say which
/// page calls it (`x-used-by`). Endpoints that don't yet are the debt in
/// `test/hub/api_unused_baseline.txt` — it can only shrink. Regenerate:
/// `UPDATE_BASELINE=1 flutter test test/hub`.
///
/// Skipped when the BE checkout isn't next to the app.
void main() {
  final file = File('../chubi-pocket-be/internal/apidoc/openapi.yaml');

  Object? plain(Object? v) => v is YamlMap
      ? {for (final e in v.entries) '${e.key}': plain(e.value)}
      : v is YamlList
      ? [for (final e in v) plain(e)]
      : v;

  test('the BE spec parses and every endpoint says who calls it (ratchet)', () {
    final json = plain(loadYaml(file.readAsStringSync()))!;
    final doc = ApiDoc.parse(
      (json as Map).cast<String, dynamic>(),
    ).withFlows(pageFlows);
    expect(doc.endpoints, isNotEmpty);
    expect(doc.schemas, isNotEmpty);

    // Every $ref points at something that exists.
    final text = jsonEncode(json);
    final dangling = <String>{};
    for (final m in RegExp(r'"\$ref":"#/([^"]+)"').allMatches(text)) {
      Object? at = json;
      for (final part in m.group(1)!.split('/')) {
        at = at is Map ? at[part] : null;
      }
      if (at == null) dangling.add(m.group(1)!);
    }
    expect(dangling, isEmpty, reason: 'dangling \$ref');

    expect(
      doc.endpoints.where((e) => (e.summary ?? '').isEmpty).map((e) => e.id),
      isEmpty,
      reason: 'every endpoint needs a summary',
    );

    final unused = doc.unused.map((e) => e.id).toList()..sort();
    final baseline = File('test/hub/api_unused_baseline.txt');
    if (Platform.environment['UPDATE_BASELINE'] == '1' ||
        !baseline.existsSync()) {
      baseline.writeAsStringSync('${unused.join('\n')}\n');
    }
    final known = baseline
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toSet();
    expect(
      unused.toSet().difference(known),
      isEmpty,
      reason: 'a spec endpoint no page flow lists — add it to page_flows.dart',
    );
    expect(
      known.difference(unused.toSet()),
      isEmpty,
      reason:
          'now in a flow (or is gone) — remove from the baseline '
          '(UPDATE_BASELINE=1)',
    );
  }, skip: file.existsSync() ? false : 'BE checkout not found next to the app');
}
