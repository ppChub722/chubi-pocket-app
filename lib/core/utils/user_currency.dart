import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../ui/ui.dart';

/// The viewer's own currency (owner 2026-10-15): every amount in the app is
/// shown in it, whatever currency column a record carries.
///
/// Read it in `build()` and pass it down: `select` asserts when called from a
/// builder callback (e.g. a `DetailPageBody` section builder).
extension UserCurrencyX on BuildContext {
  /// Code of the signed-in user's currency; `THB` before login / in tests
  /// without an [AuthCubit].
  String get userCurrency {
    try {
      return select<AuthCubit, String>(
        (c) => switch (c.state) {
          AuthAuthenticated(:final user) => user.currency,
          _ => 'THB',
        },
      );
    } on ProviderNotFoundException {
      return 'THB';
    }
  }

  String get userCurrencySymbol => Currencies.symbolOf(userCurrency);
}

/// For event handlers / callbacks, where a `select` read is not allowed.
extension UserCurrencyReadX on BuildContext {
  String get readUserCurrencySymbol {
    try {
      final s = read<AuthCubit>().state;
      return Currencies.symbolOf(
        s is AuthAuthenticated ? s.user.currency : 'THB',
      );
    } on ProviderNotFoundException {
      return Currencies.symbolOf('THB');
    }
  }
}
