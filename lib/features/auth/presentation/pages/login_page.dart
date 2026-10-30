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

  @override
  void initState() {
    super.initState();
    // A 401 kicked the user here: say why, once (the toast lives past the
    // route change, so it is shown from the page the user lands on).
    WidgetsBinding.instance.addPostFrameCallback((_) => _noteExpired());
  }

  void _noteExpired() {
    if (!mounted) return;
    final auth = context.read<AuthCubit>();
    final s = auth.state;
    if (s is! AuthUnauthenticated || !s.sessionExpired) return;
    auth.acknowledgeSessionExpired();
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.errSessionExpired,
      tone: Tone.warning,
    );
  }

  /// Both auth pages read the one [AuthCubit]: a failed login must not show on
  /// the register page, nor a failed sign-up here on the way back.
  Future<void> _openRegister() async {
    // The error snackbar lives app-wide: it must not follow to register.
    SnackStack.of(ScaffoldMessenger.of(context)).clearTransient();
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
        listenWhen: (_, s) =>
            s is AuthFailure || (s is AuthUnauthenticated && s.sessionExpired),
        listener: (context, s) {
          if (s is AuthUnauthenticated) {
            _noteExpired();
          } else if (ModalRoute.of(context)?.isCurrent ?? true) {
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
