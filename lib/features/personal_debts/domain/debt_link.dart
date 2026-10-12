import 'package:equatable/equatable.dart';

import '../../transactions/domain/refs.dart';
import 'debt_direction.dart';

/// `DebtLink`: on a transaction that IS a debt entry's wallet side (one
/// record with the entry) — `Transaction.counterparty`.
class DebtLink extends Equatable {
  const DebtLink({
    required this.entryId,
    required this.key,
    required this.person,
    required this.direction,
    this.paid = false,
  });

  final String entryId;

  /// The person key (`c:<contact id>` / `n:<name>`).
  final String key;
  final EmbeddedPerson person;
  final DebtEntryDirection direction;

  /// The "จ่ายแล้ว" label.
  final bool paid;

  factory DebtLink.fromJson(Map<String, dynamic> json) => DebtLink(
    entryId: json['entry_id'] as String,
    key: json['key'] as String,
    person: EmbeddedPerson.fromJson(
      (json['person'] as Map).cast<String, dynamic>(),
    ),
    direction: DebtEntryDirection.parse(json['direction'] as String?),
    paid: (json['paid'] as bool?) ?? false,
  );

  @override
  List<Object?> get props => [entryId, key, person, direction, paid];
}
