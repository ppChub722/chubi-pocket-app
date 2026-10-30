import '../../../ui/ui.dart';
import '../../users/domain/avatar_settings.dart';
import '../domain/connection.dart';

/// How a connection's row looks on the profile page (0.4.2 1b): not
/// available → coming soon; not linked → grey; linked with a picture → the
/// picture + logo badge; linked without → the logo in colour.
ConnectionRowState connectionRowState(Connection c) {
  if (!c.available) return ConnectionRowState.comingSoon;
  if (!c.linked) return ConnectionRowState.unlinked;
  return c.photo != null && c.photo!.url.isNotEmpty
      ? ConnectionRowState.linkedPhoto
      : ConnectionRowState.linkedLogo;
}

/// The settings card's third line: `(logo_url, name)` of the linked apps,
/// in the server's order.
List<(String, String)> linkedLogos(List<Connection> items) => [
  for (final c in items)
    if (c.linked) (c.logoUrl, c.name),
];

/// The linked app my picked picture comes from (its logo badges my avatar),
/// else null (icon, upload, an unlinked app, nothing loaded).
Connection? pictureSourceApp(AvatarSettings? settings, List<Connection> items) {
  final source = settings?.source;
  if (source == null ||
      source == AvatarSource.icon ||
      source == AvatarSource.upload) {
    return null;
  }
  for (final c in items) {
    if (c.provider == source) return c.linked ? c : null;
  }
  return null;
}

/// The edit page's picture rows after ไอคอน / อัปโหลดเอง: one per linked app
/// that has a stored picture.
List<Connection> photoSourceApps(List<Connection> items) => [
  for (final c in items)
    if (c.linked && c.photo != null && c.photo!.url.isNotEmpty) c,
];

/// The connection page's permission rows: a switch only when the app is
/// linked and the permission is live.
enum PermissionRowState { toggle, dimmed, comingSoon }

PermissionRowState permissionRowState(Connection c, ConnectionPermission p) {
  if (!p.available) return PermissionRowState.comingSoon;
  return c.linked ? PermissionRowState.toggle : PermissionRowState.dimmed;
}
