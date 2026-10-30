import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../settings/presentation/pages/settings_money_page.dart'
    show signedInUser;
import '../data/connections_repository.dart';
import '../domain/connection.dart';
import 'cubit/connections_cubit.dart';

/// A failed connection call as a toast: the codes with their own words
/// (NO_PHOTO, LAST_LOGIN_METHOD), else the app's error text.
void showConnectionError(BuildContext context, Connection c, Object error) {
  final l = AppLocalizations.of(context)!;
  final code = error is ApiException ? error.code : null;
  final text = switch (code) {
    ConnectionErrors.noPhoto => l.connectionsErrorNoPhoto(c.name),
    ConnectionErrors.lastLoginMethod => l.connectionsErrorLastLoginMethod,
    _ => null,
  };
  if (text == null) {
    showErrorSnackBar(context, error);
  } else {
    showAppSnackBar(context, text, tone: Tone.danger);
  }
}

/// ลบ the picture imported from [c] (edit page + connection page): the
/// confirm dialog (with the "in use" line when it is my picked picture),
/// then DELETE /avatars/{provider}; my profile goes to [AuthCubit], the row
/// loses its picture. True when it was deleted.
Future<bool> deleteConnectionPhoto(
  BuildContext context,
  Connection c, {
  bool? inUse,
}) async {
  final l = AppLocalizations.of(context)!;
  final auth = context.read<AuthCubit>();
  final repo = context.read<ConnectionsRepository>();
  final cubit = context.read<ConnectionsCubit>();
  final picked =
      inUse ?? signedInUser(auth.state)?.avatarSettings?.source == c.provider;
  final ok = await showConfirmDialog(
    context,
    title: l.connectionsPhotoDeleteTitle(c.name),
    message: picked ? l.connectionsPhotoDeleteInUse : null,
    confirmLabel: l.commonDelete,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    final me = await repo.deleteAvatar(c.provider);
    auth.updateUser(me);
    cubit.photoDeleted(c.provider);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showConnectionError(context, c, e);
    return false;
  }
}
