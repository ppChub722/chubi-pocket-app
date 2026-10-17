import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Login form. Generic 401 message on bad credentials (no field-level reveal —
/// security pattern). On success, [AuthCubit] flips to [AuthAuthenticated] and
/// the router redirects to `/`.
///
/// Built from the kit only: the page is `AuthPageBody` + framed `AppInput`s +
/// buttons; this file holds state, validation, the API call and navigation.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  /// Both auth pages read the one [AuthCubit]: a failed login must not show
  /// on the register page, nor a failed sign-up here on the way back.
  Future<void> _openRegister() async {
    // The error snackbar lives app-wide: it must not follow to register.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final auth = context.read<AuthCubit>()..acknowledgeFailure();
    await context.push('/auth/register');
    if (mounted) auth.acknowledgeFailure();
  }

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
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (_, s) => s is AuthFailure,
        listener: (context, s) {
          if (ModalRoute.of(context)?.isCurrent ?? true) {
            showErrorSnackBar(context, (s as AuthFailure).error);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isSubmitting = state is AuthLoading;
            return AuthPageBody(
              formKey: _formKey,
              brand: const AuthBrandHeader(),
              groups: [
                AppInput(
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.commonRequired : null,
                ),
                AppInput(
                  controller: _passwordCtrl,
                  enabled: !isSubmitting,
                  label: l.authLoginPasswordLabel,
                  prefixIcon: AppIcons.lock,
                  obscurable: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l.commonRequired : null,
                ),
              ],
              submit: AppButton(
                label: l.authLoginSubmit,
                submits: true,
                onPressed: isSubmitting ? null : _submit,
                loading: isSubmitting,
                size: AppButtonSize.large,
                expand: true,
              ),
              // TODO(google-sign-in): wire once POST /auth/google exists
              // (contract §12).
              alternatives: const [AuthOrDivider(), GoogleSignInButton()],
              switchLink: AppButton(
                label: l.authLoginGoToRegister,
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: isSubmitting ? null : _openRegister,
              ),
              footer: const AuthPrefsBar(),
            );
          },
        ),
      ),
    );
  }
}
