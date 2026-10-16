import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/add_tile.dart';
import '../atoms/app_icon.dart';
import '../tokens/app_radius.dart';
import '../atoms/locked_in_edit.dart';

/// Detail-page building blocks: GROUPED sections (owner 2026-10-12 — the one
/// section style). Label left, value/control right — or label on top for long
/// values.
///
/// ```dart
/// SectionCard(first: true, title: 'ข้อมูล', description: '…', children: [
///   DetailRow(icon: PpForgeIcons.email, label: 'อีเมล', trailing: Text(email)),
///   DetailStacked(label: 'บันทึก', child: PpForgeInput.inline(...)),
/// ]),
/// ```

/// One section of a detail page: the green [title] and its one-line
/// [description] sit ABOVE a rounded container with a filled surface and no
/// stroke; the [children] inside are separated by a 2 px gap (the page shows
/// through) and only the first / last rows carry the outer corners. Sections
/// are spaced by [PpForgeSpacing.lg] (none above the [first] one). Strokes stay
/// reserved for editable inputs.
///
/// A group either reserves the leading-icon slot for every [DetailRow] or for
/// none: if any row has an icon, the rows without one keep the space so the
/// titles align ([DetailGroupScope]).
///
/// Sits in a list padded [PpForgeSpacing.lg] at the sides (the detail-page norm).
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.children,
    this.title,
    this.trailing,
    this.leading,
    this.onHeaderTap,
    this.description,
    this.first = false,
    this.locked = false,
    this.dividers = true,
    this.fields = false,
    super.key,
  });

  final List<Widget> children;
  final String? title;

  /// One line right under the green heading: what the section is for
  /// (owner 2026-10-12 — every section heading has one).
  final String? description;

  /// A small action at the end of the title row (👁, share, …).
  final Widget? trailing;

  /// A mark before the title.
  final Widget? leading;

  /// Makes the heading (title row + description) tappable — a
  /// [CollapsibleSection]'s toggle.
  final VoidCallback? onHeaderTap;

  /// The page's first section — no space above it.
  final bool first;

  /// An action section in edit mode: dimmed and inert ([LockedInEdit]).
  final bool locked;

  /// false = the children touch (one block that isn't a list of rows).
  final bool dividers;

  /// The children are form FIELDS (framed `PpForgeInput`s, a picker card) rather than
  /// rows: the section pads each one — a side inset, a small gap between them —
  /// so a page never adds its own spacing. Implies no row gaps.
  final bool fields;

  Widget _tappable(Widget header) => onHeaderTap == null
      ? header
      : InkWell(
          onTap: onHeaderTap,
          overlayColor: _restingOverlay,
          child: header,
        );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasTitleRow = title != null || trailing != null || leading != null;
    final reserve = children.any(
      (c) => c is DetailRow && (c.leading != null || c.icon != null),
    );
    const outer = Radius.circular(PpForgeRadius.lg);
    // A rounded Material, NOT a ClipRRect: a framed field's notched label
    // overhangs its box by half a line, and a clip would cut it in half.
    Widget cell(int i, Widget row) {
      final radius = BorderRadius.vertical(
        top: i == 0 ? outer : Radius.zero,
        bottom: i == children.length - 1 ? outer : Radius.zero,
      );
      return ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.none,
        child: Material(
          color: scheme.surface,
          borderRadius: radius,
          child: fields
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    PpForgeSpacing.lg,
                    i == 0 ? PpForgeSpacing.md : PpForgeSpacing.xs,
                    PpForgeSpacing.lg,
                    i == children.length - 1
                        ? PpForgeSpacing.md
                        : PpForgeSpacing.xs,
                  ),
                  child: row,
                )
              : row,
        ),
      );
    }

    final group = DetailGroupScope(
      reserveIcon: reserve,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in children.indexed) ...[
            if (i > 0) SizedBox(height: dividers ? 2 : 0),
            cell(i, row),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: PpForgeSpacing.lg),
        if (hasTitleRow || description != null)
          _tappable(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasTitleRow)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PpForgeSpacing.md,
                      0,
                      PpForgeSpacing.xs,
                      PpForgeSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: PpForgeSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            title ?? '',
                            style: text.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                  ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PpForgeSpacing.md,
                      0,
                      PpForgeSpacing.md,
                      PpForgeSpacing.sm,
                    ),
                    child: Text(
                      description!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (children.isNotEmpty) LockedInEdit(locked: locked, child: group),
      ],
    );
  }
}

