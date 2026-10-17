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
    this.iconCode,
  });

  final String id;
  final String label;

  /// The icon's own code: the pickers behind "more" draw it (a category /
  /// tag row); [icon] / [color] are the chip's.
  final IconCode? iconCode;

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

/// What the sheet edits: ids only, no models. The period and the sort are
/// not here, they live on the page. Every group takes SEVERAL values, OR-ed
/// inside the group (wallet KBank OR cash OR no wallet) and AND-ed between
/// groups; an empty group = no filter there.
@immutable
class TxFilterSelection {
  const TxFilterSelection({
    this.types = const {},
    this.walletIds = const [],
    this.noWallet = false,
    this.categoryIds = const [],
    this.uncategorized = false,
    this.tagIds = const [],
    this.noTags = false,
  });

  final Set<TransactionType> types;

  /// Wallets, and/or [noWallet] (rows without one).
  final List<String> walletIds;
  final bool noWallet;

  /// Categories (each with its sub-categories), and/or [uncategorized].
  final List<String> categoryIds;
  final bool uncategorized;

  /// Tags, and/or [noTags] (rows without any).
  final List<String> tagIds;
  final bool noTags;

  TxFilterSelection copyWith({
    Set<TransactionType>? types,
    List<String>? walletIds,
    bool? noWallet,
    List<String>? categoryIds,
    bool? uncategorized,
    List<String>? tagIds,
    bool? noTags,
  }) => TxFilterSelection(
    types: types ?? this.types,
    walletIds: walletIds ?? this.walletIds,
    noWallet: noWallet ?? this.noWallet,
    categoryIds: categoryIds ?? this.categoryIds,
    uncategorized: uncategorized ?? this.uncategorized,
    tagIds: tagIds ?? this.tagIds,
    noTags: noTags ?? this.noTags,
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
    required this.noTag,
    required this.walletPicker,
    required this.categoryPicker,
    required this.tagPicker,
    required this.confirm,
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
  final String noTag;

  /// The words of the pickers behind each row's "more": the same pickers the
  /// create form opens.
  final AccountPickerLabels walletPicker;
  final CategoryMultiPickerLabels categoryPicker;
  final TagPickerLabels tagPicker;

  /// The wallet picker's confirm button, from how many are ticked.
  final String Function(int count) confirm;

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

/// The sheet's body: ประเภท · กระเป๋า · หมวด · แท็ก chip rows. Every chip is
/// dashed (tap = toggle) and several can be on in every row; "all" leads a
/// row (on while nothing in it is picked, tap clears it); each of กระเป๋า /
/// หมวด / แท็ก has its "no …" chip ("ไม่มีกระเป๋า" …) so you can ask for the
/// rows that have none, alone or together with a pick (OR inside a row);
/// "more" opens the full picker of the row — the one the create form opens.
/// [ล้าง] [ใช้ตัวกรอง] pinned.
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

  bool _fits(TxFilterOption c, Set<TransactionType> types) =>
      types.isEmpty || c.types == null || c.types!.any(types.contains);

  List<String> _toggled(List<String> ids, String id) =>
      ids.contains(id) ? [...ids.where((x) => x != id)] : [...ids, id];

  void _toggleType(TransactionType t) {
    final next = {..._f.types};
    if (!next.remove(t)) next.add(t);
    // A category that fits none of the types now on is dropped.
    final cats = {
      for (final c in widget.options?.categories ?? const <TxFilterOption>[])
        c.id: c,
    };
    _set(
      _f.copyWith(
        types: next,
        categoryIds: [
          for (final id in _f.categoryIds)
            if (cats[id] == null || _fits(cats[id]!, next)) id,
        ],
      ),
    );
  }

  Future<void> _moreWallets(List<TxFilterOption> wallets) async {
    final r = await showAccountMultiPickSheet(
      context,
      wallets: [
        for (final a in wallets)
          WalletPickItem(
            id: a.id,
            name: a.label,
            icon: a.listIcon ?? a.icon ?? AppIcons.wallet,
            color: a.color,
          ),
      ],
      labels: _l.walletPicker,
      confirm: _l.confirm,
      selectedIds: _f.walletIds.toSet(),
      noneSelected: _f.noWallet,
    );
    if (r == null || !mounted) return;
    _set(_f.copyWith(walletIds: r.ids.toList(), noWallet: r.none));
  }

  Future<void> _moreCategories(List<TxFilterOption> categories) async {
    final pool = [
      for (final c in categories)
        if (_fits(c, _f.types)) c,
    ];
    final r = await showCategoryMultiPicker(
      context,
      rows: [
        for (final c in pool)
          CategoryPickerRow(
            id: c.id,
            name: c.label,
            parentId: c.parentId,
            sortOrder: c.sortOrder,
            iconCode: c.iconCode,
          ),
      ],
      labels: _l.categoryPicker,
      initial: [
        for (final id in _f.categoryIds) (id: id, includeChildren: false),
      ],
      // A picked category always counts its sub-categories here.
      showIncludeChildren: false,
    );
    if (r == null || !mounted) return;
    _set(_f.copyWith(categoryIds: [for (final p in r) p.id]));
  }

  Future<void> _moreTags(List<TxFilterOption> tags) async {
    final r = await showTagPicker(
      context,
      data: ValueNotifier(
        TagPickerData(
          items: [
            for (final t in tags)
              TagPickerItem(id: t.id, name: t.label, iconCode: t.iconCode),
          ],
        ),
      ),
      labels: _l.tagPicker,
      selected: _f.tagIds.toSet(),
    );
    if (r == null || !mounted) return;
    _set(_f.copyWith(tagIds: r.toList()));
  }

  static List<Widget> _skeletonChips() => [
    for (final w in const [72.0, 56.0, 64.0])
      SkeletonBox(width: w, height: ChipSize.control.height, borderRadius: 999),
  ];

  /// One chip of the sheet: dashed always (tap toggles), picked = the tint of
  /// its own colour. No inner line here — nothing on this page is "fixed".
  AppChip _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) => AppChip(
    label: label,
    icon: icon,
    color: color,
    selected: selected,
    dashed: true,
    onTap: onTap,
  );

