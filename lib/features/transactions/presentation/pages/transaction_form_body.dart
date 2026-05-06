import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../widgets/account_picker_sheet.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/splits_section.dart';
import '../../../../shared/icon_maker/icon_registry.dart';

/// Initial values for [TransactionFormBody], used when editing or when
/// the caller wants to pre-fill specific fields (e.g. tap an account
/// row → open Add transaction with that account pre-selected).
class TransactionFormInitial {
  const TransactionFormInitial({
    this.editingTransaction,
    this.preferredAccount,
    this.type,
  });

  /// Non-null when the form is opened for edit. Pre-fills every field.
  final Transaction? editingTransaction;

  /// Pre-selects this account on a fresh form (no-op when editing).
  final Account? preferredAccount;

  /// Pre-selects the type tab on a fresh form (no-op when editing).
  final TransactionType? type;
}

/// The actual form fields. Embedded in [TransactionFormPage] (full
/// page, with Save & add another) and [showTransactionFormSheet] (modal
/// quick-add, no Save & add another, note collapsible).
///
/// `allowSaveAndAddAnother` toggles the second action button + the
/// `popOnSave` behavior of the parent. For the modal, the parent wraps
/// this body in a draggable sheet and pops on save.
class TransactionFormBody extends StatefulWidget {
  const TransactionFormBody({
    required this.allowSaveAndAddAnother,
    required this.collapsibleNote,
    required this.onSaved,
    required this.initial,
    super.key,
  });

  /// Show the "Save & add another" button next to "Save".
  final bool allowSaveAndAddAnother;

  /// True for modal (note hidden behind "+ Add note" expand); false
  /// for page (note always visible).
  final bool collapsibleNote;

  /// Called after a successful save. The parent decides whether to pop
  /// the route / sheet, show a snackbar, etc. — the body itself doesn't
  /// know its presentation context.
  ///
  /// `addedAnother == true` when the user clicked "Save & add another"
  /// — the parent should keep the form open and the body resets fields
  /// internally.
  final void Function({required bool addedAnother}) onSaved;

  final TransactionFormInitial initial;

  @override
  State<TransactionFormBody> createState() => TransactionFormBodyState();
}

