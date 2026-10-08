import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../widgets/account_picker_sheet.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../widgets/event_section.dart';
import '../widgets/splits_section.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/ui.dart';

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

/// The actual form fields — embedded in [TransactionFormPage] (full
/// page: create from the empty-state tiles, and every edit). The `+`
/// button uses its own quick-create sheet (quick_create_sheet.dart).
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
    this.showTags = true,
    this.allowTransfer = true,
    this.enableEventSection = false,
    this.onSplitsChanged,
    super.key,
  });

  /// Show the "Save & add another" button next to "Save".
  final bool allowSaveAndAddAnother;

  /// True for modal (note hidden behind "+ Add note" expand); false
  /// for page (note always visible).
  final bool collapsibleNote;

  /// Hide the tag chip row when false. The quick-create-project embed
  /// (spec §10/4.24) turns it off: `POST /v1/projects/quick` returns no
  /// transaction id, so tags could not be attached afterwards — showing
  /// the row would silently drop the user's selection.
  final bool showTags;

  /// Hide the Transfer type tab when false. Quick create embeds the
  /// form for a *bill* (expense / income) — a project board row can't
  /// be a transfer (spec §10 — project tx type is expense | income).
  final bool allowTransfer;

  /// Fires whenever the draft split list changes (create mode only).
  /// Quick create listens to recompute its members+date default name
  /// (spec §10/4.24).
  final ValueChanged<List<SplitDraft>>? onSplitsChanged;

  /// Show the collapsible "สร้างอีเวนต์จากบิลนี้..." expander below the
  /// splits section (create mode, non-transfer only — spec §10/4.24).
  /// When the user arms it, [save] posts `POST /v1/projects/quick`
  /// instead of the plain transaction create, then navigates to the new
  /// event's page.
  final bool enableEventSection;

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
  final _eventKey = GlobalKey<EventSectionState>();

  late TransactionType _type;
  Account? _account;
  Account? _toAccount; // transfer destination
  Category? _category;

  // Snapshot of account ids when entering edit mode — used to detect moves.
  String? _initialAccountId;
  String? _initialToAccountId;
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
  // Splits on both bill types (spec §12): expense = "หารกับ" (they owe
  // me), income = "แบ่งให้" (I received money that partly belongs to
  // them → I owe them). The BE flips the debt direction by parent type.
  bool get _showSplits => !_isEdit && !_isTransfer;

  /// Shared-wallet edit rules (spec §14/2, API §14 pinned flags):
  /// - `is_locked` — ex-member's own row: the whole form is read-only.
  /// - `can_edit_category=false` — another member's row: everything but
  ///   the category is editable (the category belongs to the author's
  ///   taxonomy).
  bool get _lockedRow =>
      widget.initial.editingTransaction?.isLocked ?? false;
  bool get _canEditCategory =>
      widget.initial.editingTransaction?.canEditCategory ?? true;

  /// Public read-only signal for the parent scaffold (hides Save
  /// buttons on locked rows).
  bool get isReadOnly => _lockedRow;

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
      if (widget.showTags) context.read<TagsCubit>().loadIfNeeded();
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

      Account? toAcc;
      if (i.transferGroupId != null) {
        final txState = context.read<TransactionsCubit>().state;
        for (final t in txState.transactions) {
          if (t.id != i.id && t.transferGroupId == i.transferGroupId) {
            toAcc = t.accountId != null ? findAccount(t.accountId!) : null;
            break;
          }
        }
      }
      final fromAcc = i.accountId != null ? findAccount(i.accountId!) : null;
      setState(() {
        _account = fromAcc;
        _category = findCategory(i.categoryId);
        _toAccount = toAcc;
      });
      // Snapshot for dirty-detection in save().
      _initialAccountId = fromAcc?.id;
      _initialToAccountId = toAcc?.id;
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
    if (_lockedRow) return false; // read-only ex-member row (ROW_LOCKED)
    // Armed event section (spec §10/4.24): the whole form submits as
    // POST /v1/projects/quick instead of a plain transaction create.
    // keepOpen is ignored — the flow always navigates to the new event.
    final event = _eventKey.currentState;
    if (!_isEdit && event != null && event.enabled) {
      return _saveAsEvent(event);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    if (!_transferOk()) return false;
    final amount = AmountField.parse(_amountController.text);
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
        // Another member's row: never send category_id — only the
        // author may change it (403 CATEGORY_AUTHOR_ONLY otherwise).
        final clearCategory = !_isTransfer &&
            _canEditCategory &&
            initial.categoryId != null &&
            _category == null;
        // Account move: compare current vs snapshot from hydration.
        final newAccountId = _account?.id;
        final accountChanged = newAccountId != _initialAccountId;
        final toAccountChanged =
            _isTransfer && _toAccount?.id != _initialToAccountId;
        result = await txCubit.updateTransaction(
          id: initial.id,
          amount: amount,
          date: dateStr,
          categoryId:
              (_isTransfer || !_canEditCategory) ? null : _category?.id,
          clearCategory: clearCategory,
          note: note,
          clearNote: note == null && initial.note != null,
          accountId: accountChanged && newAccountId != null ? newAccountId : null,
          clearAccount: accountChanged && newAccountId == null,
          transferToAccountId: toAccountChanged ? _toAccount?.id : null,
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
        final splitsPayload = _collectSplitsPayload(amount);
        if (splitsPayload == _splitsExceedSentinel) return false;
        result = await txCubit.add(
          type: _type,
          accountId: _account?.id,
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
      } else if (result.single?.accountBalanceAfter != null &&
          result.single!.accountId != null) {
        // Single-row create — patch one account.
        accountsCubit.patchBalance(
          accountId: result.single!.accountId!,
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
    } on TagsAttachFailed {
      // Saved — only the tags didn't stick. Close like a save (a second
      // Save would duplicate the transaction) and say so.
      if (!mounted) return true;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.txSavedTagsFailed)));
      widget.onSaved(addedAnother: false);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      // Shared-wallet codes (CATEGORY_AUTHOR_ONLY / ROW_LOCKED /
      // NOT_MEMBER) get friendly copy; everything else falls back to
      // the BE message as before.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            walletErrorMessage(AppLocalizations.of(context)!, e),
          ),
        ));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Armed event flow (spec §10/4.24): validate both the form and the
  /// event name, then post the whole thing as `POST /v1/projects/quick`
  /// — atomic on the BE. On success the parent closes (via onSaved) and
  /// the router lands on the new event's page.
  Future<bool> _saveAsEvent(EventSectionState event) async {
    // Validate both sections so the user sees every field error at once.
    final nameOk = event.validateName();
    final payload = buildCreatePayload();
    if (!nameOk || payload == null) return false;

    final projectsCubit = context.read<ProjectsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l = AppLocalizations.of(context)!;

    setState(() => _saving = true);
    try {
      final result = await projectsCubit.quickCreate(
        name: event.name,
        newTransaction: payload,
        transactionIds: event.selectedTransactionIds,
      );
      // The BE created the new bill and re-tagged the ticked ones —
      // refresh the caches whose rows / balances changed server-side.
      unawaited(accountsCubit.load());
      unawaited(txCubit.load());
      if (!mounted) return true;
      widget.onSaved(addedAnother: false); // parent pops the sheet/page
      router.push('/projects/${result.project.id}');
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(quickCreateErrorMessage(l, e))));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Transfer needs both wallets, and different ones. Says what's missing
  /// instead of failing silently.
  bool _transferOk() {
    if (!_isTransfer) return true;
    final l = AppLocalizations.of(context)!;
    final msg = _account == null || _toAccount == null
        ? l.txTransferNeedsTo
        : _account!.id == _toAccount!.id
            ? l.txTransferSameWallet
            : null;
    if (msg == null) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
    return false;
  }

  /// Sentinel returned by [_collectSplitsPayload] when the drafted
  /// splits exceed the transaction amount (snackbar already shown).
  /// Distinct from `null`, which means "no splits".
  static final List<Map<String, dynamic>> _splitsExceedSentinel =
      List.unmodifiable(<Map<String, dynamic>>[]);

  /// Filter splits: only complete rows are sent. The BE rejects the
  /// whole transaction if any row is invalid, so silently dropping
  /// half-typed rows is the friendlier behaviour. Returns
  /// [_splitsExceedSentinel] (after showing a snackbar) when the split
  /// total exceeds [amount].
  List<Map<String, dynamic>>? _collectSplitsPayload(double amount) {
    if (!_showSplits || !_splits.any((d) => d.isComplete)) return null;
    final total = _splits
        .where((d) => d.isComplete)
        .fold<double>(0, (a, d) => a + (d.owedAmount ?? 0));
    if (total > amount + 0.005) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(
          AppLocalizations.of(context)!.txSplitExceeds,
        )));
      return _splitsExceedSentinel;
    }
    return _splits
        .where((d) => d.isComplete)
        .map((d) => d.toJson())
        .toList();
  }

  /// Validates the create-mode fields and collects the exact
  /// `POST /v1/transactions` body. Returns `null` when invalid (a
  /// snackbar is shown where the rule warrants one — same behaviour
  /// as [save]).
  ///
  /// Used by the quick-create-project page (spec §10/4.24, API §10
  /// "Quick create") to embed this form and forward the body as
  /// `new_transaction` without duplicating the form's validation.
  /// Not meaningful in edit mode.
  Map<String, dynamic>? buildCreatePayload() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    if (!_transferOk()) return null;
    final amount = AmountField.parse(_amountController.text);
    if (amount == null || amount <= 0) return null;

    final splitsPayload = _collectSplitsPayload(amount);
    if (splitsPayload == _splitsExceedSentinel) return null;

    final noteRaw = _noteController.text.trim();
    return <String, dynamic>{
      'type': _type.toJson(),
      if (_account != null) 'account_id': _account!.id,
      'amount': amount,
      'date': _formatDate(_date),
      if (!_isTransfer && _category != null) 'category_id': _category!.id,
      if (noteRaw.isNotEmpty) 'note': noteRaw,
      if (_isTransfer) 'transfer_to_account_id': _toAccount!.id,
      if (splitsPayload != null && splitsPayload.isNotEmpty)
        'splits': splitsPayload,
    };
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
    widget.onSplitsChanged?.call(_splits);
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
        _splits.isNotEmpty ||
        (_eventKey.currentState?.isDirty ?? false);
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
          // Ex-member row (spec §14/2.3): the whole form is read-only,
          // with an explanatory banner. Remaining members still edit
          // these rows — only the departed author is locked out.
          if (_lockedRow) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l.transactionFormLockedBanner,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!_isEdit) _TypeTabs(
            selected: _type,
            showTransfer: widget.allowTransfer,
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
            saving: _saving || _lockedRow,
            label: l.transactionFormAmountLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _AccountTile(
            label: _isTransfer
                ? l.transactionFormFromAccountLabel
                : l.transactionFormAccountLabel,
            account: _account,
            readOnly: false,
            onTap: (_isEdit && _isTransfer)
                ? _pickTransferAccounts
                : _pickAccount,
          ),
          if (_isTransfer) ...[
            const SizedBox(height: AppSpacing.sm),
            _AccountTile(
              label: l.transactionFormToAccountLabel,
              account: _toAccount,
              readOnly: false,
              onTap: (_isEdit && _isTransfer)
                  ? _pickTransferAccounts
                  : _pickToAccount,
            ),
          ],
          if (!_isTransfer) ...[
            const SizedBox(height: AppSpacing.md),
            _CategoryTile(
              category: _category,
              // Another member's row: category disabled with a hint —
              // the author's category renders read-only from
              // category_render (spec §14/2.2).
              enabled: _canEditCategory && !_lockedRow,
              displayNameOverride: _category == null
                  ? widget
                      .initial.editingTransaction?.categoryRender?.name
                  : null,
              hint: (!_canEditCategory && !_lockedRow)
                  ? l.transactionFormCategoryAuthorOnlyHint
                  : null,
              onTap: _pickCategory,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            _TransferCategoryHint(),
          ],
          const SizedBox(height: AppSpacing.md),
          _DateTile(
            date: _date,
            onTap: _lockedRow ? null : _pickDate,
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
              enabled: !_lockedRow,
              maxLength: 500,
              maxLines: widget.collapsibleNote ? 2 : 3,
              decoration: InputDecoration(
                labelText: l.transactionFormNoteLabel,
              ),
            ),
          if (widget.showTags) ...[
            const SizedBox(height: AppSpacing.md),
            IgnorePointer(
              ignoring: _lockedRow,
              child: Opacity(
                opacity: _lockedRow ? 0.5 : 1,
                child: _TagChipsRow(
                  selectedIds: _selectedTagIds,
                  onToggle: _toggleTag,
                ),
              ),
            ),
          ],
          if (_showSplits) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            SplitsSection(
              title: _type == TransactionType.income
                  ? l.transactionSplitShareTitle
                  : l.transactionSplitWithTitle,
              totalAmount:
                  AmountField.parse(_amountController.text) ?? 0,
              drafts: _splits,
              onChanged: (next) {
                setState(() => _splits = next);
                widget.onSplitsChanged?.call(next);
                _eventKey.currentState?.setMemberNames(_splitNames(next));
              },
            ),
          ],
          // "สร้างอีเวนต์จากบิลนี้..." expander (spec §10/4.24) — create
          // mode, non-transfer only. Flipping to Transfer unmounts it
          // (selection resets), matching the BE's expense/income-only
          // board rows.
          if (!_isEdit && widget.enableEventSection && !_isTransfer) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            EventSection(key: _eventKey),
          ],
        ],
      ),
    );
  }

  /// Distinct split-counterparty names in entry order — feeds the event
  /// section's members+date default name.
  static List<String> _splitNames(List<SplitDraft> drafts) {
    final names = <String>[];
    for (final d in drafts) {
      final n = d.personName.trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }
    return names;
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
    final accsState = context.read<AccountsCubit>().state;
    final result = await showAccountPickerSheet(
      context: context,
      accounts: accsState.accounts,
      selected: _account,
      allowNone: _isEdit,
    );
    if (!mounted || result == null) return;
    setState(() {
      _account = result is AccountPickerSelected ? result.account : null;
    });
  }

  Future<void> _pickToAccount() async {
    final accsState = context.read<AccountsCubit>().state;
    final result = await showAccountPickerSheet(
      context: context,
      accounts: accsState.accounts,
      selected: _toAccount,
      excludeId: _account?.id,
      title: AppLocalizations.of(context)!.transactionFormToAccountLabel,
    );
    if (!mounted || result == null) return;
    if (result is AccountPickerSelected) {
      setState(() => _toAccount = result.account);
    }
  }

  /// Transfer edit — single bottom sheet lets user pick both FROM and TO
  /// wallets simultaneously, then confirms atomically.
  Future<void> _pickTransferAccounts() async {
    final accsState = context.read<AccountsCubit>().state;
    final picked = await showModalBottomSheet<(Account?, Account?)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TransferMoveSheet(
        accounts: accsState.accounts,
        from: _account,
        to: _toAccount,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _account = picked.$1;
      _toAccount = picked.$2;
    });
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
  const _TypeTabs({
    required this.selected,
    required this.onChanged,
    this.showTransfer = true,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  /// False hides the Transfer segment — quick-create-project embed only
  /// records bills (expense / income), see [TransactionFormBody.allowTransfer].
  final bool showTransfer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<TransactionType>(
      style: const ButtonStyle(
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
        if (showTransfer)
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
    return AmountField(
      controller: controller,
      label: label,
      currencySymbol: Currencies.symbolOf(currency),
      enabled: !saving,
      autofocus: true,
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return l.transactionFormAmountRequired;
        final n = AmountField.parse(v);
        if (n == null) return l.transactionFormAmountInvalid;
        if (n <= 0) return l.transactionFormAmountTooSmall;
        return null;
      },
    );
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
                      account?.name ??
                          (readOnly
                              ? l.transactionFormAccountNone
                              : l.transactionFormAccountRequired),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: account == null
                                ? scheme.onSurfaceVariant
                                : null,
                          ),
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
  const _CategoryTile({
    required this.category,
    required this.onTap,
    this.enabled = true,
    this.hint,
    this.displayNameOverride,
  });

  final Category? category;
  final VoidCallback onTap;

  /// False disables the picker (author-only category on another
  /// member's shared-wallet row, or a fully locked row).
  final bool enabled;

  /// Small helper line under the tile (e.g. "หมวดแก้ได้เฉพาะคนจด").
  final String? hint;

  /// Read-only name shown when the category can't be resolved from the
  /// viewer's own cache (another member's category via category_render).
  final String? displayNameOverride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: enabled ? onTap : null,
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
                          category!.iconCode?.bgColorFor(palette) ??
                              scheme.outline,
                      child: Icon(
                          IconRegistry.get(category!.iconCode?.icon,
                              fallback: Icons.category_outlined),
                          color: Colors.white,
                          size: 14),
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
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                )),
                        Text(
                          category?.name ??
                              displayNameOverride ??
                              l.transactionFormCategoryNone,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.chevron_right,
                        color: scheme.onSurfaceVariant)
                  else
                    Icon(Icons.lock_outline,
                        size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xs, left: AppSpacing.md),
            child: Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
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
  final VoidCallback? onTap;

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

