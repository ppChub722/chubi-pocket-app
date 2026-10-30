import '../../../ui/ui.dart';
import '../../users/domain/avatar_settings.dart';

/// The profile edit hero's preview (0.4.2 1b), built the way the BE will
/// build my avatar from the draft: a picked photo source with a stored
/// picture ([photoUrl]) → that photo with the draft's ring, colours =
/// picked colours + ring colours (none → the icon's → the name colour);
/// otherwise the icon (or initials) of [name].
AvatarData profilePreviewAvatar({
  required String name,
  required IconCode? iconCode,
  required AvatarSettings settings,
  String? photoUrl,
}) {
  final base = AvatarData.forName(name, iconCode: iconCode);
  if (settings.isIcon || photoUrl == null || photoUrl.isEmpty) return base;
  final draft = AvatarColorsDraft.from(settings.colors, settings.border);
  final colors = draft.profileColors;
  return AvatarData(
    kind: AvatarKind.photo,
    photoUrl: photoUrl,
    iconCode: iconCode,
    initials: base.initials,
    colors: colors.isNotEmpty ? colors : base.colors,
    border: settings.border,
  );
}

/// [settings] with the colour-only icon maker's result.
AvatarSettings withColorsDraft(
  AvatarSettings settings,
  AvatarColorsDraft draft,
) {
  final border = draft.border;
  return settings.copyWith(
    colors: draft.colors,
    border: border,
    clearBorder: border == null,
  );
}

/// What the edit page sends: null when the picture pick did not change
/// (PUT /users/me leaves `avatar_settings` alone).
AvatarSettings? avatarSettingsChange(
  AvatarSettings original,
  AvatarSettings working,
) => original == working ? null : working;
