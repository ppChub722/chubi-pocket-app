import 'package:flutter/material.dart';

import '../../molecules/detail_rows.dart';
import '../../molecules/empty_view.dart';
import '../../organisms/app_sheet.dart';
import '../../organisms/picker_sheet.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import 'person_mark.dart';

@immutable
class ContactPickerRow {
  const ContactPickerRow({
    required this.id,
    required this.name,
    this.subtitle,
    this.linked = false,
    this.iconCode,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final String? subtitle;

  final bool linked;
  final IconCode? iconCode;

  final List<String> keywords;
}

sealed class ContactPickerOutcome {
  const ContactPickerOutcome();
}

class ContactPickerRowPicked extends ContactPickerOutcome {
  const ContactPickerRowPicked(this.id);
  final String id;
}

class ContactPickerNameTyped extends ContactPickerOutcome {
  const ContactPickerNameTyped(this.name);
  final String name;
}

class ContactPickerLabels {
  const ContactPickerLabels({
    required this.title,
    required this.createNew,
    required this.saveAsContact,
    required this.useName,
    required this.useNameHint,
    required this.noContact,
    required this.noContactHint,
    required this.empty,
    this.searchHint,
  });

  final String title;

  final String? searchHint;
  final String createNew;
  final String saveAsContact;

  final String Function(String name) useName;
  final String useNameHint;
  final String noContact;
  final String noContactHint;

  final String empty;
}

class ContactPickerSheetData {
  const ContactPickerSheetData({
    required this.labels,
    required this.rows,
    this.selectedId,
    this.allowFreeText = true,
    this.allowCreate = false,
    this.unlinkAs,
    this.loading = false,
    this.error,
    this.onRetry,
    this.onSaveAsContact,
    this.onCreate,
  });

  final ContactPickerLabels labels;
  final List<ContactPickerRow> rows;
  final String? selectedId;
  final bool allowFreeText;
  final bool allowCreate;

  final String? unlinkAs;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  final Future<String?> Function(String name)? onSaveAsContact;

  final Future<String?> Function()? onCreate;
}

Future<ContactPickerOutcome?> showContactPicker(
  BuildContext context, {
  required ContactPickerSheetData Function(BuildContext sheetContext) data,
}) => showAppSheetCustom<ContactPickerOutcome>(
  context,
  builder: (_) =>
      Builder(builder: (ctx) => ContactPickerSheet(data: data(ctx))),
);

class ContactPickerSheet extends StatefulWidget {
  const ContactPickerSheet({required this.data, super.key});

  final ContactPickerSheetData data;

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

Widget _typedNameLeading(String name) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SizedBox.square(
      dimension: 36,
      child: Center(
        child: PersonMark(name: name, level: PersonLevel.name, size: 24),
      ),
    ),
    SizedBox(width: PersonMark.linkSlotWidth(36)),
  ],
);

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  final _search = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _saveAsContact(String name) async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final id = await widget.data.onSaveAsContact!(name);
    if (!mounted) return;
    if (id == null) {
      setState(() => _saving = false);
      return;
    }
    navigator.pop(ContactPickerRowPicked(id));
  }

  Future<void> _create() async {
    final id = await widget.data.onCreate!();
    if (!mounted || id == null) return;
    Navigator.of(context).pop(ContactPickerRowPicked(id));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final l = d.labels;
    final all = d.rows;
    return PickerSheet(
      title: l.title,
      searchable: true,
      searchAutofocus: true,
      searchController: _search,
      searchHint: l.searchHint,
      loading: all.isEmpty && d.loading,
      error: d.error != null && all.isEmpty ? d.error : null,
      onRetry: d.onRetry,
      footer: d.allowCreate && d.onCreate != null
          ? PickerCreateRow(label: l.createNew, onTap: _create)
          : null,
      builder: (context, lower) {
        final typed = _search.text.trim();
        final hits = lower.isEmpty
            ? all
            : all
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(lower) ||
                        (c.subtitle?.toLowerCase().contains(lower) ?? false) ||
                        c.keywords.any((k) => k.toLowerCase().contains(lower)),
                  )
                  .toList();
        final exact = all.any((c) => c.name.toLowerCase() == lower);
        final offerName = d.allowFreeText && typed.isNotEmpty && !exact;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (d.unlinkAs != null || offerName || hits.isNotEmpty)
              SectionCard(
                first: true,
                children: [
                  if (d.unlinkAs != null)
                    PickerRow(
                      leading: _typedNameLeading(d.unlinkAs!),
                      title: l.noContact,
                      subtitle: l.noContactHint,
                      selected: d.selectedId == null,
                      onTap: () => Navigator.pop(
                        context,
                        ContactPickerNameTyped(d.unlinkAs!),
                      ),
                    ),
                  if (offerName) ...[
                    PickerRow(
                      leading: _typedNameLeading(typed),
                      title: l.useName(typed),
                      subtitle: l.useNameHint,
                      onTap: () =>
                          Navigator.pop(context, ContactPickerNameTyped(typed)),
                    ),
                    PickerCreateRow(
                      label: l.saveAsContact,
                      onTap: _saving || d.onSaveAsContact == null
                          ? null
                          : () => _saveAsContact(typed),
                    ),
                  ],
                  for (final c in hits)
                    PickerRow(
                      leading: PersonMark(
                        name: c.name,
                        level: c.linked
                            ? PersonLevel.linked
                            : PersonLevel.contact,
                        iconCode: c.iconCode,
                        size: 36,
                        reserveLinkSlot: true,
                      ),
                      title: c.name,
                      subtitle: c.subtitle,
                      selected: c.id == d.selectedId,
                      onTap: () =>
                          Navigator.pop(context, ContactPickerRowPicked(c.id)),
                    ),
                ],
              ),
            if (all.isEmpty && !offerName) EmptyView.compact(message: l.empty),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
