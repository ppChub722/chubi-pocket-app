import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/sheets/people` — the people sheets: contact picker, wire names.
Widget buildSheetsPeoplePage(BuildContext context) => const _SheetsPeoplePage();

const _contacts = [
  ContactPickerRow(
    id: 'c1',
    name: 'Mata',
    subtitle: 'Flatmate',
    linked: true,
    keywords: ['mata@example.com'],
  ),
  ContactPickerRow(id: 'c2', name: 'Nok', subtitle: 'nok@example.com'),
  ContactPickerRow(id: 'c3', name: 'Pim'),
];

ContactPickerLabels _labels({bool free = true}) => ContactPickerLabels(
  title: 'Who with',
  searchHint: free ? 'Search or type a name' : null,
  createNew: 'New contact',
  saveAsContact: 'Save as contact',
  useName: (n) => 'Use "$n"',
  useNameHint: 'Just the name, not a contact',
  noContact: 'No contact',
  noContactHint: 'Keep it as a typed name',
  empty: free ? 'No contacts yet - type a name' : 'No contacts yet',
);

class _SheetsPeoplePage extends StatefulWidget {
  const _SheetsPeoplePage();

  @override
  State<_SheetsPeoplePage> createState() => _SheetsPeoplePageState();
}

class _SheetsPeoplePageState extends State<_SheetsPeoplePage> {
  String _last = 'nothing yet';

  Future<void> _pick({
    List<ContactPickerRow> rows = _contacts,
    bool free = true,
    bool create = false,
    bool loading = false,
    Object? error,
    String? unlinkAs,
  }) async {
    final r = await showContactPicker(
      context,
      data: (_) => ContactPickerSheetData(
        labels: _labels(free: free),
        rows: rows,
        selectedId: 'c2',
        allowFreeText: free,
        allowCreate: create,
        unlinkAs: unlinkAs,
        loading: loading,
        error: error,
        onRetry: () {},
        onSaveAsContact: (name) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          return 'new-$name';
        },
        onCreate: () async => 'created',
      ),
    );
    if (!mounted) return;
    setState(
      () => _last = switch (r) {
        null => 'dismissed',
        ContactPickerRowPicked(:final id) => 'picked $id',
        ContactPickerNameTyped(:final name) => 'typed "$name"',
      },
    );
  }

  Future<void> _wire() async {
    final r = await showWireNamesSheet<Set<String>>(
      context,
      labels: WireNamesLabels(
        title: 'Match names to Mata',
        body: 'Typed split names that are not a contact yet.',
        searchHint: 'Search names',
        saveLabel: (n) => n == 0 ? 'Match' : 'Match $n',
      ),
      rows: const [
        WireNameRow(name: 'mata', subtitle: 'in 3 splits'),
        WireNameRow(name: 'Mat', subtitle: 'in 1 split'),
        WireNameRow(name: 'M.', subtitle: 'in 2 splits'),
      ],
      onSave: (picked) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return picked;
      },
    );
    if (mounted) setState(() => _last = 'wired ${r ?? 'nothing'}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'ContactPickerSheet',
          note:
              'Contact rows (PersonMark, linked mark), search, "no contact" '
              'row, typed name -> use as is / save as contact, create row. '
              'Selected = highlight (Nok).',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              PpForgeButton(label: 'Open', onPressed: _pick),
              PpForgeButton(
                label: 'With create row',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _pick(create: true),
              ),
              PpForgeButton(
                label: 'Unlink as',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _pick(unlinkAs: 'Somchai'),
              ),
              PpForgeButton(
                label: 'Contacts only',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _pick(free: false),
              ),
              PpForgeButton(
                label: 'Empty',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _pick(rows: const []),
              ),
              PpForgeButton(
                label: 'Loading',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _pick(rows: const [], loading: true),
              ),
              PpForgeButton(
                label: 'Error',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _pick(rows: const [], error: 'Network down'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'WireNamesSheet',
          note:
              'FormSheet: caption, search, checkable rows, primary "Match n" '
              '(disabled until one is checked; saving dims the sheet).',
          child: PpForgeButton(label: 'Open', onPressed: _wire),
        ),
        HubDemo(
          title: 'Last result',
          child: PpForgeText(_last, role: PpForgeTextRole.body),
        ),
      ],
    );
  }
}
