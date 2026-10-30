import 'dart:async';

import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/ui/molecules/loading-states` — the loading rule (owner 2026-10-28):
/// only the PRESSED control shows loading (a spinner in place, same size and
/// position, presses ignored); controls that must not be used meanwhile are
/// just FADED ([AppOpacity.disabled]) and inert; unrelated controls stay
/// normal. No scrims. A [BusyScope] locks a region without per-field wiring.
Widget buildLoadingStatesPage(BuildContext context) =>
    const _LoadingStatesPage();

class _LoadingStatesPage extends StatelessWidget {
  const _LoadingStatesPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubDemo(
          title: 'The rule',
          note:
              '1 · The pressed control spins in place: same size, same '
              'place, its own colours, presses ignored (`loading: true`).\n'
              '2 · Controls that must not be used meanwhile are faded '
              '(AppOpacity.disabled = 0.38) and ignore input: wrap the '
              'region in BusyScope(busy: true). Inputs only fade (value '
              'readable, read-only), they never spin.\n'
              '3 · Everything else stays normal. No scrims, no overlays.\n'
              'Explicit flags win: `loading: true` spins inside a locked '
              'scope; a disabled control keeps its own disabled look.',
          child: SizedBox.shrink(),
        ),
        const HubDemo(
          title: 'Try it: a form with Save',
          note:
              'Tap Save: the button spins for 2 s, the form’s inputs and '
              'other buttons fade, the counter outside the form stays '
              'usable. Turn on “Fail the save” and the form comes back '
              'with the typed text kept, plus a retry message.',
          child: _FormDemo(),
        ),
        const HubDemo(
          title: 'Live setting (saves on flip)',
          note:
              'LiveSetting wraps its row in BusyScope.active while the save '
              'runs (1.5 s here): the switch / ▾ button / › spins, the row '
              'ignores taps, nothing else changes.',
          child: _LiveSettingDemo(),
        ),
        const HubSubheading(
          'Every control: normal · loading · faded',
          note:
              'Loading = `loading: true` (or a BusyScope.active above). '
              'Faded = inside BusyScope(busy: true). The three cells of a '
              'row are the same size; a geometry test pins it.',
        ),
        HubDemo(
          title: 'AppButton — every variant',
          child: _Triads(
            items: [
              for (final v in AppButtonVariant.values)
                _Item(
                  v.name,
                  (loading) => AppButton(
                    label: 'Save',
                    variant: v,
                    loading: loading,
                    onPressed: () {},
                  ),
                ),
              _Item(
                'icon + chip size',
                (loading) => AppButton(
                  label: 'Add',
                  icon: AppIcons.add,
                  size: AppButtonSize.chip,
                  loading: loading,
                  onPressed: () {},
                ),
              ),
              _Item(
                'large, full width',
                (loading) => SizedBox(
                  width: 160,
                  child: AppButton(
                    label: 'Save changes',
                    size: AppButtonSize.large,
                    expand: true,
                    loading: loading,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Icon buttons',
          child: _Triads(
            items: [
              _Item(
                'AppIconButton',
                (loading) => AppIconButton(
                  icon: AppIcons.share,
                  loading: loading,
                  onPressed: () {},
                ),
              ),
              _Item(
                '.edit',
                (loading) =>
                    AppIconButton.edit(loading: loading, onPressed: () {}),
              ),
              _Item(
                '.bare',
                (loading) => AppIconButton.bare(
                  icon: AppIcons.refresh,
                  loading: loading,
                  onPressed: () {},
                ),
              ),
              _Item(
                '.filled',
                (loading) => AppIconButton.filled(
                  icon: AppIcons.check,
                  loading: loading,
                  onPressed: () {},
                ),
              ),
              _Item(
                '.flat / .more',
                (loading) =>
                    AppIconButton.more(loading: loading, onPressed: () {}),
              ),
              _Item(
                'CheckCircleButton',
                (loading) => CheckCircleButton(
                  checked: true,
                  loading: loading,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AppChip — action and toggle chips',
          child: _Triads(
            items: [
              _Item(
                'action',
                (loading) => AppChip(
                  label: 'Pay now',
                  icon: AppIcons.check,
                  loading: loading,
                  onTap: () {},
                ),
              ),
              _Item(
                'toggle (selected)',
                (loading) => AppChip(
                  label: 'Monthly',
                  selected: true,
                  loading: loading,
                  onTap: () {},
                ),
              ),
              _Item(
                'dropdown, chip size',
                (loading) => AppChip(
                  label: 'Food',
                  size: ChipSize.chip,
                  trailing: AppChipTrailing.dropdown,
                  loading: loading,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AppSwitch',
          child: _Triads(
            items: [
              _Item(
                'on',
                (loading) =>
                    AppSwitch(value: true, loading: loading, onChanged: (_) {}),
              ),
              _Item(
                'off',
                (loading) => AppSwitch(
                  value: false,
                  loading: loading,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Rows: settings, detail, list, danger',
          note:
              'A row spins in the first of: › · its 🔒 icon · its value · '
              'its leading. A settings row spins its own control.',
          child: _RowTriads(
            items: [
              _Item(
                'SettingToggleRow',
                (loading) => SettingToggleRow(
                  label: 'Include in reports',
                  value: true,
                  loading: loading,
                  submits: false,
                  onChanged: (_) {},
                ),
              ),
              _Item(
                'SettingDropdownRow',
                (loading) => SettingDropdownRow<int>(
                  label: 'Week starts on',
                  value: 'Monday',
                  options: const [
                    SheetOption(value: 1, label: 'Monday'),
                    SheetOption(value: 7, label: 'Sunday'),
                  ],
                  selected: 1,
                  loading: loading,
                  submits: false,
                  onSelected: (_) {},
                ),
              ),
              _Item(
                'SettingMenuRow',
                (loading) => SettingMenuRow<int>(
                  label: 'Warn at',
                  value: '80%',
                  options: const [
                    SheetOption(value: 80, label: '80%'),
                    SheetOption(value: 90, label: '90%'),
                  ],
                  selected: 80,
                  loading: loading,
                  submits: false,
                  onSelected: (_) {},
                ),
              ),
              _Item(
                'SettingPickRow',
                (loading) => SettingPickRow(
                  label: 'Main wallet',
                  value: const Text('Cash'),
                  loading: loading,
                  submits: false,
                  onTap: () {},
                ),
              ),
              _Item(
                'AppDetailRow (tap + value)',
                (loading) => AppDetailRow(
                  label: 'Category',
                  icon: AppIcons.category,
                  trailing: const Text('Food'),
                  loading: loading,
                  onTap: () {},
                ),
              ),
              _Item(
                'AppListRow (tap + trailing + action)',
                (loading) => AppListRow(
                  leading: const Icon(AppIcons.wallet),
                  title: 'Groceries',
                  trailing: const ListRowTrailing.text('฿120'),
                  actions: [
                    ListRowAction.icon(
                      AppIcons.close,
                      loading: loading,
                      onTap: () {},
                    ),
                  ],
                  onTap: () {},
                ),
              ),
              _Item(
                'DangerRow',
                (loading) => DangerRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  padding: EdgeInsets.zero,
                  loading: loading,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Inputs: normal · faded (inputs never spin)',
          note:
              'Faded inputs keep their value readable and turn read-only; '
              'label and value fade together.',
          child: _RowTriads(
            inputs: true,
            items: [
              _Item(
                'AppInput',
                (_) => HubWithController(
                  initial: 'Lunch with Mint',
                  builder: (context, c) =>
                      AppInput(label: 'Description', controller: c),
                ),
              ),
              _Item(
                'AmountInput',
                (_) => HubWithController(
                  initial: '1,250',
                  builder: (context, c) =>
                      AmountInput(controller: c, currencySymbol: '฿'),
                ),
              ),
              _Item(
                'DetailTextField (edit mode)',
                (_) => HubWithController(
                  initial: 'Split with the team',
                  builder: (context, c) => DetailTextField(
                    label: 'Note',
                    controller: c,
                    editing: true,
                  ),
                ),
              ),
              _Item(
                'DatePickChip · SegmentedChoice · StepperPill',
                (_) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DatePickChip(date: DateTime(2026, 10, 28), onPick: () {}),
                    SegmentedChoice<int>(
                      segments: const [
                        ChoiceSegment(1, 'Expense'),
                        ChoiceSegment(2, 'Income'),
                      ],
                      selected: 1,
                      onChanged: (_) {},
                    ),
                    StepperPill(
                      label: 'Oct 2026',
                      onPrev: () {},
                      onNext: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        HubPlayground(
          title: 'Customize',
          hug: Alignment.centerLeft,
          controls: [
            PlayChoice<String>('piece', const [
              ('button', 'button'),
              ('icon', 'icon'),
              ('chip', 'chip'),
              ('switch', 'switch'),
              ('row', 'row'),
              ('input', 'input'),
            ]),
            PlayChoice<String>('state', const [
              ('normal', 'normal'),
              ('loading', 'loading'),
              ('faded (locked scope)', 'faded'),
              ('loading inside locked', 'both'),
            ]),
          ],
          builder: (context, v) {
            final state = v<String>('state');
            final loading = state == 'loading' || state == 'both';
            final Widget piece = switch (v<String>('piece')) {
              'icon' => AppIconButton(
                icon: AppIcons.share,
                loading: loading,
                onPressed: () {},
              ),
              'chip' => AppChip(
                label: 'Pay now',
                loading: loading,
                onTap: () {},
              ),
              'switch' => AppSwitch(
                value: true,
                loading: loading,
                onChanged: (_) {},
              ),
              'row' => SizedBox(
                width: 320,
                child: AppDetailRow(
                  label: 'Category',
                  trailing: const Text('Food'),
                  showChevron: true,
                  loading: loading,
                  onTap: () {},
                ),
              ),
              'input' => const SizedBox(
                width: 280,
                child: AppInput(label: 'Description', hint: 'Lunch'),
              ),
              _ => AppButton(label: 'Save', loading: loading, onPressed: () {}),
            };
            return BusyScope(
              busy: state == 'faded' || state == 'both',
              child: piece,
            );
          },
        ),
      ],
    );
  }
}

/// One demo piece: built normal (false) or loading (true).
class _Item {
  const _Item(this.label, this.build);
  final String label;
  final Widget Function(bool loading) build;
}

/// Small pieces: one line each, normal | loading | faded side by side.
class _Triads extends StatelessWidget {
  const _Triads({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: caption),
                const SizedBox(height: AppSpacing.xs),
                HubRow(
                  cells: [
                    HubCell(caption: 'normal', child: item.build(false)),
                    HubCell(caption: 'loading', child: item.build(true)),
                    HubCell(
                      caption: 'faded',
                      child: BusyScope(busy: true, child: item.build(false)),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Full-width pieces (rows, inputs): the states stacked in a card.
class _RowTriads extends StatelessWidget {
  const _RowTriads({required this.items, this.inputs = false});

  final List<_Item> items;

  /// Inputs: normal and faded only.
  final bool inputs;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    Widget labelled(String text, Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Text(text, style: caption),
          ),
          child,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SectionCard(
              first: true,
              title: item.label,
              children: [
                labelled('normal', item.build(false)),
                if (!inputs) labelled('loading', item.build(true)),
                labelled(
                  'faded',
                  BusyScope(busy: true, child: item.build(false)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A small edit form: Save spins 2 s while the rest of the form fades; a
/// counter outside the form keeps working.
class _FormDemo extends StatefulWidget {
  const _FormDemo();

  @override
  State<_FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<_FormDemo> {
  final _name = TextEditingController(text: 'Lunch with Mint');
  final _amount = TextEditingController(text: '450');
  bool _shared = true;
  int _kind = 1;
  bool _saving = false;
  bool _fail = false;
  int _outside = 0;
  String? _result;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _result = null;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = _fail
          ? 'Couldn’t save — your text is kept. Try again.'
          : 'Saved “${_name.text}”, ฿${_amount.text}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final failed = _result != null && _fail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Outside the form: never locked.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppChip(
              label: 'Unrelated counter: $_outside',
              icon: AppIcons.add,
              onTap: () => setState(() => _outside++),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSwitch(
                  value: _fail,
                  onChanged: (on) => setState(() => _fail = on),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text('Fail the save'),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        BusyScope(
          busy: _saving,
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInput(label: 'Description', controller: _name),
                  const SizedBox(height: AppSpacing.md),
                  AmountInput(controller: _amount, currencySymbol: '฿'),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedChoice<int>(
                    segments: const [
                      ChoiceSegment(1, 'Expense'),
                      ChoiceSegment(2, 'Income'),
                    ],
                    selected: _kind,
                    onChanged: (k) => setState(() => _kind = k),
                  ),
                  SettingToggleRow(
                    label: 'Split with friends',
                    value: _shared,
                    submits: false,
                    onChanged: (on) => setState(() => _shared = on),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.outlined,
                          expand: true,
                          onPressed: () => setState(() => _result = null),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: 'Save',
                          expand: true,
                          loading: _saving,
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_result case final r?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AppMessage(
              message: r,
              tone: failed ? Tone.danger : Tone.success,
            ),
          ),
      ],
    );
  }
}

/// A live switch and a live ▾ that "save" for 1.5 s.
class _LiveSettingDemo extends StatefulWidget {
  const _LiveSettingDemo();

  @override
  State<_LiveSettingDemo> createState() => _LiveSettingDemoState();
}

class _LiveSettingDemoState extends State<_LiveSettingDemo> {
  bool _on = true;
  int _day = 1;

  Future<bool> _wait() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      first: true,
      children: [
        LiveSetting<bool>(
          value: _on,
          save: (on) async {
            final ok = await _wait();
            if (mounted) setState(() => _on = on);
            return ok;
          },
          failedMessage: (e) => '$e',
          builder: (context, value, onChanged) => SettingToggleRow(
            label: 'Track balance',
            value: value,
            submits: false,
            onChanged: onChanged,
          ),
        ),
        LiveSetting<int>(
          value: _day,
          save: (d) async {
            final ok = await _wait();
            if (mounted) setState(() => _day = d);
            return ok;
          },
          failedMessage: (e) => '$e',
          builder: (context, value, onChanged) => SettingDropdownRow<int>(
            label: 'Week starts on',
            value: value == 1 ? 'Monday' : 'Sunday',
            options: const [
              SheetOption(value: 1, label: 'Monday'),
              SheetOption(value: 7, label: 'Sunday'),
            ],
            selected: value,
            submits: false,
            onSelected: onChanged,
          ),
        ),
      ],
    );
  }
}
