import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../cubit/auth_cubit.dart';

/// Login form. Generic 401 message on bad credentials (no field-level reveal —
/// security pattern). On success, [AuthCubit] flips to [AuthAuthenticated] and
/// the router redirects to `/`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          identifier: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.authLoginTitle)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (failure != null)
                          _ErrorBanner(message: _messageFor(l, failure)),
                        if (failure != null)
                          const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _identifierCtrl,
                          enabled: !isSubmitting,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.authLoginIdentifierLabel,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? l.commonRequired
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordCtrl,
                          enabled: !isSubmitting,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l.authLoginPasswordLabel,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? l.commonRequired
                                  : null,
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
                              : Text(l.authLoginSubmit),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => context.push('/auth/register'),
                          child: Text(l.authLoginGoToRegister),
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

  /// Map backend `code` → user-facing string. Phase 0 covers the common cases;
  /// the Phase 1+ "error taxonomy mapping" doc (per
  /// `design/frontend/app/overview.md §11`) will centralise this.
  String _messageFor(AppLocalizations l, AuthFailure failure) {
    final c = failure.error.code;
    if (c == 'INVALID_CREDENTIALS' || failure.error.statusCode == 401) {
      return l.authLoginInvalidCredentials;
    }
    if (c == 'NETWORK_ERROR' || c == 'NETWORK_TIMEOUT') {
      return l.errorBannerNoConnection;
    }
    return failure.error.message;
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
