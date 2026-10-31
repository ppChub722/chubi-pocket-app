import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../atoms/app_chip.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/app_input.dart';
import '../atoms/select_check.dart';
import '../molecules/chip_row.dart';
import '../molecules/danger_row.dart';
import '../molecules/detail_rows.dart';
import '../molecules/empty_view.dart';
import '../molecules/app_list_header.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import 'app_sheet.dart';
import 'picker_selection.dart';
import 'picker_sheet.dart';
import '../atoms/busy_scope.dart';

enum PickerLayout { rows, cards, chips }

/// One choice of an [ItemPickerSheet]. [parentId] puts it under another item
/// (a tree); [group] puts it under a [PickerGroup] heading.
@immutable
class PickerItem {
  const PickerItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.icon,
    this.color,
    this.parentId,
    this.group,
    this.keywords = const [],
    this.enabled = true,
    this.data,
  });

  final String id;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// The chip's icon and colour in [PickerLayout.chips].
  final IconData? icon;
  final Color? color;

  final String? parentId;
  final String? group;

  /// More words the search matches besides [title] and [subtitle].
  final List<String> keywords;
  final bool enabled;

  /// The entity behind the item, for a [PickerCardBuilder].
  final Object? data;

  bool matches(String lowerQuery) =>
      lowerQuery.isEmpty ||
      title.toLowerCase().contains(lowerQuery) ||
      (subtitle?.toLowerCase().contains(lowerQuery) ?? false) ||
      keywords.any((k) => k.toLowerCase().contains(lowerQuery));
}

@immutable
class PickerGroup {
  const PickerGroup(this.key, this.label);

  final String key;
  final String label;
}

/// A tab of the filter strip on top of the list.
@immutable
class PickerFilter {
  const PickerFilter(this.label, this.test);

  final String label;
  final bool Function(PickerItem item) test;
}

/// The "nothing" choice (ไม่ระบุ…): in a single picker it answers
/// [PickerResult.none]; in a multi picker it is one more tick.
@immutable
class PickerNone {
  const PickerNone({
    required this.label,
    this.icon,
    this.leading,
    this.subtitle,
    this.showWhileSearching = false,
  });

  final String label;
  final IconData? icon;

  /// Instead of [icon] (rows only).
  final Widget? leading;
  final String? subtitle;
  final bool showWhileSearching;
}

/// Making a new item from the picker. [onCreate] answers the new id (null =
/// cancelled); a single picker answers it, a multi picker ticks it.
@immutable
class PickerCreate {
  const PickerCreate({
    required this.label,
    required this.onCreate,
    this.fromSearch = false,
    this.atTop = false,
  });

  /// The row's words for what was typed ('' when nothing, or without
  /// [fromSearch]).
  final String Function(String typed) label;
  final Future<String?> Function(String typed) onCreate;

  /// Hands the search text to [label] / [onCreate] when no item has that exact
  /// name.
  final bool fromSearch;

  /// The row is the list's first row instead of sitting in the footer.
  final bool atTop;
}

/// A name typed by hand as the answer ([PickerResult.text]): the last row is
/// an input; while it has focus the row is highlighted and the footer turns
/// into [saveLabel].
@immutable
class PickerFreeText {
  const PickerFreeText({
    required this.hint,
    required this.saveLabel,
    this.leading,
    this.initial = '',
    this.maxLength,
  });

  final String hint;
  final String Function(String typed) saveLabel;

  /// The row's mark for what is typed (a person's initials).
  final Widget Function(String typed)? leading;

  /// In the input when the picker opens (the name typed before).
  final String initial;
  final int? maxLength;
}

