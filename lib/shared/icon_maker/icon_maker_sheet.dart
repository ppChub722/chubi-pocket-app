import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import 'color_token.dart';
import 'icon_code.dart';
import 'icon_code_widget.dart';
import 'icon_type.dart';
import 'packs/icon_pack.dart';
import 'packs/pack_registry.dart';
import 'icon_shape.dart';
import '../widgets/dashed_rect_border.dart';
import '../widgets/ui.dart';

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
  // Sheet heading — name the thing ("ไอคอนกระเป๋า") or the bulk job
  // ("เปลี่ยนสี 3 แท็ก"). Defaults to the localized "ไอคอน".
  String? title,
  // Kept for call-site compatibility; not used in the new tap-to-focus UI.
  String? iconSectionLabel,
  String? colorSectionLabel,
  String? useThisLabel,
  // Non-null enables "ใช้ไอคอนเริ่มต้นของแอป" in the ⋯ menu (returns
  // [IconMakerRemoved]). The menu shows the localized label.
  String? removeLabel,
  bool showColorSection = true,
  // Granular section visibility. Defaults keep the full editor (no change
  // for existing callers). Set these for single-attribute pickers, e.g.
  // bulk recolour (showIconPicker: false) or bulk re-icon (showColorPicker:
  // false), and hide bg/border for icon-tint types like tags.
  // Layer visibility — which of the three elements (icon / background /
  // border) the user can edit. Any non-empty combination works; hidden
  // layers keep their current value in the result. See [IconMakerLayers].
  bool showIcon = true,
  bool showBackground = true,
  bool showBorder = true,
  bool showIconPicker = true,
  bool showColorPicker = true,
  List<String> grantedPackIds = const [],
}) {
  assert(showIcon || showBackground || showBorder,
      'showIconMakerSheet needs at least one editable layer.');
  final packs = PackRegistry.packs(type: type, grantedPackIds: grantedPackIds);
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  final body = _Sheet(
    type: type,
    packs: packs,
    initial: initial,
    previewBuilder: previewBuilder,
    previewSubtitle: previewSubtitle,
    title: title,
    useThisLabel: useThisLabel,
    removeLabel: removeLabel,
    showIcon: showIcon,
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
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: body,
          ),
        ),
      ),
    );
  }
  // Fixed height (not content-sized) so switching tabs / layers never makes
  // the sheet jump. Root navigator → it covers the shell's nav + FAB.
  return showModalBottomSheet<IconMakerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.88,
      child: body,
    ),
  );
}

/// The seven layer combinations of [showIconMakerSheet] — pass
/// `layers.icon / .background / .border` as `showIcon / showBackground /
/// showBorder`.
enum IconMakerLayers {
  all(icon: true, background: true, border: true),
  iconBackground(icon: true, background: true, border: false),
  iconBorder(icon: true, background: false, border: true),
  backgroundBorder(icon: false, background: true, border: true),
  iconOnly(icon: true, background: false, border: false),
  backgroundOnly(icon: false, background: true, border: false),
  borderOnly(icon: false, background: false, border: true);

  const IconMakerLayers({
    required this.icon,
    required this.background,
    required this.border,
  });

  final bool icon;
  final bool background;
  final bool border;
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
    required this.shape,
  });

  final String? iconId;
  final List<String> iconColors;
  final String? bgId;
  final List<String> bgColors;
  final String? borderId;
  final List<String> borderColors;
  final String? shape;
}

