import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';
import 'atoms_input_proposal.dart';

/// `/dev/atoms/input` — the one text input and its kinds / looks.
Widget buildInputPage(BuildContext context) => const _InputPage();

class _InputPage extends StatefulWidget {
  const _InputPage();

  @override
  State<_InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<_InputPage> {
  final _a = TextEditingController(text: 'กสิกร');
  final _b = TextEditingController();
  final _c = TextEditingController(text: 'บัญชีรับเงินเดือน');
  final _d = TextEditingController(text: 'ข้าวมันไก่');
  final _e = TextEditingController(text: '1,250');
  final _f = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    for (final c in [_a, _b, _c, _d, _e, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InputProposalSection(),
        Text(
          'Current reference — every kind as it is today',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        HubPlayground(
          title: 'AppInput (today)',
          note:
              'The current widget\'s real options: AppInput(...) field. The '
              'proposal above replaces the looks.',
          controls: [
            PlayChoice<AppInputLook>('look', [
              for (final l in AppInputLook.values) (l.name, l),
            ]),
            const PlayText('label', initialValue: 'Name'),
            const PlayText('hint', initialValue: 'Placeholder'),
            const PlayText('helper'),
            const PlayText('errorText'),
            const PlayText('prefixText'),
            const PlayBool('enabled', initialValue: true),
            const PlayBool('readOnly'),
            const PlayBool('obscurable'),
            const PlayBool('showCounter'),
            const PlayNum(
              'maxLength',
              min: 0,
              max: 100,
              step: 10,
              initialValue: 0,
            ),
            const PlayNum('maxLines', min: 1, max: 4, step: 1, initialValue: 1),
            PlayChoice<TextAlign>('textAlign', [
              ('start', TextAlign.start),
              ('end', TextAlign.end),
              ('center', TextAlign.center),
            ]),
          ],
          builder: (context, v) {
            String? text(String k) =>
                v<String>(k).isEmpty ? null : v<String>(k);
            final max = v<double>('maxLength').round();
            return AppInput(
              look: v<AppInputLook>('look'),
              label: text('label'),
              hint: text('hint'),
              helper: text('helper'),
              errorText: text('errorText'),
              prefixText: text('prefixText'),
              enabled: v<bool>('enabled'),
              readOnly: v<bool>('readOnly'),
              obscurable: v<bool>('obscurable'),
              showCounter: v<bool>('showCounter'),
              maxLength: max == 0 ? null : max,
              maxLines: v<double>('maxLines').round(),
              textAlign: v<TextAlign>('textAlign'),
            );
          },
        ),
        HubDemo(
          title: 'AppInput — field (filled)',
          note:
              'Forms, auth, dialogs: label, hint, helper, error, prefix / '
              'suffix, password toggle, counter.',
          child: Column(
            children: [
              AppInput(controller: _a, label: 'Name', hint: 'Wallet name'),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _b,
                label: 'Password',
                obscurable: true,
                prefixIcon: AppIcons.lock,
                helper: 'Helper text sits under the field',
              ),
              const SizedBox(height: AppSpacing.md),
              const AppInput(
                label: 'With error',
                errorText: 'This name is already taken',
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _c,
                label: 'Multi-line with counter',
                maxLines: 3,
                maxLength: 200,
                showCounter: true,
              ),
              const SizedBox(height: AppSpacing.md),
              const AppInput(label: 'Disabled', enabled: false),
            ],
          ),
        ),
        HubDemo(
          title: 'AppInput.inline — view ⇄ edit in one box',
          note:
              'A detail page’s text. View: borderless, read-only, long-press '
              'enters edit; empty shows the view hint. Edit: outlined.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: _editing ? 'Switch to view' : 'Switch to edit',
                variant: AppButtonVariant.outlined,
                onPressed: () => setState(() => _editing = !_editing),
              ),
              const SizedBox(height: AppSpacing.sm),
              DetailStacked(
                label: 'Note',
                child: AppInput.inline(
                  editing: _editing,
                  controller: _f,
                  hint: 'Add a note',
                  viewHint: 'Long-press to edit',
                  onEnterEdit: () => setState(() => _editing = true),
                  maxLines: 5,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AppInput.title — a hero’s name',
          note:
              'Plain text in view, underlined in edit — the same height both ways.',
          child: AppInput.title(
            editing: _editing,
            controller: _d,
            hint: 'Name',
            onEnterEdit: () => setState(() => _editing = true),
          ),
        ),
        HubDemo(
          title: 'AppInput.search',
          note:
              'Leading search icon, ✕ once there is text. outlined (a list’s top) or pill (in a sheet).',
          child: Column(
            children: [
              AppInput.search(onChanged: (_) {}, hint: 'Search'),
              const SizedBox(height: AppSpacing.sm),
              AppInput.search(
                onChanged: (_) {},
                hint: 'Search in a sheet',
                look: AppInputLook.pill,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Looks — underline · bare · outlined',
          note:
              'Rows that edit in place use underline (split name / amount, an '
              'identifier); a hero’s big amount and chat boxes are bare.',
          child: Column(
            children: [
              AppInput(
                controller: _e,
                look: AppInputLook.underline,
                textAlign: TextAlign.end,
                prefixText: '฿ ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppInput(look: AppInputLook.bare, hint: 'Bare — no chrome'),
              const SizedBox(height: AppSpacing.md),
              const AppInput(
                look: AppInputLook.outlined,
                hint: 'Outlined, small',
                maxLength: 7,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `/dev/atoms/button` — buttons, icon buttons, bulk delete.
Widget buildButtonPage(BuildContext context) => const _ButtonPage();

class _ButtonPage extends StatefulWidget {
  const _ButtonPage();

  @override
  State<_ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<_ButtonPage> {
  bool _loading = false;
  IconChipActivity _activity = IconChipActivity.none;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'AppButton',
          note: 'Every option AppButton has.',
          controls: [
            const PlayText('label', initialValue: 'Save'),
            PlayChoice<AppButtonVariant>('variant', [
              for (final v in AppButtonVariant.values) (v.name, v),
            ]),
            PlayChoice<AppButtonSize>('size', [
              for (final v in AppButtonSize.values) (v.name, v),
            ]),
            const PlayBool('icon'),
            const PlayBool('loading'),
            const PlayBool('expand'),
            const PlayBool('enabled', initialValue: true),
          ],
          builder: (context, v) => AppButton(
            label: v<String>('label'),
            variant: v<AppButtonVariant>('variant'),
            size: v<AppButtonSize>('size'),
            icon: v<bool>('icon') ? AppIcons.check : null,
            loading: v<bool>('loading'),
            expand: v<bool>('expand'),
            onPressed: v<bool>('enabled') ? () {} : null,
          ),
        ),
        HubPlayground(
          title: 'AppIconButton',
          note: 'The chip itself (the flat variants are in the demos below).',
          controls: [
            PlayChoice<IconData>('icon', [
              ('edit', AppIcons.edit),
              ('close', AppIcons.close),
              ('inbox', AppIcons.pending),
              ('bell', AppIcons.notifications),
              ('delete', AppIcons.delete),
            ]),
            const PlayNum(
              'badgeCount',
              min: 0,
              max: 120,
              step: 1,
              initialValue: 0,
            ),
            const PlayBool('selected'),
            const PlayBool('destructive'),
            const PlayNum('size', min: 32, max: 48, step: 4, initialValue: 40),
            PlayChoice<IconChipActivity>('activity', [
              for (final a in IconChipActivity.values) (a.name, a),
            ]),
            const PlayBool('enabled', initialValue: true),
          ],
          builder: (context, v) => AppIconButton(
            icon: v<IconData>('icon'),
            badgeCount: v<double>('badgeCount').round(),
            selected: v<bool>('selected'),
            destructive: v<bool>('destructive'),
            size: v<double>('size'),
            activity: v<IconChipActivity>('activity'),
            tooltip: 'Icon button',
            onPressed: v<bool>('enabled') ? () {} : null,
          ),
        ),
        const HubSubheading(
          'In the app',
          note: 'The real presets and where they are used.',
        ),
        HubDemo(
          title: 'AppButton — variants',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final v in AppButtonVariant.values)
                AppButton(label: v.name, variant: v, onPressed: () {}),
            ],
          ),
        ),
        HubDemo(
          title: 'States',
          note:
              'Disabled (onPressed null) and loading (spinner replaces the label).',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const AppButton(label: 'Disabled', onPressed: null),
              AppButton(label: 'Loading', loading: true, onPressed: () {}),
              AppButton(
                label: 'With icon',
                icon: AppIcons.add,
                onPressed: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Large, full width',
          child: AppButton(
            label: _loading ? 'Saving…' : 'Tap to fake a save',
            size: AppButtonSize.large,
            expand: true,
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _loading = false);
            },
          ),
        ),
        HubDemo(
          title: 'AppIconButton — activity',
          note: 'none · progress · done. Tap to cycle.',
          child: AppIconButton(
            icon: AppIcons.check,
            tooltip: 'Cycle',
            activity: _activity,
            onPressed: () => setState(
              () => _activity =
                  IconChipActivity.values[(_activity.index + 1) %
                      IconChipActivity.values.length],
            ),
          ),
        ),
        HubDemo(
          title: 'Edit ✏️ — AppIconButton.edit',
          note:
              "The round ✏️. Hero top row (32, level with the chips: HeaderCard, "
              "the transaction hero, the wallet hero) and a list header's "
              "\"enter edit / reorder mode\" (36: wallets, categories, tags). "
              "Null onPressed dims it.",
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              HubCell(
                caption: 'hero 32',
                child: AppIconButton.edit(
                  size: AppIconButton.sizeHero,
                  tooltip: 'Edit',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'list 36',
                child: AppIconButton.edit(tooltip: 'Edit', onPressed: () {}),
              ),
              const HubCell(
                caption: 'disabled',
                child: AppIconButton.edit(onPressed: null),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Edit-mode bar — Cancel · Save',
          note:
              'The two big buttons of the bottom bar in edit / reorder mode or '
              'a form (ModeActionBar, Molecules → Bars, adds Undo): an '
              'outlined Cancel and a filled Save, Save disabled until there '
              'is something to save, a spinner while saving. Used by every '
              'edit / reorder page and the create forms.',
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Save',
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Shell top-right buttons',
          note:
              "The top bar's chips, normal and \"current page\" (the page they "
              "open is on screen: primary-container fill + primary ring). "
              "Inbox ⏳ (pending drafts) and bell carry a count badge; the "
              "profile chip is an AppAvatarButton whose ring follows the "
              "avatar's own shape. Used by AppTopBar.",
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              HubCell(
                caption: 'inbox · normal',
                child: AppIconButton(
                  icon: AppIcons.pending,
                  badgeCount: 3,
                  tooltip: 'Pending',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'inbox · current',
                child: AppIconButton(
                  icon: AppIcons.pending,
                  badgeCount: 3,
                  selected: true,
                  tooltip: 'Pending',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'bell · normal',
                child: AppIconButton(
                  icon: AppIcons.notifications,
                  badgeCount: 12,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'bell · current',
                child: AppIconButton(
                  icon: AppIcons.notifications,
                  selected: true,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'profile · normal',
                child: AppAvatarButton(
                  tooltip: 'Profile',
                  onTap: () {},
                  child: const UserAvatar(displayName: 'Aom Chan', size: 32),
                ),
              ),
              HubCell(
                caption: 'profile · current',
                child: AppAvatarButton(
                  tooltip: 'Profile',
                  active: true,
                  onTap: () {},
                  child: const UserAvatar(displayName: 'Aom Chan', size: 32),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Flat icon buttons — close · clear · more · back · flat',
          note:
              'No chip: a plain 48 dp tap target. ✕ close (PickerSheet, '
              'SideSheet, the quick-create header, update banner, chat dial); '
              '✕ clear (remove a split / event / row, MessageBanner); ⋯ more '
              '(a member row); ← back; .flat for anything else (the 🗑 in a '
              'draft header). iconSize / color override the look; dense '
              'shrinks the target for inline use.',
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              HubCell(
                caption: 'close',
                child: AppIconButton.close(tooltip: 'Close', onPressed: () {}),
              ),
              HubCell(
                caption: 'clear',
                child: AppIconButton.clear(tooltip: 'Clear', onPressed: () {}),
              ),
              HubCell(
                caption: 'more',
                child: AppIconButton.more(tooltip: 'More', onPressed: () {}),
              ),
              HubCell(
                caption: 'back',
                child: AppIconButton.back(tooltip: 'Back', onPressed: () {}),
              ),
              HubCell(
                caption: 'flat 🗑 (error)',
                child: AppIconButton.flat(
                  icon: AppIcons.delete,
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Delete',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'dense, 18',
                child: AppIconButton.clear(
                  dense: true,
                  iconSize: 18,
                  onPressed: () {},
                ),
              ),
              const HubCell(
                caption: 'disabled',
                child: AppIconButton.close(onPressed: null),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'BulkDeleteButton',
          note: 'A red trash icon, no label — select toolbars.',
          child: BulkDeleteButton(tooltip: 'Delete', onPressed: () {}),
        ),
      ],
    );
  }
}
