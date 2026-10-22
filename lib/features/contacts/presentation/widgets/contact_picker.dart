import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';
import '../pages/contact_detail_page.dart';

sealed class ContactPick {
  const ContactPick();
}

/// A contact (level 2 or 3).
class ContactPicked extends ContactPick {
  const ContactPicked(this.contact);
  final Contact contact;
}

/// A name from the debts that isn't a contact (level 1).
class ContactNamePicked extends ContactPick {
  const ContactNamePicked(this.name);
  final String name;
}

/// A new name typed in the search, or the name "ไม่ระบุผู้ติดต่อ" keeps.
class ContactNameTyped extends ContactPick {
  const ContactNameTyped(this.name);
  final String name;
}

/// What [ContactPicker.payer] answers: me, or a person.
sealed class PayerPick {
  const PayerPick();
}

class PayerMe extends PayerPick {
  const PayerMe();
}

class PayerPerson extends PayerPick {
  const PayerPerson(this.pick);
  final ContactPick pick;
}

/// Same people either way: every active contact, then the names from the
/// debts that aren't contacts. [debts] adds each one's balance, puts the
/// people still owing first and has the owing / no-debt tabs.
enum ContactPickerMode { contacts, debts }

/// The tabs of each mode, in order, for `initialFilter`.
abstract final class ContactPickerTabs {
  static const contactsAll = 0;
  static const contactsContacts = 1;
  static const contactsNotInContacts = 2;
  static const debtsAll = 0;
  static const debtsOwing = 1;
  static const debtsNoDebt = 2;
  static const debtsNotInContacts = 3;
}

/// The people pickers every page opens: [one] person, a linked contact to
/// [walletInvite], the typed split names to [wireNames] to a contact.
abstract final class ContactPicker {
  /// [selectedId] = a contact id, or a debts name key (`n:…`) in [mode] debts.
  /// [allowFreeText] adds the name row at the bottom ([initialName] in it);
  /// saving it answers [ContactNameTyped], and "add a contact" takes that name.
  static Future<ContactPick?> one(
    BuildContext context, {
    ContactPickerMode mode = ContactPickerMode.contacts,
    String? selectedId,
    bool allowFreeText = false,
    bool allowCreate = false,
    String? initialName,
    String? title,
    int initialFilter = 0,
    bool useRootNavigator = true,
  }) async {
    final r = await _pick(
      context,
      mode: mode,
      selectedId: selectedId,
      allowFreeText: allowFreeText,
      allowCreate: allowCreate,
      initialName: initialName,
      title: title,
      initialFilter: initialFilter,
      useRootNavigator: useRootNavigator,
    );
    return r?.pick;
  }

  /// "ใครจ่าย": [me] pinned on top ("ฉัน"), then the people as in [one]
  /// (free text + create on). Answers [PayerMe] or [PayerPerson].
  static Future<PayerPick?> payer(
    BuildContext context, {
    required PickerNone me,
    bool meSelected = false,
    String? selectedId,
    String? title,
    bool useRootNavigator = true,
  }) async {
    final r = await _pick(
      context,
      selectedId: selectedId,
      allowFreeText: true,
      allowCreate: true,
      title: title,
      useRootNavigator: useRootNavigator,
      none: me,
      noneSelected: meSelected,
    );
    if (r == null) return null;
    if (r.none) return const PayerMe();
    final p = r.pick;
    return p == null ? null : PayerPerson(p);
  }

