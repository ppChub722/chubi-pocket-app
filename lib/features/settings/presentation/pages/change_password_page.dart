import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/data/auth_repository.dart';

/// `/settings/password` — a create-style form page on the detail template
/// (like the other create / edit pages): ONE headless box of three password
/// fields (label above the underline, eye at the right), the helper under the
/// new one, field errors for a wrong current password / a mismatch, a banner
/// for a failed call. Edit mode from the start: ✕ + ยกเลิก · บันทึก, the
/// saving overlay and the discard guard come from [EditModeMixin].
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

enum _Field { current, next, confirm }

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with EditModeMixin<ChangePasswordPage, _PasswordDraft> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _currentFieldError;

  @override
  void initState() {
    super.initState();
    initDraft(const _PasswordDraft(), editing: true);
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// A form: ยกเลิก / ✕ leave the page (no view mode to fall back to).
  @override
  bool get leaveOnCancel => true;

  @override
  void onDraftRestored() {
    _sync(_currentCtrl, working.current);
    _sync(_newCtrl, working.next);
    _sync(_confirmCtrl, working.confirm);
  }

  void _sync(TextEditingController c, String v) {
    if (c.text != v) c.text = v;
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.current => working.copyWith(current: v),
    _Field.next => working.copyWith(next: v),
    _Field.confirm => working.copyWith(confirm: v),
  });

  Future<void> _submit() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context)!;
    final repo = context.read<AuthRepository>();
    final w = working;
    FocusScope.of(context).unfocus();
    setSaving(true);
    setState(() => _currentFieldError = null);
    try {
      await repo.changePassword(
        currentPassword: w.current,
        newPassword: w.next,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.changePasswordSnackSuccess,
        tone: Tone.success,
      );
      commitSaved(w);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      setState(() {
        if (e.code == 'WRONG_PASSWORD' || e.statusCode == 401) {
          _currentFieldError = l.changePasswordCurrentWrong;
        }
      });
      // Anything but a wrong current password: the app's error snackbar.
      if (_currentFieldError == null) {
        final m = pageMessenger;
        m != null ? showErrorSnackBarOn(m, e) : showErrorSnackBar(context, e);
      }
      if (_currentFieldError != null) _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final editing = isEditing;
    return editScope(
      Scaffold(
        // A form = edit mode: ✕ + ยกเลิก · บันทึก, no nav.
        appBar: AppTopBar(
          title: l.changePasswordTitle,
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: the floating bar's height is only visible inside the body.
          child: Builder(
            builder: (context) => DetailPageBody(
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              sections: [
                (first) => SectionCard(
                  first: first,
                  fields: true,
                  dividers: false,
                  children: [
                    _passwordField(
                      controller: _currentCtrl,
                      label: l.changePasswordCurrentLabel,
                      autofocus: true,
                      errorText: _currentFieldError,
                      onChanged: (v) {
                        if (_currentFieldError != null) {
                          setState(() => _currentFieldError = null);
                        }
                        _onText(_Field.current, v);
                      },
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.commonRequired : null,
                    ),
                    _passwordField(
                      controller: _newCtrl,
                      label: l.changePasswordNewLabel,
                      helper: l.changePasswordNewHelper,
                      onChanged: (v) => _onText(_Field.next, v),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return l.authRegisterPasswordTooShort;
                        }
                        if (v.length > 128) {
                          return l.authRegisterPasswordTooLong;
                        }
                        if (v == _currentCtrl.text) {
                          return l.changePasswordNewMustDiffer;
                        }
                        return null;
                      },
                    ),
                    _passwordField(
                      controller: _confirmCtrl,
                      label: l.changePasswordConfirmLabel,
                      onChanged: (v) => _onText(_Field.confirm, v),
                      onSubmitted: (_) => _submit(),
                      validator: (v) => v != _newCtrl.text
                          ? l.changePasswordConfirmMismatch
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: editActionBar(onSave: _submit),
      ),
    );
  }

  /// The form-field look: label above the underline, the eye at the right.
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    required FormFieldValidator<String> validator,
    String? helper,
    String? errorText,
    bool autofocus = false,
    ValueChanged<String>? onSubmitted,
  }) => AppInput.card(
    controller: controller,
    label: label,
    labelPlacement: AppInputLabelPlacement.above,
    helper: helper,
    obscurable: true,
    autofocus: autofocus,
    errorText: errorText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    validator: validator,
  );
}

class _PasswordDraft extends Equatable {
  const _PasswordDraft({this.current = '', this.next = '', this.confirm = ''});

  final String current;
  final String next;
  final String confirm;

  _PasswordDraft copyWith({String? current, String? next, String? confirm}) =>
      _PasswordDraft(
        current: current ?? this.current,
        next: next ?? this.next,
        confirm: confirm ?? this.confirm,
      );

  @override
  List<Object?> get props => [current, next, confirm];
}
