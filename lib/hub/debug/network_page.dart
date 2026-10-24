import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/network_recorder.dart';
import '../../ui/ui.dart';

/// `/dev/debug/network` — the app's recent API calls (the last 400, newest
/// first): method, path, status, duration, response size, the page it came
/// from and whether the page's opening or an action on it started it (best
/// effort: within ~1 s of the route appearing = "open"). Two views: the call
/// list, and a summary by endpoint (count, average time, failures) — the
/// quickest way to spot the same endpoint called again and again. No headers
/// or bodies are kept. Clear empties the buffer.
class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

enum _View { calls, endpoints }

enum _Filter { all, failed, slow, open, action }

class _NetworkPageState extends State<NetworkPage> {
  final _rec = NetworkRecorder.instance;
  _View _view = _View.calls;
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _rec.addListener(_changed);
  }

  @override
  void dispose() {
    _rec.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool _match(NetworkCall c) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !('${c.method} ${c.path} ${c.page}'.toLowerCase().contains(q))) {
      return false;
    }
    return switch (_filter) {
      _Filter.all => true,
      _Filter.failed => c.failed,
      _Filter.slow => (c.durationMs ?? 0) >= 1000,
      _Filter.open => c.trigger == NetworkTrigger.open,
      _Filter.action => c.trigger == NetworkTrigger.action,
    };
  }

  @override
  Widget build(BuildContext context) {
    final calls = _rec.calls.where(_match).toList();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Network | ${_rec.length}'),
        actions: [
          TextButton(onPressed: _rec.clear, child: const Text('Clear')),
        ],
      ),
      body: Column(
        children: [
          AppInput.search(
            hint: 'Search path or page',
            onChanged: (v) => setState(() => _query = v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                for (final v in _View.values) ...[
                  AppChip(
                    label: v == _View.calls ? 'Calls' : 'By endpoint',
                    selected: _view == v,
                    onTap: () => setState(() => _view = v),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                for (final f in _Filter.values) ...[
                  AppChip(
                    label: switch (f) {
                      _Filter.all => 'All',
                      _Filter.failed => 'Failed',
                      _Filter.slow => 'Slow ≥ 1 s',
                      _Filter.open => 'On open',
                      _Filter.action => 'By action',
                    },
                    selected: _filter == f,
                    size: ChipSize.chip,
                    onTap: () => setState(() => _filter = f),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: calls.isEmpty
                ? Center(
                    child: Text(
                      'No calls yet — use the app, then come back.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : _view == _View.calls
                ? _CallList(calls: calls)
                : _EndpointSummary(calls: calls),
          ),
        ],
      ),
    );
  }
}

String _time(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';

String _bytes(int? b) => b == null
    ? '—'
    : b < 1024
    ? '$b B'
    : '${(b / 1024).toStringAsFixed(1)} kB';

Color _statusColor(BuildContext context, NetworkCall c) {
  final scheme = Theme.of(context).colorScheme;
  if (c.pending) return scheme.onSurfaceVariant;
  if (c.failed) return scheme.error;
  return scheme.primary;
}

class _CallList extends StatelessWidget {
  const _CallList({required this.calls});

  final List<NetworkCall> calls;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      itemCount: calls.length,
      separatorBuilder: (_, _) => const AppDivider.row(),
      itemBuilder: (context, i) {
        final c = calls[i];
        final status = c.pending
            ? '…'
            : c.statusCode?.toString() ?? c.errorCode ?? 'ERR';
        return InkWell(
          onTap: () => _showDetail(context, c),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    status,
                    style: text.labelLarge?.copyWith(
                      color: _statusColor(context, c),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.method} ${c.path}',
                        style: text.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '${_time(c.startedAt)} | '
                        '${c.durationMs == null ? '—' : '${c.durationMs} ms'}'
                        ' | ${_bytes(c.responseBytes)} | '
                        '${c.trigger == NetworkTrigger.open ? 'open' : 'action'}'
                        '${c.page.isEmpty ? '' : ' | ${c.page}'}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, NetworkCall c) {
    final rows = <(String, String)>[
      ('Request', '${c.method} ${c.path}'),
      if (c.query.isNotEmpty) ('Query', c.query),
      ('Endpoint', c.endpoint),
      ('Status', c.statusCode?.toString() ?? c.errorCode ?? 'pending'),
      if (c.errorDetail != null) ('Error', c.errorDetail!),
      ('Duration', c.durationMs == null ? '—' : '${c.durationMs} ms'),
      ('Response size', _bytes(c.responseBytes)),
      ('Started', _time(c.startedAt)),
      ('Page', c.page.isEmpty ? '—' : c.page),
      (
        'Trigger',
        c.trigger == NetworkTrigger.open ? 'page opening' : 'action / refresh',
      ),
      ('Request id', c.requestId ?? '—'),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            for (final (k, v) in rows)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(k),
                subtitle: SelectableText(v),
                onTap: () => Clipboard.setData(ClipboardData(text: v)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Agg {
  int count = 0;
  int failed = 0;
  int totalMs = 0;
  int timed = 0;
  int open = 0;
  int? bytes;
  final Set<String> pages = {};
}

class _EndpointSummary extends StatelessWidget {
  const _EndpointSummary({required this.calls});

  final List<NetworkCall> calls;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final by = <String, _Agg>{};
    for (final c in calls) {
      final a = by.putIfAbsent(c.endpoint, _Agg.new);
      a.count++;
      if (c.failed) a.failed++;
      if (c.durationMs != null) {
        a.totalMs += c.durationMs!;
        a.timed++;
      }
      if (c.trigger == NetworkTrigger.open) a.open++;
      a.bytes = c.responseBytes ?? a.bytes;
      if (c.page.isNotEmpty) a.pages.add(c.page);
    }
    final rows = by.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const AppDivider.row(),
      itemBuilder: (context, i) {
        final e = rows[i];
        final a = e.value;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '×${a.count}',
                  style: text.titleSmall?.copyWith(
                    color: a.count >= 4 ? scheme.error : scheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: text.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                    Text(
                      'avg ${a.timed == 0 ? '—' : '${a.totalMs ~/ a.timed} ms'}'
                      ' | ${a.failed} failed | ${a.open} on open / '
                      '${a.count - a.open} by action | '
                      '${a.pages.length} page${a.pages.length == 1 ? '' : 's'}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (a.pages.isNotEmpty)
                      Text(
                        a.pages.join('  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
