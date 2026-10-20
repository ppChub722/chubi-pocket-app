import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/categories/domain/category_type.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/categories/presentation/widgets/category_picker.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import 'entity_pickers/account_picker_demos.dart';
import 'entity_pickers/bank_picker_demos.dart';
import 'entity_pickers/contact_picker_demos.dart';
import 'entity_pickers/debt_entry_picker_demos.dart';
import 'entity_pickers/event_picker_demos.dart';
import 'entity_pickers/member_picker_demos.dart';
import 'entity_pickers/recurring_picker_demos.dart';
import 'entity_pickers/saving_goal_picker_demos.dart';
import 'entity_pickers/tag_picker_demos.dart';

/// `/dev/ui/domain/entity-pickers` — each entity picker as the pages open it,
/// on the real caches.
Widget buildEntityPickersPage(BuildContext context) =>
    const _EntityPickersPage();

class _EntityPickersPage extends StatefulWidget {
  const _EntityPickersPage();

  @override
  State<_EntityPickersPage> createState() => _EntityPickersPageState();
}

enum _Entity {
  category('Category'),
  wallet('Wallet'),
  bank('Bank'),
  contact('Contact'),
  tag('Tag'),
  event('Event'),
  recurring('Recurring'),
  savingGoal('Saving goal'),
  debtEntry('Debt entries'),
  member('Event member');

  const _Entity(this.label);
  final String label;
}

class _EntityPickersPageState extends State<_EntityPickersPage> {
  String _result = 'nothing picked yet';
  _Entity _entity = _Entity.category;

  void _say(String v) {
    if (mounted) setState(() => _result = v);
  }

  String _one(CategoryPick? r) => switch (r) {
    null => 'closed',
    CategoryPickedNone() => 'none',
    CategoryPicked(:final category) => category.name,
  };

  String _many(CategoryPicks? r) => r == null
      ? 'closed'
      : [
          if (r.none) 'none',
          for (final c in r.categories)
            r.withChildren.contains(c.id) ? '${c.name} (+subs)' : c.name,
        ].join(', ');

  Widget _button(String label, Future<String> Function() run) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async => _say(await run()),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(title: 'Last answer', child: AppText(_result)),
        HubDemo(
          title: 'Entity',
          note: 'Each picker in the setups the pages use, on the real caches.',
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final e in _Entity.values)
                AppChip(
                  label: e.label,
                  selected: e == _entity,
                  dashed: e != _entity,
                  onTap: () => setState(() => _entity = e),
                ),
            ],
          ),
        ),
        ...switch (_entity) {
          _Entity.category => _categoryDemos(context),
          _Entity.wallet => [AccountPickerDemos(onResult: _say)],
          _Entity.bank => [BankPickerDemos(onResult: _say)],
          _Entity.contact => [ContactPickerDemos(onResult: _say)],
          _Entity.tag => [TagPickerDemos(onResult: _say)],
          _Entity.event => [EventPickerDemos(onResult: _say)],
          _Entity.recurring => [RecurringPickerDemos(onResult: _say)],
          _Entity.savingGoal => [SavingGoalPickerDemos(onResult: _say)],
          _Entity.debtEntry => [DebtEntryPickerDemos(onResult: _say)],
          _Entity.member => [MemberPickerDemos(onResult: _say)],
        },
      ],
    );
  }

  List<Widget> _categoryDemos(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final all = context.watch<CategoriesCubit>().state.categories;
    final expense = [
      for (final c in all)
        if (c.type == CategoryType.expense && !c.isSystem) c,
    ];
    final someExpense = expense.where((c) => c.parentId != null).firstOrNull;

    Widget demo(String title, String note, List<Widget> buttons) => HubDemo(
      title: title,
      note: note,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: buttons,
      ),
    );

    return [
      demo(
        'CategoryPicker.one — quick create / transaction detail',
        'One type (the transaction\'s), "ไม่ระบุหมวด", add a category. The '
            'picked one is highlighted and scrolled to.',
        [
          _button(
            'New',
            () async => _one(
              await CategoryPicker.one(
                context,
                types: const {CategoryType.expense},
                selectedId: someExpense?.id,
                allowNone: true,
                allowCreate: true,
              ),
            ),
          ),
        ],
      ),
      demo(
        'CategoryPicker.one — both types',
        'Tabs ทั้งหมด / รายจ่าย / รายรับ and a heading per type; one tab '
            'leaves one group, so its heading goes.',
        [
          _button(
            'Both, start on all',
            () async => _one(await CategoryPicker.one(context)),
          ),
          _button(
            'Both, start on income',
            () async => _one(
              await CategoryPicker.one(
                context,
                initialType: CategoryType.income,
              ),
            ),
          ),
        ],
      ),
      demo(
        'CategoryPicker.one — parent of a category / resolve',
        'Parent: top level only, "ไม่มี" as the none row, its own title. '
            'Resolve: "ไม่ระบุหมวด".',
        [
          _button(
            'Parent',
            () async => _one(
              await CategoryPicker.one(
                context,
                types: const {CategoryType.expense},
                allowNone: true,
                noneLabel: l.categoryFormParentNone,
                title: l.categoryFormParentLabel,
                maxDepth: 0,
              ),
            ),
          ),
          _button(
            'Resolve',
            () async => _one(
              await CategoryPicker.one(
                context,
                types: const {CategoryType.expense},
                allowNone: true,
                noneLabel: l.projectResolveCategoryNone,
              ),
            ),
          ),
        ],
      ),
      demo(
        'CategoryPicker.many — budget',
        'Expense only; a ticked parent shows "รวมหมวดย่อย".',
        [
          _button(
            'New',
            () async => _many(
              await CategoryPicker.many(
                context,
                types: const {CategoryType.expense},
                children: PickerChildren.toggle,
              ),
            ),
          ),
        ],
      ),
      demo(
        'CategoryPicker.many — transaction filter',
        'Both types with tabs, starting on the type the filter has; a '
            'ticked parent always takes in its sub-categories (the server '
            'does too); "ไม่ระบุหมวด" is a tick of its own.',
        [
          _button(
            'Filter, all types',
            () async => _many(
              await CategoryPicker.many(
                context,
                children: PickerChildren.always,
                allowNone: true,
              ),
            ),
          ),
          _button(
            'Filter on expense',
            () async => _many(
              await CategoryPicker.many(
                context,
                initialType: CategoryType.expense,
                children: PickerChildren.always,
                allowNone: true,
              ),
            ),
          ),
        ],
      ),
      if (all.isEmpty)
        const HubDemo(
          title: 'No categories',
          child: AppText('The categories cache is empty: sign in first.'),
        ),
    ];
  }
}