/// A row under the list that closes the picker with [PickerResult.action]
/// (e.g. "remove from the event").
@immutable
class PickerAction {
  const PickerAction({
    required this.id,
    required this.label,
    required this.icon,
    this.destructive = false,
    this.pinned = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool destructive;

  /// In the footer, always in view, instead of under the list.
  final bool pinned;
}

/// What a live picker shows right now.
@immutable
class PickerData {
  const PickerData(this.items, {this.loading = false, this.error});

  final List<PickerItem> items;
  final bool loading;
  final Object? error;
}

@immutable
class PickerResult {
  const PickerResult({
    this.ids = const [],
    this.withChildren = const {},
    this.none = false,
    this.text,
    this.action,
  });

  /// The picked ids, in the order they were ticked.
  final List<String> ids;

  /// The picked ids that also take in all their sub-items.
  final Set<String> withChildren;
  final bool none;
  final String? text;
  final String? action;

  String? get id => ids.isEmpty ? null : ids.first;
}

typedef PickerCardBuilder =
    Widget Function(
      BuildContext context,
      PickerItem item,
      bool selected,
      VoidCallback? onTap,
    );

Future<PickerResult?> showItemPicker(
  BuildContext context,
  ItemPickerSheet sheet, {
  bool useRootNavigator = true,
}) => showAppSheetCustom<PickerResult>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (_) => sheet,
);

/// The one picker every entity picker is built on: single or multi, rows /
/// cards / chips, groups, filter tabs, a tree with sub-items, a "nothing" row,
/// making a new item, live items and pull-to-refresh.
class ItemPickerSheet extends StatefulWidget {
  const ItemPickerSheet({
    required this.title,
    required this.items,
    this.live,
    this.load,
    this.multi = false,
    this.layout = PickerLayout.rows,
    this.selected = const {},
    this.selectedWithChildren = const {},
    this.noneSelected = false,
    this.none,
    this.groups = const [],
    this.filters = const [],
    this.initialFilter = 0,
    this.children = PickerChildren.separate,
    this.includeChildrenLabel,
    this.maxDepth = 2,
    this.create,
    this.freeText,
    this.actions = const [],
    this.searchable = true,
    this.searchHint,
    this.note,
    this.emptyText,
    this.noMatchText,
    this.confirmLabel,
    this.onConfirm,
    this.minPicks = 0,
    this.cardBuilder,
    this.cardHeight = 156,
    this.loading = false,
    this.error,
    this.onRetry,
    this.onRefresh,
    super.key,
  }) : assert(!multi || confirmLabel != null, 'a multi picker needs a confirm'),
       assert(
         children != PickerChildren.toggle || includeChildrenLabel != null,
         'the include box needs its label',
       );

  final String title;

  /// The items in display order. [live] replaces them (and [loading] /
  /// [error]) while the sheet is open; [load] fetches them once it opens, and
  /// again on retry / pull-to-refresh.
  final List<PickerItem> items;
  final ValueListenable<PickerData>? live;
  final Future<List<PickerItem>> Function()? load;

  final bool multi;
  final PickerLayout layout;
  final Set<String> selected;
  final Set<String> selectedWithChildren;
  final bool noneSelected;
  final PickerNone? none;

  /// The headings in order; items whose [PickerItem.group] is not here go last
  /// without a heading.
  final List<PickerGroup> groups;
  final List<PickerFilter> filters;
  final int initialFilter;
  final PickerChildren children;
  final String? includeChildrenLabel;

  /// The deepest level shown (0 = only top-level items).
  final int maxDepth;
  final PickerCreate? create;
  final PickerFreeText? freeText;
  final List<PickerAction> actions;

  /// The 🔍 in the header, the same on every picker.
  final bool searchable;
  final String? searchHint;

  /// What the sheet is about, muted under the title (every picker the same).
  final String? note;
  final String? emptyText;
  final String? noMatchText;
  final String Function(int count)? confirmLabel;

  /// Runs on confirm with the button busy; the sheet closes only on true.
  final Future<bool> Function(PickerResult result)? onConfirm;
  final int minPicks;

  final PickerCardBuilder? cardBuilder;

  /// null = each row of cards as tall as its tallest card.
  final double? cardHeight;

  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;

  @override
  State<ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<ItemPickerSheet> {
  late final PickerSelection _sel = PickerSelection(
    mode: widget.multi ? widget.children : PickerChildren.separate,
    ids: widget.selected,
    withChildren: widget.selectedWithChildren,
    none: widget.noneSelected,
  );
  final _expanded = <String>{};
  late int _filter = widget.filters.isEmpty
      ? 0
      : widget.initialFilter.clamp(0, widget.filters.length - 1);
  final _search = TextEditingController();
  late final _name = TextEditingController(text: widget.freeText?.initial);
  final _nameFocus = FocusNode();
  final _nameKey = GlobalKey();
  final _selectedKey = GlobalKey();
  late final String? _scrollTarget = widget.multi
      ? null
      : widget.selected.firstOrNull;
  bool _creating = false;
  bool _confirming = false;
  bool _primed = false;

  List<PickerItem>? _loaded;
  bool _loadingNow = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _name.addListener(_onSearch);
    _nameFocus.addListener(_onNameFocus);
    _prime(widget.live?.value.items ?? widget.items);
    if (widget.load != null) _runLoad();
  }

