import 'package:flutter/material.dart';

import '../../molecules/split_row.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/tone.dart';

/// The status line under a [ShareCard]: "✓ แบ่งครบแล้ว" when the rows add up
/// to the bill, "ยังขาด ฿x" / "เกินยอด ฿x" otherwise (red; save waits).
@immutable
class ShareStatus {
  const ShareStatus(this.text, {required this.ok});

  final String text;
  final bool ok;
}

/// One card of the quick-create "ผูกกับ" tabs (owner 2026-10-21): a header
/// (what the card decides) with its action chips (หารเท่ากัน, เพิ่มคน), the
/// [rows] (usually [ShareRow]s) and the [status] line. The rows of every card
/// add up to the bill at the top.
class ShareCard extends StatelessWidget {
  const ShareCard({
    required this.rows,
    this.title,
    this.actions = const [],
    this.headerLeading,
    this.status,
    super.key,
  }) : assert(title != null || headerLeading != null, 'a card needs a header');

  final String? title;

  /// Before the title (the อีเวนต์ card's event chip sits in the header);
  /// with no [title] it takes the header's width.
  final Widget? headerLeading;
  final List<Widget> actions;
  final List<Widget> rows;
  final ShareStatus? status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final status = this.status;
    final title = this.title;
    final leading = headerLeading;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderLine(
            actions: actions,
            title: title == null
                ? leading!
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          ...rows,
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                right: AppSpacing.sm,
              ),
              child: Text(
                status.text,
                key: const ValueKey('shareStatus'),
                textAlign: TextAlign.end,
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (status.ok ? Tone.success : Tone.danger).color(
                    context,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A heading inside a [ShareCard] with its own chips: the อีเวนต์ card's
/// "ใครจ่าย" and "ใครอยู่ในบิล" (+ หารเท่ากัน, เพิ่มคน).
class ShareSubhead extends StatelessWidget {
  const ShareSubhead({required this.title, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: _HeaderLine(
        actions: actions,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A header: [title] at the start, the [actions] chips at the end of the same
/// line when they fit, else on the next line (a 320 phone, big text).
class _HeaderLine extends StatelessWidget {
  const _HeaderLine({required this.title, required this.actions});

  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final head = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SplitRow.height),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: title,
      ),
    );
    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
        child: head,
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          head,
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: actions,
          ),
        ],
      ),
    );
  }
}

/// One row of a [ShareCard]: a [SplitRow] (avatar | name | amount | trailing:
/// × or the "A" toggle), with an optional [tag] under the name ("ใหม่ ·
/// เพิ่มเข้าอีเวนต์").
class ShareRow extends StatelessWidget {
  const ShareRow({
    required this.avatar,
    required this.name,
    required this.amount,
    this.trailing,
    this.tag,
    this.nameTrailing,
    super.key,
  });

  final Widget avatar;
  final Widget name;
  final Widget amount;
  final Widget? trailing;
  final Widget? tag;

  /// Chips right after the name (the [PayChip], "คืนแล้ว").
  final Widget? nameTrailing;

  @override
  Widget build(BuildContext context) {
    final row = SplitRow(
      avatar: avatar,
      name: name,
      amount: amount,
      trailing: trailing,
      nameTrailing: nameTrailing,
    );
    final tag = this.tag;
    if (tag == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: SplitRow.avatarSize + AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Align(alignment: AlignmentDirectional.centerStart, child: tag),
        ),
      ],
    );
  }
}
