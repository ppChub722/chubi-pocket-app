import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';

/// `/personal-debts/new` — record a debt (§11). A form is edit mode: nav
/// hidden, ยกเลิก · ↶ · บันทึก. `extra` can prefill the person
/// (`{contactId, name}`) from their page.
class PersonalDebtFormPage extends StatefulWidget {
  const PersonalDebtFormPage({this.contactId, this.name, super.key});

  final String? contactId;
  final String? name;

  @override
  State<PersonalDebtFormPage> createState() => _PersonalDebtFormPageState();
}

enum _Field { amount, description, note }

class _PersonalDebtFormPageState extends State<PersonalDebtFormPage>
    with EditModeMixin<PersonalDebtFormPage, _NewDebt> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _counterpartyError;

  @override
  void initState() {
    super.initState();
    initDraft(
      _NewDebt(
        contactId: widget.contactId,
        name: widget.name ?? '',
        currency: _defaultCurrency(),
      ),
      editing: true,
    );
  }

  String _defaultCurrency() {
    final auth = context.read<AuthCubit>().state;
    final c = auth is AuthAuthenticated ? auth.user.currency : null;
    return (c != null && Currencies.codes.contains(c)) ? c : 'THB';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  bool get leaveOnCancel => true;

  @override
  void onDraftRestored() {
    if (_amountCtrl.text != working.amount) _amountCtrl.text = working.amount;
    if (_descriptionCtrl.text != working.description) {
      _descriptionCtrl.text = working.description;
    }
    if (_noteCtrl.text != working.note) _noteCtrl.text = working.note;
  }

  Future<void> _pickCounterparty() async {
    final r = await showContactPickerSheet(
      context,
      selectedContactId: working.contactId,
    );
    if (!mounted || r == null) return;
    setState(() => _counterpartyError = null);
    applyChange(switch (r) {
      ContactPicked(:final contact) => working.copyWith(
        contactId: contact.id,
        name: contact.effectiveName,
      ),
      ContactNameTyped(:final name) => working.copyWith(
        clearContact: true,
        name: name,
      ),
    });
  }

  Future<void> _save() async {
    commitTextSession();
    final l = AppLocalizations.of(context)!;
    final formOk = _formKey.currentState?.validate() ?? false;
    final hasPerson = working.name.trim().isNotEmpty;
    setState(
      () => _counterpartyError = hasPerson ? null : l.debtCounterpartyRequired,
    );
    if (!formOk || !hasPerson) return;
    final w = working;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final created = await context.read<PersonalDebtsCubit>().create(
        direction: w.direction,
        counterpartyPersonName: w.name.trim(),
        counterpartyContactId: w.contactId,
        amount: AmountField.parse(w.amount)!,
        currency: w.currency,
        description: opt(w.description),
        note: opt(w.note),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      context.pushReplacement('/personal-debts/${created.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final w = working;
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: l.debtNewTitle,
          showBack: true,
          editing: true,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: its context sees the floating bar's height.
          child: Builder(
            builder: (context) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg).add(
                EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
              ),
              children: [
                SelectCardGroup<DebtDirection>(
                  selected: w.direction,
                  onChanged: (d) => applyChange(w.copyWith(direction: d)),
                  options: [
                    SelectCardOption(
                      value: DebtDirection.owedToMe,
                      label: l.debtDirectionOwedToMe,
                      description: l.debtDirectionOwedToMeDesc,
                      icon: AppIcons.income,
                      color: palette.income,
                    ),
                    SelectCardOption(
                      value: DebtDirection.iOwe,
                      label: l.debtDirectionIOwe,
                      description: l.debtDirectionIOweDesc,
                      icon: AppIcons.expense,
                      color: palette.expense,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AmountField(
                  controller: _amountCtrl,
                  autofocus: true,
                  currencySymbol: Currencies.symbolOf(w.currency),
                  accent: w.direction == DebtDirection.owedToMe
                      ? palette.income
                      : palette.expense,
                  onChanged: (v) => applyTextChange(
                    _Field.amount,
                    working.copyWith(amount: v),
                  ),
                  validator: (v) {
                    final n = AmountField.parse(v);
                    return (n == null || n <= 0) ? l.debtAmountRequired : null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PickerTile(
                  label: l.debtCounterparty,
                  value: w.name.isEmpty ? null : w.name,
                  placeholder: l.debtCounterpartyPlaceholder,
                  leading: Icon(
                    w.contactId != null ? AppIcons.link : AppIcons.contact,
                  ),
                  errorText: _counterpartyError,
                  onTap: _pickCounterparty,
                ),
                const SizedBox(height: AppSpacing.sm),
                CurrencyTile(
                  value: w.currency,
                  onChanged: (c) => applyChange(w.copyWith(currency: c)),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _descriptionCtrl,
                  label: l.commonDescription,
                  maxLength: TextLimits.description,
                  onChanged: (v) => applyTextChange(
                    _Field.description,
                    working.copyWith(description: v),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _noteCtrl,
                  label: l.commonNote,
                  prefixIcon: AppIcons.note,
                  maxLines: 3,
                  maxLength: TextLimits.note,
                  onChanged: (v) =>
                      applyTextChange(_Field.note, working.copyWith(note: v)),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: editActionBar(onSave: _save),
      ),
    );
  }
}

class _NewDebt {
  const _NewDebt({
    this.direction = DebtDirection.owedToMe,
    this.amount = '',
    this.contactId,
    this.name = '',
    this.currency = 'THB',
    this.description = '',
    this.note = '',
  });

  final DebtDirection direction;
  final String amount;
  final String? contactId;
  final String name;
  final String currency;
  final String description;
  final String note;

  _NewDebt copyWith({
    DebtDirection? direction,
    String? amount,
    String? contactId,
    bool clearContact = false,
    String? name,
    String? currency,
    String? description,
    String? note,
  }) => _NewDebt(
    direction: direction ?? this.direction,
    amount: amount ?? this.amount,
    contactId: clearContact ? null : (contactId ?? this.contactId),
    name: name ?? this.name,
    currency: currency ?? this.currency,
    description: description ?? this.description,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is _NewDebt &&
      other.direction == direction &&
      other.amount == amount &&
      other.contactId == contactId &&
      other.name == name &&
      other.currency == currency &&
      other.description == description &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    direction,
    amount,
    contactId,
    name,
    currency,
    description,
    note,
  );
}
