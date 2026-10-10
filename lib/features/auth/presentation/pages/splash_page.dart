import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/ui.dart';
import '../cubit/auth_cubit.dart';

/// Cold-launch screen: `AuthCubit.init()` resolves the stored token while we
/// show the logo ([BrandLogo]) + spinner, picking up where the native launch
/// screen left off (same background, logo on the same spot). Router
/// redirect logic handles the actual navigation away from `/` once state
/// settles.
///
/// Min display duration is enforced (~600 ms) to avoid the splash flashing on
/// fast token-validation responses.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _minDisplay = Duration(milliseconds: 600);

  /// e.g. "v0.1.0 (2)" — set once package_info resolves. Helps testers
  /// report exactly which build they're on.
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
        setState(() => _version = 'v${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Non-fatal — the splash just won't show a version.
    }
  }

  Future<void> _kickoff() async {
    final auth = context.read<AuthCubit>();
    final initFuture = auth.init();
    await Future.wait([initFuture, Future<void>.delayed(_minDisplay)]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No SafeArea: the native launch screen centres the logo in the whole
    // window, so it's centred in the whole screen here too — the two equal
    // flex slots around it keep it on that exact spot.
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const Spacer(),
              const BrandLogo(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'ChubiPocket',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Couldn't reach the server → why + retry (the
                          // stored token is kept); otherwise the spinner.
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              final error = state is AuthInitial
                                  ? state.startupError
                                  : null;
                              if (error == null) {
                                return const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                );
                              }
                              return ErrorView(
                                error: error,
                                onRetry: context.read<AuthCubit>().init,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Build identifier, bottom-centered — testers quote this.
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
