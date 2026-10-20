import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/ui/atoms/card` — AppCard: every surface in the app. The reference
/// for the hub's playground pattern: live instance + controls on top (the
/// widget's real options), then "In the app".
Widget buildCardPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  Widget body(String label) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text(label, style: text.bodyMedium),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubDemo(
        title: 'AppCardPick: option cards in a picker',
        note:
            'The chosen card gets one solid primary line, the others a dashed '
            'one. The wallet picker wraps its cards in it.',
        child: Row(
          children: [
            Expanded(
              child: AppCardPick(
                chosen: true,
                child: AppCard(
                  style: AppCardStyle.bordered,
                  child: body('chosen'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppCardPick(
                chosen: false,
                child: AppCard(
                  style: AppCardStyle.bordered,
                  child: body('not chosen'),
                ),
              ),
            ),
          ],
        ),
      ),
      HubInApp(
        columns: 2,
        note: 'The real presets, each with the page that uses it.',
        uses: [
          HubUse(
            label: 'plain — the theme card',
            page: 'Lists, summaries',
            child: AppCard(child: body('plain — lists, summaries')),
          ),
          HubUse(
            label: 'bordered — a raised surface, normal outline',
            page: 'Picker cards, nested cards',
            child: AppCard(
              style: AppCardStyle.bordered,
              child: body('bordered — a card inside a card'),
            ),
          ),
          HubUse(
            label: 'accent — 1.5 coloured border',
            page: 'Icon maker preview',
            child: AppCard(
              style: AppCardStyle.accent,
              color: scheme.primary,
              child: body('accent — the icon preview card'),
            ),
          ),
          HubUse(
            label: 'tinted + glyph — a colour wash',
            page: 'Wallet cards, More hub, dashboard tiles',
            child: AppCard(
              style: AppCardStyle.tinted,
              color: scheme.tertiary,
              glyph: AppIcons.budget,
              child: body('tinted — a wash + a faded corner glyph'),
            ),
          ),
          HubUse(
            label: 'flat — no fill, no border',
            page: 'PickCard (nothing picked)',
            child: AppCard(
              style: AppCardStyle.flat,
              child: body('flat — an empty slot'),
            ),
          ),
          HubUse(
            label: 'tappable',
            page: 'List rows, pick cards',
            child: AppCard(
              onTap: () {},
              child: body('tappable — ripple on tap'),
            ),
          ),
          HubUse(
            label: 'selected — 1.5 primary border',
            page: 'Pickers',
            child: AppCard(
              selected: true,
              child: body('selected — a picked card'),
            ),
          ),
          HubUse(
            label: 'borderColor — warning / error outline',
            page: 'Scheduled list (overdue)',
            child: AppCard(
              borderColor: scheme.error,
              borderWidth: 1.5,
              child: body('borderColor — overdue, error'),
            ),
          ),
        ],
      ),

      HubPlayground(
        title: 'AppCard',
        note:
            'Every option AppCard has. color is the accent border / the tint '
            'wash (accent and tinted need one); glyph is tinted only.',
        controls: [
          PlayChoice<AppCardStyle>('style', [
            for (final s in AppCardStyle.values) (s.name, s),
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
          final style = v<AppCardStyle>('style');
          return AppCard(
            style: style,
            color: v<Color>('color'),
            glyph: v<bool>('glyph') ? AppIcons.budget : null,
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
