import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_spacing.dart';

/// Index page for `/dev/*` debug routes.
///
/// Phase 0 starts with theme preview only; future debug screens (state-pattern
/// widgets showcase, API ping tester, widget sandbox) get added here.
class DevHubScreen extends StatelessWidget {
  const DevHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_DevEntry>[
      _DevEntry(
        title: 'Theme preview',
        subtitle: 'Theme registry, locale, font, color swatches, formatters',
        route: '/dev/theme-preview',
        icon: Icons.palette_outlined,
      ),
      _DevEntry(
        title: 'State widgets',
        subtitle: 'LoadingView (skeleton) · ErrorView (3 variants) · EmptyView',
        route: '/dev/state-widgets',
        icon: Icons.layers_outlined,
      ),
      _DevEntry(
        title: 'Logs',
        subtitle:
            'Live log tail · level filter · search · copy / share — env-gated',
        route: '/dev/logs',
        icon: Icons.receipt_long_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dev hub')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final e = entries[i];
          return Card(
            child: ListTile(
              leading: Icon(e.icon),
              title: Text(e.title),
              subtitle: Text(e.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(e.route),
            ),
          );
        },
      ),
    );
  }
}

class _DevEntry {
  const _DevEntry({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
}
