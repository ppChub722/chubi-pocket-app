import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../ui/ui.dart';
import 'openapi_model.dart';
import 'page_flows.dart';

/// Where the API pages get the spec: `GET /openapi.json` from the BE the app
/// talks to (the base URL already ends in `/api/v1`). One cached copy shared
/// by the three pages; pull-to-refresh style "Reload" drops it.
abstract final class HubOpenApi {
  /// Tests swap the network for a fixed document.
  static Future<Map<String, dynamic>> Function(BuildContext)? testSource;

  /// Tests swap the page-flow registry too.
  static List<PageFlow>? testFlows;

  /// A schema name to search for when the Schemas page opens (a type link on
  /// the Pages view sets it).
  static String? pendingSchema;

  static ApiDoc? _cache;

  static Future<ApiDoc> load(
    BuildContext context, {
    bool refresh = false,
  }) async {
    final cached = _cache;
    if (cached != null && !refresh) return cached;
    final Map<String, dynamic> json;
    if (testSource != null) {
      json = await testSource!(context);
    } else {
      final dio = context.read<ApiClient>().dio;
      final res = await dio.get<Map<String, dynamic>>('/openapi.json');
      final data = res.data;
      if (data == null) throw const FormatException('Empty spec');
      json = data;
    }
    return _cache = ApiDoc.parse(json).withFlows(testFlows ?? pageFlows);
  }

  static void clear() => _cache = null;
}

/// Loads the spec, shows loading / an error with retry, then [builder].
class ApiDocLoader extends StatefulWidget {
  const ApiDocLoader({required this.builder, super.key});

  final Widget Function(BuildContext context, ApiDoc doc) builder;

  @override
  State<ApiDocLoader> createState() => _ApiDocLoaderState();
}

class _ApiDocLoaderState extends State<ApiDocLoader> {
  ApiDoc? _doc;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await HubOpenApi.load(context, refresh: refresh);
      if (mounted) setState(() => _doc = doc);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      return code == null
          ? 'Cannot reach the server (${e.message ?? e.type.name}).'
          : 'The server answered $code for /openapi.json.';
    }
    return 'Could not read the spec: $e';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final doc = _doc;
    if (doc != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${doc.title} · v${doc.version}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppChip(
                icon: AppIcons.refresh,
                label: _loading ? 'Loading…' : 'Reload',
                size: ChipSize.control,
                onTap: _loading ? null : () => _load(refresh: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          widget.builder(context, doc),
        ],
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Text(
              _message(_error!),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: AppSpacing.md),
            AppChip(
              icon: AppIcons.refresh,
              label: 'Retry',
              size: ChipSize.control,
              onTap: _load,
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
