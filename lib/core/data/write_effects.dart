import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// 0.4.1-1 B2 — what a write changed, linked sides included (the BE's
/// `Effects`: the answer's own record too, final state; removed ones by id).
/// Kept as JSON here: each cache parses its own part with its own model.
class WriteEffects {
  const WriteEffects(this.json);

  /// The `effects` of a response body, if it carries one.
  static WriteEffects? of(Object? body) {
    if (body is! Map) return null;
    final e = body['effects'];
    return e is Map ? WriteEffects(e.cast<String, dynamic>()) : null;
  }

  final Map<String, dynamic> json;

  List<Map<String, dynamic>> _rows(String key) => [
    for (final r in json[key] as List? ?? const [])
      if (r is Map) r.cast<String, dynamic>(),
  ];

  List<String> _ids(String key) => [
    for (final id in json[key] as List? ?? const [])
      if (id is String) id,
  ];

  List<Map<String, dynamic>> get transactions => _rows('transactions');
  List<String> get removedTransactionIds => _ids('removed_transaction_ids');
  List<Map<String, dynamic>> get debts => _rows('debts');
  List<String> get removedDebtIds => _ids('removed_debt_ids');
  List<Map<String, dynamic>> get slots => _rows('slots');
  List<Map<String, dynamic>> get bills => _rows('bills');
  List<String> get removedBillIds => _ids('removed_bill_ids');
  List<Map<String, dynamic>> get personBalances => _rows('person_balances');

  /// `WalletBalance` rows, as is (`WalletBalance.mapOf` reads them).
  List<Map<String, dynamic>> get accountBalances => _rows('account_balances');
}

typedef EffectsApply = void Function(WriteEffects effects);

/// The one handler (next to the X-Sync-Versions resync): the API client
/// [publish]es every answer's `effects`; each cache that holds those records
/// patches itself, so a page needs no extra call and no re-fetch.
class WriteEffectsBus {
  WriteEffectsBus._();

  static final WriteEffectsBus instance = WriteEffectsBus._();

  final _subs = <EffectsApply>[];

  /// [apply] gets every write's effects. Returns the unsubscribe.
  void Function() listen(EffectsApply apply) {
    _subs.add(apply);
    return () => _subs.remove(apply);
  }

  void publish(WriteEffects effects) {
    for (final apply in List.of(_subs)) {
      try {
        apply(effects);
      } catch (_) {
        // A cache that can't take them keeps its data; the resync fixes it.
      }
    }
  }
}

/// For a cache cubit: [applyEffectsWith] patches it from every write's
/// effects; the subscription ends with the cubit.
mixin ApplyWriteEffects<S> on BlocBase<S> {
  void Function()? _offEffects;

  void applyEffectsWith(EffectsApply apply) {
    _offEffects?.call();
    _offEffects = WriteEffectsBus.instance.listen((e) {
      if (!isClosed) apply(e);
    });
  }

  @override
  Future<void> close() {
    _offEffects?.call();
    return super.close();
  }
}
