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
  });

  final String itemId;

  final String? recurringId;
  final String? recurringName;
  final IconCode? recurringIconCode;
  final int? seq;
  final int? total;

  factory RecurringItemLink.fromJson(Map<String, dynamic> json) {
    final r = json['recurring'];
    final rec = r is Map ? r.cast<String, dynamic>() : null;
    return RecurringItemLink(
      itemId: json['item_id'] as String,
      recurringId: rec?['id'] as String?,
      recurringName: rec?['name'] as String?,
      recurringIconCode: _icon(rec?['icon_code']),
      seq: (json['seq'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
    );
  }

  String label(String fallback) => [
    recurringName ?? fallback,
    if (seq != null && total != null) '$seq/$total',
  ].join(' · ');

  @override
  List<Object?> get props => [
    itemId,
    recurringId,
    recurringName,
    recurringIconCode,
    seq,
    total,
  ];
}

class EventBillLink extends Equatable {
  const EventBillLink({
    required this.event,
    required this.billId,
    this.linked = false,
  });

  final EventRef event;
  final String billId;
  final bool linked;

  factory EventBillLink.fromJson(Map<String, dynamic> json) => EventBillLink(
    event: EventRef.fromJson((json['event'] as Map).cast<String, dynamic>()),
    billId: json['bill_id'] as String,
    linked: (json['linked'] as bool?) ?? false,
  );

  @override
  List<Object?> get props => [event, billId, linked];
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
