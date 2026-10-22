import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../accounts/presentation/wallet_errors.dart';
import '../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../projects/data/projects_repository.dart';
import '../domain/link_draft.dart';
import '../domain/refs.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';
import '../data/transactions_repository.dart';
import 'cubit/transactions_cubit.dart';
import 'save_failure.dart';
import 'widgets/draft_form.dart';
import 'widgets/event_pick.dart';

/// A plain income / expense of mine edits in the quick create sheet. Splits,
/// an event bill, a debt entry, a transfer, a system or locked row, another
/// member's row: its detail page.
bool txEditsInSheet(Transaction t) =>
    t.type != TransactionType.transfer &&
    !t.isDebtEntry &&
    !t.isLocked &&
    t.canEditCategory &&
    !(t.category?.isSystem ?? false) &&
    t.splitCount == 0 &&
    t.projectId == null &&
    t.eventBill == null;

/// Deleting a tx linked to a recurring occurrence: true = also skip the
/// occurrence, false = the tx only (the occurrence is due again), null =
/// cancelled.
Future<bool?> askDeleteRecurringTx(
  BuildContext context,
  RecurringItemLink link,
) {
  final l = AppLocalizations.of(context)!;
  return showChoiceDialog<bool?>(
    context,
    title: l.txDeleteRecurringTitle,
    message: l.txDeleteRecurringBody(link.label(l.transactionTypeExpense)),
    choices: [
      DialogChoice(value: false, label: l.txDeleteRecurringOnly),
      DialogChoice(
        value: true,
        label: l.txDeleteRecurringSkip,
        variant: AppButtonVariant.destructive,
      ),
      DialogChoice(value: null, label: l.commonCancel),
    ],
  );
}

/// Editing shows the ผูกกับ tabs (0.4.0-3 B3): my own expense, not a
/// repayment / debt entry, not a partner's mirror (its money is locked), not
/// my copy of someone else's event bill (that one follows the board).
bool txLinkTabsEditable(Transaction t) {
  final bill = t.eventBill;
  return t.type == TransactionType.expense &&
      !t.isDebtEntry &&
      !t.isRepayment &&
      !t.isLocked &&
      t.canEditCategory &&
      !(t.category?.isSystem ?? false) &&
      !(t.paidBy?.fromPartner ?? false) &&
      (bill == null || (bill.isOrigin ?? bill.linked));
}

/// The ONE confirm of a tab switch: who and which wallet move, from the
/// BE preview. True = save.
Future<bool> confirmLinkPreview(
  BuildContext context,
  TxEditPreview preview, {
  required String Function(String accountId) walletName,
}) async {
  final l = AppLocalizations.of(context)!;
  String money(double v) => moneyString(context, v);
  final lines = [
    for (final p in preview.people)
      if ((p.after - p.before).abs() > 0.005)
        l.txLinkPreviewLine(p.name, money(p.before), money(p.after)),
    for (final w in preview.wallets)
      if ((w.after - w.before).abs() > 0.005)
        l.txLinkPreviewLine(
          walletName(w.accountId),
          money(w.before),
          money(w.after),
        ),
  ];
  final go = await showChoiceDialog<bool>(
    context,
    title: l.txLinkPreviewTitle,
    message: lines.isEmpty ? l.txLinkPreviewNone : lines.join('\n'),
    choices: [
      DialogChoice(
        value: true,
        label: l.transactionFormSave,
        variant: AppButtonVariant.primary,
      ),
      DialogChoice(value: false, label: l.commonCancel),
    ],
  );
  return go ?? false;
}

/// The ผูกกับ tabs while editing a saved tx (0.4.0-3 B3, owner: the SAME
/// form everywhere): tx detail and the quick create sheet both use it. The
/// edit opens on the saved tab; a switch (or other จ่ายแทน / อีเวนต์ data)
/// is previewed, confirmed ONCE, then rides in the PUT as link_mode + the
/// tab's data.
class LinkEditSession {
  LinkEditSession(this.c);

