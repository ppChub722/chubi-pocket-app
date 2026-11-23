import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';
import '../../institutions/domain/institution.dart';
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';
import '../domain/recurring_page.dart';

@immutable
class RecurringPreset {
  const RecurringPreset({
    this.kind,
    this.type,
    this.amount,
    this.categoryId,
    this.name,
    this.accountId,
    this.goalId,
    this.spare = false,
    this.person,
    this.institution,
  });

  /// `?kind=debt&person_name=…&contact=…` or `?kind=debt&institution=…&
  /// institution_name=…` (a counterparty page's + รายการประจำ).
  factory RecurringPreset.fromQuery(Map<String, String> q) {
    final type = q['type'];
    final personName = q['person_name'];
    final institutionId = q['institution'];
    final kind = q['kind'];
    return RecurringPreset(
      person: personName == null || personName.isEmpty
          ? null
          : EmbeddedPerson(name: personName, contactId: q['contact']),
      institution: institutionId == null || institutionId.isEmpty
          ? null
          : InstitutionRef(
              id: institutionId,
              name: q['institution_name'] ?? '',
            ),
      kind: kind == null
          ? null
          : RecurringKind.fromJson(kind, legacyKind: kind),
      type: type == null ? null : TransactionType.fromJson(type),
      amount: double.tryParse(q['amount'] ?? ''),
      categoryId: q['category'],
      name: q['name'],
      accountId: q['account'],
      goalId: q['goal'],
      spare: q['spare'] == '1',
    );
  }

  final RecurringKind? kind;
  final TransactionType? type;
  final double? amount;
  final String? categoryId;
  final String? name;
  final String? accountId;

  /// ออมเงิน into this goal (picked already).
  final String? goalId;

  /// ออมเงิน into ยังไม่จัดสรร (picked already).
  final bool spare;

  /// หนี้ with this person / institution (picked already).
  final EmbeddedPerson? person;
  final InstitutionRef? institution;

  bool get _saving => goalId != null || spare;
}

/// A debt item's plan as the form holds it: typed text until saved.
@immutable
class RecurringPlanDraft extends Equatable {
  const RecurringPlanDraft({
    required this.start,
    this.principal = '',
    this.count = 12,
    this.method = PlanInterestMethod.none,
    this.rate = '',
    this.installmentAmount = '',
    this.cardAccountId,
    this.openingAccountId,
  });

  factory RecurringPlanDraft.from(RecurringPlan p) => RecurringPlanDraft(
    start: p.start,
    principal: AmountInput.format(p.principal),
    count: p.count,
    method: p.method,
    rate: p.rate == null ? '' : _num(p.rate!),
    installmentAmount: p.installmentAmount == null
        ? ''
        : AmountInput.format(p.installmentAmount!),
    cardAccountId: p.cardAccountId,
  );

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  final String principal;
  final int count;
  final DateTime start;
  final PlanInterestMethod method;
  final String rate;
  final String installmentAmount;

  /// ผ่อนผ่านบัตร: the card holds the debt; the item has no line.
  final String? cardAccountId;
  final String? openingAccountId;

  bool get onCard => cardAccountId != null;

  /// Enough to preview / save: a principal, a count and what the method needs.
  bool get ok {
    final p = AmountInput.parse(principal);
    if (p == null || p <= 0 || count <= 0) return false;
    return switch (method) {
      PlanInterestMethod.flat ||
      PlanInterestMethod.reducing => double.tryParse(rate.trim()) != null,
      PlanInterestMethod.fixed =>
        (AmountInput.parse(installmentAmount) ?? 0) > 0,
      _ => true,
    };
  }

  RecurringPlanWrite? toWrite() {
    if (!ok) return null;
    return RecurringPlanWrite(
      principal: AmountInput.parse(principal)!,
      count: count,
      start: start,
      method: method,
      rate: double.tryParse(rate.trim()),
      installmentAmount: AmountInput.parse(installmentAmount),
      cardAccountId: cardAccountId,
      openingAccountId: cardAccountId == null ? openingAccountId : null,
    );
  }

