import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../domain/scheduled_enums.dart';
import '../../domain/scheduled_transaction.dart';
import '../cubit/scheduled_transactions_cubit.dart';

/// Three UI variants the user can pick on create. Maps to the
/// (entry_type, interest_rate) pair on save:
/// - recurring → entry_type=recurring
/// - installment → entry_type=installment, interest_rate=null
/// - loan → entry_type=installment, interest_rate>0
enum _FormVariant { recurring, installment, loan }

/// Create / edit a scheduled entry — `/scheduled-transactions/new` and
/// `/scheduled-transactions/:id/edit`.
///
/// Spec quirks:
/// - Variant selector is editable on create only — `entry_type` is locked
///   on PUT (spec §3.5).
/// - Edits affect future cycles only; past generated transactions are
///   preserved (spec §2.5).
class ScheduledTransactionFormPage extends StatefulWidget {
  const ScheduledTransactionFormPage({this.editingId, super.key});

  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<ScheduledTransactionFormPage> createState() =>
      _ScheduledTransactionFormPageState();
}

class _ScheduledTransactionFormPageState
    extends State<ScheduledTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _totalInstallmentsController = TextEditingController();
  final _remainingInstallmentsController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _noteController = TextEditingController();

  ScheduledTransactionType _type = ScheduledTransactionType.expense;
  _FormVariant _variant = _FormVariant.recurring;
  BillingCycle _billingCycle = BillingCycle.monthly;
  String? _accountId;
  String? _categoryId;
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 7));
  IconCode? _iconCode;
  ScheduledTransaction? _initial;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final existing = context
          .read<ScheduledTransactionsCubit>()
          .byId(widget.editingId!);
      if (existing != null) {
        _initial = existing;
        _nameController.text = existing.name;
        _amountController.text = existing.amount.toString();
        _type = existing.type;
        _billingCycle = existing.billingCycle;
        _accountId = existing.accountId;
        _categoryId = existing.categoryId;
        _iconCode = existing.iconCode;
        _noteController.text = existing.note ?? '';
        final parsed = DateTime.tryParse(existing.nextBillingDate);
        if (parsed != null) _nextBillingDate = parsed;
        if (existing.entryType == ScheduledEntryType.installment) {
          _variant = existing.isLoan
              ? _FormVariant.loan
              : _FormVariant.installment;
          _totalAmountController.text =
              existing.totalAmount?.toString() ?? '';
          _downPaymentController.text =
              existing.downPayment?.toString() ?? '';
          _totalInstallmentsController.text =
              existing.totalInstallments?.toString() ?? '';
          _remainingInstallmentsController.text =
              existing.remainingInstallments?.toString() ?? '';
          if (existing.interestRate != null) {
            _interestRateController.text = existing.interestRate!.toString();
          }
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _totalAmountController.dispose();
    _downPaymentController.dispose();
    _totalInstallmentsController.dispose();
    _remainingInstallmentsController.dispose();
    _interestRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isInstallmentVariant =>
      _variant == _FormVariant.installment ||
      _variant == _FormVariant.loan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.isEdit && _initial == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.scheduledFormTitleEdit)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l.scheduledDetailNotFoundMessage,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit
            ? l.scheduledFormTitleEdit
            : l.scheduledFormTitle),
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
            _IconPickerTile(
              iconCode: _iconCode,
              label: l.scheduledFormIconLabel,
              onTap: () => _openIconMaker(context, l),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l.scheduledFormVariantLabel),
            // Variant is the discriminator for entry_type + interest_rate.
            // Locked on edit per spec §3.5.
            SegmentedButton<_FormVariant>(
              segments: [
                ButtonSegment(
                  value: _FormVariant.recurring,
                  label: Text(l.scheduledVariantRecurring),
                ),
                ButtonSegment(
                  value: _FormVariant.installment,
                  label: Text(l.scheduledVariantInstallment),
                ),
                ButtonSegment(
                  value: _FormVariant.loan,
                  label: Text(l.scheduledVariantLoan),
                ),
              ],
              selected: {_variant},
              onSelectionChanged: widget.isEdit
                  ? null
                  : (v) => setState(() => _variant = v.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l.scheduledFormTypeLabel),
            SegmentedButton<ScheduledTransactionType>(
              segments: [
                ButtonSegment(
                  value: ScheduledTransactionType.expense,
                  label: Text(l.scheduledTypeExpense),
                ),
                ButtonSegment(
                  value: ScheduledTransactionType.income,
                  label: Text(l.scheduledTypeIncome),
                ),
              ],
              selected: {_type},
              onSelectionChanged: widget.isEdit
                  ? null
                  : (v) => setState(() {
                        _type = v.first;
                        // Type change invalidates the picked category
                        // since cats are type-scoped.
                        _categoryId = null;
                      }),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l.scheduledFormNameLabel,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.scheduledFormNameRequired
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
                labelText: _isInstallmentVariant
                    ? l.scheduledFormPaymentLabel
                    : l.scheduledFormAmountLabel,
                prefixText: '฿ ',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) {
                  return l.scheduledFormAmountInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _AccountPicker(
              selectedId: _accountId,
              onChanged: (id) => setState(() => _accountId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryPicker(
              selectedId: _categoryId,
              type: _type,
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l.scheduledFormCycleLabel),
            SegmentedButton<BillingCycle>(
              segments: [
                ButtonSegment(
                  value: BillingCycle.weekly,
                  label: Text(l.scheduledCycleWeekly),
                ),
                ButtonSegment(
                  value: BillingCycle.monthly,
                  label: Text(l.scheduledCycleMonthly),
                ),
                ButtonSegment(
                  value: BillingCycle.yearly,
                  label: Text(l.scheduledCycleYearly),
                ),
              ],
              selected: {_billingCycle},
              onSelectionChanged: (v) =>
                  setState(() => _billingCycle = v.first),
            ),
            const SizedBox(height: AppSpacing.md),
            _NextBillingTile(
              date: _nextBillingDate,
              onPick: (d) => setState(() => _nextBillingDate = d),
            ),
            if (_isInstallmentVariant) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(text: l.scheduledFormInstallmentSection),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _totalAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: l.scheduledFormTotalAmountLabel,
                  helperText: _variant == _FormVariant.loan
                      ? l.scheduledFormTotalAmountHelperLoan
                      : l.scheduledFormTotalAmountHelper,
                  helperMaxLines: 2,
                  prefixText: '฿ ',
                ),
                validator: (v) {
                  if (!_isInstallmentVariant) return null;
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) {
                    return l.scheduledFormAmountInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _downPaymentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: l.scheduledFormDownPaymentLabel,
                  prefixText: '฿ ',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalInstallmentsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l.scheduledFormTotalInstallmentsLabel,
                      ),
                      onChanged: (v) {
                        if (!widget.isEdit &&
                            _remainingInstallmentsController.text.isEmpty) {
                          _remainingInstallmentsController.text = v;
                        }
                      },
                      validator: (v) {
                        if (!_isInstallmentVariant) return null;
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return l.scheduledFormInstallmentsInvalid;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _remainingInstallmentsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:
                            l.scheduledFormRemainingInstallmentsLabel,
                      ),
                      validator: (v) {
                        if (!_isInstallmentVariant) return null;
                        final n = int.tryParse(v ?? '');
                        final total = int.tryParse(
                            _totalInstallmentsController.text);
                        if (n == null || n < 0) {
                          return l.scheduledFormInstallmentsInvalid;
                        }
                        if (total != null && n > total) {
                          return l.scheduledFormRemainingExceeds;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_variant == _FormVariant.loan) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _interestRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l.scheduledFormInterestRateLabel,
                    suffixText: '%',
                  ),
                  validator: (v) {
                    if (_variant != _FormVariant.loan) return null;
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 99.99) {
                      return l.scheduledFormInterestInvalid;
                    }
                    return null;
                  },
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.scheduledFormNoteLabel,
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
                ? l.scheduledFormSaveEdit
                : l.scheduledFormSave),
          ),
        ),
      ),
    );
  }

  Future<void> _openIconMaker(BuildContext context, AppLocalizations l) async {
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: _iconCode,
      iconSectionLabel: l.scheduledFormIconLabel,
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      setState(() => _iconCode = result.iconCode);
    } else if (result is IconMakerRemoved) {
      setState(() => _iconCode = null);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(l.scheduledFormAccountRequired)));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(l.scheduledFormCategoryRequired)));
      return;
    }
    final cubit = context.read<ScheduledTransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final amount = double.parse(_amountController.text.trim());
    final entryType = _isInstallmentVariant
        ? ScheduledEntryType.installment
        : ScheduledEntryType.recurring;
    final totalAmount = _isInstallmentVariant
        ? double.tryParse(_totalAmountController.text.trim())
        : null;
    final downPayment = _isInstallmentVariant
        ? double.tryParse(_downPaymentController.text.trim()) ?? 0
        : null;
    final totalInstallments = _isInstallmentVariant
        ? int.tryParse(_totalInstallmentsController.text.trim())
        : null;
    final remainingInstallments = _isInstallmentVariant
        ? int.tryParse(_remainingInstallmentsController.text.trim())
        : null;
    final interestRate = _variant == _FormVariant.loan
        ? double.tryParse(_interestRateController.text.trim())
        : null;
    final note = _noteController.text.trim();

    final draft = ScheduledTransaction(
      id: _initial?.id ?? 'draft',
      name: _nameController.text.trim(),
      type: _type,
      entryType: entryType,
      amount: amount,
      accountId: _accountId!,
      categoryId: _categoryId,
      billingCycle: _billingCycle,
      nextBillingDate: _isoDate(_nextBillingDate),
      status: _initial?.status ?? ScheduledStatus.active,
      note: note.isEmpty ? null : note,
      iconCode: _iconCode,
      totalAmount: totalAmount,
      downPayment: downPayment,
      totalInstallments: totalInstallments,
      remainingInstallments: remainingInstallments,
      interestRate: interestRate,
    );

    try {
      if (widget.isEdit) {
        await cubit.update(draft);
      } else {
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

  String _isoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _IconPickerTile extends StatelessWidget {
  const _IconPickerTile({
    required this.iconCode,
    required this.label,
    required this.onTap,
  });

  final IconCode? iconCode;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            IconDisplay(
              type: IconType.category,
              size: 48,
              iconCode: iconCode,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.selectedId, required this.onChanged});

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.scheduledFormAccountLabel,
          ),
          onChanged: onChanged,
          items: [
            for (final Account a in state.accounts)
              DropdownMenuItem<String>(
                value: a.id,
                child: Text(a.name),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selectedId,
    required this.type,
    required this.onChanged,
  });

  final String? selectedId;
  final ScheduledTransactionType type;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        // Spec §4.12: category type must match transaction type;
        // system categories not allowed.
        final wanted = type == ScheduledTransactionType.expense
            ? CategoryType.expense
            : CategoryType.income;
        final categories = state.categories
            .where((Category c) => c.type == wanted && !c.isSystem)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        // The dropdown's `initialValue` must reference an item in the
        // current list; if the user flips type and the previously chosen
        // category becomes invalid, fall back to null.
        final inList = categories.any((c) => c.id == selectedId);
        return DropdownButtonFormField<String>(
          initialValue: inList ? selectedId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.scheduledFormCategoryLabel,
          ),
          onChanged: onChanged,
          items: [
            for (final c in categories)
              DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name),
              ),
          ],
        );
      },
    );
  }
}

class _NextBillingTile extends StatelessWidget {
  const _NextBillingTile({required this.date, required this.onPick});

  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 20),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.scheduledFormNextBillingLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    _format(date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
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
