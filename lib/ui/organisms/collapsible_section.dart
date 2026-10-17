import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../molecules/detail_rows.dart';
import '../tokens/app/app_icons.dart';

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

  final List<Widget> children;

  final String? hint;

  final String? summary;

  final Widget? leading;

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
              child: AppIcon(AppIcons.expand, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
      children: open ? widget.children : const [],
    );
  }
}
