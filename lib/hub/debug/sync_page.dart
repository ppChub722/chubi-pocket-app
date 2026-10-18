import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/data/sync_coordinator.dart';
import '../../core/data/sync_set.dart';
import '../../ui/ui.dart';

/// `/dev/debug/sync` — what the app holds of each shared dataset versus what
/// the server last said, and the last sync rounds. Use it to confirm nothing is
/// fetched twice: a quiet app shows no new rounds.
class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _short(String? v) {
    if (v == null || v.isEmpty) return '—';
    return v.length <= 22 ? v : '…${v.substring(v.length - 22)}';
  }

  String _names(Set<SyncSet> s) =>
      s.isEmpty ? '—' : s.map((e) => e.wire).join(', ');

  String _roundBody(SyncRound r) {
    final lines = [
      'asked: ${_names(r.requested)}',
      'returned: ${_names(r.returned)}',
      'unchanged: ${_names(r.unchanged)}',
      if (r.errors.isNotEmpty)
        'errors: ${r.errors.entries.map((e) => '${e.key.wire}=${e.value}').join(', ')}',
      if (r.failure != null) 'failed: ${r.failure}',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.read<SyncCoordinator>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sync')),
      body: ListenableBuilder(
        listenable: coordinator,
        builder: (context, _) {
          final held = coordinator.held;
          final versions = coordinator.versions;
          final rounds = coordinator.rounds.reversed.toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_run(() => coordinator.sync())),
                    child: const Text('Sync everything now'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_run(coordinator.clearDeviceData)),
                    child: const Text('Clear device data'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Clear device data deletes the saved copy; restart the app to '
                'see a cold start from the server.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Datasets', style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              for (final set in SyncSet.values)
                _row(
                  context,
                  name: set.wire,
                  held: held[set],
                  server: versions[set.wire],
                  tracked: true,
                ),
              const SizedBox(height: AppSpacing.md),
              Text('Page data (version only)', style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              for (final key in SyncKey.values)
                _row(
                  context,
                  name: key.wire,
                  held: null,
                  server: versions[key.wire],
                  tracked: false,
                ),
              const SizedBox(height: AppSpacing.md),
              Text('Last ${rounds.length} rounds', style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              if (rounds.isEmpty)
                Text(
                  'No round yet.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              for (final r in rounds)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.at.toIso8601String().substring(11, 19)} · '
                          '${r.duration.inMilliseconds} ms'
                          '${r.fromFallback ? ' · fallback (no /sync)' : ''}',
                          style: text.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _roundBody(r),
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String name,
    required String? held,
    required String? server,
    required bool tracked,
  }) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final inSync = held != null && held == server;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    tracked
                        ? 'held ${_short(held)}\nserver ${_short(server)}'
                        : 'server ${_short(server)}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (tracked)
              AppChip(
                label: held == null
                    ? 'not held'
                    : (inSync ? 'in sync' : 'behind'),
                size: ChipSize.mini,
                selected: true,
                tone: held == null
                    ? AppChipTone.neutral
                    : (inSync ? AppChipTone.success : AppChipTone.info),
              ),
          ],
        ),
      ),
    );
  }
}
