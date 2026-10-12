import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../data/transactions_repository.dart';
import '../../domain/form_options.dart';
import '../../domain/transaction_type.dart';
import '../tx_list_filters.dart';
import 'tx_hero_card.dart';

/// The transactions list's filters, in a side sheet from the right (owner
/// 2026-10-10), built from the form's options (one call when it opens):
/// - ประเภท: [AppChip]s tinted in each type's colour, ทั้งหมด in primary;
/// - กระเป๋า · หมวด · แท็ก: chip rows, each led by "ทั้งหมด" (= no filter);
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
  required TransactionsRepository repository,
  bool walletLocked = false,
}) => showSideSheet<TxFilters>(
  context,
  builder: (_) => _TxFilterSheet(
    initial: current,
    base: base,
    repository: repository,
    walletLocked: walletLocked,
  ),
);

/// The category choice: ทั้งหมด (null, false) · ไม่ระบุหมวด (null, true) ·
/// a category (with its sub-categories). Null when dismissed.
Future<({Category? category, bool uncategorized})?> pickCategoryFilter(
  BuildContext context, {
  required TransactionType? type,
  required Category? selected,
  required bool uncategorized,
  required List<Category> categories,
}) async {
  final l = AppLocalizations.of(context)!;
  final pool = categories
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
        leading: const AppIcon(AppIcons.noCategory),
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
  required List<Account> accounts,
}) async {
  final l = AppLocalizations.of(context)!;
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
        leading: const AppIcon(AppIcons.noWallet),
      ),
      for (final a in accounts)
        SheetOption(value: a.id, label: a.name, leading: AppIcon(a.type.icon)),
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
    required this.repository,
    required this.walletLocked,
  });

  final TxFilters initial;
  final TxFilters base;
  final TransactionsRepository repository;
  final bool walletLocked;

  @override
  State<_TxFilterSheet> createState() => _TxFilterSheetState();
}

class _TxFilterSheetState extends State<_TxFilterSheet> {
  late TxFilters _f = widget.initial;

  /// The pick rows' data (ONE call, only now the sheet is open). Null while
  /// loading — the rows show skeleton chips.
  TxFormOptions? _options;

