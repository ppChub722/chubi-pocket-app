import 'package:equatable/equatable.dart';

/// The recurring list's summary card data: what repeats per month (pay /
/// receive) and the next due item.
///
/// `GET /recurring` top-level `summary`: `{month_pay, month_receive, next:
/// {id, name, date, amount, type} | null}` — per-month equivalents of the
/// active settings (BE computes). Read only through [RecurringSummary.fromJson];
/// a response without it (older BE) leaves the card on "—".|income|transfer|saving" } | null }`
/// The page reads it ONLY through [RecurringSummary.fromJson]; until the key
/// exists the card shows "—".
class RecurringSummary extends Equatable {
  const RecurringSummary({
    required this.monthPay,
    required this.monthReceive,
    this.nextName,
    this.nextDate,
  });

  static RecurringSummary? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final next = json['next'];
    return RecurringSummary(
      monthPay: (json['month_pay'] as num?) ?? 0,
      monthReceive: (json['month_receive'] as num?) ?? 0,
      nextName: next is Map<String, dynamic> ? next['name'] as String? : null,
      nextDate: next is Map<String, dynamic>
          ? DateTime.tryParse((next['date'] as String?) ?? '')
          : null,
    );
  }

  final num monthPay;
  final num monthReceive;
  final String? nextName;
  final DateTime? nextDate;

  @override
  List<Object?> get props => [monthPay, monthReceive, nextName, nextDate];
}
