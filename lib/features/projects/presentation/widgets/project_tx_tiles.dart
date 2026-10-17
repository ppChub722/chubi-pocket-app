import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../event_errors.dart';
import '../../../../ui/ui.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import 'project_common.dart';
import 'resolve_sheet.dart';

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

/// Type bubble for a project row (expense / income), on the kit's
/// [IconTile].
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

/// A member's [PersonMark] level: linked to an app account, else a typed
/// name (with or without an icon of its own).
PersonLevel projectMemberLevel(ProjectMember m) => m.isLinked
    ? PersonLevel.linked
    : (m.iconCode != null ? PersonLevel.contact : PersonLevel.name);

/// One board row + its split children, on the kit's [EventBillRow]. Tap the
/// tick to tick ("I've settled this") — when it's yours to settle, the
/// "record in my book" sheet comes first. Tap the row for the action sheet
/// (unmark / record / edit / delete). Ticked rows fade; locked rows are
/// inert. A tag chip opens its menu ("ดูบิลที่ติดแท็กนี้").
class ProjectTxTreeTile extends StatelessWidget {
  const ProjectTxTreeTile({
    required this.tree,
    required this.view,
    required this.onChanged,
    this.onPatch,
    this.onShowTag,
    this.onAddTagToMine,
    this.highlighted = false,
    super.key,
  });

  final ProjectTxTree tree;
  final ProjectView view;

  /// Reload the page (a write whose response can't patch it yet).
  final Future<void> Function() onChanged;

  /// A write's patch: the page applies it (null → [onChanged]).
  final ValueChanged<EventPatch>? onPatch;

  /// "ดูบิลที่ติดแท็กนี้": the รายการ tab filtered by this tag (null = no
  /// tag menu).
  final ValueChanged<BoardTag>? onShowTag;

  /// "+ เพิ่มเข้าแท็กของฉัน" (only on tags I don't have yet).
  final ValueChanged<BoardTag>? onAddTagToMine;

