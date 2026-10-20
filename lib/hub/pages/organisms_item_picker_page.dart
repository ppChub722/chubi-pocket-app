import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/ui/organisms/item-picker` — the one picker every entity picker is
/// built on, in each of its modes, on sample data.
Widget buildItemPickerPage(BuildContext context) => const _ItemPickerPage();

const _expense = 'expense';
const _income = 'income';

const _categories = [
  PickerItem(
    id: 'food',
    title: 'Food & Drinks',
    leading: Icon(AppIcons.category),
    group: _expense,
  ),
  PickerItem(
    id: 'groceries',
    title: 'Groceries',
    leading: Icon(AppIcons.category),
    parentId: 'food',
    group: _expense,
  ),
  PickerItem(
    id: 'delivery',
    title: 'Food delivery',
    leading: Icon(AppIcons.category),
    parentId: 'food',
    group: _expense,
  ),
  PickerItem(
    id: 'transport',
    title: 'Transportation',
    leading: Icon(AppIcons.category),
    group: _expense,
  ),
  PickerItem(
    id: 'taxi',
    title: 'Taxi',
    leading: Icon(AppIcons.category),
    parentId: 'transport',
    group: _expense,
  ),
  PickerItem(
    id: 'fuel',
    title: 'Fuel',
    leading: Icon(AppIcons.category),
    parentId: 'transport',
    group: _expense,
  ),
  PickerItem(
    id: 'shopping',
    title: 'Shopping',
    leading: Icon(AppIcons.category),
    group: _expense,
  ),
  PickerItem(
    id: 'salary',
    title: 'Salary',
    leading: Icon(AppIcons.category),
    group: _income,
  ),
  PickerItem(
    id: 'freelance',
    title: 'Side hustle',
    leading: Icon(AppIcons.category),
    group: _income,
  ),
  PickerItem(
    id: 'design',
    title: 'Design jobs',
    leading: Icon(AppIcons.category),
    parentId: 'freelance',
    group: _income,
  ),
];

const _groups = [
  PickerGroup(_expense, 'Expense'),
  PickerGroup(_income, 'Income'),
];

final _typeTabs = [
  PickerFilter('All', (_) => true),
  PickerFilter('Expense', (i) => i.group == _expense),
  PickerFilter('Income', (i) => i.group == _income),
];

const _wallets = [
  PickerItem(
    id: 'cash',
    title: 'Cash',
    subtitle: '฿1,200',
    leading: Icon(AppIcons.wallet),
  ),
  PickerItem(
    id: 'kbank',
    title: 'KBank',
    subtitle: '฿18,250',
    leading: Icon(AppIcons.wallet),
  ),
  PickerItem(
    id: 'card',
    title: 'Credit card',
    subtitle: '−฿3,400',
    leading: Icon(AppIcons.wallet),
  ),
];

const _tags = [
  PickerItem(id: 'work', title: 'work', icon: AppIcons.tag),
  PickerItem(id: 'trip', title: 'trip', icon: AppIcons.tag),
  PickerItem(id: 'family', title: 'family', icon: AppIcons.tag),
];

const _people = [
  PickerItem(
    id: 'lee',
    title: 'Lee',
    subtitle: 'linked',
    leading: Icon(AppIcons.contact),
    keywords: ['lee@example.com'],
  ),
  PickerItem(id: 'aom', title: 'Aom', leading: Icon(AppIcons.contact)),
  PickerItem(
    id: 'boss',
    title: 'Boss',
    subtitle: 'from a split',
    leading: Icon(AppIcons.contact),
  ),
];

String _ok(int n) => n == 0 ? 'OK' : 'OK ($n)';

class _ItemPickerPage extends StatefulWidget {
  const _ItemPickerPage();

  @override
  State<_ItemPickerPage> createState() => _ItemPickerPageState();
}

class _ItemPickerPageState extends State<_ItemPickerPage> {
  String _result = 'nothing picked yet';
  bool _failedOnce = false;

  Future<void> _open(ItemPickerSheet sheet) async {
    final r = await showItemPicker(context, sheet);
    if (!mounted) return;
    setState(
      () => _result = r == null
          ? 'closed'
          : [
              if (r.ids.isNotEmpty) 'ids: ${r.ids.join(', ')}',
              if (r.withChildren.isNotEmpty)
                'with sub-items: ${r.withChildren.join(', ')}',
              if (r.none) 'none',
              if (r.text != null) 'text: ${r.text}',
              if (r.action != null) 'action: ${r.action}',
            ].join(' | '),
    );
  }

  Widget _button(String label, ItemPickerSheet sheet) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () => _open(sheet),
  );

  @override
  Widget build(BuildContext context) {
    Widget demo(String title, String note, List<Widget> buttons) => HubDemo(
      title: title,
      note: note,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: buttons,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(title: 'Last answer', child: AppText(_result)),
        demo(
          'Rows, single',
          'Tap = pick and close. A tree (expand ▾), a "none" row, a create '
              'row, type tabs and group headings; the picked row is '
              'highlighted and scrolled to.',
          [
            _button(
              'Category (both types)',
              ItemPickerSheet(
                title: 'Choose category',
                items: _categories,
                groups: _groups,
                filters: _typeTabs,
                selected: const {'taxi'},
                none: const PickerNone(
                  label: 'No category',
                  icon: AppIcons.noCategory,
                ),
                create: PickerCreate(
                  label: (_) => 'Add category',
                  onCreate: (_) async => 'new-category',
                ),
                searchable: true,
                emptyText: 'No categories yet',
                noMatchText: 'No match',
              ),
            ),
            _button(
              'Grouped + actions',
              ItemPickerSheet(
                title: 'Link to recurring',
                items: const [
                  PickerItem(
                    id: 'netflix',
                    title: 'Netflix',
                    trailing: AppText('฿419'),
                    group: 'due',
                  ),
                  PickerItem(
                    id: 'rent',
                    title: 'Rent',
                    trailing: AppText('฿8,000'),
                    group: 'later',
                  ),
                ],
                groups: const [
                  PickerGroup('due', 'Due now'),
                  PickerGroup('later', 'Later'),
                ],
                actions: const [
                  PickerAction(
                    id: 'new',
                    label: 'New recurring',
                    icon: AppIcons.add,
                    pinned: true,
                  ),
                  PickerAction(
                    id: 'unlink',
                    label: 'Unlink',
                    icon: AppIcons.delete,
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        demo(
          'Rows, multi + sub-items',
          'Ticks and a confirm with the count. toggle = a ticked parent shows '
              'a box to take in its sub-items (budget). always = a ticked '
              'parent always takes them in; unticking one drops the parent '
              '(tx filter). separate = every row on its own.',
          [
            for (final mode in PickerChildren.values)
              _button(
                'Categories · ${mode.name}',
                ItemPickerSheet(
                  title: 'Choose categories',
                  items: _categories,
                  groups: _groups,
                  filters: _typeTabs,
                  multi: true,
                  children: mode,
                  includeChildrenLabel: 'Include sub-categories',
                  selectedWithChildren: const {'food'},
                  none: mode == PickerChildren.always
                      ? const PickerNone(
                          label: 'No category',
                          icon: AppIcons.noCategory,
                        )
                      : null,
                  confirmLabel: _ok,
                ),
              ),
          ],
        ),
        demo(
          'Cards',
          'A grid of cards (wallets, saving goals); the chosen one has a '
              'solid edge, the others dashed.',
          [
            _button(
              'Wallet, single',
              ItemPickerSheet(
                title: 'Choose wallet',
                items: _wallets,
                layout: PickerLayout.cards,
                selected: const {'kbank'},
                none: const PickerNone(label: 'No wallet'),
                create: PickerCreate(
                  label: (_) => 'New wallet',
                  onCreate: (_) async => null,
                ),
              ),
            ),
            _button(
              'Wallets, multi',
              ItemPickerSheet(
                title: 'Wallets',
                items: _wallets,
                layout: PickerLayout.cards,
                multi: true,
                none: const PickerNone(label: 'No wallet'),
                confirmLabel: _ok,
              ),
            ),
          ],
        ),
        demo(
          'Chips',
          'Tags: chips in a wrap; typing a name that does not exist offers to '
              'create it, and a multi picker ticks the new one.',
          [
            _button(
              'Tags',
              ItemPickerSheet(
                title: 'Tags',
                items: _tags,
                layout: PickerLayout.chips,
                multi: true,
                selected: const {'trip'},
                create: PickerCreate(
                  label: (typed) =>
                      typed.isEmpty ? 'New tag' : 'Create "$typed"',
                  onCreate: (typed) async => typed.isEmpty ? null : typed,
                  fromSearch: true,
                ),
                confirmLabel: _ok,
              ),
            ),
          ],
        ),
        demo(
          'Typed name + tabs',
          'People: filter tabs on top, search behind 🔍 (it also matches an '
              'email). The last row is a name input: tap it and the row lights '
              'up and Save shows in the footer, only while it has focus. '
              '"Typed before" opens with a name already in it.',
          [
            _button(
              'Person',
              ItemPickerSheet(
                title: 'Who',
                items: _people,
                filters: [
                  PickerFilter('All', (_) => true),
                  PickerFilter('Linked', (i) => i.subtitle == 'linked'),
                ],
                freeText: PickerFreeText(
                  hint: 'New name',
                  saveLabel: (_) => 'Save',
                  leading: (_) => const Icon(AppIcons.contact),
                  maxLength: 20,
                ),
                searchable: true,
                searchHint: 'Name or email',
              ),
            ),
            _button(
              'Typed before',
              ItemPickerSheet(
                title: 'Who',
                items: _people,
                freeText: PickerFreeText(
                  hint: 'New name',
                  saveLabel: (_) => 'Save',
                  leading: (_) => const Icon(AppIcons.contact),
                  initial: 'Noi',
                ),
                searchable: true,
              ),
            ),
            _button(
              'Keep-the-name row',
              ItemPickerSheet(
                title: 'Who',
                items: _people,
                none: const PickerNone(
                  label: 'Keep "Noi"',
                  subtitle: 'The name stays, not linked to anyone',
                  icon: AppIcons.contact,
                  showWhileSearching: true,
                ),
                searchable: true,
              ),
            ),
          ],
        ),
        demo(
          'Loads itself, saves before closing',
          'load = the picker fetches on open (skeleton, error + retry, '
              'pull-to-refresh). onConfirm = the button spins while saving and '
              'the sheet stays open when it fails (here: the first try). '
              'minPicks = 1.',
          [
            _button(
              'Load + save',
              ItemPickerSheet(
                title: 'Mark paid',
                items: const [],
                load: () async {
                  await Future<void>.delayed(const Duration(seconds: 1));
                  return const [
                    PickerItem(
                      id: 'e1',
                      title: 'Dinner',
                      subtitle: '12 Oct',
                      trailing: AppText('฿240'),
                    ),
                    PickerItem(
                      id: 'e2',
                      title: 'Taxi',
                      subtitle: '14 Oct',
                      trailing: AppText('฿120'),
                    ),
                  ];
                },
                multi: true,
                minPicks: 1,
                onConfirm: (_) async {
                  await Future<void>.delayed(const Duration(milliseconds: 800));
                  _failedOnce = !_failedOnce;
                  return !_failedOnce;
                },
                confirmLabel: _ok,
              ),
            ),
            _button(
              'Load fails',
              ItemPickerSheet(
                title: 'Mark paid',
                items: const [],
                load: () async {
                  await Future<void>.delayed(const Duration(seconds: 1));
                  throw 'Could not load';
                },
              ),
            ),
            _button(
              'Suggested name',
              ItemPickerSheet(
                title: 'Event',
                items: const [PickerItem(id: 'trip', title: 'Chiang Mai trip')],
                freeText: PickerFreeText(
                  hint: 'Event name',
                  saveLabel: (typed) => 'Create "$typed"',
                  leading: (_) => const Icon(AppIcons.add),
                  maxLength: 30,
                  initial: 'Dinner · 19 Oct',
                ),
              ),
            ),
          ],
        ),
        demo('States', 'Loading, error and empty, the same for every picker.', [
          _button(
            'Loading',
            const ItemPickerSheet(title: 'Loading', items: [], loading: true),
          ),
          _button(
            'Error',
            const ItemPickerSheet(
              title: 'Error',
              items: [],
              error: 'Could not load',
            ),
          ),
          _button(
            'Empty',
            const ItemPickerSheet(
              title: 'Empty',
              items: [],
              emptyText: 'Nothing here yet',
            ),
          ),
        ]),
      ],
    );
  }
}
