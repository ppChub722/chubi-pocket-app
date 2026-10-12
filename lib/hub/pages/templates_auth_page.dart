import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/templates/auth-page` — the Auth template: sign in and register are the
/// same skeleton (brand · banner · form groups · primary button · "or" + social ·
/// switch link · language/theme), built only from kit pieces.
void _noop() {}

Widget buildAuthPageTemplate(BuildContext context) => const _AuthTemplate();

class _AuthTemplate extends StatefulWidget {
  const _AuthTemplate();

  @override
  State<_AuthTemplate> createState() => _AuthTemplateState();
}

class _AuthTemplateState extends State<_AuthTemplate> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _user = TextEditingController();
  final _email = TextEditingController();
  bool _error = false;
  bool _dark = false;
  String _lang = 'en';

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    _user.dispose();
    _email.dispose();
    super.dispose();
  }

  Widget _framed(Widget child, double height) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Material(color: scheme.surfaceContainerLowest, child: child),
        ),
      ),
    );
  }

  Widget get _prefs => LanguageThemeBar(
    languages: const {'th': 'ไทย', 'en': 'English'},
    languageCode: _lang,
    onLanguage: (c) => setState(() => _lang = c),
    dark: _dark,
    onToggleTheme: () => setState(() => _dark = !_dark),
    lightTooltip: 'Light',
    darkTooltip: 'Dark',
  );

  Widget _login() => AuthPageBody(
    brand: const BrandHeader(
      name: 'chubiPocket',
      tagline: 'Know where your money goes',
    ),
    banner: _error
        ? AppMessage(
            tone: Tone.danger,
            message: 'Wrong username or password',
            onClose: () => setState(() => _error = false),
          )
        : null,
    groups: [
      AppInput(
        controller: _id,
        label: 'Username or email',
        prefixIcon: AppIcons.profile,
        onChanged: (_) {},
      ),
      AppInput(
        controller: _pw,
        label: 'Password',
        prefixIcon: AppIcons.lock,
        obscurable: true,
        onChanged: (_) {},
      ),
    ],
    submit: AppButton(
      label: 'Sign in',
      size: AppButtonSize.large,
      expand: true,
      onPressed: _noop,
    ),
    alternatives: const [
      OrDivider(label: 'or'),
      SocialSignInButton(
        label: 'Continue with Google',
        comingSoonLabel: 'Soon',
      ),
    ],
    switchLink: AppButton(
      label: 'Create an account',
      variant: AppButtonVariant.text,
      expand: true,
      onPressed: _noop,
    ),
    footer: _prefs,
  );

  Widget _register() => AuthPageBody(
    compact: true,
    brand: const BrandHeader(name: 'chubiPocket', compact: true),
    groups: [
      SectionCard(
        first: true,
        fields: true,
        dividers: false,
        title: 'Account',
        children: [
          AppInput(
            controller: _user,
            label: 'Username',
            helper: 'Lowercase letters, numbers, _ and -',
            prefixIcon: AppIcons.profile,
            onChanged: (_) {},
          ),
          AppInput(
            controller: _pw,
            label: 'Password',
            prefixIcon: AppIcons.lock,
            obscurable: true,
            onChanged: (_) {},
          ),
        ],
      ),
      SectionCard(
        fields: true,
        dividers: false,
        title: 'Profile',
        children: [
          AppInput(
            controller: _email,
            label: 'Email (optional)',
            prefixIcon: AppIcons.email,
            onChanged: (_) {},
          ),
        ],
      ),
    ],
    submit: AppButton(
      label: 'Create account',
      size: AppButtonSize.large,
      expand: true,
      onPressed: _noop,
    ),
    alternatives: const [
      OrDivider(label: 'or'),
      SocialSignInButton(
        label: 'Continue with Google',
        comingSoonLabel: 'Soon',
      ),
    ],
    switchLink: AppButton(
      label: 'I already have an account',
      variant: AppButtonVariant.text,
      expand: true,
      onPressed: _noop,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          note:
              'Login and Register are an AuthPageBody + kit pieces only; the '
              'page file keeps state, validation, the API call and navigation.',
          uses: [
            HubUse(
              wide: true,
              label:
                  'Sign in — brand, banner (toggle below), two framed inputs, '
                  'primary, "or" + Google, switch link, language / theme',
              page: 'LoginPage (AuthPageBody)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      AppChip(
                        label: 'Failed attempt banner',
                        selected: _error,
                        onTap: () => setState(() => _error = !_error),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _framed(_login(), 700),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'Register — compact brand, two grouped field sections '
                  '(SectionCard fields: true), primary, "or" + Google',
              page: 'RegisterPage (AuthPageBody compact)',
              child: _framed(_register(), 760),
            ),
            const HubUse(
              label: 'BrandHeader — logo, name, tagline (5 taps = dev hub)',
              page: 'Login',
              child: BrandHeader(name: 'chubiPocket', tagline: 'Tagline'),
            ),
            const HubUse(
              label: 'OrDivider',
              page: 'Login, Register',
              child: OrDivider(label: 'or'),
            ),
            const HubUse(
              label: 'SocialSignInButton — not wired yet: dimmed + badge',
              page: 'Login, Register',
              child: SocialSignInButton(
                label: 'Continue with Google',
                comingSoonLabel: 'Soon',
              ),
            ),
            HubUse(label: 'LanguageThemeBar', page: 'Login', child: _prefs),
          ],
        ),
      ],
    );
  }
}
