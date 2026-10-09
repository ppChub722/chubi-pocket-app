import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';
import '../widgets/debt_widgets.dart';

/// `/personal-debts/:id` — one debt, view ⇄ edit (§11). Edit covers amount,
/// counterparty and note; paid-back amount and status only move through
/// "รับเงินคืน / จ่ายคืน" (settle sheet) and "ยกเลิกหนี้นี้".
class PersonalDebtDetailPage extends StatefulWidget {
  const PersonalDebtDetailPage({required this.id, super.key});
  final String id;

  @override
  State<PersonalDebtDetailPage> createState() => _PersonalDebtDetailPageState();
}

enum _Field { amount, note }

class _PersonalDebtDetailPageState extends State<PersonalDebtDetailPage>
    with EditModeMixin<PersonalDebtDetailPage, _DebtDraft> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _noteFocus = FocusNode();

  /// Used when the debt isn't in the cubit yet (deep link).
  PersonalDebt? _fetched;
  ApiException? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final cached = context.read<PersonalDebtsCubit>().byId(widget.id);
    // initDraft (no setState) — resetDraft can't run inside initState.
    initDraft(cached == null ? const _DebtDraft() : _DebtDraft.from(cached));
    onDraftRestored();
    if (cached == null) _fetch();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final d = await context.read<PersonalDebtsRepository>().get(widget.id);
      if (!mounted) return;
      setState(() => _fetched = d);
      _rebase(d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _rebase(PersonalDebt d) => resetDraft(_DebtDraft.from(d));

  PersonalDebt? _debt(PersonalDebtsState s) {
    for (final d in s.debts) {
      if (d.id == widget.id) return d;
    }
    return _fetched;
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  void leavePage() {
    if (context.canPop()) context.pop();
  }

  @override
  void onDraftRestored() {
    if (_amountCtrl.text != working.amount) _amountCtrl.text = working.amount;
    if (_noteCtrl.text != working.note) _noteCtrl.text = working.note;
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _pickCounterparty() async {
    final r = await showContactPickerSheet(
      context,
      selectedContactId: working.contactId,
    );
    if (!mounted || r == null) return;
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

  Future<void> _save(PersonalDebt debt) async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    final orig = original;
    final counterpartyChanged =
        w.contactId != orig.contactId || w.name != orig.name;
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final updated = await context.read<PersonalDebtsCubit>().update(
        debt.id,
        amount: AmountField.parse(w.amount),
        note: w.note.trim(),
        counterpartyPersonName: counterpartyChanged ? w.name : null,
        counterpartyContactId: counterpartyChanged ? w.contactId : null,
        clearContact: counterpartyChanged && w.contactId == null,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(_DebtDraft.from(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _delete(PersonalDebt debt) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.debtDeleteTitle,
      message: l.debtDeleteBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await context.read<PersonalDebtsCubit>().delete(debt.id);
      if (!mounted) return;
      showAppSnackBar(context, l.debtDeleted, tone: Tone.success);
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _settle(PersonalDebt debt) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showSettleDebtSheet(context, debt);
    if (ok && mounted) {
      showAppSnackBar(context, l.debtSettleDone, tone: Tone.success);
    }
  }

  Future<void> _cancelDebt(PersonalDebt debt) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.debtCancelTitle,
      message: l.debtCancelBody,
      confirmLabel: l.debtCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<PersonalDebtsCubit>().cancel(debt.id);
      if (mounted) showAppSnackBar(context, l.debtCancelled);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final debt = context.select<PersonalDebtsCubit, PersonalDebt?>(
      (c) => _debt(c.state),
    );

    if (debt == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.moreDebts, showBack: true),
        extendBodyBehindAppBar: true,
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _fetch)
            // The generic skeleton is a padded list — clear the bar.
            : Builder(
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: const LoadingView(),
                ),
              ),
      );
    }

    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: isEditing ? l.debtEditTitle : debt.counterpartyPersonName,
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: its context sees the floating bar's height.
          child: Builder(
            builder: (context) => ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                MediaQuery.paddingOf(context).top + AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                LockedInEdit(locked: isEditing, child: _header(l, debt)),
                if (debt.isOpen && !isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: debt.isOwedToMe ? l.debtReceive : l.debtPay,
                    icon: AppIcons.settle,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => _settle(debt),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _rows(l, debt),
                if (debt.isOpen) ...[
                  const SizedBox(height: AppSpacing.xl),
                  LockedInEdit(
                    locked: isEditing,
                    child: Center(
                      child: AppButton(
                        label: l.debtCancel,
                        variant: AppButtonVariant.text,
                        loading: _busy,
                        onPressed: () => _cancelDebt(debt),
                      ),
                    ),
                  ),
                ],
                // Delete lives at the bottom in edit mode (no top-bar actions).
                if (isEditing)
                  DangerRow(
                    icon: AppIcons.delete,
                    label: l.debtDeleteThis,
                    onTap: isSaving ? null : () => _delete(debt),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isEditing
            ? editActionBar(onSave: () => _save(debt))
            : null,
      ),
    );
  }

  Widget _header(AppLocalizations l, PersonalDebt debt) {
    final symbol = Currencies.symbolOf(debt.currency);
    final textTheme = Theme.of(context).textTheme;
    final name = debt.counterpartyPersonName;
    return HeaderCard(
      onEdit: isEditing ? null : enterEdit,
      leading: DebtAvatar(
        contactId: debt.counterpartyContactId,
        name: name,
        size: 52,
      ),
      title: Text(
        debt.isOwedToMe ? l.debtTheyOweYou(name) : l.debtYouOwe(name),
      ),
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: debtStatusPill(context, debt.status, dense: true),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.debtOutstanding, style: textTheme.labelMedium),
          MoneyText(
            debt.outstanding,
            symbol: symbol,
            tone: debt.isOpen
                ? (debt.isOwedToMe ? MoneyTone.income : MoneyTone.expense)
                : MoneyTone.plain,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressRow(
            value: debt.amount == 0 ? 0 : debt.settledAmount / debt.amount,
            label: l.debtProgress(
              moneyString(context, debt.settledAmount, symbol: symbol),
              moneyString(context, debt.amount, symbol: symbol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rows(AppLocalizations l, PersonalDebt debt) {
    final editing = isEditing;
    final symbol = Currencies.symbolOf(debt.currency);
    final scheme = Theme.of(context).colorScheme;
    final (String source, String? sourceRoute) = debt.projectId != null
        ? (l.debtSourceProject, '/projects/${debt.projectId}')
        : debt.sourceTransactionId != null
        ? (l.debtSourceTransaction, '/transactions/${debt.sourceTransactionId}')
        : (l.debtSourceManual, null);
    return SectionCard(
      children: [
        if (editing)
          DetailStacked(
            label: l.debtAmount,
            child: AmountField(
              controller: _amountCtrl,
              currencySymbol: symbol,
              onChanged: (v) =>
                  applyTextChange(_Field.amount, working.copyWith(amount: v)),
              validator: (v) {
                final n = AmountField.parse(v);
                if (n == null || n <= 0) return l.debtAmountRequired;
                if (n + 0.005 < debt.settledAmount) {
                  return l.debtAmountBelowSettled(
                    moneyString(context, debt.settledAmount, symbol: symbol),
                  );
                }
                return null;
              },
            ),
          )
        else
          DetailRow(
            label: l.debtAmount,
            trailing: MoneyText(debt.amount, symbol: symbol),
          ),
        const RowDivider(),
        LockedInEdit(
          locked: editing,
          child: DetailRow(
            label: l.debtSettled,
            trailing: MoneyText(debt.settledAmount, symbol: symbol),
          ),
        ),
        const RowDivider(),
        DetailRow(
          label: l.debtCounterparty,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (working.contactId != null) ...[
                Icon(AppIcons.link, size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(working.name)),
            ],
          ),
          showChevron: editing,
          onTap: editing ? _pickCounterparty : null,
        ),
        const RowDivider(),
        LockedInEdit(
          locked: editing,
          child: DetailRow(
            label: l.debtSource,
            trailing: Text(source),
            showChevron: sourceRoute != null,
            onTap: sourceRoute == null ? null : () => context.push(sourceRoute),
          ),
        ),
        const RowDivider(),
        DetailStacked(
          label: l.debtNote,
          child: InlineField(
            editing: editing,
            controller: _noteCtrl,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: 500,
            onEnterEdit: () => enterEdit(focus: _noteFocus),
            onChanged: (v) =>
                applyTextChange(_Field.note, working.copyWith(note: v)),
          ),
        ),
        if (debt.createdAt != null) ...[
          const RowDivider(),
          LockedInEdit(
            locked: editing,
            child: DetailRow(
              label: l.debtCreatedAt,
              trailing: Text(
                DateFormatter.medium(
                  debt.createdAt!,
                  locale: Localizations.localeOf(context).toLanguageTag(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DebtDraft {
  const _DebtDraft({
    this.amount = '',
    this.note = '',
    this.contactId,
    this.name = '',
  });

  factory _DebtDraft.from(PersonalDebt d) => _DebtDraft(
    amount: AmountField.format(d.amount),
    note: d.note ?? '',
    contactId: d.counterpartyContactId,
    name: d.counterpartyPersonName,
  );

  /// Formatted text, as in the field.
  final String amount;
  final String note;
  final String? contactId;
  final String name;

  _DebtDraft copyWith({
    String? amount,
    String? note,
    String? contactId,
    bool clearContact = false,
    String? name,
  }) => _DebtDraft(
    amount: amount ?? this.amount,
    note: note ?? this.note,
    contactId: clearContact ? null : (contactId ?? this.contactId),
    name: name ?? this.name,
  );

  @override
  bool operator ==(Object other) =>
      other is _DebtDraft &&
      other.amount == amount &&
      other.note == note &&
      other.contactId == contactId &&
      other.name == name;

  @override
  int get hashCode => Object.hash(amount, note, contactId, name);
}
