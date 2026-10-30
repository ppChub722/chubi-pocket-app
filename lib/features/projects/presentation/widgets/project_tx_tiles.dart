import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';
import '../event_assign.dart';
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
/// (with or without an icon of its own); a removed member's spot is empty.
PersonLevel projectMemberLevel(ProjectMember m) => m.isRemoved
    ? PersonLevel.empty
    : m.isLinked
    ? PersonLevel.linked
    : (m.iconCode != null ? PersonLevel.contact : PersonLevel.name);

/// Multi-payer (0.4.1-2): the payer line's people, as the event knows them
/// (a removed one = an empty spot); empty for one payer (the single-name
/// line stays).
List<EventBillPayer> projectBillPayers(
  AppLocalizations l,
  ProjectView view,
  ProjectTransaction bill,
  String Function(double amount) money,
) => [
  if (bill.payers.length > 1)
    for (final p in bill.payers)
      if (view.member(p.member.id) case final m)
        EventBillPayer(
          name: projectMemberName(l, m),
          amount: money(p.amount),
          level: projectMemberLevel(m),
          iconCode: m.iconCode,
          avatar: m.avatar,
        ),
];

/// A member's name on a bill: a removed member's spot reads "ยังไม่ระบุคน".
String projectMemberName(AppLocalizations l, ProjectMember m) =>
    m.isRemoved ? l.evbEmptyPerson : m.displayName;

/// One row of the event book: a bill with its splits, or a payback. A tap
/// opens the event sheet. My part (my line when I paid, else my split) that
/// isn't fully in my books is tinted with a ⤓ (ลงบัญชี: the "my books" card
/// alone); what is booked shows as ✓ chips.
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
    final booked = parent.myBooks;
    final chips = _bookedChips(l, booked);
    VoidCallback? book(Set<String> want) =>
        locked || want.every(booked.contains) ? null : () => _book(context);

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
      final onBook = involved
          ? book({ProjectTransaction.bookDebt, ProjectTransaction.bookRepay})
          : null;
      return EventBillRow(
        tick: false,
        leading: IconTile(icon: AppIcons.transfer, color: color, size: 28),
        title:
            '${projectMemberName(l, payer)} → '
            '${to == null ? '?' : projectMemberName(l, to)}',
        amount: parent.amount,
        amountColor: color,
        symbol: symbol,
        caption: l.evbPaybackBy(by?.displayName ?? '?'),
        badge: involved ? chips : null,
        mine: onBook != null,
        onAction: onBook,
        actionTooltip: l.evbBookMine,
        locked: locked,
        highlighted: highlighted,
        onTap: () => _open(context),
      );
    }

    final showTag = onShowTag;
    final iPaid = myId != null && parent.transactionMemberId == myId;
    final othersIn = tree.children.any((c) => c.transactionMemberId != myId);
    final onBook = book({
      ProjectTransaction.bookTx,
      if (!iPaid || othersIn) ProjectTransaction.bookDebt,
    });
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
      payerName: projectMemberName(l, payer),
      // An income bill reads the same, only the words change (Q-E3).
      payerVerb: parent.type == 'income' ? l.evbReceives : l.evbPays,
      payerLevel: projectMemberLevel(payer),
      payerIconCode: payer.iconCode,
      payerAvatar: payer.avatar,
      // Multi-payer (0.4.1-2): every payer with what they paid, biggest
      // first (the BE order); one payer keeps the single-name line.
      payers: projectBillPayers(
        l,
        view,
        parent,
        (v) => moneyString(context, v, symbol: symbol),
      ),
      badge: iPaid ? chips : null,
      mine: iPaid && onBook != null,
      onAction: iPaid ? onBook : null,
      actionTooltip: l.evbBookMine,
      // A removed payer's empty spot: the tap fills it for this bill.
      onTap: payer.isRemoved
          ? () => _assign(context, payer)
          : () => _open(context),
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const AppDivider.row(),
          _child(
            context,
            c,
            symbol: symbol,
            myId: myId,
            chips: chips,
            onBook: iPaid ? null : onBook,
            bookTooltip: l.evbBookMine,
          ),
        ],
      ],
    );
  }

  /// ✓ ลงหนี้ / ✓ ลงรายการ for what my books already hold.
  Widget? _bookedChips(AppLocalizations l, List<String> booked) {
    final labels = [
      if (booked.contains(ProjectTransaction.bookDebt)) l.evbBookedDebt,
      if (booked.contains(ProjectTransaction.bookTx) ||
          booked.contains(ProjectTransaction.bookRepay))
        l.evbBookedTx,
    ];
    if (labels.isEmpty) return null;
    return EventBookedChips(labels: labels);
  }

  Widget _child(
    BuildContext context,
    ProjectTransaction c, {
    required String symbol,
    required String? myId,
    required Widget? chips,
    required VoidCallback? onBook,
    required String bookTooltip,
  }) {
    final debtor = view.memberOf(c);
    final mine = myId != null && debtor.id == myId;
    return EventBillChildRow(
      tick: false,
      name: projectMemberName(AppLocalizations.of(context)!, debtor),
      amount: c.amount,
      level: projectMemberLevel(debtor),
      iconCode: debtor.iconCode,
      symbol: symbol,
      badge: mine ? chips : null,
      mine: mine && onBook != null,
      onAction: mine ? onBook : null,
      actionTooltip: bookTooltip,
      locked: view.rowsLocked,
      onTap: debtor.isRemoved
          ? () => _assign(context, debtor)
          : () => _open(context),
    );
  }

  /// V15: fill a removed member's empty spot on THIS bill (one call).
  Future<void> _assign(BuildContext context, ProjectMember removed) async {
    if (view.rowsLocked || !view.canAddTx) return;
    final p = await assignEmptySpots(
      context,
      view: view,
      removed: removed,
      billIds: [tree.parent.id],
    );
    if (p == null) return;
    final patch = onPatch;
    patch == null ? await onChanged() : patch(p);
  }

  /// ⤓: the event sheet with only "ลงบัญชีของฉันด้วย"; the bill isn't
  /// changed.
  Future<void> _book(BuildContext context) async {
    final patch = onPatch;
    final saved = await showEventBillSheet(
      context,
      view: view,
      row: tree,
      onPatch: patch,
      booksOnly: true,
    );
    if (saved && patch == null) await onChanged();
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
