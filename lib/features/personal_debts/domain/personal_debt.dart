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
  List<Object?> get props =>
      [contactId, displayName, owedToMeOpen, iOweOpen, netPosition, openCount];
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
  List<Object?> get props =>
      [data, totalOwedToMe, totalIOwe, netPosition, currency];
}
