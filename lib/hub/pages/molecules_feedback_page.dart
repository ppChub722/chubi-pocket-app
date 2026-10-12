import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/molecules/feedback` — banners, progress, snackbars, dialogs and the
/// empty / error / loading states, plus the localisation hooks they read.
Widget buildFeedbackPage(BuildContext context) => const _FeedbackPage();

final _networkError = ApiException(code: 'NETWORK_ERROR', message: 'offline');
final _serverError = ApiException(
  code: 'SERVER',
  message: 'boom',
  statusCode: 500,
);
final _unknownError = ApiException(code: 'X', message: 'x');

/// A demo-only [UiErrors] with its own words, to show the hook.
class _DemoErrors extends UiErrors {
  const _DemoErrors();

  @override
  UiErrorInfo describe(Object error) => const UiErrorInfo(
    icon: AppIcons.offline,
    title: 'Custom headline',
    message: 'Every error reads this way inside this UiConfig.',
  );
}

class _FeedbackPage extends StatefulWidget {
  const _FeedbackPage();

  @override
  State<_FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<_FeedbackPage> {
  final _closable = <Tone>{...Tone.values};
  double _progress = 0.6;
  String _result = 'No dialog answered yet';

  Future<void> _confirm({required bool destructive}) async {
    final ok = await showConfirmDialog(
      context,
      title: destructive ? 'Delete this wallet?' : 'Save changes?',
      message: destructive
          ? 'Its transactions will be deleted too.'
          : 'You can edit them again later.',
      confirmLabel: destructive ? 'Delete' : 'Save',
      destructive: destructive,
    );
    if (mounted) setState(() => _result = 'Confirm resolved: $ok');
  }

  Future<void> _choice() async {
    final v = await showChoiceDialog<String>(
      context,
      title: 'Leave this form?',
      message: 'You have unsaved changes.',
      choices: const [
        DialogChoice(
          value: 'draft',
          label: 'Keep as draft',
          variant: AppButtonVariant.primary,
        ),
        DialogChoice(value: 'edit', label: 'Keep editing'),
        DialogChoice(
          value: 'discard',
          label: 'Discard',
          variant: AppButtonVariant.destructive,
        ),
      ],
    );
    if (mounted) setState(() => _result = 'Choice resolved: $v');
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    const gap = SizedBox(height: AppSpacing.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'MessageBanner',
          controls: [
            PlayChoice<Tone>('tone', [
              for (final t in Tone.values) (t.name, t),
            ], initial: Tone.danger),
            const PlayText(
              'message',
              initialValue: 'Something needs attention',
            ),
            const PlayBool('onClose'),
          ],
          builder: (context, v) => MessageBanner(
            message: v<String>('message'),
            tone: v<Tone>('tone'),
            onClose: v<bool>('onClose') ? () {} : null,
          ),
        ),
        HubPlayground(
          title: 'AppMessage (proposal)',
          controls: [
            PlayChoice<Tone>('tone', [
              ('info', Tone.info),
              ('success', Tone.success),
              ('warning', Tone.warning),
              ('danger', Tone.danger),
            ]),
            const PlayText('message', initialValue: 'Wallet deleted'),
            const PlayNum('actions', min: 0, max: 2, step: 1, initialValue: 1),
            const PlayBool('onClose'),
            const PlayBool('floating'),
          ],
          builder: (context, v) => AppMessage(
            message: v<String>('message'),
            tone: v<Tone>('tone'),
            floating: v<bool>('floating'),
            onClose: v<bool>('onClose') ? () {} : null,
            actions: [
              for (var i = 0; i < v<double>('actions').round(); i++)
                AppMessageAction(
                  label: i == 0 ? 'Undo' : 'Dismiss',
                  onPressed: () {},
                ),
            ],
          ),
        ),
        const HubSubheading(
          'In the app',
          note: 'The real presets and where they are used.',
        ),
        HubDemo(
          title: 'AppMessage — one design for banner + snackbar (PROPOSAL)',
          note:
              'Owner 2026-10-12: the snackbar and the banner share ONE body — '
              'same tone colours, icon set, radius, padding and type; only '
              'placement and lifetime differ. Banner: inline, stays until '
              'resolved or closed, 1–2 actions. Snackbar: floats at the '
              'bottom, auto-dismisses, at most 1 action. Just happened → '
              'snackbar; still true → banner. Current is the real widget, '
              'Proposed the new one; the app is unchanged until the owner OKs.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Banners — every tone',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final t in [
                Tone.info,
                Tone.success,
                Tone.warning,
                Tone.danger,
              ]) ...[
                _pair(
                  MessageBanner(message: 'Tone ${t.name}, text only', tone: t),
                  AppMessage(message: 'Tone ${t.name}, text only', tone: t),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Banner — with ✕, 1 action, 2 actions',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              _pair(
                MessageBanner(
                  message: 'No connection — changes are kept on this device',
                  tone: Tone.warning,
                  onClose: () {},
                ),
                AppMessage(
                  message: 'No connection — changes are kept on this device',
                  tone: Tone.warning,
                  onClose: () {},
                ),
              ),
              _pair(
                const _None('Today: no actions in a banner.'),
                AppMessage(
                  message: 'Could not load wallets',
                  tone: Tone.danger,
                  actions: [AppMessageAction(label: 'Retry', onPressed: () {})],
                ),
              ),
              _pair(
                const _None('Today: no actions in a banner.'),
                AppMessage(
                  message:
                      'Update available — a new version is ready to install',
                  tone: Tone.info,
                  onClose: () {},
                  actions: [
                    AppMessageAction(label: 'Later', onPressed: () {}),
                    AppMessageAction(label: 'Update', onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Snackbar — floating at the bottom',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Proposed (the same body, floating = a soft shadow)',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppMessage(
                      message: 'Wallet deleted',
                      tone: Tone.success,
                      floating: true,
                      actions: [
                        AppMessageAction(label: 'Undo', onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const AppMessage(
                      message: 'Could not save — check your connection',
                      tone: Tone.danger,
                      floating: true,
                      actions: [],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Current snackbar',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => showAppSnackBar(
                      context,
                      'Wallet deleted',
                      tone: Tone.success,
                      actionLabel: 'Undo',
                      onAction: () {},
                    ),
                  ),
                  AppButton(
                    label: 'Proposed snackbar',
                    onPressed: () => showAppMessage(
                      context,
                      'Wallet deleted',
                      tone: Tone.success,
                      actionLabel: 'Undo',
                      onAction: () {},
                    ),
                  ),
                  AppButton(
                    label: 'Proposed · error + Retry',
                    variant: AppButtonVariant.tonal,
                    onPressed: () => showAppMessage(
                      context,
                      'Could not save',
                      tone: Tone.danger,
                      actionLabel: 'Retry',
                      onAction: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'MessageBanner',
          note:
              'Inline state the user must read before trying again. Tone '
              'tints it; onClose adds a close button (tap it to dismiss).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in Tone.values) ...[
                if (_closable.contains(t)) ...[
                  MessageBanner(
                    message: 'Tone ${t.name}, with onClose',
                    tone: t,
                    onClose: () => setState(() => _closable.remove(t)),
                  ),
                  gap,
                ],
                MessageBanner(message: 'Tone ${t.name}, no onClose', tone: t),
                gap,
              ],
              if (_closable.length < Tone.values.length)
                AppButton(
                  label: 'Restore dismissed',
                  variant: AppButtonVariant.outlined,
                  onPressed: () =>
                      setState(() => _closable.addAll(Tone.values)),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'ProgressRow',
          note:
              'Ratio 0-1; above 1 the bar fills and turns the over colour '
              'and the trailing text goes bold.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProgressRow(
                value: 0.4,
                label: 'Spent 400 of 1,000',
                trailing: '40%',
              ),
              gap,
              const ProgressRow(
                value: 1,
                label: 'Exactly at the limit',
                trailing: '100%',
              ),
              gap,
              const ProgressRow(
                value: 1.3,
                label: 'Spent 1,300 of 1,000',
                trailing: '130%',
              ),
              gap,
              const ProgressRow(value: 0.5),
              gap,
              const ProgressRow(value: 0.5, trailing: '50% (trailing only)'),
              gap,
              const ProgressRow(value: 0.7, height: 16, label: 'height: 16'),
              gap,
              ProgressRow(
                value: _progress,
                label: 'Interactive',
                trailing: '${(_progress * 100).round()}%',
              ),
              Slider(
                value: _progress,
                max: 1.5,
                onChanged: (v) => setState(() => _progress = v),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showAppSnackBar',
          note:
              'Floating, replaces the current one. Tone adds a leading icon; '
              'an action needs both actionLabel and onAction.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in Tone.values)
                AppButton(
                  label: t.name,
                  variant: AppButtonVariant.outlined,
                  onPressed: () =>
                      showAppSnackBar(context, 'Tone ${t.name}', tone: t),
                ),
              AppButton(
                label: 'with action',
                onPressed: () => showAppSnackBar(
                  context,
                  'Wallet deleted',
                  tone: Tone.success,
                  actionLabel: 'Undo',
                  onAction: () => showAppSnackBar(context, 'Undone'),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showAppSnackBarOn',
          note:
              'Same, on a messenger captured up front, for calls after an '
              'await or a pop when the context may be gone.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in Tone.values)
                AppButton(
                  label: t.name,
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    await Future<void>.delayed(const Duration(seconds: 1));
                    showAppSnackBarOn(
                      messenger,
                      'After a pause: ${t.name}',
                      tone: t,
                    );
                  },
                ),
              AppButton(
                label: 'with action',
                onPressed: () => showAppSnackBarOn(
                  messenger,
                  'Saved',
                  tone: Tone.info,
                  actionLabel: 'View',
                  onAction: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showErrorSnackBar',
          note:
              'A failure with data on screen: a danger snackbar worded by '
              'UiErrors; onRetry adds the Retry action.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (label, err) in [
                ('network', _networkError),
                ('server', _serverError),
                ('unknown', _unknownError),
              ]) ...[
                AppButton(
                  label: '$label, retry',
                  variant: AppButtonVariant.outlined,
                  onPressed: () =>
                      showErrorSnackBar(context, err, onRetry: () {}),
                ),
                AppButton(
                  label: '$label, no retry',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => showErrorSnackBar(context, err),
                ),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'showConfirmDialog / showChoiceDialog + DialogChoice',
          note:
              'Confirm: two ways out, resolves a bool. Choice: three or more '
              'stacked buttons, resolves the picked value or null.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Confirm',
                    onPressed: () => _confirm(destructive: false),
                  ),
                  AppButton(
                    label: 'Confirm (destructive)',
                    variant: AppButtonVariant.destructiveOutlined,
                    onPressed: () => _confirm(destructive: true),
                  ),
                  AppButton(
                    label: 'Choice dialog',
                    variant: AppButtonVariant.outlined,
                    onPressed: _choice,
                  ),
                ],
              ),
              gap,
              AppText(_result, role: AppTextRole.caption),
            ],
          ),
        ),
        HubDemo(
          title: 'EmptyView',
          note:
              'A successful call with zero rows. The call to action is '
              'optional.',
          child: Column(
            children: [
              const HubCell(
                caption: 'No cta',
                child: EmptyView(
                  icon: AppIcons.empty,
                  title: 'Nothing here',
                  message: 'Transactions you add will show up here.',
                ),
              ),
              HubCell(
                caption: 'With AddTile cta',
                child: EmptyView(
                  icon: AppIcons.empty,
                  title: 'No wallets yet',
                  message: 'Create your first wallet to start.',
                  cta: AddTile(label: 'Add wallet', onTap: () {}),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ErrorView',
          note:
              'Full-view failure when no data is on screen. The words come '
              'from the installed UiErrors; retry is optional.',
          child: Column(
            children: [
              HubCell(
                caption: 'Network, retry',
                child: ErrorView(error: _networkError, onRetry: () {}),
              ),
              HubCell(
                caption: 'Server, retry',
                child: ErrorView(error: _serverError, onRetry: () {}),
              ),
              HubCell(
                caption: 'Unknown, retry',
                child: ErrorView(error: _unknownError, onRetry: () {}),
              ),
              HubCell(
                caption: 'Unknown, no retry',
                child: ErrorView(error: _unknownError),
              ),
            ],
          ),
        ),
        const HubDemo(
          title: 'LoadingView',
          note:
              'Skeletons, never spinners on lists. Default is a generic '
              'shimmer block; pass skeleton for a row-shaped one.',
          child: Column(
            children: [
              HubCell(
                caption: 'Default',
                child: SizedBox(height: 300, child: LoadingView()),
              ),
              HubCell(
                caption: 'Custom skeleton',
                child: LoadingView(
                  skeleton: Column(
                    children: [
                      SkeletonBox(height: 48),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'UiConfig / UiStrings / UiErrors / UiErrorInfo / AppUiConfig',
          note:
              'Generic widgets read their words from UiConfig; the app '
              'installs AppUiConfig once at its root. Below, the same '
              'ErrorView under the app config and under a custom UiConfig.',
          child: Column(
            children: [
              HubCell(
                caption: 'Installed config (AppUiConfig at the app root)',
                child: ErrorView(error: _networkError, onRetry: () {}),
              ),
              HubCell(
                caption:
                    'Custom UiConfig(strings: UiStrings(retry: ...), errors: '
                    'UiErrors subclass returning UiErrorInfo)',
                child: UiConfig(
                  strings: const UiStrings(retry: 'Try again'),
                  errors: const _DemoErrors(),
                  child: ErrorView(error: _networkError, onRetry: () {}),
                ),
              ),
              HubCell(
                caption: 'AppUiConfig(child: ...) wrapping a subtree',
                child: AppUiConfig(
                  child: ErrorView(error: _serverError, onRetry: () {}),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Current | Proposed, one under the other.
Widget _pair(Widget current, Widget proposed) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Current', style: TextStyle(fontSize: 11)),
      const SizedBox(height: 2),
      current,
      const SizedBox(height: AppSpacing.xs),
      const Text(
        'Proposed',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 2),
      proposed,
    ],
  ),
);

class _None extends StatelessWidget {
  const _None(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
