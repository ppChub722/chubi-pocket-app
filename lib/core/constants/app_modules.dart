/// Which optional modules are switched on. Hardcoded for now (owner
/// 2026-10-10): flip a flag here and ship a patch; later these come from
/// the API.
///
/// A module that's off disappears everywhere the shell lists it — its
/// เพิ่มเติม card, its top-bar chip and its place in the swipe rows
/// (`ShellRow`); its neighbours close the gap. The four nav tabs and
/// settings are core: always on.
abstract final class AppModules {
  // ── Top bar ──────────────────────────────────────────────────────────
  static const pending = true;
  static const notifications = true;

  // ── เพิ่มเติม: คลังข้อมูล ─────────────────────────────────────────────
  static const categories = true;
  static const tags = true;

  // ── เพิ่มเติม: คนและเงินร่วม ──────────────────────────────────────────
  static const contacts = true;
  static const projects = true;
  static const debts = true;

  // ── เพิ่มเติม: วางแผน ─────────────────────────────────────────────────
  static const budgets = true;
  static const savingGoals = true;
  static const scheduled = true;
}
