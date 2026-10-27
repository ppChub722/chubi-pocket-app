import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../transactions/domain/refs.dart';
import '../domain/debt_ledger.dart';

String debtCurrencySymbol(BuildContext context) {
  final auth = context.read<AuthCubit>().state;
  final code = auth is AuthAuthenticated ? auth.user.currency : null;
  return Currencies.symbolOf(
    code != null && Currencies.codes.contains(code) ? code : 'THB',
  );
}

PersonLevel debtPersonLevel(EmbeddedPerson p) => p.contactId == null
    ? PersonLevel.name
    : (p.linked ? PersonLevel.linked : PersonLevel.contact);

DebtEntryDirection? debtDirectionFor(double? net) =>
    switch (net == null ? NetSide.even : NetSide.of(net)) {
      NetSide.owedToMe => DebtEntryDirection.received,
      NetSide.iOwe => DebtEntryDirection.paid,
      NetSide.even => null,
    };

/// A person-book kind as its system category's name (ให้กู้ยืม, กู้ยืม,
/// ชำระหนี้, รับชำระหนี้): what an entry with no description of its own shows
/// (owner 2026-10-26; no generated "ให้ ลี ยืม" any more). [out] = the money
/// went from me to them.
String debtKindName(
  AppLocalizations l, {
  required bool out,
  required bool repayment,
}) => repayment
    ? (out ? l.categorySystemDebtPaid : l.categorySystemDebtReceived)
    : (out ? l.categorySystemLoanGiven : l.categorySystemLoanTaken);

/// [debtKindName] of a stored entry: paid = money out of me, both for a debt
/// (I lent) and a repayment (I paid back).
String debtEntryKindName(AppLocalizations l, DebtEntry e) => debtKindName(
  l,
  out: e.direction == DebtEntryDirection.paid,
  repayment: e.isRepayment,
);

String debtPersonPath(String key) =>
    '/personal-debts/people/${Uri.encodeComponent(key)}';
