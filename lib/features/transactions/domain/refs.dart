import 'package:equatable/equatable.dart';

import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_type.dart';
import '../../../ui/ui.dart';

IconCode? _icon(Object? v) =>
    v is Map<String, dynamic> ? IconCode.fromJson(v) : null;

class AccountRef extends Equatable {
  const AccountRef({
    required this.id,
    required this.name,
    this.iconCode,
    this.logoUrl,
    this.type = AccountType.cash,
    this.group = 'asset',
    this.currency = 'THB',
    this.archived = false,
  });

  final String id;
  final String name;
  final IconCode? iconCode;
  final String? logoUrl;
  final AccountType type;

  final String group;
  final String currency;
  final bool archived;

  bool get isLiability => group == 'liability';

  factory AccountRef.fromJson(Map<String, dynamic> json) => AccountRef(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    iconCode: _icon(json['icon_code']),
    logoUrl: json['logo_url'] as String?,
    type: AccountType.fromJson((json['type'] as String?) ?? 'cash'),
    group: (json['group'] as String?) ?? 'asset',
    currency: (json['currency'] as String?) ?? 'THB',
    archived: (json['archived'] as bool?) ?? false,
  );

  Account toAccount({double balance = 0}) => Account(
    id: id,
    name: name,
    type: type,
    balance: balance,
    currency: currency,
    iconCode: iconCode,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    iconCode,
    logoUrl,
    type,
    group,
    currency,
    archived,
  ];
}

class EmbeddedCategory extends Equatable {
  const EmbeddedCategory({
    required this.id,
    required this.name,
    this.type = CategoryType.expense,
    this.iconCode,
    this.isSystem = false,
    this.systemKind,
    this.parentId,
  });

  final String id;
  final String name;
  final CategoryType type;
  final IconCode? iconCode;
  final bool isSystem;

  final String? systemKind;
  final String? parentId;

  bool get isDebtRepayment =>
      systemKind == 'DEBT_PAID' || systemKind == 'DEBT_RECEIVED';

  /// One of the four person-book kinds (ให้กู้ยืม, กู้ยืม, ชำระหนี้,
  /// รับชำระหนี้).
  bool get isDebtKind =>
      isDebtRepayment ||
      systemKind == 'LOAN_GIVEN' ||
      systemKind == 'LOAN_TAKEN';
  bool get isTransferOut => systemKind == 'TRANSFER_OUT';
  bool get isTransferIn => systemKind == 'TRANSFER_IN';

  factory EmbeddedCategory.fromJson(Map<String, dynamic> json) =>
      EmbeddedCategory(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        type: (json['type'] as String?) == 'income'
            ? CategoryType.income
            : CategoryType.expense,
        iconCode: _icon(json['icon_code']),
        isSystem: (json['is_system'] as bool?) ?? false,
        systemKind: json['system_kind'] as String?,
        parentId: json['parent_id'] as String?,
      );

  Category toCategory({int sortOrder = 0}) => Category(
    id: id,
    name: name,
    type: type,
    iconCode: iconCode,
    parentId: parentId,
    isSystem: isSystem,
    systemKind: systemKind,
    sortOrder: sortOrder,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    iconCode,
    isSystem,
    systemKind,
    parentId,
  ];
}

class RecurringItemLink extends Equatable {
  const RecurringItemLink({
    required this.itemId,
    this.recurringId,
    this.recurringName,
    this.recurringIconCode,
    this.seq,
    this.total,
    this.slot,
  });

  /// The stored row's id, or `slot:{rule}:{slot}` when the BE sends none.
  final String itemId;

  final String? recurringId;
  final String? recurringName;
  final IconCode? recurringIconCode;
  final int? seq;
  final int? total;

  /// The occurrence's original date ("YYYY-MM-DD"); null from an old BE.
  final String? slot;

