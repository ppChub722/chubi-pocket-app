import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../ui.dart';

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

  final IconCode? iconCode;

  final IconData? icon;

  final Color? color;

  final IconData? listIcon;

  final String? subtitle;

  final String? parentId;

  final int sortOrder;

  final Set<TransactionType>? types;
}

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
    this.amountMin,
    this.amountMax,
  });

  final Set<TransactionType> types;

  final double? amountMin;
  final double? amountMax;

  /// Wallets, and/or [noWallet] (rows without one).
  final List<String> walletIds;
  final bool noWallet;

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
    ({double? min, double? max})? amount,
  }) => TxFilterSelection(
    types: types ?? this.types,
    walletIds: walletIds ?? this.walletIds,
    noWallet: noWallet ?? this.noWallet,
    categoryIds: categoryIds ?? this.categoryIds,
    uncategorized: uncategorized ?? this.uncategorized,
    tagIds: tagIds ?? this.tagIds,
    noTags: noTags ?? this.noTags,
    amountMin: amount == null ? amountMin : amount.min,
    amountMax: amount == null ? amountMax : amount.max,
  );
}

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
    required this.amountTitle,
    required this.amountMin,
    required this.amountMax,
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

  final String all;
  final String more;
  final String typeTitle;
  final String walletTitle;
  final String categoryTitle;
  final String tagTitle;
  final String amountTitle;

  final String amountMin;
  final String amountMax;
  final String expense;
  final String income;
  final String transfer;
  final String noWallet;
  final String uncategorized;
  final String noTag;

  final AccountPickerLabels walletPicker;
  final CategoryMultiPickerLabels categoryPicker;
  final TagPickerLabels tagPicker;

  final String Function(int count) confirm;

  String typeLabel(TransactionType? t) => switch (t) {
    null => all,
    TransactionType.expense => expense,
    TransactionType.income => income,
    TransactionType.transfer => transfer,
  };
}

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
        if (mounted) setState(() => _loaded = const TxFilterOptions());
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(_loaded);
}

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

  final TxFilterOptions? options;
  final TxFilterSheetLabels labels;
  final ValueChanged<TxFilterSelection> onApply;

  final bool walletLocked;

  @override
  State<TxFilterSheet> createState() => _TxFilterSheetState();
}

class _TxFilterSheetState extends State<TxFilterSheet> {
  late TxFilterSelection _f = widget.initial;

  static String _amountText(double? v) =>
      v == null ? '' : AmountInput.format(v);

  late final _min = TextEditingController(text: _amountText(_f.amountMin));
  late final _max = TextEditingController(text: _amountText(_f.amountMax));

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _amountChanged() => _set(
    _f.copyWith(
      amount: (
        min: AmountInput.parse(_min.text),
        max: AmountInput.parse(_max.text),
      ),
    ),
  );

  void _clear() {
    _set(widget.reset);
    _min.text = _amountText(widget.reset.amountMin);
    _max.text = _amountText(widget.reset.amountMax);
  }

  static const _chipLines = 2;
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

  List<Widget> _skeletonChips() => [
    for (final w in const [72.0, 56.0, 64.0])
      SkeletonBox(
        width: w,
        height: ChipSize.chip.heightOf(context),
        borderRadius: 999,
      ),
  ];

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
    dashed: !selected,
    onTap: onTap,
  );

  /// The shown chips of a row: the first [_chipMax] options, plus any picked
  /// one beyond them (a pick from "more" must stay visible).
  List<TxFilterOption> _shown(List<TxFilterOption> all, List<String> picked) =>
      [
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
    AppChip all({required bool selected, required VoidCallback onTap}) =>
        _chip(label: _l.all, selected: selected, onTap: onTap);
    return SideSheetScaffold(
      title: _l.title,
      body: ChipSizeScope(
        size: ChipSize.chip,
        child: Column(
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
                  moreOnlyWhenCut: true,
                  moreLabel: _l.more,
                  onMore: o == null ? null : () => _moreWallets(wallets),
                  chips: [
                    all(
                      selected: _f.walletIds.isEmpty && !_f.noWallet,
                      onTap: () => _set(
                        _f.copyWith(walletIds: const [], noWallet: false),
                      ),
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
                moreOnlyWhenCut: true,
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
                        _f.copyWith(
                          categoryIds: _toggled(_f.categoryIds, c.id),
                        ),
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
                moreOnlyWhenCut: true,
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
            SideSheetSection(
              title: _l.amountTitle,
              icon: AppIcons.amount,
              child: Row(
                children: [
                  Expanded(
                    child: AppInput(
                      controller: _min,
                      type: AppInputType.amount,
                      dense: true,
                      hint: _l.amountMin,
                      onChanged: (_) => _amountChanged(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: AppInput(
                      controller: _max,
                      type: AppInputType.amount,
                      dense: true,
                      hint: _l.amountMax,
                      onChanged: (_) => _amountChanged(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: _l.clear,
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: _clear,
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
