import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import 'color_token.dart';
import 'icon_code.dart';
import 'icon_code_widget.dart';
import 'icon_type.dart';
import 'packs/icon_pack.dart';
import 'packs/pack_registry.dart';

/// Return type from [showIconMakerSheet].
sealed class IconMakerResult {
  const IconMakerResult();
}

/// User confirmed a selection.
class IconMakerSelected extends IconMakerResult {
  const IconMakerSelected(this.iconCode);
  final IconCode iconCode;
}

/// User tapped "Remove" — only emitted when [showIconMakerSheet.removeLabel]
/// is provided (i.e. on an edit form where clearing the icon is allowed).
class IconMakerRemoved extends IconMakerResult {
  const IconMakerRemoved();
}

/// Opens the icon maker as a bottom sheet (mobile) or dialog (≥ 600 dp).
///
/// Returns [IconMakerSelected], [IconMakerRemoved], or `null` (dismissed).
Future<IconMakerResult?> showIconMakerSheet({
  required BuildContext context,
  required IconType type,
  IconCode? initial,
  Widget? previewSubtitle,
  Widget Function(IconCode)? previewBuilder,
  // Kept for call-site compatibility; not used in the new tap-to-focus UI.
  String? iconSectionLabel,
  String? colorSectionLabel,
  String? useThisLabel,
  String? removeLabel,
  bool showColorSection = true,
  // Granular section visibility. Defaults keep the full editor (no change
  // for existing callers). Set these for single-attribute pickers, e.g.
  // bulk recolour (showIconPicker: false) or bulk re-icon (showColorPicker:
  // false), and hide bg/border for icon-tint types like tags.
  bool showBackground = true,
  bool showBorder = true,
  bool showIconPicker = true,
  bool showColorPicker = true,
  List<String> grantedPackIds = const [],
}) {
  final packs = PackRegistry.packs(type: type, grantedPackIds: grantedPackIds);
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  final body = _Sheet(
    type: type,
    packs: packs,
    initial: initial,
    previewBuilder: previewBuilder,
    previewSubtitle: previewSubtitle,
    useThisLabel: useThisLabel,
    removeLabel: removeLabel,
    showBackground: showBackground,
    showBorder: showBorder,
    showIconPicker: showIconPicker,
    showColorPicker: showColorPicker,
  );

  if (isWide) {
    return showDialog<IconMakerResult>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: body,
        ),
      ),
    );
  }
  return showModalBottomSheet<IconMakerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => body,
  );
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum _Role { icon, background, border }

/// Snapshot of every mutable state that the undo stack rolls back.
class _Snapshot {
  const _Snapshot({
    required this.iconId,
    required this.iconColors,
    required this.bgId,
    required this.bgColors,
    required this.borderId,
    required this.borderColors,
  });

