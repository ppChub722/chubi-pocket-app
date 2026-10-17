import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

String debtPersonPath(String key) =>
    '/personal-debts/people/${Uri.encodeComponent(key)}';
