import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_chip.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../tx_list_filters.dart';

// The pick rows the transaction form and the transactions filter share
// (owner 2026-10-10): [icon] chips … [เพิ่มเติม], the chips ranked by
// use from the cached transactions, that order frozen ([ChipOrder]).
// [leading] / [trailing] add the caller's own chips (the filter's
// "ทั้งหมด", a "ไม่ระบุหมวด" picked through เพิ่มเติม).

/// หมวด: the categories most used lately for [type] — the most frequent
/// of the latest 100 rows, ties to the most recent; topped up with the
/// type's categories in their own order, [max] in all. [type] null = both
/// types (the filter's "ทั้งหมด"). Tapping a chip calls [onPick];
/// "เพิ่มเติม" calls [onMore] (the full picker). [selected] not in the row
/// joins at its end.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    required this.type,
    required this.selected,
    required this.onPick,
    required this.onMore,
    required this.order,
    this.leading = const [],
    this.trailing = const [],
    this.max = 6,
    this.leadingIcon = true,
    super.key,
  });

  final TransactionType? type;
  final Category? selected;
  final ValueChanged<Category> onPick;
  final VoidCallback onMore;

  /// Keep one per [type] for the screen's life.
  final ChipOrder order;
  final List<Widget> leading;
  final List<Widget> trailing;
  final int max;

  /// False under a section title that shows the icon (the filter sheet).
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final all = context.watch<CategoriesCubit>().state.categories;
    final txs = context.watch<TransactionsCubit>().state.transactions;
    final usable = {
      for (final c in all)
        if (!c.isSystem && categoryFitsType(c, type)) c.id: c,
    };
    List<String> rank() {
      final counts = <String, int>{};
      final firstSeen = <String, int>{};
      var seen = 0;
      for (final t in txs) {
        if (seen >= 100) break;
        final id = t.categoryId;
        if ((type != null && t.type != type) ||
            id == null ||
            !usable.containsKey(id)) {
          continue;
        }
        seen++;
        counts.update(id, (n) => n + 1, ifAbsent: () => 1);
        firstSeen.putIfAbsent(id, () => seen);
      }
      final ranked = counts.keys.toList()
        ..sort((a, b) {
          final byCount = counts[b]!.compareTo(counts[a]!);
          return byCount != 0
              ? byCount
              : firstSeen[a]!.compareTo(firstSeen[b]!);
        });
      return _topUp(ranked, [
        for (final c
            in usable.values.toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
          c.id,
      ], max);
    }

    final sel = selected;
    final ids = order.ids(
      ready: usable.isNotEmpty,
      rank: rank,
      picked: [if (sel != null && usable.containsKey(sel.id)) sel.id],
    );
    return ChipRow(
      icon: leadingIcon ? AppIcons.category : null,
      moreLabel: l.commonMore,
      onMore: onMore,
      chips: [
        ...leading,
        for (final c in [for (final id in ids) ?usable[id]])
          CategoryChip(
            category: c,
            selected: c.id == sel?.id,
            onTap: () => onPick(c),
          ),
        ...trailing,
      ],
    );
  }
}

