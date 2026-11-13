import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'package:pp_forge_core/hub.dart';

/// `/dev/templates/auth-page` — the Auth template: sign in and register are the
/// same skeleton (brand · banner · form groups · primary button · "or" + social ·
/// switch link · language/theme), built only from kit pieces.
void _noop() {}

/// The login / register cards: Telegram wired, Google and LINE not yet.
Widget _socialCards() => const SocialSignInCards(
  comingSoonLabel: 'Soon',
  options: [
    SocialSignInOption(
      label: 'Telegram',
      logo: ProviderLogo(url: '', name: 'Telegram', size: 40),
      onPressed: _noop,
    ),
    SocialSignInOption(
      label: 'Google',
      logo: ProviderLogo(url: '', name: 'Google', size: 40),
    ),
    SocialSignInOption(
      label: 'LINE',
      logo: ProviderLogo(url: '', name: 'LINE', size: 40),
    ),
  ],
);

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
          borderRadius: BorderRadius.circular(PpForgeRadius.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PpForgeRadius.md),
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
    groups: [
      PpForgeInput(
        controller: _id,
        label: 'Username or email',
        prefixIcon: AppIcons.profile,
        onChanged: (_) {},
      ),
      PpForgeInput(
        controller: _pw,
        label: 'Password',
        prefixIcon: AppIcons.lock,
        obscurable: true,
        onChanged: (_) {},
      ),
    ],
    submit: PpForgeButton(
      label: 'Sign in',
      size: PpForgeButtonSize.large,
      expand: true,
      onPressed: _noop,
    ),
    alternatives: [
      const OrDivider(label: 'or'),
      _socialCards(),
    ],
    switchLink: PpForgeButton(
      label: 'Create an account',
      variant: PpForgeButtonVariant.text,
      expand: true,
      onPressed: _noop,
    ),
    footer: _prefs,
  );

  Widget _register() => AuthPageBody(
    brand: const BrandHeader(name: 'chubiPocket'),
    groups: [
      SectionCard(
        first: true,
        fields: true,
        dividers: false,
        title: 'Account',
        children: [
          PpForgeInput(
            controller: _user,
            label: 'Username',
            helper: 'Lowercase letters, numbers, _ and -',
            prefixIcon: AppIcons.profile,
            onChanged: (_) {},
          ),
          PpForgeInput(
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
          PpForgeInput(
            controller: _email,
            label: 'Email (optional)',
            prefixIcon: AppIcons.email,
            onChanged: (_) {},
          ),
        ],
      ),
    ],
    submit: PpForgeButton(
      label: 'Create account',
      size: PpForgeButtonSize.large,
      expand: true,
      onPressed: _noop,
    ),
    alternatives: [
      const OrDivider(label: 'or'),
      _socialCards(),
    ],
    switchLink: PpForgeButton(
      label: 'I already have an account',
      variant: PpForgeButtonVariant.text,
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
                  'Sign in — brand, two framed inputs (a failed attempt = the '
                  'error snackbar, below), '
                  'primary, "or" + Google, switch link, language / theme',
              page: 'LoginPage (AuthPageBody)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: PpForgeSpacing.xs,
                    children: [
                      PpForgeChip(
                        label: 'Failed attempt (error snackbar)',
                        onTap: () => showPpForgeSnackBar(
                          context,
                          'Wrong username or password',
                          tone: Tone.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PpForgeSpacing.md),
                  _framed(_login(), 700),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'Register — same brand header, two grouped field sections '
                  '(SectionCard fields: true), primary, "or" + Google',
              page: 'RegisterPage (AuthPageBody)',
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
            HubUse(
              wide: true,
              label:
                  'SocialSignInCards — 3 columns: wired (Telegram), not wired '
                  '(Google, LINE: dimmed + badge)',
              page: 'Login, Register',
              child: _socialCards(),
            ),
            HubUse(label: 'LanguageThemeBar', page: 'Login', child: _prefs),
          ],
        ),
      ],
    );
  }
}
