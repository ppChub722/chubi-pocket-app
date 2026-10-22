import 'package:equatable/equatable.dart';

import '../../transactions/domain/refs.dart';
import 'debt_direction.dart';

class DebtLink extends Equatable {
  const DebtLink({
    required this.entryId,
    required this.key,
    required this.person,
    required this.direction,
    this.paid = false,
  });

  final String entryId;

  final String key;
  final EmbeddedPerson person;
  final DebtEntryDirection direction;

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

/// On a transaction that IS a repayment (0.4.0-3, `repayment_person`): the
/// person it pays back (expense) or comes back from (income). Tx detail shows
/// "จ่ายคืนให้ ลี ›" / "รับคืนจาก chalee ›" → the person page; its category
/// is the system Debt Paid / Received and can't change.
class RepaymentPerson extends Equatable {
  const RepaymentPerson({required this.key, required this.person});

  final String key;
  final EmbeddedPerson person;

  String get name => person.name;

  factory RepaymentPerson.fromJson(Map<String, dynamic> json) {
    final ref = json['person'] is Map
        ? (json['person'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return RepaymentPerson(
      key: json['key'] as String,
      person: EmbeddedPerson.fromJson({
        ...ref,
        'name': json['name'] ?? ref['name'],
        'contact_id': json['contact_id'] ?? ref['contact_id'],
      }),
    );
  }

  @override
  List<Object?> get props => [key, person];
}
