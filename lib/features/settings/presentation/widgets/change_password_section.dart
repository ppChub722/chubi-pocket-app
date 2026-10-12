import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/data/auth_repository.dart';

/// Profile › เปลี่ยนรหัสผ่าน: the kit's [ChangePasswordSection] with the
/// app's words and the real call. A wrong current password is a field error,
/// any other failure a message in the section.
class ProfileChangePasswordSection extends StatelessWidget {
  const ProfileChangePasswordSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final repo = context.read<AuthRepository>();
    return ChangePasswordSection(
      strings: ChangePasswordStrings(
        title: l.settingsChangePassword,
        primaryLabel: l.settingsChangePassword,
        currentLabel: l.changePasswordCurrentLabel,
        newLabel: l.changePasswordNewLabel,
        newHelper: l.changePasswordNewHelper,
        confirmLabel: l.changePasswordConfirmLabel,
        requiredError: l.commonRequired,
        tooShort: l.authRegisterPasswordTooShort,
        tooLong: l.authRegisterPasswordTooLong,
        mustDiffer: l.changePasswordNewMustDiffer,
        mismatch: l.changePasswordConfirmMismatch,
        success: l.changePasswordSnackSuccess,
      ),
      onSubmit: (current, next) async {
        try {
          await repo.changePassword(
            currentPassword: current,
            newPassword: next,
          );
          return null;
        } on ApiException catch (e) {
          if (e.code == 'WRONG_PASSWORD' || e.statusCode == 401) {
            return ChangePasswordFailure(
              currentError: l.changePasswordCurrentWrong,
            );
          }
          return ChangePasswordFailure(
            message: e.code == 'NETWORK_ERROR' || e.code == 'NETWORK_TIMEOUT'
                ? l.errorBannerNoConnectionShort
                : e.message,
          );
        }
      },
    );
  }
}