/// แท็ก: the ones picked when the screen opened, then the latest used to
/// make [shown], then by usage — that order frozen. Tapping toggles
/// ([onToggle]); "เพิ่มเติม" calls [onMore] (the full picker). [editing]
/// false = the row's own tags only, no เพิ่มเติม. [known] resolves picked
/// tags missing from this user's list (another member's, on a shared
/// wallet).
class TagChipRow extends StatelessWidget {
  const TagChipRow({
    required this.selected,
    required this.onToggle,
    required this.onMore,
    required this.order,
    this.editing = true,
    this.known = const {},
    this.leading = const [],
    this.shown = 3,
    this.leadingIcon = true,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onMore;
  final ChipOrder order;
  final bool editing;
  final Map<String, Tag> known;
  final List<Widget> leading;
  final int shown;

  /// False under a section title that shows the icon (the filter sheet).
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mine = context.watch<TagsCubit>().state.tags;
    final byId = {for (final t in mine) t.id: t};
    final txs = editing
        ? context.watch<TransactionsCubit>().state.transactions
        : const <Transaction>[];
    List<String> rank() {
      final picked = [
        for (final id in selected)
          if (byId.containsKey(id) || known.containsKey(id)) id,
      ];
      if (picked.length >= shown) return picked;
      // Latest used first (the cache is newest first), then by usage.
      final recent = <String>[];
      for (final t in txs) {
        for (final e in t.tags) {
          if (byId.containsKey(e.id) &&
              !selected.contains(e.id) &&
              !recent.contains(e.id)) {
            recent.add(e.id);
          }
        }
        if (recent.length >= shown) break;
      }
      final byUsage = mine.where((t) => !selected.contains(t.id)).toList()
        ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
      return _topUp(picked, [...recent, for (final t in byUsage) t.id], shown);
    }

    final ids = editing
        ? order.ids(ready: mine.isNotEmpty, rank: rank, picked: selected)
        : selected.toList();
    return ChipRow(
      icon: leadingIcon ? AppIcons.tag : null,
      moreLabel: l.commonMore,
      onMore: editing ? onMore : null,
      chips: [
        ...leading,
        for (final t in [for (final id in ids) ?(byId[id] ?? known[id])])
          TagChip(
            tag: t,
            selected: editing ? selected.contains(t.id) : null,
            onTap: editing ? () => onToggle(t.id) : null,
          ),
      ],
    );
  }
}

/// กระเป๋า: the wallets most used lately (latest 100 rows), topped up with
/// the rest in their own order, [max] in all — each in its own colour and
/// icon, that order frozen. Tapping calls [onPick]; "เพิ่มเติม" calls
/// [onMore] (the full list).
class WalletChipRow extends StatelessWidget {
  const WalletChipRow({
    required this.selectedId,
    required this.onPick,
    required this.onMore,
    required this.order,
    this.leading = const [],
    this.trailing = const [],
    this.max = 4,
    this.leadingIcon = true,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<Account> onPick;
  final VoidCallback onMore;
  final ChipOrder order;
  final List<Widget> leading;
  final List<Widget> trailing;
  final int max;

  /// False under a section title that shows the icon (the filter sheet).
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final txs = context.watch<TransactionsCubit>().state.transactions;
    final byId = {for (final a in accounts) a.id: a};
    List<String> rank() {
      final counts = <String, int>{};
      var seen = 0;
      for (final t in txs) {
        if (seen >= 100) break;
        final id = t.accountId;
        if (id == null || !byId.containsKey(id)) continue;
        seen++;
        counts.update(id, (n) => n + 1, ifAbsent: () => 1);
      }
      final ranked = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      return _topUp(ranked, [for (final a in accounts) a.id], max);
    }

    final sel = selectedId;
    final ids = order.ids(
      ready: accounts.isNotEmpty,
      rank: rank,
      picked: [if (sel != null && byId.containsKey(sel)) sel],
    );
    return ChipRow(
      icon: leadingIcon ? AppIcons.wallet : null,
      moreLabel: l.commonMore,
      onMore: onMore,
      chips: [
        ...leading,
        for (final a in [for (final id in ids) ?byId[id]])
          RowChip(
            label: a.name,
            icon: IconRegistry.get(a.iconCode?.icon, fallback: a.type.icon),
            color: a.iconCode?.accentColorFor(palette) ?? palette.primary,
            selected: a.id == sel,
            onTap: () => onPick(a),
          ),
        ...trailing,
      ],
    );
  }
}

/// [first], then [rest] not already in it, up to [max] — distinct.
List<String> _topUp(List<String> first, List<String> rest, int max) {
  final out = <String>[];
  for (final id in [...first, ...rest]) {
    if (out.length >= max) break;
    if (!out.contains(id)) out.add(id);
  }
  return out;
}
