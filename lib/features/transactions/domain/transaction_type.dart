enum TransactionType {
  expense,
  income,
  transfer;

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

  bool get supportsCategoryPicker => this != TransactionType.transfer;

  bool get isCredit => this == TransactionType.income;
}
