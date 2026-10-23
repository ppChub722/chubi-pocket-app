import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';
import 'event_bill_sheet.dart';
import 'project_common.dart';

String projectTxDateLabel(BuildContext context, String ymd) {
  final l = AppLocalizations.of(context)!;
  final d = DateFormatter.parseDay(ymd);
  if (d == null) return ymd;
  return DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );
}

Widget projectTxIcon(
  BuildContext context,
  ProjectTransaction tx, {
  double size = 36,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final isExpense = tx.type == 'expense';
  return IconTile(
    icon: isExpense ? AppIcons.expense : AppIcons.income,
    color: isExpense ? palette.expense : palette.income,
    size: size,
  );
}

/// A member's [PersonMark] level: linked to an app account, else a typed name
/// (with or without an icon of its own).
PersonLevel projectMemberLevel(ProjectMember m) => m.isLinked
    ? PersonLevel.linked
    : (m.iconCode != null ? PersonLevel.contact : PersonLevel.name);

/// One row of the event book: a bill with its splits, or a payback. A tap
/// opens the event sheet; "ยังไม่ลงบัญชี" marks my part that isn't in my books.
class ProjectTxTreeTile extends StatelessWidget {
  const ProjectTxTreeTile({
    required this.tree,
    required this.view,
    required this.onChanged,
    this.onPatch,
    this.onShowTag,
    this.onAddTagToMine,
    this.highlighted = false,
    this.onlyMine = false,
    super.key,
  });

  final ProjectTxTree tree;
  final ProjectView view;

  /// Reload the page (a write whose response can't patch it yet).
  final Future<void> Function() onChanged;

  final ValueChanged<EventPatch>? onPatch;

  final ValueChanged<BoardTag>? onShowTag;

  /// "+ เพิ่มเข้าแท็กของฉัน" (only on tags I don't have yet).
  final ValueChanged<BoardTag>? onAddTagToMine;

  final bool highlighted;

  /// Shows only my line: my own split, or none when I paid.
  final bool onlyMine;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final parent = tree.parent;
    final payer = view.memberOf(parent);
    final myId = view.me?.id;
    final symbol = context.readUserCurrencySymbol;
    final locked = view.rowsLocked;
    final notBooked = AppChip(
      label: l.evbNotBooked,
      tone: AppChipTone.warning,
      size: ChipSize.mini,
    );

    if (parent.isPayback) {
      final to = tree.children.isEmpty
          ? null
          : view.memberOf(tree.children.first);
      final by = view.members
          .where((m) => m.userId != null && m.userId == parent.recordUserId)
          .firstOrNull;
      final involved =
          myId != null &&
          (parent.transactionMemberId == myId || to?.id == myId);
      final color = ModuleColors.of(context).planning;
      return EventBillRow(
        tick: false,
        leading: IconTile(icon: AppIcons.transfer, color: color, size: 28),
        title: '${payer.displayName} → ${to?.displayName ?? '?'}',
        amount: parent.amount,
        amountColor: color,
        symbol: symbol,
        caption: l.evbPaybackBy(by?.displayName ?? '?'),
        badge: involved && !parent.myBooked ? notBooked : null,
        locked: locked,
        highlighted: highlighted,
        onTap: () => _open(context),
      );
    }

    final showTag = onShowTag;
    final iPaid = myId != null && parent.transactionMemberId == myId;
    final children = !onlyMine
        ? tree.children
        : (iPaid
              ? const <ProjectTransaction>[]
              : [
                  for (final c in tree.children)
                    if (c.transactionMemberId == myId) c,
                ]);
    return EventBillRow(
      tick: false,
      title: parent.description ?? parent.tags.firstOrNull ?? '—',
      amount: parent.type == 'expense' ? -parent.amount : parent.amount,
      symbol: symbol,
      locked: locked,
      tags: [
        for (final t in parent.tagRefs)
          EventTagRef(t.name, iconCode: t.iconCode),
      ],
      tagAnchorBuilder: showTag == null
          ? null
          : (context, i, chip) {
              final tag = parent.tagRefs[i];
              final addToMine = onAddTagToMine;
              return OptionMenuAnchor<String>(
                selected: null,
                options: [
                  if (!tag.mine && addToMine != null)
                    SheetOption(
                      value: 'mine',
                      leading: const AppIcon(AppIcons.add),
                      label: l.eventTagAddToMine,
                    ),
                  SheetOption(
                    value: 'show',
                    leading: const AppIcon(AppIcons.search),
                    label: l.eventTagShowBills,
                  ),
                ],
                onSelected: (v) =>
                    v == 'mine' ? addToMine?.call(tag) : showTag(tag),
                builder: (_, toggle) => chip(toggle),
              );
            },
      linked: parent.linked,
      highlighted: highlighted,
      payerName: payer.displayName,
      payerVerb: l.evbPays,
      payerLevel: projectMemberLevel(payer),
      payerIconCode: payer.iconCode,
      badge: iPaid && !parent.myBooked ? notBooked : null,
      onTap: () => _open(context),
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const AppDivider.row(),
          _child(context, c, symbol: symbol, myId: myId, notBooked: notBooked),
        ],
      ],
    );
  }

  Widget _child(
    BuildContext context,
    ProjectTransaction c, {
    required String symbol,
    required String? myId,
    required Widget notBooked,
  }) {
    final debtor = view.memberOf(c);
    final mine = myId != null && debtor.id == myId;
    return EventBillChildRow(
      tick: false,
      name: debtor.displayName,
      amount: c.amount,
      level: projectMemberLevel(debtor),
      iconCode: debtor.iconCode,
      symbol: symbol,
      badge: mine && !tree.parent.myBooked ? notBooked : null,
      locked: view.rowsLocked,
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (view.rowsLocked) return;
    final patch = onPatch;
    final saved = await showEventBillSheet(
      context,
      view: view,
      row: tree,
      onPatch: patch,
    );
    if (saved && patch == null) await onChanged();
  }
}
