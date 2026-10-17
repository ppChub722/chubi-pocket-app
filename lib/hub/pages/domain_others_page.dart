import 'package:flutter/material.dart';

import '../../core/network/connection_cubit.dart';
import '../../features/app_version/presentation/widgets/update_banner.dart';
import '../../features/auth/presentation/widgets/auth_widgets.dart';
import '../../features/notifications/domain/notification.dart';
import '../../features/notifications/presentation/widgets/notification_tile.dart';
import '../../features/projects/domain/project.dart';
import '../../features/projects/presentation/widgets/project_common.dart';
import '../../features/projects/presentation/widgets/project_tx_tiles.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/others` — notification tiles, project pieces,
/// the brand logo, the auth header and the two top-of-screen banners.
///
/// Gate pieces: BrandLogo, OfflineBanner. Feature pieces (sample models, no
/// cubit): NotificationTile, ProjectTxIcon,
/// ProjectMemberAvatar, projectStatusTone chips, AuthBrandHeader,
/// AuthOrDivider, GoogleSignInButton, UpdateBannerStrip. Skipped (need
/// cubits / repositories): ProjectTxTreeTile
/// (ProjectView + repository), AuthPrefsBar (locale / theme cubits),
/// UpdateBanner (AppVersionCubit; its strip is shown instead).
Widget buildOthersPage(BuildContext context) {
  final now = DateTime.now();

  AppNotification notif(
    NotificationType type, {
    Map<String, dynamic> payload = const {},
    DateTime? readAt,
    DateTime? actionedAt,
    String actor = 'Aom Chan',
    bool? awaitsAnswer,
  }) => AppNotification(
    id: type.wire,
    type: type,
    actor: NotificationActor(userId: 'x', displayName: actor),
    payload: payload,
    createdAt: now,
    state: actionedAt != null
        ? NotificationState.actioned
        : readAt != null
        ? NotificationState.read
        : NotificationState.unread,
    // The BE decides which rows still show their answer buttons: here, the
    // ones not yet read or actioned (the demo rows that are informational
    // pass false).
    awaitsAnswer:
        awaitsAnswer ??
        (actionedAt == null &&
            readAt == null &&
            type != NotificationType.unknown),
    readAt: readAt,
    actionedAt: actionedAt,
  );

  Widget notifCard(AppNotification n) => AppCard(
    padding: EdgeInsets.zero,
    child: NotificationTile(
      notification: n,
      onTap: (_) {},
      onAccept: (_) {},
      onReject: (_) {},
    ),
  );

  const memberWithIcon = ProjectMember(
    id: 'm2',
    projectId: 'p1',
    displayName: 'Bee',
    role: MemberRole.owner,
    status: MemberStatus.active,
    iconCode: IconCode(icon: 'favorite', iconColors: ['#EF4444']),
  );
  ProjectTransaction ptx(String type) => ProjectTransaction(
    id: type,
    projectId: 'p1',
    transactionMemberId: 'm1',
    recordUserId: 'u1',
    type: type,
    amount: 1200,
    currency: 'THB',
    date: '2026-10-10',
    marks: const [],
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubInApp(
        columns: 2,
        note:
            'Real pieces from sample models (no cubit), many variants side by '
            'side. Wide ones take a whole row.',
        uses: [
          // ── Notifications ──
          HubUse(
            wide: true,
            label: 'NotificationTile — link request: Accept / Decline',
            page: 'Notifications inbox, Home',
            child: notifCard(notif(NotificationType.contactLinkRequest)),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — wallet invite: Accept / Decline',
            page: 'Notifications inbox, Home',
            child: notifCard(
              notif(
                NotificationType.accountInvite,
                payload: const {'account_name': 'บัญชีบ้าน'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — one-tap: add the debt (split created)',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.splitCreated,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — one-tap: record the receipt (paid)',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.splitPaid,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — one-tap: copy to my book',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.projectTxRecordedForYou,
                payload: const {'amount': 1200, 'currency': 'THB'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — read + answered: "accepted" chip',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.contactLinkRequest,
                readAt: now,
                actionedAt: now,
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — read + actioned split',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.splitCreated,
                readAt: now,
                actionedAt: now,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — informational, unread (no buttons)',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.projectAdded,
                payload: const {'project_name': 'Chiang Mai trip'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — informational, read (no dot, no tint)',
            page: 'Notifications inbox',
            child: notifCard(
              notif(
                NotificationType.splitReceived,
                readAt: now,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTile — unknown type (a newer server)',
            page: 'Notifications inbox',
            child: notifCard(notif(NotificationType.unknown, readAt: now)),
          ),

          // ── Project pieces ──
          HubUse(
            label: 'ProjectTxIcon — expense',
            page: 'Project dashboard tab',
            child: projectTxIcon(context, ptx('expense')),
          ),
          HubUse(
            label: 'ProjectTxIcon — income',
            page: 'Project dashboard tab',
            child: projectTxIcon(context, ptx('income')),
          ),
          HubUse(
            label: 'ProjectTxIcon — size 28',
            page: 'Project dashboard tab',
            child: projectTxIcon(context, ptx('expense'), size: 28),
          ),
          HubUse(
            label: 'ProjectMemberAvatar — a coloured initial',
            page: 'Project members page, member pick card',
            child: const ProjectMemberAvatar(name: 'Aom Chan'),
          ),
          HubUse(
            label: 'ProjectMemberAvatar — own icon',
            page: 'Project members page, dashboard',
            child: const ProjectMemberAvatar(
              name: 'Bee',
              iconCode: IconCode(icon: 'favorite', iconColors: ['#EF4444']),
            ),
          ),
          HubUse(
            label: 'ProjectMemberAvatar — size 48',
            page: 'Project members page',
            child: const ProjectMemberAvatar(name: 'Aom Chan', size: 48),
          ),
          HubUse(
            label: 'ProjectMemberPickCard — picked',
            page: 'Project row form (payer)',
            child: ProjectMemberPickCard(
              name: 'Aom Chan',
              label: 'Paid by',
              onTap: () {},
            ),
          ),
          HubUse(
            label: 'ProjectMemberPickCard — empty with error',
            page: 'Project row form (payer)',
            child: ProjectMemberPickCard(
              name: null,
              label: 'Paid by',
              placeholder: 'Pick who paid',
              errorText: 'Pick who paid',
              onTap: () {},
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTileView — pending, unread (plain values)',
            page: 'Notifications inbox, Home',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: NotificationTileView(
                actorName: 'Aom Chan',
                title: 'Aom Chan wants to link with you',
                timeText: '09:30',
                amountText: '฿450',
                typeIcon: AppIcons.link,
                unread: true,
                pending: true,
                acceptLabel: 'Accept',
                rejectLabel: 'Decline',
                rejectConfirm: const NotificationRejectConfirm(
                  title: 'Decline?',
                  message: 'The request will be dismissed.',
                  confirmLabel: 'Decline',
                ),
                onTap: () {},
                onAccept: () {},
                onReject: () {},
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'NotificationTileView — answered chip',
            page: 'Notifications inbox, Home',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: NotificationTileView(
                actorName: 'Bee',
                title: 'Bee split Dinner with you',
                timeText: '08:10',
                typeIcon: AppIcons.split,
                acceptedLabel: 'Done',
                acceptLabel: 'Add',
                rejectLabel: 'Skip',
                onTap: () {},
              ),
            ),
          ),
          for (final s in ProjectStatus.values)
            HubUse(
              label: 'Project status chip — ${s.name}',
              page: 'Projects list, Project detail',
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppChip(
                  label: s.name,
                  dot: true,
                  selected: true,
                  tone: projectStatusTone(s),
                ),
              ),
            ),

          // ── Brand, auth, banners ──
          const HubUse(
            label: 'BrandLogo — 128 (splash)',
            page: 'Splash, Update-required page',
            child: Align(alignment: Alignment.centerLeft, child: BrandLogo()),
          ),
          const HubUse(
            label: 'BrandLogo — 88',
            page: 'Auth header (login)',
            child: Align(
              alignment: Alignment.centerLeft,
              child: BrandLogo(size: 88),
            ),
          ),
          const HubUse(
            label: 'BrandLogo — 56',
            page: 'Auth header (register)',
            child: Align(
              alignment: Alignment.centerLeft,
              child: BrandLogo(size: 56),
            ),
          ),
          const HubUse(
            label: 'BrandLogo — 32',
            page: 'Small marks',
            child: Align(
              alignment: Alignment.centerLeft,
              child: BrandLogo(size: 32),
            ),
          ),
          HubUse(
            wide: true,
            label: 'BankBrand — the banks\' own colours by BOT code',
            page: 'Bank picker (wallet identifiers)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in const [
                  '004',
                  '014',
                  '002',
                  '006',
                  '025',
                  '999',
                ])
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BankBrand.of(code),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          const HubUse(
            wide: true,
            label: 'AuthBrandHeader — logo, name, tagline (5 taps opens hub)',
            page: 'Login',
            child: AuthBrandHeader(),
          ),
          const HubUse(
            wide: true,
            label: 'AuthBrandHeader — compact: smaller logo, no tagline',
            page: 'Register',
            child: AuthBrandHeader(compact: true),
          ),
          const HubUse(
            wide: true,
            label: 'AuthOrDivider',
            page: 'Login, Register',
            child: AuthOrDivider(),
          ),
          const HubUse(
            wide: true,
            label: 'GoogleSignInButton — no handler: dimmed, "coming soon"',
            page: 'Login, Register',
            child: GoogleSignInButton(),
          ),
          HubUse(
            wide: true,
            label: 'GoogleSignInButton — live',
            page: 'Login, Register (when enabled)',
            child: GoogleSignInButton(onPressed: () {}),
          ),
          HubUse(
            wide: true,
            label: 'GoogleSignInButton — loading spinner',
            page: 'Login, Register (signing in)',
            child: GoogleSignInButton(onPressed: () {}, loading: true),
          ),
          for (final (label, status) in [
            (
              'OfflineBanner — offline: stays until the connection is back, Retry polls now',
              ConnectionStatus.offline,
            ),
            (
              'OfflineBanner — a retry is running',
              ConnectionStatus.reconnecting,
            ),
            (
              'OfflineBanner — back online: a short "connected again", then it goes',
              ConnectionStatus.backOnline,
            ),
          ])
            HubUse(
              wide: true,
              label: label,
              page: 'App shell (every page)',
              child: OfflineBanner(
                state: ServerConnectionState(status: status),
                onRetry: () {},
              ),
            ),
          HubUse(
            wide: true,
            label: 'UpdateBannerStrip — a newer build is out',
            page: 'App shell (update banner)',
            child: UpdateBannerStrip(onUpdate: () {}, onDismiss: () {}),
          ),
        ],
      ),
      HubPlayground(
        title: 'NotificationTile',
        note:
            'type picks the sentence and the actions; readAt (read) drops the '
            'dot and tint; actionedAt (answered) swaps the buttons for a chip.',
        controls: [
          PlayChoice<NotificationType>('type', [
            for (final t in NotificationType.values) (t.name, t),
          ], initial: NotificationType.contactLinkRequest),
          const PlayBool('read'),
          const PlayBool('actioned'),
        ],
        builder: (context, v) => notifCard(
          notif(
            v<NotificationType>('type'),
            payload: const {
              'amount': 450,
              'currency': 'THB',
              'account_name': 'บัญชีบ้าน',
              'project_name': 'Chiang Mai trip',
            },
            readAt: v<bool>('read') ? now : null,
            actionedAt: v<bool>('actioned') ? now : null,
          ),
        ),
      ),
      HubPlayground(
        title: 'ProjectTxIcon · ProjectMemberAvatar',
        note:
            'ProjectTxIcon: tx type and size. ProjectMemberAvatar: the member '
            '(own icon or an initial) and size.',
        controls: [
          PlayChoice<String>('type', const [
            ('expense', 'expense'),
            ('income', 'income'),
          ]),
          const PlayBool('memberIcon'),
          const PlayNum('size', min: 24, max: 64, step: 8, initialValue: 36),
        ],
        builder: (context, v) => HubRow(
          cells: [
            HubCell(
              caption: 'ProjectTxIcon',
              child: projectTxIcon(
                context,
                ptx(v<String>('type')),
                size: v<double>('size'),
              ),
            ),
            HubCell(
              caption: 'ProjectMemberAvatar',
              child: ProjectMemberAvatar(
                name: v<bool>('memberIcon') ? 'Bee' : 'Aom Chan',
                iconCode: v<bool>('memberIcon')
                    ? memberWithIcon.iconCode
                    : null,
                size: v<double>('size'),
              ),
            ),
          ],
        ),
      ),
      HubPlayground(
        title: 'Profile card (settings) — tint = avatar colour',
        note:
            'The settings profile card is a HeaderCard tinted with the '
            'avatar\'s own colour: the icon colour, else the initials colour '
            '(IconCode.tintFor with avatarName). Three users, three tints.',
        controls: const [],
        builder: (context, v) {
          final palette = Theme.of(context).extension<AppColors>()!;
          Widget card(String name) => HeaderCard(
            accent: null.tintFor(palette, avatarName: name),
            leading: UserAvatar(displayName: name, size: 52),
            title: Text(name),
            subtitle: Text('@${name.toLowerCase().replaceAll(' ', '')}'),
            trailing: const AppIcon(AppIcons.chevronRight),
          );
          return Column(
            children: [
              for (final n in const ['QA Lead', 'Aom Chan', 'Bee'])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: card(n),
                ),
            ],
          );
        },
      ),
      HubPlayground(
        title: 'BrandLogo · AuthBrandHeader · GoogleSignInButton',
        note:
            'BrandLogo: size. AuthBrandHeader: compact. GoogleSignInButton: '
            'onPressed (null = dimmed "coming soon") and loading.',
        controls: [
          const PlayNum(
            'logoSize',
            min: 32,
            max: 128,
            step: 16,
            initialValue: 56,
          ),
          const PlayBool('compact'),
          const PlayBool('onPressed', initialValue: true),
          const PlayBool('loading'),
        ],
        builder: (context, v) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: BrandLogo(size: v<double>('logoSize'))),
            const SizedBox(height: AppSpacing.md),
            AuthBrandHeader(compact: v<bool>('compact')),
            const SizedBox(height: AppSpacing.md),
            GoogleSignInButton(
              onPressed: v<bool>('onPressed') ? () {} : null,
              loading: v<bool>('loading'),
            ),
          ],
        ),
      ),
    ],
  );
}
