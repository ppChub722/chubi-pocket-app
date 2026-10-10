import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/color_token.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tags_list_skeleton.dart';

enum _SortBy { name, usage, color, icon }

/// Tags — one page, no detail (`ux-overhaul-plan.md` §5). The library list
/// shared with categories / contacts (owner 2026-10-10): [ListRow]s (icon ·
/// name · description · ×usage) with a dashed "+ เพิ่มแท็ก" tile at the end.
///
/// View: search, then [สี▾][ไอคอน▾] … [⇅ sort▾](✏️); long-press a row or ✏️
/// into edit. Edit: a batch editor over *all* tags (rename, recolour,
/// re-icon, delete, add) with a [SelectCheck] per row; deletes are staged
/// until บันทึก. Search keeps working (the colour/icon filters don't),
/// under four rules:
/// search keeps working (the colour/icon filters don't), under four rules:
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

  /// Colour / icon filters are view-only — edit mode ignores them (and
  /// shows no filter chips); they're back as they were on exit.
  bool get _hasFilter =>
      _query.trim().isNotEmpty ||
      (!isEditing && (_filterColors.isNotEmpty || _filterIcons.isNotEmpty));

  bool _matches(String name, IconCode? iconCode) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty && !name.toLowerCase().contains(q)) return false;
    if (isEditing) return true;
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
  void _beginEdit({String? focusKey}) {
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
              description: t.description ?? '',
              note: t.note ?? '',
            ),
        ]),
      );
      _selected.clear();
      _stickyIds = null;
    }
    enterEdit(focus: focusKey == null ? null : _focusFor(focusKey));
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
      previewBuilder: (iconCode) => Center(
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
      previewBuilder: (iconCode) => Center(
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
      previewBuilder: (iconCode) => Center(
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

  /// Staged — the rows go now, the server delete happens on บันทึก (ยกเลิก /
  /// ↶ bring them back), so the confirm says so.
  Future<void> _bulkDelete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.tagDeleteConfirmTitle,
      message: l.tagsBulkDeleteConfirmBody,
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
    if (name.length > TextLimits.tagName) return l.tagFormNameTooLong;
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
    // What has reached the server — a failure part-way rebases the draft on
    // it, so a retry doesn't delete / create / update twice.
    final removed = <String>{};
    final createdIds = <String, String>{}; // draft key → new server id
    final updated = <String>{}; // draft keys
    try {
      final keptIds = {
        for (final d in working.items)
          if (d.serverId != null) d.serverId!,
      };
      for (final o in original.items) {
        if (o.serverId != null && !keptIds.contains(o.serverId)) {
          await cubit.remove(o.serverId!);
          removed.add(o.serverId!);
        }
      }
      final origById = {for (final o in original.items) o.serverId: o};
      for (final d in working.items) {
        final name = d.name.trim();
        // Update is a full replace: the description / note the page doesn't
        // show (tags are name-only for now) ride along unchanged, or they
        // would be wiped.
        final tag = Tag(
          id: d.serverId ?? 'draft',
          name: name,
          iconCode: d.iconCode,
          description: d.description.isEmpty ? null : d.description,
          note: d.note.isEmpty ? null : d.note,
        );
        if (d.serverId == null) {
          final created = await cubit.add(tag);
          createdIds[d.key] = created.id;
        } else {
          final orig = origById[d.serverId]!;
          if (orig.name != name || orig.iconCode != d.iconCode) {
            await cubit.update(tag);
            updated.add(d.key);
          }
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _rebaseOnSaved(removed, createdIds, updated);
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _selected.clear();
    final saved = _withCreated(createdIds);
    commitSaved(saved);
    setState(() => _stickyIds = [for (final d in saved.items) d.serverId!]);
  }

  /// [working] with the server ids of the rows created so far.
  _TagsDraft _withCreated(Map<String, String> createdIds) => working.map(
    (d) => createdIds[d.key] == null ? d : d.withServerId(createdIds[d.key]!),
  );

  /// A save failed part-way: the baseline becomes what the server now has
  /// (minus the removed, plus the created / updated rows) and the edit keeps
  /// going on top of it — created rows carry their new ids — so the retry
  /// only sends what's left.
  void _rebaseOnSaved(
    Set<String> removed,
    Map<String, String> createdIds,
    Set<String> updated,
  ) {
    if (removed.isEmpty && createdIds.isEmpty && updated.isEmpty) return;
    final next = _withCreated(createdIds);
    final nextByKey = {for (final d in next.items) d.key: d};
    rebaseEdit(
      original: _TagsDraft([
        for (final o in original.items)
          if (!removed.contains(o.serverId))
            updated.contains(o.key) ? nextByKey[o.key]! : o,
        for (final d in next.items)
          if (createdIds.containsKey(d.key)) d,
      ]),
      working: next,
    );
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
          // The title never changes with the mode (owner, QA T1) — the
          // action bar says it's edit mode.
          title: l.tagsTitle,
          showBack: true,
          editing: isEditing,
          onBack: isEditing ? handleBack : null,
        ),
        body: TabSwitchBody(
          child: BlocBuilder<TagsCubit, TagsState>(
            builder: (context, state) => AsyncStateView(
              loading:
                  state.status == TagsStatus.initial ||
                  state.status == TagsStatus.loading,
              error: state.error,
              // Edit mode shows its drafts even before the first tag.
              isEmpty: !isEditing && state.tags.isEmpty,
              onRetry: context.read<TagsCubit>().load,
              skeleton: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
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
                    isEditing ? _editBar(l, visible!) : _viewBar(l, state.tags),
                    Expanded(
                      child: isEditing
                          ? _editList(l, visible!)
                          : _viewList(l, state.tags),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  String _sortLabel(AppLocalizations l, _SortBy s) => switch (s) {
    _SortBy.name => l.tagFormNameLabel,
    _SortBy.usage => l.tagsSortUsage,
    _SortBy.color => l.tagFormColorLabel,
    _SortBy.icon => l.tagFormIconLabel,
  };

  // View: [สี▾][ไอคอน▾] … [⇅ เรียง▾](✏️) — the library-list bar (as on
  // contacts / categories): filters left, sort right, then the way into
  // batch edit.
  Widget _viewBar(AppLocalizations l, List<Tag> tags) {
    final codes = tags.map((t) => t.iconCode);
    final colors = {for (final c in codes) ?_colorOf(c)}.toList()..sort();
    final icons = {for (final c in codes) ?_iconOf(c)}.toList()..sort();
    return FilterBar(
      chips: [_colorFilter(l, colors), _iconFilter(l, icons)],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionMenuAnchor<_SortBy>(
            selected: _sort,
            onSelected: (s) => _onFilterChanged(() => _sort = s),
            options: [
              for (final s in _SortBy.values)
                SheetOption(value: s, label: _sortLabel(l, s)),
            ],
            builder: (context, toggle) => FilterDropdownChip(
              label: _sortLabel(l, _sort),
              icon: AppIcons.sort,
              active: false,
              onTap: toggle,
            ),
          ),
          // Batch edit (the top bar carries no page actions; long-pressing
          // a row works too) — the app's round ✏️.
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: AppIcons.edit,
            size: 36,
            tooltip: l.commonEdit,
            onPressed: _beginEdit,
          ),
        ],
      ),
    );
  }

  // Edit: [☐ n/N] [สี][ไอคอน][ลบ] — actions on the selection, dimmed until
  // something is selected. No filters (search only).
  Widget _editBar(AppLocalizations l, List<_TagDraft> visible) {
    return FilterBar(
      chips: [
        SelectAllCount(
          selected: visible.where((d) => _selected.contains(d.key)).length,
          total: visible.length,
          tooltip: l.tagsSelectAll,
          onTap: () => _toggleSelectAll(visible),
        ),
        ActionPill(
          icon: AppIcons.colorPicker,
          label: l.tagsBulkColor,
          onTap: _canBulk ? _bulkColor : null,
        ),
        ActionPill(
          icon: AppIcons.iconPicker,
          label: l.tagsBulkIcon,
          onTap: _canBulk ? _bulkIcon : null,
        ),
        ActionPill(
          icon: AppIcons.delete,
          label: l.commonDelete,
          destructive: true,
          onTap: _canBulk ? _bulkDelete : null,
        ),
      ],
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
        builder: (context, setPopover) => IconSwatchGrid(
          fallback: AppIcons.tag,
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

  Widget _viewList(AppLocalizations l, List<Tag> tags) {
    final shown = _viewTags(tags);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return PullToRefresh(
      onRefresh: () async {
        setState(() => _stickyIds = null);
        await context.read<TagsCubit>().load();
      },
      child: _RowList(
        rows: [
          for (final t in shown)
            ListRow(
              key: _tileKey(t.id),
              leading: IconDisplay(
                type: IconType.tag,
                size: 40,
                iconCode: t.iconCode,
              ),
              title: t.name,
              subtitle: t.description,
              trailing: t.usageCount > 0
                  ? Text(
                      l.tagsUsageCount(t.usageCount),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              onLongPress: () => _beginEdit(focusKey: t.id),
            ),
        ],
        footer: shown.isEmpty && _hasFilter
            ? _ListMessage(text: l.tagsNoMatch)
            : AddTile(label: l.tagsAddNew, onTap: _addTag),
      ),
    );
  }

  Widget _editList(AppLocalizations l, List<_TagDraft> visible) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: c),
    );
    return Form(
      key: _formKey,
      child: _RowList(
        rows: [
          for (final d in visible)
            ListRow(
              key: _tileKey(d.key),
              checked: _selected.contains(d.key),
              onTap: () => _toggleSelect(d.key),
              leading: EditableCircle(
                size: 40,
                onTap: () => _openIconMaker(d),
                child: IconDisplay(
                  type: IconType.tag,
                  size: 40,
                  iconCode: d.iconCode,
                ),
              ),
              body: TextFormField(
                controller: _controllerFor(d),
                focusNode: _focusFor(d.key),
                maxLength: TextLimits.tagName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                onChanged: (v) => applyTextChange(
                  d.key,
                  working.map((e) => e.key == d.key ? e.copyWith(name: v) : e),
                ),
                validator: (v) => _validateName(l, d.key, v),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  filled: false,
                  errorMaxLines: 2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  enabledBorder: border(scheme.outlineVariant),
                  focusedBorder: border(scheme.primary),
                  border: border(scheme.outlineVariant),
                ),
              ),
            ),
        ],
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (visible.isEmpty && _hasFilter)
              _ListMessage(text: l.tagsNoMatch),
            AddTile(label: l.tagsAddNew, onTap: isSaving ? null : _addTag),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Layout pieces
// ────────────────────────────────────────────────────────────────────

/// Hairline-separated rows + a footer (the add tile / no-match line). Not
/// lazy: every row stays mounted, so the form validates all visible rows
/// and `ensureVisible` can reach them.
class _RowList extends StatelessWidget {
  const _RowList({required this.rows, required this.footer});

  final List<Widget> rows;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Bottom room for the shell's FAB, above the floating nav.
      padding: EdgeInsets.only(
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const RowDivider(),
            row,
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: footer,
          ),
        ],
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.text});

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

/// One tag being edited. [description] / [note] aren't shown or edited
/// (tags are name-only for now, owner 2026-10-10); they're carried so
/// the full-replace update sends them back unchanged.
class _TagDraft {
  const _TagDraft({
    required this.key,
    this.serverId,
    required this.name,
    this.iconCode,
    this.description = '',
    this.note = '',
  });

  final String key;
  final String? serverId;
  final String name;
  final IconCode? iconCode;

  /// '' = none.
  final String description;
  final String note;

  /// Created on the server (a save that failed part-way keeps editing).
  _TagDraft withServerId(String id) => _TagDraft(
    key: key,
    serverId: id,
    name: name,
    iconCode: iconCode,
    description: description,
    note: note,
  );

  _TagDraft copyWith({
    String? name,
    IconCode? iconCode,
    String? description,
    String? note,
  }) => _TagDraft(
    key: key,
    serverId: serverId,
    name: name ?? this.name,
    iconCode: iconCode ?? this.iconCode,
    description: description ?? this.description,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is _TagDraft &&
      other.key == key &&
      other.serverId == serverId &&
      other.name == name &&
      other.iconCode == iconCode &&
      other.description == description &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(key, serverId, name, iconCode, description, note);
}