  final DraftFormController c;

  /// The tabs show for this tx ([txLinkTabsEditable]).
  bool active = false;

  LinkMode? _origin;
  String? _baseline;

  void start(Transaction t, {bool enabled = true}) {
    active = enabled && txLinkTabsEditable(t);
    if (!active) return;
    c.prefillLink(t);
    final m = c.link.mode!;
    _origin = m;
    _baseline = c.linkSnapshot(m);
  }

  /// The แบ่ง rows are what's saved (their checks / the incomplete ask).
  bool get onSplitTab => !active || c.pickedTab == LinkMode.split;

  /// Another tab, or other จ่ายแทน / อีเวนต์ data: the PUT carries
  /// link_mode (a แบ่ง edit on a แบ่ง tx keeps today's splits call).
  bool get changed {
    final m = active ? c.pickedTab : null;
    if (m == null) return false;
    if (m != _origin) return true;
    return (m == LinkMode.paid || m == LinkMode.event) &&
        c.linkSnapshot(m) != _baseline;
  }

  String? _problem(AppLocalizations l, LinkMode m) {
    if (m == LinkMode.paid && c.link.paidBy == null) {
      return l.txLinkModeNeedsPayer;
    }
    if (!c.linkBalanced(m)) {
      return m == LinkMode.split ? l.txSplitUnbalanced : l.txLinkModeUnbalanced;
    }
    return null;
  }

  /// The event a switch into อีเวนต์ goes to: the one picked (a new one is
  /// made first), else the one on the form ([formProjectId]: the sheet keeps
  /// it there), else the tx's own.
  static Future<String?> _projectId(
    BuildContext context,
    Transaction t,
    EventTarget? picked,
    String? formProjectId,
  ) async {
    final l = AppLocalizations.of(context)!;
    if (picked == null && formProjectId != null) return formProjectId;
    switch (picked) {
      case ExistingEventTarget(:final project):
        return project.id;
      case NewEventTarget(:final name):
        try {
          final made = await context.read<ProjectsRepository>().create(
            name: name,
          );
          return made.project.id;
        } on ApiException catch (e) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              eventErrorMessage(l, e),
              tone: Tone.danger,
            );
          }
          return null;
        }
      case RemoveFromEvent():
        break;
      case null:
        final id = t.eventBill?.event.id ?? t.projectId;
        if (id != null) return id;
    }
    if (context.mounted) {
      showAppSnackBar(context, l.txLinkModeNeedsEvent, tone: Tone.danger);
    }
    return null;
  }

  /// Checks, preview, the ONE confirm. Returns the PUT part; null = stop
  /// (a problem said, cancelled, or refused).
  Future<Map<String, dynamic>?> prepare(
    BuildContext context, {
    required Transaction t,
    required EventTarget? event,
    required String? initialAccountId,
    required List<Account> accounts,
    required VoidCallback retry,
  }) async {
    final l = AppLocalizations.of(context)!;
    final m = c.pickedTab!;
    final problem = _problem(l, m);
    if (problem != null) {
      HapticFeedback.lightImpact();
      showAppSnackBar(context, problem, tone: Tone.danger);
      return null;
    }
    final projectId = m == LinkMode.event
        ? await _projectId(context, t, event, c.projectId)
        : null;
    if (m == LinkMode.event && projectId == null) return null;
    if (!context.mounted) return null;
    final link = c.linkEditJson(m, projectId: projectId);
    final repo = context.read<TransactionsRepository>();
    final accountId = c.account?.id;
    final accountChanged = accountId != initialAccountId;
    try {
      // When someone else pays the event, `amount` is the BILL (be-A).
      final preview = await repo.previewUpdate(
        id: t.id,
        amount: c.amountValue,
        accountId: accountChanged ? accountId : null,
        clearAccount: accountChanged && accountId == null,
        link: link,
      );
      if (!context.mounted) return null;
      final go = await confirmLinkPreview(
        context,
        preview,
        walletName: (id) =>
            accounts.where((a) => a.id == id).firstOrNull?.name ?? id,
      );
      return go ? link : null;
    } on ApiException catch (e) {
      if (!context.mounted) return null;
      showSaveFailure(
        context,
        e,
        retry: retry,
        message: splitErrorMessage(l, e) ?? walletErrorMessage(l, e),
      );
      return null;
    }
  }
}

