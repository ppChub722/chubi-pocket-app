import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';
import 'avatar_states_demo.dart';

/// Profile + connections (0.4.2 1b): the profile hero (picture + colour
/// dots), the picture radio rows, the connection rows / hero / link button,
/// provider logos, and the icon maker's colour-only mode. Pictures come from
/// the hub's fake server (a path with `ok` paints, anything else fails).
Widget buildProfileConnectionsPage(BuildContext context) {
  void noop() {}
  Widget left(Widget child) =>
      Align(alignment: Alignment.centerLeft, child: child);
  const tg = Color(0xFF26A5E4);
  const logo = '/api/v1/brand-logos/ok-telegram.png?v=1';
  const brokenLogo = '/api/v1/brand-logos/line.png?v=1';
  const photo = '/api/v1/avatars/ok?v=2';
  const photoAvatar = AvatarData(
    kind: AvatarKind.photo,
    photoUrl: photo,
    initials: 'PP',
    colors: ['#E8A33D', '#F06292'],
    border: AvatarBorder(style: 'thick', colors: ['#F06292']),
  );
  const iconAvatar = AvatarData(
    kind: AvatarKind.icon,
    iconCode: IconCode(
      icon: 'person',
      background: 'solid',
      bgColors: ['#5AA9F0'],
    ),
    initials: 'PP',
    colors: ['#5AA9F0', '#4DD6C1', '#9575CD'],
  );
  Widget chip(String label, {bool danger = false}) => AppButton(
    label: label,
    variant: danger
        ? AppButtonVariant.destructiveOutlined
        : AppButtonVariant.outlined,
    size: AppButtonSize.chip,
    onPressed: noop,
  );

  return avatarDemoScope(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          title: 'ProviderLogo · ProviderLogoStrip · ProfileColorDots',
          columns: 2,
          note:
              'The BE\'s logo_url (cached by ?v=). grey = not linked (the '
              'logo\'s luminance in the theme grey). A load error shows the '
              'first letter. Dots: colours 1–3, an unset slot is a dashed '
              'ring.',
          uses: [
            HubUse(
              label: 'logo · grey · broken',
              page: 'Connection rows',
              child: left(
                const Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ProviderLogo(url: logo, name: 'Telegram'),
                    ProviderLogo(url: logo, name: 'Telegram', grey: true),
                    ProviderLogo(url: brokenLogo, name: 'LINE'),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'strip (20 px)',
              page: 'Settings profile card, line 3',
              child: left(
                const ProviderLogoStrip(
                  logos: [(logo, 'Telegram'), (brokenLogo, 'LINE')],
                ),
              ),
            ),
            HubUse(
              label: 'dots: 3 set',
              page: 'Profile hero',
              child: left(
                const ProfileColorDots(
                  colors: ['#5AA9F0', '#4DD6C1', '#9575CD'],
                ),
              ),
            ),
            HubUse(
              label: 'dots: 2 set, 3 unset',
              page: 'Profile hero (photo)',
              child: left(
                const ProfileColorDots(colors: ['#E8A33D', '#F06292']),
              ),
            ),
            HubUse(
              label: 'radio marks',
              page: 'รูปโปรไฟล์ list',
              child: left(
                const Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    AppRadioMark(selected: true),
                    AppRadioMark(selected: false),
                    AppRadioMark(selected: false, enabled: false),
                  ],
                ),
              ),
            ),
          ],
        ),
        HubDemo(
          title: 'ProfileHeroCard — view (photo + source badge, icon)',
          note:
              'Tinted with colour 1. The picture is 56 px with the source '
              'app\'s logo as a badge (photo sources only), the colour dots '
              'under it; the name big, @username under it; ✏️ at the end; '
              'the email row inside the card. Long-press = edit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeroCard(
                tint: const Color(0xFFE8A33D),
                picture: const ProfileHeroAvatar(
                  avatar: photoAvatar,
                  badge: ProviderLogo(url: logo, name: 'Telegram'),
                ),
                name: 'ppond',
                handle: '@ppond',
                onLongPress: noop,
                actions: [CardActionButton(icon: AppIcons.edit, onTap: noop)],
                facts: const [
                  HeroFact(
                    'อีเมล',
                    'poompich@example.com',
                    icon: AppIcons.email,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ProfileHeroCard(
                tint: const Color(0xFF5AA9F0),
                picture: const ProfileHeroAvatar(avatar: iconAvatar),
                name: 'ppond',
                handle: '@ppond',
                actions: [CardActionButton(icon: AppIcons.edit, onTap: noop)],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ProfileHeroCard — edit',
          note:
              'The preview with a ✎ badge (tap = the icon maker: full for '
              'the icon, colour-only for a photo), the dots, and the inputs '
              'beside it.',
          child: ProfileHeroCard(
            editing: true,
            tint: const Color(0xFFE8A33D),
            picture: ProfileHeroAvatar(
              avatar: photoAvatar,
              editing: true,
              onTap: noop,
            ),
            fields: [
              AppInput.card(
                controller: TextEditingController(text: 'ppond'),
                label: 'ชื่อที่แสดง',
              ),
              AppInput.card(
                controller: TextEditingController(text: '@ppond (แก้ไม่ได้)'),
                label: 'ชื่อผู้ใช้',
                locked: true,
              ),
              AppInput.card(
                controller: TextEditingController(text: 'poompich@example.com'),
                label: 'อีเมล',
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'AvatarSourceRow — the รูปโปรไฟล์ radio list',
          note:
              'A radio, a 36 px picture, title / one short line, small '
              'buttons at the end (their taps never pick the row). Coming '
              'soon = muted, no taps. Without a radio it is the connection '
              'page\'s "รูปจาก <App>" row.',
          child: SectionCard(
            first: true,
            title: 'รูปโปรไฟล์',
            children: [
              AvatarSourceRow(
                title: 'ไอคอน',
                thumb: const Avatar(iconAvatar, size: 36),
                selected: false,
                onTap: noop,
                actions: [chip('แก้')],
              ),
              const AvatarSourceRow(
                title: 'อัปโหลดเอง',
                selected: false,
                comingSoon: true,
              ),
              AvatarSourceRow(
                title: 'Telegram',
                subtitle: 'นำเข้าเมื่อ 28 ต.ค. 2026',
                thumb: const Avatar(photoAvatar, size: 36),
                selected: true,
                onTap: noop,
                actions: [chip('อัปเดต'), chip('ลบ', danger: true)],
              ),
              AvatarSourceRow(
                title: 'รูปจาก Telegram',
                subtitle: 'ยังไม่ได้นำเข้า',
                actions: [chip('นำเข้า')],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ConnectionRow — every state',
          note:
              'Linked + picture: the picture with the logo badge, tinted in '
              'the brand colour, 🔗 @account. Linked, no picture: the logo. '
              'Not linked: grey logo, "แตะเพื่อเชื่อม", "ยังไม่เชื่อม". '
              'available false: coming soon.',
          child: SectionCard(
            first: true,
            title: 'การเชื่อมต่อ',
            children: [
              ConnectionRow(
                name: 'Telegram',
                logoUrl: logo,
                state: ConnectionRowState.linkedPhoto,
                brand: tg,
                photoUrl: photo,
                account: '@nong',
                onTap: noop,
              ),
              ConnectionRow(
                name: 'Telegram',
                logoUrl: logo,
                state: ConnectionRowState.linkedLogo,
                brand: tg,
                account: '@nong',
                onTap: noop,
              ),
              ConnectionRow(
                name: 'Telegram',
                logoUrl: logo,
                state: ConnectionRowState.unlinked,
                brand: tg,
                notLinkedLabel: 'ยังไม่เชื่อม',
                tapToLinkLabel: 'แตะเพื่อเชื่อม',
                onTap: noop,
              ),
              const ConnectionRow(
                name: 'LINE',
                logoUrl: brokenLogo,
                state: ConnectionRowState.comingSoon,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'ConnectionHeroCard · ConnectionLinkButton',
          note:
              'Linked: tinted with the brand colour, the picture with the '
              'logo badge, the name, 🔗 account (ellipsis) and when it was '
              'linked. Not linked: plain card, grey logo; the big brand '
              'button links. A brand too light for its white label '
              '(Telegram, LINE) is darkened to 4.5:1 '
              '(ConnectionLinkButton.fillFor).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ConnectionHeroCard(
                name: 'Telegram',
                logoUrl: logo,
                linked: true,
                brand: tg,
                photoUrl: photo,
                account: '@a_rather_long_telegram_username_here',
                linkedAtText: 'เชื่อมเมื่อ 28 ต.ค. 2026',
              ),
              const SizedBox(height: AppSpacing.md),
              const ConnectionHeroCard(
                name: 'Telegram',
                logoUrl: logo,
                linked: false,
                brand: tg,
                notLinkedLabel: 'ยังไม่เชื่อม',
              ),
              const SizedBox(height: AppSpacing.md),
              ConnectionLinkButton(
                label: 'เชื่อม Telegram',
                brand: tg,
                onPressed: noop,
              ),
              const SizedBox(height: AppSpacing.md),
              ConnectionLinkButton(
                label: 'เชื่อม LINE',
                brand: const Color(0xFF06C755),
                onPressed: noop,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Icon maker — colour-only mode (AvatarColorsPanel)',
          note:
              'For a photo source: colours 1–3, the ring style (none / thin '
              '/ thick / dashed) and the ring colour; the swatches paint the '
              'focused target. showAvatarColorsSheet opens it as a sheet '
              '(a dialog on a tablet); the result is an AvatarColorsDraft '
              '(colors + border for avatar_settings).',
          child: SizedBox(
            height: 640,
            child: AvatarColorsPanel(
              initial: AvatarColorsDraft.from(const [
                '#E8A33D',
              ], const AvatarBorder(style: 'thin', colors: ['#F06292'])),
              onDone: (_) {},
              previewBuilder: (d) => Avatar(
                AvatarData(
                  kind: AvatarKind.photo,
                  photoUrl: photo,
                  initials: 'PP',
                  colors: d.profileColors.isEmpty
                      ? const ['#26A69A']
                      : d.profileColors,
                  border: d.border,
                ),
                size: 72,
              ),
            ),
          ),
        ),
        HubPlayground(
          title: 'Colour-only sheet',
          note: 'Opens the real sheet with the playground\'s start values.',
          controls: [
            PlayChoice<String>('ring', [
              ('none', AvatarBorderStyle.none),
              ('thin', AvatarBorderStyle.thin),
              ('thick', AvatarBorderStyle.thick),
              ('dashed', AvatarBorderStyle.dashed),
            ]),
          ],
          builder: (context, v) => left(
            AppButton(
              label: 'Open',
              onPressed: () => showAvatarColorsSheet(
                context: context,
                initial: AvatarColorsDraft.from(const [
                  '#E8A33D',
                ], null).withBorderStyle(v<String>('ring')),
                previewBuilder: (d) => Avatar(
                  AvatarData(
                    kind: AvatarKind.photo,
                    photoUrl: photo,
                    initials: 'PP',
                    colors: d.profileColors,
                    border: d.border,
                  ),
                  size: 72,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
