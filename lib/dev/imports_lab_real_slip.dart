part of 'imports_lab_screen.dart';

/// One picked image, read once: the QR pass on the phone, then scan-slip.
class _SlipRun {
  const _SlipRun({
    required this.name,
    required this.bytes,
    required this.fileKey,
    this.qr,
    this.qrError,
    this.exchange,
  });

  final String name;
  final Uint8List bytes;
  final String fileKey;
  final SlipQrScan? qr;
  final String? qrError;

  /// Null when the image had no slip QR — `not_slip`, never uploaded.
  final _Exchange? exchange;

  /// `data` of the answer — the ScanResult (spec §4).
  Map<String, dynamic>? get result {
    final res = exchange?.response;
    final data = res is Map ? res['data'] : null;
    return data is Map<String, dynamic> ? data : null;
  }

  /// `data.ocr` (sent because the lab asks with debug=1).
  Map<String, dynamic>? get ocr {
    final ocr = result?['ocr'];
    return ocr is Map<String, dynamic> ? ocr : null;
  }

  /// ScanResult.status, or `not_slip` decided here.
  String? get status =>
      exchange == null ? 'not_slip' : result?['status'] as String?;
}

/// Real slips from the gallery (0.3.1): pick → QR on the phone (no slip
/// QR → `not_slip`, not uploaded) → scan-slip → the JSON it makes (status,
/// slip, pending drafts) and the OCR text drawn over the slip. "Run again"
/// re-reads the same images, to compare settings.
class _RealSlipCard extends StatefulWidget {
  const _RealSlipCard();
  @override
  State<_RealSlipCard> createState() => _RealSlipCardState();
}

class _RealSlipCardState extends State<_RealSlipCard> {
  int _psm = 11;
  bool _preprocess = false;
  bool _boxes = true;
  bool _busy = false;
  List<XFile> _files = const [];
  final List<_SlipRun> _runs = [];

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    _files = picked;
    await _readAll();
  }

  Future<void> _readAll() async {
    final dio = context.read<ApiClient>().dio;
    setState(() {
      _busy = true;
      _runs.clear();
    });
    for (final f in _files) {
      final bytes = await f.readAsBytes();
      final modified = await f.lastModified();
      final key =
          '${f.name}|${bytes.length}|${modified.millisecondsSinceEpoch ~/ 1000}';

      SlipQrScan? qr;
      String? qrError;
      try {
        qr = await const SlipQrReader().read(f.path);
      } catch (e) {
        qrError = '$e';
      }

      // QR first (owner rule): no slip QR → not a slip, don't upload.
      final slipQr = qr?.slip;
      if (slipQr == null) {
        if (!mounted) return;
        setState(
          () => _runs.add(
            _SlipRun(
              name: f.name,
              bytes: bytes,
              fileKey: key,
              qr: qr,
              qrError: qrError,
            ),
          ),
        );
        continue;
      }

      final fields = {
        'file_key': key,
        'trans_ref': slipQr.transRef,
        'bank_code': ?slipQr.bankCode,
        'debug': '1',
        'psm': '$_psm',
        'preprocess': _preprocess ? '1' : '0',
      };
      final ex = await _run(
        'POST /pending-transactions/scan-slip (multipart)\n'
        '${_pretty({...fields, 'image': '${f.name} (${bytes.length} bytes)'})}',
        () => dio.post<dynamic>(
          '/pending-transactions/scan-slip',
          data: FormData.fromMap({
            ...fields,
            'image': MultipartFile.fromBytes(bytes, filename: f.name),
          }),
        ),
      );
      if (!mounted) return;
      setState(
        () => _runs.add(
          _SlipRun(
            name: f.name,
            bytes: bytes,
            fileKey: key,
            qr: qr,
            qrError: qrError,
            exchange: ex,
          ),
        ),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Real slip → OCR', style: textTheme.titleMedium),
            Text(
              'gallery → QR on phone → POST /pending-transactions/scan-slip',
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!SlipQrReader.isSupported)
              // Phone only (owner 2026-10-09) — no pick button on web.
              Row(
                children: [
                  Icon(Icons.error, color: scheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Slip import works in the Android app only.',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
              )
            else ...[
              Text('psm', style: textTheme.labelSmall),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3 auto')),
                  ButtonSegment(value: 4, label: Text('4 col')),
                  ButtonSegment(value: 6, label: Text('6 block')),
                  ButtonSegment(value: 11, label: Text('11 sparse')),
                ],
                selected: {_psm},
                showSelectedIcon: false,
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _psm = s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Preprocess (gray + upscale)'),
                value: _preprocess,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _preprocess = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Draw line boxes'),
                value: _boxes,
                onChanged: (v) => setState(() => _boxes = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _busy
                            ? 'Reading ${_runs.length + 1}/${_files.length}…'
                            : 'Pick slips',
                      ),
                    ),
                  ),
                  if (_files.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _busy ? null : _readAll,
                      child: const Text('Run again'),
                    ),
                  ],
                ],
              ),
            ],
            for (final r in _runs) _SlipResult(run: r, boxes: _boxes),
          ],
        ),
      ),
    );
  }
}

