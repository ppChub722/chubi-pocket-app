part of 'draft_form.dart';

/// What the user picks as the kind of scheduled entry. Maps to the
/// (entry_type, interest_rate) pair on save:
/// - recurring → entry_type=recurring
/// - installment → entry_type=installment, no interest
/// - loan → entry_type=installment, interest_rate > 0
enum ScheduleVariant { recurring, installment, loan }

/// What [DraftForm]'s scheduled mode needs. A scheduled entry is a template
/// the server turns into a transaction every cycle — it has the shared
/// type · amount · category + wallet · note, plus its own fields:
///
///   [ ประจำ | ผ่อนชำระ | เงินกู้ ] · type · amount
///   icon + name · category + wallet cards (both required) · note
///   รอบ: [ สัปดาห์ | เดือน | ปี ] · วันที่งวดถัดไป
///   ข้อมูลการผ่อน (installment / loan): ยอดรวม · เงินดาวน์ · งวดทั้งหมด /
///     งวดที่เหลือ · ดอกเบี้ย (loan)
class DraftSchedule {
  const DraftSchedule({this.editing = false});

  /// Editing a saved entry: the variant and type are fixed (spec §3.5 —
  /// `entry_type` / `type` can't change on PUT).
  final bool editing;
}

/// The fields only a scheduled entry has — [DraftFormController.schedule].
class ScheduleFields extends ChangeNotifier {
  ScheduleFields() {
    for (final t in [
      name,
      totalAmount,
      downPayment,
      totalInstallments,
      remainingInstallments,
      interestRate,
    ]) {
      t.addListener(notifyListeners);
    }
  }

  final name = TextEditingController();
  IconCode? iconCode;
  ScheduleVariant variant = ScheduleVariant.recurring;
  BillingCycle cycle = BillingCycle.monthly;
  DateTime nextBillingDate = DateUtils.dateOnly(
    DateTime.now(),
  ).add(const Duration(days: 7));

  // Installment / loan only.
  final totalAmount = TextEditingController();
  final downPayment = TextEditingController();
  final totalInstallments = TextEditingController();
  final remainingInstallments = TextEditingController();
  final interestRate = TextEditingController();

  /// "งวดที่เหลือ" follows "งวดทั้งหมด" on create until the user edits it.
  bool _remainingTouched = false;

  /// Set by the first save attempt — fields show their errors from then on.
  bool showErrors = false;

  bool get isInstallment => variant != ScheduleVariant.recurring;
  bool get isLoan => variant == ScheduleVariant.loan;

  void setIcon(IconCode? c) {
    iconCode = c;
    notifyListeners();
  }

  void setVariant(ScheduleVariant v) {
    variant = v;
    notifyListeners();
  }

  void setCycle(BillingCycle c) {
    cycle = c;
    notifyListeners();
  }

  void setNextBillingDate(DateTime d) {
    nextBillingDate = d;
    notifyListeners();
  }

  void revealErrors() {
    showErrors = true;
    notifyListeners();
  }

  void _onTotalInstallmentsChanged(String v, {required bool editing}) {
    if (!editing && !_remainingTouched) remainingInstallments.text = v;
  }

  // ── Validation (same rules as the old scheduled form) ──

  String? nameError(AppLocalizations l) =>
      name.text.trim().isEmpty ? l.scheduledFormNameRequired : null;

  String? totalAmountError(AppLocalizations l) {
    if (!isInstallment) return null;
    final n = AmountField.parse(totalAmount.text);
    return n == null || n <= 0 ? l.scheduledFormAmountInvalid : null;
  }

  String? totalInstallmentsError(AppLocalizations l) {
    if (!isInstallment) return null;
    final n = int.tryParse(totalInstallments.text.trim());
    return n == null || n <= 0 ? l.scheduledFormInstallmentsInvalid : null;
  }

