import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/connectivity_cubit.dart';
import '../../features/app_version/presentation/widgets/update_banner.dart';
import '../../features/auth/presentation/widgets/auth_widgets.dart';
import '../../features/notifications/domain/notification.dart';
import '../../features/notifications/presentation/widgets/notification_tile.dart';
import '../../features/transactions/domain/refs.dart';
import '../../features/personal_debts/domain/personal_debt.dart';
import '../../features/personal_debts/presentation/widgets/debt_widgets.dart';
import '../../features/projects/domain/project.dart';
import '../../features/projects/presentation/widgets/project_common.dart';
import '../../features/projects/presentation/widgets/project_tx_tiles.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/others` — debt tiles, notification tiles, project pieces,
/// the brand logo, the auth header and the two top-of-screen banners.
///
/// Gate pieces: BrandLogo, OfflineBanner. Feature pieces (sample models, no
/// cubit): DebtTile, debtStatusChip, NotificationTile, ProjectTxIcon,
/// ProjectMemberAvatar, projectStatusTone chips, AuthBrandHeader,
/// AuthOrDivider, GoogleSignInButton, UpdateBannerStrip. Skipped (need
/// cubits / repositories): DebtAvatar (ContactsCubit), ProjectTxTreeTile
/// (ProjectView + repository), AuthPrefsBar (locale / theme cubits),
/// UpdateBanner (AppVersionCubit; its strip is shown instead).
Widget buildOthersPage(BuildContext context) {
  final now = DateTime.now();

  PersonalDebt debt({
    required String id,
    required DebtDirection direction,
    required double amount,
    double settled = 0,
    DebtStatus status = DebtStatus.open,
    String? description,
  }) => PersonalDebt(
    id: id,
    userId: 'me',
    direction: direction,
    person: EmbeddedPerson(name: 'บี'),
    amount: amount,
    settledAmount: settled,
    currency: 'THB',
    status: status,
    description: description,
    createdAt: now,
  );

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

  const member = ProjectMember(
    id: 'm1',
    projectId: 'p1',
    displayName: 'Aom Chan',
    role: MemberRole.contributor,
    status: MemberStatus.active,
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
      HubPlayground(
        title: 'DebtTile',
        note:
            'One debt row. The tile reads its whole look from the debt: '
            'direction, status, amount, settledAmount (progress / overpaid) '
            'and description.',
        controls: [
          PlayChoice<DebtDirection>('direction', [
            for (final d in DebtDirection.values) (d.name, d),
          ]),
          PlayChoice<DebtStatus>('status', [
            for (final s in DebtStatus.values) (s.name, s),
          ]),
          const PlayNum(
            'settled',
            min: 0,
            max: 1200,
            step: 100,
            initialValue: 500,
          ),
          const PlayBool('description', initialValue: true),
        ],
        builder: (context, v) => AppCard(
          padding: EdgeInsets.zero,
          child: DebtTile(
            debt: debt(
              id: 'play',
              direction: v<DebtDirection>('direction'),
              amount: 1000,
              settled: v<double>('settled'),
              status: v<DebtStatus>('status'),
              description: v<bool>('description') ? 'Dinner' : null,
            ),
          ),
        ),
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
              child: ProjectTxIcon(
                tx: ptx(v<String>('type')),
                size: v<double>('size'),
              ),
            ),
            HubCell(
              caption: 'ProjectMemberAvatar',
              child: ProjectMemberAvatar(
                member: v<bool>('memberIcon') ? memberWithIcon : member,
                size: v<double>('size'),
              ),
            ),
          ],
        ),
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
      HubDemo(
        title: 'DebtTile — open',
        note:
            'Used in: Debt person page. '
            'One debt as a row on the person\'s page: description (what for) '
            'on top when there is one, then direction and date; the '
            'outstanding amount tinted by who owes whom; progress once '
            'something was repaid.',
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              DebtTile(
                debt: debt(
                  id: 'd1',
                  direction: DebtDirection.owedToMe,
                  amount: 1500,
                  description: 'Dinner',
                ),
              ),
              const AppDivider.row(),
              DebtTile(
                debt: debt(
                  id: 'd2',
                  direction: DebtDirection.iOwe,
                  amount: 800,
                ),
              ),
              const AppDivider.row(),
              DebtTile(
                debt: debt(
                  id: 'd3',
                  direction: DebtDirection.owedToMe,
                  amount: 2000,
                  settled: 500,
                  description: 'Concert tickets',
                ),
              ),
            ],
          ),
        ),
      ),
      HubDemo(
        title: 'DebtTile — overpaid · settled · cancelled',
        note:
            'Used in: Debt person page, Debt detail. '
            'Overpaid: the difference is owed the other way, flagged. Closed '
            'debts show a status chip and the full amount, muted.',
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              DebtTile(
                debt: debt(
                  id: 'd4',
                  direction: DebtDirection.owedToMe,
                  amount: 1000,
                  settled: 1200,
                  description: 'Taxi',
                ),
              ),
              const AppDivider.row(),
              DebtTile(
                debt: debt(
                  id: 'd5',
                  direction: DebtDirection.iOwe,
                  amount: 600,
                  settled: 600,
                  status: DebtStatus.settled,
                  description: 'Lunch',
                ),
              ),
              const AppDivider.row(),
              DebtTile(
                debt: debt(
                  id: 'd6',
                  direction: DebtDirection.owedToMe,
                  amount: 300,
                  status: DebtStatus.cancelled,
                ),
              ),
            ],
          ),
        ),
      ),
      HubDemo(
        title: 'debtStatusChip',
        note:
            'Used in: Debt detail page. '
            'Open (warning), settled (success), cancelled (neutral).',
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in DebtStatus.values) debtStatusChip(context, s),
          ],
        ),
      ),
      HubDemo(
        title: 'NotificationTile — answerable requests',
        note:
            'Used in: Notifications inbox, Home. '
            'Sender avatar with a type badge, the sentence, time and amount, '
            'a dot when unread. Pending invites and link requests carry '
            'big Accept / Decline buttons (Decline asks first).',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            notifCard(notif(NotificationType.contactLinkRequest)),
            const SizedBox(height: AppSpacing.sm),
            notifCard(
              notif(
                NotificationType.accountInvite,
                payload: const {'account_name': 'บัญชีบ้าน'},
              ),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'NotificationTile — one-tap actions',
        note:
            'Used in: Notifications inbox. '
            'Prompts with one action and "skip" (a ledger, not a sync): add '
            'the debt, record the receipt, copy to my book, update my copy.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            notifCard(
              notif(
                NotificationType.splitCreated,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            notifCard(
              notif(
                NotificationType.splitPaid,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            notifCard(
              notif(
                NotificationType.projectTxRecordedForYou,
                payload: const {'amount': 1200, 'currency': 'THB'},
              ),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'NotificationTile — read · actioned · informational',
        note:
            'Used in: Notifications inbox. '
            'Read rows lose the dot and the tint. An answered request shows an '
            '"accepted" chip. Informational types have no buttons.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            notifCard(
              notif(
                NotificationType.contactLinkRequest,
                readAt: now,
                actionedAt: now,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            notifCard(
              notif(
                NotificationType.splitCreated,
                readAt: now,
                actionedAt: now,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            notifCard(
              notif(
                NotificationType.projectAdded,
                payload: const {'project_name': 'Chiang Mai trip'},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            notifCard(
              notif(
                NotificationType.splitReceived,
                readAt: now,
                payload: const {'amount': 450, 'currency': 'THB'},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            notifCard(notif(NotificationType.unknown, readAt: now)),
          ],
        ),
      ),
      HubDemo(
        title: 'ProjectTxIcon',
        note:
            'Used in: Project dashboard tab. '
            'The type bubble of a project board row: expense and income.',
        child: HubRow(
          cells: [
            HubCell(
              caption: 'expense',
              child: ProjectTxIcon(tx: ptx('expense')),
            ),
            HubCell(
              caption: 'income',
              child: ProjectTxIcon(tx: ptx('income')),
            ),
            HubCell(
              caption: 'size 28',
              child: ProjectTxIcon(tx: ptx('expense'), size: 28),
            ),
          ],
        ),
      ),
      const HubDemo(
        title: 'ProjectMemberAvatar',
        note:
            'Used in: Project members page, member pick card, project dashboard. '
            'A member\'s own icon, else a coloured initial (stable colour per '
            'member id).',
        child: HubRow(
          cells: [
            HubCell(
              caption: 'initial',
              child: ProjectMemberAvatar(member: member),
            ),
            HubCell(
              caption: 'icon',
              child: ProjectMemberAvatar(member: memberWithIcon),
            ),
            HubCell(
              caption: 'size 48',
              child: ProjectMemberAvatar(member: member, size: 48),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'Project status chips',
        note:
            'Used in: Projects list, Project detail. '
            'projectStatusTone with AppChip(selected: true, dot: true): '
            'active primary, completed success, cancelled danger, archived '
            'neutral.',
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in ProjectStatus.values)
              AppChip(
                label: s.name,
                dot: true,
                selected: true,
                tone: projectStatusTone(s),
              ),
          ],
        ),
      ),
      const HubDemo(
        title: 'BrandLogo',
        note:
            'Used in: Splash, Update-required page, Auth header. '
            'The app mark clipped to a 24% rounded square. 128 is the splash '
            'size, 88 / 56 the auth header sizes.',
        child: HubRow(
          cells: [
            HubCell(caption: '128 (splash)', child: BrandLogo()),
            HubCell(caption: '88', child: BrandLogo(size: 88)),
            HubCell(caption: '56', child: BrandLogo(size: 56)),
            HubCell(caption: '32', child: BrandLogo(size: 32)),
          ],
        ),
      ),
      HubDemo(
        title: 'AuthBrandHeader',
        note:
            'Used in: Login, Register. '
            'Logo, app name, tagline. Compact: smaller logo, no tagline '
            '(register). Tapping the logo five times opens the hub.',
        child: Column(
          children: const [
            AuthBrandHeader(),
            SizedBox(height: AppSpacing.xl),
            AuthBrandHeader(compact: true),
          ],
        ),
      ),
      HubDemo(
        title: 'AuthOrDivider · GoogleSignInButton',
        note:
            'Used in: Login, Register. '
            'The divider between the form and other sign-in options. The '
            'Google button is dimmed with a "coming soon" chip while it has '
            'no handler; with one it is live; loading adds a spinner.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthOrDivider(),
            const SizedBox(height: AppSpacing.md),
            const GoogleSignInButton(),
            const SizedBox(height: AppSpacing.sm),
            GoogleSignInButton(onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            GoogleSignInButton(onPressed: () {}, loading: true),
          ],
        ),
      ),
      HubDemo(
        title: 'OfflineBanner',
        note:
            'Used in: App shell (every page). '
            'A strip shown while the device has no network, slides away when '
            'it returns. Both states below run on a stand-in connectivity '
            'source, not the real one.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Offline'),
            const SizedBox(height: AppSpacing.xs),
            BlocProvider(
              create: (_) =>
                  ConnectivityCubit(connectivity: _FakeConnectivity(false)),
              child: const OfflineBanner(),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Online (renders nothing)'),
            const SizedBox(height: AppSpacing.xs),
            BlocProvider(
              create: (_) =>
                  ConnectivityCubit(connectivity: _FakeConnectivity(true)),
              child: const OfflineBanner(),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'UpdateBannerStrip',
        note:
            'Used in: App shell (update banner). '
            'The "new version" strip shown while a newer build is out but this '
            'one still works. The wrapper (UpdateBanner) reads the version '
            'cubit; the strip itself is shown here.',
        child: UpdateBannerStrip(onUpdate: () {}, onDismiss: () {}),
      ),
    ],
  );
}

/// A connectivity source with a fixed answer and no change events.
class _FakeConnectivity implements Connectivity {
  _FakeConnectivity(this.online);

  final bool online;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    online ? ConnectivityResult.wifi : ConnectivityResult.none,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}
