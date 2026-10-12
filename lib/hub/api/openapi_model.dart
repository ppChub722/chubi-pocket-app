/// The API section's data: a tolerant reader of the BE's OpenAPI 3.x JSON
/// (`GET /api/v1/openapi.json`). View-only — nothing here calls an endpoint.
///
/// Extensions the BE adds: per operation `x-breaking` (a note, or `true`) and
/// `x-used-by` (`[{page, calls}]`, plain strings = 1 call — read, but the hub
/// takes "used by" from the FE page-flow registry instead); at the top
/// `x-registered-routes` (the real route total) and `x-spec-routes` (the
/// method × path pairs in the spec) for the coverage counter.
library;

import 'page_flows.dart';

const _methods = ['get', 'post', 'put', 'patch', 'delete'];

class ApiProp {
  const ApiProp({
    required this.name,
    required this.type,
    required this.required,
    this.description,
    this.example,
  });

  final String name;

  /// `string`, `uuid`, `array<Split>`, `Account`, `string | null` …
  final String type;
  final bool required;
  final String? description;
  final Object? example;
}

class ApiSchema {
  const ApiSchema({
    required this.name,
    required this.type,
    this.description,
    this.properties = const [],
    this.enumValues = const [],
    this.example,
  });

  final String name;
  final String type;
  final String? description;
  final List<ApiProp> properties;
  final List<String> enumValues;
  final Object? example;
}

class ApiParam {
  const ApiParam({
    required this.name,
    required this.where,
    required this.type,
    required this.required,
    this.description,
  });

  final String name;

  /// path | query | header
  final String where;
  final String type;
  final bool required;
  final String? description;
}

/// A request body or one response: its type label, the schema it names
/// ([ref], for a link) and an example.
class ApiPayload {
  const ApiPayload({
    required this.type,
    this.status,
    this.description,
    this.ref,
    this.example,
  });

  final String? status;
  final String? description;
  final String type;
  final String? ref;
  final Object? example;
}

class ApiUse {
  const ApiUse(this.page, this.calls);
  final String page;
  final int calls;
}

class ApiEndpoint {
  const ApiEndpoint({
    required this.method,
    required this.path,
    required this.module,
    this.operationId,
    this.summary,
    this.description,
    this.params = const [],
    this.request,
    this.responses = const [],
    this.breaking,
    this.usedBy = const [],
  });

  /// GET · POST · PUT · PATCH · DELETE
  final String method;
  final String path;
  final String module;
  final String? operationId;
  final String? summary;
  final String? description;
  final List<ApiParam> params;
  final ApiPayload? request;
  final List<ApiPayload> responses;

  /// Non-null = a breaking change; the text is the note ('' = no note).
  final String? breaking;
  final List<ApiUse> usedBy;

  String get id => '$method $path';

  ApiEndpoint withUsedBy(List<ApiUse> uses) => ApiEndpoint(
    method: method,
    path: path,
    module: module,
    operationId: operationId,
    summary: summary,
    description: description,
    params: params,
    request: request,
    responses: responses,
    breaking: breaking,
    usedBy: uses,
  );
}

class ApiDoc {
  const ApiDoc({
    required this.title,
    required this.version,
    required this.schemas,
    required this.endpoints,
    this.registeredRoutes,
    this.specRoutes,
  });

  final String title;
  final String version;
  final List<ApiSchema> schemas;
  final List<ApiEndpoint> endpoints;

  /// What the server really registers, and how many of those the spec
  /// describes — the coverage counter. Null when the server doesn't say.
  final int? registeredRoutes;
  final int? specRoutes;

  int get specified => specRoutes ?? endpoints.length;

  List<String> get modules =>
      ({for (final e in endpoints) e.module}.toList()..sort());