  RecurringPlanDraft copyWith({
    String? principal,
    int? count,
    DateTime? start,
    PlanInterestMethod? method,
    String? rate,
    String? installmentAmount,
    String? cardAccountId,
    bool clearCard = false,
    String? openingAccountId,
  }) => RecurringPlanDraft(
    principal: principal ?? this.principal,
    count: count ?? this.count,
    start: start ?? this.start,
    method: method ?? this.method,
    rate: rate ?? this.rate,
    installmentAmount: installmentAmount ?? this.installmentAmount,
    cardAccountId: clearCard ? null : (cardAccountId ?? this.cardAccountId),
    openingAccountId: openingAccountId ?? this.openingAccountId,
  );

  @override
  List<Object?> get props => [
    principal,
    count,
    start,
    method,
    rate,
    installmentAmount,
    cardAccountId,
    openingAccountId,
  ];
}

/// The item form (0.4.3): the item, its main line (the one the form edits;
/// the item's other lines go back as they are), the counterparty (หนี้: a
/// person or an institution), the plan and the reminders.
@immutable
class RecurringDraft extends Equatable {
  const RecurringDraft({
    required this.rule,
    this.kind = RecurringKind.expense,
    this.name = '',
    this.description = '',
    this.note = '',
    this.amount = '',
    this.iconCode,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.tagIds = const {},
    this.autoCreate = false,
    this.goalId,
    this.goalPicked = false,
    this.person,
    this.institution,
    this.debtSub = DebtEntrySub.record,
    this.direction = DebtEntryDirection.paid,
    this.paidBy,
    this.repaysReminderId,
    this.notifyOnly = false,
    this.lineId,
    this.otherLines = const [],
    this.plan,
    this.reminders = const [],
  });