  /// Each chip section wraps onto at most this many lines, then ends with
  /// "เพิ่มเติม" (owner 2026-10-11) — given enough chips to fill them.
  static const _chipLines = 4;
  static const _chipMax = 40;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    TxFormOptions? o;
    try {
      o = await widget.repository.formOptions();
    } catch (_) {
      // The rows stay empty; the type chips and apply still work.
      o = const TxFormOptions();
    }
    if (!mounted) return;
    setState(() {
      _options = o;
      // A drill-down opened with just the category id: take its name here.
      final c = _f.category;
      if (c != null && c.name.isEmpty) {
        for (final x in o!.categoryList) {
          if (x.id == c.id) {
            _f = _f.copyWith(category: x);
            break;
          }
        }
      }
    });
  }

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

  void _toggleTag(Tag tag) {
    final on = _f.tags.any((t) => t.id == tag.id);
    _set(
      _f.copyWith(
        tags: on
            ? [
                for (final t in _f.tags)
                  if (t.id != tag.id) t,
              ]
            : [..._f.tags, tag],
      ),
    );
  }

  Future<void> _moreTags(List<Tag> tags) async {
    final l = AppLocalizations.of(context)!;
    final id = await showOptionSheet<String>(
      context,
      title: l.transactionsFilterTag,
      searchable: tags.length > 8,
      options: [
        for (final t in tags)
          SheetOption(
            value: t.id,
            label: t.name,
            leading: AppIcon(
              IconRegistry.get(t.iconCode?.icon, fallback: AppIcons.tag),
            ),
          ),
      ],
    );
    if (id == null || !mounted) return;
    final tag = tags.firstWhere((t) => t.id == id);
    if (!_f.tags.any((t) => t.id == id)) _toggleTag(tag);
  }

  static List<Widget> _skeletonChips() => [
    for (final w in const [72.0, 56.0, 64.0])
      SkeletonBox(width: w, height: ChipSize.control.height, borderRadius: 999),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wallet = _f.wallet;
    final palette = Theme.of(context).extension<AppColors>()!;
    final o = _options;
    final accounts = o?.accountList ?? const <Account>[];
    final cats = [
      for (final c in o?.categoryList ?? const <Category>[])
        if (!c.isSystem && categoryFitsType(c, _f.type)) c,
    ];
    final tags = [...?o?.tags]
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    // "ทั้งหมด" leads each pick row — selected = no filter there.
    AppChip all({required bool selected, required VoidCallback onTap}) =>
        AppChip(
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
          // geometry ([AppChip]). Types: selected = a tint of their own
          // colour — ทั้งหมด primary, รายจ่าย red, รายรับ green, โอน grey.
          SideSheetSection(
            title: l.transactionsFilterType,
            icon: AppIcons.transfer,
            child: ChipRow(
              maxLines: _chipLines,
              chips: [
                for (final t in const [
                  null,
                  TransactionType.expense,
                  TransactionType.income,
                  TransactionType.transfer,
                ])
                  AppChip(
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
              child: ChipRow(
                maxLines: _chipLines,
                moreLabel: l.commonMore,
                onMore: o == null
                    ? null
                    : () async {
                        final w = await pickWalletFilter(
                          context,
                          selected: wallet,
                          accounts: accounts,
                        );
                        if (w != null && mounted) _set(_f.copyWith(wallet: w));
                      },
                chips: [
                  all(
                    selected: wallet is TxAnyWallet,
                    onTap: () => _set(_f.copyWith(wallet: const TxAnyWallet())),
                  ),
                  if (o == null) ..._skeletonChips(),
                  for (final a in accounts.take(_chipMax))
                    AppChip(
                      label: a.name,
                      icon: IconRegistry.get(
                        a.iconCode?.icon,
                        fallback: a.type.icon,
                      ),
                      color:
                          a.iconCode?.accentColorFor(palette) ??
                          palette.primary,
                      selected:
                          wallet is TxOneWallet && wallet.account.id == a.id,
                      onTap: () => _set(
                        _f.copyWith(
                          wallet:
                              wallet is TxOneWallet && wallet.account.id == a.id
                              ? const TxAnyWallet()
                              : TxOneWallet(a),
                        ),
                      ),
                    ),
                  if (wallet is TxNoWallet)
                    AppChip(
                      label: l.transactionFormAccountNone,
                      icon: AppIcons.noWallet,
                      selected: true,
                      onTap: () =>
                          _set(_f.copyWith(wallet: const TxAnyWallet())),
                    ),
                ],
              ),
            ),
          // One category (with its sub-categories), or "ไม่ระบุหมวด" from
          // เพิ่มเติม; only the type filter's categories.
          SideSheetSection(
            title: l.transactionsFilterCategory,
            icon: AppIcons.category,
            child: ChipRow(
              maxLines: _chipLines,
              moreLabel: l.commonMore,
              onMore: o == null
                  ? null
                  : () async {
                      final r = await pickCategoryFilter(
                        context,
                        type: _f.type,
                        selected: _f.category,
                        uncategorized: _f.uncategorized,
                        categories: o.categoryList,
                      );
                      if (r == null || !mounted) return;
                      _setCategory(r.category, uncategorized: r.uncategorized);
                    },
              chips: [
                all(
                  selected: _f.category == null && !_f.uncategorized,
                  onTap: () => _setCategory(null),
                ),
                if (o == null) ..._skeletonChips(),
                for (final c in cats.take(_chipMax))
                  AppChip(
                    label: categoryDisplayName(l, c),
                    // The category's own icon (sub-categories too).
                    icon: IconRegistry.get(
                      c.iconCode?.icon,
                      fallback: AppIcons.category,
                    ),
                    color:
                        c.iconCode?.accentColorFor(palette) ?? palette.primary,
                    selected: c.id == _f.category?.id,
                    onTap: () =>
                        _setCategory(_f.category?.id == c.id ? null : c),
                  ),
                if (_f.uncategorized)
                  AppChip(
                    label: l.homeUncategorized,
                    icon: AppIcons.noCategory,
                    selected: true,
                    onTap: () => _setCategory(null),
                  ),
              ],
            ),
          ),
          // Several tags at once.
          SideSheetSection(
            title: l.transactionsFilterTag,
            icon: AppIcons.tag,
            child: ChipRow(
              maxLines: _chipLines,
              moreLabel: l.commonMore,
              onMore: o == null ? null : () => _moreTags(tags),
              chips: [
                all(
                  selected: _f.tags.isEmpty,
                  onTap: () => _set(_f.copyWith(tags: const [])),
                ),
                if (o == null) ..._skeletonChips(),
                for (final t in tags.take(_chipMax))
                  tagAppChip(
                    context,
                    t,
                    selected: _f.tags.any((x) => x.id == t.id),
                    onTap: () => _toggleTag(t),
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
