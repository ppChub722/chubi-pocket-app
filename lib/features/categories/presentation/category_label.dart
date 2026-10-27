import '../../../l10n/gen/app_localizations.dart';
import '../domain/category.dart';
import '../domain/category_type.dart';

String categoryDisplayName(AppLocalizations l, Category c) =>
    (c.isSystem ? _systemName(l, c) : null) ?? c.name;

String? _systemName(AppLocalizations l, Category c) {
  final kind = c.systemKind;
  if (kind == null) return _legacyIconName(l, c);
  return switch (kind) {
    'OPENING_IN' || 'OPENING_OUT' => l.categorySystemOpening,
    'ADJUST_IN' || 'ADJUST_OUT' => l.categorySystemAdjustment,
    'TRANSFER_IN' => l.categorySystemTransferIn,
    'TRANSFER_OUT' => l.categorySystemTransferOut,
    'DEBT_RECEIVED' => l.categorySystemDebtReceived,
    'DEBT_PAID' => l.categorySystemDebtPaid,
    'LOAN_GIVEN' => l.categorySystemLoanGiven,
    'LOAN_TAKEN' => l.categorySystemLoanTaken,
    _ => null,
  };
}

/// Fallback for a Category without `system_kind` (legacy fixtures / hub): the
/// reserved icon.
String? _legacyIconName(AppLocalizations l, Category c) =>
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