  String? remainingInstallmentsError(AppLocalizations l) {
    if (!isInstallment) return null;
    final n = int.tryParse(remainingInstallments.text.trim());
    final total = int.tryParse(totalInstallments.text.trim());
    if (n == null || n < 0) return l.scheduledFormInstallmentsInvalid;
    if (total != null && n > total) return l.scheduledFormRemainingExceeds;
    return null;
  }

  String? interestRateError(AppLocalizations l) {
    if (!isLoan) return null;
    final n = double.tryParse(interestRate.text.trim());
    return n == null || n <= 0 || n > 99.99
        ? l.scheduledFormInterestInvalid
        : null;
  }

  @override
  void dispose() {
    name.dispose();
    totalAmount.dispose();
    downPayment.dispose();
    totalInstallments.dispose();
    remainingInstallments.dispose();
    interestRate.dispose();
    super.dispose();
  }
}

/// Scheduled mode on the shared controller: prefill, the close-guard
/// snapshot, validation and the entry to send.
extension DraftScheduledX on DraftFormController {
  /// Loads a saved entry for editing.
  void prefillScheduled(
    ScheduledTransaction e, {
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    final s = schedule;
    type = e.type == ScheduledTransactionType.income
        ? TransactionType.income
        : TransactionType.expense;
    amount.text = AmountField.format(e.amount);
    note.text = e.note ?? '';
    accountTouched = true;
    account = accounts.where((a) => a.id == e.accountId).firstOrNull;
    category = categories.where((c) => c.id == e.categoryId).firstOrNull;
    s.name.text = e.name;
    s.iconCode = e.iconCode;
    s.cycle = e.billingCycle;
    s.nextBillingDate =
        DateTime.tryParse(e.nextBillingDate) ?? s.nextBillingDate;
    if (e.isInstallment) {
      s.variant = e.isLoan ? ScheduleVariant.loan : ScheduleVariant.installment;
      if (e.totalAmount != null) {
        s.totalAmount.text = AmountField.format(e.totalAmount!);
      }
      if (e.downPayment != null && e.downPayment! > 0) {
        s.downPayment.text = AmountField.format(e.downPayment!);
      }
      s.totalInstallments.text = e.totalInstallments?.toString() ?? '';
      s.remainingInstallments.text = e.remainingInstallments?.toString() ?? '';
      if (e.interestRate != null) {
        s.interestRate.text = e.interestRate!.toString();
      }
    }
  }

  /// The fields as a comparable snapshot (the close guard). The default
  /// wallet shown on create isn't a change until the user picks one.
  String scheduledSnapshot() {
    final s = schedule;
    return [
      type.name,
      amount.text,
      category?.id,
      accountTouched ? account?.id : null,
      note.text.trim(),
      s.name.text.trim(),
      s.iconCode?.toJson().toString(),
      s.variant.name,
      s.cycle.name,
      _ymd(s.nextBillingDate),
      if (s.isInstallment) ...[
        s.totalAmount.text,
        s.downPayment.text,
        s.totalInstallments.text,
        s.remainingInstallments.text,
        if (s.isLoan) s.interestRate.text,
      ],
    ].join('|');
  }

  /// The first rule the server would reject, in on-screen order; null =
  /// ready to save.
  String? scheduledProblem(AppLocalizations l) {
    final s = schedule;
    String named(String label, String msg) => '$label: $msg';
    if (amountValue <= 0) return l.quickAmountRequired;
    final nameErr = s.nameError(l);
    if (nameErr != null) return named(l.scheduledFormNameLabel, nameErr);
    if (category == null) return l.scheduledFormCategoryRequired;
    if (account == null) return l.scheduledFormAccountRequired;
    final checks = <(String, String?)>[
      (l.scheduledFormTotalAmountLabel, s.totalAmountError(l)),
      (l.scheduledFormTotalInstallmentsLabel, s.totalInstallmentsError(l)),
      (
        l.scheduledFormRemainingInstallmentsLabel,
        s.remainingInstallmentsError(l),
      ),
      (l.scheduledFormInterestRateLabel, s.interestRateError(l)),
    ];
    for (final (label, err) in checks) {
      if (err != null) return named(label, err);
    }
    return null;
  }

  /// The entry to create / update — call after [scheduledProblem] is null.
  /// [initial] = the saved entry being edited (keeps its id and status).
  ScheduledTransaction toScheduled({ScheduledTransaction? initial}) {
    final s = schedule;
    final installment = s.isInstallment;
    final n = note.text.trim();
    return ScheduledTransaction(
      id: initial?.id ?? 'draft',
      name: s.name.text.trim(),
      type: type == TransactionType.income
          ? ScheduledTransactionType.income
          : ScheduledTransactionType.expense,
      entryType: installment
          ? ScheduledEntryType.installment
          : ScheduledEntryType.recurring,
      amount: amountValue,
      accountId: account!.id,
      categoryId: category?.id,
      billingCycle: s.cycle,
      nextBillingDate: _ymd(s.nextBillingDate),
      status: initial?.status ?? ScheduledStatus.active,
      note: n.isEmpty ? null : n,
      iconCode: s.iconCode,
      totalAmount: installment ? AmountField.parse(s.totalAmount.text) : null,
      downPayment: installment
          ? AmountField.parse(s.downPayment.text) ?? 0
          : null,
      totalInstallments: installment
          ? int.tryParse(s.totalInstallments.text.trim())
          : null,
      remainingInstallments: installment
          ? int.tryParse(s.remainingInstallments.text.trim())
          : null,
      interestRate: s.isLoan
          ? double.tryParse(s.interestRate.text.trim())
          : null,
    );
  }
}

class _ScheduledForm extends StatelessWidget {
  const _ScheduledForm({
    required this.controller,
    required this.schedule,
    required this.compact,
    required this.autofocus,
  });

