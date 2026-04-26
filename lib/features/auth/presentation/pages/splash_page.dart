import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../cubit/auth_cubit.dart';

/// Cold-launch screen: `AuthCubit.init()` resolves the stored token while we
/// show the brand mark + spinner. Router redirect logic handles the actual
/// navigation away from `/` once state settles.
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

  @override
  void initState() {
    super.initState();
    _kickoff();
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LogoMark(color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'ChubiPocket',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder "C" mark — replaced when a real logo is commissioned.
/// See `chubi-pocket-docs/product/ui-design/app/design-sheet.md §2`.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: const Text(
        'C',
        style: TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
