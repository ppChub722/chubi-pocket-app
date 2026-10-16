/// The data type an [PpForgeInput] edits — layered on the look, never a look of
/// its own (owner 2026-10-12).
enum PpForgeInputType {
  /// Plain text.
  text,

  /// Money: the user's single currency symbol stuck to the number, numeric
  /// keyboard, thousands separators, right-aligned.
  amount,

  /// A number: numeric keyboard, right-aligned.
  number,

  /// A percentage: `%` suffix, 0–100, right-aligned.
  percent,

  /// A reference number (an account no., an id): digits only, unformatted,
  /// left-aligned.
  reference,
}
