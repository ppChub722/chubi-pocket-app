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
class SplitEventSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: AppSpacing.lg),
        CollapsibleSection(
          title: l.txSplitSectionTitle,
          hint: l.txSplitSectionHint,
          summary: summary ?? l.draftExtrasNone,
          collapsible: collapsible,
          initiallyOpen: initiallyOpen,
          children: [
            ?splits,
            if (e != null)
              EventRow(
                name: e.name,
                onTap: e.onTap,
                onClear: e.onClear,
                locked: e.locked,
              ),
          ],
        ),
      ],
    );
  }
}
