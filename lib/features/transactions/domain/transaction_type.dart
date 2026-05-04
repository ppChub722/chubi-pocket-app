/// The three transaction types from spec §04/§2.
///
/// Money direction is encoded by the type itself for [expense] / [income],
/// and by the system category for [transfer] (Transfer IN credits the
/// destination, Transfer OUT debits the source — see spec §2.1).
enum TransactionType {
  expense,
  income,
  transfer;

  /// Wire-format string. Snake-case to match the BE enum
  /// (`'expense' | 'income' | 'transfer'`).
  String toJson() {
    switch (this) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.income:
        return 'income';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  static TransactionType fromJson(String raw) {
    switch (raw) {
      case 'expense':
        return TransactionType.expense;
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        throw ArgumentError('Unknown transaction type: $raw');
    }
  }

  /// Whether the type uses the user-facing category picker. Transfer
  /// transactions auto-assign system Transfer IN/OUT categories — the
  /// picker is hidden for them per spec §2.3.
  bool get supportsCategoryPicker => this != TransactionType.transfer;

  /// The signed effect on an account's balance. For transfer rows, the
  /// sign is encoded by the system category, not the type — callers
  /// must inspect the row's category for transfer direction.
  bool get isCredit => this == TransactionType.income;
}
