/// Which way an entry's money went, seen from me (owner 2026-10-12: two
/// fixed types, like expense / income — th จ่าย / รับ).
enum DebtEntryDirection {
  /// I paid them (lent, repaid, a split I paid): net goes up.
  paid,

  /// They paid me (borrowed, they repaid, a split they paid): net goes down.
  received;

  String get wire => name;

  static DebtEntryDirection parse(String? s) =>
      s == 'received' ? DebtEntryDirection.received : DebtEntryDirection.paid;
}
