import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/progress` — the progress pieces shared by budgets and saving
/// goals: ProgressRow with the expected segment, ProgressCard (row / compact /
/// skeleton), ProgressSummary, ProgressHeroFooter, BreakdownRow, StatGrid.
Widget buildProgressPage(BuildContext context) => const _ProgressPage();

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();

  @override
  Widget build(BuildContext context) {
    final tones = [for (final t in ProgressTone.values) (t.name, t)];
    const entity = IconCode(icon: 'restaurant', iconColors: ['#F97316']);

    Widget bar(String caption, double v, double? e, ProgressTone t) => SizedBox(
      width: 300,
      child: HubCell(
        caption: caption,
        child: ProgressRow(
          value: v,
          expected: e,
          color: t.resolve(context),
          overColor: t.resolve(context),
          label: 'ใช้ ${(v * 100).round()}%',
          trailing: '${(v * 100).round()}%',
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'ProgressRow — used + expected',
          note:
              'value = used ratio, expected = the not-yet-spent ratio drawn '
              'after it as a lighter striped segment. Both are unclamped '
              'inputs; the bar clamps the TOTAL at 100%.',
          child: HubRow(
            cells: [
              bar('used 39% + expected 9%', 0.39, 0.09, ProgressTone.neutral),
              bar('warning 86% + 7%', 0.86, 0.07, ProgressTone.warning),
              bar('total past 100% (cut)', 0.9, 0.4, ProgressTone.neutral),
              bar('over 122% (full, danger)', 1.22, null, ProgressTone.danger),
              bar('expected only', 0, 0.2, ProgressTone.neutral),
              SizedBox(
                width: 300,
                child: HubCell(
                  caption: 'normal + pace marker at 52%',
                  child: ProgressRow(
                    value: 0.4,
                    color: ProgressTone.normal.resolve(context),
                    marker: 0.52,
                  ),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ShownTweenBuilder — bars replay when shown',
          note:
              'ProgressRow, HeroRing, HeroBar.split and DonutChart grow from '
              'zero each time their page is shown (first open after the push, '
              'back from a tab or page, an inner tab selected again, app '
              'resume). The button plays the app-resume replay.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: HubCell(
                  caption: 'used 62%',
                  child: ProgressRow(
                    value: 0.62,
                    color: ProgressTone.normal.resolve(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Replay (as on app resume)',
                variant: AppButtonVariant.outlined,
                onPressed: () => ShownTweenBuilder.replayAll.value++,
              ),
            ],
          ),
        ),
        HubPlayground(
          title: 'ProgressCard',
          note:
              'The row of a budget / goal list. tone is decided by the caller '
              '(the BE for budgets) — never derived from value. The % text is '
              'the caller\'s string, not clamped.',
          controls: [
            PlayChoice<ProgressTone>('tone', tones),
            PlayNum('used %', min: 0, max: 200, step: 1, initialValue: 86),
            PlayNum('expected %', min: 0, max: 100, step: 1, initialValue: 7),
            const PlayBool('icon', initialValue: true),
            const PlayBool('badge', initialValue: true),
            const PlayBool('overLabel'),
            const PlayBool('compact'),
            const PlayBool('dimmed'),
          ],
          builder: (context, v) {
            final used = v<num>('used %').toDouble() / 100;
            final exp = v<num>('expected %').toDouble() / 100;
            final tone = v<ProgressTone>('tone');
            final compact = v<bool>('compact');
            final badge = v<bool>('badge')
                ? StatusChip.tone(
                    label: tone.name,
                    tone: switch (tone) {
                      ProgressTone.danger => AppChipTone.danger,
                      ProgressTone.warning => AppChipTone.warning,
                      ProgressTone.success => AppChipTone.success,
                      _ => AppChipTone.neutral,
                    },
                    size: ChipSize.mini,
                  )
                : null;
            return compact
                ? ProgressCard.compact(
                    title: 'ต.ค. 2026',
                    caption: 'เฉพาะรอบนี้',
                    value: used,
                    expected: exp,
                    tone: tone,
                    badge: badge,
                    label: '฿3,120 จาก ฿8,000',
                    struckLabel: '฿6,000',
                    percentText: '${(used * 100).round()}%',
                    dimmed: v<bool>('dimmed'),
                    onTap: () {},
                  )
                : ProgressCard(
                    title: 'อาหาร',
                    caption: 'รายเดือน | 1–31 ต.ค. | เหลือ 24 วัน',
                    iconCode: v<bool>('icon') ? entity : null,
                    fallbackIcon: v<bool>('icon') ? Icons.restaurant : null,
                    value: used,
                    expected: exp,
                    tone: tone,
                    badge: badge,
                    label: 'ใช้ ฿3,120 จาก ฿8,000 | คาด +฿720',
                    overLabel: v<bool>('overLabel') ? 'เกินงบ ฿860' : null,
                    percentText: '${(used * 100).round()}%',
                    dimmed: v<bool>('dimmed'),
                    onTap: () {},
                  );
          },
        ),
        HubDemo(
          title: 'ProgressCard — rows in one SectionCard + paceBubble',
          note:
              'The budgets list: the rows sit in one SectionCard (2px gaps); '
              'paceBubble shows the plan to date over the pace tick all the '
              'time, in the bar\'s color.',
          child: SectionCard(
            first: true,
            children: [
              ProgressCard(
                title: 'test',
                caption: 'รายเดือน | เหลือ 12 วัน',
                fallbackIcon: Icons.movie_outlined,
                value: 0,
                tone: ProgressTone.normal,
                alignWithTitle: true,
                trailing: const ProgressRemainder(
                  label: 'เหลือ',
                  amount: '฿2,000',
                ),
                paceMarker: 0.65,
                paceBubble: 'แผนถึงวันนี้ ฿1,300',
                label: 'ใช้ ฿0 จาก ฿2,000',
                percentText: '0%',
              ),
              ProgressCard(
                title: 'อาหาร',
                caption: 'รายเดือน | เหลือ 12 วัน',
                fallbackIcon: Icons.restaurant_outlined,
                value: 0.87,
                tone: ProgressTone.warning,
                alignWithTitle: true,
                badge: const ProgressBadges(
                  children: [
                    StatusChip(
                      label: 'ใกล้เต็ม',
                      kind: StatusKind.warning,
                      size: ChipSize.mini,
                    ),
                  ],
                ),
                trailing: const ProgressRemainder(
                  label: 'เหลือ',
                  amount: '฿650',
                ),
                paceMarker: 0.65,
                paceBubble: 'แผนถึงวันนี้ ฿3,250',
                label: 'ใช้ ฿4,350 จาก ฿5,000',
                percentText: '87%',
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ProgressCard — list (hairline rows) + skeleton',
          note:
              'Rows sit in a divided list; ProgressCard.compact is the period '
              'row (no icon, title = the period); .skeleton keeps the slots.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressCard(
                title: 'ช้อปปิ้งออนไลน์',
                caption: 'รายเดือน | 1–31 ต.ค.',
                fallbackIcon: Icons.shopping_bag_outlined,
                value: 1.22,
                tone: ProgressTone.danger,
                badge: const ProgressBadges(
                  children: [
                    StatusChip(
                      label: 'เกินงบ',
                      kind: StatusKind.over,
                      size: ChipSize.mini,
                    ),
                    StatusChip(
                      label: 'ตามเพซจะเกิน',
                      kind: StatusKind.warning,
                      size: ChipSize.mini,
                    ),
                  ],
                ),
                trailing: const ProgressRemainder(
                  label: 'เกิน',
                  amount: '฿860',
                  over: true,
                ),
                label: 'ใช้ ฿4,860 จาก ฿4,000',
                overLabel: 'เกิน ฿860',
                percentText: '122%',
              ),
              const AppDivider(),
              ProgressCard.compact(
                title: 'ก.ย. 2026',
                value: 1.06,
                tone: ProgressTone.danger,
                label: '฿8,460 จาก ฿8,000',
                percentText: '106%',
              ),
              const AppDivider(),
              const ProgressCard.skeleton(),
              const AppDivider(),
              const ProgressCard.skeleton(compact: true),
            ],
          ),
        ),
        HubDemo(
          title: 'ProgressSummary — no icon',
          note:
              'The list header / hero footer: big money title, caption, bar, '
              'left label + right %, footnote.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProgressSummary(
                amount: 12400,
                caption: 'ใช้ไปแล้ว จาก ฿20,000',
                value: 0.62,
                expected: 0.08,
                label: 'ใช้แล้ว',
                percentText: '62%',
                footnote: 'เหลือ ฿7,600 | เกิน 1 งบ',
              ),
              const SizedBox(height: AppSpacing.lg),
              const ProgressSummary.skeleton(),
            ],
          ),
        ),
        HubDemo(
          title: 'ProgressHeroFooter — the AppHeroCard footer',
          child: AppHeroCard(
            style: HeroStyle.tinted(color: Colors.orange),
            content: [
              HeroIdentity(
                icon: const IconTile(
                  icon: Icons.restaurant,
                  color: Colors.orange,
                ),
                name: const Text('อาหาร'),
              ),
            ],
            footer: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: ProgressHeroFooter(
                  caption: 'ใช้ไปแล้ว',
                  amount: 3120,
                  subCaption: 'จาก ฿8,000 | เหลือ ฿4,880',
                  value: 0.39,
                  expected: 0.09,
                  color: Colors.orange,
                  legendUsed: 'ใช้แล้ว 39%',
                  legendExpected: 'คาดว่าจะใช้ +฿720',
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'BreakdownRow',
          note:
              'By source / by category / a goal\'s wallet share. expected = '
              'muted "+amount" and a striped bar (still to come).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BreakdownRow(
                leading: const IconTile(
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  size: 28,
                ),
                label: 'ร้านอาหาร',
                amount: 1680,
                value: 0.54,
                color: Colors.orange,
              ),
              const BreakdownRow(
                label: 'ปกติ',
                caption: '18 รายการ',
                amount: 2460,
                value: 0.31,
                color: Colors.orange,
              ),
              const BreakdownRow(
                label: 'รายการประจำ | ล่วงหน้า',
                caption: '1 รายการ',
                amount: 450,
                expected: true,
                value: 0.056,
                color: Colors.orange,
              ),
              const BreakdownRow(label: 'No bar', amountText: '฿90'),
            ],
          ),
        ),
        HubDemo(
          title: 'StatGrid + StatTile',
          note: 'Two-column stat tiles; warning / danger = soft tint.',
          child: StatGrid(
            children: [
              const StatTile(
                caption: 'ใช้ได้อีกวันละ',
                value: '฿165',
                subCaption: 'หลังหักที่คาดไว้',
              ),
              const StatTile(
                caption: 'ตามเพซนี้จะเกินวันที่',
                value: '19 ต.ค.',
                subCaption: 'เฉลี่ยวันละ ฿390',
                tone: Tone.warning,
              ),
              const StatTile(
                caption: 'คาดสิ้นรอบ',
                valueWidget: MoneyText(12990),
                subCaption: 'เกิน ฿4,990',
                tone: Tone.danger,
              ),
              StatTile(
                caption: 'เฉลี่ย 6 รอบก่อน',
                value: '฿7,530',
                subCaption: 'ต่อรอบ (tap)',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
