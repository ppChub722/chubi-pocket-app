import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
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

/// Type bubble for a project row (expense / income).
class ProjectTxIcon extends StatelessWidget {
  const ProjectTxIcon({required this.tx, this.size = 36, super.key});

  final ProjectTransaction tx;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final isExpense = tx.type == 'expense';
    return IconTile(
      icon: isExpense ? AppIcons.expense : AppIcons.income,
      color: isExpense ? palette.expense : palette.income,
      size: size,
    );
  }
}

/// One board row + its split children. Tap the icon to tick ("I've settled
/// this") — when it's yours to settle, the "record in my book" sheet comes
/// first. Tap the row for the action sheet (unmark / record / edit /
/// delete). Ticked rows fade.
class ProjectTxTreeTile extends StatelessWidget {
  const ProjectTxTreeTile({
    required this.tree,
    required this.view,
    required this.onChanged,
    super.key,
  });

  final ProjectTxTree tree;
  final ProjectView view;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final parent = tree.parent;
    final payer = view.memberOf(parent);
    final myId = view.me?.id;
    final marked = myId != null && parent.isMarkedBy(myId);
    final scheme = Theme.of(context).colorScheme;
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoneyListTile(
          dimmed: marked,
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: view.rowsLocked
                ? null
                : () => marked
                      ? _actions(context, parent, isParent: true)
                      : _tick(context, parent, isParent: true),
            child: CornerBadge(
              size: 36,
              icon: AppIcons.check,
              show: marked,
              // The tick marks the row — state, not decoration.
              essential: true,
              child: ProjectTxIcon(tx: parent),
            ),
          ),
          title: parent.description ?? parent.tags.firstOrNull ?? '—',
          subtitle: Row(
            children: [
              memberAvatar(payer, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  [
                    payer.displayName,
                    projectTxDateLabel(context, parent.date),
                    for (final t in parent.tags) '#$t',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ),
            ],
          ),
          amount: parent.type == 'expense' ? -parent.amount : parent.amount,
          onTap: () => _actions(context, parent, isParent: true),
        ),
        for (final c in tree.children)
          _ChildRow(
            child: c,
            debtor: view.memberOf(c),
            marked: myId != null && c.isMarkedBy(myId),
            onTap: () => myId != null && c.isMarkedBy(myId)
                ? _actions(context, c, isParent: false)
                : _tick(context, c, isParent: false),
            symbol: Currencies.symbolOf(c.currency),
            owesLabel: l.projectTxOwes(payer.displayName),
          ),
      ],
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
    if (view.rowsLocked) {
      await _actions(context, tx, isParent: isParent);
      return;
    }
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

  Future<void> _mark(
    BuildContext context,
    ProjectTransaction tx,
    bool on,
  ) async {
    try {
      await context.read<ProjectsRepository>().toggleMark(
        view.project.id,
        tx.id,
        on,
      );
      await onChanged();
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
    }
  }

  Future<void> _actions(
    BuildContext context,
    ProjectTransaction tx, {
    required bool isParent,
  }) async {
    final l = AppLocalizations.of(context)!;
    final my = view.me?.id;
    final marked = my != null && tx.isMarkedBy(my);
    final editable = isParent && !view.rowsLocked;
    final canResolve = !view.rowsLocked && _canResolve(tx, isParent: isParent);
    final action = await showActionSheet<String>(
      context,
      header: ActionSheetHeader(
        leading: ProjectTxIcon(tx: tx),
        title: tx.description ?? tx.tags.firstOrNull ?? '—',
        subtitle: [
          view.memberOf(tx).displayName,
          projectTxDateLabel(context, tx.date),
          if (tx.note?.isNotEmpty ?? false) tx.note!,
        ].join(' · '),
        trailing: MoneyText(
          tx.type == 'expense' ? -tx.amount : tx.amount,
          symbol: Currencies.symbolOf(tx.currency),
          tone: MoneyTone.signed,
        ),
      ),
      actions: [
        if (marked && !view.rowsLocked)
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
        if (editable) ...[
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
      case 'unmark':
        await _mark(context, tx, false);
      case 'resolve':
        await _resolve(context, tx, isParent: isParent);
      case 'edit':
        final saved = await showQuickCreateSheet(
          context,
          project: view,
          projectRow: tree,
        );
        if (saved) await onChanged();
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
      await context.read<ProjectsRepository>().deleteTransaction(
        view.project.id,
        tx.id,
      );
      if (context.mounted) {
        showAppSnackBar(context, l.projectTxDeleted, tone: Tone.success);
      }
      await onChanged();
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
    }
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.debtor,
    required this.marked,
    required this.onTap,
    required this.symbol,
    required this.owesLabel,
  });

  final ProjectTransaction child;
  final ProjectMember debtor;
  final bool marked;
  final VoidCallback onTap;
  final String symbol;
  final String owesLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListRow(
      indent: AppSpacing.xxl,
      checked: marked,
      dimmed: marked,
      onTap: onTap,
      leading: memberAvatar(debtor, size: 20),
      body: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: debtor.displayName),
            TextSpan(
              text: ' $owesLabel',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall,
      ),
      trailing: MoneyText(
        child.amount,
        symbol: symbol,
        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
