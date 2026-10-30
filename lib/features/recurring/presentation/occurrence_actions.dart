import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/shell/tab_nav.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../personal_debts/data/personal_debts_repository.dart';
import '../../personal_debts/domain/debt_ledger.dart';
import '../../personal_debts/presentation/debt_wiring.dart'
    show debtEntryKindName;
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../transactions/presentation/widgets/recurring_link.dart';
import '../../transactions/presentation/widgets/transaction_picker.dart';
import '../data/recurring_link_repository.dart';
import '../data/recurring_repository.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring_item.dart';
import 'recurring_rows.dart' show occurrenceDebtParts;

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
  final l = AppLocalizations.of(context)!;
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
    showAppSnackBarOn(messenger, errorText(l, e), tone: Tone.danger);
    return false;
  } finally {
    _inFlight.remove(key);
  }
}

String? _text(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

/// What the sheet changed, as `PUT …/occurrences/{slot}` fields (a present
/// key overrides, null clears). A หนี้ one ([debt]) has no category, tags
/// or second wallet: those never go.
Map<String, dynamic> occurrenceFields(
  PendingDraft was,
  PendingDraft now, {
  bool debt = false,
}) => {
  if (now.amount != was.amount) 'amount': now.amount,
  if (now.date != was.date) 'date': now.date,
  if (_text(now.description) != _text(was.description))
    'description': _text(now.description),
  if (_text(now.note) != _text(was.note)) 'note': _text(now.note),
  if (now.accountId != was.accountId) 'account_id': now.accountId,
  if (!debt) ...{
    if (now.transferToAccountId != was.transferToAccountId)
      'to_account_id': now.transferToAccountId,
    if (now.categoryId != was.categoryId) 'category_id': now.categoryId,
    if (!_sameSet(now.tagIds, was.tagIds)) 'tag_ids': now.tagIds,
  },
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
      : (occurrenceFields(was, now, debt: item.isDebt)
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

/// ข้าม. A filled one can't be skipped (owner 2026-10-27): its tx (a หนี้'s
/// entry) is disconnected first.
Future<bool> skipOccurrence(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  if (item.transaction != null || item.debtEntry != null) {
    final l = AppLocalizations.of(context)!;
    showAppSnackBar(context, l.occurrenceSkipFilled, tone: Tone.warning);
    return false;
  }
  return _write(
    context,
    item.id,
    (r) => r.skipOccurrence(item.ruleId!, item.slot!),
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

/// ผูกกับรายการที่มีอยู่: picks a tx near the occurrence's date, then links
/// it ([applyOccurrenceTx]). A หนี้ one picks an entry of its person
/// instead ([linkExistingDebtEntry]).
Future<bool> linkExistingTx(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  if (item.isDebt) {
    return linkExistingDebtEntry(context, item, onChanged: onChanged);
  }
  final tx = await pickOccurrenceTx(context, item);
  if (tx == null || !context.mounted) return false;
  return applyOccurrenceTx(context, item, tx, onChanged: onChanged);
}

/// A transaction of the occurrence's type near its date (nothing written).
Future<Transaction?> pickOccurrenceTx(
  BuildContext context,
  RecurringItem item,
) => TransactionPicker.one(
  context,
  type: item.type,
  near: item.date,
  categoryId: item.category?.id,
  amount: item.amount,
);

/// Links [tx] to the occurrence; one already on another occurrence asks
/// before it moves.
Future<bool> applyOccurrenceTx(
  BuildContext context,
  RecurringItem item,
  Transaction tx, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  final l = AppLocalizations.of(context)!;
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
    showAppSnackBarOn(messenger, errorText(l, e), tone: Tone.danger);
    return false;
  } finally {
    _inFlight.remove(item.id);
  }
}

/// หนี้ ผูกกับรายการที่มีอยู่: picks an entry of the rule's person (same
/// จดหนี้ | จ่ายหนี้ and direction), then fills the occurrence with it. One
/// already on another occurrence asks before it moves.
Future<bool> linkExistingDebtEntry(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  final entry = await pickOccurrenceDebtEntry(context, item);
  if (entry == null || !context.mounted) return false;
  if (!_inFlight.add(item.id)) return false;
  final l = AppLocalizations.of(context)!;
  final repo = RecurringRepository.of(context);
  final accounts = context.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  Future<ItemWriteResult> link({bool replace = false}) =>
      repo.linkOccurrenceDebtEntry(
        item.ruleId!,
        item.slot!,
        entry.id,
        replace: replace,
      );
  try {
    ItemWriteResult r;
    try {
      r = await link();
    } on ApiException catch (e) {
      if (e.code != 'ITEM_ALREADY_LINKED' || !context.mounted) rethrow;
      final ok = await showConfirmDialog(
        context,
        title: l.recurringLinkSwapTitle,
        message: l.recurringLinkMoveBody,
        confirmLabel: l.recurringLinkSwapYes,
      );
      if (!ok) return false;
      r = await link(replace: true);
    }
    accounts.patchBalances(r.balances);
    HapticFeedback.mediumImpact();
    onChanged(r);
    showAppSnackBarOn(messenger, l.recurringLinked, tone: Tone.success);
    return true;
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, errorText(l, e), tone: Tone.danger);
    return false;
  } finally {
    _inFlight.remove(item.id);
  }
}

/// An entry of a หนี้ occurrence's person with its จดหนี้ | จ่ายหนี้ and
/// direction, newest first (nothing written).
Future<DebtEntry?> pickOccurrenceDebtEntry(
  BuildContext context,
  RecurringItem item,
) async {
  final person = item.person;
  if (person == null) return null;
  final l = AppLocalizations.of(context)!;
  final repo = context.read<PersonalDebtsRepository>();
  final key = debtPersonKey(contactId: person.contactId, name: person.name);
  final query = DebtEntryQuery(
    direction: item.direction,
    kind: item.debtSub == DebtEntrySub.repay ? 'repayment' : 'debt',
  );
  final byId = <String, DebtEntry>{};
  final result = await showItemPicker(
    context,
    ItemPickerSheet(
      title: l.debtLinkExistingLabel,
      items: const [],
      load: () async {
        final rows = [
          for (final e in (await repo.entries(
            key,
            query: query,
            perPage: 100,
          )).items)
            if (e.id != item.debtEntry?.id) e,
        ];
        byId
          ..clear()
          ..addAll({for (final e in rows) e.id: e});
        return [for (final e in rows) _debtEntryItem(l, e)];
      },
      searchable: true,
      searchHint: l.commonSearch,
      emptyText: l.occurrenceDebtPickEmpty,
    ),
  );
  final id = result?.id;
  return id == null ? null : byId[id];
}

PickerItem _debtEntryItem(AppLocalizations l, DebtEntry e) {
  final d = e.date;
  return PickerItem(
    id: e.id,
    title: e.description ?? debtEntryKindName(l, e),
    subtitle: [
      if (d != null) DateFormat.MMMd(l.localeName).format(d),
      ?e.transaction?.account?.name,
    ].join(' | '),
    trailing: MoneyText(
      e.amount,
      tone: e.direction == DebtEntryDirection.received
          ? MoneyTone.income
          : MoneyTone.expense,
    ),
  );
}

/// One occurrence in the quick create sheet (แก้เฉพาะงวดนี้): บันทึก keeps the
/// edits on this occurrence only, ยืนยัน records the tx; บันทึกในรายการ picks
/// an existing tx instead (linked on ยืนยันและผูก). The bottom left: ข้าม, or
/// ยกเลิกการข้าม / ยกเลิกจ่ายแล้ว once settled. One with a tx opens the tx.
Future<void> openOccurrenceSheet(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) async {
  // A หนี้ one filled by an entry opens the entry (its tx goes with it).
  final entry = item.debtEntry;
  if (entry != null) {
    openPage(context, '/personal-debts/entries/${entry.id}');
    return;
  }
  final tx = item.transaction;
  if (tx != null) {
    await editTransaction(context, tx.id);
    return;
  }
  final l = AppLocalizations.of(context)!;
  final debt = item.isDebt;
  final initial = item.toDraft();
  final settled = item.state.settled;
  final archived = item.state == OccurrenceState.archived;
  await showEntrySheet(
    context,
    title: item.recurring?.name ?? item.title,
    // หนี้: who and จดหนี้ | จ่ายหนี้ (no category / tags of its own).
    subtitle: [
      l.occurrenceEditOnly,
      if (debt) ...occurrenceDebtParts(l, item),
    ].join(' | '),
    initial: initial,
    // หนี้: the person card instead of the category, no tag row.
    debtPerson: debt ? item.person : null,
    // หนี้ fills with an entry of its person, not a transaction.
    chips: [
      if (debt && item.bySlot)
        EntrySheetChip(
          label: l.debtLinkExistingLabel,
          icon: AppIcons.link,
          onTap: (c) => linkExistingDebtEntry(c, item, onChanged: onChanged),
        ),
    ],
    barAction: switch (item.state) {
      OccurrenceState.archived => EntrySheetChip(
        label: l.occurrenceRestore,
        icon: AppIcons.unarchive,
        onTap: (c) => _restore(c, item, onChanged),
      ),
      // The จ่ายแล้ว row takes it off.
      OccurrenceState.paid => null,
      _ => EntrySheetChip(
        label: l.occurrenceSkip,
        icon: AppIcons.none,
        onTap: (c) => skipOccurrence(c, item, onChanged: onChanged),
      ),
    },
    // Paid without a transaction, with its amount (R5); a skipped one too
    // (R4). A recorded one (a saving entry) is paid by its link.
    paid: item.state == OccurrenceState.done
        ? null
        : EntrySheetPaid(
            initial: item.state == OccurrenceState.paid,
            apply: (c, paid, draft) {
              final fields = occurrenceFields(initial, draft, debt: debt);
              final amount = paid ? fields.remove('amount') as double? : null;
              return _write(c, item.id, (r) async {
                if (fields.isNotEmpty) {
                  await r.updateOccurrence(item.ruleId!, item.slot!, fields);
                }
                return paid
                    ? r.markOccurrencePaid(
                        item.ruleId!,
                        item.slot!,
                        amount: amount,
                      )
                    : r.unmarkOccurrencePaid(item.ruleId!, item.slot!);
              }, onChanged);
            },
          ),
    // ออมเงิน records a saving, never a transaction; หนี้ links an entry
    // (the chip above). A skipped one takes a tx straight away (R4).
    link: item.isSaving || debt
        ? null
        : EntrySheetLink(
            pick: (c) => pickOccurrenceTx(c, item),
            apply: (c, tx) =>
                applyOccurrenceTx(c, item, tx, onChanged: onChanged),
          ),
    // บันทึก keeps the edits on the occurrence (it reaches the รอยืนยัน box
    // as edited on its day); สร้างรายการใหม่ ticked records it now.
    // A skipped one is confirmed straight away (R4).
    createAction: settled && !archived
        ? null
        : EntrySheetAction(
            label: l.occurrenceCreateNow,
            onPressed: (draft) => confirmOccurrence(
              context,
              item,
              onChanged: onChanged,
              was: initial,
              now: draft,
            ),
          ),
    actions: [
      EntrySheetAction(
        label: l.commonSave,
        onPressed: (draft) async {
          final fields = occurrenceFields(initial, draft, debt: debt);
          if (fields.isEmpty) return true;
          return _write(
            context,
            item.id,
            (r) => r.updateOccurrence(item.ruleId!, item.slot!, fields),
            onChanged,
          );
        },
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
    if (context.mounted) showErrorSnackBar(context, e);
    return;
  }
  if (!context.mounted) return;
  if (item == null) {
    openPage(context, '/recurring/$ruleId');
    return;
  }
  await openOccurrenceSheet(context, item, onChanged: onChanged);
}

/// A due occurrence's buttons laid out in an OccurrenceFocusCard: the main
/// one (ยืนยัน / ใส่ยอด; a draft's ยืนยัน opens รอยืนยัน), จ่ายแล้ว, ข้าม. The
/// rest are in its sheet (a tap on the card).
List<OccurrenceAction> occurrenceFocusActions(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  void sheet() =>
      unawaited(openOccurrenceSheet(context, item, onChanged: onChanged));
  final unknown = item.needsAmount || item.amount == null;
  return [
    unknown
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
    // จ่ายแล้ว keeps an amount (R5): without one the sheet asks for it.
    OccurrenceAction(
      label: l.occurrenceMarkPaid,
      onTap: unknown
          ? sheet
          : () => unawaited(_paid(context, item, onChanged, paid: true)),
    ),
    OccurrenceAction(
      label: l.occurrenceSkip,
      onTap: () =>
          unawaited(skipOccurrence(context, item, onChanged: onChanged)),
    ),
  ];
}

/// Can be picked for ยืนยันที่เลือก / ข้ามที่เลือก: addressable by slot (an
/// old draft too) and not settled.
bool canSettleSelected(RecurringItem i) => i.bySlot && !i.state.settled;

/// Still needs an amount: it goes in the รอใส่ยอด box with a field.
bool needsAmountInput(RecurringItem i) =>
    i.needsAmount || i.amount == null || i.amount! <= 0;

/// A waiting occurrence's word: รอใส่ยอด while it has no amount, else
/// รอยืนยัน (a due one and an old draft read the same now).
String waitingLabel(AppLocalizations l, RecurringItem i) => needsAmountInput(i)
    ? l.fpRecurringAwaitingValue
    : l.occurrenceStateNotCreated;

/// What ต้องจัดการ does to the picked rows (confirm / skip / markPaid).
typedef SettleAction = OccurrenceBulk;

/// The amount ยืนยัน / จ่ายแล้ว records [i] with: typed in its row, else its
/// own; null while it has none (such a row can only be skipped).
double? settleAmount(RecurringItem i, Map<String, double> typed) {
  final t = typed[i.id];
  if (t != null && t > 0) return t;
  return needsAmountInput(i) ? null : i.amount;
}

/// ยืนยัน / ข้าม (asks first) / จ่ายแล้ว for the picked ones, in one bulk
/// call (per [RecurringRepository.maxBulk]). ยืนยัน and จ่ายแล้ว (R5) take
/// [amounts] typed in the rows and leave out the ones still without an
/// amount. A snack says how many went through and how many were left.
Future<void> settleSelected(
  BuildContext context,
  List<RecurringItem> items, {
  required SettleAction action,
  required ValueChanged<ItemWriteResult> onChanged,
  Map<String, double> amounts = const {},
}) async {
  final l = AppLocalizations.of(context)!;
  if (action == SettleAction.skip) {
    final ok = await showConfirmDialog(
      context,
      title: l.occurrenceSkipSelectedTitle(items.length),
      confirmLabel: l.occurrenceSkip,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
  }
  final withAmount = action != SettleAction.skip;
  final noAmount = withAmount
      ? [
          for (final i in items)
            if (settleAmount(i, amounts) == null) i,
        ]
      : const <RecurringItem>[];
  final repo = RecurringRepository.of(context);
  final accounts = context.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final send = [
    for (final i in items)
      if (!noAmount.contains(i) && _inFlight.add(i.id)) i,
  ];
  var done = 0;
  var refused = 0;
  ApiException? failed;
  try {
    for (var at = 0; at < send.length; at += RecurringRepository.maxBulk) {
      final chunk = send.skip(at).take(RecurringRepository.maxBulk).toList();
      final r = await repo.settleMany(action, [
        for (final i in chunk)
          (
            ruleId: i.ruleId!,
            slot: i.slot!,
            amount: withAmount ? settleAmount(i, amounts) : null,
          ),
      ]);
      accounts.patchBalances(r.balances);
      onChanged(r);
      done += chunk.length - r.leftOut.length;
      refused += r.leftOut.length;
    }
  } on ApiException catch (e) {
    failed = e;
  } finally {
    _inFlight.removeAll(send.map((i) => i.id));
  }
  if (done > 0) HapticFeedback.mediumImpact();
  final parts = [
    if (done > 0)
      switch (action) {
        SettleAction.skip => l.occurrenceSkippedCount(done),
        SettleAction.markPaid => l.occurrencePaidCount(done),
        SettleAction.confirm => l.occurrenceSavedCount(done),
      },
    if (noAmount.isNotEmpty) l.occurrenceLeftOut(noAmount.length),
    if (refused > 0) l.occurrenceLeftOutRefused(refused),
    if (failed != null) errorText(l, failed),
  ];
  if (parts.isEmpty) return;
  showAppSnackBarOn(
    messenger,
    parts.join(' | '),
    tone: failed != null
        ? Tone.danger
        : noAmount.isNotEmpty || refused > 0
        ? Tone.warning
        : Tone.success,
  );
}

/// A rule's all-at-once buttons: ยืนยันทั้งหมด (the
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
