import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell/tab_nav.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../transactions/presentation/widgets/recurring_link.dart';
import '../../transactions/presentation/widgets/transaction_picker.dart';
import '../data/recurring_link_repository.dart';
import '../data/recurring_repository.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring_item.dart';
import 'recurring_item_actions.dart';

/// Occurrences being written, so a second tap waits for the first.
final _inFlight = <String>{};

Future<bool> _write(
  BuildContext context,
  String key,
  Future<ItemWriteResult> Function(RecurringRepository repo) run,
  ValueChanged<ItemWriteResult> onChanged, {
  String? done,
}) async {
  if (!_inFlight.add(key)) return false;
  final repo = RecurringRepository.of(context);
  final accounts = context.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final r = await run(repo);
    accounts.patchBalances(r.balances);
    HapticFeedback.mediumImpact();
    onChanged(r);
    if (done != null) showAppSnackBarOn(messenger, done, tone: Tone.success);
    return true;
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, e.message, tone: Tone.danger);
    return false;
  } finally {
    _inFlight.remove(key);
  }
}

String? _text(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

/// What the sheet changed, as `PUT …/occurrences/{slot}` fields (a present
/// key overrides, null clears).
Map<String, dynamic> occurrenceFields(PendingDraft was, PendingDraft now) => {
  if (now.amount != was.amount) 'amount': now.amount,
  if (now.date != was.date) 'date': now.date,
  if (_text(now.description) != _text(was.description))
    'description': _text(now.description),
  if (_text(now.note) != _text(was.note)) 'note': _text(now.note),
  if (now.accountId != was.accountId) 'account_id': now.accountId,
  if (now.transferToAccountId != was.transferToAccountId)
    'to_account_id': now.transferToAccountId,
  if (now.categoryId != was.categoryId) 'category_id': now.categoryId,
  if (!_sameSet(now.tagIds, was.tagIds)) 'tag_ids': now.tagIds,
};

bool _sameSet(List<String> a, List<String> b) =>
    a.length == b.length && a.toSet().containsAll(b);

/// ยืนยัน: records the tx (dated the occurrence unless the sheet moved it),
/// after storing the sheet's other edits on the occurrence.
Future<bool> confirmOccurrence(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
  PendingDraft? was,
  PendingDraft? now,
}) {
  final l = AppLocalizations.of(context)!;
  final rule = item.ruleId!;
  final slot = item.slot!;
  final rest = was == null || now == null
      ? const <String, dynamic>{}
      : (occurrenceFields(was, now)
          ..remove('amount')
          ..remove('date')
          ..remove('account_id'));
  return _write(
    context,
    item.id,
    (r) async {
      if (rest.isNotEmpty) await r.updateOccurrence(rule, slot, rest);
      return r.confirmOccurrence(
        rule,
        slot,
        amount: now?.amount,
        date: now == null || now.date == was?.date ? null : parseYmd(now.date),
        accountId: now == null || now.accountId == was?.accountId
            ? null
            : now.accountId,
      );
    },
    onChanged,
    done: l.quickSaved,
  );
}

/// ข้าม; one linked to a tx asks whether that tx goes too.
Future<bool> skipOccurrence(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  bool? deleteTx;
  if (item.transaction != null) {
    final l = AppLocalizations.of(context)!;
    final choice = await showLinkedPrompt(
      context,
      title: l.occurrenceSkipLinkedTitle,
      cancelLabel: l.linkedCancel,
      thisSideLabel: l.occurrenceSkipKeepTx,
      bothSidesLabel: l.occurrenceSkipDeleteTx,
      destructive: true,
    );
    if (choice == null || !context.mounted) return false;
    deleteTx = choice == LinkedChoice.bothSides;
  }
  return _write(
    context,
    item.id,
    (r) => r.skipOccurrence(item.ruleId!, item.slot!, deleteTx: deleteTx),
    onChanged,
  );
}

Future<bool> _restore(
  BuildContext context,
  RecurringItem item,
  ValueChanged<ItemWriteResult> onChanged,
) => _write(
  context,
  item.id,
  (r) => r.restoreOccurrence(item.ruleId!, item.slot!),
  onChanged,
);

Future<bool> _paid(
  BuildContext context,
  RecurringItem item,
  ValueChanged<ItemWriteResult> onChanged, {
  required bool paid,
}) => _write(
  context,
  item.id,
  (r) => paid
      ? r.markOccurrencePaid(item.ruleId!, item.slot!)
      : r.unmarkOccurrencePaid(item.ruleId!, item.slot!),
  onChanged,
);

