/// Categories are scoped by direction. The third "transfer" direction in
/// the spec is handled by system categories (`Transfer In` / `Transfer
/// Out`) and is intentionally not exposed as a user-facing type — see
/// [`design/spec/05-categories-tags.md §4.2`](../../../../../chubi-pocket-docs/design/spec/05-categories-tags.md).
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
