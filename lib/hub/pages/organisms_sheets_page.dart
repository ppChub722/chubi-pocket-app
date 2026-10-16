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

  Widget _demoButton(String label, VoidCallback onPressed) => PpForgeButton(
    label: label,
    onPressed: onPressed,
    variant: PpForgeButtonVariant.outlined,
  );

  Future<void> _standardSheet() => showPpForgeSheet<void>(
    context,
    title: 'Sheet title',
    builder: (_) => const Padding(
      padding: EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
      child: PpForgeText('Body scrolls when tall; the footer stays pinned.'),
    ),
    footer: Padding(
      padding: const EdgeInsets.all(PpForgeSpacing.lg),
      child: Builder(
        builder: (ctx) => PpForgeButton(
          label: 'Confirm',
          expand: true,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    ),
  );

  Future<void> _customSheet() => showPpForgeSheetCustom<void>(
    context,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height,
      child: PpForgeSheetScaffold(
        title: 'Full-height custom sheet',
        footer: Padding(
          padding: const EdgeInsets.all(PpForgeSpacing.lg),
          child: PpForgeButton(
            label: 'Close',
            variant: PpForgeButtonVariant.tonal,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
          child: PpForgeText(
            'A sheet that builds its own PpForgeSheetScaffold.',
          ),
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
    return showPpForgeSheetCustom<void>(
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
              padding: EdgeInsets.all(PpForgeSpacing.xxl),
              child: Center(child: PpForgeText('No wallets yet')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final w in rows)
                PickerRow(
                  title: w,
                  leading: const Icon(PpForgeIcons.wallet),
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

  /// Multi-select: rows with a square check, the count on the confirm.
  Future<void> _multiPicker() async {
    const bills = ['Dinner', 'Taxi', 'Hotel', 'Snacks', 'Tickets'];
    final picked = <String>{};
    final added = await showPpForgeSheetCustom<Set<String>>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => PickerSheet(
          title: 'Add bills',
          searchable: true,
          footer: PickerConfirmBar(
            label: 'Add (${picked.length})',
            onPressed: picked.isEmpty
                ? null
                : () => Navigator.of(ctx).pop({...picked}),
          ),
          builder: (context, query) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final b in bills.where(
                (b) => b.toLowerCase().contains(query),
              ))
                PickerRow(
                  title: b,
                  subtitle: '฿240 · 12 Oct',
                  checked: picked.contains(b),
                  onTap: () => setSheet(
                    () => picked.contains(b) ? picked.remove(b) : picked.add(b),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (added != null) _say('added ${added.join(', ')}');
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
        leading: Icon(PpForgeIcons.wallet),
      ),
      actions: const [
        SheetAction(value: 'edit', label: 'Edit', icon: PpForgeIcons.edit),
        SheetAction(
          value: 'share',
          label: 'Share',
          subtitle: 'With your partner',
          icon: PpForgeIcons.share,
        ),
        SheetAction(
          value: 'archive',
          label: 'Archive',
          icon: PpForgeIcons.archive,
          enabled: false,
        ),
        SheetAction(
          value: 'delete',
          label: 'Delete',
          icon: PpForgeIcons.delete,
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
            icon: PpForgeIcons.wallet,
            child: Wrap(
              spacing: PpForgeSpacing.sm,
              runSpacing: PpForgeSpacing.sm,
              children: [
                PpForgeChip(label: 'Cash', selected: true),
                PpForgeChip(label: 'Savings'),
                PpForgeChip(label: 'Credit card'),
              ],
            ),
          ),
          SideSheetSection(
            title: 'Type',
            child: Wrap(
              spacing: PpForgeSpacing.sm,
              runSpacing: PpForgeSpacing.sm,
              children: [
                PpForgeChip(label: 'Income'),
                PpForgeChip(label: 'Expense', selected: true),
              ],
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: PpForgeButton(
              label: 'Reset',
              variant: PpForgeButtonVariant.outlined,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          const SizedBox(width: PpForgeSpacing.md),
          Expanded(
            child: PpForgeButton(
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
          title: 'showPpForgeDatePicker + PpForgeDatePickerSheet',
          note:
              'THE date picker: a bottom sheet with a calendar — tapping a day '
              'picks it at once — plus "Today" and, when clearable, "Clear". '
              'Replaces the raw Material date picker. Resolves with '
              'PpForgeDatePicked(date) / PpForgeDateCleared / null (dismissed). Used by '
              'the quick-create date, the scheduled next billing, a goal '
              "deadline (clearable), a debt's payment date.",
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              _demoButton('Pick a date', () async {
                final r = await showPpForgeDatePicker(
                  context,
                  initial: DateTime.now(),
                );
                _say(r is PpForgeDatePicked ? r.date : r);
              }),
              _demoButton('Deadline (clearable, future only)', () async {
                final now = DateTime.now();
                final r = await showPpForgeDatePicker(
                  context,
                  initial: now.add(const Duration(days: 90)),
                  first: now,
                  last: DateTime(now.year + 20),
                  title: 'Deadline',
                  clearable: true,
                );
                _say(r is PpForgeDatePicked ? r.date : r);
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
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
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
          title: 'showPpForgeDateRangePicker + PpForgeDateRangePickerSheet',
          note:
              'THE date RANGE picker, same sheet look as the date picker: tap a '
              'day to start, another to end (tap again to start over), then '
              'Save. Optional preset chips above the calendar. Resolves with a '
              'DateTimeRange / null (dismissed). Used by the transactions '
              'custom period.',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              _demoButton('Pick a range', () async {
                final r = await showPpForgeDateRangePicker(context);
                _say(r);
              }),
              _demoButton('With presets, up to today', () async {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final r = await showPpForgeDateRangePicker(
                  context,
                  last: today,
                  initial: DateTimeRange(
                    start: today.subtract(const Duration(days: 6)),
                    end: today,
                  ),
                  presets: [
                    PpForgeDateRangePreset(
                      'Last 7 days',
                      DateTimeRange(
                        start: today.subtract(const Duration(days: 6)),
                        end: today,
                      ),
                    ),
                    PpForgeDateRangePreset(
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
          title: 'showMultiDatePicker + MultiDatePickerSheet',
          note:
              'Pick SEVERAL days (a custom recurrence): tap a day to toggle it '
              '(picked = filled, never ticked), days outside first / last are '
              'dimmed, the picked days are removable chips under the calendar '
              '(tap one to drop it). Clear + a confirm labelled by the caller '
              'with the count, off while nothing is picked. Resolves with the '
              'day-only dates / null (dismissed). Inline body below (bounded '
              'height), or open the real sheet.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  return SizedBox(
                    height: 600,
                    child: PpForgeCard(
                      style: PpForgeCardStyle.bordered,
                      child: MultiDatePickerSheet(
                        initial: {
                          today.add(const Duration(days: 3)),
                          today.add(const Duration(days: 10)),
                        },
                        first: today,
                        last: DateTime(today.year + 2, today.month, today.day),
                        title: 'Pick the dates',
                        confirmLabel: (n) => 'Use $n dates',
                        onChanged: (s) => _say('picked: ${s.length}'),
                        onConfirm: (s) => _say((s.toList()..sort()).join(', ')),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: PpForgeSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: _demoButton('Open the multi-date sheet', () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final r = await showMultiDatePicker(
                    context,
                    initial: const {},
                    first: today,
                    last: DateTime(today.year + 2, today.month, today.day),
                    title: 'Pick the dates',
                    confirmLabel: (n) => n == 0 ? 'Pick dates' : 'Use $n dates',
                  );
                  _say(r == null ? null : (r.toList()..sort()).join(', '));
                }),
              ),
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
          title: 'Multi-select picker — PickerRow(checked) + PickerConfirmBar',
          note:
              'Several at once (add bills to an event, add members): each row '
              'leads with the square SelectCheck and a checked row is tinted; '
              'the pinned confirm shows the count ("Add (n)") and is off with '
              'nothing checked. Single-select pickers stay highlight-only.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PickerRow(
                title: 'Dinner',
                subtitle: '฿240',
                checked: true,
                onTap: () {},
              ),
              PickerRow(
                title: 'Taxi',
                subtitle: '฿120',
                checked: false,
                onTap: () {},
              ),
              const PickerConfirmBar(label: 'Add (1)', onPressed: null),
              const SizedBox(height: PpForgeSpacing.sm),
              PpForgeButton(
                label: 'Open a multi-select picker',
                onPressed: _multiPicker,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Last result',
          note: 'What the sheets resolve with.',
          child: PpForgeText(
            '$_result - wallet: $_wallet, currency: $_currency, sort: $_sort',
            role: PpForgeTextRole.caption,
          ),
        ),
        HubDemo(
          title:
              'PpForgeSheetScaffold, showPpForgeSheet, showPpForgeSheetCustom',
          note:
              'The standard bottom sheet: drag handle, title, scrolling body, '
              'pinned footer. Custom = a sheet that builds its own scaffold.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'Title + footer',
                child: _demoButton('showPpForgeSheet', _standardSheet),
              ),
              HubCell(
                caption: 'Full height',
                child: _demoButton('showPpForgeSheetCustom', _customSheet),
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
          title: 'showPpForgeSheet',
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
            child: PpForgeButton(
              label: 'Open the sheet',
              onPressed: () => showPpForgeSheet<void>(
                context,
                title: v<String>('title').isEmpty ? null : v<String>('title'),
                builder: (_) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PpForgeSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < v<double>('bodyLines').round(); i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: PpForgeSpacing.xs,
                          ),
                          child: PpForgeText('A line of the body.'),
                        ),
                    ],
                  ),
                ),
                footer: v<bool>('footer')
                    ? Padding(
                        padding: const EdgeInsets.all(PpForgeSpacing.lg),
                        child: Builder(
                          builder: (ctx) => PpForgeButton(
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
