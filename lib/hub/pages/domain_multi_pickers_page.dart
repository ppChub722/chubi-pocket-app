import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import 'package:pp_forge/hub.dart';

/// `/dev/domain/multi-pickers` - the multi-select pickers: a category tree
/// with a per-row "include subcategories" switch, and a wallet list.
Widget buildDomainMultiPickersPage(BuildContext context) =>
    const _MultiPickersPage();

const _rows = <CategoryPickerRow>[
  CategoryPickerRow(id: 'food', name: 'Food', sortOrder: 0),
  CategoryPickerRow(id: 'cafe', name: 'Cafe', parentId: 'food', sortOrder: 0),
  CategoryPickerRow(id: 'meal', name: 'Meals', parentId: 'food', sortOrder: 1),
  CategoryPickerRow(id: 'transport', name: 'Transport', sortOrder: 1),
  CategoryPickerRow(id: 'rent', name: 'Rent', sortOrder: 2),
];

const _items = [
  AccountMultiPickItem(
    id: 'cash',
    name: 'Cash',
    icon: Icons.payments_outlined,
    balance: '1,200.00',
  ),
  AccountMultiPickItem(
    id: 'bank',
    name: 'Bank',
    icon: Icons.account_balance_outlined,
    balance: '35,000.00',
  ),
  // Untracked wallet: no balance line.
  AccountMultiPickItem(
    id: 'other',
    name: 'Untracked',
    icon: Icons.account_balance_wallet_outlined,
  ),
];

class _MultiPickersPage extends StatefulWidget {
  const _MultiPickersPage();

  @override
  State<_MultiPickersPage> createState() => _MultiPickersPageState();
}

class _MultiPickersPageState extends State<_MultiPickersPage> {
  List<CategoryMultiPick> _cats = const [];
  List<String> _wallets = const [];
  String _catsLast = 'not opened yet';
  String _walletsLast = 'not opened yet';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final catLabels = CategoryMultiPickerLabels(
      title: l.multiPickCategoriesTitle,
      searchHint: l.multiPickSearch,
      includeChildren: l.multiPickIncludeChildren,
      confirm: (n) => l.multiPickConfirm(n),
      empty: l.multiPickEmpty,
      noMatch: l.multiPickNoMatch,
    );
    final walletLabels = AccountMultiPickerLabels(
      title: l.multiPickWalletsTitle,
      searchHint: l.multiPickSearch,
      confirm: (n) => l.multiPickConfirm(n),
      empty: l.multiPickEmpty,
      noMatch: l.multiPickNoMatch,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'showCategoryMultiPicker',
          note:
              'The category tree with several picks (square check + tint, no '
              'tick). A picked row that has subcategories shows an include-'
              'subcategories switch. Confirm returns the list (empty is '
              'allowed); dismiss returns null.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'result: $_catsLast',
                child: PpForgeButton(
                  label: 'showCategoryMultiPicker',
                  variant: PpForgeButtonVariant.outlined,
                  onPressed: () async {
                    final r = await showCategoryMultiPicker(
                      context,
                      rows: _rows,
                      labels: catLabels,
                      initial: _cats,
                    );
                    if (!mounted) return;
                    setState(() {
                      if (r != null) _cats = r;
                      _catsLast = r == null
                          ? 'dismissed (null)'
                          : r
                                .map(
                                  (p) =>
                                      '${p.id}${p.includeChildren ? "+" : ""}',
                                )
                                .join(', ');
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'showAccountMultiPicker',
          note:
              'Several wallets (square check + tint). An untracked wallet '
              'passes no balance and shows none. Resolves the picked ids.',
          child: HubRow(
            cells: [
              HubCell(
                caption: 'result: $_walletsLast',
                child: PpForgeButton(
                  label: 'showAccountMultiPicker',
                  variant: PpForgeButtonVariant.outlined,
                  onPressed: () async {
                    final r = await showAccountMultiPicker(
                      context,
                      wallets: _items,
                      labels: walletLabels,
                      initial: _wallets,
                    );
                    if (!mounted) return;
                    setState(() {
                      if (r != null) _wallets = r;
                      _walletsLast = r == null
                          ? 'dismissed (null)'
                          : r.join(', ');
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
