import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../ui.dart';

/// One pickable value of [TxFilterSheet] as plain display data — a wallet, a
/// category or a tag. The feature wrapper resolves names, icons and colours.
@immutable
class TxFilterOption {
  const TxFilterOption({
    required this.id,
    required this.label,
    this.icon,
    this.color,
    this.listIcon,
    this.subtitle,
    this.parentId,
    this.sortOrder = 0,
    this.types,
  });

  final String id;
  final String label;

  /// The chip's icon (the wallet / category / tag's own).
  final IconData? icon;

  /// The chip's tint (null = the app primary).
  final Color? color;

  /// The icon in the "more" list when it differs from [icon] (wallets show
  /// their type's icon there); null = [icon].
  final IconData? listIcon;

  /// Category roots: a line under the label in the "more" list (their type's
  /// name, shown only while no type filter is on).
  final String? subtitle;

  /// Categories: the parent's id (null = a root). Sub-categories are listed
  /// under their root in the "more" list.
  final String? parentId;

  /// Categories: the order of the roots / of the sub-categories in a root.
  final int sortOrder;

  /// Categories: the transaction types it fits (null = every type).
  final Set<TransactionType>? types;
}

/// The pick rows' data — wallets, categories (active, non-system) and tags,
/// in the order the chips show them.
@immutable
class TxFilterOptions {
  const TxFilterOptions({
    this.wallets = const [],
    this.categories = const [],
    this.tags = const [],
  });

  final List<TxFilterOption> wallets;
  final List<TxFilterOption> categories;
  final List<TxFilterOption> tags;
}

/// What the sheet edits — ids only, no models. The period and the sort are
/// not here: they live on the page.
@immutable
class TxFilterSelection {
  const TxFilterSelection({
    this.type,
    this.walletId,
    this.noWallet = false,
    this.categoryId,
    this.uncategorized = false,
    this.tagIds = const [],
  });

  /// null = every type.
  final TransactionType? type;

  /// One wallet, or [noWallet] (only rows without a wallet); both unset = any.
  final String? walletId;
  final bool noWallet;

  /// A category (with its sub-categories), or [uncategorized].
  final String? categoryId;
  final bool uncategorized;
  final List<String> tagIds;

  TxFilterSelection copyWith({
    TransactionType? type,
    bool clearType = false,
    String? walletId,
    bool? noWallet,
    bool clearWallet = false,
    String? categoryId,
    bool clearCategory = false,
    bool? uncategorized,
    List<String>? tagIds,
  }) => TxFilterSelection(
    type: clearType ? null : (type ?? this.type),
    walletId: clearWallet ? null : (walletId ?? this.walletId),
    noWallet: clearWallet ? (noWallet ?? false) : (noWallet ?? this.noWallet),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    uncategorized: uncategorized ?? this.uncategorized,
    tagIds: tagIds ?? this.tagIds,
  );
}

/// The words of [TxFilterSheet] — the caller passes its localised strings.
class TxFilterSheetLabels {
  const TxFilterSheetLabels({
    required this.title,
    required this.apply,
    required this.clear,
    required this.all,
    required this.more,
    required this.typeTitle,
    required this.walletTitle,
    required this.categoryTitle,
    required this.tagTitle,
    required this.expense,
    required this.income,
    required this.transfer,
    required this.noWallet,
    required this.uncategorized,
  });

  final String title;
  final String apply;
  final String clear;

  /// "All" — leads each pick row (= no filter there).
  final String all;
  final String more;
  final String typeTitle;
  final String walletTitle;
  final String categoryTitle;
  final String tagTitle;
  final String expense;
  final String income;
  final String transfer;
  final String noWallet;
  final String uncategorized;

  String typeLabel(TransactionType? t) => switch (t) {
    null => all,
    TransactionType.expense => expense,
    TransactionType.income => income,
    TransactionType.transfer => transfer,
  };
}

