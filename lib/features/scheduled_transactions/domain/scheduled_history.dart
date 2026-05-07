import 'package:equatable/equatable.dart';

import 'scheduled_enums.dart';

/// Result of `GET /v1/scheduled-transactions/:id/history` (spec §3.9).
class ScheduledHistory extends Equatable {
  const ScheduledHistory({
    required this.entries,
    required this.totalGenerated,
    required this.totalAmountGenerated,
  });

  final List<ScheduledHistoryEntry> entries;
  final int totalGenerated;
  final double totalAmountGenerated;

  factory ScheduledHistory.fromJson(Map<String, dynamic> json) {
    final entries = (json['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ScheduledHistoryEntry.fromJson)
        .toList();
    return ScheduledHistory(
      entries: entries,
      totalGenerated: json['total_generated'] as int? ?? entries.length,
      totalAmountGenerated:
          (json['total_amount_generated'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [entries, totalGenerated, totalAmountGenerated];
}

class ScheduledHistoryEntry extends Equatable {
  const ScheduledHistoryEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.generatedAt,
  });

  final String id;
  final double amount;
  final String date;
  final String? generatedAt;

  factory ScheduledHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScheduledHistoryEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      generatedAt: json['generated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, amount, date, generatedAt];
}

/// Result of `POST /v1/scheduled-transactions/:id/generate-now`
/// (spec §3.8).
///
/// Carries the freshly created transaction id (so the caller can link
/// to it) plus a *partial* post-state of the schedule — only the three
/// fields the spec returns: `next_billing_date`,
/// `remaining_installments`, `status`. The cubit merges these into the
/// cached row before re-emitting state, so we deliberately don't try
/// to parse a full [ScheduledTransaction] here.
class GenerateNowResult extends Equatable {
  const GenerateNowResult({
    required this.generatedTransactionId,
    required this.generatedAmount,
    required this.generatedDate,
    required this.nextBillingDate,
    required this.status,
    this.remainingInstallments,
  });

  final String generatedTransactionId;
  final double generatedAmount;
  final String generatedDate;
  final String nextBillingDate;
  final ScheduledStatus status;
  final int? remainingInstallments;

  factory GenerateNowResult.fromJson(Map<String, dynamic> json) {
    final tx = json['generated_transaction'] as Map<String, dynamic>;
    final updated = json['schedule_updated'] as Map<String, dynamic>? ?? {};
    return GenerateNowResult(
      generatedTransactionId: tx['id'] as String,
      generatedAmount: (tx['amount'] as num).toDouble(),
      generatedDate: tx['date'] as String,
      nextBillingDate: updated['next_billing_date'] as String,
      status: ScheduledStatus.fromJson(updated['status'] as String),
      remainingInstallments: updated['remaining_installments'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        generatedTransactionId,
        generatedAmount,
        generatedDate,
        nextBillingDate,
        status,
        remainingInstallments,
      ];
}
