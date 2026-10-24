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
import 'edit_draft.dart';
import 'edit_mode_scope.dart';

mixin EditModeMixin<W extends StatefulWidget, D extends Object> on State<W> {
  bool _editing = false;
  bool _askingToDiscard = false;
  bool _saving = false;
  late EditDraft<D> _draft;
  Timer? _debounce;

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// This page's own snackbar messenger ([editScope] installs it): snackbars
  /// shown through it float above the page's action bar instead of over it.
  ScaffoldMessengerState? get pageMessenger => _messengerKey.currentState;

  /// The nav hides while this page is on screen in edit mode (the action bar
  /// takes its place); worked out from state, never remembered.
  late final ShellNavClaim _shellNav = ShellNavClaim(() => mounted && _editing);

  bool get isEditing => _editing;

  bool get canEdit => true;
  bool get isSaving => _saving;
  D get original => _draft.original;
  D get working => _draft.working;
  bool get isDirty => _draft.isDirty;
  bool get canUndo => _draft.canUndo;

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
    _draft = EditDraft(draft);
    _editing = editing;
  }

  void resetDraft(D draft) {
    if (_editing) return;
    setState(() => _draft.reset(draft));
    onDraftRestored();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellNav.attach(context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _shellNav.dispose();
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
      _draft.discard();
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
    if (_draft.needsDiscardPrompt) {
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
    _debounce?.cancel();
    _debounce = null;
    if (!_draft.change(next)) return;
    setState(() => _editing = true);
    HapticFeedback.selectionClick();
  }

  void applyTextChange(Object field, D next) {
    setState(() => _draft.textChange(field, next));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(commitTextSession);
    });
  }

  void commitTextSession() {
    _debounce?.cancel();
    _debounce = null;
    _draft.commitSession();
  }

  void undo() {
    HapticFeedback.selectionClick();
    if (!_draft.canUndo) return;
    if (_draft.hasOpenSession) {
      _debounce?.cancel();
      _debounce = null;
    }
    setState(_draft.undo);
    onDraftRestored();
    if (_draft.fullyUndone) cancelEdit();
  }

  void setSaving(bool value) {
    if (_saving == value) return;
    setState(() => _saving = value);
  }

  void commitSaved(D saved) {
    _debounce?.cancel();
    _debounce = null;
    setState(() {
      _draft.commitSaved(saved);
      _editing = false;
      _saving = false;
    });
    onDraftRestored();
  }

  void rebaseEdit({required D original, required D working}) {
    _debounce?.cancel();
    _debounce = null;
    setState(() => _draft.rebase(original: original, working: working));
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

  void _syncShellChrome() => _shellNav.changed();
}