/// Saving an edit of my tx that's tied to another record asks whether that
/// side changes too. An event bill (made from my tx, or my copy; 0.4.0-3
/// B3, owner's words) asks "แก้ในอีเวนต์ด้วยไหม?" [แก้แค่ของฉัน]
/// [แก้ทั้งคู่]; a recurring link keeps the generic ask. The answer is
/// `also_update_link` (= apply_to_event on the BE). cancelled = stop.
Future<({bool cancelled, bool? alsoUpdateLink})> askLinkedTxSave(
  BuildContext context,
  Transaction t,
) async {
  final l = AppLocalizations.of(context)!;
  final event = t.eventBill != null;
  if (!event && !t.hasPromptedLink) {
    return (cancelled: false, alsoUpdateLink: null);
  }
  final choice = await showLinkedPrompt(
    context,
    title: event ? l.linkedEventAskTitle : l.linkedSaveTitle,
    cancelLabel: l.linkedCancel,
    thisSideLabel: event ? l.linkedMineOnly : l.linkedSaveThisOnly,
    bothSidesLabel: event ? l.linkedBoth : l.linkedSaveBoth,
  );
  if (choice == null) return (cancelled: true, alsoUpdateLink: null);
  return (cancelled: false, alsoUpdateLink: choice == LinkedChoice.bothSides);
}

/// The rule the server would reject first; null = ready to save.
String? transactionEditProblem(
  AppLocalizations l,
  DraftFormController c, {
  bool splitsEditable = true,
  bool checkSplits = true,
}) {
  if (c.amountValue <= 0) return l.quickAmountRequired;
  if (c.isTransfer) {
    if (c.account == null || c.toAccount == null) return l.txTransferNeedsTo;
    if (c.account!.id == c.toAccount!.id) return l.txTransferSameWallet;
  }
  // [checkSplits] false: another ผูกกับ tab is saved, the แบ่ง rows stay home.
  if (!c.isTransfer && checkSplits) {
    final total = c.splits
        .where((s) => s.isComplete)
        .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
    if (total > c.splitCap + 0.005) {
      return c.eventOthers > 0 ? l.txSplitExceedsShare : l.txSplitExceeds;
    }
    if (splitsEditable && !c.splitsBalanced) return l.txSplitUnbalanced;
  }
  return null;
}

String? splitErrorMessage(AppLocalizations l, ApiException e) =>
    switch (e.code) {
      'SPLITS_EXCEED_AMOUNT' => l.txSplitExceeds,
      'SPLITS_EXCEED_SHARE' => l.txSplitExceedsShare,
      'SPLIT_CONTACT_NOT_FOUND' ||
      'CONTACT_NOT_FOUND' ||
      'CONTACT_ARCHIVED' => l.txSplitErrorContact,
      'SPLITS_AUTHOR_ONLY' => l.txSplitAuthorOnly,
      _ => null,
    };

