import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';

/// Create / edit account form — routed at `/accounts/new` and
/// `/accounts/:id/edit`.
///
/// **Create mode** (default): Save calls `cubit.add(...)` →
/// `POST /v1/accounts`. Opening balance can be non-zero and the server
/// auto-creates an Opening Balance transaction.
///
/// **Edit mode** (`editingId` set): controllers are pre-populated from
/// the cubit's cache. Save calls `cubit.update(...)` →
/// `PUT /v1/accounts/:id`. Per spec §2.4, **balance is NOT editable
/// here** — the field is hidden and the user adjusts via the detail-
/// page "Adjust balance" overflow menu (which calls
/// `POST /v1/accounts/:id/adjust-balance`).
///
/// Sections (top to bottom):
/// - Live preview card (re-renders every change)
/// - Type chips with leading icons
/// - Name
/// - [IconColorPicker] (shared widget)
/// - Currency — disabled tile with "Phase 2" badge
/// - Opening balance (create mode only)
/// - Description (200 chars, optional)
/// - Note (200 chars, optional)
/// - Credit details (only when [AccountType.isCredit])
class AccountFormPage extends StatefulWidget {
  const AccountFormPage({this.editingId, super.key});

  /// Non-null when the page is opened for edit (`/accounts/:id/edit`).
  /// Null for create (`/accounts/new`).
  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _statementDateController = TextEditingController();
  final _paymentDueController = TextEditingController();
  final _minimumPaymentController = TextEditingController();

  AccountType _type = AccountType.cash;
  IconCode? _iconCode;

  /// The pre-edit snapshot when [AccountFormPage.isEdit] is true. Used
  /// to compute dirty-ness for the discard-confirm dialog and to build
  /// the [Account] body for the PUT call (preserving id, currency, etc.).
  Account? _initial;

  bool get _isCredit => _type.isCredit;

