import 'data_changes.dart';
import 'sync_set.dart';

/// Which page-data caches reload when these page-data keys / datasets changed.
Set<DataTable> tablesForSync({
  Set<SyncKey> keys = const {},
  Set<SyncSet> sets = const {},
}) => {
  for (final k in keys)
    ...switch (k) {
      SyncKey.transactions => const {
        DataTable.transactions,
        DataTable.dashboard,
        DataTable.budgets,
      },
      SyncKey.budgets => const {DataTable.budgets, DataTable.dashboard},
      SyncKey.savingGoals => const {DataTable.savingGoals, DataTable.dashboard},
      SyncKey.pending => const {DataTable.pending},
    },
  for (final s in sets)
    ...switch (s) {
      SyncSet.accounts || SyncSet.recurring => const {DataTable.dashboard},
      SyncSet.debtPeople => const {DataTable.dashboard, DataTable.debts},
      SyncSet.projects => const {DataTable.projects},
      _ => const <DataTable>{},
    },
};
