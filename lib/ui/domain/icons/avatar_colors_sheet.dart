import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';

/// The icon maker's colour-only mode (0.4.2 1b): a photo source's profile
/// colours 1–3, its ring style (none / thin / thick / dashed) and the ring's
/// colour, picked from the same swatches as the full maker. [previewBuilder]
/// draws the photo with the draft. Null = cancelled.
Future<AvatarColorsDraft?> showAvatarColorsSheet({
  required BuildContext context,
  required AvatarColorsDraft initial,
  required Widget Function(AvatarColorsDraft draft) previewBuilder,
  String? title,
  bool slotsOnly = false,
}) {
  Widget body(BuildContext ctx) => AvatarColorsPanel(
    initial: initial,
    previewBuilder: previewBuilder,
    title: title,
    slotsOnly: slotsOnly,
    onDone: (d) => Navigator.of(ctx).pop<AvatarColorsDraft>(d),
  );
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<AvatarColorsDraft>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: body(ctx),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<AvatarColorsDraft>(
    context: context,
    sheetAnimationStyle: AppMotion.sheetStyle,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.82,
      child: body(ctx),
    ),
  );
}

/// The body of [showAvatarColorsSheet] (the hub shows it inline): preview ·
/// the four targets (colour 1, 2, 3, ring colour) · ring styles · swatches
/// for the focused target · ยกเลิก / ใช้แบบนี้. [onDone] gets the draft, or
/// null on cancel.
class AvatarColorsPanel extends StatefulWidget {
  const AvatarColorsPanel({
    required this.initial,
    required this.previewBuilder,
    required this.onDone,
    this.title,
    this.slotsOnly = false,
    super.key,
  });

  final AvatarColorsDraft initial;
  final Widget Function(AvatarColorsDraft draft) previewBuilder;
  final ValueChanged<AvatarColorsDraft?> onDone;
  final String? title;

  /// Colours 1–3 only: no ring styles, no ring colour (an icon whose
  /// background has no colour of its own; the ring lives in the icon code).
  final bool slotsOnly;

  @override
  State<AvatarColorsPanel> createState() => _AvatarColorsPanelState();
}

class _AvatarColorsPanelState extends State<AvatarColorsPanel> {
  late AvatarColorsDraft _draft = widget.initial;
  final List<AvatarColorsDraft> _undo = [];

  /// 0–2 = colour 1–3, 3 = the ring colour.
  int _focus = 0;
  static const _ring = AvatarColorsDraft.slotCount;

  String _specOf(int target) =>
      target == _ring ? _draft.borderColor : _draft.slots[target];

  void _set(AvatarColorsDraft next) {
    if (next == _draft) return;
    setState(() {
      _undo.add(_draft);
      if (_undo.length > 10) _undo.removeAt(0);
      _draft = next;
    });
  }

  void _apply(String spec, {bool custom = false}) {
    if (custom) {
      final recent = ppForgeRecentColors;
      recent.remove(spec);
      recent.insert(0, spec);
      if (recent.length > 5) recent.removeLast();
    }
    if (_focus == _ring) {
      var next = _draft.withBorderColor(spec);
      // A ring colour with no ring turns a thin ring on.
      if (!next.hasBorder) {
        next = next.withBorderStyle(AvatarBorderStyle.thin);
      }
      _set(next);
    } else {
      _set(_draft.withSlot(_focus, spec));
    }
  }

  void _clearFocused() => _set(
    _focus == _ring
        ? _draft.withBorderStyle(AvatarBorderStyle.none)
        : _draft.withSlot(_focus, ''),
  );

  Future<void> _pickCustom() async {
    final palette = Theme.of(context).extension<AppColors>()!;
    final current = _specOf(_focus);
    final seed = current.isEmpty
        ? Theme.of(context).colorScheme.primary
        : ppForgeResolveColor(current, palette);
    final picked = await showPpForgeColorWheelDialog(
      context,
      seed,
      chubiIconMakerStrings(AppLocalizations.of(context)!),
    );
    if (picked == null || !mounted) return;
    final hex =
        '#${(picked.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    _apply(hex, custom: true);
  }

