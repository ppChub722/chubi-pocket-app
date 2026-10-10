/// Where the blocking update page lives — outside the shell.
const updateRequiredPath = '/update-required';

/// The version gate's redirect: while [blocked], every location but
/// `/dev/*` (the debug hub stays reachable) goes to [updateRequiredPath];
/// once it isn't, the page sends the user home. Null = go ahead.
String? versionGateRedirect(String location, {required bool blocked}) {
  final path = Uri.parse(location).path;
  if (path == '/dev' || path.startsWith('/dev/')) return null;
  if (blocked) return path == updateRequiredPath ? null : updateRequiredPath;
  return path == updateRequiredPath ? '/' : null;
}
