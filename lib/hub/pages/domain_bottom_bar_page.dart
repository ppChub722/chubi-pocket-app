import 'package:flutter/material.dart';

import '../../app/shell/main_bottom_nav.dart';
import '../../app/shell/nav_layout.dart';
import '../../app/shell/tab_nav.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';

/// The shell's bottom bar and its centre + (owner 2026-10-12: quick create =
/// ONE sheet with a per-page default; the + wears the mode's colour).
Widget buildBottomBarPage(BuildContext context) => const _BottomBarPage();

class _BottomBarPage extends StatefulWidget {
  const _BottomBarPage();

  @override
  State<_BottomBarPage> createState() => _BottomBarPageState();
}

class _BottomBarPageState extends State<_BottomBarPage> {
  QuickCreateMode _mode = QuickCreateMode.tx;
  ShellTab? _tab = ShellTab.home;

  static const _buttonWords = {
    QuickCreateMode.tx: 'บันทึก',
    QuickCreateMode.debt: 'จดหนี้',
    QuickCreateMode.saving: 'ออมเงิน',
  };

  static const _labels = {
    QuickCreateMode.tx: 'รายการ',
    QuickCreateMode.debt: 'หนี้',
    QuickCreateMode.saving: 'ออม',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'Bottom bar — the + follows the page’s mode',
          note:
              'The real shell bar. Each page says what the + opens '
              '(QuickCreatePresetScope: mode + preset) and the + takes the '
              'MODE’s colour from QuickCreateModeColors — pages never pass a '
              'colour. A change (tab switch, push, pop) cross-fades in 200 ms. '
              'Pick a mode below to see it. Its items come from the shell’s '
              'NavLayout (bottomItems, + after the first half); top chips and '
              'the More groups read the same object.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuickCreateModeTabs(
                mode: _mode,
                labels: _labels,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 96,
                child: MainBottomNav(
                  items: NavLayout.defaults.bottomItems,
                  current: _tab,
                  onSelected: (t) => setState(() => _tab = t),
                  addMode: _mode,
                  onAddPressed: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'QuickCreateButton — every mode',
          note:
              'Owner 2026-10-22 (mock QuickCreateBtn): in the bar it is a '
              '48-high capsule — the mode icon (quickCreateModeIcon) + the '
              'word บันทึก / จดหนี้ / ออมเงิน. tx = the theme primary | debt = '
              'ModuleColors.debt (#7A5AE0) | saving = ModuleColors.saving '
              '(#3B7DD8). Without a label: the round + (kept for reuse). '
              'Per page: Home / More / tx list / wallets / categories / tags '
              'lists and pending → tx; a wallet → tx + that wallet; a '
              'category → tx + that category; debts list → debt; a debt '
              'person / contact → debt + that person.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HubRow(
                cells: [
                  for (final m in QuickCreateMode.values)
                    HubCell(
                      caption: '${m.name} capsule',
                      child: QuickCreateButton(
                        mode: m,
                        label: _buttonWords[m],
                        onPressed: () {},
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              HubRow(
                cells: [
                  for (final m in QuickCreateMode.values)
                    HubCell(
                      caption: '${m.name} round',
                      child: QuickCreateButton(mode: m, onPressed: () {}),
                    ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'QuickCreateHeadButton + QuickCreateCtaButton — in the page',
          note:
              'The + in a list head (level with the 🔍 beside it) and the '
              'empty state’s filled call to action, both in the page’s mode '
              'colour; both open quick create in that mode. Live on the '
              'debts list (hero head + empty state).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HubRow(
                cells: [
                  for (final m in QuickCreateMode.values)
                    HubCell(
                      caption: '${m.name} head +',
                      child: QuickCreateHeadButton(mode: m, onPressed: () {}),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              EmptyView(
                icon: AppIcons.debt,
                title: 'ยังไม่มีหนี้ค้าง',
                message: 'จดไว้ว่าใครยืม ใครจ่ายแทน จะได้ไม่ลืมทวง',
                cta: QuickCreateCtaButton(
                  mode: QuickCreateMode.debt,
                  label: 'จดหนี้',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'QuickCreateModeTabs — the sheet’s mode switch',
          note:
              'At the very top of the quick create, above the EntryCard: the '
              'app\'s one tab style (AppTabBar pill), an icon on each mode, '
              'in the theme primary (no per-mode colours, owner 2026-10-21).',
          child: HubRow(
            cells: [
              for (final m in QuickCreateMode.values)
                HubCell(
                  caption: '${m.name} selected',
                  child: QuickCreateModeTabs(mode: m, labels: _labels),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