/// ผูกกับรายการที่มีอยู่: picks a tx near the occurrence's date; one already
/// on another occurrence asks before it moves.
Future<bool> linkExistingTx(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  final l = AppLocalizations.of(context)!;
  final tx = await TransactionPicker.one(
    context,
    type: item.type,
    near: item.date,
    categoryId: item.category?.id,
    amount: item.amount,
  );
  if (tx == null || !context.mounted) return false;
  final moving = tx.recurringItem != null;
  if (moving) {
    final ok = await showConfirmDialog(
      context,
      title: l.recurringLinkSwapTitle,
      message: l.recurringLinkMoveBody,
      confirmLabel: l.recurringLinkSwapYes,
    );
    if (!ok || !context.mounted) return false;
  }
  if (!_inFlight.add(item.id)) return false;
  final repo = RecurringLinkRepository.of(context);
  final accounts = context.read<AccountsCubit>();
  final txCubit = context.read<TransactionsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final r = await repo.linkOccurrence(
      item.ruleId!,
      item.slot!,
      tx.id,
      replace: moving,
    );
    accounts.patchBalances(r.balances);
    final fresh = r.transaction;
    if (fresh != null) txCubit.patchRow(fresh, afterWrite: true);
    HapticFeedback.mediumImpact();
    onChanged(ItemWriteResult(items: [?r.item], balances: r.balances));
    showAppSnackBarOn(messenger, l.recurringLinked, tone: Tone.success);
    return true;
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, recurringLinkError(l, e), tone: Tone.danger);
    return false;
  } finally {
    _inFlight.remove(item.id);
  }
}

/// One occurrence in the quick create sheet (แก้เฉพาะงวดนี้): บันทึก keeps the
/// edits on this occurrence only, ยืนยัน records the tx. Chips: ข้าม /
/// จ่ายแล้ว / ผูกกับรายการที่มีอยู่, or ยกเลิกการข้าม / ยกเลิกจ่ายแล้ว once
/// settled. One with a tx opens the tx; one from an old BE (no slot) the old
/// item sheet.
Future<void> openOccurrenceSheet(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  final tx = item.transaction;
  if (tx != null) {
    await editTransaction(context, tx.id);
    return;
  }
  if (item.state == OccurrenceState.pending) {
    openPage(context, '/pending');
    return;
  }
  if (!item.bySlot) {
    await editRecurringItem(context, item, onChanged: onChanged);
    return;
  }
  final l = AppLocalizations.of(context)!;
  final initial = item.toDraft();
  final settled = item.state.settled;
  final link = EntrySheetChip(
    label: l.occurrenceLinkExisting,
    icon: AppIcons.link,
    onTap: (c) => linkExistingTx(c, item, onChanged: onChanged),
  );
  await showEntrySheet(
    context,
    title: item.recurring?.name ?? item.title,
    subtitle: l.occurrenceEditOnly,
    initial: initial,
    chips: switch (item.state) {
      OccurrenceState.archived => [
        EntrySheetChip(
          label: l.occurrenceRestore,
          icon: AppIcons.unarchive,
          onTap: (c) => _restore(c, item, onChanged),
        ),
      ],
      OccurrenceState.paid => [
        EntrySheetChip(
          label: l.occurrenceUnmarkPaid,
          icon: AppIcons.undo,
          onTap: (c) => _paid(c, item, onChanged, paid: false),
        ),
        link,
      ],
      _ => [
        EntrySheetChip(
          label: l.occurrenceSkip,
          icon: AppIcons.none,
          onTap: (c) => skipOccurrence(c, item, onChanged: onChanged),
        ),
        EntrySheetChip(
          label: l.occurrenceMarkPaid,
          icon: AppIcons.check,
          onTap: (c) => _paid(c, item, onChanged, paid: true),
        ),
        link,
      ],
    },
    actions: [
      EntrySheetAction(
        label: l.commonSave,
        primary: settled,
        onPressed: (draft) async {
          final fields = occurrenceFields(initial, draft);
          if (fields.isEmpty) return true;
          return _write(
            context,
            item.id,
            (r) => r.updateOccurrence(item.ruleId!, item.slot!, fields),
            onChanged,
          );
        },
      ),
      if (!settled)
        EntrySheetAction(
          label: l.occurrenceConfirm,
          onPressed: (draft) => confirmOccurrence(
            context,
            item,
            onChanged: onChanged,
            was: initial,
            now: draft,
          ),
        ),
    ],
  );
}

