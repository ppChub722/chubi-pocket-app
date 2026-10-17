import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/shell_chrome.dart';
import '../../app/shell/tab_nav.dart';
import '../atoms/ui_config.dart';
import '../molecules/confirm_dialog.dart';
import '../organisms/saving_overlay.dart';
import '../molecules/mode_action_bar.dart';
import 'edit_mode_scope.dart';

mixin EditModeMixin<W extends StatefulWidget, D extends Object> on State<W> {
  bool _editing = false;
  bool _askingToDiscard = false;
  bool _saving = false;
  late D _original;
  late D _working;
  final List<D> _undoStack = [];

  D? _sessionStart;
  Object? _sessionField;
  Timer? _debounce;

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// This page's own snackbar messenger ([editScope] installs it): snackbars
  /// shown through it float above the page's action bar instead of over it.
  ScaffoldMessengerState? get pageMessenger => _messengerKey.currentState;

  ShellChromeController? _shellChrome;
  bool? _chromeHiddenFor;

  bool get isEditing => _editing;

  bool get canEdit => true;
  bool get isSaving => _saving;
  D get original => _original;
  D get working => _working;
  bool get isDirty => _working != _original;
  bool get canUndo => _sessionStart != null || _undoStack.isNotEmpty;

  void onDraftRestored() {}

  bool get leaveOnCancel => false;

  void leavePage() {
    if (context.canPop()) {
      context.pop();
    } else {
      ShellBackScope.maybeOf(context)?.call();
    }
  }

  void initDraft(D draft, {bool editing = false}) {
    _original = draft;
    _working = draft;
    _editing = editing;
  }

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
    // Always release: this page can never keep the shell hidden past its life.
    _shellChrome?.show(owner: this);
    super.dispose();
  }

  void enterEdit({FocusNode? focus, VoidCallback? then}) {
    if (!canEdit) return;
    if (!_editing) {
      HapticFeedback.lightImpact();
      setState(() => _editing = true);
    }
    if (focus != null || then != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        focus?.requestFocus();
        then?.call();
      });
    }
  }

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

  Future<void> handleBack() async {
    if (_saving || _askingToDiscard) return;
    if (!_editing) {
      leavePage();
      return;
    }
    if (isDirty || _sessionStart != null) {
      final l = UiConfig.stringsOf(context);
      _askingToDiscard = true;
      final ok = await showConfirmDialog(
        context,
        title: l.discardTitle,
        message: l.discardMessage,
        cancelLabel: l.keepEditing,
        confirmLabel: l.discardConfirm,
        destructive: true,
      );
      _askingToDiscard = false;
      if (!ok || !mounted || !_editing) return;
    }
    cancelEdit();
  }

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

  void setSaving(bool value) {
    if (_saving == value) return;
    setState(() => _saving = value);
  }

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

  Widget editScope(Widget child) {
    _syncShellChrome();
    return PopScope(
      canPop: !_editing && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBack();
      },
      // A save / delete in flight dims the page and blocks input
      // ([SavingOverlay]) — the user never edits under a running call.
      child: EditModeScope(
        busy: _editing || _saving,
        child: ScaffoldMessenger(
          key: _messengerKey,
          child: SavingOverlay(saving: _saving, child: child),
        ),
      ),
    );
  }

  Widget editActionBar({required VoidCallback onSave, bool canSave = true}) {
    final l = UiConfig.stringsOf(context);
    return ModeActionBar(
      canUndo: canUndo && !_saving,
      canSave: canSave && isDirty && !_saving,
      saving: _saving,
      cancelLabel: l.cancel,
      saveLabel: l.save,
      undoTooltip: l.undo,
      onCancel: cancelEdit,
      onUndo: undo,
      onSave: onSave,
    );
  }

  void _syncShellChrome() {
    if (_chromeHiddenFor == _editing) return;
    _chromeHiddenFor = _editing;
    final route = ModalRoute.of(context);
    // Deferred: toggling notifies the shell, which can't rebuild mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_editing) {
        _shellChrome?.show(owner: this);
        return;
      }
      whenRouteSettled(route, () {
        if (mounted && _editing) _shellChrome?.hide(owner: this);
      });
    });
  }
}
