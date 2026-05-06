import 'package:flutter/material.dart';

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
  );

  if (isWide) {
    return showDialog<IconMakerResult>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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

  final String iconId;
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
  });

  final IconType type;
  final List<IconPack> packs;
  final IconCode? initial;
  final Widget Function(IconCode)? previewBuilder;
  final Widget? previewSubtitle;
  final String? useThisLabel;
  final String? removeLabel;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  // Current icon_code fields
  late String _iconId;
  late List<String> _iconColors;
  String? _bgId;
  late List<String> _bgColors;
  String? _borderId;
  late List<String> _borderColors;

  // Picker focus state
  _Role? _focusedRole;   // null = picker is empty (nothing tapped yet)
  bool _colorMode = false;
  int _focusedSlotIndex = 0;

  // Preview hide toggles — UI only, never saved. Initialised from
  // `IconType.defaultPreviewHides` and reset every time the sheet opens.
  late bool _hideIcon;
  late bool _hideBg;
  late bool _hideBorder;

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
        iconColors: _iconColors,
        background: _bgId,
        bgColors: _bgColors,
        border: _borderId,
        borderColors: _borderColors,
      );

  // ── Initialisation ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final hides = widget.type.defaultPreviewHides;
    _hideIcon = hides.icon;
    _hideBg = hides.bg;
    _hideBorder = hides.border;
    _init(widget.initial);
  }

  /// Live `IconCode` with currently-hidden layers stripped.
  /// Picker tiles, swatches, and editor mini-previews always use [_current];
  /// only the live preview at the top of the sheet uses this.
  IconCode get _previewCode => IconCode(
        icon: _hideIcon ? null : _iconId,
        iconColors: _hideIcon ? const [] : _iconColors,
        background: _hideBg ? null : _bgId,
        bgColors: _hideBg ? const [] : _bgColors,
        border: _hideBorder ? null : _borderId,
        borderColors: _hideBorder ? const [] : _borderColors,
      );

  void _init(IconCode? ic) {
    final allIcons = _allItems(_Role.icon);
    final allBgs = _allItems(_Role.background);

    // Icon
    final firstIconId = allIcons.firstOrNull?.id ?? 'category';
    _iconId = ic?.icon ?? firstIconId;
    if (ic?.iconColors.isNotEmpty == true) {
      _iconColors = List.of(ic!.iconColors);
    } else {
      _iconColors = List.of(
        _findItem(_Role.icon, _iconId)?.colors ?? const ['@presetThemeColorOnIcon'],
      );
    }

    // Background — same path for every type. Tags hide bg at display time
    // via IconType.applyDisplayRules, but still get the full picker here.
    _bgId = ic?.background ?? allBgs.firstOrNull?.id;
    if (ic?.bgColors.isNotEmpty == true) {
      _bgColors = List.of(ic!.bgColors);
    } else {
      _bgColors = List.of(
        _findItem(_Role.background, _bgId ?? '')?.colors ?? const ['@presetThemeColor1'],
      );
    }

    // Border
    _borderId = ic?.border;
    if (ic?.borderColors.isNotEmpty == true) {
      _borderColors = List.of(ic!.borderColors);
    } else if (_borderId != null) {
      _borderColors = List.of(
        _findItem(_Role.border, _borderId!)?.colors ?? const ['@presetThemeColorBorder'],
      );
    } else {
      _borderColors = [];
    }
  }

  // ── Interactions ─────────────────────────────────────────────────────────

  void _openAssetPicker(_Role role) {
    setState(() {
      _focusedRole = role;
      _colorMode = false;
    });
  }

  void _openColorPicker(_Role role, int slotIndex) {
    setState(() {
      _focusedRole = role;
      _colorMode = true;
      _focusedSlotIndex = slotIndex;
    });
  }

  void _selectAsset(_Role role, String? newId) {
    _pushSnapshot();
    setState(() {
      switch (role) {
        case _Role.icon:
          if (newId == null) return;
          final defaults = _findItem(role, newId)?.colors ?? const [];
          // Replace (not merge) — the asset's defaults are the contract.
          // Undo covers regret cases.
          _iconColors = List.of(defaults);
          _iconId = newId;
          if (_colorMode &&
              _focusedRole == role &&
              _focusedSlotIndex >= _iconColors.length) {
            _focusedSlotIndex = 0;
          }
        case _Role.background:
          _bgId = newId;
          if (newId == null) {
            _bgColors = [];
          } else {
            final defaults = _findItem(role, newId)?.colors ?? const [];
            _bgColors = List.of(defaults);
          }
          if (_colorMode &&
              _focusedRole == role &&
              _focusedSlotIndex >= _bgColors.length) {
            _focusedSlotIndex = 0;
          }
        case _Role.border:
          _borderId = newId;
          if (newId == null) {
            _borderColors = [];
          } else {
            final defaults = _findItem(role, newId)?.colors ?? const [];
            _borderColors = List.of(defaults);
          }
          if (_colorMode &&
              _focusedRole == role &&
              _focusedSlotIndex >= _borderColors.length) {
            _focusedSlotIndex = 0;
          }
      }
    });
  }

  /// Apply a colour spec (hex literal or `@presetTheme*` token) to the
  /// currently focused slot. [isCustom] is true only for hex picked via
  /// the custom-hex dialog; those land in the `Recent` strip. Theme/common
  /// swatch taps don't pollute Recent.
  void _applyColor(String spec, {required bool isCustom}) {
    final role = _focusedRole;
    if (role == null) return;
    _pushSnapshot();
    setState(() {
      final colors = _colorsFor(role);
      if (_focusedSlotIndex < colors.length) {
        colors[_focusedSlotIndex] = spec;
      }
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
    final currentSpec = _focusedRole != null &&
            _focusedSlotIndex < _colorsFor(_focusedRole!).length
        ? _colorsFor(_focusedRole!)[_focusedSlotIndex]
        : '#FFFFFF';
    final seedHex = isThemeToken(currentSpec)
        ? '#${(resolveColor(currentSpec, palette).toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'
        : currentSpec;
    final hex = await _showHexDialog(context, seedHex);
    if (hex != null) _applyColor(hex, isCustom: true);
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
            const SizedBox(height: AppSpacing.sm),
            _buildHideToggles(context),
            const SizedBox(height: AppSpacing.md),
            _buildEditorRow(context, _Role.icon),
            const SizedBox(height: AppSpacing.xs),
            _buildEditorRow(context, _Role.background),
            const SizedBox(height: AppSpacing.xs),
            _buildEditorRow(context, _Role.border),
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
    final code = _previewCode;
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

  Widget _buildHideToggles(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) {
      return InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: 0,
      children: [
        toggle('Hide icon', _hideIcon, (v) => setState(() => _hideIcon = v)),
        toggle('Hide background', _hideBg, (v) => setState(() => _hideBg = v)),
        toggle('Hide border', _hideBorder,
            (v) => setState(() => _hideBorder = v)),
      ],
    );
  }

  Widget _buildEditorRow(BuildContext context, _Role role) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = _focusedRole == role;
    final colors = _colorsFor(role);

    final label = switch (role) {
      _Role.icon => 'Icon',
      _Role.background => 'Background',
      _Role.border => 'Border',
    };
    final assetId = switch (role) {
      _Role.icon => _iconId,
      _Role.background => _bgId,
      _Role.border => _borderId,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primaryContainer.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border(left: BorderSide(color: scheme.primary, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openAssetPicker(role),
            child: _buildEditorMiniPreview(role, 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: textTheme.labelMedium),
                Text(
                  assetId ?? '∅ none',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                    fontStyle:
                        assetId == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < colors.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                _SlotSwatch(
                  spec: colors[i],
                  isFocused: isActive && _colorMode && _focusedSlotIndex == i,
                  onTap: () => _openColorPicker(role, i),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorMiniPreview(_Role role, double size) {
    final code = _current;
    switch (role) {
      case _Role.icon:
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

  Widget _buildPickerSection(BuildContext context) {
    if (_focusedRole == null) {
      return _PickerPlaceholder(
        message: 'Tap an element above to edit',
      );
    }
    if (_colorMode) return _buildColorPicker(context);
    return _buildAssetPicker(context, _focusedRole!);
  }

  Widget _buildColorPicker(BuildContext context) {
    final role = _focusedRole!;
    final colors = _colorsFor(role);
    final label = switch (role) {
      _Role.icon => 'Icon',
      _Role.background => 'Background',
      _Role.border => 'Border',
    };
    final total = colors.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label › color ${_focusedSlotIndex + 1} of $total',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Theme row — each swatch resolves through AppColors and shows
        // a 🎨 palette badge to mark it as theme-tracking.
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          children: _themeRowSpecs.map((spec) {
            return _ColorCircle(
              spec: spec,
              isSelected: _isCurrentSlotSpec(colors, spec),
              showThemeBadge: true,
              onTap: () => _applyColor(spec, isCustom: false),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Common row — fixed brand + universal hex literals.
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          children: _commonRowSpecs.map((spec) {
            return _ColorCircle(
              spec: spec,
              isSelected: _isCurrentSlotSpec(colors, spec),
              showThemeBadge: false,
              onTap: () => _applyColor(spec, isCustom: false),
            );
          }).toList(),
        ),
        if (_recentColors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Recent',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentColors.map((spec) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _ColorCircle(
                    spec: spec,
                    isSelected: _isCurrentSlotSpec(colors, spec),
                    showThemeBadge: false,
                    onTap: () => _applyColor(spec, isCustom: false),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _pickCustomHex,
            icon: const Icon(Icons.colorize_outlined, size: 16),
            label: const Text('Custom hex'),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetPicker(BuildContext context, _Role role) {
    final label = switch (role) {
      _Role.icon => 'Icon',
      _Role.background => 'Background',
      _Role.border => 'Border',
    };
    final canBeNull = role != _Role.icon;

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
          _buildPackTiles(context, role, widget.packs[pi], pi == 0 && canBeNull),
        ],
      ],
    );
  }

  Widget _buildPackTiles(
      BuildContext context, _Role role, IconPack pack, bool withNull) {
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

    final crossAxisCount = role == _Role.icon ? 5 : 4;

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
          dots: item.colors,
          isSelected: currentId == item.id,
          onTap: () => _selectAsset(role, item.id),
          isNull: false,
        ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.82,
      children: children,
    );
  }

  Widget _buildTilePreview(
      _Role role, IconPackItem item, IconCode current, double size) {
    switch (role) {
      case _Role.icon:
        final previewCode = current.copyWith(icon: item.id);
        return IconCodeWidget(iconCode: previewCode, size: size);

      case _Role.background:
        final previewCode = current.copyWith(
          background: item.id,
          bgColors: item.colors.isNotEmpty
              ? item.colors
              : current.bgColors,
        );
        return _BgPreview(iconCode: previewCode, size: size);

      case _Role.border:
        final previewCode = current.copyWith(
          border: item.id,
          borderColors: item.colors.isNotEmpty ? item.colors : current.borderColors,
        );
        return _BorderPreview(iconCode: previewCode, size: size);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, AppLocalizations l) {
    return Row(
      children: [
        // Undo button — visible only when there's something to undo.
        // Capped at _undoLimit (10).
        if (_undoStack.isNotEmpty) ...[
          IconButton(
            tooltip: 'Undo (${_undoStack.length})',
            onPressed: _undo,
            icon: const Icon(Icons.undo),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (widget.removeLabel != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pop<IconMakerResult>(const IconMakerRemoved()),
              icon: const Icon(Icons.delete_outline),
              label: Text(widget.removeLabel!),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
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

// ─── Hex input dialog ─────────────────────────────────────────────────────────

Future<String?> _showHexDialog(BuildContext context, String current) async {
  final initial = current.replaceFirst('#', '');
  final ctrl = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Enter hex color'),
      content: TextField(
        controller: ctrl,
        maxLength: 6,
        autocorrect: false,
        decoration: const InputDecoration(
          prefixText: '#',
          hintText: 'e.g. FF5733',
          counterText: '',
        ),
        onSubmitted: (v) {
          final hex = _parseHex(v);
          if (hex != null) Navigator.of(ctx).pop(hex);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final hex = _parseHex(ctrl.text);
            if (hex != null) Navigator.of(ctx).pop(hex);
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

String? _parseHex(String raw) {
  final cleaned = raw.trim().replaceAll('#', '');
  if (cleaned.length != 6) return null;
  if (int.tryParse(cleaned, radix: 16) == null) return null;
  return '#${cleaned.toUpperCase()}';
}

// ─── Small helper widgets ─────────────────────────────────────────────────────

class _SlotSwatch extends StatelessWidget {
  const _SlotSwatch({
    required this.spec,
    required this.isFocused,
    required this.onTap,
  });

  final String spec;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: resolveColor(spec, palette),
          border: Border.all(
            color: isFocused ? scheme.onSurface : scheme.outlineVariant,
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
  });

  final String spec;
  final bool isSelected;
  final bool showThemeBadge;
  final VoidCallback onTap;

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected ? scheme.onSurface : scheme.outlineVariant,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 16, color: checkColor)
                : null,
          ),
          if (showThemeBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                  border: Border.all(color: scheme.outlineVariant, width: 0.5),
                ),
                child: const Center(
                  child: Text('🎨', style: TextStyle(fontSize: 8)),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: scheme.primary, width: 2.5)
                  : null,
            ),
            padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
            child: preview,
          ),
          const SizedBox(height: 4),
          if (dots.isEmpty && !isNull)
            Text(
              'preset',
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

class _PickerPlaceholder extends StatelessWidget {
  const _PickerPlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
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
