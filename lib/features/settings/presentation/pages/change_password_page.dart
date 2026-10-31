import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/presentation/refresh_me.dart';
import 'settings_money_page.dart' show signedInUser;

/// เปลี่ยนรหัสผ่าน; for an account with no password yet (made through an
/// outside app, 0.4.2 1b-2) ตั้งรหัสผ่าน: the new password only.
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
  String? _newFieldError;

  /// No password yet: set one (no current-password field).
  late final bool _setMode =
      !(signedInUser(context.read<AuthCubit>().state)?.hasPassword ?? true);

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
    setState(() => _currentFieldError = _newFieldError = null);
    try {
      await repo.changePassword(
        currentPassword: _setMode ? null : w.current,
        newPassword: w.next,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        _setMode
            ? l.profileSetPasswordSnackSuccess
            : l.changePasswordSnackSuccess,
        tone: Tone.success,
      );
      // has_password flips: the profile row says เปลี่ยนรหัสผ่าน again.
      if (_setMode) await refreshMe(context);
      if (!mounted) return;
      commitSaved(w);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      setState(() {
        if (!_setMode && (e.code == 'WRONG_PASSWORD' || e.statusCode == 401)) {
          _currentFieldError = l.changePasswordCurrentWrong;
        } else if (!_setMode) {
          _currentFieldError = fieldErrorText(l, e, 'current_password');
        }
        _newFieldError = fieldErrorText(l, e, 'new_password');
      });
      if (_currentFieldError == null && _newFieldError == null) {
        final m = pageMessenger;
        m != null ? showErrorSnackBarOn(m, e) : showErrorSnackBar(context, e);
      } else {
        _formKey.currentState?.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final editing = isEditing;
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: _setMode ? l.profileSetPassword : l.changePasswordTitle,
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          child: Builder(
            builder: (context) => DetailPageBody(
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              sections: [
                (first) => SectionCard(
                  first: first,
                  fields: true,
                  dividers: false,
                  children: [
                    if (!_setMode)
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
                      autofocus: _setMode,
                      errorText: _newFieldError,
                      onChanged: (v) {
                        if (_newFieldError != null) {
                          setState(() => _newFieldError = null);
                        }
                        _onText(_Field.next, v);
                      },
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return l.authRegisterPasswordTooShort;
                        }
                        if (v.length > 128) {
                          return l.authRegisterPasswordTooLong;
                        }
                        if (!_setMode && v == _currentCtrl.text) {
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
