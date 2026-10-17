import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../recurring/data/recurring_link_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

/// The amount question after a link: the setting's amount vs the
/// transaction's (`amount_differs`). Asked once.
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

/// "งวด 16 ต.ค." — the period an occurrence stands for.
String recurringPeriodLabel(AppLocalizations l, DateTime date) =>
    l.recurringPickerPeriod(DateFormat.MMMd(l.localeName).format(date));

/// The text of a failed link: 409 ITEM_ALREADY_LINKED has its own words,
/// anything else the BE's message.
String recurringLinkError(AppLocalizations l, ApiException e) =>
    e.code == 'ITEM_ALREADY_LINKED' ? l.recurringLinkAlreadyLinked : e.message;

/// The route of the recurring create page prefilled from a transaction
/// (type, amount, category, wallet, name). The page reads `type=saving` and
/// `account` today; the rest are for it to pick up (see the report).
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

/// The recurring link of ONE transaction form, shared by quick create (the
/// pick is held until the transaction exists, then [link]) and the
/// transaction detail ([linkNow], immediate). Holds the chosen candidate, the
/// busy flag and the open amount question; the page listens and rebuilds.
class RecurringLinkHandle extends ChangeNotifier {
  RecurringLinkHandle({this.repository});

  /// Tests inject one; null = built from the app's ApiClient.
  final RecurringLinkRepository? repository;

  LinkCandidate? _candidate;
  RecurringAmountAsk? _ask;
  bool _busy = false;

  /// The chosen recurring — only while it still fits [type] (a switch of the
  /// draft's type drops it, silently).
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

  /// Forget the chosen candidate but keep the open amount question: the link
  /// is done (the saved row now carries it).
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

  /// Opens the picker; the choice is kept in the handle and returned.
  Future<LinkCandidate?> choose(
    BuildContext context, {
    required TransactionType type,
    required String createRoute,
    String? categoryId,
    double? amount,
  }) async {
    final picked = await showRecurringLinkPicker(
      context,
      type: type,
      categoryId: categoryId,
      amount: amount,
      selectedItemId: candidateFor(type)?.occurrence.itemId,
      createRoute: createRoute,
      repository: repository,
    );
    if (picked != null) _set(candidate: picked);
    return picked;
  }

  RecurringLinkRepository _repo(BuildContext context) =>
      repository ?? RecurringLinkRepository.of(context);

  /// The link call for [txId] with the chosen candidate. Returns the answer
  /// (null on a failure: [error] says why). Opens the amount question when
  /// the BE says the amounts differ.
  Future<LinkResult?> link(
    BuildContext context,
    String txId, {
    required void Function(String message) error,
  }) async {
    final c = _candidate;
    if (c == null) return null;
    final l = AppLocalizations.of(context)!;
    final repo = _repo(context);
    _set(busy: true);
    try {
      final r = await repo.link(c.occurrence.itemId, txId);
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
      error(recurringLinkError(l, e));
      return null;
    }
  }

  /// Detail page: link [txId] now, hand the answer's row to [onLinked].
  Future<Transaction?> linkNow(
    BuildContext context,
    String txId, {
    required void Function(Transaction fresh, Map<String, double> balances)
    onLinked,
    required void Function(String message) error,
  }) async {
    final r = await link(context, txId, error: error);
    final tx = r?.transaction;
    if (r != null && tx != null) onLinked(tx, r.balances);
    return tx;
  }

  /// Detail page: the ✕ of a saved link — ONE `unlinkRecurringItem` call
  /// (the occurrence is open again, the transaction untouched). On success
  /// [onUnlinked] runs (the page patches its cached row); a failure goes to
  /// [error]. Returns whether it worked.
  Future<bool> unlinkNow(
    BuildContext context,
    String itemId, {
    required VoidCallback onUnlinked,
    required void Function(String message) error,
  }) async {
    final repo = _repo(context);
    _set(busy: true);
    try {
      await repo.unlink(itemId);
      _set(busy: false);
      onUnlinked();
      return true;
    } on ApiException catch (e) {
      _set(busy: false);
      error(e.message);
      return false;
    }
  }

  /// The answer to the amount question: "อัปเดต" = ONE `PUT /recurring/:id
  /// {amount}`; "ไม่ต้อง" = nothing. Either way the link stays.
  Future<void> answer(
    BuildContext context, {
    required bool update,
    required void Function(String message) error,
    required void Function(String message) done,
  }) async {
    final a = _ask;
    if (a == null) return;
    if (!update) {
      _set();
      return;
    }
    final l = AppLocalizations.of(context)!;
    final repo = _repo(context);
    _set(busy: true, ask: a);
    try {
      await repo.updateAmount(a.recurringId, a.txAmount);
      _set(busy: false);
      done(l.recurringLinkedAmountUpdated);
    } on ApiException catch (e) {
      _set(busy: false, ask: a);
      error(e.message);
    }
  }

