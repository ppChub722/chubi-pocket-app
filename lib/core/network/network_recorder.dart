import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum NetworkTrigger { open, action }

@immutable
class NetworkCall {
  const NetworkCall({
    required this.id,
    required this.method,
    required this.path,
    required this.query,
    required this.startedAt,
    this.statusCode,
    this.durationMs,
    this.responseBytes,
    this.errorCode,
    this.errorDetail,
    this.requestId,
    this.page = '',
    this.trigger = NetworkTrigger.action,
    this.pending = false,
  });

  final int id;
  final String method;

  /// The path under the base URL, without the query string.
  final String path;
  final String query;
  final DateTime startedAt;
  final int? statusCode;
  final int? durationMs;
  final int? responseBytes;

  final String? errorCode;

  /// The platform's own words when no response came back (a failed DNS
  /// lookup, a refused or timed-out connection and the address it tried).
  final String? errorDetail;
  final String? requestId;
  final bool pending;

  final String page;

  final NetworkTrigger trigger;

  bool get failed => !pending && (statusCode == null || statusCode! >= 400);

  String get endpoint => '$method ${normalizePath(path)}';

  static final _id = RegExp(r'/([0-9a-fA-F]{8}-[0-9a-fA-F-]{27}|\d+)(?=/|$)');

  static String normalizePath(String path) =>
      path.replaceAllMapped(_id, (_) => '/:id');

  NetworkCall copyWith({
    int? statusCode,
    int? durationMs,
    int? responseBytes,
    String? errorCode,
    String? errorDetail,
    String? requestId,
    bool? pending,
  }) => NetworkCall(
    id: id,
    method: method,
    path: path,
    query: query,
    startedAt: startedAt,
    statusCode: statusCode ?? this.statusCode,
    durationMs: durationMs ?? this.durationMs,
    responseBytes: responseBytes ?? this.responseBytes,
    errorCode: errorCode ?? this.errorCode,
    errorDetail: errorDetail ?? this.errorDetail,
    requestId: requestId ?? this.requestId,
    page: page,
    trigger: trigger,
    pending: pending ?? this.pending,
  );
}

class NetworkRecorder extends ChangeNotifier {
  NetworkRecorder._();

  static final NetworkRecorder instance = NetworkRecorder._();

  static const capacity = 400;

  final List<NetworkCall> _calls = [];
  int _next = 0;

  String _page = '';
  DateTime _pageSince = DateTime.fromMillisecondsSinceEpoch(0);

  void noteRoute(String location) {
    if (location == _page) return;
    _page = location;
    _pageSince = DateTime.now();
  }

  List<NetworkCall> get calls => List.unmodifiable(_calls.reversed);

  int get length => _calls.length;

  int _start(String method, String path, String query) {
    final id = _next++;
    final now = DateTime.now();
    _calls.add(
      NetworkCall(
        id: id,
        method: method,
        path: path,
        query: query,
        startedAt: now,
        page: _page,
        trigger: now.difference(_pageSince) < const Duration(seconds: 1)
            ? NetworkTrigger.open
            : NetworkTrigger.action,
        pending: true,
      ),
    );
    if (_calls.length > capacity) _calls.removeAt(0);
    notifyListeners();
    return id;
  }

  void _finish(
    int id, {
    int? statusCode,
    int? durationMs,
    int? bytes,
    String? errorCode,
    String? errorDetail,
    String? requestId,
  }) {
    final i = _calls.lastIndexWhere((c) => c.id == id);
    if (i < 0) return;
    _calls[i] = _calls[i].copyWith(
      statusCode: statusCode,
      durationMs: durationMs,
      responseBytes: bytes,
      errorCode: errorCode,
      errorDetail: errorDetail,
      requestId: requestId,
      pending: false,
    );
    notifyListeners();
  }

  void clear() {
    _calls.clear();
    notifyListeners();
  }
}

class NetworkRecorderInterceptor extends Interceptor {
  NetworkRecorderInterceptor({NetworkRecorder? recorder})
    : _recorder = recorder ?? NetworkRecorder.instance;

  final NetworkRecorder _recorder;

  static const _idExtra = '__chubi_net_id';
  static const _stopwatchExtra = '__chubi_net_stopwatch';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    options.extra[_idExtra] = _recorder._start(
      options.method,
      options.path.startsWith('http') ? uri.path : options.path,
      _safeQuery(uri),
    );
    options.extra[_stopwatchExtra] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final o = response.requestOptions;
    _recorder._finish(
      o.extra[_idExtra] as int? ?? -1,
      statusCode: response.statusCode,
      durationMs: (o.extra[_stopwatchExtra] as Stopwatch?)?.elapsedMilliseconds,
      bytes: _size(response),
      requestId: o.headers['X-Request-ID']?.toString(),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    _recorder._finish(
      o.extra[_idExtra] as int? ?? -1,
      statusCode: err.response?.statusCode,
      durationMs: (o.extra[_stopwatchExtra] as Stopwatch?)?.elapsedMilliseconds,
      bytes: err.response == null ? null : _size(err.response!),
      errorCode: err.response == null ? err.type.name : null,
      errorDetail: errorDetailOf(err),
      requestId: o.headers['X-Request-ID']?.toString(),
    );
    handler.next(err);
  }

  /// What the platform said when no response came back, cut to 300 chars;
  /// null when the server answered (its status says enough).
  static String? errorDetailOf(DioException err) {
    if (err.response != null) return null;
    final raw = (err.error ?? err.message ?? '').toString().trim();
    if (raw.isEmpty) return null;
    return raw.length > 300 ? '${raw.substring(0, 300)}…' : raw;
  }

  static final _secret = RegExp(
    r'token|password|secret|authorization|api_?key|otp|pin|card|cvv',
    caseSensitive: false,
  );

  static String _safeQuery(Uri uri) => uri.queryParametersAll.entries
      .expand(
        (e) => e.value.map(
          (v) => '${e.key}=${_secret.hasMatch(e.key) ? '[REDACTED]' : v}',
        ),
      )
      .join('&');

  static int? _size(Response<dynamic> r) =>
      int.tryParse(r.headers.value('content-length') ?? '');
}