  final String? iconId;
  final List<String> iconColors;
  final String? bgId;
  final List<String> bgColors;
  final String? borderId;
  final List<String> borderColors;
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _Sheet extends StatefulWidget {
  const _Sheet({
    required this.type,
    required this.packs,
    required this.initial,
    required this.previewBuilder,
    required this.previewSubtitle,
    required this.useThisLabel,
    required this.removeLabel,
    this.showBackground = true,
    this.showBorder = true,
    this.showIconPicker = true,
    this.showColorPicker = true,
  });

  final IconType type;
  final List<IconPack> packs;
  final IconCode? initial;
  final Widget Function(IconCode)? previewBuilder;
  final Widget? previewSubtitle;
  final String? useThisLabel;
  final String? removeLabel;
  final bool showBackground;
  final bool showBorder;
  final bool showIconPicker;
  final bool showColorPicker;

  /// True only in the full editor (every section visible).
  bool get isFull =>
      showBackground && showBorder && showIconPicker && showColorPicker;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  // Current icon_code fields
  String? _iconId;
  late List<String> _iconColors;
  String? _bgId;
  late List<String> _bgColors;
  String? _borderId;
  late List<String> _borderColors;

  // Picker focus state
  _Role? _focusedRole;   // which element the colour picker edits
  int _focusedSlotIndex = 0;

  // Recent custom hex picks — persists across sheet opens within the app session.
  static final List<String> _recentColors = [];

  // Undo history — last N snapshots before any colour/asset change.
  // Capped at [_undoLimit]; oldest entries dropped when the cap is reached.
  // Reset every time the sheet opens.
  final List<_Snapshot> _undoStack = [];
  static const int _undoLimit = 10;

  // ── Picker palette ───────────────────────────────────────────────────────
  // Row 1 — theme-derived: 6 specs that resolve through the active AppColors.
  // The picker draws a small 🎨 badge over each to mark them as theme-tracking.
  static const _themeRowSpecs = <String>[
    '@presetThemeColor1',
    '@presetThemeColor2',
    '@presetThemeColor3',
    '@presetThemeColorContainer',
    '@presetThemeColorOnIcon',
    '@presetThemeColorBorder',
  ];

  // Row 2 — common: fixed hex literals. 2 brand colours + 4 universal.
  static const _commonRowSpecs = <String>[
    '#00A389', // brand teal
    '#F06292', // brand pink (placeholder)
    '#1E293B', // soft dark (blue-tinted)
    '#F0F9FF', // soft light (blue-tinted)
    '#EF4444', // red
    '#0EA5E9', // sky blue
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<IconPackItem> _allItems(_Role role) => widget.packs
      .expand((p) => switch (role) {
            _Role.icon => p.icons,
            _Role.background => p.backgrounds,
            _Role.border => p.borders,
          })
      .toList();

  IconPackItem? _findItem(_Role role, String id) {
    for (final pack in widget.packs) {
      final list = switch (role) {
        _Role.icon => pack.icons,
        _Role.background => pack.backgrounds,
        _Role.border => pack.borders,
      };
      final item = list.where((i) => i.id == id).firstOrNull;
      if (item != null) return item;
    }
    return null;
  }

  List<String> _colorsFor(_Role role) => switch (role) {
        _Role.icon => _iconColors,
        _Role.background => _bgColors,
        _Role.border => _borderColors,
      };

  /// True if the focused slot's current spec equals [spec] (case-insensitive).
  /// Used to draw the ✓ on theme/common swatches.
  bool _isCurrentSlotSpec(List<String> colors, String spec) =>
      _focusedSlotIndex < colors.length &&
      colors[_focusedSlotIndex].toLowerCase() == spec.toLowerCase();

  /// Colours to render [item] with: one entry per slot the item needs, taken
  /// from the role's chosen colours by index, falling back to the item's own
  /// default for any slot the user hasn't set. Pure — reading state, never
  /// mutating it. This is the single rule the left side uses for everything
  /// (previews, tiles, dots) so selecting an asset never has to touch colours.
  List<String> _reflectColors(_Role role, IconPackItem item) {
    final chosen = _colorsFor(role);
    return [
      for (var i = 0; i < item.colors.length; i++)
        i < chosen.length ? chosen[i] : item.colors[i],
    ];
  }

  /// Effective colours for the role's *currently selected* asset (empty when
  /// the asset is "none"). Used by [_current] for the live preview and save.
  List<String> _effectiveColors(_Role role) {
    final id = switch (role) {
      _Role.icon => _iconId,
      _Role.background => _bgId,
      _Role.border => _borderId,
    };
    if (id == null) return const [];
    final item = _findItem(role, id);
    if (item == null) return _colorsFor(role);
    return _reflectColors(role, item);
  }

  void _setColors(_Role role, List<String> value) {
    switch (role) {
      case _Role.icon:
        _iconColors = value;
      case _Role.background:
        _bgColors = value;
      case _Role.border:
        _borderColors = value;
    }
  }

  String _roleLabel(AppLocalizations l, _Role role) => switch (role) {
        _Role.icon => l.iconMakerRoleIcon,
        _Role.background => l.iconMakerRoleBackground,
        _Role.border => l.iconMakerRoleBorder,
      };

  // ── Undo ─────────────────────────────────────────────────────────────────

  /// Capture the current state before any mutation. Cap at [_undoLimit].
  void _pushSnapshot() {
    _undoStack.add(_Snapshot(
      iconId: _iconId,
      iconColors: List.of(_iconColors),
      bgId: _bgId,
      bgColors: List.of(_bgColors),
      borderId: _borderId,
      borderColors: List.of(_borderColors),
    ));
    if (_undoStack.length > _undoLimit) _undoStack.removeAt(0);
  }

  /// Pop the last snapshot and apply it. No-op if the stack is empty.
  void _undo() {
    if (_undoStack.isEmpty) return;
    final s = _undoStack.removeLast();
    setState(() {
      _iconId = s.iconId;
      _iconColors = s.iconColors;
      _bgId = s.bgId;
      _bgColors = s.bgColors;
      _borderId = s.borderId;
      _borderColors = s.borderColors;
    });
  }

  IconCode get _current => IconCode(
        icon: _iconId,
        iconColors: _effectiveColors(_Role.icon),
        background: _bgId,
        bgColors: _effectiveColors(_Role.background),
        border: _borderId,
        borderColors: _effectiveColors(_Role.border),
      );

  // ── Initialisation ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init(widget.initial);
    // Both picker halves are shown side by side, so always start focused on
    // the icon role — the split picker then shows its assets + colors at once.
    _focusedRole = _Role.icon;
    _focusedSlotIndex = 0;
  }

  void _init(IconCode? ic) {
    final allIcons = _allItems(_Role.icon);
    final allBgs = _allItems(_Role.background);

    // Left = asset ids. A brand-new sheet (ic == null) picks a default icon +
    // background; an existing code keeps its ids exactly, including `null`.
    final firstIconId = allIcons.firstOrNull?.id ?? 'category';
    _iconId = ic == null ? firstIconId : ic.icon;
    _bgId = ic == null ? allBgs.firstOrNull?.id : ic.background;
    _borderId = ic?.border;

    // Right = chosen colours, by slot index. Start from the saved code only;
    // any slot left empty renders with the asset's own default (see
    // [_reflectColors]), so each asset shows its native palette until the
    // user actually picks a colour for that slot.
    _iconColors = List.of(ic?.iconColors ?? const <String>[]);
    _bgColors = List.of(ic?.bgColors ?? const <String>[]);
    _borderColors = List.of(ic?.borderColors ?? const <String>[]);
  }

  // ── Interactions ─────────────────────────────────────────────────────────

  void _openAssetPicker(_Role role) {
    setState(() {
      if (_focusedRole != role) _focusedSlotIndex = 0;
      _focusedRole = role;
    });
  }

  void _openColorPicker(_Role role, int slotIndex) {
    setState(() {
      _focusedRole = role;
      _focusedSlotIndex = slotIndex;
    });
  }

  /// Selecting an asset only changes which asset is used — it never touches
  /// the role's colour array. The chosen colours stay put; any slot the new
  /// asset adds beyond them falls back to that asset's default at render time
  /// (see [_reflectColors]). Clearing to "none" ([newId] == null) drops the
  /// colours since there's nothing to colour.
  void _selectAsset(_Role role, String? newId) {
    _pushSnapshot();
    setState(() {
      switch (role) {
        case _Role.icon:
          _iconId = newId;
          if (newId == null) _iconColors = [];
        case _Role.background:
          _bgId = newId;
          if (newId == null) _bgColors = [];
        case _Role.border:
          _borderId = newId;
          if (newId == null) _borderColors = [];
      }
      // Keep the focused slot in range for the new asset.
      final slots = _effectiveColors(role).length;
      if (_focusedSlotIndex >= slots) _focusedSlotIndex = 0;
    });
  }

  /// Apply a colour spec (hex literal or `@presetTheme*` token) to the
  /// currently focused slot. [isCustom] is true only for hex picked via
  /// the custom-hex dialog; those land in the `Recent` strip. Theme/common
  /// swatch taps don't pollute Recent.
  void _applyColor(String spec, {required bool isCustom}) {
    final role = _focusedRole;
    if (role == null) return;
    // Work from the effective list (chosen colours padded to the asset's slot
    // count), set the focused slot, then store it back — so a never-touched
    // slot is persisted with its default + the new pick.
    final colors = _effectiveColors(role);
    if (_focusedSlotIndex >= colors.length) return;
    _pushSnapshot();
    setState(() {
      colors[_focusedSlotIndex] = spec;
      _setColors(role, colors);
      if (isCustom) {
        _recentColors.remove(spec);
        _recentColors.insert(0, spec);
        if (_recentColors.length > 6) _recentColors.removeLast();
      }
    });
  }

  Future<void> _pickCustomHex() async {
    // Seed the dialog with the resolved hex of the focused slot — even if
    // the slot currently holds a `@presetTheme*` token, the user sees the
    // colour they're editing.
    final palette = Theme.of(context).extension<AppColors>()!;
    final eff =
        _focusedRole != null ? _effectiveColors(_focusedRole!) : const <String>[];
    final currentSpec = _focusedSlotIndex < eff.length
        ? eff[_focusedSlotIndex]
        : '#FFFFFF';
    final seed = resolveColor(currentSpec, palette);
    final picked = await _showColorWheelDialog(context, seed);
    if (picked != null) {
      final hex =
          '#${(picked.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      _applyColor(hex, isCustom: true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLivePreview(context),
            const SizedBox(height: AppSpacing.md),
            _buildEditorStrip(context),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _buildPickerSection(context),
            const SizedBox(height: AppSpacing.md),
            _buildActions(context, l),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(BuildContext context) {
    final code = _current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.previewBuilder != null)
          widget.previewBuilder!(code)
        else
          Center(child: IconCodeWidget(iconCode: code, size: 80)),
        if (widget.previewSubtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(child: widget.previewSubtitle!),
        ],
      ],
    );
  }

