import '../../atoms/app_icon_button.dart';
import '../../atoms/app_input.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import '../../molecules/chip_row.dart';
import '../../atoms/app_chip.dart';
import 'package:flutter/material.dart';

import '../../molecules/detail_rows.dart';
import '../../molecules/empty_view.dart';
import '../../organisms/app_sheet.dart';
import '../../atoms/live_items.dart';
import '../../organisms/picker_sheet.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import 'person_mark.dart';

/// One person in the picker, at any [level]: a bare name (not in contacts),
/// a contact, or a contact linked to a real user. [trailing] is extra info
/// the caller shows on the right (a debt balance); [tags] are what its
/// [ContactPickerFilter]s test.
@immutable
class ContactPickerRow {
  const ContactPickerRow({
    required this.id,
    required this.name,
    this.subtitle,
    this.level = PersonLevel.contact,
    this.iconCode,
    this.keywords = const [],
    this.trailing,
    this.tags = const {},
  });

  final String id;
  final String name;
  final String? subtitle;
  final PersonLevel level;
  final IconCode? iconCode;
  final List<String> keywords;
  final Widget? trailing;
  final Set<String> tags;
}

/// A filter tab of the picker: [label] and which rows it keeps.
@immutable
class ContactPickerFilter {
  const ContactPickerFilter(this.label, this.test);

  final String label;
  final bool Function(ContactPickerRow row) test;
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
    required this.noContact,
    required this.noContactHint,
    required this.empty,
    this.searchHint,
    this.noMatch,
    this.typeName,
  });

  final String title;

  final String? searchHint;
  final String createNew;

  final String noContact;
  final String noContactHint;

  final String empty;

  /// A filter / search that keeps nobody. Null = [empty].
  final String? noMatch;

  /// The top row that opens the search to type a new name (with free text);
  /// null = no such row.
  final String? typeName;
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
    this.onCreate,
    this.filters = const [],
    this.initialFilter = 0,
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

  final Future<String?> Function()? onCreate;

  /// The filter tabs (the first is usually "all"); none = no tabs.
  final List<ContactPickerFilter> filters;

  /// Which tab is on when it opens — a caller's default.
  final int initialFilter;
}

Future<ContactPickerOutcome?> showContactPicker(
  BuildContext context, {
  required ContactPickerSheetData Function(BuildContext sheetContext) data,
  Listenable? refresh,
  Future<void> Function()? onRefresh,
}) => showAppSheetCustom<ContactPickerOutcome>(
  context,
  builder: (_) => SheetRefreshScope(
    onRefresh: onRefresh,
    child: refresh == null
        ? Builder(builder: (ctx) => ContactPickerSheet(data: data(ctx)))
        : ListenableBuilder(
            listenable: refresh,
            builder: (ctx, _) => ContactPickerSheet(data: data(ctx)),
          ),
  ),
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
  final _newName = TextEditingController();
  late int _filter = widget.data.filters.isEmpty
      ? 0
      : widget.data.initialFilter.clamp(0, widget.data.filters.length - 1);

  @override
  void dispose() {
    _search.dispose();
    _newName.dispose();
    super.dispose();
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
      searchToggle: true,
      searchController: _search,
      searchHint: l.searchHint,
      loading: all.isEmpty && d.loading,
      error: d.error != null && all.isEmpty ? d.error : null,
      onRetry: d.onRetry,
      footer: d.allowCreate && d.onCreate != null
          ? PickerCreateRow(label: l.createNew, onTap: _create)
          : null,
      header: d.filters.length < 2
          ? null
          : ChipRow(
              chips: [
                for (final (i, f) in d.filters.indexed)
                  AppChip(
                    label: f.label,
                    size: ChipSize.chip,
                    selected: i == _filter,
                    dashed: i != _filter,
                    onTap: () => setState(() => _filter = i),
                  ),
              ],
            ),
      builder: (context, lower) {
        final shown = d.filters.isEmpty
            ? all
            : all.where(d.filters[_filter].test).toList();
        final hits = lower.isEmpty
            ? shown
            : shown
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(lower) ||
                        (c.subtitle?.toLowerCase().contains(lower) ?? false) ||
                        c.keywords.any((k) => k.toLowerCase().contains(lower)),
                  )
                  .toList();
        final offerType = d.allowFreeText && l.typeName != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (d.unlinkAs != null || offerType || hits.isNotEmpty)
              SectionCard(
                first: true,
                children: [
                  if (offerType)
                    _NewNameRow(
                      controller: _newName,
                      hint: l.typeName!,
                      onSubmit: (name) =>
                          Navigator.pop(context, ContactPickerNameTyped(name)),
                    ),
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
                  for (final c in hits)
                    PickerRow(
                      leading: PersonMark(
                        name: c.name,
                        level: c.level,
                        iconCode: c.iconCode,
                        size: 36,
                        reserveLinkSlot: true,
                      ),
                      title: c.name,
                      subtitle: c.subtitle,
                      trailing: c.trailing == null
                          ? null
                          : Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.lg - AppSpacing.xs,
                              ),
                              child: c.trailing,
                            ),
                      selected: c.id == d.selectedId,
                      onTap: () =>
                          Navigator.pop(context, ContactPickerRowPicked(c.id)),
                    ),
                ],
              ),
            if (all.isEmpty)
              EmptyView.compact(message: l.empty)
            else if (hits.isEmpty && d.unlinkAs == null)
              EmptyView.compact(message: l.noMatch ?? l.empty),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}

/// The top row of a picker that takes free text: a person mark, an input
/// for a new name, and ✓ (or the keyboard's done) to use it.
class _NewNameRow extends StatelessWidget {
  const _NewNameRow({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmit;

  void _submit() {
    final name = controller.text.trim();
    if (name.isNotEmpty) onSubmit(name);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.xs,
      AppSpacing.xs,
    ),
    child: Row(
      children: [
        _typedNameLeading(''),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppInput.card(
            controller: controller,
            hint: hint,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppIconButton.flat(
            icon: AppIcons.check,
            onPressed: controller.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ],
    ),
  );
}
