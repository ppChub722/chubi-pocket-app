import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../recurring/data/recurring_link_repository.dart';
import '../../../recurring/presentation/widgets/recurring_picker.dart';
import '../../domain/refs.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

class RecurringAmountAsk {
  const RecurringAmountAsk({
    required this.recurringId,
    required this.ruleAmount,
    required this.txAmount,
  });

  final String recurringId;
  final double ruleAmount;
  final double txAmount;
}

String recurringPeriodLabel(AppLocalizations l, DateTime date) =>
    l.recurringPickerPeriod(DateFormat.MMMd(l.localeName).format(date));

bool _alreadyLinked(ApiException e) =>
    e.code == 'ITEM_ALREADY_LINKED' || e.code == 'ALREADY_LINKED';

String recurringLinkError(AppLocalizations l, ApiException e) =>
    _alreadyLinked(e) ? l.recurringLinkAlreadyLinked : e.message;

/// A 409 on link: the occurrence holds another tx (its `details.transaction`)
/// or this tx is on another occurrence. True = link with `replace`.
Future<bool> askSwapLink(BuildContext context, ApiException e) {
  final l = AppLocalizations.of(context)!;
  final tx = e.details?['transaction'];
  final name = tx is Map ? tx['description'] as String? : null;
  return showConfirmDialog(
    context,
    title: l.recurringLinkSwapTitle,
    message: tx is Map
        ? l.recurringLinkSwapBody(
            name == null || name.trim().isEmpty
                ? moneyString(context, (tx['amount'] as num?)?.toDouble() ?? 0)
                : name,
          )
        : l.recurringLinkMoveBody,
    confirmLabel: l.recurringLinkSwapYes,
  );
}

String recurringCreateRoute({
  required TransactionType type,
  double? amount,
  String? categoryId,
  String? accountId,
  String? name,
}) => Uri(
  path: '/recurring/new',
  queryParameters: {
    'type': type.toJson(),
    if (amount != null && amount > 0) 'amount': amount.toString(),
    'category': ?categoryId,
    'account': ?accountId,
    if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
  },
).toString();

class RecurringLinkHandle extends ChangeNotifier {
  RecurringLinkHandle({this.repository});

  final RecurringLinkRepository? repository;

  LinkCandidate? _candidate;
  RecurringAmountAsk? _ask;
  bool _busy = false;

  LinkCandidate? candidateFor(TransactionType type) =>
      _candidate != null && _candidate!.setting.type == type
      ? _candidate
      : null;

  RecurringAmountAsk? get ask => _ask;
  bool get busy => _busy;

  void clear() {
    _candidate = null;
    _ask = null;
    notifyListeners();
  }

  void clearChoice() {
    _candidate = null;
    notifyListeners();
  }

  void _set({LinkCandidate? candidate, RecurringAmountAsk? ask, bool? busy}) {
    if (candidate != null) _candidate = candidate;
    _ask = ask;
    _busy = busy ?? _busy;
    notifyListeners();
  }

  /// [txId] / [txDate]: the tx being linked (an edit), so the picker can
  /// put its date's occurrence first and not call its own one "taken".
  Future<LinkCandidate?> choose(
    BuildContext context, {
    required TransactionType type,
    required String createRoute,
    String? categoryId,
    double? amount,
    DateTime? txDate,
    String? txId,
    String? linkedRuleId,
    String? linkedItemId,
  }) async {
    final chosen = candidateFor(type);
    final picked = await RecurringPicker.one(
      context,
      type: type,
      categoryId: categoryId,
      amount: amount,
      selectedRuleId: chosen?.setting.id ?? linkedRuleId,
      selectedItemId: chosen?.occurrence.itemId ?? linkedItemId,
      createRoute: createRoute,
      txDate: txDate,
      txId: txId,
    );
    if (picked != null) pick(picked);
    return picked;
  }

  void pick(LinkCandidate c) => _set(candidate: c);

  RecurringLinkRepository _repo(BuildContext context) =>
      repository ?? RecurringLinkRepository.of(context);

  Future<LinkResult> _linkCall(
    RecurringLinkRepository repo,
    LinkOccurrence o,
    String txId,
    bool replace,
  ) => o.bySlot
      ? repo.linkOccurrence(o.ruleId!, o.slot!, txId, replace: replace)
      : repo.link(o.itemId, txId, replace: replace);

  /// [replace]: the tx is moving off its own old occurrence, no need to ask.
  /// Otherwise a taken side asks "สลับ?" before linking with replace.
  Future<LinkResult?> link(
    BuildContext context,
    String txId, {
    required void Function(String message) error,
    bool replace = false,
  }) async {
    if (_candidate == null) return null;
    final l = AppLocalizations.of(context)!;
    return linkWith(
      _repo(context),
      txId,
      error: error,
      errorText: (e) => recurringLinkError(l, e),
      askSwap: (e) async => context.mounted && await askSwapLink(context, e),
      replace: replace,
    );
  }

