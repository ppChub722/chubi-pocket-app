import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';
import '../core/network/api_exception.dart';
import '../shared/widgets/empty_view.dart';
import '../shared/widgets/error_view.dart';
import '../shared/widgets/loading_view.dart';
import '../shared/widgets/skeleton_box.dart';

/// Renders each Phase 0 state-pattern widget so we can eyeball them in one
/// place. Reachable via `/dev/state-widgets`.
class StateWidgetsPreviewScreen extends StatefulWidget {
  const StateWidgetsPreviewScreen({super.key});

  @override
  State<StateWidgetsPreviewScreen> createState() =>
      _StateWidgetsPreviewScreenState();
}

class _StateWidgetsPreviewScreenState extends State<StateWidgetsPreviewScreen> {
  _Variant _variant = _Variant.loading;
  _ErrorKind _errorKind = _ErrorKind.network;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State widgets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                SegmentedButton<_Variant>(
                  segments: const [
                    ButtonSegment(
                      value: _Variant.loading,
                      label: Text('Loading'),
                      icon: Icon(Icons.hourglass_top_outlined),
                    ),
                    ButtonSegment(
                      value: _Variant.error,
                      label: Text('Error'),
                      icon: Icon(Icons.error_outline),
                    ),
                    ButtonSegment(
                      value: _Variant.empty,
                      label: Text('Empty'),
                      icon: Icon(Icons.inbox_outlined),
                    ),
                  ],
                  selected: {_variant},
                  onSelectionChanged: (s) =>
                      setState(() => _variant = s.first),
                ),
                if (_variant == _Variant.error) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: _ErrorKind.values
                        .map((k) => ChoiceChip(
                              label: Text(k.name),
                              selected: _errorKind == k,
                              onSelected: (_) =>
                                  setState(() => _errorKind = k),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: switch (_variant) {
        _Variant.loading => LoadingView(skeleton: _listSkeleton()),
        _Variant.error => ErrorView(
            error: _errorKind.toException(),
            onRetry: () => setState(() {}),
          ),
        _Variant.empty => const EmptyView(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            message: 'Log your first one to get started.',
          ),
      },
    );
  }

  /// Per-row skeleton matching `TransactionRow` shape (design-sheet §8.5.1).
  Widget _listSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const _TransactionRowSkeleton(),
    );
  }
}

class _TransactionRowSkeleton extends StatelessWidget {
  const _TransactionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonBox(height: 40, width: 40, shape: BoxShape.circle),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                height: 16,
                width: MediaQuery.sizeOf(context).width * 0.6,
              ),
              const SizedBox(height: AppSpacing.xs),
              SkeletonBox(
                height: 14,
                width: MediaQuery.sizeOf(context).width * 0.4,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const SkeletonBox(height: 16, width: 80),
      ],
    );
  }
}

enum _Variant { loading, error, empty }

enum _ErrorKind { network, server, unknown }

extension on _ErrorKind {
  ApiException toException() => switch (this) {
        _ErrorKind.network => const ApiException(
            code: 'NETWORK_ERROR',
            message: 'No connection',
          ),
        _ErrorKind.server => const ApiException(
            code: 'INTERNAL_ERROR',
            message: 'Internal server error',
            statusCode: 500,
          ),
        _ErrorKind.unknown => const ApiException(
            code: 'WHATEVER',
            message: 'Something odd happened',
          ),
      };
}
