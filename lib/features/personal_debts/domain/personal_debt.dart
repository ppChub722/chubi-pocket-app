import 'package:equatable/equatable.dart';

enum DebtDirection { iOwe, owedToMe }

extension DebtDirectionWire on DebtDirection {
  String get wire {
    switch (this) {
      case DebtDirection.iOwe:
        return 'i_owe';
      case DebtDirection.owedToMe:
        return 'owed_to_me';
    }
  }

  static DebtDirection parse(String? s) {
    switch (s) {
      case 'owed_to_me':
        return DebtDirection.owedToMe;
      default:
        return DebtDirection.iOwe;
    }
  }
}

enum DebtStatus { open, settled, cancelled }

extension DebtStatusWire on DebtStatus {
  String get wire {
    switch (this) {
      case DebtStatus.open:
        return 'open';
      case DebtStatus.settled:
        return 'settled';
      case DebtStatus.cancelled:
        return 'cancelled';
    }
  }

  static DebtStatus parse(String? s) {
    switch (s) {
      case 'settled':
        return DebtStatus.settled;
      case 'cancelled':
        return DebtStatus.cancelled;
      default:
        return DebtStatus.open;
    }
  }
}

class PersonalDebt extends Equatable {
  const PersonalDebt({
    required this.id,
    required this.userId,
    required this.direction,
    required this.counterpartyPersonName,
    required this.amount,
    required this.settledAmount,
    required this.currency,
    required this.status,
    this.counterpartyContactId,
    this.sourceTransactionId,
    this.sourceProjectTransactionId,
    this.projectId,
    this.note,
    this.createdAt,
  });

  final String id;
  final String userId;
  final DebtDirection direction;
  final String? counterpartyContactId;
  final String counterpartyPersonName;
  final String? sourceTransactionId;
  final String? sourceProjectTransactionId;
  final String? projectId;
  final double amount;
  final double settledAmount;
  final String currency;
  final DebtStatus status;
  final String? note;
  final DateTime? createdAt;

  double get outstanding => (amount - settledAmount).clamp(0, double.infinity);
  bool get isOpen => status == DebtStatus.open;
  bool get isIOwe => direction == DebtDirection.iOwe;
  bool get isOwedToMe => direction == DebtDirection.owedToMe;

  factory PersonalDebt.fromJson(Map<String, dynamic> json) {
    return PersonalDebt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      direction: DebtDirectionWire.parse(json['direction'] as String?),
      counterpartyContactId: json['counterparty_contact_id'] as String?,
      counterpartyPersonName: json['counterparty_person_name'] as String,
      sourceTransactionId: json['source_transaction_id'] as String?,
      sourceProjectTransactionId:
          json['source_project_transaction_id'] as String?,
      projectId: json['project_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      settledAmount: (json['settled_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: DebtStatusWire.parse(json['status'] as String?),
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(
        (json['created_at'] as String?) ?? '',
      )?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    direction,
    counterpartyContactId,
    counterpartyPersonName,
    sourceTransactionId,
    sourceProjectTransactionId,
    projectId,
    amount,
    settledAmount,
    currency,
    status,
    note,
    createdAt,
  ];
}

/// Person row from `GET /personal-debts/people` — aggregated by counterparty.
class PersonRow extends Equatable {
  const PersonRow({
    required this.displayName,
    required this.owedToMeOpen,
    required this.iOweOpen,
    required this.netPosition,
    required this.openCount,
    this.contactId,
  });

  final String? contactId;
  final String displayName;
  final double owedToMeOpen;
  final double iOweOpen;
  final double netPosition;
  final int openCount;

  bool get theyOweMeNet => netPosition > 0;
  bool get iOweThemNet => netPosition < 0;
  bool get even => netPosition.abs() < 0.005;

  factory PersonRow.fromJson(Map<String, dynamic> json) {
    return PersonRow(
      contactId: json['contact_id'] as String?,
      displayName: json['display_name'] as String,
      owedToMeOpen: (json['owed_to_me_open'] as num).toDouble(),
      iOweOpen: (json['i_owe_open'] as num).toDouble(),
      netPosition: (json['net_position'] as num).toDouble(),
      openCount: (json['open_count'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [
    contactId,
    displayName,
    owedToMeOpen,
    iOweOpen,
    netPosition,
    openCount,
  ];
}

class PeopleResponse extends Equatable {
  const PeopleResponse({
    required this.data,
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.netPosition,
    required this.currency,
  });

  final List<PersonRow> data;
  final double totalOwedToMe;
  final double totalIOwe;
  final double netPosition;
  final String currency;

  factory PeopleResponse.fromJson(Map<String, dynamic> json) {
    return PeopleResponse(
      data: ((json['data'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PersonRow.fromJson)
          .toList(),
      totalOwedToMe: (json['total_owed_to_me'] as num?)?.toDouble() ?? 0,
      totalIOwe: (json['total_i_owe'] as num?)?.toDouble() ?? 0,
      netPosition: (json['net_position'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'THB',
    );
  }

  @override
  List<Object?> get props => [
    data,
    totalOwedToMe,
    totalIOwe,
    netPosition,
    currency,
  ];
}

/// Everything with one counterparty, grouped the way the BE's `/people`
/// does it: by contact when linked, otherwise by the typed name
/// (case-insensitive). A linked row and a typed row with the same name are
/// two different people until the name is absorbed into the contact.
class DebtPerson {
  DebtPerson({
    required this.contactId,
    required this.displayName,
    required this.debts,
  });

  final String? contactId;
  final String displayName;
  final List<PersonalDebt> debts;

  static String keyOf(PersonalDebt d) => d.counterpartyContactId != null
      ? 'c:${d.counterpartyContactId}'
      : 'n:${d.counterpartyPersonName.trim().toLowerCase()}';

  String get key => contactId != null
      ? 'c:$contactId'
      : 'n:${displayName.trim().toLowerCase()}';

  bool matches(PersonalDebt d) => keyOf(d) == key;

  Iterable<PersonalDebt> get open => debts.where((d) => d.isOpen);

  double get owedToMeOpen =>
      open.where((d) => d.isOwedToMe).fold(0, (a, d) => a + d.outstanding);
  double get iOweOpen =>
      open.where((d) => d.isIOwe).fold(0, (a, d) => a + d.outstanding);

  /// > 0 → they owe me (net); < 0 → I owe them.
  double get net => owedToMeOpen - iOweOpen;
  int get openCount => open.length;
  String get currency => debts.isEmpty ? 'THB' : debts.first.currency;

  /// Group [all] by person; most money at stake first, settled-up last.
  static List<DebtPerson> group(Iterable<PersonalDebt> all) {
    final byKey = <String, DebtPerson>{};
    for (final d in all) {
      byKey
          .putIfAbsent(
            keyOf(d),
            () => DebtPerson(
              contactId: d.counterpartyContactId,
              displayName: d.counterpartyPersonName,
              debts: [],
            ),
          )
          .debts
          .add(d);
    }
    return byKey.values.toList()..sort((a, b) {
      final byOpen = (b.openCount > 0 ? 1 : 0) - (a.openCount > 0 ? 1 : 0);
      if (byOpen != 0) return byOpen;
      return b.net.abs().compareTo(a.net.abs());
    });
  }
}
