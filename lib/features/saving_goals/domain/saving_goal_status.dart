/// Lifecycle status for a saving goal.
///
/// `active` — counts toward the linked account's allocation sum (≤ 100%).
/// `archived` — frees its allocation slot; restoring re-checks capacity.
enum SavingGoalStatus {
  active,
  archived;

  String toJson() {
    switch (this) {
      case SavingGoalStatus.active:
        return 'active';
      case SavingGoalStatus.archived:
        return 'archived';
    }
  }

  static SavingGoalStatus fromJson(String raw) {
    switch (raw) {
      case 'active':
        return SavingGoalStatus.active;
      case 'archived':
        return SavingGoalStatus.archived;
      default:
        throw ArgumentError('Unknown saving goal status: $raw');
    }
  }
}
