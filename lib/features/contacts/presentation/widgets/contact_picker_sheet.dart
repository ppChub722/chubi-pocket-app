import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../data/contacts_repository.dart';
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

/// "กับใคร" — search the user's active contacts, or (when [allowFreeText])
/// use the typed name for someone not in the book. Used by debts, bill
/// splits and project members.
Future<ContactPickResult?> showContactPickerSheet(
  BuildContext context, {
  String? selectedContactId,
  bool allowFreeText = true,
  String? title,
}) {
  return showAppSheet<ContactPickResult>(
    context,
    title: title ?? AppLocalizations.of(context)!.contactPickerTitle,
    // Fixed height so the results list scrolls inside the sheet, under the
    // title row; shrinks with the keyboard (the search field autofocuses).
    builder: (ctx) => SizedBox(
      height:
          (MediaQuery.sizeOf(ctx).height -
              MediaQuery.viewInsetsOf(ctx).bottom) *
          0.7,
      child: _ContactPicker(
        selectedContactId: selectedContactId,
        allowFreeText: allowFreeText,
      ),
    ),
  );
}

class _ContactPicker extends StatefulWidget {
  const _ContactPicker({
    required this.selectedContactId,
    required this.allowFreeText,
  });

  final String? selectedContactId;
  final bool allowFreeText;

  @override
  State<_ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends State<_ContactPicker> {
  late final Future<List<Contact>> _future = context
      .read<ContactsRepository>()
      .list(status: 'active');
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final q = _query.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchBar(
          autofocus: true,
          hint: widget.allowFreeText ? l.contactPickerSearchHint : null,
          onChanged: (v) => setState(() => _query = v),
        ),
        Expanded(
          child: FutureBuilder<List<Contact>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < 6; i++) const SkeletonListTile(),
                  ],
                );
              }
              final all = snap.data ?? const <Contact>[];
              final lower = q.toLowerCase();
              final hits = lower.isEmpty
                  ? all
                  : all
                        .where(
                          (c) =>
                              c.effectiveName.toLowerCase().contains(lower) ||
                              (c.effectiveEmail?.toLowerCase().contains(
                                    lower,
                                  ) ??
                                  false) ||
                              (c.phone?.contains(lower) ?? false),
                        )
                        .toList();
              final exact = all.any(
                (c) => c.effectiveName.toLowerCase() == lower,
              );
              final offerName = widget.allowFreeText && q.isNotEmpty && !exact;

              return ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  if (offerName)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        child: Icon(AppIcons.add, color: scheme.primary),
                      ),
                      title: Text(l.contactPickerUseName(q)),
                      subtitle: Text(l.contactPickerUseNameHint),
                      onTap: () => Navigator.pop(context, ContactNameTyped(q)),
                    ),
                  if (all.isEmpty && !offerName)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        l.contactPickerEmpty,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final c in hits)
                    ListTile(
                      leading: UserAvatar(
                        displayName: c.effectiveName,
                        iconCode: c.effectiveIconCode,
                      ),
                      title: Text(c.effectiveName),
                      subtitle: c.effectiveEmail == null
                          ? null
                          : Text(c.effectiveEmail!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.isLinked)
                            Icon(
                              AppIcons.link,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          if (c.id == widget.selectedContactId) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(AppIcons.check, color: scheme.primary),
                          ],
                        ],
                      ),
                      selected: c.id == widget.selectedContactId,
                      onTap: () => Navigator.pop(context, ContactPicked(c)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
