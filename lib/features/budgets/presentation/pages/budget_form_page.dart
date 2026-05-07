import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../transactions/presentation/widgets/category_picker_sheet.dart';
import '../../domain/budget.dart';
import '../../domain/budget_period.dart';
import '../../domain/budget_scope.dart';
import '../../domain/budget_status.dart';
import '../cubit/budgets_cubit.dart';

/// Create / edit a user-scope budget — `/budgets/new` and
/// `/budgets/:id/edit`.
///
/// Project-scope budget creation is reached from the project detail page
/// (Phase 1c), not here, so this form is hard-coded to user-scope.
///
/// Spec quirks:
/// - Only **expense** categories are pickable (income / system rejected).
/// - `category_id`, `scope`, `project_id` are NOT editable on PUT
///   (spec §3.4) — the category picker is disabled in edit mode.
/// - Budget icon comes from the linked category (migration 000037 dropped
///   the per-budget icon_code), so the form has no icon picker — picking
///   the category sets the icon implicitly.
/// - `description`, when set, is the budget's primary label everywhere
///   (list card, detail header, AppBar title).
class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({this.editingId, super.key});

  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  String? _categoryId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  Budget? _initial;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final existing = context.read<BudgetsCubit>().byId(widget.editingId!);
      if (existing != null) {
        _initial = existing;
        _amountController.text = existing.amount.toString();
        _descriptionController.text = existing.description ?? '';
        _noteController.text = existing.note ?? '';
        _categoryId = existing.categoryId;
        _period = existing.period;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.isEdit && _initial == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.budgetFormTitleEdit)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l.budgetDetailNotFoundMessage,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? l.budgetFormTitleEdit : l.budgetFormTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          children: [
            _CategoryTile(
              selectedId: _categoryId,
              enabled: !widget.isEdit,
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l.budgetFormDescriptionLabel,
                helperText: l.budgetFormDescriptionHelper,
                helperMaxLines: 2,
              ),
              validator: (v) => (v != null && v.length > 200)
                  ? l.budgetFormDescriptionTooLong
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: l.budgetFormAmountLabel,
                prefixText: '฿ ',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return l.budgetFormAmountInvalid;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l.budgetFormPeriodLabel),
            SegmentedButton<BudgetPeriod>(
              segments: [
                ButtonSegment(
                  value: BudgetPeriod.weekly,
                  label: Text(l.budgetPeriodWeekly),
                ),
                ButtonSegment(
                  value: BudgetPeriod.monthly,
                  label: Text(l.budgetPeriodMonthly),
                ),
                ButtonSegment(
                  value: BudgetPeriod.yearly,
                  label: Text(l.budgetPeriodYearly),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.budgetFormNoteLabel,
                helperText: l.budgetFormNoteHelper,
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(widget.isEdit
                ? l.budgetFormSaveEdit
                : l.budgetFormSave),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.budgetFormCategoryRequired)));
      return;
    }
    final cubit = context.read<BudgetsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final descValue = description.isEmpty ? null : description;
    final note = _noteController.text.trim();
    final noteValue = note.isEmpty ? null : note;

    try {
      if (widget.isEdit) {
        // Construct directly (not via copyWith) so cleared text fields
        // are sent as JSON null, which the BE's `*string` fields treat
        // as an explicit clear.
        final updated = Budget(
          id: _initial!.id,
          categoryId: _initial!.categoryId,
          amount: amount,
          period: _period,
          scope: _initial!.scope,
          currency: _initial!.currency,
          status: _initial!.status,
          projectId: _initial!.projectId,
          description: descValue,
          note: noteValue,
          category: _initial!.category,
        );
        await cubit.update(updated);
      } else {
        final draft = Budget(
          id: 'draft',
          categoryId: _categoryId!,
          amount: amount,
          period: _period,
          scope: BudgetScope.user,
          currency: 'THB',
          status: BudgetStatus.active,
          description: descValue,
          note: noteValue,
        );
        await cubit.add(draft);
      }
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    context.pop();
  }
}

/// Tap-to-open category tile. Renders the picked category's icon + name
/// (or a placeholder when nothing is selected). Uses the shared
/// [showCategoryPickerSheet] from the transactions module so the budget
/// form gets the same hierarchical, indented picker users already know.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        Category? selected;
        for (final c in state.categories) {
          if (c.id == selectedId) {
            selected = c;
            break;
          }
        }
        final placeholder = scheme.onSurfaceVariant;
        final disabledTint =
            enabled ? scheme.onSurface : scheme.onSurfaceVariant;
        return InkWell(
          onTap: enabled ? () => _open(context, state.categories) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (selected != null)
                  IconDisplay(
                    type: IconType.category,
                    size: 44,
                    iconCode: selected.iconCode,
                  )
                else
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.surfaceContainerHigh,
                    child: Icon(Icons.category_outlined, color: placeholder),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.budgetFormCategoryLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: placeholder,
                            ),
                      ),
                      Text(
                        selected?.name ?? l.budgetFormCategoryPlaceholder,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: selected != null
                                  ? disabledTint
                                  : placeholder,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled
                            ? l.budgetFormCategoryHelper
                            : l.budgetFormCategoryLockedHelper,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: placeholder,
                            ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.chevron_right, color: placeholder),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, List<Category> categories) async {
    Category? current;
    for (final c in categories) {
      if (c.id == selectedId) {
        current = c;
        break;
      }
    }
    final result = await showCategoryPickerSheet(
      context: context,
      categories: categories,
      type: CategoryType.expense,
      selected: current,
      allowNone: false,
    );
    if (result is CategoryPickerSelected) {
      onChanged(result.category.id);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
