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

  /// The linked-record prompt (save, or delete with a red both-sides).
  Future<void> _linked({required bool delete}) async {
    final v = await showLinkedPrompt(
      context,
      title: delete
          ? 'Delete the linked item too?'
          : 'Update the other side too?',
      message: 'This transaction is linked to "Netflix | 3/12".',
      cancelLabel: 'Not now',
      thisSideLabel: delete ? 'Delete this side only' : 'Save this side only',
      bothSidesLabel: delete ? 'Delete both' : 'Save and update the other side',
      destructive: delete,
    );
    if (mounted) setState(() => _result = 'Linked prompt resolved: $v');
  }

  static const _allScopes = {
    EditScope.thisOne: 'This item',
    EditScope.following: 'This and the following',
    EditScope.past: 'All past items',
    EditScope.upcoming: 'All upcoming items',
    EditScope.all: 'All items',
  };

  /// "Apply to…" — the five scopes, or two for a rule change.
  Future<void> _scope({required bool all}) async {
    final v = await showEditScopeChoice(
      context,
      title: 'Apply to',
      options: all
          ? _allScopes
          : {
              EditScope.upcoming: _allScopes[EditScope.upcoming]!,
              EditScope.all: _allScopes[EditScope.all]!,
            },
    );
    if (mounted) setState(() => _result = 'Edit scope resolved: $v');
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
        const HubSubheading(
          'In the app',
          note: 'The real presets and where they are used.',
        ),
        HubDemo(
          title: 'ProgressRow: today and warn lines',
          note:
              'marker (the pace, "today") and alert (the warn point) are lines on '
              'the bar; markerLabel / alertLabel name them above it. When the two '
              'are too close for both, only the alert\'s label shows.',
          child: Builder(
            builder: (context) => ProgressRow(
              value: 0.42,
              marker: 0.61,
              markerLabel: 'Today',
              alert: 0.8,
              alertColor: Theme.of(context).extension<AppColors>()!.warning,
              alertLabel: 'Warn',
              label: 'Used ฿840',
              trailing: 'Up to ฿1,226 by today',
            ),
          ),
        ),
        HubDemo(
          title: 'ProgressRow: markerBubble (always shown)',
          note:
              'markerBubble shows over the marker all the time, in the bar\'s '
              'color, and replaces the small labels. Near an edge it slides '
              'inside the row; its arrow stays on the line.',
          child: Builder(
            builder: (context) {
              final palette = Theme.of(context).extension<AppColors>()!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProgressRow(
                    value: 0,
                    marker: 0.65,
                    markerBubble: 'Plan to date ฿1,300',
                    label: 'Used ฿0 of ฿2,000',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ProgressRow(
                    value: 0.87,
                    marker: 0.65,
                    markerBubble: 'Plan to date ฿3,250',
                    color: palette.warning,
                    label: 'Used ฿4,350 of ฿5,000',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ProgressRow(
                    value: 1.1,
                    marker: 0.95,
                    markerBubble: 'Plan to date ฿2,850',
                    overColor: palette.expense,
                    label: 'Used ฿3,300 of ฿3,000',
                  ),
                ],
              );
            },
          ),
        ),
        const HubDemo(
          title: 'ProgressRow: fillDot + markerBubble + endLabel',
          note:
              'The event budget bar: a dot on the end of the fill, what\'s '
              'spent in a bubble over it (marker = the fill), and the whole '
              'budget at the bar\'s right end, on its line.',
          child: ProgressRow(
            value: 0.59,
            fillDot: true,
            marker: 0.59,
            markerBubble: '฿11,740',
            endLabel: '฿20,000',
          ),
        ),
        HubDemo(
          title: 'ProgressRow: fillLabel (on the fill\'s end)',
          note:
              'A pill in the bar\'s color sitting on the end of the fill '
              '(the saving goals list: ━━━(31%)───). It moves with the fill '
              'and stays inside the bar\'s width at 0% and 100%.',
          child: Builder(
            builder: (context) {
              final palette = Theme.of(context).extension<AppColors>()!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProgressRow(value: 0, fillLabel: '0%'),
                  const SizedBox(height: AppSpacing.md),
                  ProgressRow(
                    value: 0.31,
                    color: palette.warning,
                    fillLabel: '31%',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const ProgressRow(value: 1, fillLabel: '100%'),
                ],
              );
            },
          ),
        ),
        HubDemo(
          title: 'ConnectionBanner — connecting, can\'t connect, back',
          note:
              'connecting = info tone + spinner, no button; can\'t connect = '
              'danger + Retry; both end with a plain X (onClose) that only '
              'hides the banner. Icon, text, action and X share one centre '
              'line with even padding (AppMessage).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in ConnectionBannerState.values) ...[
                ConnectionBanner(
                  state: s,
                  offlineText: 'Can\'t reach the server',
                  reconnectingText: 'Connecting… 1/6',
                  backText: 'Connected again',
                  retryLabel: 'Retry',
                  onRetry: () {},
                  onClose: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'AppMessage — icon override',
          note:
              'icon: replaces the tone\'s icon (a lock on a "locked" banner); the '
              'colour stays the tone\'s.',
          child: const AppMessage(
            message: 'This wallet is shared — only its owner can change it',
            tone: Tone.warning,
            icon: AppIcons.lock,
          ),
        ),
        HubDemo(
          title: 'AppMessage — banner and snackbar, one design',
          note:
              'The snackbar and the banner share ONE body — the same tone '
              'colours, icon set, radius, padding and type; only placement and '
              'lifetime differ. Banner: inline, stays until resolved or closed, '
              '1–2 actions. Snackbar: floats at the bottom, auto-dismisses, at '
              'most 1 action. Just happened → snackbar; still true → banner. '
              'Banners: login errors, "no connection", the update banner. '
              'Snackbars: every save / delete / undo, error + Retry.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in [
                Tone.info,
                Tone.success,
                Tone.warning,
                Tone.danger,
              ]) ...[
                AppMessage(message: 'Tone ${t.name}, text only', tone: t),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppMessage(
                message: 'No connection — changes are kept on this device',
                tone: Tone.warning,
                onClose: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              AppMessage(
                message: 'Could not load wallets',
                tone: Tone.danger,
                actions: [AppMessageAction(label: 'Retry', onPressed: () {})],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppMessage(
                message: 'Update available — a new version is ready to install',
                tone: Tone.info,
                onClose: () {},
                actions: [
                  AppMessageAction(label: 'Later', onPressed: () {}),
                  AppMessageAction(label: 'Update', onPressed: () {}),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Snackbar', style: Theme.of(context).textTheme.labelLarge),
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
                    label: 'Show: success + Undo',
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
                    label: 'Show: error + Retry',
                    variant: AppButtonVariant.tonal,
                    onPressed: () => showAppSnackBar(
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
          title: 'showConfirmDialog / showChoiceDialog / showLinkedPrompt',
          note:
              'Confirm: two ways out, resolves a bool. Choice: three or more '
              'stacked buttons, resolves the picked value or null. Linked '
              'prompt (owner 2026-10-13): a tx and the event bill / '
              'recurring item it is linked to never sync by themselves — at '
              'save / delete the app asks [Not now] [This side only] '
              '[Both]; resolves a LinkedChoice or null (cancel).',
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
                  AppButton(
                    label: 'Linked prompt (save)',
                    variant: AppButtonVariant.tonal,
                    onPressed: () => _linked(delete: false),
                  ),
                  AppButton(
                    label: 'Linked prompt (delete)',
                    variant: AppButtonVariant.destructiveOutlined,
                    onPressed: () => _linked(delete: true),
                  ),
                ],
              ),
              gap,
              AppText(_result, role: AppTextRole.caption),
            ],
          ),
        ),
        HubDemo(
          title: 'showEditScopeChoice — which items an edit applies to',
          note:
              'A central popover with a muted title (owner 2026-10-13): one '
              'row per EditScope passed, in that order; the selected one '
              'highlighted, never ✓. Resolves the scope or null. Recurring '
              'items pass all five; a recurring rule change passes upcoming '
              '/ all. Labels come in as params.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HubCell(
                caption: 'Inline (EditScopeChoice), selected: upcoming',
                child: EditScopeChoice(
                  title: 'Apply to',
                  options: _allScopes,
                  selected: EditScope.upcoming,
                  onPicked: (s) => setState(() => _result = 'Picked: $s'),
                ),
              ),
              gap,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Five scopes',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _scope(all: true),
                  ),
                  AppButton(
                    label: 'Rule change (two)',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _scope(all: false),
                  ),
                ],
              ),
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

        HubPlayground(
          title: 'AppMessage',
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
      ],
    );
  }
}
