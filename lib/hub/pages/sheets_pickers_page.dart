import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'package:pp_forge/hub.dart';

/// `/dev/domain/pickers` — the category-tree and tag picker sheets
/// (presentational organisms; the feature wrappers feed them real data).
Widget buildSheetsPickersPage(BuildContext context) => const _PickersPage();

const _categoryLabels = CategoryPickerLabels(
  title: 'Choose category',
  searchHint: 'Search categories',
  none: 'No category',
  addNew: 'Add category',
  empty: 'No categories yet',
  noMatch: 'No match',
);

const _categories = <CategoryPickerRow>[
  CategoryPickerRow(
    id: 'food',
    name: 'Food & drinks',
    iconCode: IconCode(iconColors: ['#E67E22']),
  ),
  CategoryPickerRow(
    id: 'groceries',
    name: 'Groceries',
    parentId: 'food',
    iconCode: IconCode(iconColors: ['#E67E22']),
  ),
  CategoryPickerRow(
    id: 'fruit',
    name: 'Fruit',
    parentId: 'groceries',
    iconCode: IconCode(iconColors: ['#E67E22']),
  ),
  CategoryPickerRow(
    id: 'cafe',
    name: 'Cafe',
    parentId: 'food',
    sortOrder: 1,
    iconCode: IconCode(iconColors: ['#E67E22']),
  ),
  CategoryPickerRow(
    id: 'travel',
    name: 'Travel',
    sortOrder: 1,
    iconCode: IconCode(iconColors: ['#3F8EFC']),
  ),
  CategoryPickerRow(
    id: 'flights',
    name: 'Flights',
    parentId: 'travel',
    iconCode: IconCode(iconColors: ['#3F8EFC']),
  ),
  CategoryPickerRow(
    id: 'home',
    name: 'Home',
    sortOrder: 2,
    iconCode: IconCode(iconColors: ['#2ECC71']),
  ),
];

final _tagLabels = TagPickerLabels(
  title: 'Tags',
  searchHint: 'Search tags',
  ok: 'OK',
  addTag: 'New tag',
  createNamed: (n) => 'Create "$n"',
  empty: 'No tags yet',
  noMatch: 'No match',
  nameSave: 'Save',
  nameHint: 'Tag name',
);

const _tags = <TagPickerItem>[
  TagPickerItem(
    id: 't1',
    name: 'lunch',
    iconCode: IconCode(iconColors: ['#E67E22']),
  ),
  TagPickerItem(
    id: 't2',
    name: 'work',
    iconCode: IconCode(iconColors: ['#3F8EFC']),
  ),
  TagPickerItem(id: 't3', name: 'trip'),
  TagPickerItem(id: 't4', name: 'gift'),
];

class _PickersPage extends StatefulWidget {
  const _PickersPage();

  @override
  State<_PickersPage> createState() => _PickersPageState();
}

class _PickersPageState extends State<_PickersPage> {
  String _result = 'nothing picked yet';
  String? _categoryId = 'fruit';
  Set<String> _tagIds = {'t1'};

  void _say(Object? v) => setState(() => _result = '$v');

  Widget _demoButton(String label, VoidCallback onPressed) => PpForgeButton(
    label: label,
    onPressed: onPressed,
    variant: PpForgeButtonVariant.outlined,
  );

  Future<void> _category({
    bool allowNone = true,
    int maxDepth = 2,
    bool create = false,
    List<CategoryPickerRow> rows = _categories,
  }) async {
    final r = await showCategoryPicker(
      context,
      rows: rows,
      labels: _categoryLabels,
      selectedId: _categoryId,
      allowNone: allowNone,
      maxDepth: maxDepth,
      onCreate: create ? () async => 'home' : null,
    );
    switch (r) {
      case null:
        _say('dismissed');
      case CategoryPickerNone():
        setState(() => _categoryId = null);
        _say('none');
      case CategoryPickerPicked(:final id):
        setState(() => _categoryId = id);
        _say('category $id');
    }
  }

  Future<void> _tag({
    TagPickerData data = const TagPickerData(items: _tags),
    bool create = true,
  }) async {
    final notifier = ValueNotifier(data);
    final r = await showTagPicker(
      context,
      data: notifier,
      labels: _tagLabels,
      selected: _tagIds,
      onCreate: create
          ? (name) async {
              final id = 'new-${notifier.value.items.length}';
              notifier.value = TagPickerData(
                items: [
                  ...notifier.value.items,
                  TagPickerItem(id: id, name: name),
                ],
              );
              return id;
            }
          : null,
      onRetry: () => notifier.value = const TagPickerData(items: _tags),
    );
    if (r == null) {
      _say('dismissed');
    } else {
      setState(() => _tagIds = r);
      _say('tags ${r.join(', ')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'showCategoryPicker + CategoryPickerSheet',
          note:
              'The category-tree picker: indented rows with their own icon, '
              'a chevron only on rows that have children, a search that keeps '
              'the tree (a match opens its parents), the picked row '
              'highlighted and scrolled into view, an optional None row and '
              'an optional create row. Plain CategoryPickerRow values + '
              'CategoryPickerLabels in; resolves CategoryPickerPicked(id) / '
              'CategoryPickerNone / null (dismissed). The feature wrapper '
              'showCategoryPickerSheet maps Category models and l10n.',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              _demoButton('Three levels (Fruit picked)', _category),
              _demoButton(
                'Two levels, no None row',
                () => _category(allowNone: false, maxDepth: 1),
              ),
              _demoButton('With create row', () => _category(create: true)),
              _demoButton('Empty', () => _category(rows: const [])),
            ],
          ),
        ),
        HubDemo(
          title: 'showTagPicker + TagPickerSheet',
          note:
              'The tag picker: several tags at once as chips (icon + colour '
              'from the tag), a search, and a create row — the typed name, or '
              'the name sheet when the box is empty; the new tag shows up in '
              'the live list and is picked. Resolves the picked ids on OK / '
              'null. Without onCreate (the filter) an empty list shows an '
              'empty line. The feature wrapper showTagPickerSheet feeds the '
              'cubit list and creates through it; showNewTagNameSheet is the '
              'name sheet on its own.',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              _demoButton('Pick tags (can create)', _tag),
              _demoButton('Filter (no create)', () => _tag(create: false)),
              _demoButton(
                'Empty, no create',
                () => _tag(data: const TagPickerData(), create: false),
              ),
              _demoButton(
                'Loading',
                () => _tag(data: const TagPickerData(loading: true)),
              ),
              _demoButton(
                'Load error (retry)',
                () => _tag(
                  data: const TagPickerData(error: 'Could not load tags'),
                ),
              ),
              _demoButton('New-tag name sheet', () async {
                final n = await showNewTagNameSheet(
                  context,
                  title: 'New tag',
                  saveLabel: 'Save',
                  hint: 'Tag name',
                );
                _say(n ?? 'dismissed');
              }),
            ],
          ),
        ),
        HubDemo(title: 'Last result', child: PpForgeText(_result)),
      ],
    );
  }
}
