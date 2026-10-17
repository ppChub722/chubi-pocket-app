enum CategoryType {
  expense,
  income;

  String toJson() {
    switch (this) {
      case CategoryType.expense:
        return 'expense';
      case CategoryType.income:
        return 'income';
    }
  }

  static CategoryType fromJson(String raw) {
    switch (raw) {
      case 'expense':
        return CategoryType.expense;
      case 'income':
        return CategoryType.income;
      default:
        throw ArgumentError('Unknown category type: $raw');
    }
  }
}