/// The transactions list's filters in a side sheet from the right — a
/// PRESENTATIONAL organism: it edits a [TxFilterSelection] over the pick rows
/// in [options] (null while they load → skeleton chips), words as [labels],
/// and nothing imported from cubits / repositories. [initial] is where it
/// opens, [reset] what ล้าง goes back to. Resolves the applied selection, or
/// null when closed without applying. [options] resolves (never throws — a
/// failure is an empty set) so the sheet opens at once.
Future<TxFilterSelection?> showTxFilterSideSheet(
  BuildContext context, {
  required TxFilterSelection initial,
  required TxFilterSelection reset,
  required Future<TxFilterOptions> options,
  required TxFilterSheetLabels labels,
  bool walletLocked = false,
}) => showSideSheet<TxFilterSelection>(
  context,
  builder: (ctx) => _OptionsLoader(
    options: options,
    builder: (loaded) => TxFilterSheet(
      initial: initial,
      reset: reset,
      options: loaded,
      labels: labels,
      walletLocked: walletLocked,
      onApply: (s) => Navigator.of(ctx).pop(s),
    ),
  ),
);

/// Feeds [builder] null until [options] arrives.
class _OptionsLoader extends StatefulWidget {
  const _OptionsLoader({required this.options, required this.builder});

  final Future<TxFilterOptions> options;
  final Widget Function(TxFilterOptions? loaded) builder;

  @override
  State<_OptionsLoader> createState() => _OptionsLoaderState();
}

class _OptionsLoaderState extends State<_OptionsLoader> {
  TxFilterOptions? _loaded;

