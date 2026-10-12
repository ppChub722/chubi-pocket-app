import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import 'event_pick.dart';

/// The event row of the section: what [SplitEventSection] needs to draw
/// "อีเวนต์ … ›" — the name (null = "ไม่ได้เลือก"), a tap (open the picker,
/// or the event itself in view), a ✕ and the lock.
class SplitEventSlot {
  const SplitEventSlot({
    this.name,
    this.onTap,
    this.onClear,
    this.locked = false,
  });

  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;
}

/// THE split + event block of a transaction (owner 2026-10-12), built once and
/// used by quick create, the pending drafts ("เพิ่มร่าง" + "แก้ร่าง") and the
/// transaction detail:
///
///   แบ่งรายการ                                         (green section heading)
///   แบ่งยอดให้คนอื่น หรือใส่ในอีเวนต์                  (one-line description)
///   แบ่งยอด            [+ เพิ่มคน] [หารเท่ากัน]          (row label, as อีเวนต์)
///   (ฉัน) … ฿  ⟳ · (ลี) … ฿ ✕ · …                       (the people)
///   อีเวนต์                              ไม่ได้เลือก  ›
///
/// No separators inside it. [splits] is the "แบ่งยอด" row (built by the
/// caller: the [SplitsSection] editor with `embedded: true`, or a read-only
/// list); [event] the อีเวนต์ row. Either may be null.
///
/// [collapsible]: the heading toggles it (pending: closed by default, quick
/// create: open by default); closed, the description line gives way to
/// [summary] ("แบ่ง 2 คน · ทริปเชียงใหม่", or "ไม่ได้ตั้ง"). The transaction
/// detail is never collapsible — always open, view and edit.
class SplitEventSection extends StatefulWidget {
  const SplitEventSection({
    this.splits,
    this.event,
    this.summary,
    this.collapsible = false,
    this.initiallyOpen = true,
    this.first = false,
    super.key,
  });

  final Widget? splits;
  final SplitEventSlot? event;
  final String? summary;
  final bool collapsible;
  final bool initiallyOpen;

  /// No band above (the first section of a page).
  final bool first;

  @override
  State<SplitEventSection> createState() => _SplitEventSectionState();
}

class _SplitEventSectionState extends State<SplitEventSection> {
  late bool _open = !widget.collapsible || widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final e = widget.event;
    final open = !widget.collapsible || _open;
    final summary = widget.summary;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  l.txSplitSectionTitle,
                  role: AppTextRole.section,
                ),
              ),
              if (widget.collapsible)
                AppIcon(
                  open ? AppIcons.collapse : AppIcons.expand,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          open || !widget.collapsible
              ? AppText(l.txSplitSectionHint, role: AppTextRole.caption)
              : AppText(
                  summary ?? l.draftExtrasNone,
                  role: AppTextRole.caption,
                  color: summary == null
                      ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : scheme.onSurface,
                  weight: summary == null ? null : FontWeight.w600,
                  maxLines: 1,
                ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.first) const SectionBand(),
        widget.collapsible
            ? InkWell(
                onTap: () => setState(() => _open = !_open),
                child: header,
              )
            : header,
        if (open) ...[
          ?widget.splits,
          if (e != null)
            EventRow(
              name: e.name,
              onTap: e.onTap,
              onClear: e.onClear,
              locked: e.locked,
            ),
        ],
      ],
    );
  }
}
