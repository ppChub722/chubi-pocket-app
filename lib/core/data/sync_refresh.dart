import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sync_coordinator.dart';
import 'sync_set.dart';

/// Pull-to-refresh of a sheet or screen that reads these datasets: syncs them.
Future<void> Function() syncRefreshOf(BuildContext context, Set<SyncSet> sets) {
  final coordinator = context.read<SyncCoordinator>();
  return () async {
    await coordinator.sync(sets);
  };
}
