/// The draft, its undo steps and its dirty rules, apart from the widget.
class EditDraft<D extends Object> {
  EditDraft(D draft) : original = draft, working = draft;

  D original;
  D working;
  final List<D> _undoStack = [];
  D? _sessionStart;
  Object? _sessionField;

  bool get isDirty => working != original;
  bool get hasOpenSession => _sessionStart != null;
  bool get canUndo => _sessionStart != null || _undoStack.isNotEmpty;
  bool get needsDiscardPrompt => isDirty || _sessionStart != null;
  bool get fullyUndone => _undoStack.isEmpty && !isDirty;

  void reset(D draft) {
    original = draft;
    working = draft;
  }

  /// False when [next] equals the working draft: nothing to record.
  bool change(D next) {
    commitSession();
    if (next == working) return false;
    _undoStack.add(working);
    working = next;
    return true;
  }

  void textChange(Object field, D next) {
    if (_sessionStart == null) {
      _sessionStart = working;
      _sessionField = field;
    } else if (_sessionField != field) {
      commitSession();
      _sessionStart = working;
      _sessionField = field;
    }
    working = next;
  }

  void commitSession() {
    final start = _sessionStart;
    _sessionStart = null;
    _sessionField = null;
    if (start != null && start != working) _undoStack.add(start);
  }

  /// One undo step: the open typing burst, else the last recorded change.
  void undo() {
    final start = _sessionStart;
    if (start != null) {
      _sessionStart = null;
      _sessionField = null;
      working = start;
    } else if (_undoStack.isNotEmpty) {
      working = _undoStack.removeLast();
    }
  }

  void discard() {
    working = original;
    _clearHistory();
  }

  void commitSaved(D saved) {
    reset(saved);
    _clearHistory();
  }

  void rebase({required D original, required D working}) {
    this.original = original;
    this.working = working;
    _clearHistory();
  }

  void _clearHistory() {
    _undoStack.clear();
    _sessionStart = null;
    _sessionField = null;
  }
}
