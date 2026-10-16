import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_client.dart';
import '../../ui/ui.dart';

/// `/dev/debug/env` — what this build is talking to and running as: the API
/// base URL, build mode, platform, app version and build number. Tap a row to
/// copy it.
class EnvInfoScreen extends StatefulWidget {
  const EnvInfoScreen({super.key});

  @override
  State<EnvInfoScreen> createState() => _EnvInfoScreenState();
}

class _EnvInfoScreenState extends State<EnvInfoScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((i) {
          if (mounted) setState(() => _info = i);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    String? baseUrl;
    try {
      baseUrl = context.read<ApiClient>().dio.options.baseUrl;
    } catch (_) {
      baseUrl = null;
    }
    final mode = kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug';
    const defineUrl = String.fromEnvironment('API_BASE_URL');
    const defineHost = String.fromEnvironment('API_HOST');
    final rows = <(String, String)>[
      ('API base URL', baseUrl ?? 'unknown'),
      ('API_BASE_URL define', defineUrl.isEmpty ? '(not set)' : defineUrl),
      ('API_HOST define', defineHost.isEmpty ? '(not set)' : defineHost),
      ('Build mode', mode),
      ('Platform', kIsWeb ? 'web' : defaultTargetPlatform.name),
      ('App version', _info?.version ?? '…'),
      ('Build number', _info?.buildNumber ?? '…'),
      ('Package', _info?.packageName ?? '…'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Environment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PpForgeSpacing.lg,
          PpForgeSpacing.md,
          PpForgeSpacing.lg,
          PpForgeSpacing.huge,
        ),
        children: [
          for (final (k, v) in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(k),
              subtitle: SelectableText(v),
              onTap: () => Clipboard.setData(ClipboardData(text: v)),
            ),
        ],
      ),
    );
  }
}
