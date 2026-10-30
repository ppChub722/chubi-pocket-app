import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  /// Both auth pages read the one [AuthCubit]: a failed login must not show on
  /// the register page, nor a failed sign-up here on the way back.
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
    // No inline errors: an empty field gets the same toast as a wrong login.
    if (_identifierCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.authLoginInvalidCredentials,
        tone: Tone.danger,
      );
      return;
    }
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
              alternatives: const [AuthOrDivider(), AuthSocialCards()],
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
