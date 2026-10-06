import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

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
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isSubmitting = state is AuthLoading;
          final failure = state is AuthFailure ? state : null;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthBrandHeader(),
                          const SizedBox(height: AppSpacing.xl),
                          if (failure != null) ...[
                            MessageBanner(
                              message: _messageFor(l, failure),
                              onClose: () => context
                                  .read<AuthCubit>()
                                  .acknowledgeFailure(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          AppTextField(
                            controller: _identifierCtrl,
                            enabled: !isSubmitting,
                            label: l.authLoginIdentifierLabel,
                            prefixIcon: AppIcons.profile,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l.commonRequired
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _passwordCtrl,
                            enabled: !isSubmitting,
                            label: l.authLoginPasswordLabel,
                            prefixIcon: AppIcons.lock,
                            obscurable: true,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l.commonRequired
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: l.authLoginSubmit,
                            onPressed: isSubmitting ? null : _submit,
                            loading: isSubmitting,
                            size: AppButtonSize.large,
                            expand: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const AuthOrDivider(),
                          const SizedBox(height: AppSpacing.lg),
                          // TODO(google-sign-in): wire once POST /auth/google
                          // exists (contract §12).
                          const GoogleSignInButton(),
                          const SizedBox(height: AppSpacing.lg),
                          TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => context.push('/auth/register'),
                            child: Text(l.authLoginGoToRegister),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const AuthPrefsBar(),
                        ],
                      ),
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