  factory RecurringDraft.blank({
    RecurringKind kind = RecurringKind.expense,
    RecurringPreset preset = const RecurringPreset(),
  }) {
    final k =
        preset.kind ??
        (preset._saving ? RecurringKind.saving : null) ??
        switch (preset.type) {
          TransactionType.income => RecurringKind.income,
          TransactionType.transfer => RecurringKind.transfer,
          _ => kind,
        };
    final start = today();
    final debt = k == RecurringKind.debt;
    return RecurringDraft(
      kind: k,
      name: preset.name ?? '',
      amount: preset.amount == null || preset.amount! <= 0
          ? ''
          : AmountInput.format(preset.amount!),
      accountId: preset.accountId,
      categoryId: k == RecurringKind.saving ? null : preset.categoryId,
      goalId: preset.goalId,
      goalPicked: preset._saving,
      person: debt && preset.institution == null ? preset.person : null,
      institution: debt ? preset.institution : null,
      rule: RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: start,
        monthly: RecurrenceMonthly.onDay(start.day),
      ),
    );
  }

  /// The detail's item: one line in the form (its main line, else
  /// [lineId]; [newLine] = a blank new line), the other lines kept.
  factory RecurringDraft.fromDetail(
    RecurringDetail d, {
    String? lineId,
    bool newLine = false,
  }) {
    final page = d.page;
    if (page == null) return RecurringDraft.from(d.recurring);
    final main = newLine
        ? null
        : page.lines.where((l) => l.id == lineId).firstOrNull ?? page.mainLine;
    final view = main == null
        ? page.view
        : lineView(page.json, main.json, asItem: true);
    var base = RecurringDraft.from(view);
    if (newLine) {
      base = base._copy(amount: '', autoCreate: false, clearPaidBy: true);
    }
    final cp = page.counterparty;
    return base._copy(
      person: cp == null || cp.isInstitution ? null : cp.asPerson,
      clearPerson: cp == null || cp.isInstitution,
      institution: cp?.institution,
      paidBy: main?.paidBy,
      repaysReminderId: main?.repaysReminderId,
      notifyOnly: main?.notifyOnly ?? false,
      clearRepays: main?.repaysReminderId == null,
      lineId: main?.id,
      otherLines: [
        for (final l in page.lines)
          if (l.id != main?.id) l.toInput(),
      ],
      plan: page.plan == null ? null : RecurringPlanDraft.from(page.plan!),
      reminders: page.reminders,
      direction: page.direction,
    );
  }

  /// One rule's fields (today's rule page, or an item's main line).
  factory RecurringDraft.from(Recurring r) => RecurringDraft(
    kind: r.kind,
    rule: r.rule,
    name: r.name,
    description: r.description ?? '',
    note: r.note ?? '',
    amount: r.amount == null || r.amount! <= 0
        ? ''
        : AmountInput.format(r.amount!),
    iconCode: r.iconCode,
    accountId: r.account?.id,
    toAccountId: r.toAccount?.id,
    categoryId: r.category?.id,
    tagIds: {for (final t in r.tags) t.id},
    autoCreate: r.autoCreate,
    goalId: r.goalId,
    goalPicked: r.isSaving,
    person: r.person,
    paidBy: r.paidBy,
    debtSub: r.debtSub ?? DebtEntrySub.record,
    direction: r.direction ?? DebtEntryDirection.paid,
  );

  final RecurringKind kind;

  /// หนี้ only: the counterparty, a person (a contact or a typed name) or an
  /// institution ([institution] wins).
  final EmbeddedPerson? person;
  final InstitutionRef? institution;

  /// หนี้ only: the main line's จดหนี้ | จ่ายหนี้ and the item's direction
  /// (paid = they owe me).
  final DebtEntrySub debtSub;
  final DebtEntryDirection direction;

  /// คนจ่ายแทน: a person pays the main line for me (no wallet).
  final EmbeddedPerson? paidBy;

  /// The main line's id (null = a new line).
  final String? lineId;

  /// คืนคนจ่ายแทน (0.4.3): the item's person-paid line this one pays back.
  final String? repaysReminderId;

  /// แค่แจ้งเตือน (0.4.3): the rounds book nothing; only the alerts go out.
  final bool notifyOnly;

  /// The item's other lines as `LineInput` JSON, sent back unchanged.
  final List<Map<String, dynamic>> otherLines;

  /// หนี้ only: the installment plan.
  final RecurringPlanDraft? plan;
  final List<RecurringReminder> reminders;

  final RecurrenceRule rule;
  final String name;
  final String description;
  final String note;
  final String amount;
  final PpForgeIconCode? iconCode;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final Set<String> tagIds;
  final bool autoCreate;

  /// ออมเงิน: the goal (null = ยังไม่จัดสรร once [goalPicked]).
  final String? goalId;

  /// A new saving item starts with nothing picked: the goal or ยังไม่จัดสรร
  /// has to be chosen.
  final bool goalPicked;

  bool get isDebt => kind == RecurringKind.debt;

  bool get isTransfer => kind == RecurringKind.transfer;

  bool get isSaving => kind == RecurringKind.saving;

  /// The money side of a round: a debt's by its direction (received = in).
  TransactionType get type => isDebt
      ? (direction == DebtEntryDirection.received
            ? TransactionType.income
            : TransactionType.expense)
      : kind.defaultType;

  /// A หนี้ item needs its counterparty.
  bool get personOk => !isDebt || person != null || institution != null;

  bool get goalOk => !isSaving || goalPicked;

  bool get amountOptional => notifyOnly || kind.amountOptional;

  /// คนจ่ายแทน is for my expenses (and a debt): รายจ่าย / ค่าสมาชิก / บิล /
  /// หนี้.
  bool get canPaidBy => kind == RecurringKind.expense;

  /// ผ่อนผ่านบัตร: the item has no line (paid with the card's statement).
  bool get cardPlan => isDebt && (plan?.onCard ?? false);

  /// A หนี้ line's wallet is optional (none = ledger-only rows); a person
  /// paying needs none.
  bool get walletOk =>
      cardPlan ||
      isDebt ||
      paidBy != null ||
      (accountId != null && (!isTransfer || toAccountId != null));

  /// The plan, when there is one, is complete.
  bool get planOk => !isDebt || plan == null || plan!.ok;

  /// บันทึกอัตโนมัติ needs the wallet(s) (or a person paying).
  bool get canAutoCreate => walletOk || isDebt;

  /// Auto-create with no amount books 0 every time: the form warns.
  bool get autoCreateWarns {
    final a = AmountInput.parse(amount);
    return autoCreate && canAutoCreate && (a == null || a <= 0);
  }

  RecurringDraft withKind(RecurringKind k) {
    if (k == kind) return this;
    final saving = k == RecurringKind.saving;
    final debt = k == RecurringKind.debt;
    final transfer = k == RecurringKind.transfer;
    // ออมเงิน / หนี้ / โอน have no category; ออมเงิน / หนี้ no tags.
    final noCategory =
        saving || debt || transfer || k.defaultType != kind.defaultType;
    final paid = k == RecurringKind.expense;
    return _copy(
      kind: k,
      clearToAccount: !transfer,
      clearCategory: noCategory,
      tagIds: saving || debt ? const {} : tagIds,
      goalId: saving ? goalId : null,
      clearGoal: !saving,
      goalPicked: saving && goalPicked,
      clearPerson: !debt,
      clearInstitution: !debt,
      clearPaidBy: !paid,
      clearPlan: !debt,
    );
  }

  /// หนี้: the person, the entry kind and / or the direction. A person
  /// replaces an institution.
  RecurringDraft withDebt({
    EmbeddedPerson? person,
    DebtEntrySub? sub,
    DebtEntryDirection? direction,
  }) => _copy(
    person: person,
    clearInstitution: person != null,
    debtSub: sub,
    direction: direction,
  );

  /// หนี้ with an institution (replaces a person).
  RecurringDraft withInstitution(InstitutionRef i) =>
      _copy(institution: i, clearPerson: true);

  /// คนจ่ายแทน (null = back to a wallet).
  RecurringDraft withPaidBy(EmbeddedPerson? p) => _copy(
    paidBy: p,
    clearPaidBy: p == null,
    clearAccount: p != null,
    clearRepays: p != null,
  );

  /// แค่แจ้งเตือน on / off (a notice: no one pays, nothing is paid back, no
  /// auto-create).
  RecurringDraft withNotifyOnly(bool on) => _copy(
    notifyOnly: on,
    clearPaidBy: on,
    clearRepays: on,
    autoCreate: on ? false : null,
  );

  /// คืนคนจ่ายแทน: pays back that person-paid line (null = a plain expense).
  RecurringDraft withRepays(String? lineId) => _copy(
    repaysReminderId: lineId,
    clearRepays: lineId == null,
    clearPaidBy: lineId != null,
  );

  /// Picks the goal (null = ยังไม่จัดสรร).
  RecurringDraft withGoal(String? id) =>
      _copy(goalId: id, clearGoal: id == null, goalPicked: true);

  RecurringDraft withPlan(RecurringPlanDraft? p) =>
      _copy(plan: p, clearPlan: p == null);

  RecurringDraft withReminders(List<RecurringReminder> r) =>
      _copy(reminders: r);

  RecurringWrite toWrite() {
    final d = description.trim();
    final n = note.trim();
    final parsed = AmountInput.parse(amount);
    final line = RecurringLineWrite(
      id: lineId,
      amount: amountOptional ? (parsed ?? 0) : parsed,
      accountId: paidBy == null ? accountId : null,
      paidByContactId: paidBy?.contactId,
      paidByName: paidBy?.name,
      toAccountId: isTransfer ? toAccountId : null,
      // 0.4.3: a debt item's rounds pay its debt back (repay / collect)
      debtSub: isDebt ? DebtEntrySub.repay : null,
      repaysReminderId: paidBy == null && !notifyOnly ? repaysReminderId : null,
      notifyOnly: notifyOnly,
      rule: rule,
      autoCreate: autoCreate && canAutoCreate,
    );
    return RecurringWrite(
      name: name.trim(),
      kind: kind,
      description: d.isEmpty ? null : d,
      note: n.isEmpty ? null : n,
      iconCode: iconCode,
      categoryId: categoryId,
      tagIds: tagIds.toList(),
      goalId: goalId,
      contactId: person?.contactId,
      personName: person?.name,
      institutionId: institution?.id,
      direction: isDebt ? direction : null,
      plan: isDebt ? plan?.toWrite() : null,
      reminders: reminders,
      lines: cardPlan ? const [] : [line.toJson(), ...otherLines],
    );
  }

  RecurringDraft copyWith({
    RecurringKind? kind,
    RecurrenceRule? rule,
    String? name,
    String? description,
    String? note,
    String? amount,
    PpForgeIconCode? iconCode,
    bool clearIcon = false,
    String? accountId,
    bool clearAccount = false,
    String? toAccountId,
    String? categoryId,
    bool clearCategory = false,
    Set<String>? tagIds,
    bool? autoCreate,
  }) => _copy(
    kind: kind,
    rule: rule,
    name: name,
    description: description,
    note: note,
    amount: amount,
    iconCode: iconCode,
    clearIcon: clearIcon,
    accountId: accountId,
    clearAccount: clearAccount,
    clearPaidBy: accountId != null,
    toAccountId: toAccountId,
    categoryId: categoryId,
    clearCategory: clearCategory,
    tagIds: tagIds,
    autoCreate: autoCreate,
  );

  RecurringDraft _copy({
    RecurringKind? kind,
    RecurrenceRule? rule,
    String? name,
    String? description,
    String? note,
    String? amount,
    PpForgeIconCode? iconCode,
    bool clearIcon = false,
    String? accountId,
    bool clearAccount = false,
    String? toAccountId,
    bool clearToAccount = false,
    String? categoryId,
    bool clearCategory = false,
    Set<String>? tagIds,
    bool? autoCreate,
    String? goalId,
    bool clearGoal = false,
    bool? goalPicked,
    EmbeddedPerson? person,
    bool clearPerson = false,
    InstitutionRef? institution,
    bool clearInstitution = false,
    DebtEntrySub? debtSub,
    DebtEntryDirection? direction,
    EmbeddedPerson? paidBy,
    bool clearPaidBy = false,
    String? repaysReminderId,
    bool clearRepays = false,
    bool? notifyOnly,
    String? lineId,
    List<Map<String, dynamic>>? otherLines,
    RecurringPlanDraft? plan,
    bool clearPlan = false,
    List<RecurringReminder>? reminders,
  }) => RecurringDraft(
    kind: kind ?? this.kind,
    rule: rule ?? this.rule,
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    accountId: clearAccount ? null : (accountId ?? this.accountId),
    toAccountId: clearToAccount ? null : (toAccountId ?? this.toAccountId),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    tagIds: tagIds ?? this.tagIds,
    autoCreate: autoCreate ?? this.autoCreate,
    goalId: clearGoal ? null : (goalId ?? this.goalId),
    goalPicked: goalPicked ?? this.goalPicked,
    person: clearPerson ? null : (person ?? this.person),
    institution: clearInstitution ? null : (institution ?? this.institution),
    debtSub: debtSub ?? this.debtSub,
    direction: direction ?? this.direction,
    paidBy: clearPaidBy ? null : (paidBy ?? this.paidBy),
    repaysReminderId: clearRepays
        ? null
        : (repaysReminderId ?? this.repaysReminderId),
    notifyOnly: notifyOnly ?? this.notifyOnly,
    lineId: lineId ?? this.lineId,
    otherLines: otherLines ?? this.otherLines,
    plan: clearPlan ? null : (plan ?? this.plan),
    reminders: reminders ?? this.reminders,
  );

  @override
  List<Object?> get props => [
    kind,
    rule,
    name,
    description,
    note,
    amount,
    iconCode,
    accountId,
    toAccountId,
    categoryId,
    tagIds,
    autoCreate,
    goalId,
    goalPicked,
    person,
    institution,
    debtSub,
    direction,
    paidBy,
    lineId,
    otherLines,
    plan,
    reminders,
  ];
}
