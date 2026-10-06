import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/currencies.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../menus/option_menu.dart';
import '../sheets/option_sheet.dart';
import 'picker_tile.dart';

/// Currency field: a [PickerTile] that opens a popover of
/// [Currencies.codes] (short list → popover, per the app rule).
/// `onChanged: null` = read-only (e.g. an account's currency after create).
class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  /// Defaults to the localized "สกุลเงิน".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final display =
        '${Currencies.symbolOf(value)}  $value · ${Currencies.nameOf(l, value)}';
    final tileLabel = label ?? l.commonCurrency;
    if (onChanged == null) {
      return PickerTile(
        label: tileLabel,
        value: display,
        leading: const Icon(AppIcons.currency),
        readOnly: true,
        onTap: null,
      );
    }
    return OptionMenuAnchor<String>(
      selected: value,
      onSelected: onChanged!,
      options: [
        for (final c in Currencies.codes)
          SheetOption(
            value: c,
            label: '$c · ${Currencies.nameOf(l, c)}',
            leading: SizedBox(
              width: 24,
              child: Text(Currencies.symbolOf(c), textAlign: TextAlign.center),
            ),
          ),
      ],
      builder: (context, toggle) => PickerTile(
        label: tileLabel,
        value: display,
        leading: const Icon(AppIcons.currency),
        onTap: toggle,
      ),
    );
  }
}
