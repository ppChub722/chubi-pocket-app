import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../domain/transaction_type.dart';
import '../tx_list_filters.dart';
import 'pick_chip_rows.dart';
import 'tx_hero_card.dart';

/// The transactions list's filters, in a side sheet from the right (owner
/// 2026-10-10), built from the form's own pieces:
/// - ประเภท: [RowChip]s tinted in each type's colour, ทั้งหมด in primary;
/// - กระเป๋า · หมวด · แท็ก: the form's chip rows ([WalletChipRow],
///   [CategoryChipRow], [TagChipRow]), each led by "ทั้งหมด" (= no filter);
///   wallet / category pick one (tap again → ทั้งหมด), tags several;
///   เพิ่มเติม opens the full list (with ไม่มีกระเป๋า / ไม่ระบุหมวด);
/// then [ล้าง] [ใช้ตัวกรอง]. The period and the sort live on the page
/// (its pill and ⇅) — the sheet carries them through untouched.
///
/// Resolves the new filters, or null when closed without applying. ล้าง
/// goes back to [base] (how the list opened — a wallet's list keeps its
/// wallet) but keeps the page's period and sort; [walletLocked] hides the
/// wallet section (a wallet's own list).
Future<TxFilters?> showTxFilterSheet(
  BuildContext context, {
  required TxFilters current,
  required TxFilters base,
  bool walletLocked = false,
}) => showSideSheet<TxFilters>(
  context,
  builder: (_) =>
      _TxFilterSheet(initial: current, base: base, walletLocked: walletLocked),
);

/// The category choice: ทั้งหมด (null, false) · ไม่ระบุหมวด (null, true) ·
/// a category (with its sub-categories). Null when dismissed.
Future<({Category? category, bool uncategorized})?> pickCategoryFilter(
  BuildContext context, {
  required TransactionType? type,
  required Category? selected,
  required bool uncategorized,
}) async {
  final l = AppLocalizations.of(context)!;
  final pool = context
      .read<CategoriesCubit>()
      .state
      .categories
      .where((c) => !c.isSystem && categoryFitsType(c, type))
      .toList();
  int order(Category a, Category b) => a.sortOrder.compareTo(b.sortOrder);
  final roots = pool.where((c) => c.parentId == null).toList()..sort(order);
  final byId = {for (final c in pool) c.id: c};
  String typeOf(Category c) => c.type == CategoryType.income
      ? l.transactionTypeIncome
      : l.transactionTypeExpense;
  final picked = await showOptionSheet<String>(
    context,
    title: l.transactionsFilterCategory,
    searchable: pool.length > 8,
    selected: uncategorized ? '-' : selected?.id ?? '*',
    options: [
      SheetOption(value: '*', label: l.transactionsListFilterAll),
      SheetOption(
        value: '-',
        label: l.homeUncategorized,
        leading: const Icon(AppIcons.noCategory),
      ),
      for (final root in roots) ...[
        SheetOption(
          value: root.id,
          label: root.name,
          subtitle: type == null ? typeOf(root) : null,
        ),
        for (final child
            in pool.where((c) => c.parentId == root.id).toList()..sort(order))
          SheetOption(value: child.id, label: child.name, subtitle: root.name),
      ],
    ],
  );
  if (picked == null) return null;
  return (category: byId[picked], uncategorized: picked == '-');
}

/// The wallet choice. Null when dismissed.
Future<TxWalletFilter?> pickWalletFilter(
  BuildContext context, {
  required TxWalletFilter selected,
}) async {
  final l = AppLocalizations.of(context)!;
  final accounts = context.read<AccountsCubit>().state.accounts;
  final picked = await showOptionSheet<String>(
    context,
    title: l.transactionsFilterAccount,
    selected: switch (selected) {
      TxAnyWallet() => '*',
      TxNoWallet() => '-',
      TxOneWallet(:final account) => account.id,
    },
    options: [
      SheetOption(value: '*', label: l.transactionsListFilterAll),
      SheetOption(
        value: '-',
        label: l.transactionFormAccountNone,
        leading: const Icon(AppIcons.noWallet),
      ),
      for (final a in accounts)
        SheetOption(value: a.id, label: a.name, leading: Icon(a.type.icon)),
    ],
  );
  return switch (picked) {
    null => null,
    '*' => const TxAnyWallet(),
    '-' => const TxNoWallet(),
    _ => TxOneWallet(accounts.firstWhere((a) => a.id == picked)),
  };
}

