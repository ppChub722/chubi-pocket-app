import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'sync_set.dart';

class SyncPayload {
  const SyncPayload({required this.v, required this.body});

  final String v;
  final Map<String, dynamic> body;
}

class SyncError {
  const SyncError({required this.code, required this.message});

  final String code;
  final String message;
}

class SyncResult {
  const SyncResult({
    required this.syncedAt,
    required this.versions,
    required this.data,
    required this.unchanged,
    required this.errors,
    this.fromFallback = false,
  });

  final DateTime syncedAt;
  final Map<String, String> versions;
  final Map<SyncSet, SyncPayload> data;
  final Set<SyncSet> unchanged;
  final Map<SyncSet, SyncError> errors;
  final bool fromFallback;
}

class SyncRepository {
  SyncRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;
  bool _supported = true;

  /// `want` null = every dataset; `have` = the version of each dataset the app holds.
  Future<SyncResult> sync({
    Set<SyncSet>? want,
    Map<SyncSet, String> have = const {},
  }) async {
    if (_supported) {
      try {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/sync',
          data: <String, dynamic>{
            if (want != null) 'want': [for (final s in want) s.wire],
            'have': {for (final e in have.entries) e.key.wire: e.value},
          },
        );
        return _parse(res.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          throw ApiException.fromDioException(e);
        }
        _supported = false;
      }
    }
    return _fallback(want ?? SyncSet.values.toSet());
  }

  SyncResult _parse(Map<String, dynamic> json) {
    final data = <SyncSet, SyncPayload>{};
    for (final e in (json['data'] as Map? ?? const {}).entries) {
      final set = SyncSet.fromWire('${e.key}');
      final item = e.value;
      if (set == null || item is! Map) continue;
      data[set] = SyncPayload(
        v: '${item['v']}',
        body: Map<String, dynamic>.from(item['body'] as Map),
      );
    }
    final errors = <SyncSet, SyncError>{};
    for (final e in (json['errors'] as Map? ?? const {}).entries) {
      final set = SyncSet.fromWire('${e.key}');
      final item = e.value;
      if (set == null || item is! Map) continue;
      errors[set] = SyncError(
        code: '${item['code']}',
        message: '${item['message']}',
      );
    }
    return SyncResult(
      syncedAt:
          DateTime.tryParse('${json['synced_at']}') ?? DateTime.now().toUtc(),
      versions: {
        for (final e in (json['versions'] as Map? ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
      data: data,
      unchanged: {
        for (final w in (json['unchanged'] as List? ?? const []))
          ?SyncSet.fromWire('$w'),
      },
      errors: errors,
    );
  }

  /// A backend without `/sync`: each dataset from its own endpoint, no versions.
  Future<SyncResult> _fallback(Set<SyncSet> want) async {
    final data = <SyncSet, SyncPayload>{};
    final errors = <SyncSet, SyncError>{};
    await Future.wait([
      for (final set in want)
        () async {
          try {
            data[set] = SyncPayload(v: '', body: await _fetch(set));
          } on DioException catch (e) {
            final err = ApiException.fromDioException(e);
            errors[set] = SyncError(code: err.code, message: err.message);
          } catch (e) {
            errors[set] = SyncError(code: 'UNKNOWN_ERROR', message: '$e');
          }
        }(),
    ]);
    return SyncResult(
      syncedAt: DateTime.now().toUtc(),
      versions: const {},
      data: data,
      unchanged: const {},
      errors: errors,
      fromFallback: true,
    );
  }

  Future<Map<String, dynamic>> _fetch(SyncSet set) {
    switch (set) {
      case SyncSet.accounts:
        return _get('/accounts', {'status': 'all'});
      case SyncSet.categories:
        return _get('/categories', {'include_system': 'true'});
      case SyncSet.tags:
        return _get('/tags');
      case SyncSet.contacts:
        return _get('/contacts', {'status': 'all'});
      case SyncSet.debtPeople:
        return _allPages('/personal-debts/people', {'all': 'true'});
      case SyncSet.projects:
        return _allPages('/projects', {'status': 'all'});
      case SyncSet.recurring:
        return _allPages('/recurring', {'status': 'all'});
      case SyncSet.formDefaults:
        return _formDefaults();
      case SyncSet.providers:
        return _get('/payment-providers');
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> _allPages(
    String path,
    Map<String, dynamic> query,
  ) async {
    const perPage = 100;
    final first = await _get(path, {...query, 'page': 1, 'per_page': perPage});
    final rows = List<dynamic>.of(first['data'] as List? ?? const []);
    final pages =
        ((first['pagination'] as Map?)?['total_pages'] as num?)?.toInt() ?? 1;
    for (var page = 2; page <= pages; page++) {
      final next = await _get(path, {
        ...query,
        'page': page,
        'per_page': perPage,
      });
      rows.addAll(next['data'] as List? ?? const []);
    }
    return {
      ...first,
      'data': rows,
      'pagination': {
        'page': 1,
        'per_page': rows.isEmpty ? 1 : rows.length,
        'total': rows.length,
        'total_pages': 1,
      },
    };
  }

  Future<Map<String, dynamic>> _formDefaults() async {
    final options = await _get('/transactions/form-options');
    return {
      'default_account_id': options['default_account_id'],
      'fee_category_id': options['fee_category_id'],
    };
  }
}
