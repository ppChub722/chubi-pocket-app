import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../features/accounts/domain/account.dart';
import '../../../features/accounts/domain/account_type.dart';
import '../../ui.dart';

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
            if (account.showsBalance)
              MoneyText(
                accountDisplayBalance(account),
                style: AppTypography.of(
                  context,
                  AppTextRole.money,
                )?.copyWith(color: accountBalanceColor(context, account)),
              ),
            if (account.creditUsedPct != null) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 100,
                child: ProgressRow(
                  value: (account.creditUsedPct! / 100).clamp(0.0, 1.0),
                  color: accent,
                  height: 4,
                  label: AppLocalizations.of(
                    context,
                  )!.accountCreditUsedPercent(account.creditUsedPct!),
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
    final utilization = account.creditUsedPct == null
        ? null
        : (account.creditUsedPct! / 100).clamp(0.0, 1.0);
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
        if (account.showsBalance) ...[
          const SizedBox(height: AppSpacing.xs),
          MoneyText(
            accountDisplayBalance(account),
            style: AppTypography.of(
              context,
              AppTextRole.money,
            )?.copyWith(color: accountBalanceColor(context, account)),
          ),
        ],
        if (utilization != null) ...[
          const SizedBox(height: AppSpacing.xs),
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
              AppText('${account.creditUsedPct}%', role: AppTextRole.caption),
            ],
          ),
        ],
      ],
    );
  }
}

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
      essential: true,
      child: child,
    );
  }
}

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

Color accountBalanceColor(BuildContext context, Account account) {
  if (account.isLiability) return account.colorOf(context);
  final palette = Theme.of(context).extension<AppColors>()!;
  return account.iconCode.tintFor(palette);
}

/// The balance to show: a zero is a plain 0 — `-0.0` (a new card) would read
/// "-฿0.00".
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
