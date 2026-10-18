import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart' as ui;
import '../../../../ui/ui.dart';
import '../../../../core/network/api_exception.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../cubit/contacts_cubit.dart';
import '../pages/contact_detail_page.dart';
import '../../domain/contact.dart';

sealed class ContactPickResult {
  const ContactPickResult();
}

/// A contact (level 2 or 3).
class ContactPicked extends ContactPickResult {
  const ContactPicked(this.contact);
  final Contact contact;
}

/// A new name typed in the search.
class ContactNameTyped extends ContactPickResult {
  const ContactNameTyped(this.name);
  final String name;
}

/// A name already known (from the debts) that isn't a contact (level 1).
class ContactNamePicked extends ContactPickResult {
  const ContactNamePicked(this.name);
  final String name;
}

/// Who the picker is for. Same people either way (every contact + the names
/// that aren't contacts); [debts] adds each one's debt balance and the
/// owing / no-debt tabs.
enum ContactPickerMode { contacts, debts }

/// Tabs of each mode, in order — a caller picks its default with
/// `initialFilter` (its index).
abstract final class ContactPickerTabs {
  static const contactsAll = 0;
  static const contactsContacts = 1;
  static const contactsNotInContacts = 2;
  static const debtsAll = 0;
  static const debtsOwing = 1;
  static const debtsNoDebt = 2;
  static const debtsNotInContacts = 3;
}

Future<ContactPickResult?> showContactPickerSheet(
  BuildContext context, {
  String? selectedContactId,
  bool allowFreeText = true,
  bool allowCreate = false,
  String? title,
  String? unlinkAs,
  ContactPickerMode mode = ContactPickerMode.contacts,
  int initialFilter = 0,
  Future<DebtPeoplePage>? people,
}) async {
  final contacts = context.read<ContactsCubit>()..loadIfNeeded();
  final debts = ValueNotifier<List<PersonBalance>>(const []);
  Future<DebtPeoplePage>? source = people;
  if (source == null) {
    try {
      source = context.read<PersonalDebtsRepository>().listPeople(
        all: true,
        perPage: 100,
      );
    } catch (_) {
      source = null; // no debts here (a test, the hub): contacts only
    }
  }
  source?.then((p) => debts.value = p.items, onError: (_) {});
  Contact? made;
  final names = <String, String>{};
  final outcome = await ui.showContactPicker(
    context,
    refresh: debts,
    data: (ctx) {
      final l = AppLocalizations.of(ctx)!;
      final cubit = ctx.read<ContactsCubit>();
      final state = ctx.watch<ContactsCubit>().state;
      final isDebts = mode == ContactPickerMode.debts;
      final rows = _rows(
        ctx,
        l,
        contacts: state.contacts
            .where((c) => c.status == ContactStatus.active)
            .toList(),
        people: debts.value,
        withDebt: isDebts,
      );
      names
        ..clear()
        ..addEntries(rows.map((r) => MapEntry(r.id, r.name)));
      bool owing(ui.ContactPickerRow r) => r.tags.contains(_owing);
      bool bare(ui.ContactPickerRow r) => r.level == PersonLevel.name;
      return ui.ContactPickerSheetData(
        labels: ui.ContactPickerLabels(
          title: title ?? l.contactPickerTitle,
          searchHint: isDebts
              ? l.debtsSearchHint
              : (allowFreeText ? l.contactPickerSearchHint : null),
          createNew: l.contactPickerCreateNew,
          saveAsContact: l.contactPickerSaveAsContact,
          useName: isDebts ? l.debtPersonAddTyped : l.contactPickerUseName,
          useNameHint: l.contactPickerUseNameHint,
          noContact: l.txSplitNoContact,
          noContactHint: l.txSplitNoContactHint,
          empty: allowFreeText
              ? l.contactPickerEmpty
              : l.contactPickerEmptyPlain,
          noMatch: l.contactPickerNoMatch,
          typeName: l.contactPickerTypeName,
        ),
        rows: rows,
        filters: isDebts
            ? [
                ui.ContactPickerFilter(l.contactPickerFilterAll, (_) => true),
                ui.ContactPickerFilter(l.contactPickerFilterOwing, owing),
                ui.ContactPickerFilter(
                  l.contactPickerFilterNoDebt,
                  (r) => !owing(r),
                ),
                ui.ContactPickerFilter(
                  l.contactPickerFilterNotInContacts,
                  bare,
                ),
              ]
            : [
                ui.ContactPickerFilter(l.contactPickerFilterAll, (_) => true),
                ui.ContactPickerFilter(
                  l.contactPickerFilterContacts,
                  (r) => !bare(r),
                ),
                ui.ContactPickerFilter(
                  l.contactPickerFilterNotInContacts,
                  bare,
                ),
              ],
        initialFilter: initialFilter,
        selectedId: selectedContactId,
        allowFreeText: allowFreeText,
        allowCreate: allowCreate,
        unlinkAs: unlinkAs,
        loading:
            state.status == ContactsStatus.loading ||
            state.status == ContactsStatus.initial,
        error: state.status == ContactsStatus.error ? state.error : null,
        onRetry: cubit.load,
        onSaveAsContact: (name) async {
          try {
            final c = await cubit.create(displayName: name);
            made = c;
            return c.id;
          } on ApiException catch (e) {
            if (ctx.mounted) {
              showAppSnackBar(
                ctx,
                e.message.isEmpty ? l.contactPickerSaveFailed : e.message,
                tone: Tone.danger,
              );
            }
            return null;
          }
        },
        onCreate: () async {
          final created = await Navigator.of(ctx, rootNavigator: true).push(
            MaterialPageRoute<Contact>(
              builder: (_) => const ContactDetailPage(popOnCreate: true),
            ),
          );
          if (created != null) made = created;
          return created?.id;
        },
      );
    },
  );
  debts.dispose();
  return switch (outcome) {
    null => null,
    ui.ContactPickerNameTyped(:final name) => ContactNameTyped(name),
    ui.ContactPickerRowPicked(:final id) when id.startsWith(_namePrefix) =>
      ContactNamePicked(names[id] ?? id.substring(_namePrefix.length)),
    ui.ContactPickerRowPicked(:final id) => _resolve(contacts, id, made),
  };
}

