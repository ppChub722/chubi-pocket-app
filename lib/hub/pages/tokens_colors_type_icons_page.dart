import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/tokens/colors` — the palette of the active theme and mode (switch
/// theme / mode in Debug → Theme switcher or the status bar toggle).
Widget buildColorsPage(BuildContext context) {
  final palette = Theme.of(context).extension<PpForgeColors>()!;
  final scheme = Theme.of(context).colorScheme;
  final module = ModuleColors.of(context);
  Widget swatch(String name, Color c, Color on) => HubCell(
    caption: name,
    child: Container(
      width: 84,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(PpForgeRadius.sm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        'Aa',
        style: TextStyle(color: on, fontWeight: FontWeight.w700),
      ),
    ),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'Brand & surfaces',
        child: HubRow(
          cells: [
            swatch('primary', palette.primary, palette.onPrimary),
            swatch(
              'primaryContainer',
              palette.primaryContainer,
              palette.onPrimaryContainer,
            ),
            swatch('secondary', palette.secondary, palette.onSecondary),
            swatch('background', palette.background, palette.onBackground),
            swatch('surface', palette.surface, palette.onSurface),
            swatch(
              'surfaceVariant',
              palette.surfaceVariant,
              palette.onSurfaceVariant,
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'Status',
        child: HubRow(
          cells: [
            swatch('success', palette.success, palette.onSuccess),
            swatch('warning', palette.warning, palette.onWarning),
            swatch('error', palette.error, palette.onError),
            swatch('info', palette.info, palette.onInfo),
          ],
        ),
      ),
      HubDemo(
        title: 'Money (domain)',
        note:
            'Income, expense and the two wallet groups. These live in the '
            'app’s own tokens — generic pieces take a colour, never read these.',
        child: HubRow(
          cells: [
            swatch('income', palette.income, palette.onIncome),
            swatch('expense', palette.expense, palette.onExpense),
            swatch('walletAsset', palette.walletAsset, palette.onPrimary),
            swatch(
              'walletLiability',
              palette.walletLiability,
              palette.onPrimary,
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'Module groups',
        note: 'คลัง · คน · วางแผน — one set per theme.',
        child: HubRow(
          cells: [
            swatch('library', module.library, Colors.white),
            swatch('people', module.people, Colors.white),
            swatch('planning', module.planning, Colors.white),
          ],
        ),
      ),
      HubDemo(
        title: 'Semantic tones',
        note: 'Tone → colour, as chips, snackbars and banners use them.',
        child: Wrap(
          spacing: PpForgeSpacing.sm,
          runSpacing: PpForgeSpacing.sm,
          children: [
            for (final t in Tone.values)
              PpForgeChip(
                label: t.name,
                tone: PpForgeChipTone.fromTone(t),
                selected: true,
                size: ChipSize.chip,
              ),
          ],
        ),
      ),
    ],
  );
}

/// `/dev/tokens/typography` — the seven roles.
Widget buildTypographyPage(BuildContext context) {
  const samples = <(PpForgeTextRole, String)>[
    (PpForgeTextRole.display, '฿1,250.00'),
    (PpForgeTextRole.title, 'ข้าวมันไก่ · Chicken rice'),
    (PpForgeTextRole.section, 'สมาชิก · Members'),
    (PpForgeTextRole.label, 'วันที่ · Date'),
    (PpForgeTextRole.body, 'บัญชีรับเงินเดือน ใช้จ่ายประจำ · Salary account'),
    (PpForgeTextRole.caption, 'สร้างเมื่อ 12 ต.ค. · Created 12 Oct'),
    (PpForgeTextRole.money, '฿96,248.33'),
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (role, text) in samples)
        HubDemo(
          title: role.name,
          note: _roleNote[role],
          child: PpForgeText(text, role: role),
        ),
    ],
  );
}

const _roleNote = <PpForgeTextRole, String>{
  PpForgeTextRole.display:
      'A big number or heading on its own — a hero’s amount.',
  PpForgeTextRole.title: 'A page or hero title.',
  PpForgeTextRole.section:
      'The big green heading of a detail section (หัวข้อ section).',
  PpForgeTextRole.label: 'A row’s field label (หัวข้อ).',
  PpForgeTextRole.body: 'Running text and values.',
  PpForgeTextRole.caption: 'Small muted supporting text — hints, meta lines.',
  PpForgeTextRole.money: 'An amount of money: bold, tabular digits.',
};

/// `/dev/tokens/icons` — every PpForgeIcons entry by group.
Widget buildIconsPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in PpForgeIcons.catalog.entries)
        HubDemo(
          title: entry.key,
          child: Wrap(
            spacing: PpForgeSpacing.md,
            runSpacing: PpForgeSpacing.md,
            children: [
              for (final icon in entry.value.entries)
                SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      PpForgeIcon(
                        icon.value,
                        size: PpForgeIconSize.lg,
                        color: scheme.onSurface,
                      ),
                      const SizedBox(height: PpForgeSpacing.xxs),
                      PpForgeText(
                        icon.key,
                        role: PpForgeTextRole.caption,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
