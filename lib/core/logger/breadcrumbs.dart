/// The last steps the user took (pages, button taps, writes, failed calls),
/// kept in memory so an error can say what led to it. Release builds log
/// warn and up only, so without these a crash report shows the error but
/// not the path to it. No amounts or typed text: paths, labels, statuses.
class Breadcrumbs {
  Breadcrumbs._();

  static final Breadcrumbs instance = Breadcrumbs._();

  static const capacity = 50;

  final List<String> _steps = [];

  void add(String step) {
    final line = '${_time(DateTime.now())} $step';
    if (_steps.isNotEmpty && _steps.last.substring(9) == step) return;
    _steps.add(line);
    if (_steps.length > capacity) _steps.removeAt(0);
  }

  void page(String path) => add('page $path');

  void tap(String label) => add('tap "$label"');

  List<String> get steps => List.unmodifiable(_steps);

  String get text => _steps.join('\n');

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}
