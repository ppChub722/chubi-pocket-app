import 'package:equatable/equatable.dart';

/// Result of `GET /v1/scheduled-transactions/upcoming?days=N`
/// (spec §3.3). Drives the optional "due in N days" widget.
class ScheduledUpcoming extends Equatable {
  const ScheduledUpcoming({
    required this.entries,
    required this.totalExpenseDue,
    required this.totalIncomeDue,
  });

  final List<ScheduledUpcomingEntry> entries;
  final double totalExpenseDue;
  final double totalIncomeDue;

  factory ScheduledUpcoming.fromJson(Map<String, dynamic> json) {
    final entries = (json['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ScheduledUpcomingEntry.fromJson)
        .toList();
    return ScheduledUpcoming(
      entries: entries,
      totalExpenseDue: (json['total_expense_due'] as num?)?.toDouble() ?? 0,
      totalIncomeDue: (json['total_income_due'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [entries, totalExpenseDue, totalIncomeDue];
}

class ScheduledUpcomingEntry extends Equatable {
  const ScheduledUpcomingEntry({
    required this.id,
    required this.name,
    required this.nextBillingDate,
    required this.amount,
    required this.daysUntil,
  });

  final String id;
  final String name;
  final String nextBillingDate;
  final double amount;
  final int daysUntil;

  factory ScheduledUpcomingEntry.fromJson(Map<String, dynamic> json) {
    return ScheduledUpcomingEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      nextBillingDate: json['next_billing_date'] as String,
      amount: (json['amount'] as num).toDouble(),
      daysUntil: json['days_until'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, nextBillingDate, amount, daysUntil];
}
