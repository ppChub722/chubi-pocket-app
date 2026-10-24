import '../domain/pending_transaction.dart';

({List<PendingTransaction> blocked, List<String> ready}) splitSelection(
  Iterable<String> selected,
  List<PendingTransaction> items,
) {
  final byId = {for (final p in items) p.id: p};
  final blocked = [
    for (final id in selected)
      if (byId[id] != null && !byId[id]!.canConfirm) byId[id]!,
  ];
  final ready = [
    for (final id in selected)
      if (byId[id]?.canConfirm ?? true) id,
  ];
  return (blocked: blocked, ready: ready);
}
