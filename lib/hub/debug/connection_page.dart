import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/network/connection_cubit.dart';
import '../../core/network/network_recorder.dart';
import '../../ui/ui.dart';
import 'dns_lookup.dart';

/// `/dev/debug/connection` — can this device reach the server, and if not,
/// where it breaks: the API URL the build uses, the addresses this device's
/// DNS gives for its host (a stale answer after a server move shows here),
/// `/health` and `/app/version` with their time or the platform's error,
/// the app's online state and the latest failed calls. Runs on open; Copy
/// report puts it all on the clipboard. Reachable before login (logo taps).
class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({super.key});

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _Check {
  const _Check(this.label, this.value, {this.ok});

  final String label;
  final String value;

  /// null = information only.
  final bool? ok;
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  static const _timeout = Duration(seconds: 8);

  List<_Check> _checks = const [];
  bool _running = false;
  DateTime? _ranAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    final checks = <_Check>[];

    ApiClient? api;
    try {
      api = context.read<ApiClient>();
    } catch (_) {}
    ConnectionStatus? status;
    try {
      status = context.read<ConnectionCubit>().state.status;
    } catch (_) {}

    try {
      final info = await PackageInfo.fromPlatform();
      checks.add(_Check('App', '${info.version} (${info.buildNumber})'));
    } catch (_) {}
    final baseUrl = api?.dio.options.baseUrl;
    checks.add(
      _Check('API base URL', baseUrl ?? 'unknown', ok: baseUrl != null),
    );
    if (status != null) {
      checks.add(
        _Check(
          'App online state',
          status.name,
          ok: status == ConnectionStatus.online,
        ),
      );
    }

    final uri = baseUrl == null ? null : Uri.tryParse(baseUrl);
    if (uri != null && uri.host.isNotEmpty) {
      checks.add(await _dns(uri.host));
      checks.add(await _health(uri.origin));
      if (api != null) checks.add(await _version(api));
    }

    final failed = NetworkRecorder.instance.calls
        .where((c) => c.failed)
        .take(10);
    for (final c in failed) {
      checks.add(
        _Check(
          'Failed ${_time(c.startedAt)}',
          [
            '${c.method} ${c.path}',
            '→ ${c.statusCode ?? c.errorCode ?? 'error'}',
            if (c.errorDetail != null) c.errorDetail!,
          ].join('  '),
          ok: false,
        ),
      );
    }
    if (failed.isEmpty) {
      checks.add(const _Check('Failed calls', 'none recorded'));
    }

    if (!mounted) return;
    setState(() {
      _checks = checks;
      _running = false;
      _ranAt = DateTime.now();
    });
  }

  Future<_Check> _dns(String host) async {
    final sw = Stopwatch()..start();
    try {
      final ips = await lookupHost(host).timeout(_timeout);
      return _Check(
        'DNS $host',
        '${ips.isEmpty ? '(no address)' : ips.join(', ')}  (${sw.elapsedMilliseconds} ms)',
        ok: ips.isNotEmpty,
      );
    } on UnsupportedError catch (e) {
      return _Check('DNS $host', e.message ?? 'not available');
    } catch (e) {
      return _Check('DNS $host', _short(e), ok: false);
    }
  }

  Future<_Check> _health(String origin) async {
    final dio = Dio(
      BaseOptions(connectTimeout: _timeout, receiveTimeout: _timeout),
    );
    final sw = Stopwatch()..start();
    try {
      final r = await dio.get<dynamic>('$origin/health');
      return _Check(
        'GET /health',
        '${r.statusCode}  ${r.data}  (${sw.elapsedMilliseconds} ms)',
        ok: r.statusCode == 200,
      );
    } on DioException catch (e) {
      return _Check('GET /health', _dioError(e, sw), ok: false);
    } finally {
      dio.close();
    }
  }

  Future<_Check> _version(ApiClient api) async {
    final sw = Stopwatch()..start();
    try {
      final r = await api.dio.get<dynamic>('/app/version');
      return _Check(
        'GET /app/version',
        '${r.statusCode}  (${sw.elapsedMilliseconds} ms)',
        ok: r.statusCode == 200,
      );
    } on DioException catch (e) {
      return _Check('GET /app/version', _dioError(e, sw), ok: false);
    }
  }

  static String _dioError(DioException e, Stopwatch sw) {
    final status = e.response?.statusCode;
    final detail = NetworkRecorderInterceptor.errorDetailOf(e);
    return [
      status?.toString() ?? e.type.name,
      ?detail,
      '(${sw.elapsedMilliseconds} ms)',
    ].join('  ');
  }

  static String _short(Object e) {
    final s = e.toString();
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  String get _report => [
    'Connection check ${_ranAt?.toIso8601String() ?? ''}',
    'Platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}, ${kReleaseMode ? 'release' : 'debug'}',
    for (final c in _checks)
      '${c.ok == null ? '·' : (c.ok! ? 'OK' : 'FAIL')}  ${c.label}: ${c.value}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Connection')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          Row(
            children: [
              AppButton(
                label: _running ? 'Checking…' : 'Check again',
                icon: Icons.refresh,
                size: AppButtonSize.control,
                loading: _running,
                onPressed: _running ? null : _run,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Copy report',
                icon: Icons.copy,
                size: AppButtonSize.control,
                variant: AppButtonVariant.outlined,
                onPressed: _checks.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: _report));
                        showAppSnackBar(context, 'Report copied');
                      },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in _checks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: c.ok == null
                  ? Icon(Icons.info_outline, color: scheme.onSurfaceVariant)
                  : Icon(
                      c.ok! ? Icons.check_circle : Icons.error,
                      color: c.ok! ? Colors.green : scheme.error,
                    ),
              title: Text(c.label),
              subtitle: SelectableText(c.value),
              onTap: () => Clipboard.setData(ClipboardData(text: c.value)),
            ),
        ],
      ),
    );
  }
}
