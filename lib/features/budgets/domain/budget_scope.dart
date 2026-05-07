/// Budget scope (spec §08/§4.2).
///
/// `user` — personal limit independent of any project.
/// `project` — limit within a project; only project owner can mutate.
enum BudgetScope {
  user,
  project;

  String toJson() {
    switch (this) {
      case BudgetScope.user:
        return 'user';
      case BudgetScope.project:
        return 'project';
    }
  }

  static BudgetScope fromJson(String raw) {
    switch (raw) {
      case 'user':
        return BudgetScope.user;
      case 'project':
        return BudgetScope.project;
      default:
        throw ArgumentError('Unknown budget scope: $raw');
    }
  }
}