// ── Transfer move sheet ───────────────────────────────────────────────

/// Bottom sheet for moving both sides of a transfer simultaneously.
/// Returns `(newFrom, newTo)` on confirm, null on dismiss.
class _TransferMoveSheet extends StatefulWidget {
  const _TransferMoveSheet({
    required this.accounts,
    required this.from,
    required this.to,
  });

  final List<Account> accounts;
  final Account? from;
  final Account? to;

  @override
  State<_TransferMoveSheet> createState() => _TransferMoveSheetState();
}

class _TransferMoveSheetState extends State<_TransferMoveSheet> {
  late Account? _from;
  late Account? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  Future<void> _pickFrom() async {
    final result = await showAccountPickerSheet(
      context: context,
      accounts: widget.accounts,
      selected: _from,
      excludeId: _to?.id,
    );
    if (!mounted || result == null) return;
    if (result is AccountPickerSelected) setState(() => _from = result.account);
  }

  Future<void> _pickTo() async {
    final l = AppLocalizations.of(context)!;
    final result = await showAccountPickerSheet(
      context: context,
      accounts: widget.accounts,
      selected: _to,
      excludeId: _from?.id,
      title: l.transactionFormToAccountLabel,
    );
    if (!mounted || result == null) return;
    if (result is AccountPickerSelected) setState(() => _to = result.account);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final canConfirm = _from != null && _to != null && _from!.id != _to!.id;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.transactionFormMoveTransferTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _AccountTile(
              label: l.transactionFormFromAccountLabel,
              account: _from,
              readOnly: false,
              onTap: _pickFrom,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Icon(Icons.arrow_downward,
                  color: scheme.onSurfaceVariant, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AccountTile(
              label: l.transactionFormToAccountLabel,
              account: _to,
              readOnly: false,
              onTap: _pickTo,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed:
                  canConfirm ? () => Navigator.of(context).pop((_from, _to)) : null,
              child: Text(l.commonOk),
            ),
          ],
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

String _formatAmountInput(double amount) => AmountField.format(amount);

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
