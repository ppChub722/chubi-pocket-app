import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/top_bar_crumbs.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/accounts_repository.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../wallet_errors.dart';

/// `/accounts/:id/members` — the wallet members screen (spec §14 / B4).
///
/// - Active members with role chip; pending invites carry a "รอตอบรับ"
///   chip (notification-pattern invite, not yet accepted).
/// - History section for members who left (dimmed, joined/left dates) —
///   membership is append-only (spec §14/2.4).
/// - Invite by email (dashed "+ เชิญทางอีเมล" row under the active members). The
///   FIRST invite on a currently-personal wallet is gated by the
///   conversion warning (spec §14/4) — sharing exposes the wallet's
///   entire history to the new member.
/// - Leave (self), remove member / transfer ownership (owner only —
///   spec §14/2.5 reuses the project transfer-ownership pattern).
class WalletMembersPage extends StatefulWidget {
  const WalletMembersPage({required this.accountId, super.key});
  final String accountId;

  @override
  State<WalletMembersPage> createState() => _WalletMembersPageState();
}

class _WalletMembersPageState extends State<WalletMembersPage> {
  List<WalletMember> _members = const [];
  bool _loading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ms = await context.read<AccountsRepository>().listMembers(
        widget.accountId,
      );
      if (!mounted) return;
      setState(() {
        _members = ms;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String? get _currentUserId {
    final s = context.read<AuthCubit>().state;
    if (s is AuthAuthenticated) return s.user.id;
    return null;
  }

  bool get _isOwner {
    final uid = _currentUserId;
    for (final m in _members) {
      if (m.userId == uid && m.isActive) return m.isOwner;
    }
    return false;
  }

  /// Active (non-pending, non-left) member count — drives the
  /// "first invite converts this wallet" warning gate.
  int get _activeCount => _members.where((m) => m.isActive).length;

  TopBarCrumb? _walletCrumb(BuildContext context) {
    final a = context.read<AccountsCubit>().byId(widget.accountId);
    return a == null
        ? null
        : TopBarCrumb(
            label: a.name,
            path: '/accounts/${a.id}',
            routeName: 'account-detail',
          );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final active = _members
        .where((m) => !m.hasLeft)
        .toList(); // includes pending
    final history = _members.where((m) => m.hasLeft).toList();
    return Scaffold(
      // Breadcrumb parent = this wallet. Invite lives in the body (a dashed
      // row under the active members) — the top bar carries no page actions.
      appBar: AppTopBar(
        title: l.walletMembersTitle,
        showBack: true,
        parent: _walletCrumb(context),
      ),
      extendBodyBehindAppBar: true,
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : _loading && _members.isEmpty
          // Padding-less ListView: clears the floating bar by itself.
          ? ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [for (var i = 0; i < 3; i++) const SkeletonListTile()],
            )
          : PullToRefresh(
              onRefresh: _load,
              // Builder: the body's context sees the floating bar's
              // height.
              child: Builder(
                builder: (context) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                    bottom: AppSpacing.huge,
                  ),
                  children: [
                    for (final m in active)
                      _MemberTile(
                        member: m,
                        isSelf: m.userId == _currentUserId,
                        viewerIsOwner: _isOwner,
                        onLeave: () => _onLeave(l, m),
                        onRemove: () => _onRemove(l, m),
                        onTransferOwnership: () => _onTransferOwnership(l, m),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: AddTile(
                        label: l.walletMembersInvite,
                        variant: AddTileVariant.row,
                        icon: AppIcons.inviteMember,
                        onTap: () => _onInvitePressed(l),
                      ),
                    ),
                    if (history.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          l.walletMembersHistoryTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      for (final m in history)
                        Opacity(
                          opacity: 0.55,
                          child: _MemberTile(
                            member: m,
                            isSelf: m.userId == _currentUserId,
                            viewerIsOwner: false,
                            onLeave: null,
                            onRemove: null,
                            onTransferOwnership: null,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Invite flow ─────────────────────────────────────────────────────

  Future<void> _onInvitePressed(AppLocalizations l) async {
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (_) => const _InviteEmailSheet(),
    );
    if (email == null || !mounted) return;

    // Conversion warning (spec §14/4): gate the FIRST invite on a
    // currently-personal wallet. Adding to an already-shared wallet
    // skips the warning.
    if (_activeCount <= 1) {
      final account = context.read<AccountsCubit>().byId(widget.accountId);
      final ok = await showConfirmDialog(
        context,
        title: l.walletConvertWarnTitle(email),
        message: l.walletConvertWarnBody(account?.name ?? '', email),
        confirmLabel: l.walletInviteSend,
      );
      if (!ok || !mounted) return;
    }

    final repo = context.read<AccountsRepository>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.inviteMember(accountId: widget.accountId, email: email);
      showAppSnackBarOn(messenger, l.walletInviteSent, tone: Tone.success);
      await _load();
      // Membership changed server-side; refresh the accounts cache so
      // is_shared / members[] on the list + detail stay in sync.
      await accountsCubit.load();
    } on ApiException catch (e) {
      showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  // ─── Member actions ──────────────────────────────────────────────────

  Future<void> _onLeave(AppLocalizations l, WalletMember me) async {
    final ok = await showConfirmDialog(
      context,
      title: l.walletLeaveConfirmTitle,
      message: l.walletLeaveConfirmBody,
      confirmLabel: l.walletLeaveAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = context.read<AccountsRepository>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await repo.removeMember(accountId: widget.accountId, memberId: me.id);
      // No longer a member — the wallet drops out of our list. Pop all
      // the way back to the wallets list.
      await accountsCubit.load();
      if (router.canPop()) router.pop();
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      // OWNER_MUST_TRANSFER lands here when the owner tries to leave a
      // still-shared wallet (spec §14/2.5).
      showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  Future<void> _onRemove(AppLocalizations l, WalletMember m) async {
    final ok = await showConfirmDialog(
      context,
      title: l.walletRemoveMemberConfirmTitle(m.displayName),
      message: l.walletRemoveMemberConfirmBody,
      confirmLabel: l.commonRemove,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = context.read<AccountsRepository>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.removeMember(accountId: widget.accountId, memberId: m.id);
      await _load();
      await accountsCubit.load();
    } on ApiException catch (e) {
      showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  Future<void> _onTransferOwnership(AppLocalizations l, WalletMember m) async {
    final ok = await showConfirmDialog(
      context,
      title: l.walletTransferOwnershipConfirmTitle(m.displayName),
      message: l.walletTransferOwnershipConfirmBody,
      confirmLabel: l.walletTransferOwnershipConfirm,
    );
    if (!ok || !mounted) return;
    final repo = context.read<AccountsRepository>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.transferOwnership(
        accountId: widget.accountId,
        newOwnerUserId: m.userId,
      );
      showAppSnackBarOn(
        messenger,
        l.walletTransferOwnershipSuccess,
        tone: Tone.success,
      );
      await _load();
      await accountsCubit.load();
    } on ApiException catch (e) {
      showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }
}

// ─── Tiles & dialogs ─────────────────────────────────────────────────────

enum _MemberAction { remove, transferOwnership, leave }

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isSelf,
    required this.viewerIsOwner,
    required this.onLeave,
    required this.onRemove,
    required this.onTransferOwnership,
  });

  final WalletMember member;
  final bool isSelf;
  final bool viewerIsOwner;
  final VoidCallback? onLeave;
  final VoidCallback? onRemove;
  final VoidCallback? onTransferOwnership;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final canLeave = isSelf && !member.hasLeft && onLeave != null;
    // v1 rule (API §14): a member may remove themselves; the owner may
    // remove anyone (but not themselves — they leave via transfer).
    final canRemove =
        viewerIsOwner && !isSelf && !member.hasLeft && onRemove != null;
    final canTransfer =
        viewerIsOwner &&
        !isSelf &&
        member.isActive &&
        onTransferOwnership != null;

    final dates = <String>[
      if (member.joinedAt != null)
        l.walletMemberJoined(_dateOnly(member.joinedAt!)),
      if (member.leftAt != null) l.walletMemberLeft(_dateOnly(member.leftAt!)),
    ];

    return ListTile(
      leading: UserAvatar(
        displayName: member.displayName,
        iconCode: member.iconCode,
        size: 40,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '(${l.walletMemberYou})',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          if (member.pending)
            _Chip(
              label: l.walletMemberPending,
              background: scheme.tertiaryContainer,
              foreground: scheme.onTertiaryContainer,
            )
          else
            _Chip(
              label: member.isOwner
                  ? l.walletMemberRoleOwner
                  : l.walletMemberRoleMember,
              background: member.isOwner
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              foreground: member.isOwner
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
        ],
      ),
      subtitle: dates.isEmpty ? null : Text(dates.join(' · ')),
      trailing: (canLeave || canRemove || canTransfer)
          ? PopupMenuButton<_MemberAction>(
              onSelected: (a) {
                switch (a) {
                  case _MemberAction.leave:
                    onLeave?.call();
                  case _MemberAction.remove:
                    onRemove?.call();
                  case _MemberAction.transferOwnership:
                    onTransferOwnership?.call();
                }
              },
              itemBuilder: (_) => [
                if (canTransfer)
                  PopupMenuItem(
                    value: _MemberAction.transferOwnership,
                    child: Text(l.walletTransferOwnershipAction),
                  ),
                if (canRemove)
                  PopupMenuItem(
                    value: _MemberAction.remove,
                    child: Text(
                      l.walletRemoveMemberAction,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                if (canLeave)
                  PopupMenuItem(
                    value: _MemberAction.leave,
                    child: Text(
                      l.walletLeave,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  static String _dateOnly(String iso) {
    final t = iso.indexOf('T');
    return t > 0 ? iso.substring(0, t) : iso;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "เชิญสมาชิก" sheet — one email field; resolves the trimmed email, or
/// null on cancel.
class _InviteEmailSheet extends StatefulWidget {
  const _InviteEmailSheet();

  @override
  State<_InviteEmailSheet> createState() => _InviteEmailSheetState();
}

class _InviteEmailSheetState extends State<_InviteEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppSheetScaffold(
      title: l.walletInviteTitle,
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l.commonCancel,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: l.walletInviteSend,
              icon: AppIcons.send,
              size: AppButtonSize.large,
              expand: true,
              onPressed: _submit,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: AppTextField(
            controller: _email,
            autofocus: true,
            label: l.walletInviteEmailLabel,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty || !t.contains('@') || t.length > 254) {
                return l.walletInviteEmailInvalid;
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
