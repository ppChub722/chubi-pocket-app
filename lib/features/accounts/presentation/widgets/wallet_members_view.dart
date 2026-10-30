import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../wallet_errors.dart';

Future<bool> inviteWalletMember(
  BuildContext context, {
  required Account account,
  required List<WalletMember> members,
  required void Function(MembersResult) onResult,
}) async {
  final l = AppLocalizations.of(context)!;
  final contact = await ContactPicker.walletInvite(
    context,
    excludeUserIds: {
      for (final m in members)
        if (!m.hasLeft) m.userId,
    },
  );
  if (contact == null || !context.mounted) return false;
  final name = contact.name;

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

  final List<WalletMember> members;

  final void Function(MembersResult) onResult;
  final Future<void> Function() onRefresh;

  final EdgeInsetsGeometry padding;

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
      final r = await cubit.removeMember(
        accountId: account.id,
        memberId: me.id,
      );
      onResult(r);
      router.go('/accounts');
    } on ApiException catch (e) {
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

enum _MemberAction { transferOwnership, remove, leave }

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
    final locale = Localizations.localeOf(context).toLanguageTag();

    final canLeave = isSelf && !member.hasLeft && onLeave != null;
    final canRemove =
        viewerIsOwner && !isSelf && !member.hasLeft && onRemove != null;
    final canTransfer =
        viewerIsOwner &&
        !isSelf &&
        member.isActive &&
        onTransferOwnership != null;

    final dates = <String>[
      if (member.joinedAt != null)
        l.walletMemberJoined(_dateOnly(member.joinedAt!, locale)),
      if (member.leftAt != null)
        l.walletMemberLeft(_dateOnly(member.leftAt!, locale)),
    ];
    final role = member.pending
        ? ListRowChip(l.walletMemberPending, tone: Tone.warning, selected: true)
        : ListRowChip(
            member.isOwner ? l.walletMemberRoleOwner : l.walletMemberRoleMember,
            tone: member.isOwner ? Tone.primary : Tone.neutral,
            selected: true,
          );
    return AppListRow(
      leading: Avatar(member.avatar, size: 40),
      title: isSelf ? '${member.name} (${l.walletMemberYou})' : member.name,
      status: role,
      line2: dates.isEmpty ? null : ListRowLine(parts: dates),
      actions: [
        if (canLeave || canRemove || canTransfer)
          ListRowAction.menu<_MemberAction>(
            tooltip: l.commonMore,
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
                  submits: true,
                ),
              if (canRemove)
                SheetOption(
                  value: _MemberAction.remove,
                  label: l.walletRemoveMemberAction,
                  destructive: true,
                  submits: true,
                ),
              if (canLeave)
                SheetOption(
                  value: _MemberAction.leave,
                  label: l.walletLeave,
                  destructive: true,
                  submits: true,
                ),
            ],
          ),
      ],
    );
  }

  static String _dateOnly(String iso, String locale) {
    final t = iso.indexOf('T');
    final day = t > 0 ? iso.substring(0, t) : iso;
    final d = DateFormatter.parseDay(day);
    return d == null ? day : DateFormatter.medium(d, locale: locale);
  }
}
