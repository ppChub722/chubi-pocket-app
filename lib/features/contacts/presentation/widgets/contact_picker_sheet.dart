import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../../core/network/api_exception.dart';
import '../cubit/contacts_cubit.dart';
import '../../domain/contact.dart';
import 'contact_linked_mark.dart';

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

/// "กับใคร" — on the kit [PickerSheet]: search the user's active contacts,
/// or (when [allowFreeText]) a typed name for someone not in the book —
/// "ใช้ชื่อนี้" as it is, or "＋ บันทึกเป็นผู้ติดต่อ" (made, then picked).
/// The current one is highlighted (no ✓). Used by debts, bill splits and
/// project members. Contacts come from [ContactsCubit], so a failed load
/// shows an error with retry, not "no contacts".
Future<ContactPickResult?> showContactPickerSheet(
  BuildContext context, {
  String? selectedContactId,
  bool allowFreeText = true,
  String? title,
}) {
  context.read<ContactsCubit>().loadIfNeeded();
  return showAppSheetCustom<ContactPickResult>(
    context,
    builder: (_) => _ContactPicker(
      title: title ?? AppLocalizations.of(context)!.contactPickerTitle,
      selectedContactId: selectedContactId,
      allowFreeText: allowFreeText,
    ),
  );
}

class _ContactPicker extends StatefulWidget {
  const _ContactPicker({
    required this.title,
    required this.selectedContactId,
    required this.allowFreeText,
  });

  final String title;
  final String? selectedContactId;
  final bool allowFreeText;

  @override
  State<_ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends State<_ContactPicker> {
  final _search = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String? _subtitleOf(Contact c) {
    // Description (who they are) wins over email — as on the contacts list.
    final description = c.description?.trim() ?? '';
    if (description.isNotEmpty) return description;
    final email = c.effectiveEmail ?? '';
    return email.isEmpty ? null : email;
  }

  /// "＋ บันทึกเป็นผู้ติดต่อ": make the typed name a contact, then pick it.
  Future<void> _saveAsContact(String name) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ContactsCubit>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final c = await cubit.create(displayName: name);
      navigator.pop(ContactPicked(c));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        e.message.isEmpty ? l.contactPickerSaveFailed : e.message,
        tone: Tone.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<ContactsCubit>().state;
    final all = state.contacts
        .where((c) => c.status == ContactStatus.active)
        .toList();
    return PickerSheet(
      title: widget.title,
      searchable: true,
      searchAutofocus: true,
      searchController: _search,
      searchHint: widget.allowFreeText ? l.contactPickerSearchHint : null,
      loading:
          all.isEmpty &&
          (state.status == ContactsStatus.loading ||
              state.status == ContactsStatus.initial),
      error: state.status == ContactsStatus.error && all.isEmpty
          ? state.error
          : null,
      onRetry: context.read<ContactsCubit>().load,
      builder: (context, lower) {
        final scheme = Theme.of(context).colorScheme;
        final typed = _search.text.trim();
        final hits = lower.isEmpty
            ? all
            : all
                  .where(
                    (c) =>
                        c.effectiveName.toLowerCase().contains(lower) ||
                        (c.description?.toLowerCase().contains(lower) ??
                            false) ||
                        (c.effectiveEmail?.toLowerCase().contains(lower) ??
                            false) ||
                        (c.phone?.contains(lower) ?? false),
                  )
                  .toList();
        final exact = all.any((c) => c.effectiveName.toLowerCase() == lower);
        final offerName = widget.allowFreeText && typed.isNotEmpty && !exact;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Someone not in the book: their name as it is, or saved as a
            // contact first.
            if (offerName) ...[
              PickerRow(
                // A typed name — the person mark's first level (👤), in
                // the avatars' 36 column + the 🔗 slot, so its text lines up
                // with the contact rows.
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: PersonMark(
                          name: typed,
                          level: PersonLevel.name,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: PersonMark.linkSlotWidth(36)),
                  ],
                ),
                title: l.contactPickerUseName(typed),
                subtitle: l.contactPickerUseNameHint,
                onTap: () => Navigator.pop(context, ContactNameTyped(typed)),
              ),
              PickerCreateRow(
                label: l.contactPickerSaveAsContact,
                onTap: _saving ? () {} : () => _saveAsContact(typed),
              ),
            ],
            if (all.isEmpty && !offerName)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l.contactPickerEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final c in hits)
              PickerRow(
                leading: ContactAvatar(contact: c, size: 36),
                title: c.effectiveName,
                subtitle: _subtitleOf(c),
                selected: c.id == widget.selectedContactId,
                onTap: () => Navigator.pop(context, ContactPicked(c)),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
