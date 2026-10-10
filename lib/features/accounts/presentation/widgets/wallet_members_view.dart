import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import 'wallet_invite_picker.dart';

/// A wallet's members (spec §14 / B4) — the wallet page's สมาชิก tab
/// (`/accounts/:id/members` opens it there):
///
/// - Active members: avatar · name (คุณ) · role pill; a pending invite
///   carries "รอตอบรับ". ⋯ holds what the viewer may do to that member.
/// - "+ เชิญจากผู้ติดต่อ" (owner; no email invite since 2026-10-11): pick
///   one of my contacts linked to an app account ([showWalletInvitePicker]);
///   the FIRST invite on a personal wallet asks first — sharing exposes the
///   wallet's whole history (spec §14/4).
/// - History: members who left (dimmed, joined / left dates) —
///   membership is append-only (spec §14/2.4).
/// - Leave (self), remove / transfer ownership (owner — spec §14/2.5).
/// The invite flow (owner): pick a linked contact ([showWalletInvitePicker],
/// [members] still in the wallet hidden), confirm the FIRST invite on a
/// personal wallet (spec §14/4 — sharing exposes its history), send, then
/// refresh the wallets cache. Returns whether an invite went out. Used by
/// the สมาชิก tab and the wallet page's "invite" row.
Future<bool> inviteWalletMember(
  BuildContext context, {
  required String accountId,
  required List<WalletMember> members,
}) async {
  final l = AppLocalizations.of(context)!;
  // Hidden: everyone in the wallet or already invited.
  final contact = await showWalletInvitePicker(
    context,
    excludeUserIds: {
      for (final m in members)
        if (!m.hasLeft) m.userId,
    },
  );
  if (contact == null || !context.mounted) return false;
  final name = contact.effectiveName;

  // Conversion warning: gate the FIRST invite on a currently-personal
  // wallet. Adding to an already-shared wallet skips the warning.
  if (members.where((m) => m.isActive).length <= 1) {
    final account = context.read<AccountsCubit>().byId(accountId);
    final ok = await showConfirmDialog(
      context,
      title: l.walletConvertWarnTitle(name),
      message: l.walletConvertWarnBody(account?.name ?? '', name),
      confirmLabel: l.walletInviteSend,
    );
    if (!ok || !context.mounted) return false;
  }

  final repo = context.read<AccountsRepository>();
  final accountsCubit = context.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    await repo.inviteMember(accountId: accountId, contactId: contact.id);
    showAppSnackBarOn(messenger, l.walletInviteSent, tone: Tone.success);
    // Membership changed server-side; refresh the accounts cache so
    // is_shared / members[] on the list + detail stay in sync.
    await accountsCubit.load();
    return true;
  } on ApiException catch (e) {
    showAppSnackBarOn(
      messenger,
      e.code == 'VALIDATION_ERROR'
          ? l.walletErrorInviteInvalid
          : walletErrorMessage(l, e),
      tone: Tone.danger,
    );
    return false;
  }
}

class WalletMembersView extends StatefulWidget {
  const WalletMembersView({
    required this.accountId,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String accountId;

  /// Around the list (the tab's insets).
  final EdgeInsetsGeometry padding;

  @override
  State<WalletMembersView> createState() => _WalletMembersViewState();
}

class _WalletMembersViewState extends State<WalletMembersView> {
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final error = _error;
    if (error != null) return ErrorView(error: error, onRetry: _load);
    if (_loading && _members.isEmpty) {
      return ListView(
        padding: widget.padding,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (var i = 0; i < 3; i++) const SkeletonListTile()],
      );
    }
    final uid = _currentUserId;
    final owner = _isOwner;
    final active = _members.where((m) => !m.hasLeft).toList(); // + pending
    final history = _members.where((m) => m.hasLeft).toList();
    return PullToRefresh(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        children: [
          SectionCard(
            first: true,
            children: [
              for (final m in active)
                _MemberRow(
                  member: m,
                  isSelf: m.userId == uid,
                  viewerIsOwner: owner,
                  onLeave: () => _onLeave(l, m),
                  onRemove: () => _onRemove(l, m),
                  onTransferOwnership: () => _onTransferOwnership(l, m),
                ),
            ],
          ),
          // Only the owner invites (the BE checks too).
          if (owner)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: AddTile(
                label: l.walletInviteFromContacts,
                variant: AddTileVariant.row,
                icon: AppIcons.inviteMember,
                onTap: () => _onInvitePressed(l),
              ),
            ),
          if (history.isNotEmpty)
            Opacity(
              opacity: 0.55,
              child: SectionCard(
                title: l.walletMembersHistoryTitle,
                children: [
                  for (final m in history)
                    _MemberRow(
                      member: m,
                      isSelf: m.userId == uid,
                      viewerIsOwner: false,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Invite flow ─────────────────────────────────────────────────────

  Future<void> _onInvitePressed(AppLocalizations l) async {
    final invited = await inviteWalletMember(
      context,
      accountId: widget.accountId,
      members: _members,
    );
    if (invited && mounted) await _load();
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
      // No longer a member — the wallet drops out of my list, and its page
      // with it: straight back to the wallets list, however we got here.
      await accountsCubit.load();
      router.go('/accounts');
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

// ─── Rows & sheets ─────────────────────────────────────────────────────

enum _MemberAction { transferOwnership, remove, leave }

/// `[avatar]  name (คุณ)            [role] ⋯` · joined / left dates.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isSelf,
    required this.viewerIsOwner,
    this.onLeave,
    this.onRemove,
    this.onTransferOwnership,
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
    // v1 rule (API §14): the owner may remove anyone but themselves (they
    // leave via a transfer).
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
    final Widget pill = member.pending
        ? StatusPill(label: l.walletMemberPending, tone: Tone.warning)
        : LabelPill(
            label: member.isOwner
                ? l.walletMemberRoleOwner
                : l.walletMemberRoleMember,
            tone: member.isOwner ? Tone.primary : Tone.neutral,
          );
    final destructive = TextStyle(color: scheme.error);
    return DetailRow(
      leading: UserAvatar(
        displayName: member.displayName,
        iconCode: member.iconCode,
        size: 40,
      ),
      label: isSelf
          ? '${member.displayName} (${l.walletMemberYou})'
          : member.displayName,
      helper: dates.isEmpty ? null : dates.join(' · '),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill,
          if (canLeave || canRemove || canTransfer)
            OptionMenuAnchor<_MemberAction>(
              onSelected: (a) => switch (a) {
                _MemberAction.leave => onLeave?.call(),
                _MemberAction.remove => onRemove?.call(),
                _MemberAction.transferOwnership => onTransferOwnership?.call(),
              },
              options: [
                if (canTransfer)
                  SheetOption(
                    value: _MemberAction.transferOwnership,
                    label: l.walletTransferOwnershipAction,
                  ),
                if (canRemove)
                  SheetOption(
                    value: _MemberAction.remove,
                    label: l.walletRemoveMemberAction,
                    labelStyle: destructive,
                  ),
                if (canLeave)
                  SheetOption(
                    value: _MemberAction.leave,
                    label: l.walletLeave,
                    labelStyle: destructive,
                  ),
              ],
              builder: (context, toggle) => IconButton(
                tooltip: l.commonMore,
                icon: const Icon(AppIcons.more),
                onPressed: toggle,
              ),
            ),
        ],
      ),
    );
  }

  static String _dateOnly(String iso) {
    final t = iso.indexOf('T');
    return t > 0 ? iso.substring(0, t) : iso;
  }
}
