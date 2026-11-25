import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/domain/account_type.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../institutions/domain/institution.dart';
import '../../../institutions/presentation/widgets/institution_picker.dart';
import '../../../recurring/presentation/recurring_draft.dart';
import '../../../recurring/presentation/widgets/recurring_plan_form.dart';
import '../../../transactions/presentation/widgets/debt_entry_form.dart';
import '../../data/personal_debts_repository.dart';

enum _Creditor { card, institution, person }

/// จดหนี้ผ่อนใหม่ (0.4.3, artifact D-Create): who it is owed to (a card /
/// PayLater wallet, an institution or a person), what it is (a purchase: the
/// full price is an expense today; a cash loan: money into a wallet), and the
/// plan (principal, installments, first due date, interest). A card plan
/// books nothing (the purchase is on the card already).
class NewDebtPlanPage extends StatefulWidget {
  const NewDebtPlanPage({this.cardId, this.cardName, super.key});

  /// ผ่อนใหม่ from a card page: the card is the creditor.
  final String? cardId;
  final String? cardName;

  @override
  State<NewDebtPlanPage> createState() => _NewDebtPlanPageState();
}

class _NewDebtPlanPageState extends State<NewDebtPlanPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  /// ทิศ: true = เราติดเขา (received), false = เขาติดเรา (paid).
  bool _iOwe = true;
  String? _categoryId;
  String? _categoryName;
  _Creditor _creditor = _Creditor.person;
  String? _cardId;
  String? _cardName;
  InstitutionRef? _institution;
  DebtPick? _person;
  bool _cash = false;
  Account? _opening;
  RecurringPlanDraft? _plan = RecurringPlanDraft(
    start: DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
  );
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.cardId != null) {
      _creditor = _Creditor.card;
      _cardId = widget.cardId;
      _cardName = widget.cardName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _ready {
    final creditor = switch (_creditor) {
      _Creditor.card => _cardId != null,
      _Creditor.institution => _institution != null,
      _Creditor.person => _person != null,
    };
    return creditor && _name.text.trim().isNotEmpty && _plan?.toWrite() != null;
  }

  Future<void> _pickCreditor() async {
    final l = AppLocalizations.of(context)!;
    switch (_creditor) {
      case _Creditor.card:
        final r = await AccountPicker.one(
          context,
          title: l.debtPlanCreditorCard,
        );
        if (!mounted || r is! AccountPicked) return;
        final t = r.account.type;
        if (t != AccountType.creditCard && t != AccountType.payLater) {
          showErrorSnackBar(context, l.debtPlanCreditorCard);
          return;
        }
        setState(() {
          _cardId = r.account.id;
          _cardName = r.account.name;
        });
      case _Creditor.institution:
        final r = await InstitutionPicker.one(
          context,
          selectedId: _institution?.id,
        );
        if (mounted && r != null) setState(() => _institution = r);
      case _Creditor.person:
        final r = await showDebtPersonPicker(context, selected: _person);
        if (mounted && r != null) setState(() => _person = r);
    }
  }

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context)!;
    final r = await CategoryPicker.one(
      context,
      types: {CategoryType.expense},
      selectedId: _categoryId,
      allowNone: true,
      title: l.debtPlanCategory,
    );
    if (!mounted || r == null) return;
    setState(() {
      switch (r) {
        case CategoryPicked(:final category):
          _categoryId = category.id;
          _categoryName = category.name;
        case CategoryPickedNone():
          _categoryId = null;
          _categoryName = null;
      }
    });
  }

  Future<void> _pickOpening() async {
    final l = AppLocalizations.of(context)!;
    final r = await AccountPicker.one(context, title: l.debtPlanOpeningWallet);
    if (mounted && r is AccountPicked) setState(() => _opening = r.account);
  }

  Future<void> _save() async {
    final plan = _plan?.toWrite();
    if (plan == null) return;
    setState(() => _saving = true);
    final card = _creditor == _Creditor.card;
    try {
      final p = await context.read<PersonalDebtsRepository>().createPlan({
        'name': _name.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'category_id': card || !_cash ? _categoryId : null,
        'direction': card || _iOwe ? 'received' : 'paid',
        // they owe me: always money I lent (a cash loan)
        'origin': card || (!_cash && _iOwe) ? 'purchase' : 'cash',
        'creditor': {
          'account_id': card ? _cardId : null,
          'institution_id': _creditor == _Creditor.institution
              ? _institution?.id
              : null,
          'contact_id': _creditor == _Creditor.person
              ? _person?.person.contactId
              : null,
          'person_name':
              _creditor == _Creditor.person && _person?.person.contactId == null
              ? _person?.person.name
              : null,
        },
        'plan': {
          ...plan.toJson(),
          'opening_account_id': !card && _cash ? _opening?.id : null,
        },
      });
      if (mounted) context.pushReplacement('/personal-debts/plans/${p.id}');
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
        setState(() => _saving = false);
      }
    }
  }

  String _creditorLabel(AppLocalizations l, _Creditor c) => switch (c) {
    _Creditor.card => l.debtPlanCreditorCard,
    _Creditor.institution => l.debtPlanCreditorInstitution,
    _Creditor.person => l.debtPlanCreditorPerson,
  };

  String? _creditorValue() => switch (_creditor) {
    _Creditor.card => _cardName,
    _Creditor.institution => _institution?.name,
    _Creditor.person => _person?.person.name,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final card = _creditor == _Creditor.card;
    return AppPage(
      topBar: AppTopBar(title: l.debtPlanNew, showBack: true),
      body: Builder(
        builder: (context) => ListView(
          padding: AppPage.scrollPadding(context),
          children: [
            SectionCard(
              first: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(PpForgeSpacing.md),
                  child: PpForgeInput(
                    key: const ValueKey('debtPlanName'),
                    controller: _name,
                    label: l.commonName,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SettingDropdownRow<bool>(
                  key: const ValueKey('debtPlanDirection'),
                  label: l.debtPlanDirection,
                  value: _iOwe ? l.debtPlanIOwe : l.debtPlanTheyOwe,
                  selected: _iOwe,
                  submits: false,
                  onSelected: (v) => setState(() {
                    _iOwe = v;
                    if (!v && _creditor == _Creditor.card) {
                      _creditor = _Creditor.person;
                    }
                  }),
                  options: [
                    SheetOption(value: true, label: l.debtPlanIOwe),
                    SheetOption(value: false, label: l.debtPlanTheyOwe),
                  ],
                ),
                SettingDropdownRow<_Creditor>(
                  key: const ValueKey('debtPlanCreditorKind'),
                  label: l.debtPlanCreditor,
                  value: _creditorLabel(l, _creditor),
                  selected: _creditor,
                  submits: false,
                  onSelected: (c) => setState(() => _creditor = c),
                  options: [
                    for (final c in _Creditor.values)
                      if (_iOwe || c != _Creditor.card)
                        SheetOption(value: c, label: _creditorLabel(l, c)),
                  ],
                ),
                InfoRow(
                  key: const ValueKey('debtPlanCreditorPick'),
                  label: _creditorLabel(l, _creditor),
                  value: _creditorValue() ?? '—',
                  showChevron: true,
                  onTap: _pickCreditor,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PpForgeSpacing.md,
                    vertical: PpForgeSpacing.sm,
                  ),
                  child: PpForgeInput(
                    key: const ValueKey('debtPlanDescription'),
                    controller: _description,
                    label: l.debtPlanDescription,
                  ),
                ),
                if (!card && _iOwe)
                  SettingDropdownRow<bool>(
                    key: const ValueKey('debtPlanOrigin'),
                    label: l.debtPlanOrigin,
                    value: _cash
                        ? l.debtPlanOriginCash
                        : l.debtPlanOriginPurchase,
                    selected: _cash,
                    submits: false,
                    onSelected: (v) => setState(() => _cash = v),
                    options: [
                      SheetOption(
                        value: false,
                        label: l.debtPlanOriginPurchase,
                      ),
                      SheetOption(value: true, label: l.debtPlanOriginCash),
                    ],
                  ),
                if (card || (!_cash && _iOwe))
                  InfoRow(
                    key: const ValueKey('debtPlanCategory'),
                    label: l.debtPlanCategory,
                    value: _categoryName ?? '—',
                    showChevron: true,
                    onTap: _pickCategory,
                  ),
                if (!card && (_cash || !_iOwe))
                  InfoRow(
                    key: const ValueKey('debtPlanOpening'),
                    label: l.debtPlanOpeningWallet,
                    value: _opening?.name ?? '—',
                    showChevron: true,
                    onTap: _pickOpening,
                  ),
              ],
            ),
            const SizedBox(height: PpForgeSpacing.md),
            RecurringPlanForm(
              plan: _plan,
              onChanged: (p) => setState(() => _plan = p),
            ),
            const SizedBox(height: PpForgeSpacing.md),
            InfoBox(
              rows: [
                if (card) InfoRow(label: l.debtPlanHintCard),
                InfoRow(label: l.debtPlanHintReminder),
              ],
            ),
            const SizedBox(height: PpForgeSpacing.lg),
            PpForgeButton(
              key: const ValueKey('debtPlanSave'),
              label: l.debtPlanSave,
              expand: true,
              loading: _saving,
              onPressed: _ready && !_saving ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens จดหนี้ผ่อนใหม่ (used by the debts page).
Future<void> openNewDebtPlan(BuildContext context) =>
    context.push('/personal-debts/plans/new');
