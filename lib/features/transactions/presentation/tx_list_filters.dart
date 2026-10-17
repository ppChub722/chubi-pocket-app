import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_type.dart';
import '../../tags/domain/tag.dart';
import '../domain/transaction_type.dart';

/// A category belongs to one type — does [c] fit [type]? (null = any.)
bool categoryFitsType(Category c, TransactionType? type) => switch (type) {
  null => true,
  TransactionType.income => c.type == CategoryType.income,
  TransactionType.expense => c.type == CategoryType.expense,
  TransactionType.transfer => false,
};

/// The unit a transactions list period is measured in.
enum TxPeriodKind { day, week, month, year, all, custom }

/// The list's period — what the pill on top shows and steps (owner
/// 2026-10-10). [start] is the day, or the first day of the week (Monday)
/// / month / year; a custom range runs [start]..[end].
@immutable
class TxPeriod {
  const TxPeriod._(this.kind, this.start, [this.end]);

  /// One day.
  factory TxPeriod.day(DateTime day) =>
      TxPeriod._(TxPeriodKind.day, DateTime(day.year, day.month, day.day));

  /// The month holding [day].
  factory TxPeriod.month(DateTime day) =>
      TxPeriod._(TxPeriodKind.month, DateTime(day.year, day.month));

  /// The Monday-to-Sunday week holding [day].
  factory TxPeriod.week(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return TxPeriod._(
      TxPeriodKind.week,
      d.subtract(Duration(days: d.weekday - 1)),
    );
  }

  /// The year holding [day].
  factory TxPeriod.year(DateTime day) =>
      TxPeriod._(TxPeriodKind.year, DateTime(day.year));

  /// Everything.
  static final all = TxPeriod._(TxPeriodKind.all, DateTime(0));

  /// [from]..[to], both days included.
  factory TxPeriod.custom(DateTime from, DateTime to) => TxPeriod._(
    TxPeriodKind.custom,
    DateTime(from.year, from.month, from.day),
    DateTime(to.year, to.month, to.day),
  );

  /// The [kind] period holding [day] (custom / all aren't anchored).
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

  /// The last day included (null = open: [TxPeriodKind.all]).
  DateTime? get last => switch (kind) {
    TxPeriodKind.day => start,
    TxPeriodKind.month => DateTime(start.year, start.month + 1, 0),
    TxPeriodKind.week => start.add(const Duration(days: 6)),
    TxPeriodKind.year => DateTime(start.year, 12, 31),
    TxPeriodKind.custom => end,
    TxPeriodKind.all => null,
  };

  /// `from` / `to` for the API (`YYYY-MM-DD`; nulls = open).
  ({String? from, String? to}) get bounds => kind == TxPeriodKind.all
      ? (from: null, to: null)
      : (from: _ymd(start), to: _ymd(last!));

  /// The neighbouring period [dir] steps away (−1 back, +1 forward), or
  /// null for one with no neighbours (ทั้งหมด, a custom range).
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

  /// Forward stops at the period holding today (nothing's ahead of it).
  bool canStepForward(DateTime today) {
    final next = step(1);
    return next != null && !next.start.isAfter(today);
  }

  /// The pill's text.
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

/// Everything the filter sheet sets (search stays in the page's field).
/// Every group takes SEVERAL values: OR-ed inside the group (wallet KBank OR
/// cash OR no wallet), AND-ed between groups; an empty group = no filter.
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
    this.sort = 'date_desc',
  });

  final TxPeriod period;
  final Set<TransactionType> types;

  /// Wallets, and/or [noWallet] (rows without one).
  final List<Account> wallets;
  final bool noWallet;

  /// Categories (each with its sub-categories), and/or [uncategorized].
  final List<Category> categories;
  final bool uncategorized;

  /// Tags, and/or [noTags] (rows without any).
  final List<Tag> tags;
  final bool noTags;
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
    sort: sort ?? this.sort,
  );

  static Set<String> _ids(Iterable<Object> xs, String Function(Object) id) => {
    for (final x in xs) id(x),
  };

  /// The same filters, ignoring the period (the pill owns it).
  bool sameFiltersAs(TxFilters o) =>
      setEquals(o.types, types) &&
      o.noWallet == noWallet &&
      o.uncategorized == uncategorized &&
      o.noTags == noTags &&
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

  /// How many values are on beyond how the page opened [base] (what the
  /// "ตัวกรอง" button counts).
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
        extra(
          {for (final t in tags) t.id},
          {for (final t in base.tags) t.id},
        ) +
        (noTags && !base.noTags ? 1 : 0);
  }
}
