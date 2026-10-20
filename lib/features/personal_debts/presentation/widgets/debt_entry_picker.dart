import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_ledger.dart';
import '../debt_wiring.dart';

class DebtEntryPicks {
  const DebtEntryPicks({this.ids = const {}, this.entries = const []});

  /// Every ticked id, in tick order (also ones the list no longer holds).
  final Set<String> ids;
  final List<DebtEntry> entries;
}

/// A person's open debt entries, to tick the ones being paid off.
/// [entries] = the list to start from (`const []` for a name typed just now);
/// without it the person's open entries are loaded.
abstract final class DebtEntryPicker {
  static Future<DebtEntryPicks?> many(
    BuildContext context, {
    required String personKey,
    Set<String> selected = const {},
    List<DebtEntry>? entries,
    String? title,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    final locale = Localizations.localeOf(context).languageCode;
    final repo = entries == null
        ? context.read<PersonalDebtsRepository>()
        : null;
    var latest = entries ?? const <DebtEntry>[];
    List<PickerItem> itemsOf(List<DebtEntry> all) => [
      for (final e in all) _item(l, e, symbol, locale),
    ];

    final r = await showItemPicker(
      context,
      useRootNavigator: useRootNavigator,
      ItemPickerSheet(
        title: title ?? l.debtMarkPaidTitle,
        items: itemsOf(latest),
        load: repo == null
            ? null
            : () async {
                try {
                  final page = await repo.entries(
                    personKey,
                    query: const DebtEntryQuery(paid: false),
                    perPage: 50,
                  );
                  latest = page.items;
                } catch (e, st) {
                  throw ApiException.from(e, st);
                }
                return itemsOf(latest);
              },
        multi: true,
        selected: selected,
        searchHint: l.debtsEntrySearchHint,
        emptyText: l.debtMarkPaidNone,
        noMatchText: l.debtsEntriesNoMatch,
        confirmLabel: l.debtCloseConfirm,
      ),
    );
    if (r == null) return null;
    final byId = {for (final e in latest) e.id: e};
    return DebtEntryPicks(
      ids: r.ids.toSet(),
      entries: [for (final id in r.ids) ?byId[id]],
    );
  }

  static PickerItem _item(
    AppLocalizations l,
    DebtEntry e,
    String symbol,
    String locale,
  ) {
    final paid = e.direction == DebtEntryDirection.paid;
    final text = (e.description ?? '').trim();
    final date = e.date;
    return PickerItem(
      id: e.id,
      title: text.isNotEmpty
          ? text
          : (paid ? l.debtsDirPaid : l.debtsDirReceived),
      subtitle: date == null
          ? null
          : DateFormatter.friendly(
              date,
              today: l.commonToday,
              yesterday: l.commonYesterday,
              locale: locale,
            ),
      trailing: MoneyText(
        e.amount,
        symbol: symbol,
        tone: paid ? MoneyTone.expense : MoneyTone.income,
      ),
    );
  }
}
