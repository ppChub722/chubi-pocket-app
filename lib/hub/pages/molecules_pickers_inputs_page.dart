import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/molecules/pickers-inputs` — pick cards, steppers, month / day
/// pickers, the amount input, chip rows, filter bar, theme chips, chat dial.
Widget buildPickersInputsPage(BuildContext context) =>
    const _PickersInputsPage();

class _PickersInputsPage extends StatefulWidget {
  const _PickersInputsPage();

  @override
  State<_PickersInputsPage> createState() => _PickersInputsPageState();
}

enum _Kind { expense, income, transfer }

class _PickersInputsPageState extends State<_PickersInputsPage> {
  // PickCard
  String? _wallet = 'Savings';

  // SelectCardGroup
  _Kind _kind = _Kind.expense;
  String _plan = 'monthly';

  // StepperPill
  int _step = 3;

  // MonthPill
  DateTime _month = DateTime(2026, 10);
  DateTime? _pickedMonth;

  // Day of month
  int? _day = 15;
  int? _gridDay;

  // AmountInput
  final _plain = TextEditingController(text: '1,250');
  final _fills = TextEditingController();
  final _negative = TextEditingController(text: '-300');
  final _accent = TextEditingController(text: '4,800');
  final _off = TextEditingController(text: '99');

  // ThemeModeChips
  ThemeMode _mode = ThemeMode.system;

  // SegmentedChoice
  String _notify = 'notify';

  // ChatDial
  String? _sent;

  @override
  void dispose() {
    for (final c in [_plain, _fills, _negative, _accent, _off]) {
      c.dispose();
    }
    super.dispose();
  }

  static const _toneOptions = [
    SelectCardOption<int>(
      value: 0,
      label: 'Expense',
      icon: AppIcons.expense,
      color: Colors.red,
    ),
    SelectCardOption<int>(
      value: 1,
      label: 'Income',
      icon: AppIcons.income,
      color: Colors.green,
    ),
    SelectCardOption<int>(
      value: 2,
      label: 'Transfer',
      icon: AppIcons.transfer,
      color: Colors.blueGrey,
    ),
    SelectCardOption<int>(
      value: 3,
      label: 'Primary',
      icon: AppIcons.check,
      description: 'No colour set',
    ),
  ];

  static const _selectSpecs = [
    _SelectSpec('Row · expense picked', 0, true, null, 2),
    _SelectSpec('Row · income picked', 1, true, null, 2),
    _SelectSpec('Row · transfer picked (neutral)', 2, true, null, 2, from: 2),
    _SelectSpec('Row · primary picked', 3, true, null, 2, from: 2),
    _SelectSpec(
      'Columns · expense / income / transfer / primary',
      2,
      true,
      2,
      4,
    ),
    _SelectSpec('Disabled + picked (read-only)', 0, false, null, 2),
    _SelectSpec('Disabled + picked · columns', 3, false, 2, 4),
  ];

  Widget _selectPair(_SelectSpec spec) => SelectCardGroup<int>(
    selected: spec.selected,
    columns: spec.columns,
    onChanged: spec.enabled ? (_) {} : null,
    options: _toneOptions.sublist(spec.from, spec.from + spec.count),
  );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubSubheading(
          'In the app',
          note: 'The real presets and where they are used.',
        ),
        HubDemo(
          title: 'PickCard — one height per variant',
          note:
              'Picking never adds a line or moves the layout. The 3-line '
              'variant (reserveSubtitle: wallet, category) keeps its subtitle '
              'line when empty, and shows the error there in red; the 2-line '
              'variant (plain) shows the error in place of the label. The '
              'dashed outline turns red. Nothing is added below the card.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '3 lines — empty · picked · error',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const PickCard(
                label: 'Wallet',
                placeholder: 'Choose a wallet',
                leading: PickCardEmptyIcon(AppIcons.wallet),
                reserveSubtitle: true,
                onTap: null,
              ),
              const SizedBox(height: AppSpacing.sm),
              PickCard(
                label: 'Wallet',
                value: 'Savings',
                accent: Colors.teal,
                leading: const PickCardEmptyIcon(AppIcons.wallet),
                subtitle: const Text('Balance 12,400'),
                reserveSubtitle: true,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              const PickCard(
                label: 'Wallet',
                placeholder: 'Choose a wallet',
                leading: PickCardEmptyIcon(AppIcons.wallet),
                errorText: 'Pick a wallet first',
                reserveSubtitle: true,
                onTap: null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '2 lines (plain) — empty · picked · error',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const PickCard(
                label: 'Payer',
                placeholder: 'Choose a member',
                leading: PickCardEmptyIcon(AppIcons.contact),
                onTap: null,
              ),
              const SizedBox(height: AppSpacing.sm),
              const PickCard(
                label: 'Payer',
                value: 'Aom',
                leading: PickCardEmptyIcon(AppIcons.contact),
                onTap: null,
              ),
              const SizedBox(height: AppSpacing.sm),
              const PickCard(
                label: 'Payer',
                placeholder: 'Choose a member',
                leading: PickCardEmptyIcon(AppIcons.contact),
                errorText: 'Pick who paid',
                onTap: null,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PickCard — interactive',
          note:
              'A form slot that opens a picker. Nothing picked: dashed '
              'outline with a muted empty icon. Picked: solid card, tinted '
              'when it has an accent, optional subtitle and watermark.',
          child: Column(
            children: [
              PickCard(
                label: 'Wallet',
                placeholder: 'Choose a wallet',
                leading: const PickCardEmptyIcon(AppIcons.wallet),
                value: _wallet,
                accent: Colors.teal,
                watermark: AppIcons.wallet,
                subtitle: const Text('Balance 12,400'),
                onTap: () => setState(
                  () => _wallet = _wallet == null ? 'Savings' : null,
                ),
              ),
              gap,
              const PickCard(
                label: 'Category (plain, no accent)',
                value: 'Food',
                leading: PickCardEmptyIcon(AppIcons.category, size: 32),
                dense: true,
                onTap: null,
              ),
              gap,
              PickCard(
                label: 'Wallet',
                placeholder: 'Choose a wallet',
                leading: const PickCardEmptyIcon(AppIcons.wallet),
                errorText: 'Pick a wallet first',
                onTap: () {},
              ),
              gap,
              PickCard(
                label: 'Date',
                value: '12 Oct 2026',
                leading: const PickCardEmptyIcon(AppIcons.date),
                trailing: const Icon(AppIcons.chevronRight),
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xs),
              const AppText(
                'Tap the first card to toggle empty / picked.',
                role: AppTextRole.caption,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'SelectCardGroup — every tone and layout (selected look)',
          note:
              'ONE selected look (owner 2026-10-12): a 2-px border in the '
              "option's tone + a faint wash of it (a gradient, top-left to "
              'bottom-right, like the tinted hero / card surface, no watermark), '
              'label and icon in the tone (darkened in light mode until they '
              'read). Picked but read-only = the same, dimmed. Used by: wallet '
              'type (account detail), debt direction (debt form), schedule '
              'variant and billing cycle (scheduled form). Expense red, income '
              'green, transfer neutral, primary — row and columns. Use the '
              'toolbar for light / dark and every theme.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final spec in _selectSpecs) ...[
                Text(spec.title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                _selectPair(spec),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'SelectCardGroup — interactive',
          note:
              'Pick one of a few. Default: one row, icon beside text. '
              'columns: stacked cards, icon above, wrapping into rows.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectCardGroup<_Kind>(
                selected: _kind,
                onChanged: (v) => setState(() => _kind = v),
                options: const [
                  SelectCardOption(
                    value: _Kind.expense,
                    label: 'Expense',
                    icon: AppIcons.expense,
                    color: Colors.red,
                  ),
                  SelectCardOption(
                    value: _Kind.income,
                    label: 'Income',
                    icon: AppIcons.income,
                    color: Colors.green,
                  ),
                ],
              ),
              gap,
              SelectCardGroup<_Kind>(
                selected: _kind,
                columns: 3,
                onChanged: (v) => setState(() => _kind = v),
                options: const [
                  SelectCardOption(
                    value: _Kind.expense,
                    label: 'Expense',
                    icon: AppIcons.expense,
                    color: Colors.red,
                  ),
                  SelectCardOption(
                    value: _Kind.income,
                    label: 'Income',
                    icon: AppIcons.income,
                    color: Colors.green,
                  ),
                  SelectCardOption(
                    value: _Kind.transfer,
                    label: 'Transfer',
                    icon: AppIcons.transfer,
                  ),
                ],
              ),
              gap,
              SelectCardGroup<String>(
                selected: _plan,
                onChanged: (v) => setState(() => _plan = v),
                options: const [
                  SelectCardOption(
                    value: 'monthly',
                    label: 'Monthly',
                    description: 'Every month',
                  ),
                  SelectCardOption(
                    value: 'weekly',
                    label: 'Weekly',
                    description: 'Every week',
                  ),
                ],
              ),
              gap,
              const SelectCardGroup<String>(
                selected: 'a',
                onChanged: null,
                options: [
                  SelectCardOption(value: 'a', label: 'Disabled (picked)'),
                  SelectCardOption(value: 'b', label: 'Disabled'),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'StepperPill',
          note:
              'The ‹ label ▾ › stepper. Arrows appear when onPrev / onNext '
              'is set (a null side is disabled); the ▾ appears when onTap is '
              'set.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'Both enabled + tap',
                child: StepperPill(
                  label: 'Step $_step',
                  onPrev: () => setState(() => _step--),
                  onNext: () => setState(() => _step++),
                  onTap: () {},
                ),
              ),
              const HubCell(
                caption: 'Prev disabled',
                child: StepperPill(label: 'First', onNext: _noop),
              ),
              const HubCell(
                caption: 'Next disabled',
                child: StepperPill(label: 'Last', onPrev: _noop),
              ),
              HubCell(
                caption: 'No arrows, with ▾',
                child: StepperPill(label: 'All wallets', onTap: () {}),
              ),
              const HubCell(
                caption: 'No arrows, no tap',
                child: StepperPill(label: 'Static'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'StepperPill presets + MonthPickerGrid + showMonthPicker',
          note:
              'One pill for every period. StepperPill.month steps by month and opens '
              'the picker on tap; StepperPill.period does the same for a week '
              '(Mon–Sun) and a year (budgets). first / last bound the arrows. '
              'The grid is the picker sheet body.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HubRow(
                cells: [
                  HubCell(
                    caption: 'Unbounded',
                    child: StepperPill.month(
                      value: _month,
                      onChanged: (m) => setState(() => _month = m),
                    ),
                  ),
                  HubCell(
                    caption: 'Bounded Aug-Dec 2026',
                    child: StepperPill.month(
                      value: _month,
                      first: DateTime(2026, 8),
                      last: DateTime(2026, 12),
                      onChanged: (m) => setState(() => _month = m),
                    ),
                  ),
                ],
              ),
              gap,
              HubRow(
                cells: [
                  HubCell(
                    caption: 'Week (Mon–Sun)',
                    child: StepperPill.period(
                      unit: StepperUnit.week,
                      value: _month,
                      onChanged: (m) => setState(() => _month = m),
                    ),
                  ),
                  HubCell(
                    caption: 'Year',
                    child: StepperPill.period(
                      unit: StepperUnit.year,
                      value: _month,
                      last: DateTime(2027),
                      onChanged: (m) => setState(() => _month = m),
                    ),
                  ),
                ],
              ),
              gap,
              Row(
                children: [
                  AppButton(
                    label: 'showMonthPicker',
                    variant: AppButtonVariant.tonal,
                    onPressed: () async {
                      final m = await showMonthPicker(
                        context,
                        selected: _month,
                      );
                      if (m != null) setState(() => _pickedMonth = m);
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppText(
                      _pickedMonth == null
                          ? 'Result: not picked yet'
                          : 'Result: ${_pickedMonth!.year}-'
                                '${_pickedMonth!.month}',
                      role: AppTextRole.caption,
                    ),
                  ),
                ],
              ),
              gap,
              const AppText(
                'MonthPickerGrid (inline, bounded Jun 2026 - Mar 2027)',
                role: AppTextRole.caption,
              ),
              MonthPickerGrid(
                selected: _month,
                first: DateTime(2026, 6),
                last: DateTime(2027, 3),
                onPicked: (m) => setState(() => _month = m),
              ),
            ],
          ),
        ),
        HubDemo(
          title:
              'DayOfMonthGrid + showDayOfMonthPicker + dayOfMonthLabel '
              '(+ DayOfMonthPick)',
          note:
              'A day 1-30, "last day" (31) and optionally "none" (null). '
              'The sheet resolves to a DayOfMonthPick, null = dismissed.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppButton(
                    label: 'showDayOfMonthPicker',
                    variant: AppButtonVariant.tonal,
                    onPressed: () async {
                      final DayOfMonthPick? r = await showDayOfMonthPicker(
                        context,
                        title: 'Statement day',
                        selected: _day,
                      );
                      if (r != null) setState(() => _day = r.day);
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppText(
                      dayOfMonthLabel(context, _day),
                      role: AppTextRole.label,
                    ),
                  ),
                ],
              ),
              gap,
              HubRow(
                cells: [
                  HubCell(
                    caption: 'dayOfMonthLabel(null)',
                    child: AppText(dayOfMonthLabel(context, null)),
                  ),
                  HubCell(
                    caption: 'dayOfMonthLabel(5)',
                    child: AppText(dayOfMonthLabel(context, 5)),
                  ),
                  HubCell(
                    caption: 'dayOfMonthLabel(kLastDayOfMonth)',
                    child: AppText(dayOfMonthLabel(context, kLastDayOfMonth)),
                  ),
                ],
              ),
              gap,
              const AppText(
                'DayOfMonthGrid (allowNone: true)',
                role: AppTextRole.caption,
              ),
              DayOfMonthGrid(
                selected: _gridDay,
                onPicked: (d) => setState(() => _gridDay = d),
              ),
              gap,
              const AppText(
                'DayOfMonthGrid (allowNone: false)',
                role: AppTextRole.caption,
              ),
              DayOfMonthGrid(
                selected: _gridDay ?? 1,
                allowNone: false,
                onPicked: (d) => setState(() => _gridDay = d),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AmountInput + AmountQuickFill + ThousandsInputFormatter',
          note:
              'The big amount field: thousands grouping as you type, '
              'optional quick-fill chips, a +/- toggle with allowNegative, '
              'an accent colour. AmountInput.parse / .format convert text '
              'and number. ThousandsInputFormatter is the formatter inside '
              'it.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountInput(controller: _plain, label: 'Amount'),
              gap,
              AmountInput(
                controller: _fills,
                label: 'With quick fills',
                quickFills: const [
                  AmountQuickFill(label: '+100', amount: 100),
                  AmountQuickFill(label: '+500', amount: 500),
                  AmountQuickFill(label: '+1,000', amount: 1000),
                ],
              ),
              gap,
              AmountInput(
                controller: _negative,
                label: 'allowNegative: true',
                allowNegative: true,
              ),
              gap,
              AmountInput(
                controller: _accent,
                label: 'Accent colour',
                accent: Colors.teal,
                quickFills: const [
                  AmountQuickFill(label: '500', amount: 500),
                  AmountQuickFill(label: '1,000', amount: 1000),
                ],
              ),
              gap,
              AmountInput(controller: _off, label: 'Disabled', enabled: false),
              gap,
              ListenableBuilder(
                listenable: _plain,
                builder: (_, _) => AppText(
                  'parse("${_plain.text}") = '
                  '${AmountInput.parse(_plain.text)}'
                  ' / format(1234.5) = ${AmountInput.format(1234.5)}',
                  role: AppTextRole.caption,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ThemeModeChips',
          note: 'Light / dark / system, with their icons.',
          child: ThemeModeChips(
            selected: _mode,
            onChanged: (m) => setState(() => _mode = m),
            lightLabel: 'Light',
            darkLabel: 'Dark',
            systemLabel: 'System',
          ),
        ),
        HubDemo(
          title: 'SegmentedChoice',
          note:
              'Pick one of 2-4 short options (notification settings: off / '
              'notify / auto). The chosen one is highlighted.',
          child: SegmentedChoice<String>(
            selected: _notify,
            onChanged: (v) => setState(() => _notify = v),
            segments: const [
              ChoiceSegment('off', 'Off'),
              ChoiceSegment('notify', 'Notify'),
              ChoiceSegment('auto', 'Auto'),
            ],
          ),
        ),
        HubDemo(
          title: 'ChatDial',
          note:
              'A floating button that grows into a one-line chat input '
              '(close and send). Normally a Scaffold floating action button; '
              'shown here in a fixed box with a set openWidth.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ChatDial(
                    hint: 'Type e.g. Coffee 65',
                    tooltip: 'Quick add',
                    sendTooltip: 'Send',
                    closeTooltip: 'Close',
                    openWidth: 320,
                    onSend: (t) => setState(() => _sent = t),
                  ),
                ),
              ),
              AppText(
                _sent == null ? 'Sent: nothing yet' : 'Sent: $_sent',
                role: AppTextRole.caption,
              ),
            ],
          ),
        ),

        HubPlayground(
          title: 'PickCard',
          note:
              'Every option PickCard has. reserveSubtitle keeps one height '
              'per variant when only some options show a subtitle.',
          controls: [
            const PlayBool('picked', initialValue: true),
            PlayChoice<Color?>('accent', [
              ('none', null),
              ('teal', Colors.teal),
              ('red', Colors.red),
              ('indigo', Colors.indigo),
            ]),
            const PlayBool('subtitle', initialValue: true),
            const PlayBool('watermark'),
            const PlayBool('dense'),
            const PlayBool('reserveSubtitle'),
            const PlayText('errorText'),
          ],
          builder: (context, v) => PickCard(
            label: 'Wallet',
            placeholder: 'Choose a wallet',
            leading: const PickCardEmptyIcon(AppIcons.wallet),
            value: v<bool>('picked') ? 'Savings' : null,
            accent: v<Color?>('accent'),
            subtitle: v<bool>('subtitle') ? const Text('Balance 12,400') : null,
            watermark: v<bool>('watermark') ? AppIcons.wallet : null,
            dense: v<bool>('dense'),
            reserveSubtitle: v<bool>('reserveSubtitle'),
            errorText: v<String>('errorText').isEmpty
                ? null
                : v<String>('errorText'),
            onTap: () {},
          ),
        ),
        HubPlayground(
          title: 'SelectCardGroup',
          note: 'One selected look; read-only = onChanged null.',
          controls: [
            PlayChoice<int>('selected', [
              ('expense', 0),
              ('income', 1),
              ('transfer', 2),
              ('primary', 3),
            ]),
            PlayChoice<int?>('columns', [('row', null), ('2', 2), ('3', 3)]),
            const PlayBool('readOnly'),
          ],
          builder: (context, v) => SelectCardGroup<int>(
            selected: v<int>('selected'),
            columns: v<int?>('columns'),
            onChanged: v<bool>('readOnly') ? null : (_) {},
            options: _toneOptions,
          ),
        ),
        HubPlayground(
          title: 'StepperPill',
          hug: Alignment.center,
          note:
              'The period presets (tap the arrows; month also taps open the picker).',
          controls: [
            PlayChoice<StepperUnit>('unit', [
              for (final u in StepperUnit.values) (u.name, u),
            ]),
            const PlayBool('bounded'),
          ],
          builder: (context, v) => HubStateful<DateTime>(
            initial: DateTime(2026, 10, 14),
            builder: (context, value, set) => StepperPill.period(
              unit: v<StepperUnit>('unit'),
              value: value,
              first: v<bool>('bounded') ? DateTime(2026, 8) : null,
              last: v<bool>('bounded') ? DateTime(2026, 12) : null,
              onChanged: set,
            ),
          ),
        ),
        HubPlayground(
          title: 'AmountInput',
          controls: [
            const PlayText('label', initialValue: 'Amount'),
            const PlayBool('quickFills'),
            const PlayBool('allowNegative'),
            const PlayBool('enabled', initialValue: true),
            PlayChoice<Color?>('accent', [
              ('none', null),
              ('expense', Colors.red),
              ('income', Colors.green),
            ]),
          ],
          builder: (context, v) => HubWithController(
            initial: '1,250',
            builder: (context, c) => AmountInput(
              controller: c,
              label: v<String>('label').isEmpty ? null : v<String>('label'),
              enabled: v<bool>('enabled'),
              allowNegative: v<bool>('allowNegative'),
              accent: v<Color?>('accent'),
              quickFills: v<bool>('quickFills')
                  ? const [
                      AmountQuickFill(label: '+100', amount: 100),
                      AmountQuickFill(label: '+500', amount: 500),
                    ]
                  : const [],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectSpec {
  const _SelectSpec(
    this.title,
    this.selected,
    this.enabled,
    this.columns,
    this.count, {
    this.from = 0,
  });

  final String title;

  /// The option value that is picked (an absolute value of _toneOptions).
  final int selected;
  final bool enabled;
  final int? columns;
  final int count;
  final int from;
}

void _noop() {}