  /// The three role editors (icon / background / border) laid out horizontally
  /// as cards, so it reads at a glance which element you're editing. Only the
  /// roles enabled for this sheet are shown.
  Widget _buildEditorStrip(BuildContext context) {
    final roles = <_Role>[
      _Role.icon,
      if (widget.showBackground) _Role.background,
      if (widget.showBorder) _Role.border,
    ];
    // IntrinsicHeight gives the Row a bounded cross-axis extent so the cards
    // can stretch to equal height — plain stretch inside the vertically
    // scrolling sheet would have an unbounded height and assert.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < roles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildEditorCard(context, roles[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, _Role role) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = _focusedRole == role;
    final label = _roleLabel(AppLocalizations.of(context)!, role);

    final VoidCallback? onTap = widget.showIconPicker
        ? () => _openAssetPicker(role)
        : (widget.showColorPicker ? () => _openColorPicker(role, 0) : null);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primaryContainer.withValues(alpha: 0.35)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? scheme.primary : scheme.outlineVariant,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditorMiniPreview(role, 48),
            const SizedBox(height: 10),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorMiniPreview(_Role role, double size) {
    final code = _current;
    switch (role) {
      case _Role.icon:
        if (code.icon == null) return _NullCircle(size: size);
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconCodeWidget(
              iconCode: IconCode(icon: code.icon, iconColors: code.iconColors),
              size: size * 0.7,
              fallbackColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      case _Role.background:
        if (code.background == null) return _NullCircle(size: size);
        return SizedBox(
          width: size,
          height: size,
          child: _BgPreview(iconCode: code, size: size),
        );
      case _Role.border:
        if (code.border == null || code.borderColors.isEmpty) {
          return _NullCircle(size: size);
        }
        return SizedBox(
          width: size,
          height: size,
          child: _BorderPreview(iconCode: code, size: size),
        );
    }
  }

  // ── Picker section ────────────────────────────────────────────────────────

  /// Split picker: left = asset (icon/bg/border designs), right = colors for
  /// the focused role. The colour tray on the right slides open/closed as the
  /// selected item gains/loses editable colour slots; the asset side fills the
  /// freed space. In single-attribute modes only the relevant half is shown.
  Widget _buildPickerSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final role = _focusedRole ?? _Role.icon;
    final showAsset = widget.showIconPicker;
    // The colour tray only makes sense when the current item exposes editable
    // colour slots — a fixed/preset asset (or "none") collapses it.
    final hasColor =
        widget.showColorPicker && _effectiveColors(role).isNotEmpty;

    // Colour-only mode (no asset side).
    if (!showAsset) {
      return hasColor
          ? _buildColorPicker(context, role, columns: 4)
          : const SizedBox.shrink();
    }
    // Asset-only sheet (colours never editable) — plain full-width grid.
    if (!widget.showColorPicker) {
      return _buildAssetPicker(context, role, columns: 6);
    }

    // Fixed 50/50 split. When the current item has no editable colours the
    // right tray is simply hidden — its layout slot stays, so the asset side
    // doesn't reflow (no slide, no column change).
    return SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildAssetPicker(context, role, columns: 3),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(width: 1, color: scheme.outlineVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: hasColor
                ? SingleChildScrollView(
                    child: _buildColorPicker(context, role, columns: 4),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, _Role role,
      {required int columns}) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    // Effective colours = chosen, padded to the asset's slot count with its
    // defaults. This drives the slot selector + ✓ marks.
    final colors = _effectiveColors(role);
    final total = colors.length;
    // Clamp — role may have fewer slots than the last focused one.
    final slot = _focusedSlotIndex.clamp(0, total > 0 ? total - 1 : 0);

    Widget cell(String? spec, {bool themeBadge = false}) {
      if (spec == null) return const SizedBox.shrink();
      return Center(
        child: _ColorCircle(
          spec: spec,
          size: 42,
          isSelected: _isCurrentSlotSpec(colors, spec),
          showThemeBadge: themeBadge,
          onTap: () => _applyColor(spec, isCustom: false),
        ),
      );
    }

    // Faint outlined circle for an as-yet-unused recent slot.
    Widget emptySlot() => Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: 2),
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.outline),
          ),
        );

    // A grid of swatches laid out in rows of [columns] — plain Column/Row so
    // it nests cleanly inside the scroll view (no GridView measuring quirks).
    Widget grid(List<String> specs, {bool themeBadge = false}) {
      final rows = <Widget>[];
      for (var i = 0; i < specs.length; i += columns) {
        final end = (i + columns) < specs.length ? i + columns : specs.length;
        final rowSpecs = specs.sublist(i, end);
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: 6),
                Expanded(
                  child: j < rowSpecs.length
                      ? cell(rowSpecs[j], themeBadge: themeBadge)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The colour currently being edited — centred, with a clear divider
        // separating it from the palette of choices below.
        if (total >= 1) ...[
          Center(
            child: Text(
              total > 1 ? l.iconMakerColorEditing : l.iconMakerColor,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (int i = 0; i < total; i++)
                  _SlotSwatch(
                    spec: colors[i],
                    isFocused: slot == i,
                    size: 40,
                    onTap: () => setState(() => _focusedSlotIndex = i),
                  ),
              ],
            ),
          ),
          if (total > 1) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                l.iconMakerColorHint,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.outline),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
        ],
        sectionLabel(l.iconMakerRecentCustom),
        // Top row: two most-recent custom colours + a custom-hex button that
        // spans the last two of the four columns.
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: _recentColors.isNotEmpty
                    ? cell(_recentColors[0])
                    : emptySlot(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _recentColors.length > 1
                    ? cell(_recentColors[1])
                    : emptySlot(),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _pickCustomHex,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.colorize_outlined,
                            size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(l.iconMakerHex,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        sectionLabel(l.iconMakerThemeColors),
        grid(_themeRowSpecs, themeBadge: true),
        const SizedBox(height: AppSpacing.xs),
        sectionLabel(l.iconMakerPresetColors),
        grid(_commonRowSpecs),
      ],
    );
  }

  Widget _buildAssetPicker(BuildContext context, _Role role,
      {required int columns}) {
    final label = _roleLabel(AppLocalizations.of(context)!, role);
    // Every element — icon included — can be set to "none".
    const canBeNull = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int pi = 0; pi < widget.packs.length; pi++) ...[
          if (pi > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _PackDivider(packId: widget.packs[pi].id),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildPackTiles(
              context, role, widget.packs[pi], pi == 0 && canBeNull, columns),
        ],
      ],
    );
  }

  Widget _buildPackTiles(BuildContext context, _Role role, IconPack pack,
      bool withNull, int crossAxisCount) {
    final code = _current;
    final items = switch (role) {
      _Role.icon => pack.icons,
      _Role.background => pack.backgrounds,
      _Role.border => pack.borders,
    };

    final currentId = switch (role) {
      _Role.icon => _iconId,
      _Role.background => _bgId,
      _Role.border => _borderId,
    };

    // Build tile list: optional null tile first, then pack items
    final children = <Widget>[
      if (withNull)
        _AssetTile(
          preview: _NullCircle(size: 44),
          dots: const [],
          isSelected: currentId == null,
          onTap: () => _selectAsset(role, null),
          isNull: true,
        ),
      for (final item in items)
        _AssetTile(
          preview: _buildTilePreview(role, item, code, 44),
          dots: _reflectColors(role, item),
          isSelected: currentId == item.id,
          onTap: () => _selectAsset(role, item.id),
          isNull: false,
        ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.xs,
        // Fixed row height (not width-derived) so wide cells don't balloon
        // into tall empty tiles — enough for the 44 preview + its selection
        // ring/padding + the dots/label row below.
        mainAxisExtent: 74,
      ),
      children: children,
    );
  }

  /// A neutral tile background guaranteed to contrast with [fg], so a glyph
  /// tinted the same as (or near) the sheet surface never disappears while
  /// browsing. Picks whichever of a dark/light neutral has the higher WCAG
  /// contrast ratio against the icon colour. Picker tiles only — the live
  /// preview at the top always shows the real composition.
  Color _contrastTileBg(Color fg) {
    const dark = Color(0xFF1F2430);
    const light = Color(0xFFEFF2F7);
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    return ratio(fg, dark) >= ratio(fg, light) ? dark : light;
  }

  Widget _buildTilePreview(
      _Role role, IconPackItem item, IconCode current, double size) {
    switch (role) {
      case _Role.icon:
        // Show the glyph alone on an auto-contrast disc — the tile is for
        // choosing the shape, not previewing the final background/border.
        final palette = Theme.of(context).extension<AppColors>()!;
        final fg = current.iconColors.isNotEmpty
            ? resolveColor(current.iconColors.first, palette)
            : Theme.of(context).colorScheme.primary;
        final glyphCode =
            IconCode(icon: item.id, iconColors: current.iconColors);
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _contrastTileBg(fg),
          ),
          child: IconCodeWidget(iconCode: glyphCode, size: size * 0.62),
        );

      case _Role.background:
        // Reflect the currently-selected colour on every tile, keeping the
        // item's own slot count.
        final previewCode = current.copyWith(
          background: item.id,
          bgColors: _reflectColors(_Role.background, item),
        );
        return _BgPreview(iconCode: previewCode, size: size);

      case _Role.border:
        final previewCode = current.copyWith(
          border: item.id,
          borderColors: _reflectColors(_Role.border, item),
        );
        return _BorderPreview(iconCode: previewCode, size: size);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Reset every element back to the type's defaults (first icon + its default
  /// colours, default background, no border). Undoable via the snapshot stack.
  void _resetToDefault() {
    _pushSnapshot();
    setState(() {
      _init(null);
      _focusedRole = _Role.icon;
      _focusedSlotIndex = 0;
    });
  }

  Widget _buildActions(BuildContext context, AppLocalizations l) {
    return Row(
      children: [
        // Undo — visible only when there's something to undo (cap _undoLimit).
        if (_undoStack.isNotEmpty)
          IconButton(
            tooltip: 'Undo (${_undoStack.length})',
            onPressed: _undo,
            icon: const Icon(Icons.undo),
          ),
        IconButton(
          tooltip: l.iconMakerReset,
          onPressed: _resetToDefault,
          icon: const Icon(Icons.restart_alt),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop<IconMakerResult>(null),
            child: Text(l.commonCancel),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context)
                .pop<IconMakerResult>(IconMakerSelected(_current)),
            child: Text(widget.useThisLabel ?? l.iconPickerUseThis),
          ),
        ),
      ],
    );
  }
}