/// [openOccurrenceSheet] for an occurrence known only by its address (a home
/// card, a notice): rule + slot (+ its [date], in case it was moved), else
/// the stored [itemId]. One that can't be found opens its rule.
Future<void> openOccurrence(
  BuildContext context, {
  String? itemId,
  String? ruleId,
  String? slot,
  DateTime? date,
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  final repo = RecurringRepository.of(context);
  final RecurringItem? item;
  try {
    item = ruleId != null && slot != null
        ? await repo.findOccurrence(ruleId, slot, date: date)
        : itemId == null
        ? null
        : await repo.getItem(itemId);
  } on ApiException catch (e) {
    if (context.mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    return;
  }
  if (!context.mounted) return;
  if (item == null) {
    openPage(context, '/recurring/$ruleId');
    return;
  }
  await openOccurrenceSheet(context, item, onChanged: onChanged);
}

/// A due occurrence's buttons in ต้องจัดการ: ยืนยัน in one tap when the
/// amount is known, else ใส่ยอด (the sheet); ⋯ แก้เฉพาะงวดนี้ / จ่ายแล้ว /
/// ข้าม / ผูกกับรายการที่มีอยู่. A skipped one offers ยกเลิกการข้าม. Null when
/// there is nothing to do (recorded, paid, or an old BE's row).
OccurrenceActions? occurrenceActionsFor(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  if (!item.bySlot) return null;
  final l = AppLocalizations.of(context)!;
  if (item.state == OccurrenceState.archived) {
    return OccurrenceActions(
      primary: OccurrenceAction(
        label: l.occurrenceRestore,
        onTap: () => unawaited(_restore(context, item, onChanged)),
      ),
    );
  }
  if (item.state.settled || item.state == OccurrenceState.pending) {
    return null;
  }
  void sheet() =>
      unawaited(openOccurrenceSheet(context, item, onChanged: onChanged));
  final unknown = item.needsAmount || item.amount == null;
  return OccurrenceActions(
    primary: unknown
        ? OccurrenceAction(
            label: l.occurrenceEnterAmount,
            warning: true,
            onTap: sheet,
          )
        : OccurrenceAction(
            label: l.occurrenceConfirm,
            onTap: () => unawaited(
              confirmOccurrence(context, item, onChanged: onChanged),
            ),
          ),
    more: [
      if (!unknown) OccurrenceAction(label: l.occurrenceEditOnly, onTap: sheet),
      OccurrenceAction(
        label: l.occurrenceMarkPaid,
        onTap: () => unawaited(_paid(context, item, onChanged, paid: true)),
      ),
      OccurrenceAction(
        label: l.occurrenceSkip,
        onTap: () =>
            unawaited(skipOccurrence(context, item, onChanged: onChanged)),
      ),
      OccurrenceAction(
        label: l.occurrenceLinkExisting,
        onTap: () =>
            unawaited(linkExistingTx(context, item, onChanged: onChanged)),
      ),
    ],
  );
}

/// A rule's all-at-once buttons for its [DueGroupHeader]: ยืนยันทั้งหมด (the
/// ones with an amount; the rest stay, a snack says how many), ⋯
/// จ่ายแล้วทั้งหมด / ข้ามทั้งหมด.
OccurrenceActions settleAllActions(
  BuildContext context,
  String ruleId, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  void run(OccurrenceBulk action) => unawaited(
    _write(context, 'rule:$ruleId', (r) => r.settleAll(ruleId, action), (r) {
      onChanged(r);
      final noAmount = r.leftOut.where((o) => o.reason == 'needs_amount');
      final refused = r.leftOut.length - noAmount.length;
      final left = [
        if (noAmount.isNotEmpty) l.occurrenceLeftOut(noAmount.length),
        if (refused > 0) l.occurrenceLeftOutRefused(refused),
      ];
      showAppSnackBarOn(
        messenger,
        left.isEmpty ? l.quickSaved : left.join(' | '),
        tone: left.isEmpty ? Tone.success : Tone.warning,
      );
    }),
  );
  return OccurrenceActions(
    primary: OccurrenceAction(
      label: l.occurrenceConfirmAll,
      onTap: () => run(OccurrenceBulk.confirm),
    ),
    more: [
      OccurrenceAction(
        label: l.occurrencePaidAll,
        onTap: () => run(OccurrenceBulk.markPaid),
      ),
      OccurrenceAction(
        label: l.occurrenceSkipAll,
        onTap: () => run(OccurrenceBulk.skip),
      ),
    ],
  );
}
