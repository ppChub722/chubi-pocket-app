import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';

/// Renders one account in the grid.
///
/// Visual rule (locked in design discussion): the account's [color] drives
/// the icon background, the card border, and the balance text. The card
/// surface stays neutral (`surfaceContainer`) so dark/light themes both
/// remain legible.
///
/// Two layouts:
/// - [_HorizontalLayout] — used when the parent grid has 1 column (mobile
///   portrait). Reads like a list row: icon · name+type · balance.
/// - [_VerticalLayout] — used at 2 / 3 columns (mobile landscape, tablet,
///   web). Stacks icon top-left, name middle, balance bottom.
class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    required this.horizontal,
    this.onTap,
    this.onIconTap,
    super.key,
  });

  final Account account;

  /// True for 1-col grids; false for 2 / 3-col grids.
  final bool horizontal;
  final VoidCallback? onTap;

  /// When set, the icon circle becomes its own tap target — used by the
  /// account create / edit form to open the icon-color picker without
  /// hijacking taps on the rest of the card. Pass `null` to keep the icon
  /// non-interactive (the default in the grid).
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: account.color.color, width: 1.5),
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
              // Subtitle: description preferred, else fallback to type.
              // Keeps the most useful "what is this account for" hint
              // visible at the grid level without an extra line.
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
                    color: account.color.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (account.creditUtilization != null) ...[
              const SizedBox(height: 4),
              _UtilizationBar(
                fraction: account.creditUtilization!,
                color: account.color.color,
                width: 100,
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.accountCreditUsedPercent(
                  (account.creditUtilization! * 100).round(),
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: account.color.color,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (account.creditUtilization != null) ...[
          const SizedBox(height: 4),
          _UtilizationBar(
            fraction: account.creditUtilization!,
            color: account.color.color,
            width: double.infinity,
          ),
        ],
      ],
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.account,
    required this.size,
    this.onTap,
  });
  final Account account;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return EditableCircle(
      size: size,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: account.color.color,
          shape: BoxShape.circle,
        ),
        child: Icon(account.icon.icon, size: size * 0.55, color: Colors.white),
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

  /// Pass [double.infinity] to stretch to the parent's available width.
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