/// A row never looks selected at rest: hover / focus / highlight overlays are
/// transparent (a web hover or a focus kept after a tap tinted the row); only
/// the press splash shows.
final WidgetStateProperty<Color?> _restingOverlay =
    WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.pressed) ? null : Colors.transparent,
    );

/// Tells the [DetailRow]s of a section whether it has leading icons: if any
/// row has one, every row reserves the slot so titles align.
class DetailGroupScope extends InheritedWidget {
  const DetailGroupScope({
    required this.reserveIcon,
    required super.child,
    super.key,
  });

  final bool reserveIcon;

  static bool reserves(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DetailGroupScope>()
          ?.reserveIcon ??
      false;

  @override
  bool updateShouldNotify(DetailGroupScope old) =>
      reserveIcon != old.reserveIcon;
}

/// The "add one more" row at the end of a [SectionCard] (a number, a
/// split, …): a row-style [AddTile], inset like the rows around it.
class DetailAddRow extends StatelessWidget {
  const DetailAddRow({
    required this.label,
    required this.onTap,
    this.icon = PpForgeIcons.add,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.lg,
        vertical: PpForgeSpacing.sm,
      ),
      child: AddTile(
        label: label,
        icon: icon,
        variant: AddTileVariant.row,
        onTap: onTap,
      ),
    );
  }
}

/// A row: label (+ optional helper) on the left, value/control on the right.
/// [onTap] makes the whole row tappable (pickers); [leading] adds an icon;
/// [onLongPress] = the view-mode "long-press to edit" on a row.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    this.trailing,
    this.helper,
    this.error,
    this.leading,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.showChevron = false,
    this.locked = false,
    this.horizontalInset = PpForgeSpacing.lg,
    super.key,
  });

  /// A picker row (owner 2026-10-11): `label  value ›`. An empty [value]
  /// keeps the row, with the muted [emptyText] ("ไม่ได้เลือก") — never
  /// hidden. The `›` shows while it can be tapped ([onTap] set).
  ///
  /// An ENTITY value (a category, wallet, person, event, tag — owner
  /// 2026-10-12) is shown as that entity's chip: pass [valueChip] — an
  /// `PpForgeChip(size: ChipSize.chip, icon:, color:, label:)` (display, no tap) —
  /// instead of [value]; empty stays the faint [emptyText]. A value that is
  /// SEVERAL entities (a budget's categories / tags / wallets) passes
  /// [valueChips]: they wrap, right-aligned, within the half row.
  factory DetailRow.pick({
    required String label,
    String? value,
    Widget? valueChip,
    List<Widget>? valueChips,
    required String emptyText,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? helper,
    String? error,
    Widget? leading,
    IconData? icon,
    bool locked = false,
    double horizontalInset = PpForgeSpacing.lg,
    Key? key,
  }) => DetailRow(
    key: key,
    label: label,
    helper: helper,
    error: error,
    leading: leading,
    icon: icon,
    locked: locked,
    horizontalInset: horizontalInset,
    onTap: onTap,
    onLongPress: onLongPress,
    showChevron: onTap != null,
    trailing: _PickValue(
      value: value,
      chip: valueChip,
      chips: valueChips,
      emptyText: emptyText,
    ),
  );

  /// View mode: enter edit on this row (long-press).
  final VoidCallback? onLongPress;

  final String label;
  final Widget? trailing;
  final String? helper;

  /// A field error under the label ("category required", a server message):
  /// error colour, replaces nothing — it shows after the [helper].
  final String? error;
  final Widget? leading;

  /// A leading icon (an [PpForgeIcon], muted) — the grouped section style's row
  /// glyph. Within one group either every row has one or none does: a group
  /// with any icon reserves the slot on the rows without, so titles align.
  final IconData? icon;
  final VoidCallback? onTap;

  /// Shows a `›` after [trailing] — use for rows that navigate / open a sheet.
  final bool showChevron;

  /// Can't be changed (owner 2026-10-11): a 🔒 right after the value (owner
  /// 2026-10-12: next to the value, so labels stay aligned) — the row itself
  /// is NOT dimmed.
  final bool locked;

  /// Side padding; 0 when the row sits in a form already inset by its page.
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: PpForgeSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null || icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
                child: leading ?? PpForgeIcon(icon!),
              ),
              const SizedBox(width: PpForgeSpacing.md),
            ] else if (DetailGroupScope.reserves(context)) ...[
              const SizedBox(width: 22 + PpForgeSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: detailLabelStyle(context)),
                  if (helper != null) ...[
                    const SizedBox(height: PpForgeSpacing.xs),
                    Text(
                      helper!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: PpForgeSpacing.xs),
                    Text(
                      error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: PpForgeSpacing.md),
              // The value takes only what it needs (up to half the row); the label +
              // helper column is Expanded and gets ALL the rest — a switch row's
              // helper never wraps at half width.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.right,
                  child: trailing!,
                ),
              ),
            ],
            // Locked: a 🔒 right after the value, so every label stays aligned.
            if (locked) ...[
              const SizedBox(width: PpForgeSpacing.xs),
              Icon(PpForgeIcons.lock, size: 16, color: scheme.onSurfaceVariant),
            ],
            if (showChevron) ...[
              const SizedBox(width: PpForgeSpacing.xs),
              Icon(PpForgeIcons.chevronRight, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
    if (onTap == null && onLongPress == null) return row;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      overlayColor: _restingOverlay,
      child: row,
    );
  }
}

