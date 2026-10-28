import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app/currencies.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../molecules/option_menu.dart';
import '../../organisms/option_sheet.dart';
import '../../molecules/detail_rows.dart';

class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final display =
        '${Currencies.symbolOf(value)}  $value | ${Currencies.nameOf(l, value)}';
    final tileLabel = label ?? l.commonCurrency;
    if (onChanged == null) {
      return AppDetailRow.pick(
        label: tileLabel,
        value: display,
        emptyText: display,
        leading: const Icon(AppIcons.currency),
        locked: true,
        horizontalInset: 0,
      );
    }
    return OptionMenuAnchor<String>(
      selected: value,
      onSelected: onChanged!,
      options: [
        for (final c in Currencies.codes)
          SheetOption(
            value: c,
            label: '$c | ${Currencies.nameOf(l, c)}',
            leading: SizedBox(
              width: 24,
              child: Text(Currencies.symbolOf(c), textAlign: TextAlign.center),
            ),
          ),
      ],
      builder: (context, toggle) => AppDetailRow.pick(
        label: tileLabel,
        value: display,
        emptyText: display,
        leading: const Icon(AppIcons.currency),
        onTap: toggle,
        horizontalInset: 0,
      ),
    );
  }
}
