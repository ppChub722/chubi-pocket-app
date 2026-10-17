const updateRequiredPath = '/update-required';

String? versionGateRedirect(String location, {required bool blocked}) {
  final path = Uri.parse(location).path;
  if (path == '/dev' || path.startsWith('/dev/')) return null;
  if (blocked) return path == updateRequiredPath ? null : updateRequiredPath;
  return path == updateRequiredPath ? '/' : null;
}