  final DraftFormController controller;
  final DraftSchedule schedule;
  final bool compact;
  final bool autofocus;

  Future<void> _pickCategory(BuildContext context) async {
    final c = controller;
    final r = await showCategoryPickerSheet(
      context: context,
      categories: context.read<CategoriesCubit>().state.categories,
      type: c.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      selected: c.category,
      // Required here — the generated transactions take their icon from it.
      allowNone: false,
    );
    if (r is CategoryPickerSelected) c.setCategory(r.category);
  }

  Future<void> _pickAccount(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final c = controller;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: context.read<AccountsCubit>().state.accounts,
      selected: c.account,
      title: l.scheduledFormAccountLabel,
    );
    if (r is AccountPickerSelected) c.setAccount(r.account);
  }

  Future<void> _pickIcon(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final s = controller.schedule;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: s.iconCode,
      iconSectionLabel: l.scheduledFormIconLabel,
    );
    if (r is IconMakerSelected) {
      s.setIcon(r.iconCode);
    } else if (r is IconMakerRemoved) {
      s.setIcon(null);
    }
  }

  Future<void> _pickNextBilling(BuildContext context) async {
    final s = controller.schedule;
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: s.nextBillingDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (d != null) s.setNextBillingDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locked = schedule.editing;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final s = c.schedule;
        final err = s.showErrors;
        const money = TextInputType.numberWithOptions(decimal: true);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectCardGroup<ScheduleVariant>(
              selected: s.variant,
              onChanged: locked ? null : s.setVariant,
              columns: 3,
              options: [
                SelectCardOption(
                  value: ScheduleVariant.recurring,
                  label: l.scheduledVariantRecurring,
                  icon: AppIcons.scheduled,
                ),
                SelectCardOption(
                  value: ScheduleVariant.installment,
                  label: l.scheduledVariantInstallment,
                  icon: AppIcons.creditCard,
                ),
                SelectCardOption(
                  value: ScheduleVariant.loan,
                  label: l.scheduledVariantLoan,
                  icon: AppIcons.bank,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _TypeSwitch(
              type: c.type,
              allowTransfer: false,
              onChanged: locked ? null : c.setType,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.isInstallment
                  ? l.scheduledFormPaymentLabel
                  : l.scheduledFormAmountLabel,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            _AmountInput(
              controller: c.amount,
              type: c.type,
              compact: compact,
              autofocus: autofocus,
            ),
            if (err && c.amountValue <= 0)
              Text(
                l.scheduledFormAmountInvalid,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableCircle(
                  size: 56,
                  onTap: () => _pickIcon(context),
                  child: IconDisplay(
                    type: IconType.category,
                    size: 56,
                    iconCode: s.iconCode,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: s.name,
                    label: l.scheduledFormNameLabel,
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    errorText: err ? s.nameError(l) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CategoryPickCard(
                    category: c.category,
                    label: l.scheduledFormCategoryLabel,
                    placeholder: l.scheduledFormCategoryRequired,
                    errorText: err && c.category == null
                        ? l.scheduledFormCategoryRequired
                        : null,
                    onTap: () => _pickCategory(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: WalletPickCard(
                    account: c.account,
                    label: l.scheduledFormAccountLabel,
                    placeholder: l.scheduledFormAccountRequired,
                    errorText: err && c.account == null
                        ? l.scheduledFormAccountRequired
                        : null,
                    onTap: () => _pickAccount(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: c.note,
              maxLength: 200,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: l.scheduledFormNoteLabel,
                counterText: '',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            SectionHeader(
              title: l.scheduledFormCycleLabel,
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
            ),
            SelectCardGroup<BillingCycle>(
              selected: s.cycle,
              onChanged: s.setCycle,
              options: [
                // Daily isn't offered (BE-only) — kept when an entry
                // already has it so the group still shows its value.
                if (s.cycle == BillingCycle.daily)
                  SelectCardOption(
                    value: BillingCycle.daily,
                    label: l.scheduledCycleDaily,
                  ),
                SelectCardOption(
                  value: BillingCycle.weekly,
                  label: l.scheduledCycleWeekly,
                ),
                SelectCardOption(
                  value: BillingCycle.monthly,
                  label: l.scheduledCycleMonthly,
                ),
                SelectCardOption(
                  value: BillingCycle.yearly,
                  label: l.scheduledCycleYearly,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            PickerTile(
              label: l.scheduledFormNextBillingLabel,
              value: DateFormatter.medium(
                s.nextBillingDate,
                locale: Localizations.localeOf(context).toLanguageTag(),
              ),
              leading: const Icon(AppIcons.date),
              onTap: () => _pickNextBilling(context),
            ),
            if (s.isInstallment) ...[
              SectionHeader(
                title: l.scheduledFormInstallmentSection,
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
              ),
              AppTextField(
                controller: s.totalAmount,
                label: l.scheduledFormTotalAmountLabel,
                helper: s.isLoan
                    ? l.scheduledFormTotalAmountHelperLoan
                    : l.scheduledFormTotalAmountHelper,
                prefixIcon: AppIcons.cash,
                keyboardType: money,
                inputFormatters: [ThousandsInputFormatter()],
                errorText: err ? s.totalAmountError(l) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: s.downPayment,
                label: l.scheduledFormDownPaymentLabel,
                prefixIcon: AppIcons.cash,
                keyboardType: money,
                inputFormatters: [ThousandsInputFormatter()],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: s.totalInstallments,
                      label: l.scheduledFormTotalInstallmentsLabel,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) =>
                          s._onTotalInstallmentsChanged(v, editing: locked),
                      errorText: err ? s.totalInstallmentsError(l) : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: s.remainingInstallments,
                      label: l.scheduledFormRemainingInstallmentsLabel,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => s._remainingTouched = true,
                      errorText: err ? s.remainingInstallmentsError(l) : null,
                    ),
                  ),
                ],
              ),
              if (s.isLoan) ...[
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: s.interestRate,
                  label: l.scheduledFormInterestRateLabel,
                  keyboardType: money,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  suffix: const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('%'),
                  ),
                  errorText: err ? s.interestRateError(l) : null,
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
