import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_spacing.dart';
import '../core/logger/app_logger.dart';
import '../core/logger/log_entry.dart';

/// `/dev/logs` — in-app log viewer.
///
/// Subscribes to [AppLogger.onEntry] for live tail and starts from the
/// current ring buffer. Filterable by level + free-text. Tap a row to
/// inspect; long-press to copy. The "Copy all" action exports the
/// merged log file via the system clipboard (good enough for closed
/// beta — no share-sheet dependency to maintain).
class LogsViewerScreen extends StatefulWidget {
  const LogsViewerScreen({super.key});

  @override
  State<LogsViewerScreen> createState() => _LogsViewerScreenState();
}

class _LogsViewerScreenState extends State<LogsViewerScreen> {
  late StreamSubscription<LogEntry> _sub;
  final TextEditingController _searchCtrl = TextEditingController();
  LogLevel? _minFilter; // null = no minimum (show all)
  bool _newestFirst = true;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _filePath = AppLogger.instance.filePath;
    _sub = AppLogger.instance.onEntry.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LogEntry> get _visible {
    final all = AppLogger.instance.recent;
    final q = _searchCtrl.text.trim().toLowerCase();
    final minSev = _minFilter?.severity ?? -1;
    final filtered = all.where((e) {
      if (e.level.severity < minSev) return false;
      if (q.isEmpty) return true;
      if (e.message.toLowerCase().contains(q)) return true;
      if ((e.requestId ?? '').toLowerCase().contains(q)) return true;
      if ((e.userId ?? '').toLowerCase().contains(q)) return true;
      for (final entry in e.fields.entries) {
        if (entry.key.toLowerCase().contains(q)) return true;
        if ('${entry.value}'.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList(growable: false);
    if (_newestFirst) {
      return filtered.reversed.toList(growable: false);
    }
    return filtered;
  }

  Future<void> _copyAllToClipboard() async {
    final body = await AppLogger.instance.readAllForShare();
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${body.length} chars to clipboard')),
    );
  }

  void _showEntry(LogEntry e) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntryDetailSheet(entry: e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppLogger.instance.config;
    final entries = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: _newestFirst ? 'Newest first' : 'Oldest first',
            icon: Icon(_newestFirst
                ? Icons.arrow_downward
                : Icons.arrow_upward),
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy_all),
            onPressed: _copyAllToClipboard,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${config.env.wire.toUpperCase()} · '
                  'min=${config.minLevel.wire} · '
                  'bodies=${config.logBodies} · '
                  'file=${config.fileSink}'
                  '${_filePath != null ? "\n${_filePath!}" : ""}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search msg / request_id / fields',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LevelFilterRow(
                  current: _minFilter,
                  onChanged: (v) => setState(() => _minFilter = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No log entries match'))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _EntryTile(
                      entry: entries[i],
                      onTap: () => _showEntry(entries[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LevelFilterRow extends StatelessWidget {
  const _LevelFilterRow({required this.current, required this.onChanged});
  final LogLevel? current;
  final ValueChanged<LogLevel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: current == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 4),
          for (final lvl in LogLevel.values) ...[
            ChoiceChip(
              label: Text('${lvl.tag} ${lvl.wire.toLowerCase()}'),
              selected: current == lvl,
              onSelected: (_) => onChanged(lvl),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap});
  final LogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (entry.level) {
      LogLevel.debug => scheme.onSurfaceVariant,
      LogLevel.info => scheme.primary,
      LogLevel.warn => Colors.orange,
      LogLevel.error => scheme.error,
      LogLevel.critical => Colors.purple,
    };
    final t = entry.timestamp.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final ts = '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';

    return InkWell(
      onTap: onTap,
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: entry.toJsonLine()));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              child: Text(entry.level.tag,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(ts,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500, color: color)),
                  if (entry.requestId != null || entry.fields.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if (entry.requestId != null)
                            'req=${entry.requestId!.substring(0, entry.requestId!.length.clamp(0, 8))}',
                          if (entry.fields.isNotEmpty)
                            entry.fields.entries
                                .take(3)
                                .map((e) => '${e.key}=${e.value}')
                                .join('  '),
                        ].join('  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryDetailSheet extends StatelessWidget {
  const _EntryDetailSheet({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(entry.message,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy JSON',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: entry.toJsonLine()));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(entry.toJsonLine(),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
