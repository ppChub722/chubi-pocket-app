import '../../../l10n/gen/app_localizations.dart';
import '../domain/category.dart';
import '../domain/category_type.dart';

/// The name to show for [c]. The BE seeds the eight system categories
/// (opening balance, adjustment, transfer in / out, debt received / paid)
/// with English names and keeps `system_kind` off the wire, so they're
/// recognised by their reserved icon and shown in the user's language.
/// Every other category shows its own name.
String categoryDisplayName(AppLocalizations l, Category c) =>
    (c.isSystem ? _systemName(l, c) : null) ?? c.name;

String? _systemName(AppLocalizations l, Category c) =>
    switch (c.iconCode?.icon) {
      'system_opening' => l.categorySystemOpening,
      'system_adjustment' => l.categorySystemAdjustment,
      'system_transfer' =>
        c.type == CategoryType.income
            ? l.categorySystemTransferIn
            : l.categorySystemTransferOut,
      'system_debt_received' => l.categorySystemDebtReceived,
      'system_debt_paid' => l.categorySystemDebtPaid,
      _ => null,
    };
