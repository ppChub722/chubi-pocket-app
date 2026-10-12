import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import 'member_avatar_stack.dart';
import '../../../../ui/ui.dart';

/// Renders one wallet (account) in the grid.
///
/// The account's [iconCode] accent drives the card wash, border and
/// balance text — styled like the เพิ่มเติม hub cards. [horizontal] is the
/// list-row form (the reorder list, the icon maker's preview); the grid
/// uses the vertical card. A card's credit bar is its used credit — an
/// overpaid card shows none ([Account.creditUtilization]).
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
/// The wallet's hero look as one [HeroStyle]: the wallet colour as a wash, a soft
/// border and the account type's glyph. The wallet hero AND its compact bar
/// are built from it, so the bar mirrors the card.
HeroStyle accountHeroStyle(
  BuildContext context,
  Account account, {
  bool showGlyph = true,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return HeroStyle.tinted(
    color: account.iconCode.tintFor(
      palette,
      fallback: account.colorOf(context),
    ),
    glyph: showGlyph ? account.type.icon : null,
    strongBorder: false,
  );
}

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
    return HeroSurface(
      style: accountHeroStyle(context, account, showGlyph: showGlyph),
      glyphSize: glyphSize,
      onTap: onTap,
      margin: margin ?? EdgeInsets.zero,
      child: child,
    );
  }
}

class _HorizontalLayout extends StatelessWidget {
  const _HorizontalLayout({required this.account, this.onIconTap});
  final Account account;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = account.iconCode.tintFor(palette);
    final desc = account.description?.trim();
    final note = account.note?.trim();
    final hasDesc = desc != null && desc.isNotEmpty;
    final hasNote = note != null && note.isNotEmpty;
    return Row(
      children: [
        AccountIconCircle(
          account: account,
          size: AvatarMetrics.sizeLarge,
          onTap: onIconTap,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(account.name, role: AppTextRole.title, maxLines: 1),
              const SizedBox(height: AppSpacing.xxs),
              AppText(
                hasDesc ? desc : accountTypeLabel(context, account.type),
                role: AppTextRole.caption,
                maxLines: 1,
              ),
              if (hasNote) ...[
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  note,
                  role: AppTextRole.caption,
                  italic: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (account.isShared) ...[
                const SizedBox(height: AppSpacing.xs),
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
              accountDisplayBalance(account),
              style: AppTypography.of(
                context,
                AppTextRole.money,
              )?.copyWith(color: accountBalanceColor(context, account)),
            ),
            if (account.creditUtilization != null) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 100,
                child: ProgressRow(
                  value: account.creditUtilization!,
                  color: accent,
                  height: 4,
                  label: AppLocalizations.of(context)!.accountCreditUsedPercent(
                    (account.creditUtilization! * 100).round(),
                  ),
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
    final accent = account.iconCode.tintFor(palette);
    final desc = account.description?.trim();
    final utilization = account.creditUtilization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountIconCircle(
              account: account,
              size: AvatarMetrics.sizeMedium,
              onTap: onIconTap,
            ),
            const Spacer(),
            if (account.isShared) OtherMembersStack(account: account),
          ],
        ),
        const Spacer(),
        AppText(
          account.name,
          role: AppTextRole.title,
          weight: FontWeight.w700,
          maxLines: 1,
        ),
        AppText(
          desc != null && desc.isNotEmpty
              ? desc
              : accountTypeLabel(context, account.type),
          role: AppTextRole.caption,
          maxLines: 1,
        ),
        const SizedBox(height: AppSpacing.xs),
        MoneyText(
          accountDisplayBalance(account),
          style: AppTypography.of(
            context,
            AppTextRole.money,
          )?.copyWith(color: accountBalanceColor(context, account)),
        ),
        if (utilization != null) ...[
          const SizedBox(height: AppSpacing.xs),
          // Bar beside its percent (one line, keeps the card's height).
          Row(
            children: [
              Expanded(
                child: ProgressRow(
                  value: utilization,
                  color: accent,
                  height: 4,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppText(
                '${(utilization * 100).round()}%',
                role: AppTextRole.caption,
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
    this.onLongPress,
    super.key,
  });

  final Account account;
  final double size;
  final VoidCallback? onTap;

  /// View mode: enter edit (long-press); works without [onTap], no pencil.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final display = IconDisplay(
      type: IconType.account,
      size: size,
      iconCode: account.iconCode,
    );
    // Only an EDITABLE icon is an EditableCircle (never below 40, with the
    // pencil); a plain one — the compact bar's 28 — is just the icon.
    final icon = onTap == null && onLongPress == null
        ? SizedBox(width: size, height: size, child: display)
        : EditableCircle(
            size: size,
            onTap: onTap,
            onLongPress: onLongPress,
            child: display,
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
    return CornerBadge(
      size: size,
      icon: AppIcons.link,
      color: scheme.primaryContainer,
      iconColor: scheme.onPrimaryContainer,
      tooltip: l.walletSharedLabel,
      // Shared is state, not decoration: kept on small icons too.
      essential: true,
      child: child,
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
    final others = account.otherMembers;
    if (others.isEmpty) return const SizedBox.shrink();
    return MemberAvatarStack(members: others, size: size);
  }
}

/// A wallet's balance text colour (owner 2026-10-11): what you owe — a
/// credit-type wallet — in the liability token; otherwise the wallet's own
/// icon colour (the card wash keeps that colour either way).
Color accountBalanceColor(BuildContext context, Account account) {
  if (account.isLiability) return account.colorOf(context);
  final palette = Theme.of(context).extension<AppColors>()!;
  return account.iconCode.tintFor(palette);
}

/// The balance to show: a zero is a plain 0 — `-0.0` (a new card) would
/// read "-฿0.00".
double accountDisplayBalance(Account account) =>
    account.balance == 0 ? 0 : account.balance;

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