/// The id of a level-1 row (a debts key: `n:<lowercased name>`).
const _namePrefix = 'n:';
const _owing = 'owing';

/// Every active contact, then the names from the debts that aren't contacts.
/// With [withDebt]: each one's balance on the right, people still owing first
/// (in the debts' order), everyone else A–Z.
List<ui.ContactPickerRow> _rows(
  BuildContext context,
  AppLocalizations l, {
  required List<Contact> contacts,
  required List<PersonBalance> people,
  required bool withDebt,
}) {
  final symbol = withDebt ? debtCurrencySymbol(context) : '';
  final byKey = {for (final p in people) p.key: p};
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
  Set<String> tags(PersonBalance? p) => {if (p != null && p.net != 0) _owing};

  final rows = <({ui.ContactPickerRow row, int? debtOrder})>[];
  final order = {for (final (i, p) in people.indexed) p.key: i};
  for (final c in contacts) {
    final p = byKey[debtPersonKey(contactId: c.id)];
    final base = _rowOf(c);
    rows.add((
      row: ui.ContactPickerRow(
        id: base.id,
        name: base.name,
        subtitle: owingLine(p) ?? base.subtitle,
        level: base.level,
        iconCode: base.iconCode,
        keywords: base.keywords,
        trailing: trailing(p),
        tags: tags(p),
      ),
      debtOrder: p != null && p.net != 0 ? order[p.key] : null,
    ));
  }
  for (final p in people) {
    if (p.person.contactId != null || !p.key.startsWith(_namePrefix)) continue;
    rows.add((
      row: ui.ContactPickerRow(
        id: p.key,
        name: p.person.name,
        subtitle: owingLine(p),
        level: PersonLevel.name,
        iconCode: p.person.iconCode,
        trailing: trailing(p),
        tags: tags(p),
      ),
      debtOrder: p.net != 0 ? order[p.key] : null,
    ));
  }
  if (withDebt) {
    rows.sort((a, b) {
      final da = a.debtOrder, db = b.debtOrder;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return a.row.name.toLowerCase().compareTo(b.row.name.toLowerCase());
    });
  }
  return [for (final r in rows) r.row];
}

ContactPickResult? _resolve(ContactsCubit cubit, String id, Contact? made) {
  if (made != null && made.id == id) return ContactPicked(made);
  for (final c in cubit.state.contacts) {
    if (c.id == id) return ContactPicked(c);
  }
  return null;
}

ui.ContactPickerRow _rowOf(Contact c) {
  final description = c.description?.trim() ?? '';
  final email = c.email ?? '';
  return ui.ContactPickerRow(
    id: c.id,
    name: c.name,
    subtitle: description.isNotEmpty
        ? description
        : (email.isEmpty ? null : email),
    level: c.isLinked ? PersonLevel.linked : PersonLevel.contact,
    iconCode: c.iconCode,
    keywords: [
      c.displayName,
      if (c.nickname != null) c.nickname!,
      if (c.description != null) c.description!,
      if (c.email != null) c.email!,
      if (c.phone != null) c.phone!,
    ],
  );
}
