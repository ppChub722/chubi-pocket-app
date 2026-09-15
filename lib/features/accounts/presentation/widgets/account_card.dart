import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import 'member_avatar_stack.dart';

/// Renders one wallet (account) in the grid.
///
/// The account's [iconCode] drives the icon background, card border, and
/// balance text. Card surface stays neutral (`surfaceContainer`).
///
/// Shared wallets (spec §14, [Account.isShared]) additionally show a
/// small chain-link badge overlaid on the icon's corner (the user's own
/// icon/logo stays) and an avatar stack of the OTHER active members
/// (self excluded, max 3 then "+N").
class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    required this.horizontal,
    this.onTap,
    this.onIconTap,
    super.key,
  });

  final Account account;
  final bool horizontal;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        account.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: horizontal
              ? _HorizontalLayout(account: account, onIconTap: onIconTap)
              : _VerticalLayout(account: account, onIconTap: onIconTap),
        ),
      ),
    );
  }
}

class _HorizontalLayout extends StatelessWidget {
  const _HorizontalLayout({required this.account, this.onIconTap});
  final Account account;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        account.iconCode?.accentColorFor(palette) ?? palette.primary;
    final desc = account.description?.trim();
    final note = account.note?.trim();
    final hasDesc = desc != null && desc.isNotEmpty;
    final hasNote = note != null && note.isNotEmpty;
    return Row(
      children: [
        _IconCircle(account: account, size: 44, onTap: onIconTap),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                hasDesc ? desc : _typeLabel(context, account.type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              if (hasNote) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              if (account.isShared) ...[
                const SizedBox(height: 4),
                _OtherMembersRow(account: account),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(account.balance),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (account.creditUtilization != null) ...[
              const SizedBox(height: 4),
              _UtilizationBar(
                fraction: account.creditUtilization!,
                color: accent,
                width: 100,
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.accountCreditUsedPercent(
                  (account.creditUtilization! * 100).round(),
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _VerticalLayout extends StatelessWidget {
  const _VerticalLayout({required this.account, this.onIconTap});
  final Account account;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        account.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _IconCircle(account: account, size: 36, onTap: onIconTap),
        const SizedBox(height: AppSpacing.sm),
        Text(
          account.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          _typeLabel(context, account.type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        Text(
          CurrencyFormatter.format(account.balance),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (account.creditUtilization != null) ...[
          const SizedBox(height: 4),
          _UtilizationBar(
            fraction: account.creditUtilization!,
            color: accent,
            width: double.infinity,
          ),
        ],
      ],
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.account, required this.size, this.onTap});
  final Account account;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = EditableCircle(
      size: size,
      onTap: onTap,
      child: IconDisplay(
        type: IconType.account,
        size: size,
        iconCode: account.iconCode,
      ),
    );
    if (!account.isShared) return icon;
    return SharedWalletIconBadge(size: size, child: icon);
  }
}

/// Overlays a small chain-link badge on the bottom-right corner of a
/// wallet icon — marks a shared wallet without replacing the user's
/// own icon_code / logo (spec B2).
class SharedWalletIconBadge extends StatelessWidget {
  const SharedWalletIconBadge({
    required this.size,
    required this.child,
    super.key,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final badgeSize = (size * 0.42).clamp(14.0, 22.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -2,
            bottom: -2,
            child: Tooltip(
              message: l.walletSharedLabel,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1),
                ),
                child: Icon(
                  Icons.link,
                  size: badgeSize * 0.68,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar stack of the wallet's OTHER active members — the viewer is
/// excluded so the stack answers "who am I sharing this with".
class _OtherMembersRow extends StatelessWidget {
  const _OtherMembersRow({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final selfId = auth is AuthAuthenticated ? auth.user.id : null;
    final others = account.otherMembers(selfId);
    if (others.isEmpty) return const SizedBox.shrink();
    return MemberAvatarStack(members: others, size: 18);
  }
}

class _UtilizationBar extends StatelessWidget {
  const _UtilizationBar({
    required this.fraction,
    required this.color,
    required this.width,
  });

  final double fraction;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: width,
        height: 4,
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 4,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

String _typeLabel(BuildContext context, AccountType type) {
  final l = AppLocalizations.of(context)!;
  switch (type) {
    case AccountType.cash:
      return l.accountTypeCash;
    case AccountType.bank:
      return l.accountTypeBank;
    case AccountType.eWallet:
      return l.accountTypeEWallet;
    case AccountType.creditCard:
      return l.accountTypeCreditCard;
    case AccountType.payLater:
      return l.accountTypePayLater;
  }
}
