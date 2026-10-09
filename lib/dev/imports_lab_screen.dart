import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_spacing.dart';
import '../core/network/api_client.dart';

part 'imports_lab_slip_flow.dart';

/// `/dev/imports` — fire the 0.3.0 import endpoints by hand and see exactly
/// what went out and what came back (status, time, pretty JSON).
///
/// The BE side is still a stub (logs + echoes), so this is where the slip /
/// chat flows get exercised before the real UI calls them:
/// - `POST /pending-transactions/parse-text` — the chat box
/// - the slip flow, step by step: send the gallery file names to
///   `POST /slip-imports/check` → see which came back new / already seen →
///   upload only the new ones to `POST /pending-transactions/scan-slip`
///   (a 1×1 test PNG each). `DELETE /slip-imports` forgets them again.
class ImportsLabScreen extends StatelessWidget {
  const ImportsLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imports lab')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _ParseTextCard(),
          SizedBox(height: AppSpacing.md),
          _SlipFlowCard(),
        ],
      ),
    );
  }
}

/// One call's request + response, as shown under each card.
class _Exchange {
  const _Exchange({
    required this.request,
    this.status,
    this.response,
    this.error,
    this.elapsed,
  });

  final String request;
  final int? status;
  final Object? response;
  final String? error;
  final Duration? elapsed;
}

/// Runs [call] and captures what was sent / received, errors included.
Future<_Exchange> _run(
  String request,
  Future<Response<dynamic>> Function() call,
) async {
  final sw = Stopwatch()..start();
  try {
    final res = await call();
    return _Exchange(
      request: request,
      status: res.statusCode,
      response: res.data,
      elapsed: sw.elapsed,
    );
  } on DioException catch (e) {
    return _Exchange(
      request: request,
      status: e.response?.statusCode,
      response: e.response?.data,
      error: e.message ?? e.type.name,
      elapsed: sw.elapsed,
    );
  }
}

String _pretty(Object? v) {
  if (v == null) return '—';
  try {
    return const JsonEncoder.withIndent('  ').convert(v);
  } catch (_) {
    return '$v';
  }
}

/// Card shell: title, endpoint, inputs, send button, last exchange.
class _LabCard extends StatelessWidget {
  const _LabCard({
    required this.title,
    required this.endpoint,
    required this.inputs,
    required this.onSend,
    required this.busy,
    required this.last,
  });

  final String title;
  final String endpoint;
  final List<Widget> inputs;
  final VoidCallback onSend;
  final bool busy;
  final _Exchange? last;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ex = last;
    final ok = ex != null && ex.error == null && (ex.status ?? 0) < 300;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleMedium),
            Text(
              endpoint,
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...inputs,
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: busy ? null : onSend,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Send'),
            ),
            if (ex != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.error,
                    size: 18,
                    color: ok ? Colors.green : scheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      [
                        'HTTP ${ex.status ?? '—'}',
                        if (ex.elapsed != null)
                          '${ex.elapsed!.inMilliseconds} ms',
                        ?ex.error,
                      ].join(' · '),
                      style: textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              _Block(label: 'Request', text: ex.request),
              _Block(label: 'Response', text: _pretty(ex.response)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A labelled monospace box; long-press copies it.
class _Block extends StatelessWidget {
  const _Block({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$label copied')));
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── parse-text ──────────────────────────────────────────────────────────

class _ParseTextCard extends StatefulWidget {
  const _ParseTextCard();
  @override
  State<_ParseTextCard> createState() => _ParseTextCardState();
}

class _ParseTextCardState extends State<_ParseTextCard> {
  final _text = TextEditingController(text: 'กาแฟ 65 เมื่อวาน');
  bool _busy = false;
  _Exchange? _last;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final dio = context.read<ApiClient>().dio;
    final body = {'text': _text.text};
    setState(() => _busy = true);
    final ex = await _run(
      'POST /pending-transactions/parse-text\n${_pretty(body)}',
      () => dio.post<dynamic>('/pending-transactions/parse-text', data: body),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _last = ex;
    });
  }

  @override
  Widget build(BuildContext context) => _LabCard(
    title: 'Chat → text to JSON',
    endpoint: 'POST /pending-transactions/parse-text',
    busy: _busy,
    last: _last,
    onSend: _send,
    inputs: [
      TextField(
        controller: _text,
        decoration: const InputDecoration(
          labelText: 'text',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    ],
  );
}
