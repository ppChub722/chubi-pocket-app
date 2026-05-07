/// Budget recurrence period (spec §08/§3.1).
///
/// Boundaries are computed in the user's `preferences.timezone` —
/// `weekly` is Mon–Sun, `monthly` is calendar month, `yearly` is Jan–Dec.
enum BudgetPeriod {
  weekly,
  monthly,
  yearly;

  String toJson() {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }

  static BudgetPeriod fromJson(String raw) {
    switch (raw) {
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        throw ArgumentError('Unknown budget period: $raw');
    }
  }
}
