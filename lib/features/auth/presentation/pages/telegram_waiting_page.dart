import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/telegram_login_cubit.dart';

/// "รอยืนยันใน Telegram": the user confirms in the bot chat and comes back;
/// the app asks the server on resume, every few seconds while it is in front,
/// and on the retry button.
class TelegramWaitingPage extends StatefulWidget {
  const TelegramWaitingPage({super.key});

  /// How often the page asks while it is in front.
  static const pollEvery = Duration(seconds: 3);

  @override
  State<TelegramWaitingPage> createState() => _TelegramWaitingPageState();
}

class _TelegramWaitingPageState extends State<TelegramWaitingPage> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _inFront = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _inFront = true;
        _check();
      },
      onHide: () => _inFront = false,
    );
    _timer = Timer.periodic(TelegramWaitingPage.pollEvery, (_) {
      if (_inFront) _check();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Opened with no login running (a restored route): back to the form.
      if (context.read<TelegramLoginCubit>().state.phase ==
          TelegramLoginPhase.idle) {
        context.go('/auth/login');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _check() {
    if (mounted) unawaited(context.read<TelegramLoginCubit>().check());
  }

  void _cancel() {
    context.read<TelegramLoginCubit>().reset();
    context.go('/auth/login');
  }

  Future<void> _reopen() async {
    final l = AppLocalizations.of(context)!;
    final url = context.read<TelegramLoginCubit>().state.url;
    final uri = url == null ? null : Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showAppSnackBar(context, l.authTelegramOpenFailed, tone: Tone.danger);
    }
  }

  void _onState(BuildContext context, TelegramLoginState s) {
    final l = AppLocalizations.of(context)!;
    switch (s.phase) {
      case TelegramLoginPhase.signup:
        context.pushReplacement('/auth/telegram/signup');
      case TelegramLoginPhase.expired:
        final e = s.failure;
        if (e != null) {
          showErrorSnackBar(context, e);
        } else {
          showAppSnackBar(context, l.authTelegramExpired, tone: Tone.danger);
        }
        context.read<TelegramLoginCubit>().reset();
        context.go('/auth/login');
      case TelegramLoginPhase.waiting:
        final e = s.failure;
        if (e != null) showErrorSnackBar(context, e);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: l.authTelegramWaitTitle,
          showBack: true,
          showUniversal: false,
          showParent: false,
          onBack: _cancel,
        ),
        body: BlocConsumer<TelegramLoginCubit, TelegramLoginState>(
          listenWhen: (a, b) =>
              a.phase != b.phase || a.failureId != b.failureId,
          listener: _onState,
          builder: (context, s) => SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: ProviderLogo(
                          url: '/api/v1/brand-logos/telegram.png?v=1',
                          name: 'Telegram',
                          size: 72,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l.authTelegramWaitTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l.authTelegramWaitBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        label: l.authTelegramCheck,
                        loading: s.checking,
                        onPressed: _check,
                        size: AppButtonSize.large,
                        expand: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l.authTelegramReopen,
                        variant: AppButtonVariant.outlined,
                        onPressed: _reopen,
                        size: AppButtonSize.large,
                        expand: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l.commonCancel,
                        variant: AppButtonVariant.text,
                        onPressed: _cancel,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
