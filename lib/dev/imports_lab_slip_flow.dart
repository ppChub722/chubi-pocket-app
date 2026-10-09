part of 'imports_lab_screen.dart';

/// One file's upload in step 4.
class _Upload {
  const _Upload(this.fileKey, this.exchange);
  final String fileKey;
  final _Exchange exchange;
}

/// The whole "Import slip" round trip, one numbered step at a time:
/// 1 the names sent · 2 the /check call · 3 new vs already seen ·
/// 4 an upload per new file. Run it twice to watch the seen ones drop out.
class _SlipFlowCard extends StatefulWidget {
  const _SlipFlowCard();
  @override
  State<_SlipFlowCard> createState() => _SlipFlowCardState();
}

class _SlipFlowCardState extends State<_SlipFlowCard> {
  final _files = TextEditingController(
    text:
        'KPlus_20261009_081100.jpg|48213|1760000000\n'
        'SCB_20261009_120501.jpg|51022|1760010000\n'
        'Screenshot_20261009_130000.png|80211|1760020000',
  );
  bool _busy = false;
  List<String>? _sent;
  _Exchange? _check;
  List<String> _new = const [];
  List<String> _seen = const [];
  final List<_Upload> _uploads = [];
  _Exchange? _reset;

  /// A 1×1 PNG — the stub only looks at the upload's metadata.
  static final _fakePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  void dispose() {
    _files.dispose();
    super.dispose();
  }

  Future<void> _runFlow() async {
    final dio = context.read<ApiClient>().dio;
    final files = [
      for (final line in _files.text.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    setState(() {
      _busy = true;
      _sent = files;
      _check = null;
      _new = const [];
      _seen = const [];
      _uploads.clear();
      _reset = null;
    });

    // 2 — which are new?
    final body = {'files': files};
    final check = await _run(
      'POST /slip-imports/check\n${_pretty(body)}',
      () => dio.post<dynamic>('/slip-imports/check', data: body),
    );
    if (!mounted) return;
    final res = check.response;
    final data = res is Map ? res['data'] : null;
    List<String> list(String k) => data is Map && data[k] is List
        ? (data[k] as List).cast<String>()
        : const [];
    setState(() {
      _check = check;
      _new = list('new_files');
      _seen = list('seen_files');
    });

    // 4 — upload only the new ones.
    for (final (i, key) in _new.indexed) {
      final fields = {'file_key': key, 'trans_ref': 'TEST-REF-${i + 1}'};
      final name = key.split('|').first;
      final shown = {
        ...fields,
        'image': '$name (test PNG, ${_fakePng.length} bytes)',
      };
      final ex = await _run(
        'POST /pending-transactions/scan-slip (multipart)\n${_pretty(shown)}',
        () => dio.post<dynamic>(
          '/pending-transactions/scan-slip',
          data: FormData.fromMap({
            ...fields,
            'image': MultipartFile.fromBytes(_fakePng, filename: name),
          }),
        ),
      );
      if (!mounted) return;
      setState(() => _uploads.add(_Upload(key, ex)));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _clearHistory() async {
    final dio = context.read<ApiClient>().dio;
    setState(() => _busy = true);
    final ex = await _run(
      'DELETE /slip-imports',
      () => dio.delete<dynamic>('/slip-imports'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _reset = ex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sent = _sent;
    final check = _check;
    final reset = _reset;
    final okUploads = _uploads.where((u) => _isOk(u.exchange)).length;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Slip flow (Import slip)', style: textTheme.titleMedium),
            Text(
              'names → /slip-imports/check → new vs seen → scan-slip per new file',
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _files,
              minLines: 2,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'gallery files — one "name|size|modified" per line',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _runFlow,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Run flow'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _busy ? null : _clearHistory,
                  child: const Text('Clear history'),
                ),
              ],
            ),
            if (reset != null) ...[
              _Status(exchange: reset),
              _Block(label: 'Response', text: _pretty(reset.response)),
            ],
            if (sent != null) ...[
              _Step(n: 1, title: 'Names sent (${sent.length})'),
              for (final f in sent) _FileLine(fileKey: f),
            ],
            if (check != null) ...[
              const _Step(n: 2, title: 'Check — which are new?'),
              _Status(exchange: check),
              _Block(label: 'Request', text: check.request),
              _Block(label: 'Response', text: _pretty(check.response)),
              _Step(
                n: 3,
                title:
                    'Result — ${_new.length} new · ${_seen.length} already scanned',
              ),
              for (final f in sent ?? const <String>[])
                _FileLine(
                  fileKey: f,
                  tag: _new.contains(f)
                      ? 'NEW → upload'
                      : _seen.contains(f)
                      ? 'SEEN → skip'
                      : '?',
                  good: _new.contains(f),
                ),
            ],
            if (check != null && _new.isNotEmpty) ...[
              _Step(
                n: 4,
                title:
                    'Upload new files — $okUploads / ${_new.length} ok'
                    '${_busy ? '…' : ''}',
              ),
              for (final u in _uploads)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: Icon(
                    _isOk(u.exchange) ? Icons.check_circle : Icons.error,
                    color: _isOk(u.exchange)
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    u.fileKey.split('|').first,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  subtitle: Text(
                    'HTTP ${u.exchange.status ?? '—'} · '
                    '${u.exchange.elapsed?.inMilliseconds ?? '—'} ms',
                  ),
                  children: [
                    _Block(label: 'Request', text: u.exchange.request),
                    _Block(
                      label: 'Response',
                      text: _pretty(u.exchange.response),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isOk(_Exchange e) => e.error == null && (e.status ?? 0) < 300;

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title});
  final int n;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: scheme.primary,
            child: Text(
              '$n',
              style: TextStyle(fontSize: 12, color: scheme.onPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

/// A file key on one line, with an optional NEW / SEEN tag.
class _FileLine extends StatelessWidget {
  const _FileLine({required this.fileKey, this.tag, this.good = false});
  final String fileKey;
  final String? tag;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fileKey,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: good
                    ? Colors.green.withValues(alpha: 0.15)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: good ? Colors.green.shade800 : scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "✓ HTTP 200 · 42 ms" for one call.
class _Status extends StatelessWidget {
  const _Status({required this.exchange});
  final _Exchange exchange;

  @override
  Widget build(BuildContext context) {
    final ok = _isOk(exchange);
    final elapsed = exchange.elapsed;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error,
            size: 18,
            color: ok ? Colors.green : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              [
                'HTTP ${exchange.status ?? '—'}',
                if (elapsed != null) '${elapsed.inMilliseconds} ms',
                ?exchange.error,
              ].join(' · '),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
