enum AsyncStateKind { content, offline, slow, skeleton, error, empty }

/// What an AsyncStateView shows. [settled]: the first load has finished once.
/// [isOffline] is read only while a first load is running.
AsyncStateKind asyncStateKind({
  required bool loading,
  required bool isEmpty,
  required bool hasError,
  required bool hasEmptyView,
  required bool settled,
  required bool slow,
  required bool Function() isOffline,
}) {
  if (!isEmpty) return AsyncStateKind.content;
  if (loading && !settled && isOffline()) return AsyncStateKind.offline;
  if (loading && !settled && slow) return AsyncStateKind.slow;
  if (loading && !settled) return AsyncStateKind.skeleton;
  if (hasError) return AsyncStateKind.error;
  return hasEmptyView ? AsyncStateKind.empty : AsyncStateKind.content;
}
