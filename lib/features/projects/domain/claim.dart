import 'package:equatable/equatable.dart';

import 'project.dart';

/// One bill's real pair between me and one other member (BE
/// `ClaimableBill`, GET /projects/{id}/claimable): what a claim ("ลงสมุดของฉัน",
/// a lump of one or many) would book.
class ClaimableBill extends Equatable {
  const ClaimableBill({
    required this.ptId,
    required this.type,
    required this.date,
    required this.amount,
    required this.billAmount,
    required this.other,
    required this.theyOweMe,
    this.paybackKind,
    this.description,
    this.payer,
    this.myTransactionId,
    this.claimed = false,
    this.claimedDebtId,
    this.payers = const [],
  });

  /// Multi-payer (0.4.1-2): every payer with what they paid, biggest first;
  /// one entry for a single payer.
  final List<({ProjectMemberRef member, double amount})> payers;

  final String ptId;

  /// expense | income | payback.
  final String type;

  /// A debt-type bill: payback | loan; null otherwise.
  final String? paybackKind;
  final String date;
  final String? description;
  final double billAmount;
  final ProjectMemberRef? payer;
  final ProjectMemberRef other;

  /// BE `direction` paid = they owe me (+); received = I owe them (−).
  final bool theyOweMe;

  /// The pair on this bill.
  final double amount;
  final String? myTransactionId;

  /// Already in my book: can't be claimed again.
  final bool claimed;
  final String? claimedDebtId;

  bool get isDebtType => type == 'payback';

  /// "Join an existing bill" with my tx: a money bill someone else paid /
  /// received, not booked, and I hold no copy of it yet.
  bool get joinable =>
      !claimed &&
      !isDebtType &&
      myTransactionId == null &&
      !(payer?.isMe ?? false);

  static ClaimableBill? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final other = ProjectMemberRef.tryParse(json['other']);
    if (other == null) return null;
    return ClaimableBill(
      ptId: json['pt_id'] as String,
      type: (json['type'] as String?) ?? 'expense',
      paybackKind: json['payback_kind'] as String?,
      date: (json['date'] as String?) ?? '',
      description: json['description'] as String?,
      billAmount: (json['bill_amount'] as num?)?.toDouble() ?? 0,
      payer: ProjectMemberRef.tryParse(json['payer']),
      other: other,
      theyOweMe: json['direction'] == 'paid',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      myTransactionId: json['my_transaction_id'] as String?,
      claimed: json['claimed'] == true,
      claimedDebtId: json['claimed_debt_id'] as String?,
      payers: [
        for (final p in (json['payers'] as List?) ?? const [])
          if (p is Map<String, dynamic>)
            if (ProjectMemberRef.tryParse(p['member']) case final m?)
              (member: m, amount: (p['amount'] as num?)?.toDouble() ?? 0),
      ],
    );
  }

  static List<ClaimableBill> listOf(Map<String, dynamic> json) => [
    for (final b in (json['data'] as List?) ?? const []) ?tryParse(b),
  ];

  @override
  List<Object?> get props => [
    ptId,
    type,
    paybackKind,
    date,
    description,
    billAmount,
    payer,
    other,
    theyOweMe,
    amount,
    myTransactionId,
    claimed,
    claimedDebtId,
    payers,
  ];
}

/// What a claim answered (the rest of what changed rides `effects`).
class ClaimResult {
  const ClaimResult({this.debtIds = const [], this.amount = 0});

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    final debts = [
      for (final d in (json['debts'] as List?) ?? const [])
        if (d is Map<String, dynamic>) d,
    ];
    return ClaimResult(
      debtIds: [for (final d in debts) d['id'] as String],
      amount: debts.isEmpty
          ? 0
          : (debts.first['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final List<String> debtIds;

  /// The lump debt's amount (the first debt).
  final double amount;
}
