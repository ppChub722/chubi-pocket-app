import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../cubit/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _currencies = ['THB', 'USD', 'EUR', 'GBP', 'JPY'];
  static final _usernameRegex = RegExp(r'^[a-z0-9_-]{3,50}$');

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _currency = 'THB';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _displayNameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          currency: _currency,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.authRegisterTitle),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isSubmitting = state is AuthLoading;
          final failure = state is AuthFailure ? state : null;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (failure != null) ...[
                          _ErrorBanner(message: _bannerMessageFor(l, failure)),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextFormField(
                          controller: _usernameCtrl,
                          enabled: !isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.authRegisterUsernameLabel,
                            errorText: _fieldErrorFor(l, 'username', failure),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return l.commonRequired;
                            if (!_usernameRegex.hasMatch(s)) {
                              return l.authRegisterUsernameInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _displayNameCtrl,
                          enabled: !isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.authRegisterDisplayNameLabel,
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return l.commonRequired;
                            if (s.length > 100) {
                              return l.authRegisterDisplayNameTooLong;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _emailCtrl,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.authRegisterEmailLabel,
                            errorText: _fieldErrorFor(l, 'email', failure),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordCtrl,
                          enabled: !isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.authRegisterPasswordLabel,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return l.authRegisterPasswordTooShort;
                            }
                            if (v.length > 128) {
                              return l.authRegisterPasswordTooLong;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirmCtrl,
                          enabled: !isSubmitting,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l.authRegisterConfirmLabel,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return l.authRegisterConfirmMismatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: InputDecoration(
                              labelText: l.authRegisterCurrencyLabel),
                          items: _currencies
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: isSubmitting
                              ? null
                              : (v) => setState(() => _currency = v ?? 'THB'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: isSubmitting ? null : _submit,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(l.authRegisterSubmit),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => context.canPop()
                                  ? context.pop()
                                  : context.go('/auth/login'),
                          child: Text(l.authRegisterGoToLogin),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Top-banner message — used for non-field-specific failures.
  String _bannerMessageFor(AppLocalizations l, AuthFailure failure) {
    final c = failure.error.code;
    if (c == 'USERNAME_EXISTS') return l.authRegisterUsernameTaken;
    if (c == 'EMAIL_EXISTS') return l.authRegisterEmailTaken;
    if (c == 'NETWORK_ERROR' || c == 'NETWORK_TIMEOUT') {
      return l.errorBannerNoConnection;
    }
    if (c == 'VALIDATION_ERROR') return l.authRegisterFixErrors;
    return failure.error.message;
  }

  /// Field-level mapping. `USERNAME_EXISTS`/`EMAIL_EXISTS` show inline next to
  /// the offending field as well as in the top banner — per spec.
  String? _fieldErrorFor(
      AppLocalizations l, String field, AuthFailure? failure) {
    if (failure == null) return null;
    final c = failure.error.code;
    if (field == 'username' && c == 'USERNAME_EXISTS') {
      return l.authRegisterUsernameTakenInline;
    }
    if (field == 'email' && c == 'EMAIL_EXISTS') {
      return l.authRegisterEmailTakenInline;
    }
    final detailMsg = (failure.error.details?[field] as String?);
    return detailMsg;
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
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: () => context.read<AuthCubit>().acknowledgeFailure(),
          ),
        ],
      ),
    );
  }
}
