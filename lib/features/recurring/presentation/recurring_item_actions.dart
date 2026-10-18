import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell/tab_nav.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../data/recurring_repository.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';

enum ItemMenuAction {
  edit,
  sendNow,
  create,
  openPending,
  openTx,
  openRecurring,
  archive,
  restore,
  delete,
}

class RecurringItemActions extends StatefulWidget {
  const RecurringItemActions({
    required this.item,
    required this.onChanged,
    required this.builder,
    this.onOpenRecurring,
    this.onBusy,
    super.key,
  });

  final RecurringItem item;
  final ValueChanged<ItemWriteResult> onChanged;

  final Widget Function(BuildContext context, VoidCallback open) builder;

  final VoidCallback? onOpenRecurring;

  final ValueChanged<bool>? onBusy;

  @override
  State<RecurringItemActions> createState() => _RecurringItemActionsState();
}

class _RecurringItemActionsState extends State<RecurringItemActions> {
  List<ItemMenuAction> get _actions {
    final i = widget.item;
    return [
      ItemMenuAction.edit,
      ...switch (i.state) {
        OccurrenceState.upcoming => [
          ItemMenuAction.sendNow,
          ItemMenuAction.archive,
        ],
        OccurrenceState.notCreated => [
          ItemMenuAction.create,
          ItemMenuAction.archive,
        ],
        OccurrenceState.archived => [
          ItemMenuAction.create,
          ItemMenuAction.restore,
        ],
        OccurrenceState.pending => [ItemMenuAction.openPending],
        OccurrenceState.done => [ItemMenuAction.openTx],
      },
      if (widget.onOpenRecurring != null) ItemMenuAction.openRecurring,
      ItemMenuAction.delete,
    ];
  }

  String _label(AppLocalizations l, ItemMenuAction a) => switch (a) {
    ItemMenuAction.edit => l.commonEdit,
    ItemMenuAction.sendNow => l.recurringItemSendNow,
    ItemMenuAction.create => l.recurringItemCreate,
    ItemMenuAction.openPending => l.recurringItemOpenPending,
    ItemMenuAction.openTx => l.recurringItemOpenTx,
    ItemMenuAction.openRecurring => l.recurringItemOpenRecurring,
    ItemMenuAction.archive => l.recurringItemArchive,
    ItemMenuAction.restore => l.recurringItemRestore,
    ItemMenuAction.delete => l.commonDelete,
  };

  IconData _icon(ItemMenuAction a) => switch (a) {
    ItemMenuAction.edit => AppIcons.edit,
    ItemMenuAction.sendNow => AppIcons.pending,
    ItemMenuAction.create => AppIcons.add,
    ItemMenuAction.openPending => AppIcons.pending,
    ItemMenuAction.openTx => AppIcons.transactions,
    ItemMenuAction.openRecurring => AppIcons.scheduled,
    ItemMenuAction.archive => AppIcons.archive,
    ItemMenuAction.restore => AppIcons.unarchive,
    ItemMenuAction.delete => AppIcons.delete,
  };

  Future<void> _run(ItemMenuAction a) async {
    final i = widget.item;
    switch (a) {
      case ItemMenuAction.edit:
        await editRecurringItem(context, i, onChanged: widget.onChanged);
        return;
      case ItemMenuAction.openPending:
        openPage(context, '/pending');
        return;
      case ItemMenuAction.openTx:
        final tx = i.transaction;
        if (tx != null) openPage(context, '/transactions/${tx.id}');
        return;
      case ItemMenuAction.openRecurring:
        widget.onOpenRecurring?.call();
        return;
      case ItemMenuAction.sendNow:
        await _call((r) => r.createFromItem(i.id, ItemTarget.pending));
      case ItemMenuAction.create:
        await createFromRecurringItem(context, i, onChanged: widget.onChanged);
        return;
      case ItemMenuAction.archive:
        await _call((r) => r.setItemArchived(i.id, archived: true));
      case ItemMenuAction.restore:
        await _call((r) => r.setItemArchived(i.id, archived: false));
      case ItemMenuAction.delete:
        final withTx = await askDeleteLinked(
          context,
          linkedTx: i.transaction != null,
        );
        if (withTx == null) return;
        await _call((r) => r.deleteItem(i.id, deleteLinkedTx: withTx));
    }
  }

