import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/data/money_text.dart';
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
/// The account's [iconCode] accent drives the card wash, border and
/// balance text — styled like the เพิ่มเติม hub cards. [horizontal] is the
/// list-row form (reorder mode); the grid uses the vertical card.
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
    return AccountCardSurface(
      account: account,
      onTap: onTap,
      // Grid card only — on the row form it would sit under the balance.
      showGlyph: !horizontal,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: horizontal
            ? _HorizontalLayout(account: account, onIconTap: onIconTap)
            : _VerticalLayout(account: account, onIconTap: onIconTap),
      ),
    );
  }
}

/// The wallet-card look on its own: soft accent wash from the top-left,
/// hairline accent border, big faded type glyph in the bottom-right corner
/// (same language as the เพิ่มเติม hub cards). Shared by the grid
/// [AccountCard] and the wallet detail page's hero header, so both read as
/// the same object.
class AccountCardSurface extends StatelessWidget {
  const AccountCardSurface({
    required this.account,
    required this.child,
    this.onTap,
    this.showGlyph = true,
    this.glyphSize = 88,
    this.margin,
    super.key,
  });

  final Account account;
  final Widget child;
  final VoidCallback? onTap;
  final bool showGlyph;
  final double glyphSize;

  /// Card margin; null = the theme default (grid spacing).
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = account.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: accent.withValues(alpha: 0.25)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.16),
              accent.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (showGlyph)
                Positioned(
                  right: -glyphSize * 0.16,
                  bottom: -glyphSize * 0.2,
                  child: Icon(
                    account.type.icon,
                    size: glyphSize,
                    color: accent.withValues(alpha: 0.10),
                  ),
                ),
              child,
            ],
          ),
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
    final accent = account.iconCode?.accentColorFor(palette) ?? palette.primary;
    final desc = account.description?.trim();
    final note = account.note?.trim();
    final hasDesc = desc != null && desc.isNotEmpty;
    final hasNote = note != null && note.isNotEmpty;
    return Row(
      children: [
        AccountIconCircle(account: account, size: 44, onTap: onIconTap),
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
                hasDesc ? desc : accountTypeLabel(context, account.type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                OtherMembersStack(account: account),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              account.balance,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = account.iconCode?.accentColorFor(palette) ?? palette.primary;
    final desc = account.description?.trim();
    final utilization = account.creditUtilization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountIconCircle(account: account, size: 40, onTap: onIconTap),
            const Spacer(),
            if (account.isShared) OtherMembersStack(account: account),
          ],
        ),
        const Spacer(),
        Text(
          account.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          desc != null && desc.isNotEmpty
              ? desc
              : accountTypeLabel(context, account.type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        MoneyText(
          account.balance,
          style: textTheme.titleMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (utilization != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _UtilizationBar(
                  fraction: utilization,
                  color: accent,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${(utilization * 100).round()}%',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The wallet's icon in an [EditableCircle] (pencil badge while [onTap] is
/// set), with the shared-wallet badge when [Account.isShared]. Constant
/// footprint either way, so toggling [onTap] never reflows.
class AccountIconCircle extends StatelessWidget {
  const AccountIconCircle({
    required this.account,
    required this.size,
    this.onTap,
    super.key,
  });

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
                  AppIcons.link,
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
class OtherMembersStack extends StatelessWidget {
  const OtherMembersStack({required this.account, this.size = 18, super.key});

  final Account account;
  final double size;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final selfId = auth is AuthAuthenticated ? auth.user.id : null;
    final others = account.otherMembers(selfId);
    if (others.isEmpty) return const SizedBox.shrink();
    return MemberAvatarStack(members: others, size: size);
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
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

String accountTypeLabel(BuildContext context, AccountType type) {
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
