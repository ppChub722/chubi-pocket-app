import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// The hub's fake picture server: a path with `ok` paints a picture, any
/// other path fails (the fallback demos). No network.
Future<Uint8List> avatarDemoFetch(Uri url) async {
  if (!url.path.contains('ok')) throw StateError('demo: no picture at $url');
  const s = 96.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    const Rect.fromLTWH(0, 0, s, s),
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(s, s), const [
        Color(0xFFFFB74D),
        Color(0xFFE57373),
      ]),
  );
  final skin = Paint()..color = const Color(0xFFFFF3E0);
  c.drawCircle(const Offset(s / 2, s * 0.4), s * 0.2, skin);
  c.drawOval(
    Rect.fromCenter(
      center: const Offset(s / 2, s * 0.98),
      width: s * 0.78,
      height: s * 0.62,
    ),
    skin,
  );
  final image = await rec.endRecording().toImage(s.toInt(), s.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Wraps [child] in the fake picture server.
Widget avatarDemoScope(Widget child) => ServerImageScope(
  baseUrl: 'https://demo.invalid/api/v1',
  fetch: avatarDemoFetch,
  child: child,
);

const _icon = IconCode(
  icon: 'person',
  background: 'solid',
  bgColors: ['#26A69A'],
  border: 'thin',
  borderColors: ['#00796B'],
);

AvatarData _photo({
  AvatarBorder? border,
  bool broken = false,
  IconCode? icon,
}) => AvatarData(
  kind: AvatarKind.photo,
  photoUrl: broken ? '/api/v1/avatars/gone?v=1' : '/api/v1/avatars/ok?v=2',
  iconCode: icon,
  initials: 'AC',
  colors: const ['#E8A33D', '#F06292'],
  border: border,
);

/// A brand logo stand-in for the corner badge (the real one is the BE's
/// `logo_url` through [ServerImageScope]).
Widget _logo() => const ColoredBox(
  color: Color(0xFF26A5E4),
  child: Center(child: Icon(Icons.send, size: 9, color: Color(0xFFFFFFFF))),
);

/// `Avatar` — every state the BE can send, the fallbacks, borders, a corner
/// logo, sizes; plus `ProfileColors`.
Widget buildAvatarStates(BuildContext context) {
  Widget left(Widget child) =>
      Align(alignment: Alignment.centerLeft, child: child);
  final palette = Theme.of(context).extension<AppColors>()!;
  final surface = Theme.of(context).colorScheme.surface;
  Widget dots(List<Color> cs) => Wrap(
    spacing: AppSpacing.xs,
    children: [
      for (final c in cs)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
    ],
  );
  return avatarDemoScope(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          title: 'Avatar (0.4.2 1b) — every state',
          columns: 2,
          note:
              'Draws the BE\'s avatar object as it says. A photo loads with '
              'the Bearer token through ServerImageScope (here a fake server) '
              'and is cached by its URL (?v= included); a load error falls '
              'back to the icon, then the initials.',
          uses: [
            HubUse(
              label: 'photo',
              page: 'Settings card, profile, members',
              child: left(Avatar(_photo())),
            ),
            HubUse(
              label: 'photo — thin ring',
              page: 'Profile',
              child: left(
                Avatar(
                  _photo(
                    border: const AvatarBorder(
                      style: 'thin',
                      colors: ['#F06292'],
                    ),
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'photo — thick ring',
              page: 'Profile',
              child: left(
                Avatar(
                  _photo(
                    border: const AvatarBorder(
                      style: 'thick',
                      colors: ['#26A69A'],
                    ),
                  ),
                  size: 56,
                ),
              ),
            ),
            HubUse(
              label: 'photo — dashed ring',
              page: 'Profile',
              child: left(
                Avatar(
                  _photo(
                    border: const AvatarBorder(
                      style: 'dashed',
                      colors: ['@presetThemeColor1'],
                    ),
                  ),
                  size: 56,
                ),
              ),
            ),
            HubUse(
              label: 'photo fails → its icon',
              page: 'Any person',
              child: left(Avatar(_photo(broken: true, icon: _icon))),
            ),
            HubUse(
              label: 'photo fails, no icon → initials',
              page: 'Any person',
              child: left(Avatar(_photo(broken: true))),
            ),
            HubUse(
              label: 'icon',
              page: 'Any person',
              child: left(Avatar(AvatarData.forName('Aom', iconCode: _icon))),
            ),
            HubUse(
              label: 'initials (colour 1)',
              page: 'A typed name, a contact with no icon',
              child: left(Avatar(AvatarData.forName('Aom Chan'))),
            ),
            HubUse(
              label: 'initials — empty name',
              page: 'Any person',
              child: left(Avatar(AvatarData.forName(''))),
            ),
            HubUse(
              label: 'photo + brand logo badge',
              page: 'Profile → การเชื่อมต่อ',
              child: left(Avatar(_photo(), size: 48, badge: _logo())),
            ),
            HubUse(
              label: 'sizes 20 / 32 / 40 / 56 / 80',
              page: 'Everywhere',
              wide: true,
              child: Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  for (final s in const [20.0, 32.0, 40.0, 56.0, 80.0])
                    HubCell(
                      caption: '${s.round()}',
                      child: Avatar(_photo(), size: s),
                    ),
                ],
              ),
            ),
            HubUse(
              label:
                  'ProfileColors — slots 1, 2, 3 of ["#E8A33D", "", "#F06292"]',
              page: 'Hero tints, split pills',
              wide: true,
              child: dots([
                for (var n = 0; n < 3; n++)
                  ProfileColors.slot(
                    const ['#E8A33D', '', '#F06292'],
                    n,
                    palette: palette,
                    surface: surface,
                  ),
              ]),
            ),
            HubUse(
              label: 'ProfileColors.distinct — 5 from one colour',
              page: 'Pages needing several',
              wide: true,
              child: dots(
                ProfileColors.distinct(
                  const ['#26A69A'],
                  5,
                  palette: palette,
                  surface: surface,
                ),
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'Avatar',
          note: 'Pick a kind; a broken photo shows the fallback chain.',
          controls: [
            PlayChoice<String>('kind', [
              ('photo', 'photo'),
              ('photo (broken)', 'broken'),
              ('icon', 'icon'),
              ('initials', 'initials'),
            ]),
            PlayChoice<String>('border', [
              ('none', ''),
              ('thin', 'thin'),
              ('thick', 'thick'),
              ('dashed', 'dashed'),
            ]),
            const PlayText('name', initialValue: 'Aom Chan'),
            const PlayBool('logo badge'),
            const PlayNum('size', min: 16, max: 96, step: 4, initialValue: 56),
          ],
          builder: (context, v) {
            final name = v<String>('name');
            final style = v<String>('border');
            final border = style.isEmpty
                ? null
                : AvatarBorder(style: style, colors: const ['#F06292']);
            final avatar = switch (v<String>('kind')) {
              'photo' => _photo(border: border),
              'broken' => _photo(broken: true, border: border),
              'icon' => AvatarData.forName(name, iconCode: _icon),
              _ => AvatarData.forName(name),
            };
            return left(
              Avatar(
                avatar,
                size: v<double>('size'),
                badge: v<bool>('logo badge') ? _logo() : null,
              ),
            );
          },
        ),
      ],
    ),
  );
}
