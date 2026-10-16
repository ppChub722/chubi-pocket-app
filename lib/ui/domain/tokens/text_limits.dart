/// Max lengths of the name / description / note fields — the same on every
/// "thing" (wallet, category, tag, contact, budget, saving goal, project,
/// scheduled) and record (transaction, pending draft, project row, debt).
/// They match the BE validators (characters, not bytes; migration 51).
abstract final class TextLimits {
  static const name = 100;

  /// Tags are short chips.
  static const tagName = 50;

  static const description = 200;
  static const note = 500;

  /// A contact's email / phone.
  static const email = 255;
  static const phone = 50;
}
