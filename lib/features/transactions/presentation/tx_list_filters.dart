import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_type.dart';
import '../../tags/domain/tag.dart';
import '../domain/transaction_type.dart';

bool categoryFitsType(Category c, TransactionType? type) => switch (type) {
  null => true,
  TransactionType.income => c.type == CategoryType.income,
  TransactionType.expense => c.type == CategoryType.expense,
  TransactionType.transfer => false,
};

enum TxPeriodKind { day, week, month, year, all, custom }

@immutable
class TxPeriod {
  const TxPeriod._(this.kind, this.start, [this.end]);

  factory TxPeriod.day(DateTime day) =>
      TxPeriod._(TxPeriodKind.day, DateTime(day.year, day.month, day.day));

  factory TxPeriod.month(DateTime day) =>
      TxPeriod._(TxPeriodKind.month, DateTime(day.year, day.month));

  factory TxPeriod.week(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return TxPeriod._(
      TxPeriodKind.week,
      d.subtract(Duration(days: d.weekday - 1)),
    );
  }

  factory TxPeriod.year(DateTime day) =>
      TxPeriod._(TxPeriodKind.year, DateTime(day.year));

  static final all = TxPeriod._(TxPeriodKind.all, DateTime(0));

  factory TxPeriod.custom(DateTime from, DateTime to) => TxPeriod._(
    TxPeriodKind.custom,
    DateTime(from.year, from.month, from.day),
    DateTime(to.year, to.month, to.day),
  );

  factory TxPeriod.of(TxPeriodKind kind, DateTime day) => switch (kind) {
    TxPeriodKind.day => TxPeriod.day(day),
    TxPeriodKind.month => TxPeriod.month(day),
    TxPeriodKind.week => TxPeriod.week(day),
    TxPeriodKind.year => TxPeriod.year(day),
    TxPeriodKind.all => TxPeriod.all,
    TxPeriodKind.custom => TxPeriod.custom(day, day),
  };

  final TxPeriodKind kind;
  final DateTime start;
  final DateTime? end;

  DateTime? get last => switch (kind) {
    TxPeriodKind.day => start,
    TxPeriodKind.month => DateTime(start.year, start.month + 1, 0),
    TxPeriodKind.week => start.add(const Duration(days: 6)),
    TxPeriodKind.year => DateTime(start.year, 12, 31),
    TxPeriodKind.custom => end,
    TxPeriodKind.all => null,
  };

  ({String? from, String? to}) get bounds => kind == TxPeriodKind.all
      ? (from: null, to: null)
      : (from: _ymd(start), to: _ymd(last!));

  TxPeriod? step(int dir) => switch (kind) {
    TxPeriodKind.day => TxPeriod.day(
      DateTime(start.year, start.month, start.day + dir),
    ),
    TxPeriodKind.month => TxPeriod.month(
      DateTime(start.year, start.month + dir),
    ),
    TxPeriodKind.week => TxPeriod.week(start.add(Duration(days: 7 * dir))),
    TxPeriodKind.year => TxPeriod.year(DateTime(start.year + dir)),
    TxPeriodKind.all || TxPeriodKind.custom => null,
  };

  String label(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return switch (kind) {
      TxPeriodKind.day => DateFormat.yMMMEd(locale).format(start),
      TxPeriodKind.month => DateFormat.yMMMM(locale).format(start),
      TxPeriodKind.year => DateFormat.y(locale).format(start),
      TxPeriodKind.all => l.transactionsRangeAll,
      TxPeriodKind.week || TxPeriodKind.custom =>
        '${DateFormat.MMMd(locale).format(start)} – '
            '${DateFormat.yMMMd(locale).format(last!)}',
    };
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is TxPeriod &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}

@immutable
class TxFilters {
  const TxFilters({
    required this.period,
    this.types = const {},
    this.wallets = const [],
    this.noWallet = false,
    this.categories = const [],
    this.uncategorized = false,
    this.tags = const [],
    this.noTags = false,
    this.amountMin,
    this.amountMax,
    this.sort = 'date_desc',
  });

  final TxPeriod period;
  final Set<TransactionType> types;

  /// Wallets, and/or [noWallet] (rows without one).
  final List<Account> wallets;
  final bool noWallet;

  final List<Category> categories;
  final bool uncategorized;

  /// Tags, and/or [noTags] (rows without any).
  final List<Tag> tags;
  final bool noTags;

  final double? amountMin;
  final double? amountMax;
  final String sort;

  TxFilters copyWith({
    TxPeriod? period,
    Set<TransactionType>? types,
    List<Account>? wallets,
    bool? noWallet,
    List<Category>? categories,
    bool? uncategorized,
    List<Tag>? tags,
    bool? noTags,
    ({double? min, double? max})? amount,
    String? sort,
  }) => TxFilters(
    period: period ?? this.period,
    types: types ?? this.types,
    wallets: wallets ?? this.wallets,
    noWallet: noWallet ?? this.noWallet,
    categories: categories ?? this.categories,
    uncategorized: uncategorized ?? this.uncategorized,
    tags: tags ?? this.tags,
    noTags: noTags ?? this.noTags,
    amountMin: amount == null ? amountMin : amount.min,
    amountMax: amount == null ? amountMax : amount.max,
    sort: sort ?? this.sort,
  );

