import '../../../ui/ui.dart';
import '../domain/recurring_item.dart';

({ItemPage produced, ItemPage upcoming, RecurringDetail? detail}) applyItemWrite(
  ItemWriteResult r, {
  required ItemPage produced,
  required ItemPage upcoming,
  required RecurringDetail? detail,
  required DateTime now,
}) {
  final all = [...produced.items, ...upcoming.items];
  final known = {for (final i in all) i.id};
  final merged = [
    ...r.applyTo(all),
    for (final i in r.items)
      if (!known.contains(i.id)) i,
  ];
  bool ahead(RecurringItem i) =>
      i.state == OccurrenceState.upcoming ||
      (i.state == OccurrenceState.archived && !i.date.isBefore(now));
  final setting = r.setting;
  return (
    produced: ItemPage(
      items: [
        for (final i in merged)
          if (!ahead(i)) i,
      ]..sort((a, b) => b.date.compareTo(a.date)),
      page: produced.page,
      totalPages: produced.totalPages,
    ),
    upcoming: ItemPage(
      items: [
        for (final i in merged)
          if (ahead(i)) i,
      ]..sort((a, b) => a.date.compareTo(b.date)),
      page: upcoming.page,
      totalPages: upcoming.totalPages,
      windowed: upcoming.windowed,
      nextFrom: upcoming.nextFrom,
    ),
    detail: setting != null && detail != null
        ? RecurringDetail(
            recurring: setting,
            produced: detail.produced,
            upcoming: detail.upcoming,
            balances: detail.balances,
            stats: detail.stats,
          )
        : detail,
  );
}
