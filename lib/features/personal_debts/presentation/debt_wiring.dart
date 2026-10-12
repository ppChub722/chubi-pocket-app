import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/ui.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../transactions/domain/refs.dart';

/// Debts are single-currency (owner 2026-10-12): every amount is in the
/// user's own currency, from `/me`.
String debtCurrencySymbol(BuildContext context) {
  final auth = context.read<AuthCubit>().state;
  final code = auth is AuthAuthenticated ? auth.user.currency : null;
  return Currencies.symbolOf(
    code != null && Currencies.codes.contains(code) ? code : 'THB',
  );
}

/// The [PersonMark] level of a resolved person.
PersonLevel debtPersonLevel(EmbeddedPerson p) => p.contactId == null
    ? PersonLevel.name
    : (p.linked ? PersonLevel.linked : PersonLevel.contact);

/// `/personal-debts/people/<key>` (the key URL-encoded).
String debtPersonPath(String key) =>
    '/personal-debts/people/${Uri.encodeComponent(key)}';
