/// Shared datasets the device keeps; wire names match the backend's `/sync`.
enum SyncSet {
  accounts('accounts'),
  categories('categories'),
  tags('tags'),
  contacts('contacts'),
  debtPeople('debt_people'),
  projects('projects'),
  recurring('recurring'),
  formDefaults('form_defaults'),
  providers('providers');

  const SyncSet(this.wire);

  final String wire;

  static SyncSet? fromWire(String wire) {
    for (final s in values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// Page data: only their versions travel, so the app knows which pages to reload.
enum SyncKey {
  transactions('transactions'),
  budgets('budgets'),
  savingGoals('saving_goals'),
  pending('pending');

  const SyncKey(this.wire);

  final String wire;

  static SyncKey? fromWire(String wire) {
    for (final k in values) {
      if (k.wire == wire) return k;
    }
    return null;
  }
}
