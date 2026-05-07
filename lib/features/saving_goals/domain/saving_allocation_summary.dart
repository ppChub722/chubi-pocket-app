import 'package:equatable/equatable.dart';

/// Result of `GET /v1/accounts/:id/saving-allocations` (spec §3.7).
///
/// Powers the per-account allocation "pie" — total balance split across
/// each active goal's slice plus the unallocated remainder. The form
/// page reads this so the user knows the remaining capacity before
/// picking an `allocation_pct` for a new goal.
class SavingAllocationSummary extends Equatable {
  const SavingAllocationSummary({
    required this.accountId,
    required this.accountBalance,
    required this.currency,
    required this.activeGoals,
    required this.allocatedPct,
    required this.unallocatedPct,
    required this.unallocatedAmount,
  });

  final String accountId;
  final double accountBalance;
  final String currency;
  final List<SavingAllocationSlice> activeGoals;
  final double allocatedPct;
  final double unallocatedPct;
  final double unallocatedAmount;

  factory SavingAllocationSummary.fromJson(Map<String, dynamic> json) {
    final goals = (json['active_goals'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(SavingAllocationSlice.fromJson)
        .toList();
    return SavingAllocationSummary(
      accountId: json['account_id'] as String,
      accountBalance: (json['account_balance'] as num).toDouble(),
      currency: json['currency'] as String,
      activeGoals: goals,
      allocatedPct: (json['allocated_pct'] as num).toDouble(),
      unallocatedPct: (json['unallocated_pct'] as num).toDouble(),
      unallocatedAmount: (json['unallocated_amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        accountId,
        accountBalance,
        currency,
        activeGoals,
        allocatedPct,
        unallocatedPct,
        unallocatedAmount,
      ];
}

class SavingAllocationSlice extends Equatable {
  const SavingAllocationSlice({
    required this.id,
    required this.name,
    required this.allocationPct,
    required this.currentAmount,
  });

  final String id;
  final String name;
  final double allocationPct;
  final double currentAmount;

  factory SavingAllocationSlice.fromJson(Map<String, dynamic> json) {
    return SavingAllocationSlice(
      id: json['id'] as String,
      name: json['name'] as String,
      allocationPct: (json['allocation_pct'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, allocationPct, currentAmount];
}