  /// The row's slot. [linkedName] = the saved transaction's own link (shown
  /// as the chip, [onOpenLinked] opens it); otherwise the chosen candidate.
  /// The ✕: on a saved link [onUnlink] (the unlink call); on a draft's pick
  /// [onClear] (local, only before the transaction exists).
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

/// After a quick create saved the transaction: the amount question as a
/// dialog (the sheet is gone, so there is no row to put a card under).
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

/// The picker sheet (thin wrapper over [RecurringPickerSheet]): loads the
/// candidates for [type] in one call, shows them in the BE's order — the
/// recurring group, then the เตือนจ่าย ones (no amount yet) — and resolves
/// the chosen [LinkCandidate]. The footer opens the create page at
/// [createRoute]. Resolves null when dismissed.
Future<LinkCandidate?> showRecurringLinkPicker(
  BuildContext context, {
  required TransactionType type,
  required String createRoute,
  String? selectedItemId,
  String? categoryId,
  double? amount,
  RecurringLinkRepository? repository,
}) async {
  final repo = repository ?? RecurringLinkRepository.of(context);
  final r = await showAppSheetCustom<Object>(
    context,
    useRootNavigator: false,
    builder: (_) => _RecurringLinkSheet(
      type: type,
      repository: repo,
      selectedItemId: selectedItemId,
      categoryId: categoryId,
      amount: amount,
    ),
  );
  if (r is LinkCandidate) return r;
  if (r is RecurringCreateNew && context.mounted) {
    openPage(context, createRoute);
  }
  return null;
}

class _RecurringLinkSheet extends StatefulWidget {
  const _RecurringLinkSheet({
    required this.type,
    required this.repository,
    this.selectedItemId,
    this.categoryId,
    this.amount,
  });

  final TransactionType type;
  final RecurringLinkRepository repository;
  final String? selectedItemId;
  final String? categoryId;
  final double? amount;

  @override
  State<_RecurringLinkSheet> createState() => _RecurringLinkSheetState();
}

class _RecurringLinkSheetState extends State<_RecurringLinkSheet> {
  List<LinkCandidate>? _rows;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await widget.repository.candidates(
        widget.type,
        categoryId: widget.categoryId,
        amount: widget.amount,
      );
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  RecurringPickRow _row(AppLocalizations l, LinkCandidate c) {
    final s = c.setting;
    final o = c.occurrence;
    final status = c.isReminder
        ? l.recurringPickerStatusReminder
        : switch (o.status) {
            'pending' => l.recurringPickerStatusPending,
            'not_created' => l.recurringPickerStatusNotCreated,
            _ => l.recurringPickerStatusUpcoming,
          };
    return RecurringPickRow(
      id: o.itemId,
      title: s.name,
      subtitle:
          '${recurrenceLabel(l, s.rule)} · ${recurringPeriodLabel(l, o.date)} $status',
      leading: c.isReminder
          ? const AppIcon(AppIcons.notifications)
          : IconDisplay(
              type: IconType.category,
              size: 36,
              iconCode: s.iconCode ?? s.category?.iconCode,
            ),
      amount: o.amount,
      tone: switch (s.type) {
        TransactionType.expense => MoneyTone.expense,
        TransactionType.income => MoneyTone.income,
        _ => MoneyTone.plain,
      },
      trailingLabel: c.isReminder ? l.recurringPickerAwaitingAmount : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = _rows ?? const <LinkCandidate>[];
    return RecurringPickerSheet(
      title: l.recurringPickerTitle,
      loading: _rows == null && _error == null,
      error: _error,
      onRetry: _load,
      selectedId: widget.selectedItemId,
      // The BE's order, grouped as it came: a row sits in exactly one group
      // (likely rows leave their normal one); no client-side ranking.
      groups: [
        RecurringPickGroup(
          title: l.recurringPickerGroupLikely,
          rows: [
            for (final c in rows)
              if (c.likely) _row(l, c),
          ],
        ),
        RecurringPickGroup(
          title: l.recurringPickerGroupRecurring,
          rows: [
            for (final c in rows)
              if (!c.likely && !c.isReminder) _row(l, c),
          ],
        ),
        RecurringPickGroup(
          title: l.recurringPickerGroupReminders,
          rows: [
            for (final c in rows)
              if (!c.likely && c.isReminder) _row(l, c),
          ],
        ),
      ],
      createLabel: l.recurringPickerCreate,
      emptyText: l.recurringPickerEmpty,
      onPicked: (id) => Navigator.of(
        context,
      ).pop(rows.firstWhere((c) => c.occurrence.itemId == id)),
      onCreate: () => Navigator.of(context).pop(const RecurringCreateNew()),
    );
  }
}
