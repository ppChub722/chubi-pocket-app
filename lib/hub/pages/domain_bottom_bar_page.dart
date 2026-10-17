import 'package:flutter/material.dart';

import '../../app/shell/main_bottom_nav.dart';
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
  int _tab = 0;

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
              'Pick a mode below to see it.',
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
                  currentIndex: _tab,
                  onTabSelected: (i) => setState(() => _tab = i),
                  addMode: _mode,
                  onAddPressed: () {},
                  onMorePressed: () => setState(() => _tab = 3),
                  moreSelected: _tab == 3,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'QuickCreateButton — every mode',
          note:
              'tx = the theme primary · debt = ModuleColors.people · saving = ModuleColors.planning. '
              'Per page: Home / More / tx list / wallets / categories / tags '
              'lists and pending → tx; a wallet → tx + that wallet; a '
              'category → tx + that category; debts list → debt; a debt '
              'person / contact → debt + that person.',
          child: HubRow(
            cells: [
              for (final m in QuickCreateMode.values)
                HubCell(
                  caption: m.name,
                  child: QuickCreateButton(mode: m, onPressed: () {}),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'QuickCreateModeTabs — the sheet’s mode switch',
          note:
              'At the very top of the quick create, above the EntryCard; '
              'each chip in its mode’s colour (the same as the +). Not in the '
              'sheet yet: debt mode waits on the BE.',
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
