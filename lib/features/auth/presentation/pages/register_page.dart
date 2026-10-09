import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _currency = 'THB';

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
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isSubmitting = state is AuthLoading;
          final failure = state is AuthFailure ? state : null;
          return SafeArea(
            top: false,
            child: Center(
              child: SingleChildScrollView(
                // Clear the floating top bar.
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).top + AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthBrandHeader(compact: true),
                          const SizedBox(height: AppSpacing.lg),
                          if (failure != null) ...[
                            MessageBanner(
                              message: _bannerMessageFor(l, failure),
                              onClose: () => context
                                  .read<AuthCubit>()
                                  .acknowledgeFailure(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          SectionCard(
                            title: l.authRegisterSectionAccount,
                            children: [
                              AppTextField(
                                controller: _usernameCtrl,
                                enabled: !isSubmitting,
                                label: l.authRegisterUsernameLabel,
                                helper: l.authRegisterUsernameHint,
                                prefixIcon: AppIcons.profile,
                                errorText: _fieldErrorFor(
                                  l,
                                  'username',
                                  failure,
                                ),
                                autofillHints: const [
                                  AutofillHints.newUsername,
                                ],
                                inputFormatters: [_lowercase],
                                textInputAction: TextInputAction.next,
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
                              AppTextField(
                                controller: _passwordCtrl,
                                enabled: !isSubmitting,
                                label: l.authRegisterPasswordLabel,
                                helper: l.authRegisterPasswordHint,
                                prefixIcon: AppIcons.lock,
                                obscurable: true,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.next,
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
                              AppTextField(
                                controller: _confirmCtrl,
                                enabled: !isSubmitting,
                                label: l.authRegisterConfirmLabel,
                                prefixIcon: AppIcons.lock,
                                obscurable: true,
                                textInputAction: TextInputAction.next,
                                validator: (v) => v != _passwordCtrl.text
                                    ? l.authRegisterConfirmMismatch
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: l.authRegisterSectionProfile,
                            children: [
                              AppTextField(
                                controller: _displayNameCtrl,
                                enabled: !isSubmitting,
                                label: l.authRegisterDisplayNameLabel,
                                prefixIcon: AppIcons.profile,
                                autofillHints: const [AutofillHints.name],
                                textInputAction: TextInputAction.next,
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
                              AppTextField(
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
                                validator: (v) {
                                  final s = v?.trim() ?? '';
                                  if (s.isEmpty) return null;
                                  return _emailRegex.hasMatch(s)
                                      ? null
                                      : l.editProfileEmailInvalid;
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              CurrencyTile(
                                value: _currency,
                                label: l.authRegisterCurrencyLabel,
                                onChanged: isSubmitting
                                    ? null
                                    : (c) => setState(() => _currency = c),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: l.authRegisterSubmit,
                            onPressed: isSubmitting ? null : _submit,
                            loading: isSubmitting,
                            size: AppButtonSize.large,
                            expand: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const AuthOrDivider(),
                          const SizedBox(height: AppSpacing.lg),
                          // TODO(google-sign-in): same flow as login — the
                          // BE creates the account on first sign-in.
                          const GoogleSignInButton(),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: isSubmitting ? null : _toLogin,
                            child: Text(l.authRegisterGoToLogin),
                          ),
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

  static final _lowercase = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        newValue.copyWith(text: newValue.text.toLowerCase()),
  );

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
    final detailMsg = (failure.error.details?[field] as String?);
    return detailMsg;
  }
}
