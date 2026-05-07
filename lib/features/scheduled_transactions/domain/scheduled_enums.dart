/// `type` on a scheduled entry — what kind of transaction it generates.
/// Mirrors `transactions.type`. Transfer-type is deferred (spec §4.9).
enum ScheduledTransactionType {
  expense,
  income;

  String toJson() => name;

  static ScheduledTransactionType fromJson(String raw) {
    switch (raw) {
      case 'expense':
        return ScheduledTransactionType.expense;
      case 'income':
        return ScheduledTransactionType.income;
      default:
        throw ArgumentError('Unknown scheduled type: $raw');
    }
  }
}

/// `entry_type` discriminator (spec §2.1).
///
/// `recurring` — indefinite (Netflix, salary).
/// `installment` — finite count; with `interest_rate > 0` it's labeled
/// "Loan" in the UI, but DB shape is identical (spec §4.2).
enum ScheduledEntryType {
  recurring,
  installment;

  String toJson() => name;

  static ScheduledEntryType fromJson(String raw) {
    switch (raw) {
      case 'recurring':
        return ScheduledEntryType.recurring;
      case 'installment':
        return ScheduledEntryType.installment;
      default:
        throw ArgumentError('Unknown entry_type: $raw');
    }
  }
}

/// `billing_cycle` (spec §3.1).
///
/// `daily` is accepted by the BE but not surfaced in the form's segmented
/// selector — listed here so list/detail pages can still parse rows
/// created via other clients (Postman, future power-user form, etc.).
enum BillingCycle {
  daily,
  weekly,
  monthly,
  yearly;

  String toJson() => name;

  static BillingCycle fromJson(String raw) {
    switch (raw) {
      case 'daily':
        return BillingCycle.daily;
      case 'weekly':
        return BillingCycle.weekly;
      case 'monthly':
        return BillingCycle.monthly;
      case 'yearly':
        return BillingCycle.yearly;
      default:
        throw ArgumentError('Unknown billing_cycle: $raw');
    }
  }
}

/// Lifecycle status (spec §2.4). Transitions are server-validated:
/// `active ↔ paused`, both → `cancelled`. `completed` and `cancelled`
/// are terminal.
enum ScheduledStatus {
  active,
  paused,
  completed,
  cancelled;

  String toJson() => name;

  static ScheduledStatus fromJson(String raw) {
    switch (raw) {
      case 'active':
        return ScheduledStatus.active;
      case 'paused':
        return ScheduledStatus.paused;
      case 'completed':
        return ScheduledStatus.completed;
      case 'cancelled':
        return ScheduledStatus.cancelled;
      default:
        throw ArgumentError('Unknown scheduled status: $raw');
    }
  }
}
