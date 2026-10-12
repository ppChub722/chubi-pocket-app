import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart' as ui;
import '../../../../ui/ui.dart';
import '../../../../core/network/api_exception.dart';
import '../cubit/contacts_cubit.dart';
import '../pages/contact_detail_page.dart';
import '../../domain/contact.dart';

/// Result of [showContactPickerSheet]. `null` = dismissed.
sealed class ContactPickResult {
  const ContactPickResult();
}

/// A saved contact was picked — send its id (e.g. `counterparty_contact_id`).
class ContactPicked extends ContactPickResult {
  const ContactPicked(this.contact);
  final Contact contact;
}

/// A free-text name (someone not in the contact book).
class ContactNameTyped extends ContactPickResult {
  const ContactNameTyped(this.name);
  final String name;
}

/// "กับใคร" — thin wrapper over the ui organism `ContactPickerSheet`: search
/// the user's active contacts, or (when [allowFreeText]) a typed name for
/// someone not in the book — "ใช้ชื่อนี้" as it is, or "＋ บันทึกเป็นผู้ติดต่อ"
/// (made, then picked). The current one is highlighted (no ✓). Used by debts,
/// bill splits and project members. [allowCreate] adds "สร้างผู้ติดต่อใหม่":
/// the create page is pushed over the sheet (like a category over its picker);
/// saving there picks the new contact, back returns here. Contacts come from
/// [ContactsCubit], so a failed load shows an error with retry, not "no
/// contacts". Here: Contact -> ui rows, l10n -> labels, create via the cubit.
Future<ContactPickResult?> showContactPickerSheet(
  BuildContext context, {
  String? selectedContactId,
  bool allowFreeText = true,
  bool allowCreate = false,
  String? title,
  String? unlinkAs,
}) async {
  final contacts = context.read<ContactsCubit>()..loadIfNeeded();
  // A contact made inside the sheet (save-as / create page) — resolved to the
  // model when the sheet answers with its id.
  Contact? made;
  final outcome = await ui.showContactPicker(
    context,
    data: (ctx) {
      final l = AppLocalizations.of(ctx)!;
      final cubit = ctx.read<ContactsCubit>();
      final state = ctx.watch<ContactsCubit>().state;
      final all = state.contacts
          .where((c) => c.status == ContactStatus.active)
          .toList();
      return ui.ContactPickerSheetData(
        labels: ui.ContactPickerLabels(
          title: title ?? l.contactPickerTitle,
          searchHint: allowFreeText ? l.contactPickerSearchHint : null,
          createNew: l.contactPickerCreateNew,
          saveAsContact: l.contactPickerSaveAsContact,
          useName: l.contactPickerUseName,
          useNameHint: l.contactPickerUseNameHint,
          noContact: l.txSplitNoContact,
          noContactHint: l.txSplitNoContactHint,
          empty: allowFreeText
              ? l.contactPickerEmpty
              : l.contactPickerEmptyPlain,
        ),
        rows: [for (final c in all) _rowOf(c)],
        selectedId: selectedContactId,
        allowFreeText: allowFreeText,
        allowCreate: allowCreate,
        unlinkAs: unlinkAs,
        loading:
            state.status == ContactsStatus.loading ||
            state.status == ContactsStatus.initial,
        error: state.status == ContactsStatus.error ? state.error : null,
        onRetry: cubit.load,
        // "＋ บันทึกเป็นผู้ติดต่อ": make the typed name a contact, then pick it.
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
        // The create page, pushed over the sheet. Saving there pops with the
        // new contact -> pick it; back (nothing saved) returns to the picker.
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
  return switch (outcome) {
    null => null,
    ui.ContactPickerNameTyped(:final name) => ContactNameTyped(name),
    ui.ContactPickerRowPicked(:final id) => _resolve(contacts, id, made),
  };
}

ContactPickResult? _resolve(ContactsCubit cubit, String id, Contact? made) {
  if (made != null && made.id == id) return ContactPicked(made);
  for (final c in cubit.state.contacts) {
    if (c.id == id) return ContactPicked(c);
  }
  return null;
}

ui.ContactPickerRow _rowOf(Contact c) {
  // Description (who they are) wins over email — as on the contacts list.
  final description = c.description?.trim() ?? '';
  final email = c.email ?? '';
  return ui.ContactPickerRow(
    id: c.id,
    name: c.name,
    subtitle: description.isNotEmpty
        ? description
        : (email.isEmpty ? null : email),
    linked: c.isLinked,
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