  bool get _hasUserInput {
    if (widget.isEdit) {
      // Edit mode: dirty if anything differs from the loaded initial.
      if (_initial == null) return false;
      final i = _initial!;
      final desc = _descriptionController.text.trim();
      final note = _noteController.text.trim();
      final initialDesc = (i.description ?? '');
      final initialNote = (i.note ?? '');
      if (_nameController.text != i.name) return true;
      if (_type != i.type) return true;
      if (_iconCode != i.iconCode) return true;
      if (desc != initialDesc) return true;
      if (note != initialNote) return true;
      if (_isCredit) {
        if (_creditLimitController.text !=
            (i.creditLimit?.toString() ?? '')) {
          return true;
        }
        if (_statementDateController.text !=
            (i.statementDate?.toString() ?? '')) {
          return true;
        }
        if (_paymentDueController.text !=
            (i.paymentDueDate?.toString() ?? '')) {
          return true;
        }
        if (_minimumPaymentController.text !=
            (i.minimumPayment?.toString() ?? '')) {
          return true;
        }
      }
      return false;
    }
    // Create mode: dirty if any user input is present.
    return _nameController.text.isNotEmpty ||
        _balanceController.text != '0' ||
        _descriptionController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        _creditLimitController.text.isNotEmpty ||
        _statementDateController.text.isNotEmpty ||
        _paymentDueController.text.isNotEmpty ||
        _minimumPaymentController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      // Cubit cache populated by the list page or detail page navigation.
      // If the user deep-links into an unloaded edit URL, byId returns
      // null and we render a not-found scaffold.
      final existing =
          context.read<AccountsCubit>().byId(widget.editingId!);
      if (existing != null) {
        _initial = existing;
        _nameController.text = existing.name;
        _descriptionController.text = existing.description ?? '';
        _noteController.text = existing.note ?? '';
        _type = existing.type;
        _iconCode = existing.iconCode;
        if (existing.type.isCredit) {
          _creditLimitController.text =
              existing.creditLimit?.toString() ?? '';
          _statementDateController.text =
              existing.statementDate?.toString() ?? '';
          _paymentDueController.text =
              existing.paymentDueDate?.toString() ?? '';
          _minimumPaymentController.text =
              existing.minimumPayment?.toString() ?? '';
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _creditLimitController.dispose();
    _statementDateController.dispose();
    _paymentDueController.dispose();
    _minimumPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Edit mode + the account isn't in the cubit cache → user deep-linked
    // an unloaded id. Show a minimal not-found scaffold rather than an
    // empty form that would create a wrong PUT body on save.
    if (widget.isEdit && _initial == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.accountFormTitleEdit)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l.accountDetailNotFoundMessage,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasUserInput,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard(context, l);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEdit ? l.accountFormTitleEdit : l.accountFormTitle,
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
              _SectionLabel(text: l.accountFormPreviewLabel),
              AccountCard(
                account: _previewAccount(),
                horizontal: true,
                onIconTap: () => _openIconMaker(context, l),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(text: l.accountFormTypeLabel),
              _TypeChips(
                selected: _type,
                onSelected: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l.accountFormNameLabel,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l.accountFormNameRequired;
                  }
                  if (v.length > 100) return l.accountFormNameTooLong;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _CurrencyTile(currency: _initial?.currency ?? 'THB'),
              if (!widget.isEdit) ...[
                // Edit mode hides the balance field — per spec §2.4 PUT
                // can't change `balance`. The detail page's "Adjust
                // balance" overflow menu calls /adjust-balance instead,
                // which creates an Adjustment transaction so the cached
                // balance stays consistent with the transaction history.
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\-0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l.accountFormBalanceLabel,
                    helperText: l.accountFormBalanceHelper,
                    helperMaxLines: 2,
                    prefixText: '฿ ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.accountFormDescriptionLabel,
                  helperText: l.accountFormDescriptionHelper,
                  helperMaxLines: 2,
                ),
                validator: (v) => (v != null && v.length > 200)
                    ? l.accountFormDescriptionTooLong
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l.accountFormNoteLabel,
                  helperText: l.accountFormNoteHelper,
                  helperMaxLines: 2,
                ),
                validator: (v) => (v != null && v.length > 200)
                    ? l.accountFormNoteTooLong
                    : null,
              ),
              if (_isCredit) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(text: l.accountFormCreditSection),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _creditLimitController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l.accountFormCreditLimitLabel,
                    prefixText: '฿ ',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (!_isCredit) return null;
                    final parsed = double.tryParse(v ?? '');
                    if (parsed == null || parsed <= 0) {
                      return l.accountFormCreditLimitRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _statementDateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.accountFormStatementDateLabel,
                          helperText: l.accountFormStatementDateHelper,
                          helperMaxLines: 2,
                        ),
                        validator: _validateDayOfMonth(l),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _paymentDueController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.accountFormPaymentDueLabel,
                          helperText: l.accountFormPaymentDueHelper,
                          helperMaxLines: 2,
                        ),
                        validator: _validateDayOfMonth(l),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _minimumPaymentController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l.accountFormMinimumPaymentLabel,
                    prefixText: '฿ ',
                  ),
                ),
              ],
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
                  ? l.accountFormSaveEdit
                  : l.accountFormSave),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the universal icon-color picker as a bottom sheet (or dialog on
  /// tablet width). The picker is fully generic — we map our typed enums to
  /// its [IconPickerOption] / [IconPickerSwatch] shape on the way in, and
  /// back to typed enums on the way out.
  ///
  /// The preview at the top of the sheet is the same [AccountCard] used in
  /// the form's preview slot — so the user sees their pick in the same
  /// visual frame the grid renders. Future contexts (categories / tags /
  /// projects, eventually user avatar) supply their own previewBuilder.
  Future<void> _openIconMaker(BuildContext context, AppLocalizations l) async {
    final result = await showIconMakerSheet(
      context: context,
      iconIds: IconRegistry.accountIconIds,
      style: IconMakerStyle.background,
      initial: _iconCode,
      iconSectionLabel: l.accountFormIconLabel,
      colorSectionLabel: l.accountFormColorLabel,
      previewBuilder: (iconCode) => AccountCard(
        account: _previewAccount().copyWith(iconCode: iconCode),
        horizontal: true,
      ),
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      setState(() => _iconCode = result.iconCode);
    }
  }

  /// Validator for day-of-month fields. Empty is allowed (optional field);
  /// when present, must parse to 1..31.
  FormFieldValidator<String> _validateDayOfMonth(AppLocalizations l) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final n = int.tryParse(value);
      if (n == null || n < 1 || n > 31) return l.accountFormDayInvalid;
      return null;
    };
  }

  Account _previewAccount() {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final creditLimit = _isCredit
        ? double.tryParse(_creditLimitController.text) ?? 0
        : null;
    return Account(
      id: 'preview',
      name: _nameController.text.isEmpty
          ? AppLocalizations.of(context)!.accountFormNameLabel
          : _nameController.text,
      type: _type,
      balance: balance,
      currency: 'THB',
      iconCode: _iconCode,
      creditLimit: creditLimit,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final description = _descriptionController.text.trim();
    final note = _noteController.text.trim();
    final descValue = description.isEmpty ? null : description;
    final noteValue = note.isEmpty ? null : note;
    final creditLimit =
        _isCredit ? double.tryParse(_creditLimitController.text) : null;
    final statementDate =
        _isCredit ? int.tryParse(_statementDateController.text) : null;
    final paymentDue =
        _isCredit ? int.tryParse(_paymentDueController.text) : null;
    final minimumPayment = _isCredit
        ? double.tryParse(_minimumPaymentController.text)
        : null;

    try {
      if (widget.isEdit) {
        // Edit mode preserves id + balance + currency from the loaded
        // initial. Balance is intentionally NOT touched — adjust-balance
        // is the only path to mutate it (spec §2.4 / §2.5).
        //
        // NOT using copyWith here: copyWith.description treats `null` as
        // "leave current" via `?? this.description`, so a cleared field
        // would silently reset to the prior value. Constructing the
        // Account directly keeps explicit-null semantics, which the BE's
        // presence-tracked Update DTO needs to clear the column.
        final updated = Account(
          id: _initial!.id,
          name: _nameController.text.trim(),
          type: _type,
          balance: _initial!.balance,
          currency: _initial!.currency,
          iconCode: _iconCode,
          description: descValue,
          note: noteValue,
          creditLimit: creditLimit,
          statementDate: statementDate,
          paymentDueDate: paymentDue,
          minimumPayment: minimumPayment,
        );
        await cubit.update(updated);
      } else {
        // Server assigns id; placeholder never reaches the wire
        // (toCreateJson omits it).
        final draft = Account(
          id: 'draft',
          name: _nameController.text.trim(),
          type: _type,
          balance: double.tryParse(_balanceController.text) ?? 0,
          currency: 'THB',
          iconCode: _iconCode,
          description: descValue,
          note: noteValue,
          creditLimit: creditLimit,
          statementDate: statementDate,
          paymentDueDate: paymentDue,
          minimumPayment: minimumPayment,
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

  Future<bool> _confirmDiscard(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isEdit
            ? l.accountFormDiscardTitleEdit
            : l.accountFormDiscardTitle),
        content: Text(l.accountFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.commonRemove),
          ),
        ],
      ),
    );
    return ok ?? false;
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

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.selected, required this.onSelected});

  final AccountType selected;
  final ValueChanged<AccountType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: AccountType.values.map((t) {
        final isSelected = t == selected;
        return ChoiceChip(
          avatar: Icon(
            t.icon,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(_labelFor(l, t)),
          selected: isSelected,
          onSelected: (_) => onSelected(t),
        );
      }).toList(),
    );
  }

  String _labelFor(AppLocalizations l, AccountType t) {
    switch (t) {
      case AccountType.cash:
        return l.accountTypeCash;
      case AccountType.bank:
        return l.accountTypeBank;
      case AccountType.eWallet:
        return l.accountTypeEWallet;
      case AccountType.creditCard:
        return l.accountTypeCreditCard;
      case AccountType.payLater:
        return l.accountTypePayLater;
    }
  }
}

/// Disabled currency tile — surfaces the future multi-currency feature
/// without letting users tap it. Spec phase summary in
/// [`03-accounts.md`](../../../../../chubi-pocket-docs/design/spec/03-accounts.md)
/// has multi-currency at Phase 2; until then, accounts default to the user's
/// currency (THB for now).
class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        enabled: false,
        leading: Icon(Icons.attach_money, color: scheme.onSurfaceVariant),
        title: Text(l.accountFormCurrencyLabel),
        subtitle: Text(currency),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l.accountFormPhase2Badge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}
