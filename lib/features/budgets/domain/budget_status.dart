enum BudgetStatus {
  active,
  archived;

  String toJson() {
    switch (this) {
      case BudgetStatus.active:
        return 'active';
      case BudgetStatus.archived:
        return 'archived';
    }
  }

  static BudgetStatus fromJson(String raw) {
    switch (raw) {
      case 'active':
        return BudgetStatus.active;
      case 'archived':
        return BudgetStatus.archived;
      default:
        throw ArgumentError('Unknown budget status: $raw');
    }
  }
}
