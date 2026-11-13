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
        padding: const EdgeInsets.all(PpForgeSpacing.md),
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
  return HeroStyle.tinted(
    color: account.colorOf(context),
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
    final accent = account.colorOf(context);
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
        const SizedBox(width: PpForgeSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PpForgeText(account.name, role: PpForgeTextRole.title, maxLines: 1),
              const SizedBox(height: PpForgeSpacing.xxs),
              PpForgeText(
                hasDesc ? desc : accountTypeLabel(context, account.type),
                role: PpForgeTextRole.caption,
                maxLines: 1,
              ),
              if (hasNote) ...[
                const SizedBox(height: PpForgeSpacing.xxs),
                PpForgeText(
                  note,
                  role: PpForgeTextRole.caption,
                  italic: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (account.isShared) ...[
                const SizedBox(height: PpForgeSpacing.xs),
                OtherMembersStack(account: account),
              ],
            ],
          ),
        ),
        const SizedBox(width: PpForgeSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (account.showsBalance)
              MoneyText(
                accountDisplayBalance(account),
                style: PpForgeTypography.of(
                  context,
                  PpForgeTextRole.money,
                )?.copyWith(color: accountBalanceColor(context, account)),
              ),
            if (account.creditUsedPct != null) ...[
              const SizedBox(height: PpForgeSpacing.xs),
              SizedBox(
                width: 100,
                child: ProgressRow(
                  value: (account.creditUsedPct! / 100).clamp(0.0, 1.0),
                  color: accent,
                  height: 4,
                  fillLabel: '${account.creditUsedPct}%',
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
    final accent = account.colorOf(context);
    final desc = account.description?.trim();
    final utilization = account.creditUsedPct == null
        ? null
        : (account.creditUsedPct! / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AccountIconCircle(
              account: account,
              size: AvatarMetrics.sizeMedium,
              onTap: onIconTap,
            ),
            const SizedBox(width: PpForgeSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PpForgeText(
                    account.name,
                    role: PpForgeTextRole.title,
                    weight: FontWeight.w700,
                    maxLines: 1,
                  ),
                  PpForgeText(
                    desc != null && desc.isNotEmpty
                        ? desc
                        : accountTypeLabel(context, account.type),
                    role: PpForgeTextRole.caption,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (account.isShared) ...[
              const SizedBox(width: PpForgeSpacing.xs),
              OtherMembersStack(account: account),
            ],
          ],
        ),
        const Spacer(),
        if (account.showsBalance) _InfoLine(account: account),
        if (account.showsBalance) ...[
          const SizedBox(height: PpForgeSpacing.xs),
          MoneyText(
            accountDisplayBalance(account),
            style: PpForgeTypography.of(
              context,
              PpForgeTextRole.money,
            )?.copyWith(color: accountBalanceColor(context, account)),
          ),
          if (account.savings case final s? when s.saved > 0)
            PpForgeText(
              AppLocalizations.of(
                context,
              )!.fpWalletSavedLegend(moneyString(context, s.saved)),
              role: PpForgeTextRole.caption,
              maxLines: 1,
            ),
        ],
        if (utilization != null) ...[
          const SizedBox(height: PpForgeSpacing.xs),
          ProgressRow(
            value: utilization,
            color: accent,
            height: 4,
            fillLabel: '${account.creditUsedPct}%',
          ),
        ],
      ],
    );
  }
}

/// What the grid card says above the balance: a card's due date (amber within
/// a week), else its credit left, else this month's money in and out.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final days = account.daysUntilDue;
    final available = account.creditAvailable;
    if (account.type.isCredit && days != null && days >= 0) {
      return PpForgeText(
        days == 0 ? l.accountCardDueToday : l.accountCardDueIn(days),
        role: PpForgeTextRole.caption,
        color: days <= 7 ? palette.warning : null,
        weight: days <= 7 ? FontWeight.w700 : null,
        maxLines: 1,
      );
    }
    if (account.type.isCredit && available != null) {
      return PpForgeText(
        l.fpWalletCardLeft(moneyString(context, available)),
        role: PpForgeTextRole.caption,
        maxLines: 1,
      );
    }
    if (account.monthIn <= 0 && account.monthOut <= 0) {
      return const SizedBox.shrink();
    }
    Widget part(IconData icon, Color color, double amount) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PpForgeIcon(icon, size: PpForgeIconSize.xs, color: color),
        const SizedBox(width: PpForgeSpacing.xxs),
        PpForgeText(moneyString(context, amount), role: PpForgeTextRole.caption),
      ],
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            part(AppIcons.trendUp, palette.income, account.monthIn),
            const SizedBox(width: PpForgeSpacing.sm),
            part(AppIcons.trendDown, palette.expense, account.monthOut),
          ],
        ),
      ),
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
      iconCode: account.shownIconCode,
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
  final palette = Theme.of(context).extension<PpForgeColors>()!;
  if (account.isLiability) return ModuleColors.of(context).walletLiability;
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

/// Each wallet type's own icon + colour, shown until the user picks theirs.
extension AccountTypeIconDefault on AccountType {
  TypeIconDefault get iconDefault => switch (this) {
    AccountType.cash => const TypeIconDefault(
      iconId: 'cash',
      color: Color(0xFF16A34A),
    ),
    AccountType.bank => const TypeIconDefault(
      iconId: 'bank',
      color: Color(0xFF2563EB),
    ),
    AccountType.eWallet => const TypeIconDefault(
      iconId: 'e_wallet',
      color: Color(0xFF7C3AED),
    ),
    AccountType.creditCard => const TypeIconDefault(
      iconId: 'credit_card',
      color: Color(0xFFEA580C),
    ),
    AccountType.payLater => const TypeIconDefault(
      iconId: 'schedule',
      color: Color(0xFFD97706),
    ),
  };
}
