enum DebtEntryDirection {
  paid,

  received;

  String get wire => name;

  static DebtEntryDirection parse(String? s) =>
      s == 'received' ? DebtEntryDirection.received : DebtEntryDirection.paid;
}
