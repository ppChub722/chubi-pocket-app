import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../recurring/data/recurring_link_repository.dart';
import '../../../recurring/presentation/cubit/recurring_directory_cubit.dart';
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

String recurringLinkError(AppLocalizations l, ApiException e) =>
    e.code == 'ITEM_ALREADY_LINKED' ? l.recurringLinkAlreadyLinked : e.message;

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
    );
    if (picked != null) _set(candidate: picked);
    return picked;
  }

  RecurringLinkRepository _repo(BuildContext context) =>
      repository ?? RecurringLinkRepository.of(context);

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

Future<LinkCandidate?> showRecurringLinkPicker(
  BuildContext context, {
  required TransactionType type,
  required String createRoute,
  String? selectedItemId,
  String? categoryId,
  double? amount,
}) async {
  final r = await showAppSheetCustom<Object>(
    context,
    useRootNavigator: false,
    builder: (_) => _RecurringLinkSheet(
      type: type,
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
    this.selectedItemId,
    this.categoryId,
    this.amount,
  });

  final TransactionType type;
  final String? selectedItemId;
  final String? categoryId;
  final double? amount;

  @override
  State<_RecurringLinkSheet> createState() => _RecurringLinkSheetState();
}

class _RecurringLinkSheetState extends State<_RecurringLinkSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecurringDirectoryCubit>().loadIfNeeded();
    });
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
          '${recurrenceLabel(l, s.rule)} | ${recurringPeriodLabel(l, o.date)} $status',
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
    final directory = context.watch<RecurringDirectoryCubit>();
    final loaded = directory.state.status == RecurringDirectoryStatus.loaded;
    final rows = directory.candidates(
      widget.type,
      categoryId: widget.categoryId,
      amount: widget.amount,
    );
    return SheetRefreshScope(
      onRefresh: directory.load,
      child: RecurringPickerSheet(
        title: l.recurringPickerTitle,
        loading:
            !loaded && directory.state.status != RecurringDirectoryStatus.error,
        error: !loaded ? directory.state.error : null,
        onRetry: directory.load,
        selectedId: widget.selectedItemId,
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
      ),
    );
  }
}
