import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/recurring` — recurring texts: DueText (a due date as
/// relative words) and RecurrenceText (a RecurrenceRule in words). The
/// Row markers (↻ / ⏲ / 🔗 / status / dimmed) are on Molecules → List row.
Widget buildRecurringPage(BuildContext context) => const _RecurringPage();

void _noop() {}

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
              '= upcoming | date came, nothing made = not created | a draft = '
              'pending | a real tx = done | archived = "don\'t want it". One '
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
          title: 'MonthCalendar — month grid with dots (generic organism)',
          note:
              'The week starts where the locale starts it (th: Sunday). dots: '
              'day of the month → colours (3 drawn at most); captions: a '
              'short line under the day ("-419", "~1,305" = an average) in its '
              'tone. edges: a border in the day\'s tone (waiting = warning, '
              'out / in = red / green; the recurring page uses this instead '
              'of dots). A day with something gets a box; selected = filled, '
              'today = a plain outline; past '
              'days muted; the weeks\' ends show the next / previous month '
              'greyed. The page feeds the data. Used by the recurring list\'s '
              'ปฏิทิน tab.',
          child: const _CalendarDemo(),
        ),
        HubDemo(
          title:
              'MonthCalendar(showStepper: false) — under the page\'s stepper',
          note:
              'The recurring list\'s ปฏิทิน tab: the hero\'s ‹ month › drives '
              'the grid, so the grid drops its own stepper.',
          child: const _CalendarDemo(showStepper: false),
        ),
        HubDemo(
          title: 'CalendarTile + DateTile — dates as tiles',
          note:
              'CalendarTile: a tear-off sheet (month strip in the card\'s '
              'accent, the day big, the weekday) for the next occurrence in a '
              'hero. DateTile: a row\'s day over its month, the short year '
              'when it isn\'t this year, the weekday for a month\'s list, or '
              'any caption ("พรุ่งนี้"). inline: the two on one line ("3 ศ."), '
              'end aligned, for a month\'s compact list.',
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CalendarTile(date: inDays(14)),
              DateTile(date: inDays(3)),
              DateTile(date: DateTime(now.year + 1, 1, 3)),
              DateTile(date: inDays(5), weekday: true),
              DateTile(date: inDays(1), caption: 'พรุ่งนี้'),
              DateTile(date: inDays(5), weekday: true, inline: true),
            ],
          ),
        ),
        HubDemo(
          title: 'DatePickChip — an optional date as a chip',
          note:
              'None = dashed "+ เลือกวันที่" (emptyLabel can say more, e.g. '
              '"เลือกวันกำหนดจ่าย"); set = the day + ✕ to clear; no onPick = '
              'view mode, just the day. format swaps the medium date for '
              'the page\'s own words. Used by the recurring trial date and '
              'the debt due date.',
          child: _DatePickChipDemo(start: inDays(30)),
        ),
        HubDemo(
          title: 'TodayLine — between past and coming rows',
          note:
              'The calendar list in date order: past rows dimmed unless '
              'still waiting, the today line before the first coming one. '
              'Rows are AppListRow (see UI → molecules → list-row).',
          child: SectionCard(
            children: [
              AppListRow(
                leading: const IconDisplay(type: IconType.category, size: 36),
                title: 'ค่าเน็ตบ้าน',
                line2: const ListRowLine(
                  lead: ListRowChip('อัตโนมัติ'),
                  parts: ['อ. 20 ต.ค.'],
                ),
                trailing: const ListRowTrailing.value(
                  MoneyText(-599, symbol: '฿'),
                ),
                dimmed: true,
              ),
              const TodayLine(label: 'วันนี้ 23 ต.ค.'),
              AppListRow(
                leading: const IconDisplay(type: IconType.category, size: 36),
                title: 'อาหารแมว',
                line2: const ListRowLine(parts: ['ส. 24 ต.ค.']),
                trailing: const ListRowTrailing.value(
                  MoneyText(-350, symbol: '฿'),
                  caption: 'พรุ่งนี้',
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DueCard + DueSelectBar — ต้องจัดการ as two boxes',
          note:
              'รอใส่ยอด: a DueAmountField per row (hint "รอใส่ยอด") and a '
              'DueConfirmButton ✓. รอยืนยัน: the amount big and a ✓. Every row '
              'has a check (OccurrenceRow selected / onSelected); each box a '
              'DueSelectBar (เลือกทั้งหมด / เลือกแล้ว n, ข้ามที่เลือก, '
              'ยืนยันที่เลือก (n); off until something is picked). The page '
              'warns before recording an empty amount as 0.',
          child: const _PickDemo(),
        ),
        HubDemo(
          title: 'OccurrenceTile + OccurrenceTileGrid — ปรับแต่งล่วงหน้า',
          note:
              'The sheet\'s month grid: a cell per occurrence, three to a row. '
              'ถัดไป edged in primary, แก้ / เลื่อน washed in info with what it '
              'was struck under, ข้าม crossed out, สุดท้าย tagged green.',
          child: OccurrenceTileGrid(
            children: [
              OccurrenceTile(
                label: 'ธ.ค.',
                day: 21,
                amount: '฿129',
                amountColor: Tone.danger.color(context),
                tag: 'ถัดไป',
                highlight: true,
                onTap: _noop,
              ),
              OccurrenceTile(
                label: 'ม.ค.',
                day: 21,
                amount: '฿129',
                amountColor: Tone.danger.color(context),
                onTap: _noop,
              ),
              OccurrenceTile(
                label: 'ก.พ.',
                day: 25,
                amount: '฿129',
                amountColor: Tone.danger.color(context),
                tag: 'เลื่อน',
                tone: Tone.info,
                was: '21 ก.พ.',
                onTap: _noop,
              ),
              OccurrenceTile(
                label: 'มี.ค.',
                day: 21,
                amount: '฿159',
                amountColor: Tone.info.color(context),
                tag: 'แก้',
                tone: Tone.info,
                was: '฿129',
                onTap: _noop,
              ),
              const OccurrenceTile(
                label: 'เม.ย.',
                day: 21,
                amount: '฿129',
                tag: 'ข้าม',
                struck: true,
                onTap: _noop,
              ),
              OccurrenceTile(
                label: 'พ.ค.',
                day: 21,
                amount: '฿129',
                amountColor: Tone.danger.color(context),
                tag: 'สุดท้าย',
                tone: Tone.success,
                onTap: _noop,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DueGroupHeader + OccurrenceActions — a head with actions',
          note:
              'A head inside a DueCard with a main button and the rest behind '
              '⋯ (OccurrenceActions; the detail page\'s focus card and the ⋯ '
              'menu use OccurrenceAction too). DueMoreRow: "ดูทั้ง n งวด ›".',
          child: DueCard(
            title: 'ต้องจัดการ',
            trailing: '24',
            children: [
              DueGroupHeader(
                label: 'Netflix',
                caption: 'ตั้งแต่ พ.ย. 2024 | 24 งวด',
                actions: OccurrenceActions(
                  primary: const OccurrenceAction(
                    label: 'ยืนยันทั้งหมด',
                    onTap: _noop,
                  ),
                  more: const [
                    OccurrenceAction(label: 'จ่ายแล้วทั้งหมด', onTap: _noop),
                    OccurrenceAction(label: 'ข้ามทั้งหมด', onTap: _noop),
                  ],
                ),
              ),
              const DueMoreRow(label: 'ดูทั้ง 24 งวด', onTap: _noop),
            ],
          ),
        ),
        HubDemo(
          title: 'Recurring hero — paid bar + joined tiles',
          note:
              'The list page\'s hero: the month\'s money out, a HeroBar of how '
              'much is paid (จ่ายแล้ว / เหลือ), then HeroTiles(joined: true): '
              'income and the month\'s count in one inset box.',
          child: Builder(
            builder: (context) => AppHeroCard(
              style: HeroStyle.tinted(
                color: Theme.of(context).colorScheme.primary,
              ),
              content: const [
                HeroNumber(
                  label: 'จ่ายรวมทั้งเดือน',
                  value: MoneyText(-15497, tone: MoneyTone.signed, symbol: '฿'),
                ),
                HeroBar(
                  value: 0.53,
                  left: 'จ่ายแล้ว ฿8,200',
                  right: 'เหลือ ฿7,297',
                ),
                HeroTiles(
                  joined: true,
                  children: [
                    SummaryTileView(
                      tile: SummaryTile(
                        label: 'รายรับ',
                        value: '+฿50,000',
                        tone: SummaryTileTone.green,
                      ),
                    ),
                    SummaryTileView(
                      tile: SummaryTile(
                        label: 'รายการเดือนนี้',
                        value: '26 รายการ',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'OccurrenceFocusCard — under an item\'s hero',
          note:
              'One card for what to do next. warning: ต้องจัดการ head, the '
              'oldest due one big (CalendarTile in warning) with its buttons '
              '(the first filled; ใส่ยอด in warning), then footer rows '
              '(DueGroupHeader, DueMoreRow, OccurrenceFocusNext = ครั้งถัดไป '
              'as a line). Quiet: the next occurrence with แก้ยอด / เลื่อนวัน '
              '/ ข้าม.',
          child: Builder(
            builder: (context) {
              final warning = Theme.of(context).extension<AppColors>()!.warning;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OccurrenceFocusCard(
                    warning: true,
                    title: 'ต้องจัดการ',
                    trailing: '2 งวด',
                    date: inDays(-20),
                    label: 'เลยมา 20 วัน',
                    tag: AppChip(
                      label: 'ค้าง',
                      color: warning,
                      selected: true,
                      size: ChipSize.mini,
                    ),
                    value: const MoneyText(
                      -419,
                      tone: MoneyTone.signed,
                      symbol: '฿',
                    ),
                    primaryFirst: true,
                    actions: const [
                      OccurrenceAction(label: 'ยืนยัน', onTap: _noop),
                      OccurrenceAction(label: 'จ่ายแล้ว', onTap: _noop),
                      OccurrenceAction(label: 'ข้าม', onTap: _noop),
                    ],
                    footer: [
                      const DueMoreRow(label: 'ดูทั้ง 2 งวด', onTap: _noop),
                      OccurrenceFocusNext(
                        label: 'ครั้งถัดไป | อีก 11 วัน',
                        amount: const MoneyText(
                          -419,
                          tone: MoneyTone.signed,
                          symbol: '฿',
                        ),
                        onTap: _noop,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OccurrenceFocusCard(
                    date: inDays(14),
                    label: 'ครั้งถัดไป | อีก 14 วัน',
                    value: const Text('รอใส่ยอด'),
                    valueColor: warning,
                    primaryFirst: true,
                    actions: const [
                      OccurrenceAction(label: 'ใส่ยอด', onTap: _noop),
                      OccurrenceAction(label: 'เลื่อนวัน', onTap: _noop),
                      OccurrenceAction(label: 'ข้าม', onTap: _noop),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        HubDemo(
          title: 'OccurrenceChain — an item\'s occurrences on one line',
          note:
              'The tier follows the width: a number in every dot (≤ ~12 on a '
              'phone row), numbers only on the first / current / last (~13–18), '
              'plain dots with PointerBubbles over those three (~19–24), else '
              'a bar with the same bubbles. Paid = the card color, waiting = '
              'warning, skipped = grey, the next one = a ring with a halo, '
              'future = hollow. open: no end (month bubbles, a fading tail, no '
              'last bubble). The current bubble wins a collision.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (total, cur, wait, skip) in [
                (10, 5, 3, -1),
                (18, 6, 5, -1),
                (24, 8, -1, 6),
                (72, 19, -1, -1),
              ]) ...[
                Text(
                  '$total installments',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                OccurrenceChain(
                  dots: [
                    for (var i = 0; i < total; i++)
                      i == cur
                          ? ChainDot.current
                          : i == wait
                          ? ChainDot.wait
                          : i == skip
                          ? ChainDot.skipped
                          : i < cur
                          ? ChainDot.paid
                          : ChainDot.future,
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                'Open (no end): Mar → next Nov + 3 to come',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              OccurrenceChain(
                open: true,
                firstLabel: 'มี.ค. 26',
                currentLabel: 'พ.ย.',
                dots: [
                  for (var i = 0; i < 12; i++)
                    i == 8
                        ? ChainDot.current
                        : i == 7
                        ? ChainDot.wait
                        : i < 8
                        ? ChainDot.paid
                        : ChainDot.future,
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AmountLineChart — a bill whose amount changes',
          note:
              'In the recurring hero in place of the chain: each paid period '
              'a point with its amount, a dashed average, and the next period '
              'a hollow "?" in warning at the average. Colors come from the '
              'hero.',
          child: AppHeroCard(
            style: HeroStyle.tinted(
              color: Theme.of(context).colorScheme.tertiary,
            ),
            content: const [
              AmountLineChart(
                points: [
                  AmountPoint('เม.ย.', 1070, amountText: '1,070'),
                  AmountPoint('พ.ค.', 1150, amountText: '1,150'),
                  AmountPoint('มิ.ย.', 1480, amountText: '1,480'),
                  AmountPoint('ก.ค.', 1230, amountText: '1,230'),
                  AmountPoint('ส.ค.', 1198, amountText: '1,198'),
                  AmountPoint('ก.ย.', 1312, amountText: '1,312'),
                ],
                average: 1240,
                averageLabel: 'เฉลี่ย 1,240',
                nextLabel: 'ต.ค.',
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showOccurrenceSheet — edit ONE occurrence',
          note:
              'Amount + date in a FormSheet (แก้ยอด / เลื่อนวัน / ใส่ยอด). '
              'amountRequired = a reminder with no amount: needs an amount '
              '> 0 to save. withAmount: false = the date only.',
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Edit amount',
                variant: AppButtonVariant.outlined,
                onPressed: () => showOccurrenceSheet(
                  context,
                  title: 'Edit amount',
                  saveLabel: 'Save',
                  dateLabel: 'Date',
                  amountLabel: 'Amount',
                  date: inDays(3),
                  amount: 419,
                  symbol: '฿',
                  first: inDays(0),
                  last: inDays(400),
                ),
              ),
              AppButton(
                label: 'Enter amount (reminder)',
                variant: AppButtonVariant.outlined,
                onPressed: () => showOccurrenceSheet(
                  context,
                  title: 'Enter amount',
                  saveLabel: 'Save',
                  dateLabel: 'Date',
                  amountLabel: 'Amount',
                  date: inDays(3),
                  symbol: '฿',
                  first: inDays(0),
                  last: inDays(400),
                  amountRequired: true,
                ),
              ),
              AppButton(
                label: 'Count (showCountSheet)',
                variant: AppButtonVariant.outlined,
                onPressed: () => showCountSheet(
                  context,
                  title: 'Number of payments',
                  label: 'Payments',
                  saveLabel: 'Save',
                  initial: 10,
                ),
              ),
              AppButton(
                label: 'Move date',
                variant: AppButtonVariant.outlined,
                onPressed: () => showOccurrenceSheet(
                  context,
                  title: 'Move date',
                  saveLabel: 'Save',
                  dateLabel: 'Date',
                  date: inDays(3),
                  symbol: '฿',
                  first: inDays(0),
                  last: inDays(400),
                  withAmount: false,
                  focus: OccurrenceFocus.date,
                ),
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
                'daily | interval 2',
                rule(RecurrenceFreq.daily, interval: 2),
              ),
              recurCell(
                'weekly | Mon',
                rule(RecurrenceFreq.weekly, weekdays: const {1}),
              ),
              recurCell(
                'weekly | Mon + Wed',
                rule(RecurrenceFreq.weekly, weekdays: const {1, 3}),
              ),
              recurCell(
                'weekly | Mon + Wed + Fri',
                rule(RecurrenceFreq.weekly, weekdays: const {1, 3, 5}),
              ),
              recurCell(
                'weekly | interval 2 | Mon',
                rule(RecurrenceFreq.weekly, interval: 2, weekdays: const {1}),
              ),
              recurCell('monthly | day 3', rule(RecurrenceFreq.monthly)),
              recurCell(
                'monthly | last day',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onDay(
                    RecurrenceMonthly.lastDay,
                  ),
                ),
              ),
              recurCell(
                'monthly | interval 3 | day 3',
                rule(RecurrenceFreq.monthly, interval: 3),
              ),
              recurCell(
                'monthly | 2nd Monday',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onWeekday(
                    nth: 2,
                    weekday: 1,
                  ),
                ),
              ),
              recurCell(
                'monthly | last Friday',
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
                'yearly | interval 2',
                rule(RecurrenceFreq.yearly, interval: 2),
              ),
              recurCell(
                'dates | 5 picked',
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
              'seq + total (both set) append "| 4/12" (installments). '
              'showEnd appends the end: after n times / until a date; '
              'never adds nothing.',
          child: HubRow(
            cells: [
              recurCell(
                'seq 4 | total 12',
                rule(RecurrenceFreq.monthly),
                seq: 4,
                total: 12,
              ),
              HubCell(
                caption: 'showEnd | afterCount 12',
                child: RecurrenceText(
                  rule: rule(
                    RecurrenceFreq.monthly,
                    end: const RecurrenceEnd.afterCount(12),
                  ),
                  showEnd: true,
                ),
              ),
              HubCell(
                caption: 'showEnd | onDate',
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
                'weekly | Mon + Wed + Fri',
                rule(RecurrenceFreq.weekly, weekdays: const {1, 3, 5}),
              ),
              editorCell(
                'monthly | day 31',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onDay(
                    RecurrenceMonthly.lastDay,
                  ),
                ),
              ),
              editorCell(
                'monthly | 2nd Tuesday',
                rule(
                  RecurrenceFreq.monthly,
                  monthly: const RecurrenceMonthly.onWeekday(
                    nth: 2,
                    weekday: 2,
                  ),
                ),
              ),
              editorCell(
                'monthly | ends after 12',
                rule(
                  RecurrenceFreq.monthly,
                  end: const RecurrenceEnd.afterCount(12),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AppRecurrenceSheet.show — the one repeat / period sheet',
          note:
              'The editor in the app sheet with Cancel | OK; every page sets a '
              'repeat or a period through it. simple: a period (a start day '
              'instead of repeat days), showEnd: false drops สิ้นสุด, title '
              'names the field. Resolves the edited rule on OK, null on '
              'Cancel / dismiss. The last result is shown under the button.',
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

/// A button that opens [AppRecurrenceSheet] and shows the last result.
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
          label: 'AppRecurrenceSheet.show',
          variant: AppButtonVariant.outlined,
          onPressed: () async {
            final r = await AppRecurrenceSheet.show(context, initial: _rule);
            if (!mounted) return;
            setState(() {
              if (r != null) _rule = r;
              _last = r == null ? 'cancelled (null)' : 'OK';
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText(
          '$_last | ${recurrenceLabel(l, _rule, showEnd: true)}',
          role: AppTextRole.caption,
        ),
      ],
    );
  }
}

class _PickDemo extends StatefulWidget {
  const _PickDemo();

  @override
  State<_PickDemo> createState() => _PickDemoState();
}

class _PickDemoState extends State<_PickDemo> {
  static const _fill = [
    ('ค่าน้ำ', 'เลยมา 8 วัน | 15 ต.ค. | เงินสด | เฉลี่ย ฿210'),
    ('ค่าไฟ', 'วันนี้ | 23 ต.ค. | เงินสด | เฉลี่ย ฿1,305'),
  ];
  static const _ready = [
    ('Netflix', 'เลยมา 20 วัน | 3 ต.ค. | บัตรเครดิต', -419.0),
    ('ค่าเช่าห้อง', 'เลยมา 18 วัน | 5 ต.ค. | ธนาคาร', 6500.0),
  ];
  final _picked = <String>{};
  late final _values = <double?>[for (final _ in _fill) null];
  final _folded = <String>{};

  /// A section's head: check-all beside its name and count, its buttons,
  /// ⌄ / ⌃.
  Widget _bar(String name, String section, List<String> ids) {
    final n = ids.where(_picked.contains).length;
    return DueSelectBar(
      heading: true,
      selected: n,
      total: ids.length,
      selectLabel: '$name ${ids.length}',
      skipLabel: 'ข้ามที่เลือก',
      confirmLabel: n == 0 ? 'ยืนยันที่เลือก' : 'ยืนยันที่เลือก ($n)',
      onSelectAll: () => setState(() {
        if (n == ids.length) {
          _picked.removeAll(ids);
        } else {
          _picked.addAll(ids);
        }
      }),
      onSkip: () => setState(() => _picked.removeAll(ids)),
      onConfirm: () => setState(() => _picked.removeAll(ids)),
      open: !_folded.contains(section),
      onToggle: () => setState(() {
        if (!_folded.remove(section)) _folded.add(section);
      }),
    );
  }

  VoidCallback _toggle(String id) =>
      () => setState(() {
        if (!_picked.remove(id)) _picked.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final fillIds = [for (var i = 0; i < _fill.length; i++) 'f$i'];
    final readyIds = [for (var i = 0; i < _ready.length; i++) 'r$i'];
    const check = ListRowAction.button(
      AppIcons.check,
      tooltip: 'ยืนยัน',
      onTap: _noop,
    );
    return DueCard(
      title: 'ต้องจัดการ',
      trailing: '${_fill.length + _ready.length}',
      children: [
        _bar('รอใส่ยอด', 'fill', fillIds),
        if (!_folded.contains('fill'))
          for (final (i, (name, sub)) in _fill.indexed)
            AppListRow(
              checked: _picked.contains(fillIds[i]),
              onCheck: _toggle(fillIds[i]),
              leading: const IconDisplay(type: IconType.category, size: 36),
              title: name,
              line2: ListRowLine(
                lead: const ListRowChip(
                  'รอใส่ยอด',
                  tone: Tone.warning,
                  selected: true,
                ),
                parts: [sub],
              ),
              actions: [
                ListRowAction.amount(
                  key: ValueKey('pickDemo-$i'),
                  value: _values[i],
                  onChanged: (v) => _values[i] = v,
                  hint: 'รอยอด',
                ),
                check,
              ],
            ),
        const Divider(height: 1),
        _bar('รอยืนยัน', 'ready', readyIds),
        if (!_folded.contains('ready'))
          for (final (i, (name, sub, amount)) in _ready.indexed)
            AppListRow(
              checked: _picked.contains(readyIds[i]),
              onCheck: _toggle(readyIds[i]),
              leading: const IconDisplay(type: IconType.category, size: 36),
              title: name,
              line2: ListRowLine(
                lead: const ListRowChip(
                  'รอยืนยัน',
                  tone: Tone.warning,
                  selected: true,
                ),
                parts: [sub],
              ),
              trailing: ListRowTrailing.value(
                MoneyText(amount, tone: MoneyTone.signed, symbol: '฿'),
              ),
              actions: const [check],
            ),
        const DueMoreRow(label: 'ดูทั้ง 13 งวด', onTap: _noop),
      ],
    );
  }
}

class _CalendarDemo extends StatefulWidget {
  const _CalendarDemo({this.showStepper = true});

  final bool showStepper;

  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final calendar = MonthCalendar(
      month: _month,
      showStepper: widget.showStepper,
      today: DateTime.now(),
      selected: _selected,
      dots: {
        3: [CalendarDot.expense],
        5: [CalendarDot.warning, CalendarDot.expense],
        16: [
          CalendarDot.expense,
          CalendarDot.neutral,
          CalendarDot.income,
          CalendarDot.warning,
        ],
        23: [CalendarDot.warning],
        25: [CalendarDot.income],
      },
      edges: const {
        3: CalendarDot.expense,
        5: CalendarDot.warning,
        23: CalendarDot.warning,
        25: CalendarDot.income,
      },
      captions: const {
        3: CalendarCaption('-419', tone: CalendarDot.expense),
        5: CalendarCaption('-1,750', tone: CalendarDot.warning),
        23: CalendarCaption('~1,305', tone: CalendarDot.warning),
        25: CalendarCaption('+35,000', tone: CalendarDot.income),
      },
      onMonthChanged: (m) => setState(() => _month = m),
      onSelect: (d) => setState(() => _selected = d),
    );
    if (widget.showStepper) return calendar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StepperPill.month(
            value: _month,
            onChanged: (m) => setState(() => _month = m),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        calendar,
      ],
    );
  }
}

class _DatePickChipDemo extends StatefulWidget {
  const _DatePickChipDemo({required this.start});

  final DateTime start;

  @override
  State<_DatePickChipDemo> createState() => _DatePickChipDemoState();
}

class _DatePickChipDemoState extends State<_DatePickChipDemo> {
  DateTime? _date;

  Future<void> _pick() async {
    final r = await AppDatePicker.show(
      context,
      initial: _date ?? widget.start,
    );
    if (r is AppDatePicked && mounted) setState(() => _date = r.date);
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      DatePickChip(
        date: _date,
        onPick: _pick,
        onClear: () => setState(() => _date = null),
      ),
      DatePickChip(date: widget.start, onPick: _noop, onClear: _noop),
      DatePickChip(date: widget.start),
    ],
  );
}