  /// A brief tint: the bill a link opened the page on (`?bill=`).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final parent = tree.parent;
    final payer = view.memberOf(parent);
    final myId = view.me?.id;
    final marked = myId != null && parent.isMarkedBy(myId);
    final symbol = context.readUserCurrencySymbol;
    final locked = view.rowsLocked;
    final showTag = onShowTag;
    return EventBillRow(
      title: parent.description ?? parent.tags.firstOrNull ?? '—',
      amount: parent.type == 'expense' ? -parent.amount : parent.amount,
      symbol: symbol,
      marked: marked,
      locked: locked,
      onTickTap: () => marked
          ? _actions(context, parent, isParent: true)
          : _tick(context, parent, isParent: true),
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
      payerName: l.fpEventsPaidBy(payer.displayName),
      payerLevel: projectMemberLevel(payer),
      payerIconCode: payer.iconCode,
      // The day is the group's heading; line 2 = payer · split count.
      summary: tree.children.isEmpty
          ? null
          : l.fpEventsSplitCount(tree.children.length),
      onTap: () => _actions(context, parent, isParent: true),
      children: [
        for (final c in tree.children)
          _child(context, c, payer: payer, symbol: symbol, myId: myId),
      ],
    );
  }

  Widget _child(
    BuildContext context,
    ProjectTransaction c, {
    required ProjectMember payer,
    required String symbol,
    required String? myId,
  }) {
    final l = AppLocalizations.of(context)!;
    final debtor = view.memberOf(c);
    final marked = myId != null && c.isMarkedBy(myId);
    void open() => marked
        ? _actions(context, c, isParent: false)
        : _tick(context, c, isParent: false);
    return EventBillChildRow(
      name: debtor.displayName,
      amount: c.amount,
      level: projectMemberLevel(debtor),
      iconCode: debtor.iconCode,
      caption: l.projectTxOwes(payer.displayName),
      tone: MoneyTone.plain,
      symbol: symbol,
      marked: marked,
      locked: view.rowsLocked,
      onTickTap: open,
      onTap: open,
    );
  }

  /// Mine to settle: payer of a parent row, or debtor / creditor of a split.
  bool _canResolve(ProjectTransaction tx, {required bool isParent}) {
    final my = view.me?.id;
    if (my == null) return false;
    if (isParent) return tx.transactionMemberId == my;
    return tx.transactionMemberId == my ||
        tree.parent.transactionMemberId == my;
  }

  Future<void> _tick(
    BuildContext context,
    ProjectTransaction tx, {
    required bool isParent,
  }) async {
    if (view.rowsLocked) return;
    if (_canResolve(tx, isParent: isParent)) {
      final done = await _resolve(context, tx, isParent: isParent);
      if (!done || !context.mounted) return;
    }
    await _mark(context, tx, true);
  }

  Future<bool> _resolve(
    BuildContext context,
    ProjectTransaction tx, {
    required bool isParent,
  }) async {
    final my = view.me!.id;
    final counterparty = isParent
        ? null
        : tx.transactionMemberId == my
        ? view.memberOf(tree.parent)
        : view.memberOf(tx);
    final ok = await showResolveSheet(
      context,
      tx: tx,
      isParent: isParent,
      childrenTotal: isParent ? tree.childrenTotal : 0,
      myMemberId: my,
      counterparty: counterparty,
    );
    if (ok && context.mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.projectResolveDone,
        tone: Tone.success,
      );
    }
    return ok;
  }

  /// The write's patch to the page (no reload); a reload without a page
  /// handler (the hub demo).
  Future<void> _apply(EventPatch p) async {
    final apply = onPatch;
    if (apply != null) {
      apply(p);
    } else {
      await onChanged();
    }
  }

  /// One call; the PUT returns the patch.
  Future<void> _mark(
    BuildContext context,
    ProjectTransaction tx,
    bool on,
  ) async {
    try {
      final p = await context.read<ProjectsRepository>().toggleMark(
        view.project.id,
        tx.id,
        on,
      );
      await _apply(p);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          eventErrorText(AppLocalizations.of(context)!, e),
          tone: Tone.danger,
        );
      }
    }
  }

  Future<void> _actions(
    BuildContext context,
    ProjectTransaction tx, {
    required bool isParent,
  }) async {
    if (view.rowsLocked) return;
    final l = AppLocalizations.of(context)!;
    final my = view.me?.id;
    final marked = my != null && tx.isMarkedBy(my);
    final canResolve = _canResolve(tx, isParent: isParent);
    final action = await showActionSheet<String>(
      context,
      header: ActionSheetHeader(
        leading: projectTxIcon(context, tx),
        title: tx.description ?? tx.tags.firstOrNull ?? '—',
        subtitle: [
          view.memberOf(tx).displayName,
          projectTxDateLabel(context, tx.date),
          if (tx.note?.isNotEmpty ?? false) tx.note!,
        ].join(' · '),
        trailing: MoneyText(
          tx.type == 'expense' ? -tx.amount : tx.amount,
          symbol: context.readUserCurrencySymbol,
          tone: MoneyTone.signed,
        ),
      ),
      actions: [
        // The personal transaction this bill was made from (only its
        // owner gets it from the BE).
        if (tx.sourceTx case final src?)
          SheetAction(
            value: 'source',
            icon: AppIcons.link,
            label: l.eventSourceTx,
            subtitle: src.description ?? src.accountName,
          ),
        if (marked)
          SheetAction(
            value: 'unmark',
            icon: AppIcons.undo,
            label: l.projectTxUnmark,
          ),
        if (canResolve)
          SheetAction(
            value: 'resolve',
            icon: AppIcons.settle,
            label: l.projectTxResolve,
            subtitle: l.projectTxResolveHint,
          ),
        // Edit / delete follow the BE's row lock (viewers, inactive
        // members, cancelled / archived events).
        if (isParent && !tx.locked) ...[
          SheetAction(
            value: 'edit',
            icon: AppIcons.edit,
            label: l.projectTxEdit,
          ),
          SheetAction(
            value: 'delete',
            icon: AppIcons.delete,
            label: l.projectTxDelete,
            destructive: true,
          ),
        ],
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case 'source':
        openPage(context, '/transactions/${tx.sourceTx!.id}');
      case 'unmark':
        await _mark(context, tx, false);
      case 'resolve':
        await _resolve(context, tx, isParent: isParent);
      case 'edit':
        // Quick create hands back the write's patch (no reload).
        final patch = onPatch;
        final saved = await showQuickCreateSheet(
          context,
          project: view,
          projectRow: tree,
          onEventSaved: patch,
        );
        if (saved && patch == null) await onChanged();
      case 'delete':
        await _delete(context, tx);
    }
  }

  Future<void> _delete(BuildContext context, ProjectTransaction tx) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.projectTxDeleteTitle,
      message: l.projectTxDeleteBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final p = await context.read<ProjectsRepository>().deleteTransaction(
        view.project.id,
        tx.id,
      );
      if (context.mounted) {
        showAppSnackBar(context, l.projectTxDeleted, tone: Tone.success);
      }
      await _apply(p);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          eventErrorText(AppLocalizations.of(context)!, e),
          tone: Tone.danger,
        );
      }
    }
  }
}
