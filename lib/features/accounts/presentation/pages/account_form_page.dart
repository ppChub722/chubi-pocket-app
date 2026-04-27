import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/icon_color_picker_sheet.dart';
import '../../domain/account.dart';
import '../../domain/account_icon_preset.dart';
import '../../domain/account_type.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';

/// Create-account form — full-page route at `/accounts/new`.
///
/// Phase 0 mock: Save adds the account to [AccountsCubit] in memory and
/// pops back to the grid. Phase 1a wires Save to `POST /v1/accounts` with
/// optimistic insert + rollback on failure.
///
/// Sections (top to bottom):
/// - Live preview card (re-renders every change)
/// - Type chips with leading icons
/// - Name
/// - [IconColorPicker] (shared widget — used by future category / tag /
///   project forms; avatar picker can migrate to it in P2 polish)
/// - Currency — disabled tile with "Phase 2" badge (single-currency until
///   multi-currency lands per spec Phase summary)
/// - Opening balance
/// - Note (free-text, optional, ~500-char advisory)
/// - Credit details (only when [AccountType.isCredit])
class AccountFormPage extends StatefulWidget {
  const AccountFormPage({super.key});

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _statementDateController = TextEditingController();
  final _paymentDueController = TextEditingController();
  final _minimumPaymentController = TextEditingController();

  AccountType _type = AccountType.cash;
  AccountIconPreset _icon = AccountIconPreset.wallet;
  AccountColor _color = AccountColor.blue;

  bool get _isCredit => _type.isCredit;

  bool get _hasUserInput {
    return _nameController.text.isNotEmpty ||
        _balanceController.text != '0' ||
        _noteController.text.isNotEmpty ||
        _creditLimitController.text.isNotEmpty ||
        _statementDateController.text.isNotEmpty ||
        _paymentDueController.text.isNotEmpty ||
        _minimumPaymentController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
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
    return PopScope(
      canPop: !_hasUserInput,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard(context, l);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.accountFormTitle)),
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
                onIconTap: () => _openIconPicker(context, l),
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
              _CurrencyTile(currency: 'THB'),
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
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                maxLength: 500,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.accountFormNoteLabel,
                  helperText: l.accountFormNoteHelper,
                  helperMaxLines: 3,
                ),
                validator: (v) {
                  if (v != null && v.length > 500) {
                    return l.accountFormNoteTooLong;
                  }
                  return null;
                },
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
              child: Text(l.accountFormSave),
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
  Future<void> _openIconPicker(BuildContext context, AppLocalizations l) async {
    final basePreview = _previewAccount();
    final result = await showIconColorPickerSheet(
      context: context,
      iconOptions: [
        for (final p in AccountIconPreset.values)
          IconPickerOption(id: p.id, icon: p.icon),
      ],
      swatches: [
        for (final c in AccountColor.all)
          IconPickerSwatch(id: c.id, color: c.color),
      ],
      initialIconId: _icon.id,
      initialSwatchId: _color.id,
      iconSectionLabel: l.accountFormIconLabel,
      colorSectionLabel: l.accountFormColorLabel,
      previewBuilder: (icon, swatch) => AccountCard(
        account: basePreview.copyWith(
          icon: AccountIconPreset.byId(icon.id),
          color: AccountColor.byId(swatch.id),
        ),
        horizontal: true,
      ),
      uploadComingSoonLabel: l.accountFormUploadLogo,
    );
    if (!mounted || result == null) return;
    if (result is IconColorPickerSelected) {
      setState(() {
        _icon = AccountIconPreset.byId(result.iconId);
        _color = AccountColor.byId(result.swatchId);
      });
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
      icon: _icon,
      color: _color,
      creditLimit: creditLimit,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final note = _noteController.text.trim();
    final account = Account(
      id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _type,
      balance: balance,
      currency: 'THB',
      icon: _icon,
      color: _color,
      note: note.isEmpty ? null : note,
      creditLimit: _isCredit
          ? double.tryParse(_creditLimitController.text)
          : null,
      statementDate: _isCredit
          ? int.tryParse(_statementDateController.text)
          : null,
      paymentDueDate: _isCredit
          ? int.tryParse(_paymentDueController.text)
          : null,
      minimumPayment: _isCredit
          ? double.tryParse(_minimumPaymentController.text)
          : null,
    );
    context.read<AccountsCubit>().add(account);
    context.pop();
  }

  Future<bool> _confirmDiscard(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountFormDiscardTitle),
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
