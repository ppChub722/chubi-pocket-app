import 'tab_nav.dart';

class ShellBackHistory {
  final List<int> _visited = [];

  /// The tab a back is heading to — arriving there records nothing, so back
  /// never builds a "forward" trail.
  int? _backTo;

  void branchChanged(int from, int to) {
    if (from == to) return;
    _visited.remove(to);
    if (_backTo == to) {
      _backTo = null;
      return;
    }
    _visited
      ..remove(from)
      ..add(from);
  }

  /// The branch a back on a tab root goes to, or null when it should ask to
  /// close the app.
  int? backTarget(ShellTab current) {
    final ShellTab? fallback = current.inMore
        ? ShellTab.more
        : current == ShellTab.home
        ? null
        : ShellTab.home;
    final to = _visited.isNotEmpty ? _visited.removeLast() : fallback?.index;
    if (to != null) _backTo = to;
    return to;
  }
}
