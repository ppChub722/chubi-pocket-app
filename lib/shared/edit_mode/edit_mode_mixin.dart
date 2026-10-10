import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/shell_chrome.dart';
import '../../app/shell/tab_nav.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/feedback/confirm_dialog.dart';
import '../widgets/mode_action_bar.dart';

/// The app's in-place edit-mode lifecycle, shared by every detail page
/// (category, tag, contact, account, project, …) so they all behave the
/// same:
///
/// * view ⇄ edit, with the shell's nav + FAB hidden while editing
///   ([ShellChrome]) and a [ModeActionBar] (ยกเลิก · ↶ · บันทึก) instead;
/// * an immutable draft [D] (use Equatable) — `original` vs `working`
///   gives [isDirty] for free;
/// * undo — every discrete change is one step; typing bursts in one field
///   collapse into one step (500 ms debounce, or switching field);
///   undoing back to the original leaves edit mode;
/// * back (system gesture / the top bar's ✕) while editing asks before
///   dropping unsaved changes ([handleBack]); with nothing changed it just
///   returns to view mode — or leaves, for create. The ยกเลิก button is
///   direct.
///
/// Usage:
/// ```dart
/// class _FooPageState extends State<FooPage>
///     with EditModeMixin<FooPage, FooDraft> {
///   @override
///   void initState() { super.initState(); initDraft(FooDraft.from(foo)); }
///
///   @override
///   void onDraftRestored() => _nameCtrl.text = working.name; // undo/cancel
///
///   Widget build(context) => editScope(Scaffold(
///     appBar: AppTopBar(editing: isEditing, onBack: handleBack, …),
///     bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
///   ));
///
///   Future<void> _save() async {
///     commitTextSession();
///     setSaving(true);
///     try { … await repo.update(working); commitSaved(working); }
///     finally { if (mounted) setSaving(false); }
///   }
/// }
/// ```
mixin EditModeMixin<W extends StatefulWidget, D extends Object> on State<W> {
  bool _editing = false;
  bool _askingToDiscard = false;
  bool _saving = false;
  late D _original;
  late D _working;
  final List<D> _undoStack = [];

  // Open typing burst: state when it started + which field it belongs to.
  D? _sessionStart;
  Object? _sessionField;
  Timer? _debounce;

  ShellChromeController? _shellChrome;
  bool? _chromeHiddenFor;

  bool get isEditing => _editing;
  bool get isSaving => _saving;
  D get original => _original;
  D get working => _working;
  bool get isDirty => _working != _original;
  bool get canUndo => _sessionStart != null || _undoStack.isNotEmpty;

  // ── Hooks ───────────────────────────────────────────────────────────

  /// `working` jumped (undo / cancel) — push it back into text controllers.
  void onDraftRestored() {}

  /// Create flows: there's no view mode, so Cancel / back leave the page.
  bool get leaveOnCancel => false;

  /// Leaving the page (create cancel, back in view mode). A plain pop —
  /// `maybePop` would come back through this page's own PopScope. A page
  /// opened alone in its tab has nothing to pop: the shell's back takes
  /// over (previous tab, the เพิ่มเติม hub, or the dashboard).
  void leavePage() {
    if (context.canPop()) {
      context.pop();
    } else {
      ShellBackScope.maybeOf(context)?.call();
    }
  }

  // ── Setup ───────────────────────────────────────────────────────────

  /// Call from `initState`. [editing] = open straight in edit mode (create).
  void initDraft(D draft, {bool editing = false}) {
    _original = draft;
    _working = draft;
    _editing = editing;
  }

  /// The persisted record changed underneath (e.g. a cubit refresh) while
  /// not editing — rebase without touching an in-progress edit.
  void resetDraft(D draft) {
    if (_editing) return;
    setState(() {
      _original = draft;
      _working = draft;
    });
    onDraftRestored();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final element = context
        .getElementForInheritedWidgetOfExactType<ShellChrome>();
    _shellChrome = (element?.widget as ShellChrome?)?.notifier;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_chromeHiddenFor ?? false) _shellChrome?.show();
    super.dispose();
  }

  // ── Mode ────────────────────────────────────────────────────────────

  /// Enter edit mode; optionally focus a field once it's editable.
  void enterEdit({FocusNode? focus}) {
    if (!_editing) {
      HapticFeedback.lightImpact();
      setState(() => _editing = true);
    }
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
    }
  }

  /// Revert everything and return to view mode (or leave, for create).
  void cancelEdit() {
    if (leaveOnCancel) {
      leavePage();
      return;
    }
    _debounce?.cancel();
    _debounce = null;
    FocusScope.of(context).unfocus();
    setState(() {
      _working = _original;
      _undoStack.clear();
      _sessionStart = null;
      _sessionField = null;
      _editing = false;
      _saving = false;
    });
    onDraftRestored();
  }

  /// Top-bar ← / ✕ and system back. While editing with unsaved changes it
  /// asks first ("ยกเลิกการแก้ไข?" [แก้ต่อ] [ยกเลิกการแก้ไข]); with none it
  /// just leaves edit mode (owner 2026-10-10, reversing "back = cancel, no
  /// prompt"). The ยกเลิก button itself stays direct ([cancelEdit]).
  Future<void> handleBack() async {
    if (_saving || _askingToDiscard) return;
    if (!_editing) {
      leavePage();
      return;
    }
    if (isDirty || _sessionStart != null) {
      final l = AppLocalizations.of(context)!;
      _askingToDiscard = true;
      final ok = await showConfirmDialog(
        context,
        title: l.editDiscardTitle,
        message: l.editDiscardMessage,
        cancelLabel: l.editKeepEditing,
        confirmLabel: l.editDiscardConfirm,
        destructive: true,
      );
      _askingToDiscard = false;
      if (!ok || !mounted || !_editing) return;
    }
    cancelEdit();
  }

  // ── Changes ─────────────────────────────────────────────────────────

  /// One discrete change (switch, chip, picker, icon) = one undo step.
  /// Auto-enters edit mode, so view-mode controls can stay live.
  void applyChange(D next) {
    commitTextSession();
    if (next == _working) return;
    setState(() {
      _editing = true;
      _undoStack.add(_working);
      _working = next;
    });
    HapticFeedback.selectionClick();
  }

  /// A keystroke in text field [field] (any stable key, e.g. an enum).
  /// The controller already shows the text, so no [onDraftRestored].
  void applyTextChange(Object field, D next) {
    if (_sessionStart == null) {
      _sessionStart = _working;
      _sessionField = field;
    } else if (_sessionField != field) {
      commitTextSession();
      _sessionStart = _working;
      _sessionField = field;
    }
    setState(() => _working = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(commitTextSession);
    });
  }

  /// Close the open typing burst into a single undo step. Call before save.
  void commitTextSession() {
    _debounce?.cancel();
    _debounce = null;
    final start = _sessionStart;
    _sessionStart = null;
    _sessionField = null;
    if (start != null && start != _working) _undoStack.add(start);
  }

  void undo() {
    HapticFeedback.selectionClick();
    if (_sessionStart != null) {
      final start = _sessionStart as D;
      _debounce?.cancel();
      _debounce = null;
      _sessionStart = null;
      _sessionField = null;
      setState(() => _working = start);
    } else if (_undoStack.isNotEmpty) {
      setState(() => _working = _undoStack.removeLast());
    } else {
      return;
    }
    onDraftRestored();
    if (_undoStack.isEmpty && !isDirty) cancelEdit();
  }

  // ── Save ────────────────────────────────────────────────────────────

  void setSaving(bool value) {
    if (_saving == value) return;
    setState(() => _saving = value);
  }

  /// Saved successfully — [saved] (usually `working`, or what the server
  /// returned) becomes the new baseline and edit mode closes.
  void commitSaved(D saved) {
    _debounce?.cancel();
    _debounce = null;
    setState(() {
      _original = saved;
      _working = saved;
      _undoStack.clear();
      _sessionStart = null;
      _sessionField = null;
      _editing = false;
      _saving = false;
    });
    onDraftRestored();
  }

  /// A multi-step save failed part-way: [original] becomes what the server
  /// now has and [working] the edit still pending on top of it. Edit mode
  /// stays; the undo history goes (its snapshots predate what was saved, so
  /// restoring one would redo it).
  void rebaseEdit({required D original, required D working}) {
    _debounce?.cancel();
    _debounce = null;
    setState(() {
      _original = original;
      _working = working;
      _undoStack.clear();
      _sessionStart = null;
      _sessionField = null;
    });
    onDraftRestored();
  }

  // ── Chrome ──────────────────────────────────────────────────────────

  /// Wrap the page's Scaffold: routes back through [handleBack] and keeps
  /// the shell's nav + FAB hidden while editing.
  Widget editScope(Widget child) {
    _syncShellChrome();
    return PopScope(
      canPop: !_editing && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBack();
      },
      child: child,
    );
  }

  /// The standard ยกเลิก · ↶ · บันทึก bar for `bottomNavigationBar`.
  Widget editActionBar({required VoidCallback onSave, bool canSave = true}) {
    final l = AppLocalizations.of(context)!;
    return ModeActionBar(
      canUndo: canUndo && !_saving,
      canSave: canSave && isDirty && !_saving,
      saving: _saving,
      cancelLabel: l.commonCancel,
      saveLabel: l.commonSave,
      undoTooltip: l.commonUndo,
      onCancel: cancelEdit,
      onUndo: undo,
      onSave: onSave,
    );
  }

  void _syncShellChrome() {
    if (_chromeHiddenFor == _editing) return;
    _chromeHiddenFor = _editing;
    // Called from build, so the route lookup is safe here.
    final route = ModalRoute.of(context);
    // Deferred: toggling notifies the shell, which can't rebuild mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_editing) {
        _shellChrome?.show();
        return;
      }
      // A page that opens in edit mode (create) hides the nav only once it
      // has slid in — see [whenRouteSettled].
      whenRouteSettled(route, () {
        if (mounted && _editing) _shellChrome?.hide();
      });
    });
  }
}
