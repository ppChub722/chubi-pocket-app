import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/organisms/states` — async states, pull to refresh, saving overlay.
Widget buildStatesPage(BuildContext context) => const _StatesPage();

class _StatesPage extends StatelessWidget {
  const _StatesPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubSubheading(
          'In the app',
          note: 'The real presets and where they are used.',
        ),
        const HubDemo(
          title: 'AsyncStateView',
          note:
              'One rule for every async screen: first load shows the '
              'skeleton, a failure shows ErrorView + retry, nothing to show '
              'shows the empty view, data wins. A failed refresh with data '
              'on screen raises a snackbar instead of hiding the data.',
          child: _AsyncDemo(),
        ),
        HubDemo(
          title: 'AsyncStateView.fallback',
          note:
              'Detail pages while the item is not cached: skeleton, error + '
              'retry, then not found.',
          child: _FallbackDemo(),
        ),
        HubDemo(
          title: 'PullToRefresh + CoinDropIndicator',
          note:
              'Drag the list down. The coin spins while pulling and keeps '
              'dropping into the wallet until onRefresh resolves (1.5 s here).',
          child: _PullDemo(),
        ),
        HubDemo(
          title: 'CoinDropIndicator - phases',
          note: 'Public so every phase can be shown without a real pull.',
          child: _CoinPhases(),
        ),
        HubDemo(
          title: 'SavingOverlay',
          note:
              'Dims the child, shows a spinner and blocks input while a '
              'write is running.',
          child: _SavingDemo(),
        ),

        HubPlayground(
          title: 'AsyncStateView',
          note:
              'The one rule for every async screen: the state decides what '
              'shows. Pick a state; data wins over everything.',
          controls: [
            PlayChoice<int>('state', [
              ('loading', 0),
              ('error', 1),
              ('empty', 2),
              ('data', 3),
            ], initial: 0),
          ],
          builder: (context, v) {
            final state = v<int>('state');
            return SizedBox(
              height: 220,
              child: AsyncStateView(
                loading: state == 0,
                error: state == 1 ? Exception('Boom') : null,
                isEmpty: state == 2,
                onRetry: () async {},
                builder: (_) => const Center(child: Text('The data')),
              ),
            );
          },
        ),
      ],
    );
  }
}

const double _stageHeight = 320;

Widget _stageBox(BuildContext context, Widget child) => Container(
  height: _stageHeight,
  decoration: BoxDecoration(
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  clipBehavior: Clip.antiAlias,
  child: child,
);

Widget _sampleList() => ListView(
  physics: const AlwaysScrollableScrollPhysics(),
  padding: const EdgeInsets.all(AppSpacing.md),
  children: [
    for (final name in ['Groceries', 'Rent', 'Coffee', 'Transport', 'Salary'])
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppText(name),
          ),
        ),
      ),
  ],
);

ApiException _fakeError() => const ApiException(
  code: 'NETWORK_ERROR',
  message: 'Could not reach the server',
  requestId: 'req-demo-1234',
);

Widget _selector<T>({
  required List<(T, String)> options,
  required T value,
  required ValueChanged<T> onChanged,
}) => Wrap(
  spacing: AppSpacing.sm,
  runSpacing: AppSpacing.sm,
  children: [
    for (final (v, label) in options)
      AppChip(label: label, selected: v == value, onTap: () => onChanged(v)),
  ],
);

enum _Mode { loading, error, empty, data, refreshFailed }

class _AsyncDemo extends StatefulWidget {
  const _AsyncDemo();

  @override
  State<_AsyncDemo> createState() => _AsyncDemoState();
}

class _AsyncDemoState extends State<_AsyncDemo> {
  _Mode _mode = _Mode.loading;
  Object? _error;
  int _key = 0;

  void _set(_Mode m) => setState(() {
    _mode = m;
    _error = m == _Mode.error ? _fakeError() : null;
    // A fresh view each time, so "first load" is first again.
    if (m == _Mode.loading || m == _Mode.error) _key++;
  });

  Future<void> _retry() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) _set(_Mode.data);
  }

  void _failRefresh() => setState(() => _error = _fakeError());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selector<_Mode>(
          options: const [
            (_Mode.loading, 'First loading'),
            (_Mode.error, 'Error'),
            (_Mode.empty, 'Empty'),
            (_Mode.data, 'Data'),
            (_Mode.refreshFailed, 'Refresh failed'),
          ],
          value: _mode,
          onChanged: (m) {
            _set(m);
            if (m == _Mode.refreshFailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _failRefresh();
              });
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _stageBox(
          context,
          AsyncStateView(
            key: ValueKey(_key),
            loading: _mode == _Mode.loading,
            error: _error,
            isEmpty:
                _mode == _Mode.loading ||
                _mode == _Mode.error ||
                _mode == _Mode.empty,
            onRetry: _retry,
            empty: EmptyView(
              icon: AppIcons.empty,
              title: 'No wallets yet',
              message: 'Add your first wallet to start tracking.',
              cta: AddTile(label: 'Add wallet', onTap: () {}),
            ),
            builder: (_) => _sampleList(),
          ),
        ),
        if (_mode == _Mode.refreshFailed) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Fail the refresh again',
            variant: AppButtonVariant.tonal,
            onPressed: () {
              setState(() => _error = null);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _failRefresh();
              });
            },
          ),
        ],
      ],
    );
  }
}

enum _Fallback { loading, error, notFound }

class _FallbackDemo extends StatefulWidget {
  const _FallbackDemo();

  @override
  State<_FallbackDemo> createState() => _FallbackDemoState();
}

class _FallbackDemoState extends State<_FallbackDemo> {
  _Fallback _mode = _Fallback.loading;
  final _error = _fakeError();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selector<_Fallback>(
          options: const [
            (_Fallback.loading, 'Loading'),
            (_Fallback.error, 'Error'),
            (_Fallback.notFound, 'Not found'),
          ],
          value: _mode,
          onChanged: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: AppSpacing.md),
        _stageBox(
          context,
          AsyncStateView.fallback(
            key: ValueKey(_mode == _Fallback.loading),
            loading: _mode == _Fallback.loading,
            error: _mode == _Fallback.error ? _error : null,
            onRetry: () async {
              await Future<void>.delayed(const Duration(milliseconds: 800));
              if (mounted) setState(() => _mode = _Fallback.notFound);
            },
            notFound: const EmptyView(
              icon: AppIcons.empty,
              title: 'Not found',
              message: 'This item no longer exists.',
            ),
          ),
        ),
      ],
    );
  }
}

class _PullDemo extends StatelessWidget {
  const _PullDemo();

  @override
  Widget build(BuildContext context) {
    return _stageBox(
      context,
      PullToRefresh(
        onRefresh: () =>
            Future<void>.delayed(const Duration(milliseconds: 1500)),
        child: _sampleList(),
      ),
    );
  }
}

class _CoinPhases extends StatelessWidget {
  const _CoinPhases();

  @override
  Widget build(BuildContext context) {
    Widget cell(String caption, Widget indicator) => HubCell(
      caption: caption,
      child: SizedBox(width: 96, height: 112, child: indicator),
    );
    return HubRow(
      cells: [
        cell('pull 0.3', const CoinDropIndicator(pull: 0.3)),
        cell('pull 0.7', const CoinDropIndicator(pull: 0.7)),
        cell('pull 1 (armed)', const CoinDropIndicator(pull: 1)),
        cell('drop 0.2', const CoinDropIndicator(pull: 1, drop: 0.2)),
        cell('drop 0.7 (landed)', const CoinDropIndicator(pull: 1, drop: 0.7)),
        cell(
          'exit 0.6',
          const CoinDropIndicator(pull: 1, drop: 0.3, exit: 0.6),
        ),
      ],
    );
  }
}

class _SavingDemo extends StatefulWidget {
  const _SavingDemo();

  @override
  State<_SavingDemo> createState() => _SavingDemoState();
}

class _SavingDemoState extends State<_SavingDemo> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SavingOverlay(
          saving: _saving,
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Main wallet', role: AppTextRole.title),
                  const SizedBox(height: AppSpacing.sm),
                  const AppText('Balance 12,500.00'),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: 'Tap me while saving', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Save for 2 s', onPressed: _saving ? null : _save),
      ],
    );
  }
}
