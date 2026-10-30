import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/auth_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _minDisplay = Duration(milliseconds: 600);

  String _version = '';

  @override
  void initState() {
    super.initState();
    _kickoff();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
          () => _version =
              'v${info.version} (${ApiClient.releaseBuild(info.buildNumber)})',
        );
      }
    } catch (_) {}
  }

  Future<void> _kickoff() async {
    final auth = context.read<AuthCubit>();
    final initFuture = auth.init();
    await Future.wait([initFuture, Future<void>.delayed(_minDisplay)]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final error = state is AuthInitial ? state.startupError : null;
              final retry = context.read<AuthCubit>().init;
              return PullToRefresh(
                enabled: error != null,
                onRefresh: retry,
                child: BrandScreen(
                  physics: const AlwaysScrollableScrollPhysics(),
                  maxWidth: 360,
                  // Stuck on a startup error, the dev hub (Connection, Logs)
                  // is still one secret tap away.
                  header: BrandHeader(
                    name: AppLocalizations.of(context)!.appName,
                    onSecretUnlock: () => context.push('/dev'),
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    if (error == null)
                      const Center(
                        child: AppSpinner(size: AppSpinnerSize.large),
                      )
                    else
                      ErrorView(error: error, onRetry: retry),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
            child: Text(
              _version,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
