import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

/// What [TransactionPicker.pick] answers: a tx, or its create row.
typedef TxPick = ({Transaction? tx, bool create});

/// A recorded tx to link a recurring occurrence (or a debt) to: [type]'s tx
/// within [windowDays] of [near], nearest first; the same category or an
/// amount within 5% under น่าจะใช่. A tx already linked shows its recurring
/// (the caller asks before moving it). [load] replaces the API read.
abstract final class TransactionPicker {
  static const _likely = 'likely';
  static const _near = 'near';
  static const _create = '_create';

  static final _ymd = DateFormat('yyyy-MM-dd');

  static Future<Transaction?> one(
    BuildContext context, {
    required TransactionType type,
    required DateTime near,
    String? categoryId,
    double? amount,
    String? title,
    int windowDays = 45,
    Future<List<Transaction>> Function()? load,
  }) async => (await pick(
    context,
    type: type,
    near: near,
    categoryId: categoryId,
    amount: amount,
    title: title,
    windowDays: windowDays,
    load: load,
  ))?.tx;

  /// [one], plus a first row [createLabel] ("make one instead") and rows
  /// [exclude] leaves out.
  static Future<TxPick?> pick(
    BuildContext context, {
    required TransactionType type,
    required DateTime near,
    String? categoryId,
    double? amount,
    String? title,
    String? createLabel,
    bool Function(Transaction t)? exclude,
    int windowDays = 45,
    Future<List<Transaction>> Function()? load,
  }) async {
    final l = AppLocalizations.of(context)!;
    final fetch = load ?? _fetch(context, type, near, windowDays);
    final byId = <String, Transaction>{};
    final result = await showItemPicker(
      context,
      ItemPickerSheet(
        title: title ?? l.txPickerTitle,
        items: const [],
        create: createLabel == null
            ? null
            : PickerCreate(
                label: (_) => createLabel,
                onCreate: (_) async => _create,
                atTop: true,
              ),
        load: () async {
          final rows = [
            for (final t in await fetch())
              if (!t.isTransferIn && !(exclude?.call(t) ?? false)) t,
          ];
          byId
            ..clear()
            ..addAll({for (final t in rows) t.id: t});
          rows.sort((a, b) => _gap(a, near).compareTo(_gap(b, near)));
          return [
            for (final t in rows)
              _item(l, t, likely: _isLikely(t, categoryId, amount)),
          ];
        },
        groups: [
          PickerGroup(_likely, l.recurringPickerGroupLikely),
          PickerGroup(_near, l.txPickerGroupNear),
        ],
        searchable: true,
        searchHint: l.commonSearch,
      ),
    );
    final id = result?.id;
    if (id == _create) return (tx: null, create: true);
    final tx = id == null ? null : byId[id];
    return tx == null ? null : (tx: tx, create: false);
  }

  static Future<List<Transaction>> Function() _fetch(
    BuildContext context,
    TransactionType type,
    DateTime near,
    int windowDays,
  ) {
    final repo = context.read<TransactionsRepository>();
    return () async => (await repo.list(
      type: type,
      from: _ymd.format(near.subtract(Duration(days: windowDays))),
      to: _ymd.format(near.add(Duration(days: windowDays))),
      perPage: 100,
    )).transactions;
  }

  static int _gap(Transaction t, DateTime near) {
    final d = DateTime.tryParse(t.date);
    return d == null ? 1 << 30 : d.difference(near).inDays.abs();
  }

  static bool _isLikely(Transaction t, String? categoryId, double? amount) {
    if (categoryId != null && t.categoryId == categoryId) return true;
    return amount != null &&
        amount > 0 &&
        (t.amount - amount).abs() <= amount * 0.05 + 0.004;
  }

  static PickerItem _item(
    AppLocalizations l,
    Transaction t, {
    required bool likely,
  }) {
    final d = DateTime.tryParse(t.date);
    final name = t.description?.trim() ?? '';
    final linked = t.recurringItem;
    return PickerItem(
      id: t.id,
      title: name.isNotEmpty ? name : (t.category?.name ?? ''),
      subtitle: [
        if (d != null) DateFormat.MMMd(l.localeName).format(d),
        ?t.account?.name,
        if (linked != null) linked.label(l.recurringPickerGroupRecurring),
      ].join(' | '),
      group: likely ? _likely : _near,
      leading: IconDisplay(
        type: IconType.category,
        size: 36,
        iconCode: t.category?.iconCode,
      ),
      trailing: MoneyText(
        t.amount,
        tone: switch (t.type) {
          TransactionType.expense => MoneyTone.expense,
          TransactionType.income => MoneyTone.income,
          _ => MoneyTone.plain,
        },
      ),
    );
  }
}