  static Set<String> _ids(Iterable<Object> xs, String Function(Object) id) => {
    for (final x in xs) id(x),
  };

  bool sameFiltersAs(TxFilters o) =>
      setEquals(o.types, types) &&
      o.noWallet == noWallet &&
      o.uncategorized == uncategorized &&
      o.noTags == noTags &&
      o.amountMin == amountMin &&
      o.amountMax == amountMax &&
      o.sort == sort &&
      setEquals(
        _ids(o.wallets, (a) => (a as Account).id),
        _ids(wallets, (a) => (a as Account).id),
      ) &&
      setEquals(
        _ids(o.categories, (c) => (c as Category).id),
        _ids(categories, (c) => (c as Category).id),
      ) &&
      setEquals(
        _ids(o.tags, (t) => (t as Tag).id),
        _ids(tags, (t) => (t as Tag).id),
      );

  int activeCount(TxFilters base) {
    int extra(Set<Object> now, Set<Object> was) =>
        now.where((x) => !was.contains(x)).length;
    return extra(types, base.types) +
        extra(
          {for (final w in wallets) w.id},
          {for (final w in base.wallets) w.id},
        ) +
        (noWallet && !base.noWallet ? 1 : 0) +
        extra(
          {for (final c in categories) c.id},
          {for (final c in base.categories) c.id},
        ) +
        (uncategorized && !base.uncategorized ? 1 : 0) +
        extra({for (final t in tags) t.id}, {for (final t in base.tags) t.id}) +
        (noTags && !base.noTags ? 1 : 0) +
        ((amountMin != null || amountMax != null) &&
                base.amountMin == null &&
                base.amountMax == null
            ? 1
            : 0);
  }
}

/// The list's sorts (wire values), first = the default.
const txSorts = ['date_desc', 'date_asc', 'amount_desc', 'amount_asc'];

/// The token in a remembered id set for rows without a wallet / category /
/// tag.
const _none = 'none';

/// [f]'s remembered part (page_prefs `transactions`, 0.4.2-1): the sort and
/// every filter as small strings; never the period (it starts fresh).
Map<String, Object?> txFiltersPref(TxFilters f) => {
  'sort': f.sort,
  'types': [
    for (final t in TransactionType.values)
      if (f.types.contains(t)) t.name,
  ],
  'wallets': [for (final w in f.wallets) w.id, if (f.noWallet) _none],
  'categories': [
    for (final c in f.categories) c.id,
    if (f.uncategorized) _none,
  ],
  'tags': [for (final t in f.tags) t.id, if (f.noTags) _none],
  'amount': [
    if (f.amountMin != null) 'min:${f.amountMin}',
    if (f.amountMax != null) 'max:${f.amountMax}',
  ],
};

/// The choices remembered in [pref] on [base]'s period (a missing filter =
/// none; a missing sort = [base]'s). Ids resolve to the [accounts] /
/// [categories] / [tags] the app already holds; an unknown one is kept as a
/// bare id (the request only needs ids; the filter sheet fills in the
/// names). Unknown values are skipped.
TxFilters txFiltersFromPref(
  TxFilters base,
  Map<String, dynamic> pref, {
  Iterable<Account> accounts = const [],
  Iterable<Category> categories = const [],
  Iterable<Tag> tags = const [],
}) {
  if (pref.isEmpty) return base;
  List<String> strings(String key) => [
    for (final v in pref[key] is List ? pref[key] as List : const [])
      if (v is String) v,
  ];
  List<String> ids(String key) => [
    for (final v in strings(key))
      if (v != _none) v,
  ];
  bool none(String key) => strings(key).contains(_none);
  final byWallet = {for (final a in accounts) a.id: a};
  final byCategory = {for (final c in categories) c.id: c};
  final byTag = {for (final t in tags) t.id: t};
  final types = TransactionType.values.asNameMap();
  double? bound(String prefix) {
    for (final v in strings('amount')) {
      if (v.startsWith(prefix)) {
        return double.tryParse(v.substring(prefix.length));
      }
    }
    return null;
  }

  final sort = pref['sort'];
  return base.copyWith(
    sort: txSorts.contains(sort) ? sort as String : base.sort,
    types: {
      for (final t in strings('types'))
        if (types[t] != null) types[t]!,
    },
    wallets: [
      for (final id in ids('wallets'))
        byWallet[id] ??
            Account(
              id: id,
              name: '',
              type: AccountType.cash,
              balance: 0,
              currency: '',
            ),
    ],
    noWallet: none('wallets'),
    categories: [
      for (final id in ids('categories'))
        byCategory[id] ??
            Category(id: id, name: '', type: CategoryType.expense),
    ],
    uncategorized: none('categories'),
    tags: [for (final id in ids('tags')) byTag[id] ?? Tag(id: id, name: '')],
    noTags: none('tags'),
    amount: (min: bound('min:'), max: bound('max:')),
  );
}