  static Future<({bool none, ContactPick? pick})?> _pick(
    BuildContext context, {
    ContactPickerMode mode = ContactPickerMode.contacts,
    String? selectedId,
    bool allowFreeText = false,
    bool allowCreate = false,
    String? initialName,
    String? title,
    int initialFilter = 0,
    bool useRootNavigator = true,
    PickerNone? none,
    bool noneSelected = false,
  }) async {
    final l = AppLocalizations.of(context)!;
    final contacts = _maybeRead<ContactsCubit>(context);
    final directory = _maybeRead<DebtDirectoryCubit>(context);
    if (contacts != null) unawaited(contacts.loadIfNeeded());
    if (directory != null) unawaited(directory.loadIfNeeded());
    final debts = mode == ContactPickerMode.debts;
    final symbol = debts ? debtCurrencySymbol(context) : '';
    var owing = <String>{};
    PickerData dataOf() {
      final s = contacts?.state;
      final people = _people(
        l,
        contacts: [
          for (final c in s?.contacts ?? const <Contact>[])
            if (c.status == ContactStatus.active) c,
        ],
        debts: directory?.state.people ?? const [],
        withDebt: debts,
        symbol: symbol,
      );
      owing = people.owing;
      return PickerData(
        people.items,
        loading: s != null && _loading(s),
        error: s != null && s.status == ContactsStatus.error ? s.error : null,
      );
    }

    final data = ValueNotifier(dataOf());
    final subs = [
      ?contacts?.stream.listen((_) => data.value = dataOf()),
      ?directory?.stream.listen((_) => data.value = dataOf()),
    ];
    bool bare(PickerItem i) => _isName(i.id);
    Contact? created;
    try {
      final r = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: title ?? l.contactPickerTitle,
          items: data.value.items,
          live: data,
          selected: {?selectedId},
          none: none,
          noneSelected: none == null ? selectedId == null : noneSelected,
          filters: debts
              ? [
                  PickerFilter(l.contactPickerFilterAll, (_) => true),
                  PickerFilter(
                    l.contactPickerFilterOwing,
                    (i) => owing.contains(i.id),
                  ),
                  PickerFilter(
                    l.contactPickerFilterNoDebt,
                    (i) => !owing.contains(i.id),
                  ),
                  PickerFilter(l.contactPickerFilterNotInContacts, bare),
                ]
              : [
                  PickerFilter(l.contactPickerFilterAll, (_) => true),
                  PickerFilter(l.contactPickerFilterContacts, (i) => !bare(i)),
                  PickerFilter(l.contactPickerFilterNotInContacts, bare),
                ],
          initialFilter: initialFilter,
          freeText: allowFreeText
              ? PickerFreeText(
                  hint: l.contactPickerTypeName,
                  saveLabel: l.contactPickerUseName,
                  leading: (typed) => _mark(typed, PersonLevel.name, null),
                  initial: initialName?.trim() ?? '',
                  maxLength: TextLimits.name,
                )
              : null,
          create: allowCreate
              ? PickerCreate(
                  label: (_) => l.contactPickerCreateNew,
                  onCreate: (typed) async {
                    final made =
                        await Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<Contact>(
                            builder: (_) => ContactDetailPage(
                              popOnCreate: true,
                              initialName: typed.isEmpty ? null : typed,
                            ),
                          ),
                        );
                    if (made != null) created = made;
                    return made?.id;
                  },
                )
              : null,
          searchable: true,
          searchHint: debts ? l.debtsSearchHint : l.contactsSearchHint,
          emptyText: allowFreeText
              ? l.contactPickerEmpty
              : l.contactPickerEmptyPlain,
          noMatchText: l.contactPickerNoMatch,
          onRetry: contacts?.load,
          onRefresh: contacts == null
              ? null
              : syncRefreshOf(context, const {
                  SyncSet.contacts,
                  SyncSet.debtPeople,
                }),
        ),
      );
      if (r == null) return null;
      if (r.none) return (none: true, pick: null);
      if (r.text case final typed?) {
        return (none: false, pick: ContactNameTyped(typed));
      }
      final id = r.id;
      if (created case final c? when c.id == id) {
        return (none: false, pick: ContactPicked(c));
      }
      final ContactPick? pick = switch (data.value.items
          .where((i) => i.id == id)
          .firstOrNull) {
        PickerItem(data: final Contact c) => ContactPicked(c),
        PickerItem(data: final PersonBalance p) => ContactNamePicked(
          p.person.name,
        ),
        _ => null,
      };
      return (none: false, pick: pick);
    } finally {
      for (final s in subs) {
        unawaited(s.cancel());
      }
      data.dispose();
    }
  }

  /// The linked, active contacts not yet in the wallet ([excludeUserIds] are
  /// its members' user ids).
  static Future<Contact?> walletInvite(
    BuildContext context, {
    required Set<String> excludeUserIds,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final cubit = _maybeRead<ContactsCubit>(context);
    if (cubit != null) unawaited(cubit.loadIfNeeded());
    PickerData dataOf(ContactsState s) => PickerData(
      [
        for (final c in s.contacts)
          if (c.isLinked &&
              !c.isArchived &&
              !excludeUserIds.contains(c.linkedUser?.id))
            PickerItem(
              id: c.id,
              title: c.name,
              subtitle: c.email,
              leading: _mark(c.name, PersonLevel.linked, c.iconCode, size: 40),
              data: c,
            ),
      ],
      loading: _loading(s),
      error: s.status == ContactsStatus.error ? s.error : null,
    );
    final feed = cubit == null
        ? null
        : CubitFeed<ContactsState, PickerData>(cubit, dataOf);
    try {
      final r = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: l.walletInvitePickTitle,
          items: feed?.value.items ?? const [],
          live: feed?.listenable,
          note: l.walletInvitePickHint,
          searchHint: l.contactsSearchHint,
          emptyText: l.walletInvitePickEmpty,
          noMatchText: l.contactPickerNoMatch,
          onRetry: cubit?.load,
          onRefresh: cubit == null
              ? null
              : syncRefreshOf(context, const {SyncSet.contacts}),
        ),
      );
      final id = r?.id;
      final items = feed?.value.items ?? const <PickerItem>[];
      return switch (items.where((i) => i.id == id).firstOrNull) {
        PickerItem(data: final Contact c) => c,
        _ => null,
      };
    } finally {
      unawaited(feed?.dispose());
    }
  }

  /// The split names typed for [contactName] that aren't a contact. The ticks
  /// go to [onSave]; null = it failed, and the sheet stays open.
  static Future<T?> wireNames<T>(
    BuildContext context, {
    required String contactName,
    required List<UnlinkedName> names,
    required Future<T?> Function(Set<String> picked) onSave,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    T? saved;
    final r = await showItemPicker(
      context,
      useRootNavigator: useRootNavigator,
      ItemPickerSheet(
        title: l.contactWireSheetTitle(contactName),
        note: l.contactWireSheetBody,
        items: [
          for (final n in names)
            PickerItem(
              id: n.name,
              title: n.name,
              subtitle: l.contactWireCount(n.count),
            ),
        ],
        multi: true,
        searchHint: l.contactWireSearch,
        noMatchText: l.contactPickerNoMatch,
        confirmLabel: l.contactWireSave,
        minPicks: 1,
        onConfirm: (picked) async {
          saved = await onSave(picked.ids.toSet());
          return saved != null;
        },
      ),
    );
    return r == null ? null : saved;
  }

  static T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  static bool _loading(ContactsState s) =>
      s.status == ContactsStatus.initial || s.status == ContactsStatus.loading;

  /// The id of a level-1 row: a debts key `n:<lowercased name>`.
  static bool _isName(String id) => id.startsWith('n:');

  static Widget _mark(
    String name,
    PersonLevel level,
    IconCode? iconCode, {
    double size = 36,
  }) => PersonMark(
    name: name,
    level: level,
    iconCode: iconCode,
    size: size,
    reserveLinkSlot: true,
  );

  /// Every contact, then the names from the debts that aren't contacts. With
  /// [withDebt]: each one's balance on the right, people still owing first (in
  /// the debts' order), everyone else A–Z. [owing] = the ids still owing.
  static ({List<PickerItem> items, Set<String> owing}) _people(
    AppLocalizations l, {
    required List<Contact> contacts,
    required List<PersonBalance> debts,
    required bool withDebt,
    required String symbol,
  }) {
    final byKey = {for (final p in debts) p.key: p};
    final order = {for (final (i, p) in debts.indexed) p.key: i};
    Widget? trailing(PersonBalance? p) => !withDebt || p == null || p.net == 0
        ? null
        : NetBalance(
            amount: p.net,
            owedToMeLabel: l.debtsOwedToMe,
            iOweLabel: l.debtsIOwe,
            settledLabel: l.debtSettledLabel,
            currencySymbol: symbol,
          );
    String? owingLine(PersonBalance? p) => !withDebt || p == null || p.net == 0
        ? null
        : l.debtsOpenCount(p.openCount);

    final rows = <({PickerItem item, int? debtOrder})>[];
    final owing = <String>{};
    void add(PickerItem item, PersonBalance? p) {
      final key = p != null && p.net != 0 ? p.key : null;
      if (key != null) owing.add(item.id);
      rows.add((item: item, debtOrder: key == null ? null : order[key]));
    }

    for (final c in contacts) {
      final p = byKey[debtPersonKey(contactId: c.id)];
      final about = c.description?.trim() ?? '';
      final email = c.email ?? '';
      add(
        PickerItem(
          id: c.id,
          title: c.name,
          subtitle:
              owingLine(p) ??
              (about.isNotEmpty ? about : (email.isEmpty ? null : email)),
          leading: _mark(
            c.name,
            c.isLinked ? PersonLevel.linked : PersonLevel.contact,
            c.iconCode,
          ),
          trailing: trailing(p),
          keywords: [
            c.displayName,
            ?c.nickname,
            ?c.description,
            ?c.email,
            ?c.phone,
          ],
          data: c,
        ),
        p,
      );
    }
    for (final p in debts) {
      if (p.person.contactId != null || !_isName(p.key)) continue;
      add(
        PickerItem(
          id: p.key,
          title: p.person.name,
          subtitle: owingLine(p),
          leading: _mark(p.person.name, PersonLevel.name, p.person.iconCode),
          trailing: trailing(p),
          data: p,
        ),
        p,
      );
    }
    if (withDebt) {
      rows.sort((a, b) {
        final da = a.debtOrder, db = b.debtOrder;
        if (da != null && db != null) return da.compareTo(db);
        if (da != null) return -1;
        if (db != null) return 1;
        return a.item.title.toLowerCase().compareTo(b.item.title.toLowerCase());
      });
    }
    return (items: [for (final r in rows) r.item], owing: owing);
  }
}
