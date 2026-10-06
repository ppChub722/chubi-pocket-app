import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
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

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.changePasswordSnackSuccess)),
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
    return Scaffold(
      // A form = edit mode (§1.4): ✕ + ยกเลิก · บันทึก, no nav.
      appBar: AppTopBar(
        title: l.changePasswordTitle,
        showBack: true,
        editing: true,
        onBack: () => context.pop(),
      ),
      bottomNavigationBar: ModeActionBar(
        canUndo: false,
        canSave: !_submitting,
        saving: _submitting,
        cancelLabel: l.commonCancel,
        saveLabel: l.changePasswordSubmit,
        undoTooltip: l.commonUndo,
        onCancel: () => context.pop(),
        onUndo: () {},
        onSave: _submit,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      _ErrorBanner(message: _bannerMessageFor(l, _error!)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _currentCtrl,
                      enabled: !_submitting,
                      obscureText: _obscureCurrent,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l.changePasswordCurrentLabel,
                        errorText: _currentFieldError,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.commonRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _newCtrl,
                      enabled: !_submitting,
                      obscureText: _obscureNew,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l.changePasswordNewLabel,
                        helperText: l.changePasswordNewHelper,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
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
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmCtrl,
                      enabled: !_submitting,
                      obscureText: _obscureConfirm,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l.changePasswordConfirmLabel,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _newCtrl.text) {
                          return l.changePasswordConfirmMismatch;
                        }
                        return null;
                      },
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