  Future<void> _call(
    Future<ItemWriteResult> Function(RecurringRepository repo) run,
  ) async {
    final repo = RecurringRepository.of(context);
    final accounts = context.read<AccountsCubit>();
    widget.onBusy?.call(true);
    try {
      final result = await run(repo);
      accounts.patchBalances(result.balances);
      HapticFeedback.mediumImpact();
      widget.onChanged(result);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      widget.onBusy?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return OptionMenuAnchor<ItemMenuAction>(
      options: [
        for (final a in _actions)
          SheetOption(
            value: a,
            label: _label(l, a),
            leading: AppIcon(_icon(a)),
            destructive: a == ItemMenuAction.delete,
          ),
      ],
      onSelected: _run,
      builder: widget.builder,
    );
  }
}

Future<bool> _sheetWrite(
  BuildContext context,
  Future<ItemWriteResult> Function(RecurringRepository repo) run,
  ValueChanged<ItemWriteResult> onChanged,
) async {
  final repo = RecurringRepository.of(context);
  final accounts = context.read<AccountsCubit>();
  try {
    final result = await run(repo);
    accounts.patchBalances(result.balances);
    HapticFeedback.mediumImpact();
    onChanged(result);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
    return false;
  }
}

Future<void> editRecurringItem(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  return showEntrySheet(
    context,
    title: l.recurringItemEditTitle,
    initial: item.toDraft(),
    actions: [
      EntrySheetAction(
        label: l.commonSave,
        onPressed: (draft) async {
          var scope = EditScope.thisOne;
          if (item.recurring != null) {
            final picked = await askItemScope(context);
            if (picked == null) return false;
            scope = picked;
          }
          if (!context.mounted) return false;
          var alsoUpdateLink = false;
          if (item.linked) {
            final choice = await showLinkedPrompt(
              context,
              title: l.linkedSaveTitle,
              cancelLabel: l.linkedCancel,
              thisSideLabel: l.linkedSaveThisOnly,
              bothSidesLabel: l.linkedSaveBoth,
            );
            if (choice == null) return false;
            alsoUpdateLink = choice == LinkedChoice.bothSides;
          }
          if (!context.mounted) return false;
          return _sheetWrite(
            context,
            (r) => r.updateItem(
              item.id,
              draft,
              scope: scope,
              alsoUpdateLink: alsoUpdateLink,
            ),
            onChanged,
          );
        },
      ),
    ],
  );
}

Future<void> createFromRecurringItem(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  EntrySheetAction action(ItemTarget target) => EntrySheetAction(
    label: target == ItemTarget.pending
        ? l.recurringItemToPending
        : l.recurringItemToTx,
    primary: target == ItemTarget.transaction,
    onPressed: (draft) => _sheetWrite(
      context,
      (r) => r.createFromItem(item.id, target, values: draft),
      onChanged,
    ),
  );
  return showEntrySheet(
    context,
    title: l.recurringItemCreateTitle,
    initial: item.toDraft(),
    actions: [action(ItemTarget.pending), action(ItemTarget.transaction)],
  );
}

Future<void> addRecurringItem(
  BuildContext context,
  Recurring recurring, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  return showEntrySheet(
    context,
    title: l.recurringAddItem,
    initial: PendingDraft(
      type: recurring.type,
      amount: recurring.amount,
      accountId: recurring.account?.id,
      transferToAccountId: recurring.toAccount?.id,
      categoryId: recurring.category?.id,
      date: ymd(today()),
      description: recurring.description,
      tagIds: [for (final t in recurring.tags) t.id],
    ),
    actions: [
      EntrySheetAction(
        label: l.commonSave,
        onPressed: (draft) => _sheetWrite(
          context,
          (r) => r.addItem(recurring.id, draft),
          onChanged,
        ),
      ),
    ],
  );
}

Future<EditScope?> askItemScope(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return showEditScopeChoice(
    context,
    title: l.recurringScopeTitle,
    options: {
      EditScope.thisOne: l.recurringScopeThis,
      EditScope.following: l.recurringScopeFollowing,
      EditScope.past: l.recurringScopePast,
      EditScope.upcoming: l.recurringScopeUpcoming,
      EditScope.all: l.recurringScopeAll,
    },
    selected: EditScope.thisOne,
  );
}

Future<ItemTarget?> askCreateTarget(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return showChoiceDialog<ItemTarget?>(
    context,
    title: l.recurringItemCreateTitle,
    message: l.recurringItemCreateBody,
    choices: [
      DialogChoice(value: null, label: l.linkedCancel),
      DialogChoice(value: ItemTarget.pending, label: l.recurringItemToPending),
      DialogChoice(
        value: ItemTarget.transaction,
        label: l.recurringItemToTx,
        variant: AppButtonVariant.primary,
      ),
    ],
  );
}

/// Deleting items: with a linked real tx it asks "ลบรายการจริงด้วยไหม" (true =
/// both sides); otherwise a plain confirm (false).
Future<bool?> askDeleteLinked(
  BuildContext context, {
  required bool linkedTx,
  int count = 1,
}) async {
  final l = AppLocalizations.of(context)!;
  if (linkedTx) {
    final choice = await showLinkedPrompt(
      context,
      title: l.recurringDeleteLinkedTitle,
      cancelLabel: l.linkedCancel,
      thisSideLabel: l.recurringDeleteItemOnly,
      bothSidesLabel: l.recurringDeleteItemBoth,
      destructive: true,
    );
    return switch (choice) {
      LinkedChoice.thisSideOnly => false,
      LinkedChoice.bothSides => true,
      null => null,
    };
  }
  final ok = await showConfirmDialog(
    context,
    title: l.recurringItemDeleteTitle(count),
    message: l.recurringItemDeleteBody,
    confirmLabel: l.commonDelete,
    destructive: true,
  );
  return ok ? false : null;
}