/// A placeholder value — "not selected", "no numbers yet", "long-press to
/// edit" (owner 2026-10-12): ONE faint style everywhere. The row that holds
/// it makes the whole row tappable: tapping enters edit mode and starts
/// adding that thing (opens its picker / adds its row).
class DetailPlaceholder extends StatelessWidget {
  const DetailPlaceholder(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
    );
  }
}

/// [DetailRow.pick]'s value: the text, or the muted [emptyText].
class _PickValue extends StatelessWidget {
  const _PickValue({
    required this.value,
    required this.chip,
    required this.emptyText,
    this.chips,
  });

  final String? value;
  final Widget? chip;
  final List<Widget>? chips;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final many = chips;
    if (many != null && many.isNotEmpty) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: PpForgeSpacing.xs,
        runSpacing: PpForgeSpacing.xs,
        children: many,
      );
    }
    if (chip != null) return chip!;
    final empty = value == null || value!.isEmpty;
    if (empty) return DetailPlaceholder(emptyText);
    return Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

/// A row for long values: label on top, value full-width below. The
/// value follows the editable-text indent rule (owner 2026-10-12): an
/// editable value's frame lines up with the label, its text indented by the
/// frame's padding (in view AND edit, so nothing moves when the frame
/// appears); a read-only value has no frame and sits flush with the label.
class DetailStacked extends StatelessWidget {
  const DetailStacked({
    required this.label,
    required this.child,
    this.onLongPress,
    super.key,
  });

  final String label;
  final Widget child;

  /// View mode: enter edit on this block (long-press).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final block = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.lg,
        vertical: PpForgeSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: detailLabelStyle(context)),
          const SizedBox(height: PpForgeSpacing.xs),
          child,
        ],
      ),
    );
    if (onLongPress == null) return block;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: block,
    );
  }
}

/// Bold label style shared by [DetailRow] / [DetailStacked].
TextStyle? detailLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
