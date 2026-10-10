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
enum TxPeriodKind { month, week, year, all, custom }

/// The list's period — what the pill on top shows and steps (owner
/// 2026-10-10). [start] is the first day of the month / week (Monday) /
/// year; a custom range runs [start]..[end].
@immutable
class TxPeriod {
  const TxPeriod._(this.kind, this.start, [this.end]);

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

/// Wallet filter: everything, rows with no wallet only, or one wallet.
sealed class TxWalletFilter {
  const TxWalletFilter();
}

class TxAnyWallet extends TxWalletFilter {
  const TxAnyWallet();

  @override
  bool operator ==(Object other) => other is TxAnyWallet;

  @override
  int get hashCode => 0;
}

class TxNoWallet extends TxWalletFilter {
  const TxNoWallet();

  @override
  bool operator ==(Object other) => other is TxNoWallet;

  @override
  int get hashCode => 1;
}

class TxOneWallet extends TxWalletFilter {
  const TxOneWallet(this.account);
  final Account account;

  @override
  bool operator ==(Object other) =>
      other is TxOneWallet && other.account.id == account.id;

  @override
  int get hashCode => account.id.hashCode;
}

/// Everything the filter sheet sets (search stays in the page's field).
@immutable
class TxFilters {
  const TxFilters({
    required this.period,
    this.type,
    this.wallet = const TxAnyWallet(),
    this.category,
    this.uncategorized = false,
    this.tags = const [],
    this.sort = 'date_desc',
  });

  final TxPeriod period;
  final TransactionType? type;
  final TxWalletFilter wallet;

  /// With its sub-categories. Exclusive with [uncategorized].
  final Category? category;

  /// Only rows without a category ("ไม่ระบุหมวด").
  final bool uncategorized;
  final List<Tag> tags;
  final String sort;

  TxFilters copyWith({
    TxPeriod? period,
    TransactionType? type,
    bool clearType = false,
    TxWalletFilter? wallet,
    Category? category,
    bool clearCategory = false,
    bool? uncategorized,
    List<Tag>? tags,
    String? sort,
  }) => TxFilters(
    period: period ?? this.period,
    type: clearType ? null : (type ?? this.type),
    wallet: wallet ?? this.wallet,
    category: clearCategory ? null : (category ?? this.category),
    uncategorized: uncategorized ?? this.uncategorized,
    tags: tags ?? this.tags,
    sort: sort ?? this.sort,
  );

  /// The same filters, ignoring the period (the pill owns it).
  bool sameFiltersAs(TxFilters o) =>
      o.type == type &&
      o.wallet == wallet &&
      o.category?.id == category?.id &&
      o.uncategorized == uncategorized &&
      o.sort == sort &&
      o.tags.map((t) => t.id).toSet().containsAll(tags.map((t) => t.id)) &&
      o.tags.length == tags.length;
}
