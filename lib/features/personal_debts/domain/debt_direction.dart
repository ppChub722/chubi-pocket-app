enum DebtEntryDirection {
  paid,

  received;

  String get wire => name;

  static DebtEntryDirection parse(String? s) =>
      s == 'received' ? DebtEntryDirection.received : DebtEntryDirection.paid;
}

/// Quick create's debt mode (owner 2026-10-21): record a debt (a ledger row)
/// or repay (a transaction tied to the person).
enum DebtEntrySub { record, repay }

/// Which way a repayment's money goes: I pay them back, or they pay me.
enum DebtRepaymentKind {
  pay,
  receive;

  String get wire => name;

  /// From a person's balance (> 0 = they owe me): what settles it.
  static DebtRepaymentKind forNet(double net) =>
      net > 0 ? DebtRepaymentKind.receive : DebtRepaymentKind.pay;
}