class TransactionFormBodyState extends State<TransactionFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  Account? _account;
  Account? _toAccount; // transfer destination
  Category? _category;
  late DateTime _date;
  bool _showNote = false;
  bool _saving = false;

  /// Currently-selected tag ids. Mutated only via [_toggleTag] and the
  /// initial hydration; the chip row reads from this set to highlight.
  final Set<String> _selectedTagIds = <String>{};

  /// Draft splits for create-mode only. Splits are not editable post-create
  /// per spec §06.3.1 (PUT replaces all; deferred). The form skips the
  /// section entirely on edit + on transfers.
  List<SplitDraft> _splits = const [];

  bool get _isTransfer => _type == TransactionType.transfer;
  bool get _isEdit => widget.initial.editingTransaction != null;
  bool get _showSplits =>
      !_isEdit && !_isTransfer && _type == TransactionType.expense;

  @override
  void initState() {
    super.initState();
    final i = widget.initial.editingTransaction;
    if (i != null) {
      _type = i.type;
      _amountController.text = _formatAmountInput(i.amount);
      _noteController.text = i.note ?? '';
      _date = DateTime.tryParse(i.date) ?? DateTime.now();
      _showNote = i.note != null && i.note!.isNotEmpty;
      _selectedTagIds.addAll(i.tags.map((t) => t.id));
    } else {
      _type = widget.initial.type ?? TransactionType.expense;
      _date = DateTime.now();
      _showNote = !widget.collapsibleNote;
    }

    // Resolve initial account / category once dependencies (cubits) are
    // available — addPostFrameCallback avoids reading providers during
    // initState. Also warm the tags cache for the chip row.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hydrateFromCubits();
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Pulls the account + category objects out of the cubit caches. For
  /// edit mode the ids come from the editingTransaction; for create mode
  /// the account defaults to `preferredAccount` or the user's first
  /// active account.
  void _hydrateFromCubits() {
    final accountsState = context.read<AccountsCubit>().state;
    final categoriesState = context.read<CategoriesCubit>().state;

    final i = widget.initial.editingTransaction;
    if (i != null) {
      // Edit: resolve refs by id.
      Account? findAccount(String id) {
        for (final a in accountsState.accounts) {
          if (a.id == id) return a;
        }
        return null;
      }

      Category? findCategory(String? id) {
        if (id == null) return null;
        for (final c in categoriesState.categories) {
          if (c.id == id) return c;
        }
        return null;
      }

      setState(() {
        _account = findAccount(i.accountId);
        _category = findCategory(i.categoryId);
        // Transfer to-account: identified via the paired row sharing
        // the transfer_group_id. We don't know which row the user
        // clicked into; if this row is the OUT side, the IN side's
        // account is the "to". For simplicity in 1a we surface it as
        // read-only on the form, computed best-effort.
        if (i.transferGroupId != null) {
          final txState = context.read<TransactionsCubit>().state;
          for (final t in txState.transactions) {
            if (t.id != i.id && t.transferGroupId == i.transferGroupId) {
              _toAccount = findAccount(t.accountId);
              break;
            }
          }
        }
      });
      return;
    }

    // Create: pre-select preferredAccount, else first active.
    final preferred = widget.initial.preferredAccount;
    setState(() {
      _account = preferred ??
          (accountsState.accounts.isNotEmpty
              ? accountsState.accounts.first
              : null);
    });
  }

  // ── Public API for parents to drive Save / Save & add another ─────

  /// Validates + saves. Returns true on success, false on validation
  /// failure or API error (snackbar already shown by the body).
  Future<bool> save({required bool keepOpen}) async {
    if (_saving) return false;
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    if (_account == null) return false;
    if (_isTransfer && _toAccount == null) return false;
    if (_isTransfer && _account!.id == _toAccount!.id) return false;
    // Category required for expense/income (BE rejects with
    // VALIDATION_ERROR otherwise — mirror the rule client-side so the
    // user gets a fast feedback loop instead of a snackbar round-trip).
    if (!_isTransfer && _category == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Please pick a category'),
        ));
      return false;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return false;

    final noteRaw = _noteController.text.trim();
    final note = noteRaw.isEmpty ? null : noteRaw;
    final dateStr = _formatDate(_date);

    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      final TransactionMutationResult result;
      if (_isEdit) {
        // Edit: only amount / date / note (and category for non-transfer).
        // Category clear semantics: an explicit-null is sent only when
        // the form previously had a category and the user cleared it.
        final initial = widget.initial.editingTransaction!;
        final clearCategory = !_isTransfer &&
            initial.categoryId != null &&
            _category == null;
        result = await txCubit.updateTransaction(
          id: initial.id,
          amount: amount,
          date: dateStr,
          categoryId: _isTransfer ? null : _category?.id,
          clearCategory: clearCategory,
          note: note,
          clearNote: note == null && initial.note != null,
        );
        // Reconcile tags after the row update succeeds. For transfers
        // the OUT row is the canonical "tagged" side (see [add]).
        final tagTargetId = result.transfer != null
            ? result.transfer!.rows
                .firstWhere(
                  (r) => r.signedAmount < 0,
                  orElse: () => result.transfer!.rows.first,
                )
                .id
            : initial.id;
        await txCubit.setTags(
          transactionId: tagTargetId,
          tagIds: _selectedTagIds.toList(),
        );
      } else {
        // Filter splits: only complete rows are sent. The BE rejects the
        // whole transaction if any row is invalid, so silently dropping
        // half-typed rows is the friendlier behaviour.
        List<Map<String, dynamic>>? splitsPayload;
        if (_showSplits && _splits.any((d) => d.isComplete)) {
          final total = _splits
              .where((d) => d.isComplete)
              .fold<double>(0, (a, d) => a + (d.owedAmount ?? 0));
          if (total > amount + 0.005) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(
                'Splits exceed transaction amount.',
              )));
            return false;
          }
          splitsPayload =
              _splits.where((d) => d.isComplete).map((d) => d.toJson()).toList();
        }
        result = await txCubit.add(
          type: _type,
          accountId: _account!.id,
          amount: amount,
          date: dateStr,
          categoryId: _isTransfer ? null : _category?.id,
          note: note,
          transferToAccountId:
              _isTransfer ? _toAccount!.id : null,
          tagIds: _selectedTagIds.toList(),
          splits: splitsPayload,
        );
      }

      // Surgical balance update on AccountsCubit. The BE returns
      // `account_balance_after` on create, but not on update; for edit
      // we always do a `accountsCubit.load()` since the math is more
      // involved (could affect 1 or 2 accounts depending on transfer).
      if (_isEdit) {
        await accountsCubit.load();
      } else if (result.single?.accountBalanceAfter != null) {
        // Single-row create — patch one account.
        accountsCubit.patchBalance(
          accountId: result.single!.accountId,
          newBalance: result.single!.accountBalanceAfter!,
        );
      } else if (result.transfer != null) {
        // Transfer create — BE doesn't return per-row balance_after,
        // so refresh both affected accounts.
        await accountsCubit.load();
      }

      if (!mounted) return true;
      if (keepOpen) {
        _resetForNextEntry();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .transactionFormSavedAddedAnother),
            duration: const Duration(seconds: 2),
          ));
      }
      widget.onSaved(addedAnother: keepOpen);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForNextEntry() {
    setState(() {
      _amountController.text = '';
      _noteController.text = '';
      _category = null;
      _date = DateTime.now();
      _showNote = !widget.collapsibleNote;
      _splits = const [];
      // Keep _type and _account — the user's likely entering similar
      // transactions in a row (e.g. several lunch expenses).
    });
  }

  /// True when the form has user-entered content that would be lost on
  /// dismissal. Used by the parent's PopScope.
  bool get isDirty {
    if (_isEdit) {
      final i = widget.initial.editingTransaction!;
      if (_amountController.text.trim() != _formatAmountInput(i.amount)) {
        return true;
      }
      if (_noteController.text.trim() != (i.note ?? '')) return true;
      if (_formatDate(_date) != i.date) return true;
      if (!_isTransfer && _category?.id != i.categoryId) return true;
      return false;
    }
    return _amountController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        _category != null ||
        _splits.isNotEmpty;
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isEdit) _TypeTabs(
            selected: _type,
            onChanged: (t) => setState(() {
              _type = t;
              // Clear category when switching to/from transfer or
              // between expense/income (category type must match).
              _category = null;
              if (t != TransactionType.transfer) {
                _toAccount = null;
              }
            }),
          ),
          if (_isEdit) _ReadOnlyTypeChip(type: _type),
          const SizedBox(height: AppSpacing.md),
          _AmountField(
            controller: _amountController,
            currency: _account?.currency ?? 'THB',
            saving: _saving,
            label: l.transactionFormAmountLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _AccountTile(
            label: _isTransfer
                ? l.transactionFormFromAccountLabel
                : l.transactionFormAccountLabel,
            account: _account,
            readOnly: _isEdit,
            onTap: _isEdit ? null : _pickAccount,
          ),
          if (_isTransfer) ...[
            const SizedBox(height: AppSpacing.sm),
            _AccountTile(
              label: l.transactionFormToAccountLabel,
              account: _toAccount,
              readOnly: _isEdit,
              onTap: _isEdit ? null : _pickToAccount,
            ),
            if (_isEdit) Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l.transactionDetailTransferReadonlyHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
          if (!_isTransfer) ...[
            const SizedBox(height: AppSpacing.md),
            _CategoryTile(
              category: _category,
              onTap: _pickCategory,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            _TransferCategoryHint(),
          ],
          const SizedBox(height: AppSpacing.md),
          _DateTile(
            date: _date,
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.collapsibleNote && !_showNote)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.transactionFormNoteAddLabel),
                onPressed: () => setState(() => _showNote = true),
              ),
            )
          else
            TextFormField(
              controller: _noteController,
              maxLength: 500,
              maxLines: widget.collapsibleNote ? 2 : 3,
              decoration: InputDecoration(
                labelText: l.transactionFormNoteLabel,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _TagChipsRow(
            selectedIds: _selectedTagIds,
            onToggle: _toggleTag,
          ),
          if (_showSplits) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            SplitsSection(
              totalAmount:
                  double.tryParse(_amountController.text.trim()) ?? 0,
              drafts: _splits,
              onChanged: (next) => setState(() => _splits = next),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleTag(String id) {
    setState(() {
      if (_selectedTagIds.contains(id)) {
        _selectedTagIds.remove(id);
      } else {
        _selectedTagIds.add(id);
      }
    });
  }

  // ── Picker handlers ───────────────────────────────────────────────

  Future<void> _pickAccount() async {
    final state = context.read<AccountsCubit>().state;
    final picked = await showAccountPickerSheet(
      context: context,
      accounts: state.accounts,
      selected: _account,
    );
    if (picked != null && mounted) setState(() => _account = picked);
  }

  Future<void> _pickToAccount() async {
    final state = context.read<AccountsCubit>().state;
    final picked = await showAccountPickerSheet(
      context: context,
      accounts: state.accounts,
      selected: _toAccount,
      excludeId: _account?.id,
      title: AppLocalizations.of(context)!.transactionFormToAccountLabel,
    );
    if (picked != null && mounted) setState(() => _toAccount = picked);
  }

  Future<void> _pickCategory() async {
    final state = context.read<CategoriesCubit>().state;
    final categoryType = _type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final result = await showCategoryPickerSheet(
      context: context,
      categories: state.categories,
      type: categoryType,
      selected: _category,
    );
    if (!mounted || result == null) return;
    setState(() {
      _category = result is CategoryPickerSelected ? result.category : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }
}

// ── Field widgets ────────────────────────────────────────────────────

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selected, required this.onChanged});

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<TransactionType>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
      segments: [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text(l.transactionTypeExpense),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text(l.transactionTypeIncome),
        ),
        ButtonSegment(
          value: TransactionType.transfer,
          label: Text(l.transactionTypeTransfer),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ReadOnlyTypeChip extends StatelessWidget {
  const _ReadOnlyTypeChip({required this.type});
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = switch (type) {
      TransactionType.expense => l.transactionTypeExpense,
      TransactionType.income => l.transactionTypeIncome,
      TransactionType.transfer => l.transactionTypeTransfer,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        avatar: Icon(_typeIcon(type), size: 18),
      ),
    );
  }

  IconData _typeIcon(TransactionType t) {
    return switch (t) {
      TransactionType.expense => Icons.south,
      TransactionType.income => Icons.north,
      TransactionType.transfer => Icons.swap_horiz,
    };
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.saving,
    required this.label,
  });

  final TextEditingController controller;
  final String currency;
  final bool saving;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      enabled: !saving,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: _currencyPrefix(currency),
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return l.transactionFormAmountRequired;
        final n = double.tryParse(t);
        if (n == null) return l.transactionFormAmountInvalid;
        if (n <= 0) return l.transactionFormAmountTooSmall;
        return null;
      },
    );
  }

  String _currencyPrefix(String c) {
    // Phase 1 is THB only; the prefix is purely cosmetic.
    if (c == 'THB') return '฿ ';
    return '$c ';
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.label,
    required this.account,
    required this.readOnly,
    required this.onTap,
  });

  final String label;
  final Account? account;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (account != null)
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      account!.iconCode?.bgColorFor(palette) ?? scheme.outline,
                  child: Icon(IconRegistry.get(account!.iconCode?.icon, fallback: Icons.account_balance_wallet_outlined), color: Colors.white, size: 14),
                )
              else
                Icon(Icons.account_balance_wallet_outlined,
                    color: scheme.onSurfaceVariant, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                    Text(
                      account?.name ?? l.transactionFormAccountRequired,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              if (account != null)
                Text(
                  CurrencyFormatter.format(account!.balance),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              if (!readOnly)
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (category != null)
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      category!.iconCode?.bgColorFor(palette) ?? scheme.outline,
                  child: Icon(IconRegistry.get(category!.iconCode?.icon, fallback: Icons.category_outlined), color: Colors.white, size: 14),
                )
              else
                Icon(Icons.category_outlined,
                    color: scheme.onSurfaceVariant, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.transactionFormCategoryLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                    Text(
                      category?.name ?? l.transactionFormCategoryNone,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferCategoryHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.onSurfaceVariant, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l.transactionFormTransferCategoryHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: scheme.onSurfaceVariant, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.transactionFormDateLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                    Text(
                      _formatDate(date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String _formatAmountInput(double amount) {
  // Prefer integer rendering for whole-baht amounts so the user sees
  // "1500" not "1500.0" when editing — fewer keystrokes to fix.
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toStringAsFixed(2);
}

/// Multi-select chip wrap for tags. Reads the user's tag list from
/// [TagsCubit]; tap a chip to toggle. New users start with no tags;
/// the row shows a hint that links to the tags-management page when
/// the cubit's cache is empty.
class _TagChipsRow extends StatelessWidget {
  const _TagChipsRow({required this.selectedIds, required this.onToggle});

  final Set<String> selectedIds;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return BlocBuilder<TagsCubit, TagsState>(
      builder: (context, state) {
        final tags = state.tags;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sell_outlined,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l.transactionFormTagsLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 4),
                child: Text(
                  l.transactionFormTagsEmpty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final t in tags)
                      FilterChip(
                        label: Text(t.name),
                        avatar: Icon(IconRegistry.get(t.iconCode?.icon, fallback: Icons.label_outline), size: 16),
                        selected: selectedIds.contains(t.id),
                        onSelected: (_) => onToggle(t.id),
                        selectedColor: (t.iconCode?.accentColorFor(palette) ?? palette.primary).withValues(alpha: 0.35),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
