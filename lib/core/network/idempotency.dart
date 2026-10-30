import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

/// Safe retries (0.4.2-3 B2): one [Idempotency] per form or sheet. Every
/// write sent inside [run] carries `Idempotency-Key: <base>-<n>-<body hash>`
/// (n = its order in that save), so Retry after a timeout sends the same keys
/// and the server answers the writes it already did from its record instead of
/// writing twice. A changed form sends a different body, so a different key.
class Idempotency {
  Idempotency() : base = _randomHex(16);

  final String base;

  Future<T> run<T>(Future<T> Function() save) =>
      runZoned(save, zoneValues: {_zoneKey: _Run(base)});

  /// The key for a write sent inside [run]; null outside one or for a read.
  static String? keyFor(RequestOptions o) {
    if (o.method.toUpperCase() == 'GET') return null;
    final run = Zone.current[_zoneKey];
    if (run is! _Run) return null;
    return run.next('${o.method} ${o.uri} ${_bodyText(o.data)}');
  }

  static const header = 'Idempotency-Key';

  static final _zoneKey = Object();

  static String _bodyText(Object? data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  static String _randomHex(int bytes) {
    final r = Random.secure();
    return [
      for (var i = 0; i < bytes; i++)
        r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}

class _Run {
  _Run(this.base);

  final String base;
  var _n = 0;

  String next(String request) => '$base-${_n++}-${_fnv1a(request)}';

  /// 32-bit FNV-1a, hex: enough to tell two bodies of one save apart.
  static String _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final b in utf8.encode(s)) {
      h ^= b;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}