// ─── Colour wheel dialog ──────────────────────────────────────────────────────

/// Popup HSV wheel + hex field (flutter_colorpicker). Returns the picked
/// colour, or null if cancelled.
Future<Color?> _showColorWheelDialog(BuildContext context, Color seed) {
  final l = AppLocalizations.of(context)!;
  var selected = seed;
  return showDialog<Color>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.colorPickerTitle),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: seed,
          onColorChanged: (c) => selected = c,
          enableAlpha: false,
          hexInputBar: true,
          portraitOnly: true,
          labelTypes: const [],
          pickerAreaBorderRadius: BorderRadius.circular(12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(selected),
          child: Text(l.colorPickerUse),
        ),
      ],
    ),
  );
}

// ─── Small helper widgets ─────────────────────────────────────────────────────

class _SlotSwatch extends StatelessWidget {
  const _SlotSwatch({
    required this.spec,
    required this.isFocused,
    required this.onTap,
    this.size = 24,
  });

  final String spec;
  final bool isFocused;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: resolveColor(spec, palette),
          // Focus marked by a primary ring — border grows inward so the
          // overall size never changes.
          border: Border.all(
            color: isFocused ? scheme.primary : scheme.outlineVariant,
            width: isFocused ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.spec,
    required this.isSelected,
    required this.onTap,
    this.showThemeBadge = false,
    this.size = 36,
  });

  final String spec;
  final bool isSelected;
  final bool showThemeBadge;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final color = resolveColor(spec, palette);
    // Pick a contrasting check colour: white on dark fills, black on light.
    final checkColor = color.computeLuminance() > 0.6 ? Colors.black54 : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected ? scheme.onSurface : scheme.outlineVariant,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: size * 0.44, color: checkColor)
                : null,
          ),
          if (showThemeBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                  border: Border.all(color: scheme.outlineVariant, width: 0.5),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  size: 9,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NullCircle extends StatelessWidget {
  const _NullCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1.5,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Text(
          '∅',
          style: TextStyle(
            fontSize: size * 0.35,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.preview,
    required this.dots,
    required this.isSelected,
    required this.onTap,
    required this.isNull,
  });

  final Widget preview;
  final List<String> dots;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNull;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // Always reserve the ring + padding (transparent when unselected)
            // so selecting a tile never changes its footprint.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? scheme.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: preview,
          ),
          const SizedBox(height: 4),
          if (dots.isEmpty && !isNull)
            Text(
              AppLocalizations.of(context)!.iconMakerPresetLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                    fontSize: 9,
                  ),
            )
          else if (!isNull)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: dots.map((spec) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resolveColor(spec, palette),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _PackDivider extends StatelessWidget {
  const _PackDivider({required this.packId});
  final String packId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        const SizedBox(width: AppSpacing.sm),
        Text(
          packId,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ─── Background preview ───────────────────────────────────────────────────────

class _BgPreview extends StatelessWidget {
  const _BgPreview({required this.iconCode, required this.size});
  final IconCode iconCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: _decoration(palette),
    );
  }

  BoxDecoration _decoration(AppColors palette) {
    final colors = iconCode.bgColors;
    Color c(int i) => resolveColor(colors[i], palette);

    return switch (iconCode.background) {
      'superGradientA' when colors.length >= 2 => BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c(0), c(1)],
          ),
        ),
      'radialGlow' when colors.length >= 2 => BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [c(0), c(1)],
          ),
        ),
      'stripedPatternDi' when colors.length >= 3 => BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c(0), c(0), c(1), c(1), c(2), c(2)],
            stops: const [0.0, 0.33, 0.33, 0.66, 0.66, 1.0],
          ),
        ),
      'rainbow' => const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFEF4444),
              Color(0xFFF59E0B),
              Color(0xFFFCD34D),
              Color(0xFF22C55E),
              Color(0xFF3B82F6),
              Color(0xFF6366F1),
              Color(0xFFA855F7),
              Color(0xFFEF4444),
            ],
          ),
        ),
      'snowflake' => const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFDBEAFE),
        ),
      'wreath' || 'starburst' => const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF15803D),
        ),
      _ => BoxDecoration(
          shape: BoxShape.circle,
          color: colors.isNotEmpty ? c(0) : palette.primary,
        ),
    };
  }
}

// ─── Border preview ───────────────────────────────────────────────────────────

class _BorderPreview extends StatelessWidget {
  const _BorderPreview({required this.iconCode, required this.size});
  final IconCode iconCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconCode.border == null || iconCode.borderColors.isEmpty) {
      return SizedBox(width: size, height: size);
    }
    final palette = Theme.of(context).extension<AppColors>()!;
    final color = resolveColor(iconCode.borderColors.first, palette);
    final width = iconCode.border == 'thick' ? 4.0 : 2.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
    );
  }
}
