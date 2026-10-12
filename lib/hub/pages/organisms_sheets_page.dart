import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/organisms/sheets` — bottom sheets, pickers, option / action menus
/// and the side sheet.
Widget buildSheetsPage(BuildContext context) => const _SheetsPage();

const _wallets = ['Cash', 'Savings', 'Credit card', 'Travel fund', 'Joint'];

const _currencies = <(String, String)>[
  ('THB', 'Thai baht'),
  ('USD', 'US dollar'),
  ('EUR', 'Euro'),
  ('JPY', 'Japanese yen'),
  ('GBP', 'Pound sterling'),
  ('SGD', 'Singapore dollar'),
  ('AUD', 'Australian dollar'),
  ('CNY', 'Chinese yuan'),
];

class _SheetsPage extends StatefulWidget {
  const _SheetsPage();

  @override
  State<_SheetsPage> createState() => _SheetsPageState();
}

class _SheetsPageState extends State<_SheetsPage> {
  String _wallet = 'Savings';
  String _currency = 'THB';
  String _sort = 'newest';
  String _result = 'nothing picked yet';

  void _say(Object? v) => setState(() => _result = '$v');

  Widget _demoButton(String label, VoidCallback onPressed) => AppButton(
    label: label,
    onPressed: onPressed,
    variant: AppButtonVariant.outlined,
  );

  Future<void> _standardSheet() => showAppSheet<void>(
    context,
    title: 'Sheet title',
    builder: (_) => const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppText('Body scrolls when tall; the footer stays pinned.'),
    ),
    footer: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Builder(
        builder: (ctx) => AppButton(
          label: 'Confirm',
          expand: true,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    ),
  );

  Future<void> _customSheet() => showAppSheetCustom<void>(
    context,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height,
      child: AppSheetScaffold(
        title: 'Full-height custom sheet',
        footer: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: 'Close',
            variant: AppButtonVariant.tonal,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppText('A sheet that builds its own AppSheetScaffold.'),
        ),
      ),
    ),
  );

  Future<void> _walletPicker({
    bool loading = false,
    Object? error,
    bool empty = false,
    bool create = false,
  }) {
    return showAppSheetCustom<void>(
      context,
      builder: (ctx) => PickerSheet(
        title: 'Choose wallet',
        searchable: !loading && error == null && !empty,
        searchHint: 'Search wallets',
        loading: loading,
        error: error,
        onRetry: error == null ? null : () => Navigator.of(ctx).pop(),
        footer: create
            ? PickerCreateRow(
                label: 'New wallet',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _say('create wallet');
                },
              )
            : null,
        builder: (context, query) {
          final rows = _wallets
              .where((w) => w.toLowerCase().contains(query))
              .toList();
          if (empty || rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: AppText('No wallets yet')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final w in rows)
                PickerRow(
                  title: w,
                  leading: const Icon(AppIcons.wallet),
                  subtitle: w == 'Credit card' ? 'Billing day 25' : null,
                  selected: w == _wallet,
                  onTap: () {
                    setState(() => _wallet = w);
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shortOptions() async {
    final v = await showOptionSheet<String>(
      context,
      title: 'Sort by',
      selected: _sort,
      options: const [
        SheetOption(value: 'newest', label: 'Newest first'),
        SheetOption(value: 'oldest', label: 'Oldest first'),
        SheetOption(value: 'amount', label: 'Amount'),
        SheetOption(value: 'locked', label: 'Disabled option', enabled: false),
      ],
    );
    if (v != null) setState(() => _sort = v);
  }

  Future<void> _longOptions() async {
    final v = await showOptionSheet<String>(
      context,
      title: 'Currency',
      searchable: true,
      selected: _currency,
      options: [
        for (final c in _currencies)
          SheetOption(value: c.$1, label: c.$1, subtitle: c.$2),
      ],
    );
    if (v != null) setState(() => _currency = v);
  }

  Future<void> _actions() async {
    final v = await showActionSheet<String>(
      context,
      header: const ActionSheetHeader(
        title: 'Savings',
        subtitle: 'Wallet - 12,400.00',
        leading: Icon(AppIcons.wallet),
      ),
      actions: const [
        SheetAction(value: 'edit', label: 'Edit', icon: AppIcons.edit),
        SheetAction(
          value: 'share',
          label: 'Share',
          subtitle: 'With your partner',
          icon: AppIcons.share,
        ),
        SheetAction(
          value: 'archive',
          label: 'Archive',
          icon: AppIcons.archive,
          enabled: false,
        ),
        SheetAction(
          value: 'delete',
          label: 'Delete',
          icon: AppIcons.delete,
          destructive: true,
        ),
      ],
    );
    if (v != null) _say('action: $v');
  }

  Future<void> _sideSheet() => showSideSheet<void>(
    context,
    builder: (ctx) => SideSheetScaffold(
      title: 'Filters',
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideSheetSection(
            title: 'Wallets',
            icon: AppIcons.wallet,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppChip(label: 'Cash', selected: true),
                AppChip(label: 'Savings'),
                AppChip(label: 'Credit card'),
              ],
            ),
          ),
          SideSheetSection(
            title: 'Type',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppChip(label: 'Income'),
                AppChip(label: 'Expense', selected: true),
              ],
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Reset',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: 'Apply',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubSubheading(
          'In the app',
          note: 'The real sheets and where they are used.',
        ),
        HubDemo(
          title: 'showAppDatePicker + AppDatePickerSheet',
          note:
              'THE date picker: a bottom sheet with a calendar — tapping a day '
              'picks it at once — plus "Today" and, when clearable, "Clear". '
              'Replaces the raw Material date picker. Resolves with '
              'AppDatePicked(date) / AppDateCleared / null (dismissed). Used by '
              'the quick-create date, the scheduled next billing, a goal '
              "deadline (clearable), a debt's payment date.",
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _demoButton('Pick a date', () async {
                final r = await showAppDatePicker(
                  context,
                  initial: DateTime.now(),
                );
                _say(r is AppDatePicked ? r.date : r);
              }),
              _demoButton('Deadline (clearable, future only)', () async {
                final now = DateTime.now();
                final r = await showAppDatePicker(
                  context,
                  initial: now.add(const Duration(days: 90)),
                  first: now,
                  last: DateTime(now.year + 20),
                  title: 'Deadline',
                  clearable: true,
                );
                _say(r is AppDatePicked ? r.date : r);
              }),
            ],
          ),
        ),
        HubDemo(
          title:
              'Sheets are organisms — the pattern (reference: the period sheet)',
          note:
              'Every sheet is SPLIT: a PRESENTATIONAL organism in lib/ui '
              '(layout + inputs; takes data, words and callbacks; imports '
              'nothing from features / cubits / repos) and a thin feature '
              'WRAPPER that reads the cubit / repo, maps its model + l10n in, '
              'and handles the result. Generic ones (no domain model) live in '
              'lib/ui/organisms, money / people / transaction ones in '
              'lib/ui/domain/…. Each is listed here with sample data and opens '
              'live. Reference: PeriodPickerSheet (wrapper: transactions '
              'period_sheet.dart).',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _demoButton('Period sheet (reference)', () async {
                final now = DateTime.now();
                final r = await showPeriodPickerSheet(
                  context,
                  current: PeriodPick(PeriodUnit.month, now),
                  labels: const PeriodPickerLabels(
                    title: 'Period',
                    weekHint: 'Any day picks its whole week',
                    day: 'Day',
                    week: 'Week',
                    month: 'Month',
                    year: 'Year',
                    all: 'All',
                    custom: 'Custom',
                  ),
                );
                _say(
                  r == null ? null : '${r.unit.name} ${r.start} ${r.end ?? ''}',
                );
              }),
            ],
          ),
        ),
        HubDemo(
          title: 'showAppDateRangePicker + AppDateRangePickerSheet',
          note:
              'THE date RANGE picker, same sheet look as the date picker: tap a '
              'day to start, another to end (tap again to start over), then '
              'Save. Optional preset chips above the calendar. Resolves with a '
              'DateTimeRange / null (dismissed). Used by the transactions '
              'custom period.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _demoButton('Pick a range', () async {
                final r = await showAppDateRangePicker(context);
                _say(r);
              }),
              _demoButton('With presets, up to today', () async {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final r = await showAppDateRangePicker(
                  context,
                  last: today,
                  initial: DateTimeRange(
                    start: today.subtract(const Duration(days: 6)),
                    end: today,
                  ),
                  presets: [
                    AppDateRangePreset(
                      'Last 7 days',
                      DateTimeRange(
                        start: today.subtract(const Duration(days: 6)),
                        end: today,
                      ),
                    ),
                    AppDateRangePreset(
                      'This month',
                      DateTimeRange(
                        start: DateTime(today.year, today.month),
                        end: today,
                      ),
                    ),
                  ],
                );
                _say(r);
              }),
            ],
          ),
        ),
        HubDemo(
          title: 'Picker rows — chevron · destructive · disabled create',
          note:
              'PickerRow(chevron: true) opens something further (a bank row); '
              'SheetOption(destructive: true) shows its label in the error '
              'colour (remove, leave); PickerCreateRow(onTap: null) is dimmed '
              '(while saving).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PickerRow(title: 'Kasikorn Bank', chevron: true, onTap: () {}),
              PickerRow(
                title: 'Leave wallet',
                titleStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                onTap: () {},
              ),
              const PickerCreateRow(label: 'New contact', onTap: null),
            ],
          ),
        ),
        HubDemo(
          title: 'Last result',
          note: 'What the sheets resolve with.',
          child: AppText(
            '$_result - wallet: $_wallet, currency: $_currency, sort: $_sort',
            role: AppTextRole.caption,
          ),
        ),
        HubDemo(
          title: 'AppSheetScaffold, showAppSheet, showAppSheetCustom',
          note:
              'The standard bottom sheet: drag handle, title, scrolling body, '
              'pinned footer. Custom = a sheet that builds its own scaffold.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'Title + footer',
                child: _demoButton('showAppSheet', _standardSheet),
              ),
              HubCell(
                caption: 'Full height',
                child: _demoButton('showAppSheetCustom', _customSheet),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PickerSheet, PickerRow, PickerCreateRow',
          note:
              'Searchable list on the picker shell. The selected row is '
              'highlighted, never ticked.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'Searchable, selected row',
                child: _demoButton('Picker', _walletPicker),
              ),
              HubCell(
                caption: 'Loading',
                child: _demoButton(
                  'Loading',
                  () => _walletPicker(loading: true),
                ),
              ),
              HubCell(
                caption: 'Error + retry',
                child: _demoButton(
                  'Error',
                  () => _walletPicker(
                    error: const ApiException(
                      code: 'NETWORK_ERROR',
                      message: 'Could not reach the server',
                    ),
                  ),
                ),
              ),
              HubCell(
                caption: 'Empty',
                child: _demoButton('Empty', () => _walletPicker(empty: true)),
              ),
              HubCell(
                caption: 'Footer create row',
                child: _demoButton(
                  'With create',
                  () => _walletPicker(create: true),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showOptionSheet, SheetOption',
          note: 'Single-select list; long lists add search and subtitles.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'Short list',
                child: _demoButton('Sort by', _shortOptions),
              ),
              HubCell(
                caption: 'Searchable, subtitles',
                child: _demoButton('Currency', _longOptions),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'SheetAction, ActionSheetHeader, showActionSheet',
          note: 'What do you want to do with this? Includes a destructive row.',
          child: HubCell(
            caption: 'Header + actions',
            child: _demoButton('Actions', _actions),
          ),
        ),
        HubDemo(
          title: 'SideSheetScaffold, SideSheetSection, showSideSheet',
          note: 'Settings of the screen behind it, e.g. filters.',
          child: HubCell(
            caption: 'From the right, two sections + footer',
            child: _demoButton('Filters', _sideSheet),
          ),
        ),

        HubPlayground(
          title: 'showAppSheet',
          note:
              'The standard bottom sheet: a title, a body that scrolls and an '
              'optional pinned footer. Set the options, then open it.',
          controls: [
            const PlayText('title', initialValue: 'Sheet title'),
            const PlayBool('footer', initialValue: true),
            const PlayNum(
              'bodyLines',
              min: 1,
              max: 40,
              step: 1,
              initialValue: 3,
            ),
          ],
          builder: (context, v) => Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Open the sheet',
              onPressed: () => showAppSheet<void>(
                context,
                title: v<String>('title').isEmpty ? null : v<String>('title'),
                builder: (_) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < v<double>('bodyLines').round(); i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: AppText('A line of the body.'),
                        ),
                    ],
                  ),
                ),
                footer: v<bool>('footer')
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Builder(
                          builder: (ctx) => AppButton(
                            label: 'Confirm',
                            expand: true,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
