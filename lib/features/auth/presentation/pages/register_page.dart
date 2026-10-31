import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static final _usernameRegex = RegExp(r'^[a-z0-9_-]{3,50}$');
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _currency = 'THB';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthCubit>().acknowledgeFailure();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Same rules the form had inline; now one answer, a toast.
  bool get _valid {
    final username = _usernameCtrl.text.trim();
    final name = _displayNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    return _usernameRegex.hasMatch(username) &&
        password.length >= 8 &&
        password.length <= 128 &&
        _confirmCtrl.text == password &&
        name.isNotEmpty &&
        name.length <= 100 &&
        (email.isEmpty || _emailRegex.hasMatch(email));
  }

  void _submit() {
    if (!_valid) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.authRegisterIncomplete,
        tone: Tone.danger,
      );
      return;
    }
    context.read<AuthCubit>().register(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _displayNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      currency: _currency,
    );
  }

  void _toLogin() =>
      context.canPop() ? context.pop() : context.go('/auth/login');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(
        title: l.authRegisterTitle,
        showBack: true,
        showUniversal: false,
        showParent: false,
        onBack: _toLogin,
      ),
      extendBodyBehindAppBar: true,
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
            final failure = state is AuthFailure ? state : null;
            return AuthPageBody(
              brand: const AuthBrandHeader(),
              groups: [
                SectionCard(
                  first: true,
                  fields: true,
                  dividers: false,
                  title: l.authRegisterSectionAccount,
                  children: [
                    AppInput(
                      controller: _usernameCtrl,
                      enabled: !isSubmitting,
                      label: l.authRegisterUsernameLabel,
                      helper: l.authRegisterUsernameHint,
                      prefixIcon: AppIcons.profile,
                      errorText: _fieldErrorFor(l, 'username', failure),
                      autofillHints: const [AutofillHints.newUsername],
                      inputFormatters: [_lowercase],
                      textInputAction: TextInputAction.next,
                    ),
                    AppInput(
                      controller: _passwordCtrl,
                      enabled: !isSubmitting,
                      label: l.authRegisterPasswordLabel,
                      helper: l.authRegisterPasswordHint,
                      prefixIcon: AppIcons.lock,
                      obscurable: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                    ),
                    AppInput(
                      controller: _confirmCtrl,
                      enabled: !isSubmitting,
                      label: l.authRegisterConfirmLabel,
                      prefixIcon: AppIcons.lock,
                      obscurable: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
                SectionCard(
                  fields: true,
                  dividers: false,
                  title: l.authRegisterSectionProfile,
                  children: [
                    AppInput(
                      controller: _displayNameCtrl,
                      enabled: !isSubmitting,
                      label: l.authRegisterDisplayNameLabel,
                      prefixIcon: AppIcons.profile,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                    ),
                    AppInput(
                      controller: _emailCtrl,
                      enabled: !isSubmitting,
                      label: l.authRegisterEmailLabel,
                      helper: l.authRegisterEmailHint,
                      prefixIcon: AppIcons.email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      errorText: _fieldErrorFor(l, 'email', failure),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    CurrencyTile(
                      value: _currency,
                      label: l.authRegisterCurrencyLabel,
                      onChanged: isSubmitting
                          ? null
                          : (c) => setState(() => _currency = c),
                    ),
                  ],
                ),
              ],
              submit: AppButton(
                label: l.authRegisterSubmit,
                submits: true,
                onPressed: isSubmitting ? null : _submit,
                loading: isSubmitting,
                size: AppButtonSize.large,
                expand: true,
              ),
              alternatives: const [AuthOrDivider(), AuthSocialCards()],
              switchLink: AppButton(
                label: l.authRegisterGoToLogin,
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: isSubmitting ? null : _toLogin,
              ),
            );
          },
        ),
      ),
    );
  }

  static final _lowercase = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.toLowerCase()),
  );

  String? _fieldErrorFor(
    AppLocalizations l,
    String field,
    AuthFailure? failure,
  ) {
    if (failure == null) return null;
    final c = failure.error.code;
    if (field == 'username' && c == 'USERNAME_EXISTS') {
      return l.authRegisterUsernameTakenInline;
    }
    if (field == 'email' && c == 'EMAIL_EXISTS') {
      return l.authRegisterEmailTakenInline;
    }
    return fieldErrorText(l, failure.error, field);
  }
}