/// Labels the list and the sheet share.
String txTypeLabel(AppLocalizations l, TransactionType? t) => switch (t) {
  null => l.transactionsListFilterAll,
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};

String txSortLabel(AppLocalizations l, String sort) => switch (sort) {
  'date_asc' => l.transactionsSortOldest,
  'amount_desc' => l.transactionsSortAmountHigh,
  'amount_asc' => l.transactionsSortAmountLow,
  _ => l.transactionsSortNewest,
};

String? txWalletLabel(AppLocalizations l, TxWalletFilter w) => switch (w) {
  TxAnyWallet() => null,
  TxNoWallet() => l.transactionFormAccountNone,
  TxOneWallet(:final account) => account.name,
};

class _TxFilterSheet extends StatefulWidget {
  const _TxFilterSheet({
    required this.initial,
    required this.base,
    required this.walletLocked,
  });

  final TxFilters initial;
  final TxFilters base;
  final bool walletLocked;

  @override
  State<_TxFilterSheet> createState() => _TxFilterSheetState();
}

class _TxFilterSheetState extends State<_TxFilterSheet> {
  late TxFilters _f = widget.initial;

  /// The chip rows' orders, fixed while the sheet is open (categories: one
  /// per type filter) — see [ChipOrder].
  final _categoryOrders = <TransactionType?, ChipOrder>{};
  final _walletOrder = ChipOrder();
  final _tagOrder = ChipOrder();

  void _set(TxFilters f) => setState(() => _f = f);

  void _setType(TransactionType? t) {
    final keep = _f.category == null || categoryFitsType(_f.category!, t);
    _set(_f.copyWith(type: t, clearType: t == null, clearCategory: !keep));
  }

  void _setCategory(Category? c, {bool uncategorized = false}) => _set(
    _f.copyWith(
      category: c,
      clearCategory: c == null,
      uncategorized: uncategorized,
    ),
  );

  void _toggleTag(String id) {
    final on = _f.tags.any((t) => t.id == id);
    final tag = context.read<TagsCubit>().state.tags.where((t) => t.id == id);
    _set(
      _f.copyWith(
        tags: on
            ? [
                for (final t in _f.tags)
                  if (t.id != id) t,
              ]
            : [..._f.tags, ...tag],
      ),
    );
  }