Future<bool> confirmIncompleteSplits(
  BuildContext context,
  DraftFormController c,
) async {
  if (c.isTransfer) return true;
  final l = AppLocalizations.of(context)!;
  final half = [
    for (final s in c.splits)
      if (s.personName.trim().isNotEmpty != ((s.owedAmount ?? 0) > 0)) s,
  ];
  if (half.isEmpty) return true;
  final skip = await showChoiceDialog<bool>(
    context,
    title: l.txSplitIncompleteTitle,
    message: [
      for (final s in half)
        s.personName.trim().isEmpty
            ? l.txSplitIncompleteNoName(moneyString(context, s.owedAmount ?? 0))
            : l.txSplitIncompleteNoAmount(s.personName.trim()),
    ].join('\n'),
    choices: [
      DialogChoice(
        value: false,
        label: l.editKeepEditing,
        variant: AppButtonVariant.primary,
      ),
      DialogChoice(value: true, label: l.txSplitSkipIncomplete),
    ],
  );
  return skip ?? false;
}

Future<TransactionEditOutcome> saveTransactionEdit(
  BuildContext context, {
  required Transaction t,
  required DraftFormController c,
  required String? initialAccountId,
  required String? initialToAccountId,
  bool? alsoUpdateLink,
  Map<String, dynamic>? link,
}) async {
  final txCubit = context.read<TransactionsCubit>();
  final accounts = context.read<AccountsCubit>();
  final debts = DebtDirectoryCubit.maybeOf(context);
  final isTransfer = c.isTransfer;
  final description = c.description.text.trim().isEmpty
      ? null
      : c.description.text.trim();
  final note = c.note.text.trim().isEmpty ? null : c.note.text.trim();
  // Another member's row: never send category_id — only the author may change
  // it (403 CATEGORY_AUTHOR_ONLY otherwise).
  final canCategory = !isTransfer && t.canEditCategory;
  final accountId = c.account?.id;
  final accountChanged = accountId != initialAccountId;
  final toAccountChanged = isTransfer && c.toAccount?.id != initialToAccountId;

  final repo = context.read<TransactionsRepository>();
  final splits = [
    for (final s in c.splits)
      if (s.isComplete) s.toUpdateJson(),
  ];
  final splitsBefore = [
    for (final s in t.splits) {'debt_id': s.debtId, 'owed_amount': s.amount},
  ];
  // A row with split_count but no people was edited from a list row — the form
  // never had its splits.
  final splitsLoaded = t.splitCount == 0 || t.splits.isNotEmpty;
  // A ผูกกับ tab switch (B3) carries its splits in [link], in the one PUT.
  final splitsChanged =
      link == null &&
      !isTransfer &&
      t.canEditCategory &&
      splitsLoaded &&
      jsonEncode(splits) != jsonEncode(splitsBefore);
  Future<Transaction?> putSplits() async {
    if (!splitsChanged) return null;
    return repo.updateSplits(t.id, splits);
  }

  final lowering = c.amountValue < t.amount;
  if (lowering) await putSplits();
  final result = await txCubit.updateTransaction(
    id: t.id,
    amount: c.amountValue,
    date: _ymd(c.date),
    categoryId: canCategory ? c.category?.id : null,
    clearCategory: canCategory && t.categoryId != null && c.category == null,
    note: note,
    clearNote: note == null && t.note != null,
    description: description,
    clearDescription: description == null && t.description != null,
    accountId: accountChanged ? accountId : null,
    clearAccount: accountChanged && accountId == null,
    transferToAccountId: toAccountChanged ? c.toAccount?.id : null,
    tagIds: c.tagIds.toList(),
    alsoUpdateLink: alsoUpdateLink,
    link: link,
  );
  accounts.patchBalances(result.accountBalances);
  // A repayment's edit moves the person's balance (0.4.0-3); a tab switch
  // moves everyone's in it.
  for (final b in [?result.personBalance, ...result.personBalances]) {
    debts?.applyBalance(b);
  }
  if (!lowering && splitsChanged) {
    final row = await putSplits();
    if (row != null) txCubit.patchRow(row, afterWrite: true);
  }
  return const TransactionEditOutcome();
}

class TransactionEditOutcome {
  const TransactionEditOutcome({this.warning});

  /// Shown instead of "saved" (none today).
  final String? warning;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