  /// Ticks and open parents follow the first items there are (a picker that
  /// loads opens empty).
  void _prime(List<PickerItem> items) {
    if (_primed || items.isEmpty) return;
    _primed = true;
    final tree = _treeOf(items);
    _sel.normalize(tree);
    for (final id in {...widget.selected, ...widget.selectedWithChildren}) {
      _expanded.addAll(tree.ancestorsOf(id));
    }
    if (_scrollTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _selectedKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(target, alignment: 0.3);
        }
      });
    }
  }

  VoidCallback? get _retryByRefresh {
    final refresh = widget.onRefresh;
    return refresh == null ? null : () => unawaited(refresh());
  }

  Future<void> _runLoad() async {
    setState(() {
      _loadingNow = true;
      _loadError = null;
    });
    try {
      final items = await widget.load!();
      if (!mounted) return;
      setState(() {
        _loaded = items;
        _loadingNow = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loadingNow = false;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onSearch() => setState(() {});

  void _onNameFocus() {
    setState(() {});
    if (!_nameFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _nameKey.currentContext;
      if (row != null && row.mounted) Scrollable.ensureVisible(row);
    });
  }

  void _useName() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(PickerResult(text: name));
  }

  static PickerTree _treeOf(List<PickerItem> items) =>
      PickerTree([for (final i in items) (id: i.id, parentId: i.parentId)]);

  bool _isSelected(String id, PickerTree tree) =>
      widget.multi ? _sel.shownTicked(id, tree) : widget.selected.contains(id);

  void _tap(PickerItem item, PickerTree tree) {
    if (!widget.multi) {
      Navigator.of(context).pop(PickerResult(ids: [item.id]));
      return;
    }
    setState(() => _sel.toggle(item.id, tree));
  }

  void _tapNone() {
    if (!widget.multi) {
      Navigator.of(context).pop(const PickerResult(none: true));
      return;
    }
    setState(() => _sel.none = !_sel.none);
  }

  Future<void> _confirm() async {
    final result = PickerResult(
      ids: _sel.ids.toList(),
      withChildren: _sel.withChildren,
      none: _sel.none,
    );
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => _confirming = true);
    final ok = await onConfirm(result);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(result);
    } else {
      setState(() => _confirming = false);
    }
  }

  Future<void> _create(String typed, PickerTree tree) async {
    final create = widget.create!;
    if (_creating) return;
    setState(() => _creating = true);
    final id = await create.onCreate(typed);
    if (!mounted) return;
    setState(() => _creating = false);
    if (id == null) return;
    if (!widget.multi) {
      Navigator.of(context).pop(PickerResult(ids: [id]));
      return;
    }
    setState(() {
      if (!_sel.shownTicked(id, tree)) _sel.toggle(id, tree);
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.live;
    if (live != null) {
      return ValueListenableBuilder<PickerData>(
        valueListenable: live,
        builder: (context, data, _) => _sheet(context, data),
      );
    }
    if (widget.load != null) {
      return _sheet(
        context,
        PickerData(
          _loaded ?? widget.items,
          loading: _loadingNow,
          error: _loadError,
        ),
      );
    }
    return _sheet(
      context,
      PickerData(widget.items, loading: widget.loading, error: widget.error),
    );
  }

  Widget _sheet(BuildContext context, PickerData data) {
    final items = data.items;
    _prime(items);
    final tree = _treeOf(items);
    final typed = _search.text.trim();
    final searchable =
        widget.searchable || (widget.create?.fromSearch ?? false);
    final reload = widget.load == null ? null : _runLoad;
    return PickerSheet(
      title: widget.title,
      subtitle: widget.note,
      searchable: searchable,
      searchToggle: true,
      searchHint: widget.searchHint,
      searchController: _search,
      loading: data.loading && items.isEmpty,
      error: items.isEmpty ? data.error : null,
      onRetry: widget.onRetry ?? reload ?? _retryByRefresh,
      onRefresh: widget.onRefresh ?? reload,
      header: widget.filters.isEmpty ? null : _filterStrip(),
      footer: _footer(items, tree, typed),
      builder: (context, query) => _body(context, query, typed, items, tree),
    );
  }

  Widget _filterStrip() => ChipRow(
    chips: [
      for (final (i, f) in widget.filters.indexed)
        AppChip(
          label: f.label,
          size: ChipSize.chip,
          selected: i == _filter,
          dashed: i != _filter,
          onTap: () => setState(() => _filter = i),
        ),
    ],
  );

  Widget? _createRow(List<PickerItem> items, PickerTree tree, String typed) {
    final create = widget.create;
    if (create == null) return null;
    final lower = typed.toLowerCase();
    final exact =
        typed.isNotEmpty && items.any((i) => i.title.toLowerCase() == lower);
    if (create.fromSearch && exact) return null;
    final word = create.fromSearch
        ? typed
        : (widget.freeText == null ? '' : _name.text.trim());
    return PickerCreateRow(
      label: create.label(word),
      onTap: _creating ? null : () => _create(word, tree),
    );
  }

  Widget? _footer(List<PickerItem> items, PickerTree tree, String typed) {
    final freeText = widget.freeText;
    final createRow = (widget.create?.atTop ?? false)
        ? null
        : _createRow(items, tree, typed);
    final pinned = [
      for (final a in widget.actions)
        if (a.pinned) _actionRow(context, a),
    ];
    if (freeText != null && _nameFocus.hasFocus) {
      final name = _name.text.trim();
      // Inside the input's tap region: a tap here must not blur the input
      // first, which would take Save away and shift the rows under the finger.
      return TextFieldTapRegion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?createRow,
            ...pinned,
            PickerConfirmBar(
              label: freeText.saveLabel(name),
              onPressed: name.isEmpty ? null : _useName,
            ),
          ],
        ),
      );
    }
    if (!widget.multi) {
      if (pinned.isEmpty) return createRow;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?createRow, ...pinned],
      );
    }
    final count = _sel.shownCount(tree) + (_sel.none ? 1 : 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?createRow,
        ...pinned,
        PickerConfirmBar(
          label: widget.confirmLabel!(count),
          loading: _confirming,
          onPressed: count < widget.minPicks || _confirming ? null : _confirm,
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    String query,
    String typed,
    List<PickerItem> items,
    PickerTree tree,
  ) {
    final filter = widget.filters.isEmpty ? null : widget.filters[_filter];
    final pool = [
      for (final i in items)
        if (tree.depthOf(i.id) <= widget.maxDepth &&
            (filter == null || filter.test(i)))
          i,
    ];
    final inPool = {for (final i in pool) i.id};

    Set<String>? visible;
    final forced = <String>{};
    if (query.isNotEmpty) {
      visible = {};
      for (final i in pool) {
        if (!i.matches(query)) continue;
        visible.add(i.id);
        for (final a in tree.ancestorsOf(i.id)) {
          if (!inPool.contains(a)) break;
          visible.add(a);
          forced.add(a);
        }
      }
    }

    final roots = [
      for (final i in pool)
        if ((i.parentId == null || !inPool.contains(i.parentId)) &&
            (visible == null || visible.contains(i.id)))
          i,
    ];
    final byId = {for (final i in pool) i.id: i};
    final view = _TreeView(
      tree: tree,
      byId: byId,
      visible: visible,
      forced: forced,
    );

    final known = {for (final g in widget.groups) g.key};
    var sections = <(String?, List<PickerItem>)>[
      for (final g in widget.groups)
        (
          g.label,
          [
            for (final r in roots)
              if (r.group == g.key) r,
          ],
        ),
      (
        null,
        [
          for (final r in roots)
            if (!known.contains(r.group)) r,
        ],
      ),
    ].where((s) => s.$2.isNotEmpty).toList();
    // One group needs no heading: the sheet's title already names the list.
    if (sections.where((s) => s.$1 != null).length < 2) {
      sections = [
        if (sections.isNotEmpty) (null, [for (final s in sections) ...s.$2]),
      ];
    }

    final none = widget.none;
    final showNone = none != null && (query.isEmpty || none.showWhileSearching);
    final freeText = widget.freeText;
    final empty = sections.isEmpty;
    final emptyText = query.isEmpty ? widget.emptyText : widget.noMatchText;

    final noneInFirst =
        showNone && sections.isNotEmpty && sections.first.$1 == null;
    final nameRow = freeText == null ? null : _freeTextRow(context, freeText);
    final nameInList =
        nameRow != null &&
        widget.layout == PickerLayout.rows &&
        sections.isNotEmpty;
    final topCreate = (widget.create?.atTop ?? false)
        ? _createRow(items, tree, typed)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?topCreate,
        if (showNone && !noneInFirst)
          _layoutOf(context, const [], view, first: true, none: none),
        for (final (i, (label, group)) in sections.indexed) ...[
          if (label != null) AppListHeader(title: label),
          _layoutOf(
            context,
            group,
            view,
            first: i == 0 && label == null,
            none: i == 0 && noneInFirst ? none : null,
            tail: nameInList && i == sections.length - 1 ? nameRow : null,
          ),
        ],
        if (empty && emptyText != null) EmptyView.compact(message: emptyText),
        if (nameRow != null && !nameInList)
          SectionCard(
            first: sections.isEmpty && !showNone,
            children: [nameRow],
          ),
        for (final a in widget.actions)
          if (!a.pinned) _actionRow(context, a),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _freeTextRow(BuildContext context, PickerFreeText f) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _nameFocus.hasFocus;
    final leading = f.leading;
    return Material(
      key: _nameKey,
      color: focused
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: BusyLock(
        child: InkWell(
          onTap: focused ? null : _nameFocus.requestFocus,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PickerRow.rowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading(_name.text.trim()),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: AppInput.inline(
                      editing: true,
                      controller: _name,
                      focusNode: _nameFocus,
                      hint: f.hint,
                      maxLength: f.maxLength ?? 200,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionRow(BuildContext context, PickerAction a) {
    void tap() => Navigator.of(context).pop(PickerResult(action: a.id));
    if (a.destructive) {
      return DangerRow(
        icon: a.icon,
        label: a.label,
        onTap: tap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      );
    }
    // In the footer it reads as a "make something" button, like create.
    if (a.pinned) return PickerCreateRow(label: a.label, onTap: tap);
    return PickerRow(leading: Icon(a.icon), title: a.label, onTap: tap);
  }

  Widget _layoutOf(
    BuildContext context,
    List<PickerItem> roots,
    _TreeView view, {
    required bool first,
    PickerNone? none,
    Widget? tail,
  }) => switch (widget.layout) {
    PickerLayout.rows => _rows(
      roots,
      view,
      first: first,
      none: none,
      tail: tail,
    ),
    PickerLayout.cards => _cards(context, roots, view, none: none),
    PickerLayout.chips => _chips(roots, view, none: none),
  };

  bool get _noneSelected => widget.multi ? _sel.none : widget.noneSelected;

  Widget _rows(
    List<PickerItem> roots,
    _TreeView view, {
    required bool first,
    PickerNone? none,
    Widget? tail,
  }) {
    final rows = <Widget>[
      if (none != null)
        PickerRow(
          key: const ValueKey('picker-none'),
          leading: none.leading ?? (none.icon == null ? null : Icon(none.icon)),
          title: none.label,
          subtitle: none.subtitle,
          selected: !widget.multi && _noneSelected,
          checked: widget.multi ? _noneSelected : null,
          onTap: _tapNone,
        ),
    ];
    for (final r in roots) {
      _collectRows(rows, r, view, depth: 0);
    }
    return SectionCard(first: first, children: [...rows, ?tail]);
  }

  void _collectRows(
    List<Widget> out,
    PickerItem item,
    _TreeView view, {
    required int depth,
  }) {
    final tree = view.tree;
    final children = view.childrenOf(item.id);
    final hasChildren = children.isNotEmpty;
    final expanded =
        view.forced.contains(item.id) || _expanded.contains(item.id);
    final picked = _isSelected(item.id, tree);
    final theme = Theme.of(context);
    final include =
        widget.multi &&
        widget.children == PickerChildren.toggle &&
        hasChildren &&
        _sel.isPicked(item.id);

    Widget? trailing = item.trailing == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: item.trailing,
          );
    if (hasChildren) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?item.trailing,
          if (include)
            BusyLock(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(
                  () => _sel.setTakesChildren(
                    item.id,
                    !_sel.takesChildren(item.id),
                    tree,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.includeChildrenLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SelectCheck(
                      key: ValueKey('include-${item.id}'),
                      value: _sel.takesChildren(item.id),
                      tooltip: widget.includeChildrenLabel,
                      onTap: () => setState(
                        () => _sel.setTakesChildren(
                          item.id,
                          !_sel.takesChildren(item.id),
                          tree,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AppIconButton.flat(
            icon: expanded ? AppIcons.collapse : AppIcons.expand,
            onPressed: view.forced.contains(item.id)
                ? null
                : () => setState(() {
                    if (!_expanded.remove(item.id)) _expanded.add(item.id);
                  }),
          ),
        ],
      );
    }

    final row = PickerRow(
      key: ValueKey('row-${item.id}'),
      indent: depth * AppSpacing.xl,
      leading: item.leading,
      title: item.title,
      subtitle: item.subtitle,
      trailing: trailing,
      selected: !widget.multi && picked,
      checked: widget.multi ? picked : null,
      onTap: item.enabled ? () => _tap(item, tree) : null,
    );
    out.add(
      item.id == _scrollTarget
          ? KeyedSubtree(key: _selectedKey, child: row)
          : row,
    );
    if (hasChildren && expanded) {
      for (final c in children) {
        _collectRows(out, c, view, depth: depth + 1);
      }
    }
  }

  Widget _cards(
    BuildContext context,
    List<PickerItem> items,
    _TreeView view, {
    PickerNone? none,
  }) {
    final build = widget.cardBuilder ?? _defaultCard;
    final tiles = [
      if (none != null)
        KeyedSubtree(
          key: const ValueKey('picker-none'),
          child: AppCardPick(
            chosen: _noneSelected,
            child: _defaultCard(
              context,
              PickerItem(
                id: '',
                title: none.label,
                leading: none.icon == null ? null : Icon(none.icon),
              ),
              _noneSelected,
              _tapNone,
            ),
          ),
        ),
      for (final i in items)
        KeyedSubtree(
          key: ValueKey('row-${i.id}'),
          child: KeyedSubtree(
            key: i.id == _scrollTarget ? _selectedKey : null,
            child: AppCardPick(
              chosen: _isSelected(i.id, view.tree),
              child: build(
                context,
                i,
                _isSelected(i.id, view.tree),
                i.enabled ? () => _tap(i, view.tree) : null,
              ),
            ),
          ),
        ),
    ];
    final columns = MediaQuery.sizeOf(context).shortestSide >= 600 ? 3 : 2;
    const gap = AppSpacing.xs;
    final height = widget.cardHeight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: height != null
          ? GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: height,
              ),
              children: tiles,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var r = 0; r < tiles.length; r += columns)
                  Padding(
                    padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var c = 0; c < columns; c++) ...[
                            if (c > 0) const SizedBox(width: gap),
                            Expanded(
                              child: r + c < tiles.length
                                  ? tiles[r + c]
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _defaultCard(
    BuildContext context,
    PickerItem item,
    bool selected,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);
    return AppCard(
      style: AppCardStyle.bordered,
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.leading != null)
            IconTheme.merge(
              data: IconThemeData(
                size: 28,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              child: item.leading!,
            ),
          if (widget.cardHeight != null)
            const Spacer()
          else
            const SizedBox(height: AppSpacing.sm),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ?item.trailing,
        ],
      ),
    );
  }

  Widget _chips(List<PickerItem> items, _TreeView view, {PickerNone? none}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (none != null)
              AppChip(
                key: const ValueKey('picker-none'),
                label: none.label,
                icon: none.icon,
                selected: _noneSelected,
                dashed: !_noneSelected,
                onTap: _tapNone,
              ),
            for (final i in items)
              AppChip(
                key: ValueKey('row-${i.id}'),
                label: i.title,
                icon: i.icon,
                color: i.color,
                selected: _isSelected(i.id, view.tree),
                dashed: !_isSelected(i.id, view.tree),
                enabled: i.enabled,
                onTap: () => _tap(i, view.tree),
              ),
          ],
        ),
      );
}

/// The shown part of the tree: the items that passed the filter tab / depth,
/// and under a search only the matches and their parents.
class _TreeView {
  const _TreeView({
    required this.tree,
    required this.byId,
    required this.visible,
    required this.forced,
  });

  final PickerTree tree;
  final Map<String, PickerItem> byId;
  final Set<String>? visible;
  final Set<String> forced;

  List<PickerItem> childrenOf(String id) => [
    for (final c in tree.childrenOf(id))
      if (byId[c] case final item?)
        if (visible == null || visible!.contains(c)) item,
  ];
}