  /// page → its endpoints with the call counts, pages sorted by name.
  Map<String, List<(ApiEndpoint, int)>> get pages {
    final out = <String, List<(ApiEndpoint, int)>>{};
    for (final e in endpoints) {
      for (final u in e.usedBy) {
        (out[u.page] ??= []).add((e, u.calls));
      }
    }
    return Map.fromEntries(
      out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Endpoints no page calls (worth a look: dead, or just not tagged yet).
  List<ApiEndpoint> get unused => [
    for (final e in endpoints)
      if (e.usedBy.isEmpty) e,
  ];

  /// The same document with every endpoint's [ApiEndpoint.usedBy] taken from
  /// the FE's page-flow registry (the spec's `x-used-by` is ignored): one
  /// use per page, its calls = the steps that call it.
  ApiDoc withFlows(List<PageFlow> flows) {
    final byOp = <String, Map<String, int>>{};
    for (final f in flows) {
      for (final step in f.steps) {
        for (final c in step.calls) {
          final op = c.operationId;
          if (op == null) continue;
          final pages = byOp.putIfAbsent(op, () => {});
          pages[f.page] = (pages[f.page] ?? 0) + 1;
        }
      }
    }
    return ApiDoc(
      title: title,
      version: version,
      schemas: schemas,
      registeredRoutes: registeredRoutes,
      specRoutes: specRoutes,
      endpoints: [
        for (final e in endpoints)
          e.withUsedBy([
            for (final u in (byOp[e.operationId] ?? const {}).entries)
              ApiUse(u.key, u.value),
          ]),
      ],
    );
  }

  /// The endpoint an operation id names, or null.
  ApiEndpoint? byOperation(String id) =>
      endpoints.where((e) => e.operationId == id).firstOrNull;

  static ApiDoc parse(Map<String, dynamic> json) {
    _root = json;
    final info = _map(json['info']);
    final schemas = _map(_map(json['components'])['schemas']);
    return ApiDoc(
      title: _str(info['title']) ?? 'API',
      version: _str(info['version']) ?? '',
      registeredRoutes: _int(json['x-registered-routes']),
      specRoutes: _int(json['x-spec-routes']),
      schemas: [for (final e in schemas.entries) _schema(e.key, _map(e.value))]
        ..sort((a, b) => a.name.compareTo(b.name)),
      endpoints: _endpoints(_map(json['paths'])),
    );
  }
}

/// The document being read — `#/components/...` refs resolve against it.
Map<String, dynamic> _root = const {};

/// Follows a `$ref` such as `#/components/parameters/Page` (a few hops at
/// most); anything else is returned as is.
Map<String, dynamic> _deref(Object? v) {
  var m = _map(v);
  for (var i = 0; i < 5; i++) {
    final ref = m[r'$ref'];
    if (ref is! String || !ref.startsWith('#/')) return m;
    Object? at = _root;
    for (final part in ref.substring(2).split('/')) {
      at = at is Map ? at[part] : null;
    }
    if (at is! Map) return m;
    m = _map(at);
  }
  return m;
}

List<ApiEndpoint> _endpoints(Map<String, dynamic> paths) {
  final out = <ApiEndpoint>[];
  for (final p in paths.entries) {
    final item = _map(p.value);
    final shared = _params(item['parameters']);
    for (final m in _methods) {
      final op = item[m];
      if (op is! Map) continue;
      final o = _map(op);
      final tags = o['tags'];
      final module = tags is List && tags.isNotEmpty
          ? '${tags.first}'
          : _guessModule(p.key);
      final body = _map(_deref(o['requestBody'])['content']);
      final bodyMedia = body.entries.firstOrNull;
      final responses = _map(o['responses']);
      out.add(
        ApiEndpoint(
          method: m.toUpperCase(),
          path: p.key,
          module: module,
          operationId: _str(o['operationId']),
          summary: _str(o['summary']),
          description: _str(o['description']),
          params: [...shared, ..._params(o['parameters'])],
          request: bodyMedia == null ? null : _payload(_map(bodyMedia.value)),
          responses: [
            for (final r in responses.entries)
              _response(r.key, _deref(r.value)),
          ],
          breaking: _breaking(o['x-breaking']),
          usedBy: _uses(o['x-used-by']),
        ),
      );
    }
  }
  return out;
}

String _guessModule(String path) {
  final parts = path.split('/').where((s) => s.isNotEmpty);
  return parts.isEmpty ? 'other' : parts.first;
}

String? _breaking(Object? v) {
  if (v == null || v == false) return null;
  if (v is String) return v;
  return '';
}

List<ApiUse> _uses(Object? v) {
  if (v is! List) return const [];
  return [
    for (final u in v)
      if (u is String)
        ApiUse(u, 1)
      else if (u is Map)
        ApiUse('${u['page']}', _int(u['calls']) ?? 1),
  ];
}

List<ApiParam> _params(Object? v) {
  if (v is! List) return const [];
  return [
    for (final raw in v)
      if (raw is Map) _param(_deref(raw)),
  ];
}

ApiParam _param(Map<String, dynamic> p) => ApiParam(
  name: '${p['name']}',
  where: '${p['in'] ?? 'query'}',
  type: _typeLabel(_map(p['schema'])),
  required: p['required'] == true,
  description: _str(p['description']),
);

ApiPayload _response(String status, Map<String, dynamic> r) => _payload(
  _map(_firstMedia(r['content'])),
  status: status,
  description: _str(r['description']),
);

Object? _firstMedia(Object? content) {
  final m = _map(content);
  return m.entries.firstOrNull?.value;
}

ApiPayload _payload(
  Map<String, dynamic> media, {
  String? status,
  String? description,
}) {
  final schema = _map(media['schema']);
  return ApiPayload(
    status: status,
    description: description,
    type: schema.isEmpty ? '' : _typeLabel(schema),
    ref: _refName(schema) ?? _refName(_map(schema['items'])),
    example: _example(media, schema),
  );
}

Object? _example(Map<String, dynamic> media, Map<String, dynamic> schema) {
  if (media.containsKey('example')) return media['example'];
  final examples = _map(media['examples']);
  if (examples.isNotEmpty) {
    final first = _map(examples.values.first);
    if (first.containsKey('value')) return first['value'];
  }
  return schema['example'];
}

ApiSchema _schema(String name, Map<String, dynamic> s) {
  final required = {
    for (final r in (s['required'] is List ? s['required'] as List : const []))
      '$r',
  };
  return ApiSchema(
    name: name,
    type: _typeLabel(s),
    description: _str(s['description']),
    properties: [
      for (final p in _map(s['properties']).entries)
        _prop(p.key, _map(p.value), required.contains(p.key)),
    ],
    enumValues: [
      if (s['enum'] is List)
        for (final v in s['enum'] as List) '$v',
    ],
    example: s['example'],
  );
}

ApiProp _prop(String name, Map<String, dynamic> p, bool required) => ApiProp(
  name: name,
  type: _typeLabel(p),
  required: required,
  description: _str(p['description']),
  example: p['example'],
);

String? _refName(Map<String, dynamic> s) {
  final r = s[r'$ref'];
  if (r is! String) return null;
  return r.split('/').last;
}

/// A one-line type: `string`, `uuid`, `array<Split>`, `Account`,
/// `string | null`, `A | B`.
String _typeLabel(Map<String, dynamic> s) {
  final ref = _refName(s);
  if (ref != null) return ref;
  for (final k in ['oneOf', 'anyOf', 'allOf']) {
    final v = s[k];
    if (v is List && v.isNotEmpty) {
      return v
          .map((e) => _typeLabel(_map(e)))
          .join(k == 'allOf' ? ' & ' : ' | ');
    }
  }
  final t = s['type'];
  final types = t is List ? t.map((e) => '$e').toList() : [if (t != null) '$t'];
  if (types.isEmpty) return s.containsKey('enum') ? 'enum' : 'any';
  return types
      .map((x) {
        if (x == 'array') return 'array<${_typeLabel(_map(s['items']))}>';
        final f = _str(s['format']);
        return f != null && x == 'string' ? f : x;
      })
      .join(' | ');
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? v.map((k, x) => MapEntry('$k', x)) : const {};

String? _str(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
