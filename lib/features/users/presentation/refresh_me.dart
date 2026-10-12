import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../data/users_repository.dart';

/// Pull-to-refresh of the profile pages: re-reads `GET /users/me` and hands it
/// to [AuthCubit]. A failed refresh keeps what is on screen.
Future<void> refreshMe(BuildContext context) async {
  final users = context.read<UsersRepository>();
  final auth = context.read<AuthCubit>();
  try {
    auth.updateUser(await users.getMe());
  } on ApiException {
    // Stale is fine; the next pull retries.
  }
}
