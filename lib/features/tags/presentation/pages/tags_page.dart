import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/color_token.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/reorder_action_bar.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tags_list_skeleton.dart';

enum _SortBy { name, usage, color, icon }

/// Tags management — one page, no detail. View mode browses (search + color/
/// icon filter + sort); edit mode is an inline batch editor (rename, recolor,
/// re-icon, delete, add — many at once, with multi-select).
class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  // View: search / filter / sort.
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _filterColors = {};
  final Set<String> _filterIcons = {};
  _SortBy _sort = _SortBy.name;

  /// When set, the view shows exactly these ids (order preserved) and ignores
  /// query/filter — the "sticky" result after an edit. Cleared when the user
  /// touches search/filter/sort or pulls to refresh.
  List<String>? _stickyIds;

  // Edit (batch).
  bool _editMode = false;
  bool _saving = false;
  List<_TagDraft> _original = const [];
  List<_TagDraft> _working = const [];
  final List<List<_TagDraft>> _undoStack = [];
  final Set<String> _selected = {};
  int _newCounter = 0;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focus = {};
  String? _sessionKey;
  List<_TagDraft>? _sessionStart;
  Timer? _debounce;

  final _formKey = GlobalKey<FormState>();
  ShellChromeController? _shellChrome;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellChrome = ShellChrome.of(context);
  }

  @override
  void dispose() {
    if (_editMode) _shellChrome?.show();
    _debounce?.cancel();
    _searchController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _dirty => !listEquals(_working, _original);
  bool get _canUndo => _sessionStart != null || _undoStack.isNotEmpty;
  bool get _allSelected =>
      _working.isNotEmpty && _selected.length == _working.length;

  TextEditingController _controllerFor(_TagDraft d) =>
      _controllers.putIfAbsent(d.key, () => TextEditingController(text: d.name));

  FocusNode _focusFor(String key) =>
      _focus.putIfAbsent(key, () => FocusNode());

  String? _tagColor(Tag t) => (t.iconCode?.iconColors.isNotEmpty ?? false)
      ? t.iconCode!.iconColors.first
      : null;
  String? _tagIcon(Tag t) => t.iconCode?.icon;

  // ── Display (view) ──────────────────────────────────────────────────

  List<Tag> _displayTags(List<Tag> all) {
    if (_stickyIds != null) {
      final byId = {for (final t in all) t.id: t};
      return [
        for (final id in _stickyIds!)
          if (byId.containsKey(id)) byId[id]!,
      ];
    }
    var list = List<Tag>.of(all);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.name.toLowerCase().contains(q)).toList();
    }
    if (_filterColors.isNotEmpty) {
      list = list.where((t) => _filterColors.contains(_tagColor(t))).toList();
    }
    if (_filterIcons.isNotEmpty) {
      list = list.where((t) => _filterIcons.contains(_tagIcon(t))).toList();
    }
    switch (_sort) {
      case _SortBy.name:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _SortBy.usage:
        list.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      case _SortBy.color:
        list.sort((a, b) => (_tagColor(a) ?? '').compareTo(_tagColor(b) ?? ''));
      case _SortBy.icon:
        list.sort((a, b) => (_tagIcon(a) ?? '').compareTo(_tagIcon(b) ?? ''));
    }
    return list;
  }

  void _resetSticky() => _stickyIds = null;

  // ── Mode lifecycle ──────────────────────────────────────────────────

  void _enterEdit({String? focusKey, bool openIcon = false}) {
    final shown = _displayTags(context.read<TagsCubit>().state.tags);
    _original = [
      for (final t in shown)
        _TagDraft(key: t.id, serverId: t.id, name: t.name, iconCode: t.iconCode),
    ];
    _working = List.of(_original);
    _undoStack.clear();
    _selected.clear();
    for (final d in _working) {
      _controllerFor(d).text = d.name;
    }
    HapticFeedback.lightImpact();
    _shellChrome?.hide();
    setState(() => _editMode = true);
    if (focusKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (openIcon) {
          _openIconMaker(_working.firstWhere((e) => e.key == focusKey));
        } else {
          _focusFor(focusKey).requestFocus();
        }
      });
    }
  }

  void _cancel() {
    _debounce?.cancel();
    _debounce = null;
    FocusScope.of(context).unfocus();
    _shellChrome?.show();
    setState(() {
      _working = List.of(_original);
      _undoStack.clear();
      _selected.clear();
      _sessionStart = null;
      _sessionKey = null;
      _editMode = false;
      _saving = false;
      _syncControllers();
    });
  }

  void _syncControllers() {
    for (final d in _working) {
      final c = _controllers[d.key];
      if (c != null && c.text != d.name) c.text = d.name;
    }
  }

  // ── Undo ────────────────────────────────────────────────────────────

  void _commitTextSession() {
    _debounce?.cancel();
    _debounce = null;
    final start = _sessionStart;
    _sessionStart = null;
    _sessionKey = null;
    if (start != null && !listEquals(start, _working)) _undoStack.add(start);
  }

  void _onNameChanged(String key, String value) {
    if (_sessionKey != key) {
      _commitTextSession();
      _sessionKey = key;
      _sessionStart = List.of(_working);
    }
    setState(() {
      _working = [
        for (final d in _working) d.key == key ? d.copyWith(name: value) : d,
      ];
    });
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => setState(_commitTextSession),
    );
  }

  void _applyDiscrete(List<_TagDraft> next) {
    _commitTextSession();
    setState(() {
      _undoStack.add(List.of(_working));
      _working = next;
    });
    HapticFeedback.selectionClick();
  }

  void _undo() {
    HapticFeedback.selectionClick();
    if (_sessionStart != null) {
      final start = _sessionStart!;
      _debounce?.cancel();
      _debounce = null;
      _sessionStart = null;
      _sessionKey = null;
      setState(() {
        _working = start;
        _syncControllers();
      });
    } else if (_undoStack.isNotEmpty) {
      setState(() {
        _working = _undoStack.removeLast();
        _syncControllers();
      });
    }
  }

  // ── Row ops ─────────────────────────────────────────────────────────

  void _addRow() {
    if (!_editMode) _enterEdit();
    final key = 'new_${_newCounter++}';
    _applyDiscrete([..._working, _TagDraft(key: key, name: '')]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(key).requestFocus();
    });
  }

  void _toggleSelect(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_working.map((d) => d.key));
      }
    });
  }

  Future<void> _openIconMaker(_TagDraft draft) async {
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.tag,
      initial: draft.iconCode,
      showBackground: false,
      showBorder: false,
      previewBuilder: (iconCode) => Align(
        alignment: Alignment.centerLeft,
        child: TagChip(
          tag: Tag(id: 'preview', name: draft.name, iconCode: iconCode),
        ),
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    _applyDiscrete([
      for (final d in _working)
        d.key == draft.key ? d.copyWith(iconCode: result.iconCode) : d,
    ]);
  }

  // ── Bulk ────────────────────────────────────────────────────────────

  Future<void> _bulkColor() async {
    if (_selected.isEmpty) return;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.tag,
      showBackground: false,
      showBorder: false,
      showIconPicker: false, // colour only
      previewBuilder: (iconCode) => Align(
        alignment: Alignment.centerLeft,
        child: TagChip(tag: Tag(id: 'preview', name: 'Aa', iconCode: iconCode)),
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    final colors = result.iconCode.iconColors;
    _applyDiscrete([
      for (final d in _working)
        _selected.contains(d.key)
            ? d.copyWith(
                iconCode:
                    (d.iconCode ?? const IconCode()).copyWith(iconColors: colors))
            : d,
    ]);
  }

  Future<void> _bulkIcon() async {
    if (_selected.isEmpty) return;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.tag,
      showBackground: false,
      showBorder: false,
      showColorPicker: false, // icon only
      previewBuilder: (iconCode) => Align(
        alignment: Alignment.centerLeft,
        child: TagChip(tag: Tag(id: 'preview', name: 'Aa', iconCode: iconCode)),
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    final glyph = result.iconCode.icon;
    _applyDiscrete([
      for (final d in _working)
        _selected.contains(d.key)
            ? d.copyWith(
                iconCode: (d.iconCode ?? const IconCode()).copyWith(icon: glyph))
            : d,
    ]);
  }

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tagDeleteConfirmTitle),
        content: Text(l.tagDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.tagDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _applyDiscrete(_working.where((d) => !_selected.contains(d.key)).toList());
    setState(() => _selected.clear());
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    _commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<TagsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final resultIds = <String>[];
    try {
      final keptIds = _working
          .where((d) => d.serverId != null)
          .map((d) => d.serverId!)
          .toSet();
      for (final o in _original) {
        if (o.serverId != null && !keptIds.contains(o.serverId)) {
          await cubit.remove(o.serverId!);
        }
      }
      for (final d in _working) {
        final name = d.name.trim();
        if (d.serverId == null) {
          final created =
              await cubit.add(Tag(id: 'draft', name: name, iconCode: d.iconCode));
          resultIds.add(created.id);
        } else {
          final orig = _original.firstWhere((o) => o.serverId == d.serverId);
          if (orig.name != name || orig.iconCode != d.iconCode) {
            await cubit.update(
              Tag(id: d.serverId!, name: name, iconCode: d.iconCode),
            );
          }
          resultIds.add(d.serverId!);
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _shellChrome?.show();
    setState(() {
      _editMode = false;
      _saving = false;
      _undoStack.clear();
      _selected.clear();
      _stickyIds = resultIds;
    });
  }

  // ── Filter popups (anchored to the chip) ────────────────────────────

  Widget _colorFilterChip(AppLocalizations l, List<Tag> tags, bool enabled) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final colors = <String>{
      for (final t in tags)
        if (_tagColor(t) != null) _tagColor(t)!,
    }.toList();
    return PopupMenuButton<void>(
      enabled: enabled,
      tooltip: '',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 304),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: StatefulBuilder(
            builder: (context, setMenu) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in colors)
                  GestureDetector(
                    onTap: () {
                      setMenu(() => _filterColors.contains(c)
                          ? _filterColors.remove(c)
                          : _filterColors.add(c));
                      setState(_resetSticky);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: resolveColor(c, palette),
                      child: _filterColors.contains(c)
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      child: _FilterChip(
        icon: Icons.palette_outlined,
        label: l.tagFormColorLabel,
        count: _filterColors.length,
        enabled: enabled,
      ),
    );
  }

  Widget _iconFilterChip(AppLocalizations l, List<Tag> tags, bool enabled) {
    final scheme = Theme.of(context).colorScheme;
    final icons = <String>{
      for (final t in tags)
        if (_tagIcon(t) != null) _tagIcon(t)!,
    }.toList();
    return PopupMenuButton<void>(
      enabled: enabled,
      tooltip: '',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 304),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: StatefulBuilder(
            builder: (context, setMenu) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in icons)
                  GestureDetector(
                    onTap: () {
                      setMenu(() => _filterIcons.contains(g)
                          ? _filterIcons.remove(g)
                          : _filterIcons.add(g));
                      setState(_resetSticky);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: _filterIcons.contains(g)
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      child: Icon(
                        IconRegistry.get(g, fallback: Icons.label_outline),
                        size: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      child: _FilterChip(
        icon: Icons.category_outlined,
        label: l.tagFormIconLabel,
        count: _filterIcons.length,
        enabled: enabled,
      ),
    );
  }

  String _sortLabel(AppLocalizations l, _SortBy s) {
    switch (s) {
      case _SortBy.name:
        return l.tagFormNameLabel;
      case _SortBy.usage:
        return 'Usage';
      case _SortBy.color:
        return l.tagFormColorLabel;
      case _SortBy.icon:
        return l.tagFormIconLabel;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_editMode && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_editMode && !_saving) _cancel();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: l.tagsTitle,
          showBack: true,
          editing: _editMode,
          onBack: _editMode ? _cancel : null,
          actions: _editMode
              ? const <AppBarAction>[]
              : [
                  AppBarAction(
                    icon: Icons.edit_outlined,
                    tooltip: l.commonEdit,
                    onPressed: () => _enterEdit(),
                  ),
                ],
        ),
        body: BlocBuilder<TagsCubit, TagsState>(
          builder: (context, state) {
            final isLoading =
                state.status == TagsStatus.loading && state.tags.isEmpty;
            if (isLoading) {
              return const LoadingView(skeleton: TagsListSkeleton());
            }
            return _buildBody(l, state.tags);
          },
        ),
        bottomNavigationBar: _editMode
            ? ReorderActionBar(
                canUndo: _canUndo && !_saving,
                canSave: _dirty && !_saving,
                cancelLabel: l.commonCancel,
                saveLabel: l.commonSave,
                undoTooltip: l.categoriesUndo,
                onCancel: _saving ? () {} : _cancel,
                onUndo: _undo,
                onSave: _save,
              )
            : null,
      ),
    );
  }

  // Fixed slot heights so the top toolbar occupies the same space in both
  // modes — view fills both rows (search + filter/sort); edit uses row 1 for
  // the bulk-action bar and leaves row 2 blank. Keeps the list from jumping.
  static const double _row1H = 56;
  static const double _row2H = 48;

  Widget _buildBody(AppLocalizations l, List<Tag> tags) {
    return Column(
      children: [
        _buildTopBar(l, tags),
        Expanded(child: _buildList(l, tags)),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations l, List<Tag> tags) {
    return Column(
      children: [
        SizedBox(
          height: _row1H,
          child: _editMode ? _actionRow(l) : _searchRow(l),
        ),
        SizedBox(
          height: _row2H,
          child: _editMode ? null : _filterSortRow(l, tags),
        ),
      ],
    );
  }

  // View, row 1: search + add.
  Widget _searchRow(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _query = v;
                _resetSticky();
              }),
              decoration: InputDecoration(
                isDense: true,
                hintText: l.commonSearch,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: l.tagsAddNew,
            icon: const Icon(Icons.add),
            onPressed: _addRow,
          ),
        ],
      ),
    );
  }

  // View, row 2: color/icon filter + sort.
  Widget _filterSortRow(AppLocalizations l, List<Tag> tags) {
    final scheme = Theme.of(context).colorScheme;
    final hasColors = tags.any((t) => _tagColor(t) != null);
    final hasIcons = tags.any((t) => _tagIcon(t) != null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          _colorFilterChip(l, tags, hasColors),
          const SizedBox(width: AppSpacing.sm),
          _iconFilterChip(l, tags, hasIcons),
          const Spacer(),
          PopupMenuButton<_SortBy>(
            initialValue: _sort,
            onSelected: (s) => setState(() {
              _sort = s;
              _resetSticky();
            }),
            itemBuilder: (_) => [
              for (final s in _SortBy.values)
                PopupMenuItem(value: s, child: Text(_sortLabel(l, s))),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(_sortLabel(l, _sort)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edit, row 1: bulk-action bar (select-all + color/icon/delete).
  Widget _actionRow(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    final hasSel = _selected.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Checkbox(
            value: _allSelected,
            tristate: true,
            onChanged: (_) => _toggleSelectAll(),
          ),
          Text(
            '${_selected.length}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          IconButton(
            tooltip: l.tagFormColorLabel,
            icon: const Icon(Icons.palette_outlined),
            onPressed: hasSel ? _bulkColor : null,
          ),
          IconButton(
            tooltip: l.tagFormIconLabel,
            icon: const Icon(Icons.category_outlined),
            onPressed: hasSel ? _bulkIcon : null,
          ),
          IconButton(
            tooltip: l.tagDeleteConfirmAction,
            icon: Icon(Icons.delete_outline,
                color: hasSel ? scheme.error : null),
            onPressed: hasSel ? _bulkDelete : null,
          ),
        ],
      ),
    );
  }

  /// One list for both modes. Rows keep a stable `row_<id>` key so toggling
  /// edit reuses the same elements — the leading checkbox then animates in via
  /// [AnimatedSize] and the icon/name slide instead of snapping.
  Widget _buildList(AppLocalizations l, List<Tag> tags) {
    if (!_editMode && tags.isEmpty) {
      return EmptyView(
        icon: Icons.sell_outlined,
        title: l.tagsEmptyTitle,
        message: l.tagsEmptyMessage,
      );
    }

    final rows = <Widget>[];
    if (_editMode) {
      for (final d in _working) {
        rows.add(_TagRow(
          key: ValueKey('row_${d.key}'),
          editing: true,
          name: d.name,
          iconCode: d.iconCode,
          selected: _selected.contains(d.key),
          onToggleSelect: () => _toggleSelect(d.key),
          controller: _controllerFor(d),
          focusNode: _focusFor(d.key),
          onIconTap: () => _openIconMaker(d),
          onNameChanged: (v) => _onNameChanged(d.key, v),
          validator: (v) => _validateName(l, d.key, v),
        ));
      }
      rows.add(const SizedBox(height: AppSpacing.sm));
      rows.add(OutlinedButton.icon(
        onPressed: _addRow,
        icon: const Icon(Icons.add),
        label: Text(l.tagsAddNew),
        style:
            OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ));
    } else {
      final shown = _displayTags(tags);
      if (shown.isEmpty) {
        rows.add(Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Center(
            child: Text(
              l.tagsEmptyTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ));
      } else {
        for (final t in shown) {
          rows.add(_TagRow(
            key: ValueKey('row_${t.id}'),
            editing: false,
            name: t.name,
            iconCode: t.iconCode,
            usage: l.tagsUsageCount(t.usageCount),
            onEnterEdit: () => _enterEdit(focusKey: t.id),
          ));
        }
      }
    }

    return Form(
      key: _formKey,
      child: PullToRefresh(
        onRefresh: _editMode
            ? () async {}
            : () async {
                setState(_resetSticky);
                await context.read<TagsCubit>().load();
              },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
          children: rows,
        ),
      ),
    );
  }

  String? _validateName(AppLocalizations l, String key, String? v) {
    final name = v?.trim() ?? '';
    if (name.isEmpty) return l.tagFormNameRequired;
    if (name.length > 50) return l.tagFormNameTooLong;
    final lower = name.toLowerCase();
    final dup = _working.any(
      (d) => d.key != key && d.name.trim().toLowerCase() == lower,
    );
    if (dup) return l.tagFormNameDuplicate;
    return null;
  }
}

// ────────────────────────────────────────────────────────────────────

class _TagDraft {
  const _TagDraft({
    required this.key,
    this.serverId,
    required this.name,
    this.iconCode,
  });

  final String key;
  final String? serverId;
  final String name;
  final IconCode? iconCode;

  _TagDraft copyWith({String? name, IconCode? iconCode}) => _TagDraft(
        key: key,
        serverId: serverId,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
      );

  @override
  bool operator ==(Object other) =>
      other is _TagDraft &&
      other.key == key &&
      other.serverId == serverId &&
      other.name == name &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(key, serverId, name, iconCode);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.count,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = count > 0;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: active ? scheme.secondaryContainer : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(active ? '$label ($count)' : label),
            Icon(Icons.arrow_drop_down, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// One row for both modes — constant metrics (icon + name field + fixed
/// trailing). Edit adds a leading checkbox; name toggles editability via a
/// transparent↔outline border so nothing reflows.
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.editing,
    required this.name,
    required this.iconCode,
    this.usage,
    this.onEnterEdit,
    this.selected = false,
    this.onToggleSelect,
    this.controller,
    this.focusNode,
    this.onIconTap,
    this.onNameChanged,
    this.validator,
    super.key,
  });

  final bool editing;
  final String name;
  final IconCode? iconCode;

  final String? usage;
  final VoidCallback? onEnterEdit;

  final bool selected;
  final VoidCallback? onToggleSelect;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onIconTap;
  final ValueChanged<String>? onNameChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final field = TextFormField(
      controller: editing ? controller : null,
      initialValue: editing ? null : name,
      focusNode: editing ? focusNode : null,
      readOnly: !editing,
      maxLength: 50,
      style: Theme.of(context).textTheme.bodyLarge,
      onChanged: editing ? onNameChanged : null,
      validator: editing ? validator : null,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: _rowBorder(editing ? scheme.outline : Colors.transparent),
        focusedBorder: _rowBorder(scheme.primary),
        border: _rowBorder(editing ? scheme.outline : Colors.transparent),
      ),
    );

    final nameWidget = editing
        ? field
        : GestureDetector(
            onLongPress: onEnterEdit,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(child: field),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading checkbox grows from zero width in edit mode so the icon
          // and name slide smoothly instead of a dead gutter in view mode.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: editing
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onToggleSelect?.call(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                : const SizedBox(height: 36),
          ),
          EditableCircle(
            size: 36,
            onTap: editing ? onIconTap : null,
            child: IconDisplay(type: IconType.tag, size: 36, iconCode: iconCode),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: nameWidget),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 44,
            child: editing
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: (usage != null && usage!.isNotEmpty)
                        ? Text(
                            usage!,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          )
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _rowBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