  /// The shown chips of a row: the first [_chipMax] options, plus any picked
  /// one beyond them (a pick from "more" must stay visible).
  List<TxFilterOption> _shown(
    List<TxFilterOption> all,
    List<String> picked,
  ) => [
    ...all.take(_chipMax),
    for (final o in all.skip(_chipMax))
      if (picked.contains(o.id)) o,
  ];

  @override
  Widget build(BuildContext context) {
    final o = widget.options;
    final wallets = o?.wallets ?? const <TxFilterOption>[];
    final cats = [
      for (final c in o?.categories ?? const <TxFilterOption>[])
        if (_fits(c, _f.types)) c,
    ];
    final tags = o?.tags ?? const <TxFilterOption>[];
    // "all" leads each row — on while nothing in the row is picked.
    AppChip all({required bool selected, required VoidCallback onTap}) =>
        _chip(label: _l.all, selected: selected, onTap: onTap);
    return SideSheetScaffold(
      title: _l.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideSheetSection(
            title: _l.typeTitle,
            icon: AppIcons.transfer,
            child: ChipRow(
              maxLines: _chipLines,
              chips: [
                all(
                  selected: _f.types.isEmpty,
                  onTap: () => _set(_f.copyWith(types: const {})),
                ),
                for (final t in const [
                  TransactionType.expense,
                  TransactionType.income,
                  TransactionType.transfer,
                ])
                  _chip(
                    label: _l.typeLabel(t),
                    icon: switch (t) {
                      TransactionType.expense => AppIcons.expense,
                      TransactionType.income => AppIcons.income,
                      TransactionType.transfer => AppIcons.transfer,
                    },
                    color: txTypeColor(context, t),
                    selected: _f.types.contains(t),
                    onTap: () => _toggleType(t),
                  ),
              ],
            ),
          ),
          if (!widget.walletLocked)
            SideSheetSection(
              title: _l.walletTitle,
              icon: AppIcons.wallet,
              child: ChipRow(
                maxLines: _chipLines,
                moreLabel: _l.more,
                onMore: o == null ? null : () => _moreWallets(wallets),
                chips: [
                  all(
                    selected: _f.walletIds.isEmpty && !_f.noWallet,
                    onTap: () =>
                        _set(_f.copyWith(walletIds: const [], noWallet: false)),
                  ),
                  _chip(
                    label: _l.noWallet,
                    icon: AppIcons.noWallet,
                    selected: _f.noWallet,
                    onTap: () => _set(_f.copyWith(noWallet: !_f.noWallet)),
                  ),
                  if (o == null) ..._skeletonChips(),
                  for (final a in _shown(wallets, _f.walletIds))
                    _chip(
                      label: a.label,
                      icon: a.icon,
                      color: a.color,
                      selected: _f.walletIds.contains(a.id),
                      onTap: () => _set(
                        _f.copyWith(walletIds: _toggled(_f.walletIds, a.id)),
                      ),
                    ),
                ],
              ),
            ),
          SideSheetSection(
            title: _l.categoryTitle,
            icon: AppIcons.category,
            child: ChipRow(
              maxLines: _chipLines,
              moreLabel: _l.more,
              onMore: o == null ? null : () => _moreCategories(o.categories),
              chips: [
                all(
                  selected: _f.categoryIds.isEmpty && !_f.uncategorized,
                  onTap: () => _set(
                    _f.copyWith(categoryIds: const [], uncategorized: false),
                  ),
                ),
                _chip(
                  label: _l.uncategorized,
                  icon: AppIcons.noCategory,
                  selected: _f.uncategorized,
                  onTap: () =>
                      _set(_f.copyWith(uncategorized: !_f.uncategorized)),
                ),
                if (o == null) ..._skeletonChips(),
                for (final c in _shown(cats, _f.categoryIds))
                  _chip(
                    label: c.label,
                    icon: c.icon,
                    color: c.color,
                    selected: _f.categoryIds.contains(c.id),
                    onTap: () => _set(
                      _f.copyWith(categoryIds: _toggled(_f.categoryIds, c.id)),
                    ),
                  ),
              ],
            ),
          ),
          SideSheetSection(
            title: _l.tagTitle,
            icon: AppIcons.tag,
            child: ChipRow(
              maxLines: _chipLines,
              moreLabel: _l.more,
              onMore: o == null ? null : () => _moreTags(tags),
              chips: [
                all(
                  selected: _f.tagIds.isEmpty && !_f.noTags,
                  onTap: () =>
                      _set(_f.copyWith(tagIds: const [], noTags: false)),
                ),
                _chip(
                  label: _l.noTag,
                  icon: AppIcons.tag,
                  selected: _f.noTags,
                  onTap: () => _set(_f.copyWith(noTags: !_f.noTags)),
                ),
                if (o == null) ..._skeletonChips(),
                for (final t in _shown(tags, _f.tagIds))
                  _chip(
                    label: t.label,
                    icon: t.icon,
                    color: t.color,
                    selected: _f.tagIds.contains(t.id),
                    onTap: () =>
                        _set(_f.copyWith(tagIds: _toggled(_f.tagIds, t.id))),
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
              label: _l.clear,
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: () => _set(widget.reset),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppButton(
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