/// The two pickers inside the sheet.
enum _Tab { style, color }

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
    this.title,
    this.showIcon = true,
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
  final String? title;
  final bool showIcon;
  final bool showBackground;
  final bool showBorder;
  final bool showIconPicker;
  final bool showColorPicker;

  /// True only in the full editor (every section visible).
  bool get isFull =>
      showIcon &&
      showBackground &&
      showBorder &&
      showIconPicker &&
      showColorPicker;

  /// Editable layers, in display order.
  List<_Role> get roles => [
        if (showIcon) _Role.icon,
        if (showBackground) _Role.background,
        if (showBorder) _Role.border,
      ];

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
  String? _shape; // IconShape name; null = circle

  // Last non-null asset per layer — "ไม่มี" hides a layer but remembers it,
  // so picking a shape with no background brings the old one back.
  final Map<_Role, String> _lastIds = {};

  // UI state
  _Tab _tab = _Tab.style;
  String _query = '';
  String? _packFilter; // null = all packs
  bool _compactPreview = false;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _hexCtl = TextEditingController();
  final FocusNode _hexFocus = FocusNode();
  bool _hexInvalid = false;

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
      shape: _shape,
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
      _shape = s.shape;
    });
  }

  IconCode get _current => IconCode(
        icon: _iconId,
        iconColors: _effectiveColors(_Role.icon),
        background: _bgId,
        bgColors: _effectiveColors(_Role.background),
        border: _borderId,
        borderColors: _effectiveColors(_Role.border),
        shape: _shape,
      );

  // ── Initialisation ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init(widget.initial);
    // Both picker halves are shown side by side, so start focused on the
    // first editable layer — the split picker then shows its assets + colors.
    _focusedRole = widget.roles.first;
    _focusedSlotIndex = 0;
    if (!widget.showIconPicker) _tab = _Tab.color;
    // Short screens: once the picker scrolls, the preview shrinks to one size.
    _scroll.addListener(() {
      final compact = _scroll.offset > 24;
      if (compact != _compactPreview) setState(() => _compactPreview = compact);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _hexCtl.dispose();
    _hexFocus.dispose();
    super.dispose();
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
    _shape = ic?.shape;

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

  /// Selecting an asset only changes which asset is used — it never touches
  /// the role's colour array. The chosen colours stay put; any slot the new
  /// asset adds beyond them falls back to that asset's default at render time
  /// (see [_reflectColors]). "ไม่มี" ([newId] == null) hides the layer but
  /// keeps its colours (and [_lastIds] remembers the asset), so picking any
  /// asset again brings the previous look back.
  void _selectAsset(_Role role, String? newId) {
    _pushSnapshot();
    setState(() {
      final prev = _assetId(role);
      if (newId == null && prev != null) _lastIds[role] = prev;
      switch (role) {
        case _Role.icon:
          _iconId = newId;
        case _Role.background:
          _bgId = newId;
        case _Role.border:
          _borderId = newId;
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
        if (_recentColors.length > 5) _recentColors.removeLast();
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
  //
  // Layout (product/phase2/ux-overhaul-plan.md §3.5, mockup v7):
  //   header (title + ⋯) · preview 72/40/24 · layer switcher (≥2 layers)
  //   · tabs รูปแบบ|สี (only when both pickers allowed) · scrolling body
  //   · ModeActionBar (ยกเลิก · ↶ · ใช้รูปนี้)

  _Role get _role => _focusedRole ?? widget.roles.first;

  String? _assetId(_Role role) => switch (role) {
        _Role.icon => _iconId,
        _Role.background => _bgId,
        _Role.border => _borderId,
      };

  /// Which picker is showing — forced when the caller allows only one.
  _Tab get _activeTab => !widget.showIconPicker
      ? _Tab.color
      : (!widget.showColorPicker ? _Tab.style : _tab);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final showTabs = widget.showIconPicker && widget.showColorPicker;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, l),
          _buildPreview(context),
          if (widget.roles.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildLayerSwitcher(context, l),
            ),
          if (showTabs)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: AppTabBar<_Tab>(
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                tabs: [
                  AppTab(value: _Tab.style, label: l.iconMakerTabStyle),
                  AppTab(value: _Tab.color, label: l.iconMakerTabColor),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: _activeTab == _Tab.style
                  ? _buildStyleTab(context, l)
                  : _buildColorTab(context, l),
            ),
          ),
          const Divider(height: 1),
          ModeActionBar(
            canSave: true,
            canUndo: _undoStack.isNotEmpty,
            undoTooltip: l.commonUndo,
            cancelLabel: l.commonCancel,
            saveLabel: widget.useThisLabel ?? l.iconPickerUseThis,
            onCancel: () => Navigator.of(context).pop<IconMakerResult>(null),
            onUndo: _undo,
            onSave: () => Navigator.of(context)
                .pop<IconMakerResult>(IconMakerSelected(_current)),
          ),
        ],
      ),
    );
  }

  // ── Header + preview ─────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title ?? l.iconMakerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(AppIcons.more),
            onSelected: (v) async {
              if (v == 'reset') {
                final ok = await showConfirmDialog(
                  context,
                  title: l.iconMakerResetConfirmTitle,
                  message: l.iconMakerResetConfirmBody,
                  confirmLabel: l.iconMakerReset,
                  destructive: true,
                );
                if (ok && mounted) _resetToDefault();
              } else if (v == 'default' && context.mounted) {
                Navigator.of(context)
                    .pop<IconMakerResult>(const IconMakerRemoved());
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.reset),
                  title: Text(l.iconMakerReset),
                ),
              ),
              if (widget.removeLabel != null)
                PopupMenuItem(
                  value: 'default',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.useDefaultIcon),
                    title: Text(l.iconMakerUseDefault),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final code = _current;
    final Widget main;
    if (widget.previewBuilder != null) {
      main = widget.previewBuilder!(code);
    } else {
      // 72 header · 40 list row · 24 chip — collapses to one size once the
      // picker scrolls (short screens).
      final sizes = _compactPreview ? const [44.0] : const [72.0, 40.0, 24.0];
      main = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < sizes.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xl),
            IconCodeWidget(iconCode: code, size: sizes[i]),
          ],
        ],
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            main,
            if (widget.previewSubtitle != null && !_compactPreview) ...[
              const SizedBox(height: AppSpacing.xs),
              widget.previewSubtitle!,
            ],
          ],
        ),
      ),
    );
  }

  // ── Layer switcher ────────────────────────────────────────────────────────

  Widget _buildLayerSwitcher(BuildContext context, AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    final roles = widget.roles;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (var i = 0; i < roles.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(child: _layerSegment(context, l, roles[i])),
          ],
        ],
      ),
    );
  }

  Widget _layerSegment(BuildContext context, AppLocalizations l, _Role role) {
    final scheme = Theme.of(context).colorScheme;
    final active = _role == role;
    final off = _assetId(role) == null;
    return Material(
      color: active ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: active
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openAssetPicker(role),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: off
                    ? Icon(AppIcons.none, size: 18, color: scheme.onSurfaceVariant)
                    : _layerMini(role, 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  _roleLabel(l, role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active ? scheme.primary : null,
                        fontWeight: active ? FontWeight.w600 : null,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tiny render of one layer alone (layer switcher dots).
  Widget _layerMini(_Role role, double size) {
    final code = _current;
    return switch (role) {
      _Role.icon => _onContrast(
          IconCode(icon: code.icon, iconColors: code.iconColors), size),
      _Role.background => IconCodeWidget(
          iconCode: IconCode(
              background: code.background,
              bgColors: code.bgColors,
              shape: code.shape),
          size: size),
      _Role.border => IconCodeWidget(
          iconCode: IconCode(
              border: code.border,
              borderColors: code.borderColors,
              shape: code.shape),
          size: size),
    };
  }

  /// A glyph-only code on an auto-contrast disc, so an icon tinted like the
  /// sheet surface (e.g. white "on icon") never disappears in a tile.
  Widget _onContrast(IconCode glyph, double size) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final fg = glyph.iconColors.isNotEmpty
        ? resolveColor(glyph.iconColors.first, palette)
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: _contrastTileBg(fg)),
      child: IconCodeWidget(iconCode: glyph, size: size * 0.66),
    );
  }

  /// A neutral tile background guaranteed to contrast with [fg] (WCAG ratio).
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

  // ── Style tab ─────────────────────────────────────────────────────────────

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );

  Widget _buildStyleTab(BuildContext context, AppLocalizations l) {
    final role = _role;
    final children = <Widget>[];

    if (role == _Role.icon) {
      children.add(AppSearchBar(
        padding: EdgeInsets.zero,
        hint: l.iconMakerSearchHint,
        onChanged: (q) => setState(() => _query = q),
      ));
    }
    // Pack chips only when there's more than one pack (base + DLC).
    if (widget.packs.length > 1) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l.transactionsRangeAll),
              selected: _packFilter == null,
              onSelected: (_) => setState(() => _packFilter = null),
            ),
            for (final p in widget.packs)
              ChoiceChip(
                label: Text(p.id),
                selected: _packFilter == p.id,
                onSelected: (_) => setState(() => _packFilter = p.id),
              ),
          ],
        ),
      ));
    }

    if (role == _Role.background) {
      // Background = shape × pattern.
      children.add(_section(l.iconMakerShape));
      children.add(_grid([
        for (final s in IconShape.values)
          _StyleTile(
            selected: IconShape.fromId(_shape) == s,
            preview: IconCodeWidget(
              iconCode: _current.copyWith(shape: s.name),
              size: 40,
            ),
            label: s.label(l),
            onTap: () => _selectShape(s),
          ),
      ], withLabels: true));
      children.add(_section(l.iconMakerPattern));
    } else {
      children.add(const SizedBox(height: AppSpacing.md));
    }

    final q = _query.trim().toLowerCase();
    final filtering = role == _Role.icon && q.isNotEmpty;
    final items = [
      for (final p in widget.packs)
        if (_packFilter == null || p.id == _packFilter)
          ...switch (role) {
            _Role.icon => p.icons,
            _Role.background => p.backgrounds,
            _Role.border => p.borders,
          },
    ].where((i) => !filtering || i.id.toLowerCase().contains(q)).toList();

    if (items.isEmpty && filtering) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text(
          l.iconMakerNoMatch(_query.trim()),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ));
    } else {
      final currentId = _assetId(role);
      children.add(_grid([
        // "ไม่มี" first — hides the layer, remembers its look.
        if (!filtering && _packFilter == null)
          _StyleTile(
            selected: currentId == null,
            preview: Icon(AppIcons.none,
                size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant),
            dots: const [],
            onTap: () => _selectAsset(role, null),
          ),
        for (final item in items)
          _StyleTile(
            selected: currentId == item.id,
            preview: _tilePreview(role, item),
            dots: _reflectColors(role, item),
            onTap: () => _selectAsset(role, item.id),
          ),
      ]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Picking a shape with no background brings back the last one (or the
  /// first available) — a shape alone has nothing to show.
  void _selectShape(IconShape s) {
    _pushSnapshot();
    setState(() {
      _shape = s == IconShape.circle ? null : s.name;
      _bgId ??= _lastIds[_Role.background] ??
          _allItems(_Role.background).firstOrNull?.id;
    });
  }

  /// Tile = the whole icon with this item swapped in, in the colours the user
  /// has chosen, so they see the result before tapping.
  Widget _tilePreview(_Role role, IconPackItem item) {
    final colors = _reflectColors(role, item);
    final code = switch (role) {
      _Role.icon => _current.copyWith(icon: item.id, iconColors: colors),
      _Role.background =>
        _current.copyWith(background: item.id, bgColors: colors),
      _Role.border => _current.copyWith(border: item.id, borderColors: colors),
    };
    if (code.background == null && role == _Role.icon) {
      return _onContrast(code, 40);
    }
    return IconCodeWidget(iconCode: code, size: 40);
  }

  /// 6-column grid; row height follows the column width.
  Widget _grid(List<Widget> tiles, {bool withLabels = false}) {
    return LayoutBuilder(builder: (context, c) {
      const cols = 6;
      const gap = 6.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          mainAxisExtent: w + (withLabels ? 18 : 12),
        ),
        children: tiles,
      );
    });
  }

  // ── Colour tab ────────────────────────────────────────────────────────────

  String _hexOf(String spec) {
    final c = resolveColor(spec, Theme.of(context).extension<AppColors>()!);
    return '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Widget _buildColorTab(BuildContext context, AppLocalizations l) {
    final role = _role;
    final colors = _effectiveColors(role);
    final off = _assetId(role) == null;
    final editable = !off && colors.isNotEmpty;
    final slot = editable ? _focusedSlotIndex.clamp(0, colors.length - 1) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSlotRow(context, l, role, colors, off, slot),
        LockedInEdit(
          locked: !editable,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _section(l.iconMakerThemeColors),
              _swatchRow([
                for (final s in _themeRowSpecs) _swatch(s, colors),
              ]),
              _section(l.iconMakerCommonColors),
              _swatchRow([
                for (final s in _commonRowSpecs) _swatch(s, colors),
              ]),
              _section(l.iconMakerCustomColors),
              _swatchRow([
                _pickerButton(l),
                for (var i = 0; i < 5; i++)
                  i < _recentColors.length
                      ? _swatch(_recentColors[i], colors)
                      : const _EmptySwatch(),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  /// Top row: the current art's colour slots (tap = choose which to edit,
  /// hex under each) | hex field for the focused slot + reset-to-default.
  Widget _buildSlotRow(BuildContext context, AppLocalizations l, _Role role,
      List<String> colors, bool off, int slot) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Widget content;
    if (off || colors.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          off ? l.iconMakerLayerOff(_roleLabel(l, role)) : l.iconMakerNotRecolorable,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    } else {
      final current = _hexOf(colors[slot]);
      if (!_hexFocus.hasFocus) {
        _hexCtl.text = current;
        _hexInvalid = false;
      }
      final item = _findItem(role, _assetId(role)!);
      final def = (item != null && slot < item.colors.length)
          ? item.colors[slot]
          : null;
      content = Row(
        children: [
          for (var i = 0; i < colors.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            InkWell(
              onTap: () => setState(() => _focusedSlotIndex = i),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableFrame(
                    selected: i == slot,
                    radius: 18,
                    gap: 2,
                    child: _Dot(spec: colors[i], size: 36),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hexOf(colors[i]),
                    style: textTheme.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: i == slot ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: i == slot ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: 104,
            child: TextField(
              controller: _hexCtl,
              focusNode: _hexFocus,
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              style: textTheme.bodyMedium
                  ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                filled: true,
                fillColor: scheme.surface,
                hintText: '#RRGGBB',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: _hexInvalid ? scheme.error : scheme.outlineVariant),
                ),
              ),
              onChanged: (_) {
                if (_hexInvalid) setState(() => _hexInvalid = false);
              },
              onSubmitted: (_) => _commitHex(current),
              onTapOutside: (_) {
                if (_hexFocus.hasFocus) {
                  _commitHex(current);
                  _hexFocus.unfocus();
                }
              },
            ),
          ),
          IconButton(
            tooltip: l.iconMakerResetSlot,
            onPressed: def == null || _hexOf(def) == current
                ? null
                : () => _applyColor(def, isCustom: false),
            icon: const Icon(AppIcons.reset),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  /// Applies a typed/pasted hex to the focused slot (also lands in Recent).
  void _commitHex(String current) {
    final raw = _hexCtl.text.trim().toUpperCase();
    final v = raw.startsWith('#') ? raw : '#$raw';
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(v)) {
      setState(() => _hexInvalid = true);
      return;
    }
    if (v == current) return;
    _applyColor(v, isCustom: true);
  }

  Widget _swatchRow(List<Widget> cells) => Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: AspectRatio(aspectRatio: 1, child: cells[i])),
          ],
        ],
      );

  Widget _swatch(String spec, List<String> colors) {
    return LayoutBuilder(builder: (context, c) {
      final d = c.maxWidth;
      return InkResponse(
        onTap: () => _applyColor(spec, isCustom: false),
        radius: d / 2,
        child: SelectableFrame(
          selected: _isCurrentSlotSpec(colors, spec),
          radius: d / 2,
          gap: 2,
          child: _Dot(spec: spec, size: double.infinity),
        ),
      );
    });
  }

  Widget _pickerButton(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final d = c.maxWidth;
      return Tooltip(
        message: l.iconMakerPickColor,
        child: InkResponse(
          onTap: _pickCustomHex,
          radius: d / 2,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: DashedRectBorder(
              color: scheme.primary,
              borderRadius: Radius.circular(d / 2),
              child: Center(
                child: Icon(AppIcons.eyedropper,
                    size: d * 0.4, color: scheme.primary),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Reset every element back to the type's defaults (first icon + its default
  /// colours, default background, no border, circle). Undoable.
  void _resetToDefault() {
    _pushSnapshot();
    setState(() {
      _init(null);
      _focusedRole = widget.roles.first;
      _focusedSlotIndex = 0;
    });
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

/// A filled colour circle with a hairline outline (light colours on light
/// surfaces stay visible).
class _Dot extends StatelessWidget {
  const _Dot({required this.spec, required this.size});

  final String spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolveColor(spec, palette),
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
      ),
    );
  }
}

/// Placeholder for a not-yet-used "เลือกเอง" (recent) slot.
class _EmptySwatch extends StatelessWidget {
  const _EmptySwatch();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: DashedRectBorder(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: Radius.circular(c.maxWidth / 2),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

/// One style-grid cell: ring-highlighted when selected, colour-slot dots
/// (or a caption) underneath. No dots = colours can't be changed.
class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.selected,
    required this.preview,
    required this.onTap,
    this.dots,
    this.label,
  });

  final bool selected;
  final Widget preview;
  final VoidCallback onTap;
  final List<String>? dots;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        Expanded(
          child: Material(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: selected
                  ? BorderSide(color: scheme.primary, width: 2)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(child: FittedBox(child: preview)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        if (label != null)
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          SizedBox(
            height: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final spec in dots ?? const <String>[])
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resolveColor(spec, palette),
                      border:
                          Border.all(color: scheme.outlineVariant, width: 0.5),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
