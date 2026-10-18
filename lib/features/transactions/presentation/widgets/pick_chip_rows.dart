import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_chip.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../tx_list_filters.dart';

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
    this.maxLines,
    this.pickLabel,
    super.key,
  });

  /// Non-null: the full-picker chip leads the row, dashed, with this text
  /// ("เลือกหมวด") instead of "เพิ่มเติม" at the end — the pending form.
  final String? pickLabel;

  final TransactionType? type;
  final Category? selected;
  final ValueChanged<Category> onPick;
  final VoidCallback onMore;

  final ChipOrder order;
  final List<Widget> leading;
  final List<Widget> trailing;
  final int max;

  final bool leadingIcon;

  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final opts = maybeTxFormOptions(context);
    final catState = opts == null
        ? context.watch<CategoriesCubit>().state
        : null;
    final all = opts == null
        ? catState!.categories
        : (opts.state.options?.categoryList ?? const <Category>[]);
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
    final loading = opts == null
        ? all.isEmpty &&
              (catState!.status == CategoriesStatus.initial ||
                  catState.status == CategoriesStatus.loading)
        : opts.state.isLoading;
    return _EnsureLoaded(
      load: (c) => opts == null
          ? c.read<CategoriesCubit>().loadIfNeeded()
          : opts.loadIfNeeded(),
      child: ChipRow(
        icon: leadingIcon ? AppIcons.category : null,
        moreLabel: pickLabel ?? l.commonMore,
        onMore: pickLabel != null ? null : onMore,
        maxLines: maxLines,
        chips: [
          if (pickLabel != null)
            sel != null
                ? categoryAppChip(
                    context,
                    sel,
                    all: all,
                    selected: true,
                    onTap: onMore,
                    dashed: true,
                  )
                : AppChip(
                    label: pickLabel!,
                    icon: AppIcons.add,
                    tone: AppChipTone.primary,
                    selected: true,
                    dashed: true,
                    onTap: onMore,
                  ),
          ...leading,
          if (loading) ..._skeletonChips(context),
          for (final c in [
            for (final id in ids)
              if (pickLabel == null || id != sel?.id) ?usable[id],
          ])
            categoryAppChip(
              context,
              c,
              all: all,
              selected: c.id == sel?.id,
              onTap: () => onPick(c),
              dashed: true,
            ),
          ...trailing,
        ],
      ),
    );
  }
}

class TagChipRow extends StatelessWidget {
  const TagChipRow({
    required this.selected,
    required this.onRemove,
    required this.onMore,
    this.editing = true,
    this.known = const {},
    this.leading = const [],
    this.leadingIcon = true,
    this.maxLines,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<String> onRemove;
  final VoidCallback onMore;
  final bool editing;
  final Map<String, Tag> known;
  final List<Widget> leading;

  final bool leadingIcon;

  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final opts = maybeTxFormOptions(context);
    final tagState = opts == null ? context.watch<TagsCubit>().state : null;
    final mine = opts == null
        ? tagState!.tags
        : (opts.state.options?.tags ?? const <Tag>[]);
    final byId = {for (final t in mine) t.id: t};
    final loading = opts == null
        ? mine.isEmpty &&
              (tagState!.status == TagsStatus.initial ||
                  tagState.status == TagsStatus.loading)
        : opts.state.isLoading;
    return _EnsureLoaded(
      load: (c) => opts == null
          ? c.read<TagsCubit>().loadIfNeeded()
          : opts.loadIfNeeded(),
      child: ChipRow(
        icon: leadingIcon ? AppIcons.tag : null,
        moreLabel: l.commonMore,
        onMore: editing ? onMore : null,
        maxLines: maxLines,
        chips: [
          ...leading,
          if (loading) ..._skeletonChips(context),
          for (final id in selected)
            if (byId[id] ?? known[id] case final t?)
              tagAppChip(
                context,
                t,
                selected: true,
                onRemove: editing ? () => onRemove(t.id) : null,
              ),
        ],
      ),
    );
  }
}

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
    this.maxLines,
    this.pickLabel,
    this.excludeId,
    super.key,
  });

  final String? pickLabel;

  final String? excludeId;

  final String? selectedId;
  final ValueChanged<Account> onPick;
  final VoidCallback onMore;
  final ChipOrder order;
  final List<Widget> leading;
  final List<Widget> trailing;
  final int max;

  final bool leadingIcon;

  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final opts = maybeTxFormOptions(context);
    final accState = opts == null ? context.watch<AccountsCubit>().state : null;
    final accounts = opts == null
        ? accState!.accounts
        : (opts.state.options?.accountList ?? const <Account>[]);
    final txs = context.watch<TransactionsCubit>().state.transactions;
    final byId = {
      for (final a in accounts)
        if (a.id != excludeId) a.id: a,
    };
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
    final loading = opts == null
        ? accounts.isEmpty &&
              (accState!.status == AccountsStatus.initial ||
                  accState.status == AccountsStatus.loading)
        : opts.state.isLoading;
    return _EnsureLoaded(
      load: (c) => opts == null
          ? c.read<AccountsCubit>().loadIfNeeded()
          : opts.loadIfNeeded(),
      child: ChipRow(
        icon: leadingIcon ? AppIcons.wallet : null,
        moreLabel: pickLabel ?? l.commonMore,
        onMore: pickLabel != null ? null : onMore,
        maxLines: maxLines,
        chips: [
          if (pickLabel != null)
            byId[sel] != null
                ? _walletChip(
                    byId[sel]!,
                    palette,
                    selected: true,
                    onTap: onMore,
                  )
                : AppChip(
                    label: pickLabel!,
                    icon: AppIcons.add,
                    tone: AppChipTone.primary,
                    selected: true,
                    dashed: true,
                    onTap: onMore,
                  ),
          ...leading,
          if (loading) ..._skeletonChips(context),
          for (final a in [
            for (final id in ids)
              if (pickLabel == null || id != sel) ?byId[id],
          ])
            _walletChip(
              a,
              palette,
              selected: a.id == sel,
              onTap: () => onPick(a),
            ),
          ...trailing,
        ],
      ),
    );
  }
}

class _EnsureLoaded extends StatefulWidget {
  const _EnsureLoaded({required this.load, required this.child});

  final Future<void> Function(BuildContext context) load;
  final Widget child;

  @override
  State<_EnsureLoaded> createState() => _EnsureLoadedState();
}

class _EnsureLoadedState extends State<_EnsureLoaded> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.load(context));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

List<Widget> _skeletonChips(
  BuildContext context, {
  ChipSize size = ChipSize.control,
}) => [
  for (final w in const [72.0, 56.0, 64.0])
    SkeletonBox(width: w, height: size.heightOf(context), borderRadius: 999),
];

List<String> _topUp(List<String> first, List<String> rest, int max) {
  final out = <String>[];
  for (final id in [...first, ...rest]) {
    if (out.length >= max) break;
    if (!out.contains(id)) out.add(id);
  }
  return out;
}

AppChip _walletChip(
  Account a,
  AppColors palette, {
  required bool selected,
  required VoidCallback? onTap,
}) => AppChip(
  label: a.name,
  icon: IconRegistry.get(a.iconCode?.icon, fallback: a.type.icon),
  color: a.iconCode.tintFor(palette),
  selected: selected,
  onTap: onTap,
  dashed: true,
  inset: selected,
);
