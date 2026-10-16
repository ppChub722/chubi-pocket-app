import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/ui/atoms/card` — PpForgeCard: every surface in the app. The reference
/// for the hub's playground pattern: live instance + controls on top (the
/// widget's real options), then "In the app".
Widget buildCardPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  Widget body(String label) => Padding(
    padding: const EdgeInsets.all(PpForgeSpacing.lg),
    child: Text(label, style: text.bodyMedium),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubInApp(
        columns: 2,
        note: 'The real presets, each with the page that uses it.',
        uses: [
          HubUse(
            label: 'plain — the theme card',
            page: 'Lists, summaries',
            child: PpForgeCard(child: body('plain — lists, summaries')),
          ),
          HubUse(
            label: 'bordered — a raised surface, normal outline',
            page: 'Picker cards, nested cards',
            child: PpForgeCard(
              style: PpForgeCardStyle.bordered,
              child: body('bordered — a card inside a card'),
            ),
          ),
          HubUse(
            label: 'accent — 1.5 coloured border',
            page: 'Icon maker preview',
            child: PpForgeCard(
              style: PpForgeCardStyle.accent,
              color: scheme.primary,
              child: body('accent — the icon preview card'),
            ),
          ),
          HubUse(
            label: 'tinted + glyph — a colour wash',
            page: 'Wallet cards, More hub, dashboard tiles',
            child: PpForgeCard(
              style: PpForgeCardStyle.tinted,
              color: scheme.tertiary,
              glyph: PpForgeIcons.budget,
              child: body('tinted — a wash + a faded corner glyph'),
            ),
          ),
          HubUse(
            label: 'flat — no fill, no border',
            page: 'PickCard (nothing picked)',
            child: PpForgeCard(
              style: PpForgeCardStyle.flat,
              child: body('flat — an empty slot'),
            ),
          ),
          HubUse(
            label: 'tappable',
            page: 'List rows, pick cards',
            child: PpForgeCard(
              onTap: () {},
              child: body('tappable — ripple on tap'),
            ),
          ),
          HubUse(
            label: 'selected — 1.5 primary border',
            page: 'Pickers',
            child: PpForgeCard(
              selected: true,
              child: body('selected — a picked card'),
            ),
          ),
          HubUse(
            label: 'borderColor — warning / error outline',
            page: 'Scheduled list (overdue)',
            child: PpForgeCard(
              borderColor: scheme.error,
              borderWidth: 1.5,
              child: body('borderColor — overdue, error'),
            ),
          ),
        ],
      ),

      HubPlayground(
        title: 'PpForgeCard',
        note:
            'Every option PpForgeCard has. color is the accent border / the tint '
            'wash (accent and tinted need one); glyph is tinted only.',
        controls: [
          PlayChoice<PpForgeCardStyle>('style', [
            for (final s in PpForgeCardStyle.values) (s.name, s),
          ]),
          PlayChoice<Color>('color', [
            ('primary', scheme.primary),
            ('tertiary', scheme.tertiary),
            ('error', scheme.error),
          ]),
          const PlayBool('glyph'),
          const PlayNum(
            'glyphSize',
            min: 48,
            max: 136,
            step: 8,
            initialValue: 88,
          ),
          const PlayBool('selected'),
          const PlayBool('onTap'),
          PlayChoice<Color?>('borderColor', [
            ('style default', null),
            ('error', scheme.error),
          ]),
          const PlayNum('padding', min: 0, max: 32, step: 4, initialValue: 16),
        ],
        builder: (context, v) {
          final style = v<PpForgeCardStyle>('style');
          return PpForgeCard(
            style: style,
            color: v<Color>('color'),
            glyph: v<bool>('glyph') ? PpForgeIcons.budget : null,
            glyphSize: v<double>('glyphSize'),
            selected: v<bool>('selected'),
            borderColor: v<Color?>('borderColor'),
            borderWidth: v<Color?>('borderColor') == null ? null : 1.5,
            onTap: v<bool>('onTap') ? () {} : null,
            padding: EdgeInsets.all(v<double>('padding')),
            child: Text('${style.name} card', style: text.bodyMedium),
          );
        },
      ),
    ],
  );
}
