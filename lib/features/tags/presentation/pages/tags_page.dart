import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/color_token.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tags_list_skeleton.dart';

enum _SortBy { name, usage, color, icon }

/// Tags — one page, no detail (`ux-overhaul-plan.md` §5). A 2-column grid
/// in both modes with a dashed "+ เพิ่มแท็ก" tile at the end.
///
/// View: search + colour/icon filters + sort + an ✏️ pill into edit. Edit: a
/// batch editor over
/// *all* tags (rename, recolour, re-icon, delete, add) with multi-select;
/// search/filters keep working, under four rules:
///  1. Save validates every row, including filtered-out ones — a hidden
///     invalid row clears the filters and scrolls to it.
///  2. Rows changed or added this session always stay visible.
///  3. Filtering a selected row out deselects it; "select all" = visible.
///  4. No re-sorting while editing.
class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage>
    with EditModeMixin<TagsPage, _TagsDraft> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _filterColors = {};
  final Set<String> _filterIcons = {};
  _SortBy _sort = _SortBy.name;

  /// After a save the view shows exactly the saved ids (in order), ignoring
  /// search/filter, so what you just edited doesn't vanish. Cleared when
  /// search/filter/sort changes or on refresh.
  List<String>? _stickyIds;

  final Set<String> _selected = {};
  int _newCounter = 0;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focus = {};
  final Map<String, GlobalKey> _tileKeys = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    initDraft(const _TagsDraft([]));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TagsCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  void onDraftRestored() {
    for (final d in working.items) {
      final c = _controllers[d.key];
      if (c != null && c.text != d.name) c.text = d.name;
    }
  }

  @override
  void cancelEdit() {
    _selected.clear();
    super.cancelEdit();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  TextEditingController _controllerFor(_TagDraft d) => _controllers.putIfAbsent(
    d.key,
    () => TextEditingController(text: d.name),
  );
  FocusNode _focusFor(String key) => _focus.putIfAbsent(key, FocusNode.new);
  GlobalKey _tileKey(String key) => _tileKeys.putIfAbsent(key, GlobalKey.new);

  static String? _colorOf(IconCode? c) =>
      (c?.iconColors.isNotEmpty ?? false) ? c!.iconColors.first : null;
  static String? _iconOf(IconCode? c) => c?.icon;

  /// Bulk actions show in edit mode always, dimmed until ≥1 is selected.
  bool get _canBulk => _selected.isNotEmpty && !isSaving;

  bool get _hasFilter =>
      _query.trim().isNotEmpty ||
      _filterColors.isNotEmpty ||
      _filterIcons.isNotEmpty;

  bool _matches(String name, IconCode? iconCode) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !name.toLowerCase().contains(q)) return false;
    if (_filterColors.isNotEmpty &&
        !_filterColors.contains(_colorOf(iconCode))) {
      return false;
    }
    if (_filterIcons.isNotEmpty && !_filterIcons.contains(_iconOf(iconCode))) {
      return false;
    }
    return true;
  }

  List<Tag> _sorted(List<Tag> all) {
    final list = List<Tag>.of(all);
    switch (_sort) {
      case _SortBy.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _SortBy.usage:
        list.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      case _SortBy.color:
        list.sort(
          (a, b) => (_colorOf(a.iconCode) ?? '').compareTo(
            _colorOf(b.iconCode) ?? '',
          ),
        );
      case _SortBy.icon:
        list.sort(
          (a, b) =>
              (_iconOf(a.iconCode) ?? '').compareTo(_iconOf(b.iconCode) ?? ''),
        );
    }
    return list;
  }

  /// View mode rows.
  List<Tag> _viewTags(List<Tag> all) {
    if (_stickyIds != null) {
      final byId = {for (final t in all) t.id: t};
      return [
        for (final id in _stickyIds!)
          if (byId[id] != null) byId[id]!,
      ];
    }
    return _sorted(all).where((t) => _matches(t.name, t.iconCode)).toList();
  }

  /// Edit mode rows — filter matches plus anything touched this session
  /// (rule 2), in the order they entered edit mode (rule 4).
  List<_TagDraft> _visibleDrafts() {
    final orig = {for (final d in original.items) d.key: d};
    return [
      for (final d in working.items)
        if (_matches(d.name, d.iconCode) || orig[d.key] != d) d,
    ];
  }

  /// Search/filter/sort changed.
  void _onFilterChanged(VoidCallback change) {
    setState(() {
      change();
      _stickyIds = null;
      if (isEditing) {
        // Rule 3: selection never hides behind a filter.
        final visible = _visibleDrafts().map((d) => d.key).toSet();
        _selected.retainWhere(visible.contains);
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    _query = '';
    _filterColors.clear();
    _filterIcons.clear();
  }

  // ── Edit lifecycle ──────────────────────────────────────────────────

  /// Enter edit over all tags, in the current sort order.
  void _beginEdit({String? focusKey, bool openIcon = false}) {
    if (!isEditing) {
      final all = _sorted(context.read<TagsCubit>().state.tags);
      resetDraft(
        _TagsDraft([
          for (final t in all)
            _TagDraft(
              key: t.id,
              serverId: t.id,
              name: t.name,
              iconCode: t.iconCode,
            ),
        ]),
      );
      _selected.clear();
      _stickyIds = null;
    }
    if (focusKey != null && openIcon) {
      enterEdit();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final d = working.items.where((e) => e.key == focusKey).firstOrNull;
        if (d != null) _openIconMaker(d);
      });
    } else {
      enterEdit(focus: focusKey == null ? null : _focusFor(focusKey));
    }
  }

  void _addTag() {
    _beginEdit();
    final key = 'new_${_newCounter++}';
    applyChange(working.add(_TagDraft(key: key, name: '')));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusFor(key).requestFocus();
      _scrollTo(key);
    });
  }

  void _toggleSelect(String key) => setState(
    () => _selected.contains(key) ? _selected.remove(key) : _selected.add(key),
  );

  void _toggleSelectAll(List<_TagDraft> visible) {
    setState(() {
      final keys = visible.map((d) => d.key);
      if (visible.isNotEmpty && keys.every(_selected.contains)) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(keys);
      }
    });
  }

  Future<void> _openIconMaker(_TagDraft draft) async {
    final l = AppLocalizations.of(context)!;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.tag,
      title: l.tagFormIconLabel,
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
    applyChange(
      working.map(
        (d) => d.key == draft.key ? d.copyWith(iconCode: result.iconCode) : d,
      ),
    );
  }

  // ── Bulk (selected rows) ────────────────────────────────────────────

  Future<void> _bulkColor() async {
    final l = AppLocalizations.of(context)!;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.tag,
      title: l.tagsBulkColor,
      showBackground: false,
      showBorder: false,
      showIconPicker: false,
      previewBuilder: (iconCode) => Align(
        alignment: Alignment.centerLeft,
        child: TagChip(
          tag: Tag(id: 'preview', name: 'Aa', iconCode: iconCode),
        ),
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    final colors = result.iconCode.iconColors;
    applyChange(
      working.map(
        (d) => _selected.contains(d.key)
            ? d.copyWith(
                iconCode: (d.iconCode ?? const IconCode()).copyWith(
                  iconColors: colors,
                ),
              )
            : d,
      ),
    );
  }

  Future<void> _bulkIcon() async {
    final l = AppLocalizations.of(context)!;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.tag,
      title: l.tagsBulkIcon,
      showBackground: false,
      showBorder: false,
      showColorPicker: false,
      previewBuilder: (iconCode) => Align(
        alignment: Alignment.centerLeft,
        child: TagChip(
          tag: Tag(id: 'preview', name: 'Aa', iconCode: iconCode),
        ),
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    final glyph = result.iconCode.icon;
    applyChange(
      working.map(
        (d) => _selected.contains(d.key)
            ? d.copyWith(
                iconCode: (d.iconCode ?? const IconCode()).copyWith(
                  icon: glyph,
                ),
              )
            : d,
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.tagDeleteConfirmTitle,
      message: l.tagDeleteConfirmBody,
      confirmLabel: l.tagDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    applyChange(
      _TagsDraft(
        working.items.where((d) => !_selected.contains(d.key)).toList(),
      ),
    );
    setState(_selected.clear);
  }

  // ── Save ────────────────────────────────────────────────────────────

  String? _validateName(AppLocalizations l, String key, String? v) {
    final name = v?.trim() ?? '';
    if (name.isEmpty) return l.tagFormNameRequired;
    if (name.length > 50) return l.tagFormNameTooLong;
    final lower = name.toLowerCase();
    final dup = working.items.any(
      (d) => d.key != key && d.name.trim().toLowerCase() == lower,
    );
    return dup ? l.tagFormNameDuplicate : null;
  }

  void _scrollTo(String key) {
    final ctx = _tileKeys[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  Future<void> _save() async {
    commitTextSession();
    final l = AppLocalizations.of(context)!;

    // Rule 1: validate every row, not just the mounted ones.
    final invalid = working.items
        .where((d) => _validateName(l, d.key, d.name) != null)
        .firstOrNull;
    if (invalid != null) {
      final visible = _visibleDrafts().any((d) => d.key == invalid.key);
      if (!visible) {
        setState(_clearFilters);
        showAppSnackBar(
          context,
          l.tagsFiltersClearedForError,
          tone: Tone.warning,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _formKey.currentState?.validate();
        _scrollTo(invalid.key);
      });
      return;
    }

    final cubit = context.read<TagsCubit>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    final resultIds = <String>[];
    try {
      final keptIds = {
        for (final d in working.items)
          if (d.serverId != null) d.serverId!,
      };
      for (final o in original.items) {
        if (o.serverId != null && !keptIds.contains(o.serverId)) {
          await cubit.remove(o.serverId!);
        }
      }
      final origById = {for (final o in original.items) o.serverId: o};
      for (final d in working.items) {
        final name = d.name.trim();
        if (d.serverId == null) {
          final created = await cubit.add(
            Tag(id: 'draft', name: name, iconCode: d.iconCode),
          );
          resultIds.add(created.id);
        } else {
          final orig = origById[d.serverId]!;
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
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _selected.clear();
    commitSaved(working);
    setState(() => _stickyIds = resultIds);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return editScope(
      Scaffold(
        // The bar floats over the body; the pinned column below starts with a
        // spacer of its height.
        extendBodyBehindAppBar: true,
        appBar: AppTopBar(
          title: isEditing ? l.tagFormTitleEdit : l.tagsTitle,
          showBack: true,
          editing: isEditing,
          onBack: isEditing ? handleBack : null,
        ),
        body: BlocBuilder<TagsCubit, TagsState>(
          builder: (context, state) => AsyncStateView(
            loading:
                state.status == TagsStatus.initial ||
                state.status == TagsStatus.loading,
            error: state.error,
            // Edit mode shows its drafts grid even before the first tag.
            isEmpty: !isEditing && state.tags.isEmpty,
            onRetry: context.read<TagsCubit>().load,
            skeleton: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: const LoadingView(skeleton: TagsListSkeleton()),
            ),
            empty: EmptyView(
              icon: AppIcons.tag,
              title: l.tagsEmptyTitle,
              message: l.tagsEmptyMessage,
              cta: AddTile(label: l.tagsAddNew, onTap: _addTag),
            ),
            builder: (context) {
              final visible = isEditing ? _visibleDrafts() : null;
              return Column(
                children: [
                  // Clear the transparent top bar.
                  SizedBox(height: MediaQuery.paddingOf(context).top),
                  AppSearchBar(
                    controller: _searchController,
                    hint: l.tagsSearchHint,
                    onChanged: (v) => _onFilterChanged(() => _query = v),
                  ),
                  SizedBox(height: 48, child: _toolRow(l, state.tags, visible)),
                  Expanded(
                    child: isEditing
                        ? _editGrid(l, visible!)
                        : _viewGrid(l, state.tags),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  // Row 2 — same height in both modes so the grid never jumps.
  //   view: [สี▾][ไอคอน▾] … [เรียง▾][✏️ แก้ไข]
  //   edit: [☐ n] [สี▾][ไอคอน▾] … [สี][ไอคอน][ลบ]
  Widget _toolRow(
    AppLocalizations l,
    List<Tag> tags,
    List<_TagDraft>? visible,
  ) {
    final codes = isEditing
        ? working.items.map((d) => d.iconCode)
        : tags.map((t) => t.iconCode);
    final colors = {for (final c in codes) ?_colorOf(c)}.toList()..sort();
    final icons = {for (final c in codes) ?_iconOf(c)}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (isEditing) ...[
            _SelectAllBox(
              visible: visible!,
              selected: _selected,
              tooltip: l.tagsSelectAll,
              onTap: () => _toggleSelectAll(visible),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          // Filters always on the left (scroll sideways if the selection
          // actions leave too little room).
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _colorFilter(l, colors),
                  const SizedBox(width: AppSpacing.sm),
                  _iconFilter(l, icons),
                ],
              ),
            ),
          ),
          // Edit: labelled actions on the selection, right-aligned, dimmed
          // until something is selected. Capped at ~62% of the row (scrolls on
          // a narrow phone) so the filters keep a foothold.
          if (isEditing) ...[
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.62,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    ActionPill(
                      icon: AppIcons.colorPicker,
                      label: l.tagsBulkColor,
                      onTap: _canBulk ? _bulkColor : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ActionPill(
                      icon: AppIcons.iconPicker,
                      label: l.tagsBulkIcon,
                      onTap: _canBulk ? _bulkIcon : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ActionPill(
                      icon: AppIcons.delete,
                      label: l.commonDelete,
                      destructive: true,
                      onTap: _canBulk ? _bulkDelete : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isEditing) ...[
            const SizedBox(width: AppSpacing.sm),
            SortChip<_SortBy>(
              selected: _sort,
              onSelected: (s) => _onFilterChanged(() => _sort = s),
              options: [
                SortOption(_SortBy.name, l.tagFormNameLabel),
                SortOption(_SortBy.usage, l.tagsSortUsage),
                SortOption(_SortBy.color, l.tagFormColorLabel),
                SortOption(_SortBy.icon, l.tagFormIconLabel),
              ],
            ),
            // The way into batch edit (the top bar carries no page actions;
            // long-pressing a tile works too).
            const SizedBox(width: AppSpacing.xs),
            ActionPill(
              icon: AppIcons.edit,
              label: l.commonEdit,
              onTap: _beginEdit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _colorFilter(AppLocalizations l, List<String> tokens) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return PopoverAnchor(
      builder: (context, toggle) => FilterDropdownChip(
        label: l.tagFormColorLabel,
        icon: AppIcons.colorPicker,
        count: _filterColors.length,
        onTap: tokens.isEmpty ? null : toggle,
      ),
      contentBuilder: (context, close) => StatefulBuilder(
        builder: (context, setPopover) => ColorSwatchGrid(
          colors: [for (final t in tokens) resolveColor(t, palette)],
          selected: {
            for (final (i, t) in tokens.indexed)
              if (_filterColors.contains(t)) i,
          },
          onToggle: (i) {
            final t = tokens[i];
            _onFilterChanged(
              () => _filterColors.contains(t)
                  ? _filterColors.remove(t)
                  : _filterColors.add(t),
            );
            setPopover(() {});
          },
          onClear: () {
            _onFilterChanged(_filterColors.clear);
            setPopover(() {});
          },
        ),
      ),
    );
  }

  Widget _iconFilter(AppLocalizations l, List<String> glyphs) {
    return PopoverAnchor(
      builder: (context, toggle) => FilterDropdownChip(
        label: l.tagFormIconLabel,
        icon: AppIcons.iconPicker,
        count: _filterIcons.length,
        onTap: glyphs.isEmpty ? null : toggle,
      ),
      contentBuilder: (context, close) => StatefulBuilder(
        builder: (context, setPopover) => _IconSwatchGrid(
          glyphs: glyphs,
          selected: _filterIcons,
          onToggle: (g) {
            _onFilterChanged(
              () => _filterIcons.contains(g)
                  ? _filterIcons.remove(g)
                  : _filterIcons.add(g),
            );
            setPopover(() {});
          },
          onClear: () {
            _onFilterChanged(_filterIcons.clear);
            setPopover(() {});
          },
        ),
      ),
    );
  }

  Widget _viewGrid(AppLocalizations l, List<Tag> tags) {
    final shown = _viewTags(tags);
    return PullToRefresh(
      onRefresh: () async {
        setState(() => _stickyIds = null);
        await context.read<TagsCubit>().load();
      },
      child: _Grid(
        children: [
          for (final t in shown)
            _TagTile(
              key: _tileKey(t.id),
              editing: false,
              name: t.name,
              iconCode: t.iconCode,
              usage: l.tagsUsageCount(t.usageCount),
              onEnterEdit: () => _beginEdit(focusKey: t.id),
              onEnterEditIcon: () => _beginEdit(focusKey: t.id, openIcon: true),
            ),
          if (shown.isEmpty && _hasFilter)
            _GridMessage(text: l.tagsNoMatch)
          else
            AddTile(label: l.tagsAddNew, onTap: _addTag),
        ],
      ),
    );
  }

  Widget _editGrid(AppLocalizations l, List<_TagDraft> visible) {
    return Form(
      key: _formKey,
      child: _Grid(
        children: [
          for (final d in visible)
            _TagTile(
              key: _tileKey(d.key),
              editing: true,
              name: d.name,
              iconCode: d.iconCode,
              selected: _selected.contains(d.key),
              onToggleSelect: () => _toggleSelect(d.key),
              controller: _controllerFor(d),
              focusNode: _focusFor(d.key),
              onIconTap: () => _openIconMaker(d),
              onNameChanged: (v) => applyTextChange(
                d.key,
                working.map((e) => e.key == d.key ? e.copyWith(name: v) : e),
              ),
              validator: (v) => _validateName(l, d.key, v),
            ),
          if (visible.isEmpty && _hasFilter) _GridMessage(text: l.tagsNoMatch),
          AddTile(label: l.tagsAddNew, onTap: isSaving ? null : _addTag),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Layout pieces
// ────────────────────────────────────────────────────────────────────

/// Two equal columns that keep every child mounted (unlike a lazy grid), so
/// the form validates all visible rows and `ensureVisible` can reach them.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  static const _gap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final full = box.maxWidth - AppSpacing.lg * 2;
        final cell = (full - _gap) / 2;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Bottom room for the shell's FAB.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            96,
          ),
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final c in children)
                SizedBox(
                  width: c is _GridMessage ? full : cell,
                  // Same inset as a tile's SelectableFrame (gap 3 + ring 2) so
                  // the add tile lines up with its row.
                  child: c is AddTile
                      ? Padding(
                          padding: const EdgeInsets.all(5),
                          child: SizedBox(height: _tileMinHeight, child: c),
                        )
                      : c,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GridMessage extends StatelessWidget {
  const _GridMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// "[☐ n]" — select / deselect everything currently visible.
class _SelectAllBox extends StatelessWidget {
  const _SelectAllBox({
    required this.visible,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final List<_TagDraft> visible;
  final Set<String> selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = visible.where((d) => selected.contains(d.key)).length;
    final value = n == 0 ? false : (n == visible.length ? true : null);
    return InkWell(
      onTap: visible.isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectCheck(
              value: value,
              tooltip: tooltip,
              onTap: visible.isEmpty ? null : onTap,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('$n', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

/// Icon filter popover — glyph swatches with the selection ring, + ล้าง.
class _IconSwatchGrid extends StatelessWidget {
  const _IconSwatchGrid({
    required this.glyphs,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final List<String> glyphs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final g in glyphs)
                SelectableFrame(
                  selected: selected.contains(g),
                  radius: 999,
                  child: InkWell(
                    onTap: () => onToggle(g),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.surfaceContainerHighest,
                      child: Icon(
                        IconRegistry.get(g, fallback: AppIcons.tag),
                        size: 18,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            PopoverClearItem(onPressed: onClear),
          ],
        ],
      ),
    );
  }
}

/// Tile height without a validation error — the add tile matches it.
const double _tileMinHeight = 58;

/// One grid cell for both modes — icon + name with constant metrics (the
/// name is the same field, only its border/editability toggle). Edit adds
/// the selection ring and a corner check; tapping the cell selects it.
class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.editing,
    required this.name,
    required this.iconCode,
    this.usage,
    this.onEnterEdit,
    this.onEnterEditIcon,
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

  // View
  final String? usage;
  final VoidCallback? onEnterEdit;
  final VoidCallback? onEnterEditIcon;

  // Edit
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
    final textTheme = Theme.of(context).textTheme;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: c),
    );

    final field = TextFormField(
      controller: editing ? controller : null,
      initialValue: editing ? null : name,
      focusNode: editing ? focusNode : null,
      readOnly: !editing,
      maxLength: 50,
      style: textTheme.bodyLarge,
      onChanged: editing ? onNameChanged : null,
      validator: editing ? validator : null,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: false,
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        enabledBorder: border(editing ? scheme.outline : Colors.transparent),
        focusedBorder: border(scheme.primary),
        border: border(editing ? scheme.outline : Colors.transparent),
      ),
    );

    final hasUsage = !editing && (usage?.isNotEmpty ?? false);
    final tile = Container(
      constraints: const BoxConstraints(minHeight: _tileMinHeight),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Edit: the select check slides in on the left while the usage
          // slot on the right slides out — the name keeps (about) its width.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: editing
                ? SelectCheck(value: selected, onTap: onToggleSelect)
                : const SizedBox(height: 28),
          ),
          GestureDetector(
            onLongPress: editing ? null : onEnterEditIcon,
            child: EditableCircle(
              size: 32,
              onTap: editing ? onIconTap : null,
              child: IconDisplay(
                type: IconType.tag,
                size: 32,
                iconCode: iconCode,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: editing
                ? field
                : GestureDetector(
                    onLongPress: onEnterEdit,
                    behavior: HitTestBehavior.opaque,
                    child: AbsorbPointer(child: field),
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: editing
                ? const SizedBox(width: AppSpacing.xs)
                : SizedBox(
                    width: 28,
                    child: hasUsage
                        ? Text(
                            usage!,
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
          ),
        ],
      ),
    );

    // Framed in both modes so the cell keeps the same box; the ring only
    // shows when selected (edit).
    return SelectableFrame(
      selected: editing && selected,
      radius: AppRadius.md,
      child: editing
          ? GestureDetector(
              onTap: onToggleSelect,
              behavior: HitTestBehavior.opaque,
              child: tile,
            )
          : tile,
    );
  }
}
// ────────────────────────────────────────────────────────────────────
// Editing snapshot — the whole list is one draft (undo / dirty).
// ────────────────────────────────────────────────────────────────────

class _TagsDraft {
  const _TagsDraft(this.items);

  final List<_TagDraft> items;

  _TagsDraft add(_TagDraft d) => _TagsDraft([...items, d]);
  _TagsDraft map(_TagDraft Function(_TagDraft) f) =>
      _TagsDraft([for (final d in items) f(d)]);

  @override
  bool operator ==(Object other) =>
      other is _TagsDraft && listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(items);
}

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