  Future<LinkResult?> linkWith(
    RecurringLinkRepository repo,
    String txId, {
    required void Function(String message) error,
    required String Function(ApiException e) errorText,
    required Future<bool> Function(ApiException e) askSwap,
    bool replace = false,
  }) async {
    final c = _candidate;
    if (c == null) return null;
    _set(busy: true);
    try {
      LinkResult r;
      try {
        r = await _linkCall(repo, c.occurrence, txId, replace || c.replace);
      } on ApiException catch (e) {
        if (e.statusCode != 409 ||
            !_alreadyLinked(e) ||
            replace ||
            c.replace ||
            !await askSwap(e)) {
          rethrow;
        }
        r = await _linkCall(repo, c.occurrence, txId, true);
      }
      _set(
        busy: false,
        ask: r.amountDiffers && r.ruleAmount != null
            ? RecurringAmountAsk(
                recurringId: c.setting.id,
                ruleAmount: r.ruleAmount!,
                txAmount: r.transactionAmount,
              )
            : null,
      );
      return r;
    } on ApiException catch (e) {
      _set(busy: false);
      error(errorText(e));
      return null;
    }
  }

  Future<Transaction?> linkNow(
    BuildContext context,
    String txId, {
    required void Function(Transaction fresh, Map<String, double> balances)
    onLinked,
    required void Function(String message) error,
    bool replace = false,
  }) async {
    final r = await link(context, txId, error: error, replace: replace);
    final tx = r?.transaction;
    if (r != null && tx != null) onLinked(tx, r.balances);
    return tx;
  }

  Future<bool> unlinkNow(
    BuildContext context,
    RecurringItemLink link, {
    required VoidCallback onUnlinked,
    required void Function(String message) error,
  }) => unlinkWith(
    _repo(context),
    link,
    onUnlinked: onUnlinked,
    error: error,
  );

  Future<bool> unlinkWith(
    RecurringLinkRepository repo,
    RecurringItemLink link, {
    required VoidCallback onUnlinked,
    required void Function(String message) error,
  }) async {
    final ruleId = link.recurringId;
    final slot = link.slot;
    _set(busy: true);
    try {
      if (ruleId != null && slot != null) {
        await repo.unlinkOccurrence(ruleId, slot);
      } else {
        await repo.unlink(link.itemId);
      }
      _set(busy: false);
      onUnlinked();
      return true;
    } on ApiException catch (e) {
      _set(busy: false);
      error(e.message);
      return false;
    }
  }

  Future<void> answer(
    BuildContext context, {
    required bool update,
    required void Function(String message) error,
    required void Function(String message) done,
  }) async {
    if (_ask == null) return;
    return answerWith(
      _repo(context),
      update: update,
      error: error,
      done: done,
      doneText: AppLocalizations.of(context)!.recurringLinkedAmountUpdated,
    );
  }

  Future<void> answerWith(
    RecurringLinkRepository repo, {
    required bool update,
    required void Function(String message) error,
    required void Function(String message) done,
    required String doneText,
  }) async {
    final a = _ask;
    if (a == null) return;
    if (!update) {
      _set();
      return;
    }
    _set(busy: true, ask: a);
    try {
      await repo.updateAmount(a.recurringId, a.txAmount);
      _set(busy: false);
      done(doneText);
    } on ApiException catch (e) {
      _set(busy: false, ask: a);
      error(e.message);
    }
  }

  SplitRecurringSlot slot(
    BuildContext context, {
    required TransactionType type,
    required void Function(String message) error,
    required void Function(String message) done,
    VoidCallback? onTap,
    String? linkedName,
    VoidCallback? onOpenLinked,
    VoidCallback? onClear,
    VoidCallback? onUnlink,
    bool locked = false,
    bool editing = true,
    VoidCallback? onLongPress,
  }) {
    final l = AppLocalizations.of(context)!;
    final c = candidateFor(type);
    final a = _ask;
    final ask = a == null
        ? null
        : AskCard(
            message: l.recurringLinkAskAmount(
              moneyString(context, a.ruleAmount),
              moneyString(context, a.txAmount),
            ),
            noLabel: l.recurringLinkAskNo,
            yesLabel: l.recurringLinkAskYes,
            busy: _busy,
            onNo: () =>
                answer(context, update: false, error: error, done: done),
            onYes: () =>
                answer(context, update: true, error: error, done: done),
          );
    final saved = linkedName != null;
    return SplitRecurringSlot(
      name: linkedName ?? c?.setting.name,
      periodLabel: c == null
          ? null
          : recurringPeriodLabel(l, c.occurrence.date),
      onTap: saved ? onOpenLinked : (_busy ? null : onTap),
      onClear: saved ? (_busy ? null : onUnlink) : (c != null ? onClear : null),
      locked: locked,
      editing: editing,
      onLongPress: onLongPress,
      ask: ask,
    );
  }
}

Future<void> askRecurringAmountAfterCreate(
  BuildContext context,
  RecurringLinkHandle handle, {
  required void Function(String message) error,
  required void Function(String message) done,
}) async {
  final a = handle.ask;
  if (a == null || !context.mounted) return;
  final l = AppLocalizations.of(context)!;
  final yes = await showConfirmDialog(
    context,
    title: l.recurringPickerGroupRecurring,
    message: l.recurringLinkAskAmount(
      moneyString(context, a.ruleAmount),
      moneyString(context, a.txAmount),
    ),
    confirmLabel: l.recurringLinkAskYes,
    cancelLabel: l.recurringLinkAskNo,
  );
  if (!context.mounted) return;
  await handle.answer(context, update: yes, error: error, done: done);
}
