import 'package:equatable/equatable.dart';

import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../projects/domain/project.dart';
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

  /// The form options built from the caches the app already holds: active wallets in the
  /// caller's order, the user's own categories as a tree walk (depth 1..3), tags as cached,
  /// and the events a bill can go to.
  factory TxFormOptions.fromCaches({
    required List<Account> accounts,
    required List<Category> categories,
    required List<Tag> tags,
    required List<Project> events,
    String? defaultAccountId,
    String? feeCategoryId,
  }) {
    return TxFormOptions(
      accounts: [
        for (final a in accounts)
          if (!a.isArchived)
            AccountOption(
              ref: AccountRef(
                id: a.id,
                name: a.name,
                iconCode: a.iconCode,
                logoUrl: a.logoUrl,
                type: a.type,
                group: a.isLiability ? 'liability' : 'asset',
                currency: a.currency,
              ),
              balance: a.balance,
              sortOrder: a.sortOrder,
              isDefault: a.id == defaultAccountId,
              trackBalance: a.trackBalance,
            ),
      ],
      defaultAccountId: defaultAccountId,
      categories: _categoryTree(categories),
      tags: tags,
      events: [
        for (final p in events)
          EventRef(
            id: p.id,
            name: p.name,
            iconCode: p.iconCode,
            status: p.status.wire,
          ),
      ],
      feeCategoryId: feeCategoryId,
    );
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

List<CategoryOption> _categoryTree(List<Category> all) {
  final mine = [
    for (final c in all)
      if (!c.isSystem) c,
  ];
  int order(Category a, Category b) {
    final t = a.type.name.compareTo(b.type.name);
    if (t != 0) return t;
    final s = a.sortOrder.compareTo(b.sortOrder);
    if (s != 0) return s;
    final created = (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    return created != 0 ? created : a.id.compareTo(b.id);
  }

  mine.sort(order);
  final ids = {for (final c in mine) c.id};
  final children = <String, List<Category>>{};
  final roots = <Category>[];
  for (final c in mine) {
    final p = c.parentId;
    if (p != null && ids.contains(p)) {
      (children[p] ??= []).add(c);
    } else {
      roots.add(c);
    }
  }
  final out = <CategoryOption>[];
  void walk(Category c, int depth, String? parentName) {
    if (depth > 3) return;
    out.add(
      CategoryOption(
        ref: EmbeddedCategory(
          id: c.id,
          name: c.name,
          type: c.type,
          iconCode: c.iconCode,
          isSystem: c.isSystem,
          systemKind: c.systemKind,
          parentId: c.parentId,
        ),
        sortOrder: c.sortOrder,
        depth: depth,
        parentName: parentName,
      ),
    );
    for (final child in children[c.id] ?? const <Category>[]) {
      walk(child, depth + 1, c.name);
    }
  }

  for (final r in roots) {
    walk(r, 1, null);
  }
  return out;
}
