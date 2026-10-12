import 'package:flutter/material.dart';

import '../../ui.dart';

/// One wallet the picker offers, as plain display data.
@immutable
class WalletPickItem {
  const WalletPickItem({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
    this.subtitle,
    this.balance,
    this.cardBuilder,
  });

  final String id;
  final String name;
  final IconData icon;

  /// The card's tint (null = the app primary).
  final Color? color;

  /// A line under the name (the wallet's type).
  final String? subtitle;

  /// The balance, already formatted.
  final String? balance;

  /// A richer card than the default one (the feature's own wallet card): it
  /// gets the tap callback. null = the default card built from the fields
  /// above.
  final Widget Function(BuildContext context, VoidCallback onTap)? cardBuilder;
}

/// What [AccountPickerSheet] picked.
sealed class AccountPick {
  const AccountPick();
}

/// One of the listed wallets.
class AccountPickWallet extends AccountPick {
  const AccountPickWallet(this.id);
  final String id;
}

/// "No wallet".
class AccountPickNone extends AccountPick {
  const AccountPickNone();
}

/// The words of [AccountPickerSheet] — the caller passes its localised
/// strings.
class AccountPickerLabels {
  const AccountPickerLabels({
    required this.title,
    required this.none,
    required this.create,
    required this.empty,
  });

  final String title;

  /// The "no wallet" tile.
  final String none;

  /// The "＋ add wallet" row.
  final String create;

  /// Shown when no wallet matches / there are none.
  final String empty;
}

/// Pick one wallet — a PRESENTATIONAL organism on the kit [PickerSheet]: a
/// card grid of [wallets], the current pick ([selectedId]) highlighted with a
/// [SelectableFrame] (a tint + ring, no ✓), search only with more than 8.
/// Data, words and callbacks in, an [AccountPick] out; nothing imported from
/// features. [allowNone] adds a "no wallet" tile first. [onCreate] (when set)
/// adds "＋ add wallet": it runs the caller's create flow over the sheet and
/// resolves the new wallet's id (picked and closed) or null (back to the
/// picker). Resolves null when dismissed.
Future<AccountPick?> showAccountPickSheet(
  BuildContext context, {
  required List<WalletPickItem> wallets,
  required AccountPickerLabels labels,
  String? selectedId,
  bool allowNone = false,
  Future<String?> Function()? onCreate,
}) => showAppSheetCustom<AccountPick>(
  context,
  builder: (ctx) => AccountPickerSheet(
    wallets: wallets,
    labels: labels,
    selectedId: selectedId,
    allowNone: allowNone,
    onCreate: onCreate,
    onPicked: (p) => Navigator.of(ctx).pop(p),
  ),
);

class AccountPickerSheet extends StatelessWidget {
  const AccountPickerSheet({
    required this.wallets,
    required this.labels,
    required this.onPicked,
    this.selectedId,
    this.allowNone = false,
    this.onCreate,
    super.key,
  });

  final List<WalletPickItem> wallets;
  final AccountPickerLabels labels;
  final ValueChanged<AccountPick> onPicked;
  final String? selectedId;
  final bool allowNone;
  final Future<String?> Function()? onCreate;

  Future<void> _create(BuildContext context) async {
    final id = await onCreate!();
    if (!context.mounted || id == null) return;
    onPicked(AccountPickWallet(id));
  }

  @override
  Widget build(BuildContext context) {
    return PickerSheet(
      title: labels.title,
      searchable: wallets.length > 8,
      footer: onCreate != null
          ? PickerCreateRow(label: labels.create, onTap: () => _create(context))
          : null,
      builder: (context, q) {
        final scheme = Theme.of(context).colorScheme;
        final visible = q.isEmpty
            ? wallets
            : wallets.where((a) => a.name.toLowerCase().contains(q)).toList();
        final tiles = <Widget>[
          if (allowNone && q.isEmpty)
            SelectableFrame(
              selected: selectedId == null,
              child: _NoneTile(
                label: labels.none,
                onTap: () => onPicked(const AccountPickNone()),
              ),
            ),
          for (final a in visible)
            SelectableFrame(
              selected: a.id == selectedId,
              child: _tile(context, a),
            ),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: tiles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    labels.empty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    // Same columns as the wallets page.
                    crossAxisCount:
                        MediaQuery.sizeOf(context).shortestSide >= 600 ? 3 : 2,
                    mainAxisSpacing: AppSpacing.xs,
                    crossAxisSpacing: AppSpacing.xs,
                    // Fixed height: a vertical wallet card (icon · name ·
                    // type · balance + optional credit bar) + the selection
                    // ring.
                    mainAxisExtent: 156,
                  ),
                  children: tiles,
                ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, WalletPickItem a) {
    void tap() => onPicked(AccountPickWallet(a.id));
    final builder = a.cardBuilder;
    if (builder != null) return builder(context, tap);
    final color = a.color ?? Theme.of(context).colorScheme.primary;
    return HeroSurface(
      style: HeroStyle.tinted(color: color, glyph: a.icon, strongBorder: false),
      glyphSize: 88,
      onTap: tap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(a.icon, size: AppIconSize.xl, color: color),
            const Spacer(),
            AppText(
              a.name,
              role: AppTextRole.title,
              weight: FontWeight.w700,
              maxLines: 1,
            ),
            if (a.subtitle != null)
              AppText(a.subtitle!, role: AppTextRole.caption, maxLines: 1),
            if (a.balance != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText(a.balance!, role: AppTextRole.money, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// "No wallet" — same footprint as a wallet card, quiet styling.
class _NoneTile extends StatelessWidget {
  const _NoneTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      style: AppCardStyle.bordered,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            AppIcons.noWallet,
            size: AppIconSize.xl,
            color: scheme.onSurfaceVariant,
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
