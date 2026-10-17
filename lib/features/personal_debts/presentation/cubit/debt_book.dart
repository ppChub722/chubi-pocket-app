import '../../domain/debt_ledger.dart';

/// "The debts book changed": a debt entry was saved from somewhere that is
/// not a debts page (the shell's + on any page, a notification action). Every
/// live debts cubit patches itself from the write response, so the people
/// list and an open person page follow without the opener wiring a callback.
///
/// Cubits [attach] on creation and [detach] on close.
abstract final class DebtBook {
  static final Set<DebtBookListener> _live = {};

  static void attach(DebtBookListener l) => _live.add(l);

  static void detach(DebtBookListener l) => _live.remove(l);

  /// A saved entry's write response reached the app.
  static void entrySaved(DebtEntryWriteResult r) {
    for (final l in _live.toList()) {
      l.onEntrySaved(r);
    }
  }
}

mixin DebtBookListener {
  void onEntrySaved(DebtEntryWriteResult r);
}
