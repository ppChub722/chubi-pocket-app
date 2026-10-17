import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/recurring` — recurring texts: DueText (a due date as
/// relative words) and RecurrenceText (a RecurrenceRule in words). The
/// TxRow 🔁 / 🔗 / status / dimmed markers are on Domain → Transactions.
Widget buildRecurringPage(BuildContext context) => const _RecurringPage();

class _RecurringPage extends StatelessWidget {
  const _RecurringPage();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    DateTime inDays(int n) => DateTime(now.year, now.month, now.day + n);
    final start = DateTime(now.year, 10, 3);
    RecurrenceRule rule(
      RecurrenceFreq freq, {
      int interval = 1,
      Set<int> weekdays = const {},
      RecurrenceMonthly? monthly,
      List<DateTime> dates = const [],
      RecurrenceEnd end = const RecurrenceEnd.never(),
    }) => RecurrenceRule(
      freq: freq,
      start: start,
      interval: interval,
      weekdays: weekdays,
      monthly: monthly,
      dates: dates,
      end: end,
    );

    Widget recurCell(
      String caption,
      RecurrenceRule r, {
      int? seq,
      int? total,
    }) => HubCell(
      caption: caption,
      child: RecurrenceText(rule: r, seq: seq, total: total),
    );

    Widget editorCell(String caption, RecurrenceRule r) => HubCell(
      caption: caption,
      child: SizedBox(
        width: 340,
        child: RecurrenceEditor(initial: r, onChanged: (_) {}),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'OccurrenceStateChip — where a produced item stands',
          note:
              'Derived from its link (owner 2026-10-13): no link + date ahead '
              '= upcoming · date came, nothing made = not created · a draft = '
              'pending · a real tx = done · archived = "don\'t want it". One '
              'tone per state (StatusChip).',
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in OccurrenceState.values)
                OccurrenceStateChip(state: s),
              const OccurrenceStateChip(
                state: OccurrenceState.pending,
                size: ChipSize.mini,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DueText — relative due date',
          note:
              'date + the BE\'s days_until (null = computed from today) → '
              'today / tomorrow / yesterday / in n days / n days overdue, '
              'then a short date (the year only when not this year). Overdue '
              'is tinted danger (tintOverdue). dueLabel() returns the string '
              'for pages and other kit pieces.',
          child: HubRow(
            cells: [
              for (final n in const [-5, -2, -1, 0, 1, 3, 30])
                HubCell(
                  caption: 'days $n',
                  child: DueText(date: inDays(n)),
                ),
              HubCell(
                caption: 'next year',
                child: DueText(date: inDays(400)),
              ),
              HubCell(
                caption: 'withDate: false',
                child: DueText(date: inDays(3), withDate: false),
              ),
              HubCell(
                caption: 'overdue, tintOverdue: false',
                child: DueText(date: inDays(-2), tintOverdue: false),
              ),
              HubCell(
                caption: 'daysUntil 7 from the BE',
                child: DueText(date: inDays(7), daysUntil: 7),
              ),
              HubCell(
                caption: 'style: bodyLarge',
                child: DueText(
                  date: inDays(-1),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'RecurrenceText — every frequency',
          note:
              'A RecurrenceRule in words (Google Calendar style). Empty '
              'weekdays = the start date\'s weekday; no monthly = the start '
              'date\'s day; yearly = the start\'s month + day. The start '
              'date in these demos is 3 Oct this year.',
          child: HubRow(
            cells: [
              recurCell('daily', rule(RecurrenceFreq.daily)),
              recurCell(
                'daily · interval 2',
                rule(RecurrenceFreq.daily, interval: 2),
              ),
              recurCell(
                'weekly · Mon',
                rule(RecurrenceFreq.weekly, weekdays: const {1}),
              ),
              recurCell(
                'weekly · Mon + Wed',
                rule(RecurrenceFreq.weekly, weekdays: const {1, 3}),
              ),
              recurCell(
                'weekly · Mon + Wed + Fri',
                rule(RecurrenceFreq.weekly, weekdays: const {1, 3, 5}),
              ),
              recurCell(
                'weekly · interval 2 · Mon',
                rule(RecurrenceFreq.weekly, interval: 2, weekdays: const {1}),
              ),
              recurCell('monthly · day 3', rule(RecurrenceFreq.monthly)),
              recurCell(
                'monthly · last day',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onDay(
                    RecurrenceMonthly.lastDay,
                  ),
                ),
              ),
              recurCell(
                'monthly · interval 3 · day 3',
                rule(RecurrenceFreq.monthly, interval: 3),
              ),
              recurCell(
                'monthly · 2nd Monday',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onWeekday(
                    nth: 2,
                    weekday: 1,
                  ),
                ),
              ),
              recurCell(
                'monthly · last Friday',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onWeekday(
                    nth: RecurrenceMonthly.lastWeek,
                    weekday: 5,
                  ),
                ),
              ),
              recurCell('yearly', rule(RecurrenceFreq.yearly)),
              recurCell(
                'yearly · interval 2',
                rule(RecurrenceFreq.yearly, interval: 2),
              ),
              recurCell(
                'dates · 5 picked',
                rule(
                  RecurrenceFreq.dates,
                  dates: [for (var i = 0; i < 5; i++) inDays(i * 7)],
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'RecurrenceText — progress and end',
          note:
              'seq + total (both set) append "· 4/12" (installments). '
              'showEnd appends the end: after n times / until a date; '
              'never adds nothing.',
          child: HubRow(
            cells: [
              recurCell(
                'seq 4 · total 12',
                rule(RecurrenceFreq.monthly),
                seq: 4,
                total: 12,
              ),
              HubCell(
                caption: 'showEnd · afterCount 12',
                child: RecurrenceText(
                  rule: rule(
                    RecurrenceFreq.monthly,
                    end: const RecurrenceEnd.afterCount(12),
                  ),
                  showEnd: true,
                ),
              ),
              HubCell(
                caption: 'showEnd · onDate',
                child: RecurrenceText(
                  rule: rule(
                    RecurrenceFreq.weekly,
                    weekdays: const {1, 3},
                    end: RecurrenceEnd.onDate(DateTime(now.year + 1, 10, 3)),
                  ),
                  showEnd: true,
                ),
              ),
              HubCell(
                caption: 'showEnd + progress',
                child: RecurrenceText(
                  rule: rule(
                    RecurrenceFreq.monthly,
                    end: const RecurrenceEnd.afterCount(12),
                  ),
                  showEnd: true,
                  seq: 4,
                  total: 12,
                ),
              ),
              HubCell(
                caption: 'style: bodyLarge',
                child: RecurrenceText(
                  rule: rule(RecurrenceFreq.monthly),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'RecurrenceEditor — the custom repeat body',
          note:
              'Google Calendar\'s "Custom…": a live summary, every N '
              'day / week / month / year, the weekday toggles (weekly, at '
              'least one stays on), day D or the Nth weekday (monthly; day 31 '
              '= the last day, the 5th weekday = the last), and the end: '
              'never / on a date (≤ start + 2 years) / after N times. '
              'Hand-picked dates are not edited here (they start as '
              'monthly). Start = 3 Oct this year.',
          child: HubRow(
            cells: [
              editorCell(
                'weekly · Mon + Wed + Fri',
                rule(RecurrenceFreq.weekly, weekdays: const {1, 3, 5}),
              ),
              editorCell(
                'monthly · day 31',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onDay(
                    RecurrenceMonthly.lastDay,
                  ),
                ),
              ),
              editorCell(
                'monthly · 2nd Tuesday',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onWeekday(
                    nth: 2,
                    weekday: 2,
                  ),
                ),
              ),
              editorCell(
                'monthly · ends after 12',
                rule(
                  RecurrenceFreq.monthly,
                  end: const RecurrenceEnd.afterCount(12),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showRecurrenceSheet — the custom repeat sheet',
          note:
              'The editor in the app sheet with Cancel · OK. Resolves the '
              'edited rule on OK, null on Cancel / dismiss. The last result '
              'is shown under the button.',
          child: _RecurrenceSheetDemo(
            initial: rule(RecurrenceFreq.weekly, weekdays: const {1}),
          ),
        ),
        HubPlayground(
          title: 'RecurrenceText',
          note:
              'Every RecurrenceRule field (start = 3 Oct this year) plus '
              'RecurrenceText\'s own options. seq / total 0 = not set.',
          hug: Alignment.centerLeft,
          controls: [
            PlayChoice<RecurrenceFreq>('freq', [
              for (final f in RecurrenceFreq.values) (f.name, f),
            ], initial: RecurrenceFreq.monthly),
            const PlayNum('interval', min: 1, max: 12, initialValue: 1),
            PlayChoice<Set<int>>('weekdays (weekly)', const [
              ('start\'s', <int>{}),
              ('Mon', {1}),
              ('Mon+Wed', {1, 3}),
              ('Mon+Wed+Fri', {1, 3, 5}),
              ('Sat+Sun', {6, 7}),
            ]),
            PlayChoice<RecurrenceMonthlyMode?>('monthly mode', const [
              ('none (start\'s day)', null),
              ('day', RecurrenceMonthlyMode.day),
              ('weekday', RecurrenceMonthlyMode.weekday),
            ]),
            const PlayNum('day (31 = last)', min: 1, max: 31, initialValue: 3),
            PlayChoice<int>('nth', const [
              ('1st', 1),
              ('2nd', 2),
              ('3rd', 3),
              ('4th', 4),
              ('5th', 5),
              ('last', RecurrenceMonthly.lastWeek),
            ], initial: 2),
            PlayChoice<int>('weekday', const [
              ('Mon', 1),
              ('Tue', 2),
              ('Wed', 3),
              ('Thu', 4),
              ('Fri', 5),
              ('Sat', 6),
              ('Sun', 7),
            ]),
            const PlayNum('dates count', min: 0, max: 10, initialValue: 5),
            PlayChoice<RecurrenceEndKind>('end', [
              for (final k in RecurrenceEndKind.values) (k.name, k),
            ]),
            const PlayNum('end count', min: 1, max: 36, initialValue: 12),
            const PlayBool('showEnd'),
            const PlayNum('seq', min: 0, max: 12, initialValue: 0),
            const PlayNum('total', min: 0, max: 12, initialValue: 0),
          ],
          builder: (context, v) {
            final mode = v<RecurrenceMonthlyMode?>('monthly mode');
            final monthly = switch (mode) {
              null => null,
              RecurrenceMonthlyMode.day => RecurrenceMonthly.onDay(
                v<double>('day (31 = last)').round(),
              ),
              RecurrenceMonthlyMode.weekday => RecurrenceMonthly.onWeekday(
                nth: v<int>('nth'),
                weekday: v<int>('weekday'),
              ),
            };
            final end = switch (v<RecurrenceEndKind>('end')) {
              RecurrenceEndKind.never => const RecurrenceEnd.never(),
              RecurrenceEndKind.onDate => RecurrenceEnd.onDate(
                DateTime(start.year + 1, start.month, start.day),
              ),
              RecurrenceEndKind.afterCount => RecurrenceEnd.afterCount(
                v<double>('end count').round(),
              ),
            };
            final seq = v<double>('seq').round();
            final total = v<double>('total').round();
            return RecurrenceText(
              rule: RecurrenceRule(
                freq: v<RecurrenceFreq>('freq'),
                start: start,
                interval: v<double>('interval').round(),
                weekdays: v<Set<int>>('weekdays (weekly)'),
                monthly: monthly,
                dates: [
                  for (var i = 0; i < v<double>('dates count').round(); i++)
                    start.add(Duration(days: i * 7)),
                ],
                end: end,
              ),
              showEnd: v<bool>('showEnd'),
              seq: seq == 0 ? null : seq,
              total: total == 0 ? null : total,
            );
          },
        ),
        HubDemo(
          title: 'RecurringPickerSheet — link a transaction to a recurring',
          note:
              'A presentational organism on the PickerSheet shell: groups '
              '(recurring, then payment reminders with no amount yet), a '
              'client search, selection = highlight, a pinned create row. '
              'Opens live with sample rows; the feature wrapper loads the BE '
              'list (GET /recurring?for_type=).',
          child: AppButton(
            label: 'Open the recurring picker',
            variant: AppButtonVariant.outlined,
            onPressed: () => showAppSheetCustom<RecurringPickChoice>(
              context,
              builder: (ctx) => RecurringPickerSheet(
                title: 'Link to a recurring',
                selectedId: 'a',
                createLabel: 'Create a recurring from this transaction',
                emptyText: 'No recurring to link to',
                onPicked: (_) => Navigator.of(ctx).pop(),
                onCreate: () => Navigator.of(ctx).pop(),
                groups: const [
                  RecurringPickGroup(
                    title: 'Recurring',
                    rows: [
                      RecurringPickRow(
                        id: 'a',
                        title: 'Car loan',
                        subtitle: 'Every 16th · Period 16 Oct not paid yet',
                        leading: AppIcon(AppIcons.recurring),
                        amount: 3023,
                        tone: MoneyTone.expense,
                      ),
                    ],
                  ),
                  RecurringPickGroup(
                    title: 'Payment reminders',
                    rows: [
                      RecurringPickRow(
                        id: 'b',
                        title: 'Water bill',
                        subtitle: 'Every 15th · Period 15 Oct enter the amount',
                        leading: AppIcon(AppIcons.notifications),
                        trailingLabel: 'Amount pending',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        HubDemo(
          title: 'AskCard — an inline question under a row',
          note:
              'The link\'s "update the recurring amount too?": message + '
              'No / Yes. busy disables both while the answer\'s call runs.',
          child: AskCard(
            message:
                'The amount differs from the recurring (฿3,023 → ฿3,100). '
                'Update the recurring\'s amount too?',
            noLabel: 'No',
            yesLabel: 'Update',
            onNo: () {},
            onYes: () {},
          ),
        ),
      ],
    );
  }
}

/// A button that opens [showRecurrenceSheet] and shows the last result.
class _RecurrenceSheetDemo extends StatefulWidget {
  const _RecurrenceSheetDemo({required this.initial});

  final RecurrenceRule initial;

  @override
  State<_RecurrenceSheetDemo> createState() => _RecurrenceSheetDemoState();
}

class _RecurrenceSheetDemoState extends State<_RecurrenceSheetDemo> {
  late RecurrenceRule _rule = widget.initial;
  String _last = 'not opened yet';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'showRecurrenceSheet',
          variant: AppButtonVariant.outlined,
          onPressed: () async {
            final r = await showRecurrenceSheet(context, initial: _rule);
            if (!mounted) return;
            setState(() {
              if (r != null) _rule = r;
              _last = r == null ? 'cancelled (null)' : 'OK';
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText(
          '$_last · ${recurrenceLabel(l, _rule, showEnd: true)}',
          role: AppTextRole.caption,
        ),
      ],
    );
  }
}
