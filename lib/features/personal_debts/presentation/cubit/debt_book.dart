import '../../domain/debt_ledger.dart';

abstract final class DebtBook {
  static final Set<DebtBookListener> _live = {};

  static void attach(DebtBookListener l) => _live.add(l);

  static void detach(DebtBookListener l) => _live.remove(l);

  static void entrySaved(DebtEntryWriteResult r) {
    for (final l in _live.toList()) {
      l.onEntrySaved(r);
    }
  }
}

mixin DebtBookListener {
  void onEntrySaved(DebtEntryWriteResult r);
}
