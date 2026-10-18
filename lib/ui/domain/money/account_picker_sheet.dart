import 'package:flutter/material.dart';

import '../../ui.dart';

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

  final Color? color;

  final String? subtitle;

  final String? balance;

  final Widget Function(BuildContext context, VoidCallback onTap)? cardBuilder;
}

sealed class AccountPick {
  const AccountPick();
}

class AccountPickWallet extends AccountPick {
  const AccountPickWallet(this.id);
  final String id;
}

class AccountPickNone extends AccountPick {
  const AccountPickNone();
}

class AccountPickerLabels {
  const AccountPickerLabels({
    required this.title,
    required this.none,
    required this.create,
    required this.empty,
  });

  final String title;

  final String none;

  final String create;

  final String empty;
}

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
      searchToggle: true,
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
              child: _walletTile(
                context,
                a,
                () => onPicked(AccountPickWallet(a.id)),
              ),
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
                    crossAxisCount:
                        MediaQuery.sizeOf(context).shortestSide >= 600 ? 3 : 2,
                    mainAxisSpacing: AppSpacing.xs,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisExtent: 156,
                  ),
                  children: tiles,
                ),
        );
      },
    );
  }
}

Widget _walletTile(BuildContext context, WalletPickItem a, VoidCallback tap) {
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

typedef AccountMultiPick = ({Set<String> ids, bool none});

Future<AccountMultiPick?> showAccountMultiPickSheet(
  BuildContext context, {
  required List<WalletPickItem> wallets,
  required AccountPickerLabels labels,
  required String Function(int count) confirm,
  Set<String> selectedIds = const {},
  bool noneSelected = false,
}) => showAppSheetCustom<AccountMultiPick>(
  context,
  builder: (ctx) => AccountCardsMultiPickerSheet(
    wallets: wallets,
    labels: labels,
    confirm: confirm,
    selectedIds: selectedIds,
    noneSelected: noneSelected,
  ),
);

class AccountCardsMultiPickerSheet extends StatefulWidget {
  const AccountCardsMultiPickerSheet({
    required this.wallets,
    required this.labels,
    required this.confirm,
    this.selectedIds = const {},
    this.noneSelected = false,
    super.key,
  });

  final List<WalletPickItem> wallets;
  final AccountPickerLabels labels;
  final String Function(int count) confirm;
  final Set<String> selectedIds;
  final bool noneSelected;

  @override
  State<AccountCardsMultiPickerSheet> createState() =>
      _AccountCardsMultiPickerSheetState();
}

class _AccountCardsMultiPickerSheetState
    extends State<AccountCardsMultiPickerSheet> {
  late final Set<String> _ids = {...widget.selectedIds};
  late bool _none = widget.noneSelected;

  void _toggle(String id) => setState(() {
    if (!_ids.remove(id)) _ids.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final count = _ids.length + (_none ? 1 : 0);
    return PickerSheet(
      title: widget.labels.title,
      searchable: widget.wallets.length > 8,
      searchToggle: true,
      footer: PickerConfirmBar(
        label: widget.confirm(count),
        onPressed: () => Navigator.of(context).pop((ids: _ids, none: _none)),
      ),
      builder: (context, q) {
        final visible = q.isEmpty
            ? widget.wallets
            : widget.wallets
                  .where((a) => a.name.toLowerCase().contains(q))
                  .toList();
        final tiles = <Widget>[
          if (q.isEmpty)
            SelectableFrame(
              selected: _none,
              child: _NoneTile(
                label: widget.labels.none,
                onTap: () => setState(() => _none = !_none),
              ),
            ),
          for (final a in visible)
            SelectableFrame(
              selected: _ids.contains(a.id),
              child: _walletTile(context, a, () => _toggle(a.id)),
            ),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).shortestSide >= 600
                  ? 3
                  : 2,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisExtent: 156,
            ),
            children: tiles,
          ),
        );
      },
    );
  }
}