  String _styleLabel(AppLocalizations l, String style) => switch (style) {
    AvatarBorderStyle.thin => l.avatarBorderThin,
    AvatarBorderStyle.thick => l.avatarBorderThick,
    AvatarBorderStyle.dashed => l.avatarBorderDashed,
    _ => l.avatarBorderNone,
  };

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _target(int i, String label) {
    final scheme = Theme.of(context).colorScheme;
    final spec = _specOf(i);
    final selected = _focus == i;
    return InkWell(
      onTap: () => setState(() => _focus = i),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableFrame(
            selected: selected,
            radius: 20,
            gap: 2,
            child: spec.isEmpty
                ? const SizedBox.square(dimension: 36, child: PpForgeEmptySwatch())
                : PpForgeColorDot(spec: spec, size: 36),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(String spec) => LayoutBuilder(
    builder: (context, c) => InkResponse(
      onTap: () => _apply(spec),
      radius: c.maxWidth / 2,
      child: SelectableFrame(
        selected: _specOf(_focus).toLowerCase() == spec.toLowerCase(),
        radius: c.maxWidth / 2,
        gap: 2,
        child: PpForgeColorDot(spec: spec, size: double.infinity),
      ),
    ),
  );

  Widget _swatchRow(List<Widget> cells) => Row(
    children: [
      for (var i = 0; i < cells.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpacing.sm),
        Expanded(child: AspectRatio(aspectRatio: 1, child: cells[i])),
      ],
    ],
  );

  Widget _picker(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l.iconMakerPickColor,
      child: InkResponse(
        onTap: _pickCustom,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: DashedRectBorder(
            color: scheme.primary,
            borderRadius: const Radius.circular(40),
            child: Center(
              child: Icon(AppIcons.eyedropper, color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _styles(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = _draft.borderColor.isEmpty
        ? AvatarColorsDraft.defaultBorderColor
        : _draft.borderColor;
    return Row(
      children: [
        for (final (i, style) in AvatarBorderStyle.all.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 76,
              child: PpForgeStyleTile(
                selected: _draft.borderStyle == style,
                label: _styleLabel(l, style),
                preview: style == AvatarBorderStyle.none
                    ? Icon(
                        AppIcons.none,
                        size: 28,
                        color: scheme.onSurfaceVariant,
                      )
                    : IconCodeWidget(
                        iconCode: IconCode(
                          border: style,
                          borderColors: [ringColor],
                        ),
                        size: 40,
                      ),
                onTap: () => _set(_draft.withBorderStyle(style)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final recent = ppForgeRecentColors;
    final canClear = _focus == _ring
        ? _draft.hasBorder
        : _specOf(_focus).isNotEmpty;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xs,
            ),
            child: Text(
              widget.title ?? l.avatarColorsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(child: widget.previewBuilder(_draft)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < AvatarColorsDraft.slotCount; i++) ...[
                        Expanded(child: _target(i, l.avatarColorsSlot(i + 1))),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      if (!widget.slotsOnly) ...[
                        Expanded(
                          child: _target(_ring, l.avatarColorsRingColor),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ] else
                        const Spacer(),
                      AppIconButton.flat(
                        tooltip: l.avatarColorsClear,
                        icon: AppIcons.none,
                        onPressed: canClear ? _clearFocused : null,
                      ),
                    ],
                  ),
                  if (!widget.slotsOnly) ...[
                    _section(l.iconMakerRoleBorder),
                    _styles(l),
                  ],
                  _section(l.iconMakerThemeColors),
                  _swatchRow([
                    for (final s in ppForgeThemeColorSpecs) _swatch(s),
                  ]),
                  _section(l.iconMakerCommonColors),
                  _swatchRow([
                    for (final s in chubiCommonColors) _swatch(s),
                  ]),
                  _section(l.iconMakerCustomColors),
                  _swatchRow([
                    _picker(l),
                    for (var i = 0; i < 5; i++)
                      i < recent.length
                          ? _swatch(recent[i])
                          : const PpForgeEmptySwatch(),
                  ]),
                ],
              ),
            ),
          ),
          const AppDivider(),
          ModeActionBar(
            canSave: true,
            canUndo: _undo.isNotEmpty,
            undoTooltip: l.commonUndo,
            cancelLabel: l.commonCancel,
            saveLabel: l.iconPickerUseThis,
            onCancel: () => widget.onDone(null),
            onUndo: () => setState(() => _draft = _undo.removeLast()),
            onSave: () => widget.onDone(_draft),
          ),
        ],
      ),
    );
  }
}
