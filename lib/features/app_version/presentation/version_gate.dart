import '../../../core/router/dev_hub_path.dart';

const updateRequiredPath = '/update-required';

String? versionGateRedirect(String location, {required bool blocked}) {
  final path = Uri.parse(location).path;
  if (isDevHubPath(path)) return null;
  if (blocked) return path == updateRequiredPath ? null : updateRequiredPath;
  return path == updateRequiredPath ? '/' : null;
}
