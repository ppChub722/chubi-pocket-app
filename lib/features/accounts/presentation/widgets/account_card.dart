import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code_widget.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';

/// Renders one account in the grid.
///
/// The account's [iconCode] drives the icon background, card border, and
/// balance text. Card surface stays neutral (`surfaceContainer`).
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
    final accent = account.iconCode?.accentColor ?? const Color(0xFF64B5F6);
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
    final accent = account.iconCode?.accentColor ?? const Color(0xFF64B5F6);
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
    final accent = account.iconCode?.accentColor ?? const Color(0xFF64B5F6);
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
    return EditableCircle(
      size: size,
      onTap: onTap,
      child: IconCodeWidget(
        iconCode: account.iconCode,
        size: size,
        fallbackIcon: Icons.account_balance_wallet,
      ),
    );
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
