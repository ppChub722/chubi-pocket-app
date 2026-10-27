import 'package:equatable/equatable.dart';

import '../../transactions/domain/refs.dart';
import 'debt_direction.dart';

/// On a transaction that is a person-book entry's transaction (0.4.1-1 D3: a
/// debt OR a repayment), connected + synced with the entry.
class DebtLink extends Equatable {
  const DebtLink({
    required this.entryId,
    required this.key,
    required this.person,
    required this.direction,
    this.repayment = false,
    this.connected = false,
    this.paid = false,
  });

  final String entryId;

  final String key;
  final EmbeddedPerson person;
  final DebtEntryDirection direction;

  /// `kind` repayment (else a debt).
  final bool repayment;

  /// An existing transaction connected later (can disconnect); false = made
  /// from the entry (delete it instead).
  final bool connected;

  final bool paid;

  factory DebtLink.fromJson(Map<String, dynamic> json) => DebtLink(
    entryId: json['entry_id'] as String,
    key: json['key'] as String,
    person: EmbeddedPerson.fromJson(
      (json['person'] as Map).cast<String, dynamic>(),
    ),
    direction: DebtEntryDirection.parse(json['direction'] as String?),
    repayment: json['kind'] == 'repayment',
    connected: (json['connected'] as bool?) ?? false,
    paid: (json['paid'] as bool?) ?? false,
  );

  @override
  List<Object?> get props => [
    entryId,
    key,
    person,
    direction,
    repayment,
    connected,
    paid,
  ];
}

/// On a transaction that IS a repayment: the person it pays back (expense) or
/// comes back from (income). Tx detail shows "จ่ายคืนให้ ลี ›" / "รับคืนจาก
/// chalee ›" → the person page; its category is the system Debt Paid /
/// Received and can't change. 0.4.1-1: worked out from the transaction's
/// [DebtLink] (kind repayment), no longer its own JSON key.
class RepaymentPerson extends Equatable {
  const RepaymentPerson({
    required this.key,
    required this.person,
    this.entryId,
  });

  final String key;
  final EmbeddedPerson person;

  /// The repayment's person-book row (GET /personal-debts/{id}).
  final String? entryId;

  String get name => person.name;

  @override
  List<Object?> get props => [key, person, entryId];
}