  factory RecurringItemLink.fromJson(Map<String, dynamic> json) {
    final r = json['recurring'];
    final rec = r is Map ? r.cast<String, dynamic>() : null;
    final ruleId = rec?['id'] as String? ?? json['rule_id'] as String?;
    final slot = json['slot'] as String?;
    return RecurringItemLink(
      itemId: json['item_id'] as String? ?? 'slot:$ruleId:$slot',
      recurringId: ruleId,
      recurringName: rec?['name'] as String?,
      recurringIconCode: _icon(rec?['icon_code']),
      seq: (json['seq'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      slot: slot,
    );
  }

  String label(String fallback) => [
    recurringName ?? fallback,
    if (seq != null && total != null) '$seq/$total',
  ].join(' | ');

  @override
  List<Object?> get props => [
    itemId,
    recurringId,
    recurringName,
    recurringIconCode,
    seq,
    total,
    slot,
  ];
}

class EventBillLink extends Equatable {
  const EventBillLink({
    required this.event,
    required this.billId,
    this.linked = false,
    this.payer,
    this.billAmount = 0,
    this.members,
    this.isOrigin,
    this.inSync,
    this.differences = const [],
  });

  final EventRef event;
  final String billId;

  /// B3: true = the bill is this tx ("origin"), false = my share ("copy");
  /// null on list rows / another member's tx.
  final bool? isOrigin;

  /// B3: false = the bill and my tx differ ([differences]); offer "update
  /// from the event" (POST /transactions/{id}/apply-event).
  final bool? inSync;
  final List<({String field, Object? mine, Object? event})> differences;

  /// true = my tx IS the bill (I paid); false = my copy of my share.
  final bool linked;

  /// Who paid the bill (0.4.0-3 B2); null on list rows.
  final BillMemberRef? payer;

  /// The whole bill; 0 on list rows.
  final double billAmount;

  /// Everyone in the bill with their share, the payer first; null on list
  /// rows.
  final List<BillShare>? members;

  factory EventBillLink.fromJson(Map<String, dynamic> json) => EventBillLink(
    event: EventRef.fromJson((json['event'] as Map).cast<String, dynamic>()),
    billId: json['bill_id'] as String,
    linked: (json['linked'] as bool?) ?? false,
    payer: json['payer'] is Map
        ? BillMemberRef.fromJson((json['payer'] as Map).cast<String, dynamic>())
        : null,
    billAmount: (json['bill_amount'] as num?)?.toDouble() ?? 0,
    members: json['members'] is List
        ? [
            for (final m in json['members'] as List)
              BillShare.fromJson((m as Map).cast<String, dynamic>()),
          ]
        : null,
    isOrigin: switch (json['kind']) {
      'origin' => true,
      'copy' => false,
      _ => null,
    },
    inSync: json['in_sync'] as bool?,
    differences: [
      for (final d in (json['differences'] as List?) ?? const [])
        if (d is Map)
          (
            field: (d['field'] as String?) ?? '',
            mine: d['mine'],
            event: d['event'],
          ),
    ],
  );

  @override
  List<Object?> get props => [
    event,
    billId,
    linked,
    payer,
    billAmount,
    members,
    isOrigin,
    inSync,
    differences,
  ];
}

/// A member of an event bill (BE MemberRef).
class BillMemberRef extends Equatable {
  const BillMemberRef({
    required this.id,
    required this.name,
    this.userId,
    this.iconCode,
    this.isMe = false,
  });

  final String id;
  final String name;
  final String? userId;
  final IconCode? iconCode;
  final bool isMe;

  factory BillMemberRef.fromJson(Map<String, dynamic> json) => BillMemberRef(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    userId: json['user_id'] as String?,
    iconCode: _icon(json['icon_code']),
    isMe: (json['is_me'] as bool?) ?? false,
  );

  @override
  List<Object?> get props => [id, name, userId, iconCode, isMe];
}

class BillShare extends Equatable {
  const BillShare({required this.member, required this.share});

  final BillMemberRef member;
  final double share;

  factory BillShare.fromJson(Map<String, dynamic> json) => BillShare(
    member: BillMemberRef.fromJson(
      (json['member'] as Map).cast<String, dynamic>(),
    ),
    share: (json['share'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [member, share];
}

/// Someone paid (part of) my expense (0.4.0-3 B1): [amount] = what they
/// paid, [myPaid] = what left my wallet (0 = none). The debt "I owe them"
/// is part of the tx: edit / delete it through the tx.
class TxPaidBy extends Equatable {
  const TxPaidBy({
    required this.debtId,
    required this.key,
    required this.person,
    required this.amount,
    required this.myPaid,
    this.fromPartner = false,
    this.paid = false,
  });

  final String debtId;

  /// The person page key (`n:lee` | `c:<id>`).
  final String key;
  final EmbeddedPerson person;
  final double amount;
  final double myPaid;

  /// A linked user's split on me, mirrored into my book: money / date /
  /// wallet follow their bill (locked).
  final bool fromPartner;

  /// The debt's "จ่ายแล้ว" label.
  final bool paid;

  factory TxPaidBy.fromJson(Map<String, dynamic> json) => TxPaidBy(
    debtId: json['debt_id'] as String,
    key: (json['key'] as String?) ?? '',
    person: EmbeddedPerson.fromJson(
      (json['person'] as Map? ?? const {}).cast<String, dynamic>(),
    ),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    myPaid: (json['my_paid'] as num?)?.toDouble() ?? 0,
    fromPartner: json['source'] == 'partner',
    paid: (json['paid'] as bool?) ?? false,
  );

  @override
  List<Object?> get props => [
    debtId,
    key,
    person,
    amount,
    myPaid,
    fromPartner,
    paid,
  ];
}

class EventRef extends Equatable {
  const EventRef({
    required this.id,
    required this.name,
    this.iconCode,
    this.status = 'active',
  });

  final String id;
  final String name;
  final IconCode? iconCode;
  final String status;

  factory EventRef.fromJson(Map<String, dynamic> json) => EventRef(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    iconCode: _icon(json['icon_code']),
    status: (json['status'] as String?) ?? 'active',
  );

  @override
  List<Object?> get props => [id, name, iconCode, status];
}

class EmbeddedPerson extends Equatable {
  const EmbeddedPerson({
    required this.name,
    this.contactId,
    this.iconCode,
    this.linked = false,
    this.linkedUserId,
  });

  final String name;
  final String? contactId;
  final IconCode? iconCode;
  final bool linked;
  final String? linkedUserId;

  factory EmbeddedPerson.fromJson(Map<String, dynamic> json) => EmbeddedPerson(
    name: (json['name'] as String?) ?? '',
    contactId: json['contact_id'] as String?,
    iconCode: _icon(json['icon_code']),
    linked: (json['linked'] as bool?) ?? false,
    linkedUserId: json['linked_user_id'] as String?,
  );

  @override
  List<Object?> get props => [name, contactId, iconCode, linked, linkedUserId];
}

class TransferPeer extends Equatable {
  const TransferPeer({
    required this.id,
    required this.isOut,
    required this.account,
  });

  final String id;
  final bool isOut;
  final AccountRef account;

  factory TransferPeer.fromJson(Map<String, dynamic> json) => TransferPeer(
    id: json['id'] as String,
    isOut: json['direction'] == 'out',
    account: AccountRef.fromJson(json['account'] as Map<String, dynamic>),
  );

  @override
  List<Object?> get props => [id, isOut, account];
}

class WalletBalance extends Equatable {
  const WalletBalance({required this.accountId, required this.balance});

  final String accountId;
  final double balance;

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
    accountId: json['account_id'] as String,
    balance: (json['balance'] as num).toDouble(),
  );

  static Map<String, double> mapOf(Object? json) => {
    if (json is List)
      for (final b in json.cast<Map<String, dynamic>>())
        b['account_id'] as String: (b['balance'] as num).toDouble(),
  };

  @override
  List<Object?> get props => [accountId, balance];
}
