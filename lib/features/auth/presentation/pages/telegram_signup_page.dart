import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/telegram_login_cubit.dart';
import '../widgets/auth_widgets.dart';

/// The short sign-up for a Telegram chat with no account: the name and
/// @username come from Telegram (editable), the currency is picked here.
class TelegramSignupPage extends StatefulWidget {
  const TelegramSignupPage({super.key});

  @override
  State<TelegramSignupPage> createState() => _TelegramSignupPageState();
}

class _TelegramSignupPageState extends State<TelegramSignupPage> {
  static final _usernameRegex = RegExp(r'^[a-z0-9_-]{3,50}$');

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String _currency = 'THB';

  @override
  void initState() {
    super.initState();
    final info = context.read<TelegramLoginCubit>().state.signup;
    _nameCtrl.text = info?.displayName ?? '';
    _usernameCtrl.text = info?.usernameSuggestion ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Opened with no sign-up pending (a restored route): back to the form.
      if (context.read<TelegramLoginCubit>().state.phase ==
          TelegramLoginPhase.idle) {
        context.go('/auth/login');
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _cancel() {
    context.read<TelegramLoginCubit>().reset();
    context.go('/auth/login');
  }

  void _submit() {
    final l = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (name.isEmpty ||
        name.length > 100 ||
        !_usernameRegex.hasMatch(username)) {
      showAppSnackBar(context, l.authRegisterIncomplete, tone: Tone.danger);
      return;
    }
    context.read<TelegramLoginCubit>().signup(
      displayName: name,
      username: username,
      currency: _currency,
    );
  }

  void _onState(BuildContext context, TelegramLoginState s) {
    final l = AppLocalizations.of(context)!;
    final e = s.failure;
    if (s.phase == TelegramLoginPhase.expired) {
      if (e != null) {
        showErrorSnackBar(context, e);
      } else {
        showAppSnackBar(context, l.authTelegramExpired, tone: Tone.danger);
      }
      context.read<TelegramLoginCubit>().reset();
      context.go('/auth/login');
      return;
    }
    if (e == null) return;
    if (e.code == 'USERNAME_EXISTS') {
      final free = s.signup?.usernameSuggestion;
      if (free != null && free.isNotEmpty) _usernameCtrl.text = free;
      showAppSnackBar(context, l.authTelegramUsernameTaken, tone: Tone.danger);
    } else {
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: l.authTelegramSignupTitle,
          showBack: true,
          showUniversal: false,
          showParent: false,
          onBack: _cancel,
        ),
        extendBodyBehindAppBar: true,
        body: BlocConsumer<TelegramLoginCubit, TelegramLoginState>(
          listenWhen: (a, b) =>
              a.phase != b.phase || a.failureId != b.failureId,
          listener: _onState,
          builder: (context, s) {
            final busy = s.phase == TelegramLoginPhase.signingUp;
            return AuthPageBody(
              compact: true,
              clearTopBar: true,
              brand: const AuthBrandHeader(compact: true),
              groups: [
                SectionCard(
                  first: true,
                  fields: true,
                  dividers: false,
                  title: l.authTelegramSignupTitle,
                  children: [
                    AppInput(
                      controller: _nameCtrl,
                      enabled: !busy,
                      label: l.authRegisterDisplayNameLabel,
                      prefixIcon: AppIcons.profile,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                    ),
                    AppInput(
                      controller: _usernameCtrl,
                      enabled: !busy,
                      label: l.authRegisterUsernameLabel,
                      helper: l.authRegisterUsernameHint,
                      prefixIcon: AppIcons.profile,
                      autofillHints: const [AutofillHints.newUsername],
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (o, n) => n.copyWith(text: n.text.toLowerCase()),
                        ),
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    CurrencyTile(
                      value: _currency,
                      label: l.authRegisterCurrencyLabel,
                      onChanged: busy
                          ? null
                          : (c) => setState(() => _currency = c),
                    ),
                  ],
                ),
                if (s.signup?.hasPhoto ?? false)
                  Row(
                    children: [
                      const ProviderLogo(
                        url: '/api/v1/brand-logos/telegram.png?v=1',
                        name: 'Telegram',
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l.authTelegramSignupPhoto,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
              ],
              submit: AppButton(
                label: l.authRegisterSubmit,
                submits: true,
                onPressed: busy ? null : _submit,
                loading: busy,
                size: AppButtonSize.large,
                expand: true,
              ),
              switchLink: AppButton(
                label: l.commonCancel,
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: busy ? null : _cancel,
              ),
            );
          },
        ),
      ),
    );
  }
}