/// One slip's outcome: QR, timings, the slip with what was read, the text.
class _SlipResult extends StatelessWidget {
  const _SlipResult({required this.run, required this.boxes});
  final _SlipRun run;
  final bool boxes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ocr = run.ocr;
    final lines = [
      for (final l in (ocr?['lines'] as List? ?? const []))
        if (l is Map<String, dynamic>) l,
    ];
    final width = (ocr?['width'] as num?)?.toDouble() ?? 0;
    final height = (ocr?['height'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          Text(
            run.name,
            style: textTheme.titleSmall?.copyWith(fontFamily: 'monospace'),
          ),
          if (run.exchange case final ex?) _Status(exchange: ex),
          _QrLine(run: run),
          if (run.status case final status?) _StatusChip(status: status),
          if (ocr != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                [
                  'conf ${ocr['conf']}',
                  'prep ${ocr['prep_ms']} ms',
                  'OCR ${ocr['ocr_ms']} ms',
                  'psm ${ocr['psm']}',
                  'scale ${ocr['scale']}',
                  '${width.toInt()}×${height.toInt()}',
                ].join(' · '),
                style: textTheme.labelMedium,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (width > 0 && height > 0)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: AspectRatio(
                aspectRatio: width / height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(run.bytes, fit: BoxFit.fill),
                    if (boxes)
                      CustomPaint(
                        painter: _LineBoxes(
                          lines: lines,
                          imageWidth: width,
                          imageHeight: height,
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Image.memory(run.bytes, fit: BoxFit.contain),
            ),
          if (run.result case final r?) ...[
            _Block(label: 'Slip (what was read)', text: _pretty(r['slip'])),
            _Block(
              label: 'Pending drafts (→ pending_transactions)',
              text: _pretty(r['pending']),
            ),
          ],
          if (ocr != null) ...[
            _Block(label: 'OCR text', text: '${ocr['text'] ?? ''}'),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Lines (${lines.length})'),
              children: [
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${l['conf']}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _confColor((l['conf'] as num?) ?? 0),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            '${l['text']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (run.exchange case final ex?)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Request / response'),
              children: [
                _Block(label: 'Request', text: ex.request),
                _Block(label: 'Response', text: _pretty(ex.response)),
              ],
            ),
        ],
      ),
    );
  }
}

/// ScanResult.status as a colored tag: ok · incomplete · unsupported_bank
/// · not_slip (decided on the phone).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ok' => Colors.green,
      'incomplete' => Colors.orange,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final hint = switch (status) {
      'not_slip' => ' — no slip QR, not uploaded',
      'unsupported_bank' => ' — no rule set for this bank yet',
      'incomplete' => ' — see slip.missing',
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: status,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            TextSpan(text: hint),
          ],
        ),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

/// "QR ✓ ref … · bank 004 · CRC ok" — or why there's no ref.
class _QrLine extends StatelessWidget {
  const _QrLine({required this.run});
  final _SlipRun run;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slip = run.qr?.slip;
    final raws = run.qr?.raws ?? const <String>[];
    final (ok, text) = switch (run) {
      _ when run.qrError != null => (false, 'QR error: ${run.qrError}'),
      _ when slip != null => (
        true,
        'QR ✓ ref ${slip.transRef} · bank ${slip.bankCode ?? '—'} · '
            'CRC ${slip.crcValid ? 'ok' : 'MISMATCH'}',
      ),
      _ when raws.isNotEmpty => (
        false,
        'QR found, not a slip QR: ${raws.join(' | ')}',
      ),
      _ => (false, 'No QR found'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 18,
            color: ok ? Colors.green : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Color _confColor(num conf) => conf >= 80
    ? Colors.green
    : conf >= 60
    ? Colors.orange
    : Colors.red;

/// Each OCR line's box over the slip, colored by confidence.
class _LineBoxes extends CustomPainter {
  _LineBoxes({
    required this.lines,
    required this.imageWidth,
    required this.imageHeight,
  });

  final List<Map<String, dynamic>> lines;
  final double imageWidth;
  final double imageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / imageWidth;
    final sy = size.height / imageHeight;
    for (final l in lines) {
      final b = l['box'];
      if (b is! Map) continue;
      double n(String k) => ((b[k] as num?) ?? 0).toDouble();
      final rect = Rect.fromLTWH(
        n('x') * sx,
        n('y') * sy,
        n('w') * sx,
        n('h') * sy,
      );
      final color = _confColor((l['conf'] as num?) ?? 0);
      canvas
        ..drawRect(rect, Paint()..color = color.withValues(alpha: 0.12))
        ..drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }
  }

  @override
  bool shouldRepaint(_LineBoxes old) =>
      old.lines != lines ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight;
}
