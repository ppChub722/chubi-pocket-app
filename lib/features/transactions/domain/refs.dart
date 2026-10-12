import 'package:equatable/equatable.dart';

import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_type.dart';
import '../../../ui/ui.dart';

/// Shared embedded refs of API v2 (spec: AccountRef / EmbeddedCategory / EventRef /
/// EmbeddedPerson / TransferPeer / WalletBalance). Every row that points at a
/// wallet, category, event or person carries the display data itself, so the
/// FE never joins against the accounts / categories / contacts caches.

IconCode? _icon(Object? v) =>
    v is Map<String, dynamic> ? IconCode.fromJson(v) : null;

/// `AccountRef`: a wallet as shown on a row. No balance.
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

  /// `asset` | `liability` (computed by the BE).
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

  /// As a (balance-less) [Account], for pickers and prefill that take one.
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

/// `EmbeddedCategory`: a category as shown on a row. A sub-category carries its
/// own icon. `systemKind` is set on system categories only.
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

  /// OPENING_IN · OPENING_OUT · ADJUST_IN · ADJUST_OUT · TRANSFER_IN ·
  /// TRANSFER_OUT · DEBT_PAID · DEBT_RECEIVED, or null.
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

  /// As a [Category], for the shared label / icon helpers.
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

/// `EventRef`: an event (project) as shown on a row.
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

/// `EmbeddedPerson`: a person on a split / debt, name already resolved live by the
/// BE (nickname → linked profile name → contact name → snapshot). The FE
/// draws the person icon when [contactId] is null.
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

/// `TransferPeer`: the other side of a transfer row. [isOut] is for THIS row.
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

/// `WalletBalance`: a wallet's balance after a write.
class WalletBalance extends Equatable {
  const WalletBalance({required this.accountId, required this.balance});

  final String accountId;
  final double balance;

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
    accountId: json['account_id'] as String,
    balance: (json['balance'] as num).toDouble(),
  );

  /// `account_balances` of a write response → {account id: balance}, for
  /// `AccountsCubit.patchBalances`.
  static Map<String, double> mapOf(Object? json) => {
    if (json is List)
      for (final b in json.cast<Map<String, dynamic>>())
        b['account_id'] as String: (b['balance'] as num).toDouble(),
  };

  @override
  List<Object?> get props => [accountId, balance];
}
