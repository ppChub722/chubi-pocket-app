import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../molecules/detail_rows.dart';
import '../tokens/app/app_icons.dart';

/// A section whose heading toggles it (owner 2026-10-12): the green section
/// title, a one-line [hint] while open, a one-line [summary] while closed (the
/// caller says what is inside: "3 people · Trip"), a chevron. One piece for
/// the แบ่งรายการ block, the debts person history, … Not collapsible
/// ([collapsible] false) it is just a titled, always-open section.
///
/// Rendered through [SectionCard] (the grouped look): heading + description
/// above, the rows in the filled rounded container, the chevron on the heading
/// row.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    required this.title,
    required this.children,
    this.hint,
    this.summary,
    this.leading,
    this.trailing,
    this.initiallyOpen = true,
    this.collapsible = true,
    this.onToggle,
    super.key,
  });

  final String title;

  /// The rows of the section — each in the grouped container (2 px gaps,
  /// outer corners), exactly like a [SectionCard]; shown while open.
  final List<Widget> children;

  /// A caption under the title while open.
  final String? hint;

  /// What is inside, shown under the title while closed (null = [hint]'s
  /// slot stays empty).
  final String? summary;

  /// A mark before the title.
  final Widget? leading;

  /// An action at the end of the heading row (before the chevron).
  final Widget? trailing;
  final bool initiallyOpen;
  final bool collapsible;
  final ValueChanged<bool>? onToggle;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _open = !widget.collapsible || widget.initiallyOpen;

  void _toggle() {
    setState(() => _open = !_open);
    widget.onToggle?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final open = !widget.collapsible || _open;
    return SectionCard(
      first: true,
      title: widget.title,
      leading: widget.leading,
      description: open ? widget.hint : widget.summary,
      onHeaderTap: widget.collapsible ? _toggle : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?widget.trailing,
          if (widget.collapsible)
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 160),
              child: PpForgeIcon(
                PpForgeIcons.expand,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      children: open ? widget.children : const [],
    );
  }
}
