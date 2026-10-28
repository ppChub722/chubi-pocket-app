import 'nav_layout.dart';
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
  /// close the app. Without history a page only เพิ่มเติม opens goes to
  /// เพิ่มเติม, any other tab to the bottom bar's first item.
  int? peekBackTarget(ShellTab current, [NavLayout? layout]) {
    if (_visited.isNotEmpty) return _visited.last;
    final nav = layout ?? NavLayout.defaults;
    final first = nav.bottomItems.firstOrNull;
    if (nav.isMoreOnly(current)) return ShellTab.more.index;
    return current == first ? null : first?.index;
  }

  /// [peekBackTarget], taken: the back is under way.
  int? backTarget(ShellTab current, [NavLayout? layout]) {
    final to = peekBackTarget(current, layout);
    if (_visited.isNotEmpty) _visited.removeLast();
    if (to != null) _backTo = to;
    return to;
  }
}
