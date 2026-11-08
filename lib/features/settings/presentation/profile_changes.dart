import '../../../ui/ui.dart';

class ProfileChanges {
  const ProfileChanges({
    this.username,
    this.displayName,
    this.email,
    this.iconCode,
    this.clearIconCode = false,
  });

  final String? username;
  final String? displayName;
  final String? email;
  final IconCode? iconCode;
  final bool clearIconCode;
}

ProfileChanges profileChanges({
  required String name,
  required String email,
  required IconCode? iconCode,
  required String originalName,
  required String originalEmail,
  required IconCode? originalIconCode,
  String? username,
  String? originalUsername,
}) {
  final newEmail = email.trim();
  final emailChanged = newEmail.isNotEmpty && newEmail != originalEmail;
  final iconChanged = iconCode != originalIconCode;
  final newUsername = username?.trim();
  return ProfileChanges(
    username: newUsername != null && newUsername != originalUsername
        ? newUsername
        : null,
    displayName: name.trim() != originalName ? name.trim() : null,
    email: emailChanged ? newEmail : null,
    iconCode: iconChanged ? iconCode : null,
    clearIconCode: iconChanged && iconCode == null,
  );
}
