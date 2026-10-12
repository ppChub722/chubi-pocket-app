import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';
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
///
/// The members list comes from the wallet page's single detail call
/// (`members_history`); each action's response ([MembersResult]) goes back
/// to the page through `onResult` — nothing is refetched.

/// The invite flow (owner): pick a linked contact ([showWalletInvitePicker],
/// [members] still in the wallet hidden), confirm the FIRST invite on a
/// personal wallet (spec §14/4 — sharing exposes its history), send. The
/// response ([MembersResult]) is handed to [onResult]. Returns whether an
/// invite went out. Used by the สมาชิก tab and the wallet page's "invite" row.
Future<bool> inviteWalletMember(
  BuildContext context, {
  required Account account,
  required List<WalletMember> members,
  required void Function(MembersResult) onResult,
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
  final name = contact.name;

  // Conversion warning: gate the FIRST invite on a currently-personal
  // wallet. Adding to an already-shared wallet skips the warning.
  if (!account.isShared) {
    final ok = await showConfirmDialog(
      context,
      title: l.walletConvertWarnTitle(name),
      message: l.walletConvertWarnBody(account.name, name),
      confirmLabel: l.walletInviteSend,
    );
    if (!ok || !context.mounted) return false;
  }

  final cubit = context.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await cubit.inviteMember(
      accountId: account.id,
      contactId: contact.id,
    );
    onResult(result);
    showAppSnackBarOn(messenger, l.walletInviteSent, tone: Tone.success);
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

class WalletMembersView extends StatelessWidget {
  const WalletMembersView({
    required this.account,
    required this.members,
    required this.onResult,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Account account;

  /// The whole membership (`members_history`): active, pending, left.
  final List<WalletMember> members;

  /// A members action's response — the page patches itself from it.
  final void Function(MembersResult) onResult;
  final Future<void> Function() onRefresh;

  /// Around the list (the tab's insets).
  final EdgeInsetsGeometry padding;

  /// Only the owner invites / removes / transfers (the BE checks too).
  bool get _isOwner => account.canEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final owner = _isOwner;
    final active = members.where((m) => !m.hasLeft).toList(); // + pending
    final history = members.where((m) => m.hasLeft).toList();
    return PullToRefresh(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          SectionCard(
            first: true,
            children: [
              for (final m in active)
                _MemberRow(
                  member: m,
                  isSelf: m.isMe,
                  viewerIsOwner: owner,
                  onLeave: () => _onLeave(context, l, m),
                  onRemove: () => _onRemove(context, l, m),
                  onTransferOwnership: () =>
                      _onTransferOwnership(context, l, m),
                ),
            ],
          ),
          if (owner)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: AddTile(
                label: l.walletInviteFromContacts,
                variant: AddTileVariant.row,
                icon: AppIcons.inviteMember,
                onTap: () => inviteWalletMember(
                  context,
                  account: account,
                  members: members,
                  onResult: onResult,
                ),
              ),
            ),
          if (history.isNotEmpty)
            Opacity(
              opacity: 0.55,
              child: SectionCard(
                title: l.walletMembersHistoryTitle,
                description: l.walletMembersHistoryDescription,
                children: [
                  for (final m in history)
                    _MemberRow(member: m, isSelf: m.isMe, viewerIsOwner: false),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Member actions ──────────────────────────────────────────────────

  Future<void> _onLeave(
    BuildContext context,
    AppLocalizations l,
    WalletMember me,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: l.walletLeaveConfirmTitle,
      message: l.walletLeaveConfirmBody,
      confirmLabel: l.walletLeaveAction,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      // Leaving returns {account: null}: the cubit drops the wallet from the
      // list, and its page with it — straight back to the wallets list.
      final r = await cubit.removeMember(
        accountId: account.id,
        memberId: me.id,
      );
      onResult(r);
      router.go('/accounts');
    } on ApiException catch (e) {
      // OWNER_MUST_TRANSFER lands here when the owner tries to leave a
      // still-shared wallet (spec §14/2.5).
      showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  Future<void> _onRemove(
    BuildContext context,
    AppLocalizations l,
    WalletMember m,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: l.walletRemoveMemberConfirmTitle(m.name),
      message: l.walletRemoveMemberConfirmBody,
      confirmLabel: l.commonRemove,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      onResult(await cubit.removeMember(accountId: account.id, memberId: m.id));
    } on ApiException catch (e) {
      showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  Future<void> _onTransferOwnership(
    BuildContext context,
    AppLocalizations l,
    WalletMember m,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: l.walletTransferOwnershipConfirmTitle(m.name),
      message: l.walletTransferOwnershipConfirmBody,
      confirmLabel: l.walletTransferOwnershipConfirm,
    );
    if (!ok || !context.mounted) return;
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await cubit.transferOwnership(
        accountId: account.id,
        newOwnerUserId: m.userId,
      );
      onResult(r);
      showAppSnackBarOn(
        messenger,
        l.walletTransferOwnershipSuccess,
        tone: Tone.success,
      );
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
        ? AppChip(
            label: l.walletMemberPending,
            tone: AppChipTone.warning,
            selected: true,
            size: ChipSize.chip,
          )
        : AppChip(
            label: member.isOwner
                ? l.walletMemberRoleOwner
                : l.walletMemberRoleMember,
            tone: member.isOwner ? AppChipTone.primary : AppChipTone.neutral,
            selected: true,
            size: ChipSize.chip,
          );
    final destructive = TextStyle(color: scheme.error);
    return DetailRow(
      leading: UserAvatar(
        displayName: member.name,
        iconCode: member.iconCode,
        size: 40,
      ),
      label: isSelf ? '${member.name} (${l.walletMemberYou})' : member.name,
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
              builder: (context, toggle) =>
                  AppIconButton.more(tooltip: l.commonMore, onPressed: toggle),
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
