import 'package:equatable/equatable.dart';

import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../tags/domain/tag.dart';
import 'refs.dart';

class AccountOption extends Equatable {
  const AccountOption({
    required this.ref,
    required this.balance,
    this.sortOrder = 0,
    this.isDefault = false,
    this.trackBalance = true,
  });

  final AccountRef ref;
  final double balance;

  final bool trackBalance;
  final int sortOrder;
  final bool isDefault;

  factory AccountOption.fromJson(Map<String, dynamic> json) => AccountOption(
    ref: AccountRef.fromJson(json),
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    isDefault: (json['is_default'] as bool?) ?? false,
    trackBalance: (json['track_balance'] as bool?) ?? true,
  );

  Account toAccount() =>
      ref.toAccount(balance: balance).copyWith(trackBalance: trackBalance);

  @override
  List<Object?> get props => [ref, balance, sortOrder, isDefault, trackBalance];
}

class CategoryOption extends Equatable {
  const CategoryOption({
    required this.ref,
    this.sortOrder = 0,
    this.depth = 1,
    this.parentName,
  });

  final EmbeddedCategory ref;
  final int sortOrder;
  final int depth;
  final String? parentName;

  factory CategoryOption.fromJson(Map<String, dynamic> json) => CategoryOption(
    ref: EmbeddedCategory.fromJson(json),
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    depth: (json['depth'] as num?)?.toInt() ?? 1,
    parentName: json['parent_name'] as String?,
  );

  Category toCategory() => ref.toCategory(sortOrder: sortOrder);

  @override
  List<Object?> get props => [ref, sortOrder, depth, parentName];
}

class TxFormOptions extends Equatable {
  const TxFormOptions({
    this.accounts = const [],
    this.defaultAccountId,
    this.categories = const [],
    this.tags = const [],
    this.events = const [],
    this.feeCategoryId,
  });

  final List<AccountOption> accounts;
  final String? defaultAccountId;
  final List<CategoryOption> categories;
  final List<Tag> tags;
  final List<EventRef> events;
  final String? feeCategoryId;

  List<Account> get accountList => [for (final a in accounts) a.toAccount()];
  List<Category> get categoryList => [
    for (final c in categories) c.toCategory(),
  ];

  Account? get defaultAccount {
    for (final a in accounts) {
      if (a.ref.id == defaultAccountId) return a.toAccount();
    }
    return null;
  }

  factory TxFormOptions.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String k) =>
        ((json[k] as List?) ?? const []).cast<Map<String, dynamic>>();
    return TxFormOptions(
      accounts: list('accounts').map(AccountOption.fromJson).toList(),
      defaultAccountId: json['default_account_id'] as String?,
      categories: list('categories').map(CategoryOption.fromJson).toList(),
      tags: list('tags').map(Tag.fromJson).toList(),
      events: list('events').map(EventRef.fromJson).toList(),
      feeCategoryId: json['fee_category_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    accounts,
    defaultAccountId,
    categories,
    tags,
    events,
    feeCategoryId,
  ];
}
