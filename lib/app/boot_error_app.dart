import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/logger/app_logger.dart';

/// Shown instead of the real app when boot fails BEFORE `runApp` could
/// mount [ChubiPocketApp] — the case that used to be an infinite white
/// screen. Wired by the `runZonedGuarded` boot guard in `main.dart`.
///
/// Deliberately NOT localized through ARB: l10n / prefs / fonts may be
/// part of what failed, so this screen depends on nothing but Material.
/// Copy is bilingual inline instead.
class BootErrorApp extends StatelessWidget {
  const BootErrorApp({required this.error, this.stackTrace, super.key});

  final Object error;
  final StackTrace? stackTrace;

  String _report() {
    final logs = AppLogger.instance.recent
        .map((e) => e.toJsonLine())
        .toList()
        .reversed
        .take(80)
        .toList()
        .reversed
        .join('\n');
    return 'ChubiPocket boot failure\n'
        'error: $error\n\n'
        'stack:\n${stackTrace ?? '-'}\n\n'
        'recent logs:\n$logs';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'เปิดแอปไม่สำเร็จ\nFailed to start',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ปิดแอปแล้วเปิดใหม่อีกครั้ง — ถ้ายังเจออยู่ กดปุ่มด้านล่าง'
                  'เพื่อคัดลอกรายละเอียดแล้วส่งให้ผู้พัฒนา\n'
                  '(Close and reopen the app. If it persists, copy the '
                  'details below and send them to the developer.)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$error',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (ctx) => FilledButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('คัดลอกรายละเอียด / Copy details'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _report()));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('คัดลอกแล้ว / Copied')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