  @override
  void initState() {
    super.initState();
    widget.options.then(
      (o) {
        if (mounted) setState(() => _loaded = o);
      },
      onError: (_) {
        // The rows stay empty; the type chips and apply still work.
        if (mounted) setState(() => _loaded = const TxFilterOptions());
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(_loaded);
}

/// The sheet's body: ประเภท · กระเป๋า · หมวด · แท็ก chip rows (each led by
/// "all" = no filter; wallet / category pick one — tap again → all, tags
/// several; "more" opens the full list) then [ล้าง] [ใช้ตัวกรอง] pinned.
class TxFilterSheet extends StatefulWidget {
  const TxFilterSheet({
    required this.initial,
    required this.reset,
    required this.options,
    required this.labels,
    required this.onApply,
    this.walletLocked = false,
    super.key,
  });

  final TxFilterSelection initial;
  final TxFilterSelection reset;

  /// null = still loading.
  final TxFilterOptions? options;
  final TxFilterSheetLabels labels;
  final ValueChanged<TxFilterSelection> onApply;

  /// Hides the wallet section (a wallet's own list).
  final bool walletLocked;

  @override
  State<TxFilterSheet> createState() => _TxFilterSheetState();
}

class _TxFilterSheetState extends State<TxFilterSheet> {
  late TxFilterSelection _f = widget.initial;

  /// Each chip section wraps onto at most this many lines, then ends with
  /// "more" — given enough chips to fill them.
  static const _chipLines = 4;
  static const _chipMax = 40;

  TxFilterSheetLabels get _l => widget.labels;

  void _set(TxFilterSelection f) => setState(() => _f = f);

  bool _fits(TxFilterOption c, TransactionType? t) =>
      t == null || (c.types?.contains(t) ?? true);

  void _setType(TransactionType? t) {
    final selected = _f.categoryId;
    var keep = true;
    if (selected != null) {
      for (final c in widget.options?.categories ?? const <TxFilterOption>[]) {
        if (c.id == selected) {
          keep = _fits(c, t);
          break;
        }
      }
    }
    _set(_f.copyWith(type: t, clearType: t == null, clearCategory: !keep));
  }

  void _setCategory(String? id, {bool uncategorized = false}) => _set(
    _f.copyWith(
      categoryId: id,
      clearCategory: id == null,
      uncategorized: uncategorized,
    ),
  );

  void _toggleTag(String id) {
    final on = _f.tagIds.contains(id);
    _set(
      _f.copyWith(
        tagIds: on
            ? [
                for (final t in _f.tagIds)
                  if (t != id) t,
              ]
            : [..._f.tagIds, id],
      ),
    );
  }

  Future<void> _moreWallets(List<TxFilterOption> wallets) async {
    final picked = await showOptionSheet<String>(
      context,
      title: _l.walletTitle,
      selected: _f.noWallet ? '-' : _f.walletId ?? '*',
      options: [
        SheetOption(value: '*', label: _l.all),
        SheetOption(
          value: '-',
          label: _l.noWallet,
          leading: const PpForgeIcon(PpForgeIcons.noWallet),
        ),
        for (final a in wallets)
          SheetOption(
            value: a.id,
            label: a.label,
            leading: PpForgeIcon(a.listIcon ?? a.icon ?? PpForgeIcons.wallet),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _set(switch (picked) {
      '*' => _f.copyWith(clearWallet: true),
      '-' => _f.copyWith(clearWallet: true, noWallet: true),
      _ => _f.copyWith(walletId: picked, noWallet: false),
    });
  }

  /// The category choice: all · uncategorized · a category (with its
  /// sub-categories).
  Future<void> _moreCategories(List<TxFilterOption> categories) async {
    final pool = [
      for (final c in categories)
        if (_fits(c, _f.type)) c,
    ];
    int order(TxFilterOption a, TxFilterOption b) =>
        a.sortOrder.compareTo(b.sortOrder);
    final roots = pool.where((c) => c.parentId == null).toList()..sort(order);
    final picked = await showOptionSheet<String>(
      context,
      title: _l.categoryTitle,
      searchable: pool.length > 8,
      selected: _f.uncategorized ? '-' : _f.categoryId ?? '*',
      options: [
        SheetOption(value: '*', label: _l.all),
        SheetOption(
          value: '-',
          label: _l.uncategorized,
          leading: const PpForgeIcon(PpForgeIcons.noCategory),
        ),
        for (final root in roots) ...[
          SheetOption(
            value: root.id,
            label: root.label,
            subtitle: _f.type == null ? root.subtitle : null,
          ),
          for (final child
              in pool.where((c) => c.parentId == root.id).toList()..sort(order))
            SheetOption(
              value: child.id,
              label: child.label,
              subtitle: root.label,
            ),
        ],
      ],
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case '*':
        _setCategory(null);
      case '-':
        _setCategory(null, uncategorized: true);
      default:
        _setCategory(picked);
    }
  }

  Future<void> _moreTags(List<TxFilterOption> tags) async {
    final id = await showOptionSheet<String>(
      context,
      title: _l.tagTitle,
      searchable: tags.length > 8,
      options: [
        for (final t in tags)
          SheetOption(
            value: t.id,
            label: t.label,
            leading: PpForgeIcon(t.icon ?? PpForgeIcons.tag),
          ),
      ],
    );
    if (id == null || !mounted) return;
    if (!_f.tagIds.contains(id)) _toggleTag(id);
  }

  static List<Widget> _skeletonChips() => [
    for (final w in const [72.0, 56.0, 64.0])
      SkeletonBox(width: w, height: ChipSize.control.height, borderRadius: 999),
  ];

  @override
  Widget build(BuildContext context) {
    final o = widget.options;
    final wallets = o?.wallets ?? const <TxFilterOption>[];
    final cats = [
      for (final c in o?.categories ?? const <TxFilterOption>[])
        if (_fits(c, _f.type)) c,
    ];
    final tags = o?.tags ?? const <TxFilterOption>[];
    // "all" leads each pick row — selected = no filter there.
    PpForgeChip all({required bool selected, required VoidCallback onTap}) =>
        PpForgeChip(label: _l.all, selected: selected, onTap: onTap);
    final anyWallet = _f.walletId == null && !_f.noWallet;
    return SideSheetScaffold(
      title: _l.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Every row the same: the icon goes in front of the section title,
          // the chips start flush left, one chip geometry ([PpForgeChip]). Types:
          // selected = a tint of their own colour — all primary, expense red,
          // income green, transfer grey.
          SideSheetSection(
            title: _l.typeTitle,
            icon: PpForgeIcons.transfer,
            child: ChipRow(
              maxLines: _chipLines,
              chips: [
                for (final t in const [
                  null,
                  TransactionType.expense,
                  TransactionType.income,
                  TransactionType.transfer,
                ])
                  PpForgeChip(
                    label: _l.typeLabel(t),
                    icon: switch (t) {
                      null => null,
                      TransactionType.expense => PpForgeIcons.expense,
                      TransactionType.income => PpForgeIcons.income,
                      TransactionType.transfer => PpForgeIcons.transfer,
                    },
                    // Null = the app primary (all).
                    color: t == null ? null : txTypeColor(context, t),
                    selected: t == _f.type,
                    onTap: t == _f.type ? null : () => _setType(t),
                  ),
              ],
            ),
          ),
          // One wallet, or none; "no wallet" lives in more's list.
          if (!widget.walletLocked)
            SideSheetSection(
              title: _l.walletTitle,
              icon: PpForgeIcons.wallet,
              child: ChipRow(
                maxLines: _chipLines,
                moreLabel: _l.more,
                onMore: o == null ? null : () => _moreWallets(wallets),
                chips: [
                  all(
                    selected: anyWallet,
                    onTap: () => _set(_f.copyWith(clearWallet: true)),
                  ),
                  if (o == null) ..._skeletonChips(),
                  for (final a in wallets.take(_chipMax))
                    PpForgeChip(
                      label: a.label,
                      icon: a.icon,
                      color: a.color,
                      selected: _f.walletId == a.id,
                      onTap: () => _set(
                        _f.walletId == a.id
                            ? _f.copyWith(clearWallet: true)
                            : _f.copyWith(walletId: a.id, noWallet: false),
                      ),
                    ),
                  if (_f.noWallet)
                    PpForgeChip(
                      label: _l.noWallet,
                      icon: PpForgeIcons.noWallet,
                      selected: true,
                      onTap: () => _set(_f.copyWith(clearWallet: true)),
                    ),
                ],
              ),
            ),
          // One category (with its sub-categories), or "uncategorized" from
          // more; only the type filter's categories.
          SideSheetSection(
            title: _l.categoryTitle,
            icon: PpForgeIcons.category,
            child: ChipRow(
              maxLines: _chipLines,
              moreLabel: _l.more,
              onMore: o == null ? null : () => _moreCategories(o.categories),
              chips: [
                all(
                  selected: _f.categoryId == null && !_f.uncategorized,
                  onTap: () => _setCategory(null),
                ),
                if (o == null) ..._skeletonChips(),
                for (final c in cats.take(_chipMax))
                  PpForgeChip(
                    label: c.label,
                    icon: c.icon,
                    color: c.color,
                    selected: c.id == _f.categoryId,
                    onTap: () =>
                        _setCategory(_f.categoryId == c.id ? null : c.id),
                  ),
                if (_f.uncategorized)
                  PpForgeChip(
                    label: _l.uncategorized,
                    icon: PpForgeIcons.noCategory,
                    selected: true,
                    onTap: () => _setCategory(null),
                  ),
              ],
            ),
          ),
          // Several tags at once.
          SideSheetSection(
            title: _l.tagTitle,
            icon: PpForgeIcons.tag,
            child: ChipRow(
              maxLines: _chipLines,
              moreLabel: _l.more,
              onMore: o == null ? null : () => _moreTags(tags),
              chips: [
                all(
                  selected: _f.tagIds.isEmpty,
                  onTap: () => _set(_f.copyWith(tagIds: const [])),
                ),
                if (o == null) ..._skeletonChips(),
                for (final t in tags.take(_chipMax))
                  PpForgeChip(
                    label: t.label,
                    icon: t.icon,
                    color: t.color,
                    selected: _f.tagIds.contains(t.id),
                    onTap: () => _toggleTag(t.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PpForgeSpacing.xl),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: PpForgeButton(
              label: _l.clear,
              variant: PpForgeButtonVariant.outlined,
              expand: true,
              onPressed: () => _set(widget.reset),
            ),
          ),
          const SizedBox(width: PpForgeSpacing.sm),
          Expanded(
            flex: 2,
            child: PpForgeButton(
              label: _l.apply,
              expand: true,
              onPressed: () => widget.onApply(_f),
            ),
          ),
        ],
      ),
    );
  }
}
