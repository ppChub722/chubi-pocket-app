import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/data/auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _submitting = false;
  ApiException? _error;
  String? _currentFieldError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// ยกเลิก and ✕ alike: leave the form (nothing while submitting).
  void _cancel() {
    if (!_submitting) context.pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _error = null;
      _currentFieldError = null;
    });
    try {
      await context.read<AuthRepository>().changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.changePasswordSnackSuccess,
        tone: Tone.success,
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'WRONG_PASSWORD' || e.statusCode == 401) {
          _currentFieldError = l.changePasswordCurrentWrong;
        } else {
          _error = e;
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SavingOverlay(
      saving: _submitting,
      child: Scaffold(
        // A form = edit mode (§1.4): ✕ + ยกเลิก · บันทึก, no nav.
        appBar: AppTopBar(
          title: l.changePasswordTitle,
          showBack: true,
          editing: true,
          // ✕ = ยกเลิก (owner 2026-10-10).
          onBack: _cancel,
        ),
        // No undo on a password form — the bar hides it (onUndo null).
        bottomNavigationBar: ModeActionBar(
          canSave: !_submitting,
          saving: _submitting,
          cancelLabel: l.commonCancel,
          saveLabel: l.changePasswordSubmit,
          onCancel: _cancel,
          onSave: _submit,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          // Builder: the floating bar's height is only visible inside the body.
          child: Builder(
            builder: (context) => DetailPageBody(
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              hero: _error == null
                  ? null
                  : AppMessage(
                      tone: Tone.danger,
                      message: _bannerMessageFor(l, _error!),
                    ),
              sections: [
                (first) => SectionCard(
                  first: first,
                  fields: true,
                  dividers: false,
                  children: [
                    AppInput(
                      controller: _currentCtrl,
                      enabled: !_submitting,
                      obscurable: true,
                      autofillHints: const [AutofillHints.password],
                      label: l.changePasswordCurrentLabel,
                      errorText: _currentFieldError,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.commonRequired : null,
                    ),
                    AppInput(
                      controller: _newCtrl,
                      enabled: !_submitting,
                      obscurable: true,
                      autofillHints: const [AutofillHints.newPassword],
                      label: l.changePasswordNewLabel,
                      helper: l.changePasswordNewHelper,
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
                    AppInput(
                      controller: _confirmCtrl,
                      enabled: !_submitting,
                      obscurable: true,
                      onSubmitted: (_) => _submit(),
                      label: l.changePasswordConfirmLabel,
                      validator: (v) {
                        if (v != _newCtrl.text) {
                          return l.changePasswordConfirmMismatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _bannerMessageFor(AppLocalizations l, ApiException e) {
    if (e.code == 'NETWORK_ERROR' || e.code == 'NETWORK_TIMEOUT') {
      return l.errorBannerNoConnectionShort;
    }
    return e.message;
  }
}