  Future<void> _moreTags() async {
    final l = AppLocalizations.of(context)!;
    final tagsCubit = context.read<TagsCubit>();
    final ids = await showTagPickerSheet(
      context,
      selected: {for (final t in _f.tags) t.id},
      title: l.transactionsFilterTag,
      allowCreate: false,
    );
    if (ids == null || !mounted) return;
    _set(
      _f.copyWith(
        tags: [
          for (final t in tagsCubit.state.tags)
            if (ids.contains(t.id)) t,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wallet = _f.wallet;
    // "ทั้งหมด" leads each pick row — selected = no filter there.
    RowChip all({required bool selected, required VoidCallback onTap}) =>
        RowChip(
          label: l.transactionsListFilterAll,
          selected: selected,
          onTap: onTap,
        );
    return SideSheetScaffold(
      title: l.transactionsFiltersTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Every row the same (owner 2026-10-10): the icon goes in front
          // of the section title, the chips start flush left, one chip
          // geometry ([RowChip]). Types: selected = a tint of their own
          // colour — ทั้งหมด primary, รายจ่าย red, รายรับ green, โอน grey.
          SideSheetSection(
            title: l.transactionsFilterType,
            icon: AppIcons.transfer,
            child: ChipRow(
              chips: [
                for (final t in const [
                  null,
                  TransactionType.expense,
                  TransactionType.income,
                  TransactionType.transfer,
                ])
                  RowChip(
                    label: txTypeLabel(l, t),
                    icon: switch (t) {
                      null => null,
                      TransactionType.expense => AppIcons.expense,
                      TransactionType.income => AppIcons.income,
                      TransactionType.transfer => AppIcons.transfer,
                    },
                    // Null = the app primary (ทั้งหมด).
                    color: t == null ? null : txTypeColor(context, t),
                    selected: t == _f.type,
                    onTap: t == _f.type ? null : () => _setType(t),
                  ),
              ],
            ),
          ),
          // One wallet, or none; "ไม่มีกระเป๋า" lives in เพิ่มเติม's list.
          if (!widget.walletLocked)
            SideSheetSection(
              title: l.transactionsFilterAccount,
              icon: AppIcons.wallet,
              child: WalletChipRow(
                leadingIcon: false,
                selectedId: wallet is TxOneWallet ? wallet.account.id : null,
                order: _walletOrder,
                onPick: (a) => _set(
                  _f.copyWith(
                    wallet: wallet is TxOneWallet && wallet.account.id == a.id
                        ? const TxAnyWallet()
                        : TxOneWallet(a),
                  ),
                ),
                onMore: () async {
                  final w = await pickWalletFilter(context, selected: wallet);
                  if (w != null && mounted) _set(_f.copyWith(wallet: w));
                },
                leading: [
                  all(
                    selected: wallet is TxAnyWallet,
                    onTap: () => _set(_f.copyWith(wallet: const TxAnyWallet())),
                  ),
                ],
                trailing: [
                  if (wallet is TxNoWallet)
                    RowChip(
                      label: l.transactionFormAccountNone,
                      icon: AppIcons.noWallet,
                      selected: true,
                      onTap: () =>
                          _set(_f.copyWith(wallet: const TxAnyWallet())),
                    ),
                ],
              ),
            ),
          // The form's row: one category (with its sub-categories), or
          // "ไม่ระบุหมวด" from เพิ่มเติม; only the type filter's categories.
          SideSheetSection(
            title: l.transactionsFilterCategory,
            icon: AppIcons.category,
            child: CategoryChipRow(
              leadingIcon: false,
              type: _f.type,
              selected: _f.category,
              order: _categoryOrders.putIfAbsent(_f.type, ChipOrder.new),
              onPick: (c) => _setCategory(_f.category?.id == c.id ? null : c),
              onMore: () async {
                final r = await pickCategoryFilter(
                  context,
                  type: _f.type,
                  selected: _f.category,
                  uncategorized: _f.uncategorized,
                );
                if (r == null || !mounted) return;
                _setCategory(r.category, uncategorized: r.uncategorized);
              },
              leading: [
                all(
                  selected: _f.category == null && !_f.uncategorized,
                  onTap: () => _setCategory(null),
                ),
              ],
              trailing: [
                if (_f.uncategorized)
                  RowChip(
                    label: l.homeUncategorized,
                    icon: AppIcons.noCategory,
                    selected: true,
                    onTap: () => _setCategory(null),
                  ),
              ],
            ),
          ),
          // The form's row, several at once.
          SideSheetSection(
            title: l.transactionsFilterTag,
            icon: AppIcons.tag,
            child: TagChipRow(
              leadingIcon: false,
              selected: {for (final t in _f.tags) t.id},
              order: _tagOrder,
              onToggle: _toggleTag,
              onMore: _moreTags,
              leading: [
                all(
                  selected: _f.tags.isEmpty,
                  onTap: () => _set(_f.copyWith(tags: const [])),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l.commonClear,
              variant: AppButtonVariant.outlined,
              expand: true,
              // Back to how the list opened (a wallet's list keeps its
              // wallet) — the period and sort are the page's, not reset.
              onPressed: () =>
                  _set(widget.base.copyWith(period: _f.period, sort: _f.sort)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppButton(
              label: l.transactionsFiltersApply,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_f),
            ),
          ),
        ],
      ),
    );
  }
}
