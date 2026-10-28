import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring.dart';

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
  });

  /// `?kind=debt&person_name=…&contact=…` (the person page's + รายการประจำ).
  factory RecurringPreset.fromQuery(Map<String, String> q) {
    final type = q['type'];
    final personName = q['person_name'];
    return RecurringPreset(
      person: personName == null || personName.isEmpty
          ? null
          : EmbeddedPerson(name: personName, contactId: q['contact']),
      kind: q['kind'] == null ? null : RecurringKind.fromJson(q['kind']),
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

  /// หนี้ with this person (picked already).
  final EmbeddedPerson? person;

  bool get _saving => goalId != null || spare;
}

@immutable
class RecurringDraft {
  const RecurringDraft({
    required this.rule,
    this.kind = RecurringKind.subscription,
    this.name = '',
    this.description = '',
    this.note = '',
    this.amount = '',
    this.iconCode,
    this.type = TransactionType.expense,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.tagIds = const {},
    this.trialUntil,
    this.autoCreate = false,
    this.goalId,
    this.goalPicked = false,
    this.person,
    this.debtSub = DebtEntrySub.record,
    this.direction = DebtEntryDirection.paid,
  });

  factory RecurringDraft.blank({
    RecurringKind kind = RecurringKind.subscription,
    RecurringPreset preset = const RecurringPreset(),
  }) {
    final k =
        preset.kind ??
        (preset._saving ? RecurringKind.saving : null) ??
        switch (preset.type) {
          TransactionType.income => RecurringKind.income,
          TransactionType.transfer => RecurringKind.reminder,
          _ => kind,
        };
    final start = today();
    return RecurringDraft(
      kind: k,
      type: k == RecurringKind.reminder && preset.type != null
          ? (preset.type == TransactionType.transfer
                ? TransactionType.transfer
                : TransactionType.expense)
          : k.defaultType,
      name: preset.name ?? '',
      amount: preset.amount == null || preset.amount! <= 0
          ? ''
          : AmountInput.format(preset.amount!),
      accountId: preset.accountId,
      categoryId: k == RecurringKind.saving ? null : preset.categoryId,
      goalId: preset.goalId,
      goalPicked: preset._saving,
      person: k == RecurringKind.debt ? preset.person : null,
      rule: RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: start,
        monthly: RecurrenceMonthly.onDay(start.day),
        end: k == RecurringKind.installment
            ? const RecurrenceEnd.afterCount(12)
            : const RecurrenceEnd.never(),
      ),
    );
  }

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
    type: r.type,
    accountId: r.account?.id,
    toAccountId: r.toAccount?.id,
    categoryId: r.category?.id,
    tagIds: {for (final t in r.tags) t.id},
    trialUntil: r.trialUntil,
    autoCreate: r.autoCreate,
    goalId: r.goalId,
    goalPicked: r.isSaving,
    person: r.person,
    debtSub: r.debtSub ?? DebtEntrySub.record,
    direction: r.direction ?? DebtEntryDirection.paid,
  );

  final RecurringKind kind;

  /// หนี้ only: the person (a contact or a typed name), จดหนี้ | จ่ายหนี้
  /// and the money's direction (the arrow).
  final EmbeddedPerson? person;
  final DebtEntrySub debtSub;
  final DebtEntryDirection direction;

  bool get isDebt => kind == RecurringKind.debt;

  /// A หนี้ rule needs its person.
  bool get personOk => !isDebt || person != null;
  final RecurrenceRule rule;
  final String name;
  final String description;
  final String note;
  final String amount;
  final IconCode? iconCode;
  final TransactionType type;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final Set<String> tagIds;

  final DateTime? trialUntil;
  final bool autoCreate;

  /// ออมเงิน: the goal (null = ยังไม่จัดสรร once [goalPicked]).
  final String? goalId;

  /// A new saving rule starts with nothing picked: the goal or ยังไม่จัดสรร
  /// has to be chosen.
  final bool goalPicked;

  bool get isTransfer => type == TransactionType.transfer;

  bool get isSaving => kind == RecurringKind.saving;

  bool get goalOk => !isSaving || goalPicked;

  bool get amountOptional => kind == RecurringKind.reminder;

  /// บันทึกอัตโนมัติ needs a fixed amount and the wallet(s).
  /// Auto-create never waits (R12): it books at amount 0 when there is no
  /// amount, so only the wallet is needed.
  bool get canAutoCreate => walletOk || isDebt;

  /// Auto-create with no amount (or a varying one, entered as none) books
  /// 0 every time: the form warns that it isn't a good fit.
  bool get autoCreateWarns {
    final a = AmountInput.parse(amount);
    return autoCreate && canAutoCreate && (a == null || a <= 0);
  }

  RecurringDraft withKind(RecurringKind k) {
    if (k == kind) return this;
    final nextType = switch (k) {
      RecurringKind.income => TransactionType.income,
      RecurringKind.reminder =>
        type == TransactionType.transfer
            ? TransactionType.transfer
            : TransactionType.expense,
      _ => TransactionType.expense,
    };
    var nextRule = rule;
    if (k == RecurringKind.installment &&
        rule.end.kind != RecurrenceEndKind.afterCount) {
      nextRule = rule.copyWith(end: const RecurrenceEnd.afterCount(12));
    }
    final saving = k == RecurringKind.saving;
    final debt = k == RecurringKind.debt;
    // ออมเงิน and หนี้ have no category or tags.
    final noCategory = saving || debt || isSaving || isDebt;
    return RecurringDraft(
      kind: k,
      rule: nextRule,
      name: name,
      description: description,
      note: note,
      amount: amount,
      iconCode: iconCode,
      type: nextType,
      accountId: accountId,
      toAccountId: nextType == TransactionType.transfer ? toAccountId : null,
      categoryId: noCategory || nextType != type ? null : categoryId,
      tagIds: saving || debt ? const {} : tagIds,
      trialUntil: k == RecurringKind.subscription ? trialUntil : null,
      autoCreate: autoCreate,
      goalId: saving ? goalId : null,
      goalPicked: saving && goalPicked,
      person: debt ? person : null,
      debtSub: debtSub,
      direction: direction,
    );
  }

  /// หนี้: the person, the entry kind and / or the direction.
  RecurringDraft withDebt({
    EmbeddedPerson? person,
    DebtEntrySub? sub,
    DebtEntryDirection? direction,
  }) => _with(
    person: person ?? this.person,
    debtSub: sub ?? debtSub,
    direction: direction ?? this.direction,
  );

  RecurringDraft _with({
    EmbeddedPerson? person,
    DebtEntrySub? debtSub,
    DebtEntryDirection? direction,
  }) => RecurringDraft(
    kind: kind,
    rule: rule,
    name: name,
    description: description,
    note: note,
    amount: amount,
    iconCode: iconCode,
    // หนี้: money in when it comes to me (the arrow).
    type: isDebt
        ? ((direction ?? this.direction) == DebtEntryDirection.received
              ? TransactionType.income
              : TransactionType.expense)
        : type,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    tagIds: tagIds,
    trialUntil: trialUntil,
    autoCreate: autoCreate,
    goalId: goalId,
    goalPicked: goalPicked,
    person: person ?? this.person,
    debtSub: debtSub ?? this.debtSub,
    direction: direction ?? this.direction,
  );

  /// Picks the goal (null = ยังไม่จัดสรร).
  RecurringDraft withGoal(String? id) => RecurringDraft(
    kind: kind,
    rule: rule,
    name: name,
    description: description,
    note: note,
    amount: amount,
    iconCode: iconCode,
    type: type,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    tagIds: tagIds,
    trialUntil: trialUntil,
    autoCreate: autoCreate,
    goalId: id,
    goalPicked: true,
  );

  /// A หนี้ rule's wallet is optional (none = ledger-only entries).
  bool get walletOk =>
      isDebt || (accountId != null && (!isTransfer || toAccountId != null));

  bool get countOk =>
      kind != RecurringKind.installment ||
      (rule.end.kind == RecurrenceEndKind.afterCount &&
          (rule.end.count ?? 0) > 0);

  RecurringWrite toWrite() {
    final d = description.trim();
    final n = note.trim();
    final parsed = AmountInput.parse(amount);
    return RecurringWrite(
      name: name.trim(),
      kind: kind,
      type: type,
      description: d.isEmpty ? null : d,
      note: n.isEmpty ? null : n,
      iconCode: iconCode,
      amount: amountOptional ? (parsed ?? 0) : parsed,
      trialUntil: trialUntil,
      accountId: accountId,
      toAccountId: isTransfer ? toAccountId : null,
      categoryId: isTransfer || isSaving || isDebt ? null : categoryId,
      tagIds: isSaving || isDebt ? const [] : tagIds.toList(),
      goalId: isSaving ? goalId : null,
      rule: rule,
      autoCreate: autoCreate && canAutoCreate,
      contactId: isDebt ? person?.contactId : null,
      personName: isDebt ? person?.name : null,
      debtSub: isDebt ? debtSub : null,
      direction: isDebt ? direction : null,
    );
  }

  RecurringDraft copyWith({
    RecurringKind? kind,
    RecurrenceRule? rule,
    String? name,
    String? description,
    String? note,
    String? amount,
    IconCode? iconCode,
    bool clearIcon = false,
    TransactionType? type,
    String? accountId,
    bool clearAccount = false,
    String? toAccountId,
    String? categoryId,
    bool clearCategory = false,
    Set<String>? tagIds,
    DateTime? trialUntil,
    bool clearTrial = false,
    bool? autoCreate,
  }) => RecurringDraft(
    kind: kind ?? this.kind,
    rule: rule ?? this.rule,
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    type: type ?? this.type,
    accountId: clearAccount ? null : (accountId ?? this.accountId),
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    tagIds: tagIds ?? this.tagIds,
    trialUntil: clearTrial ? null : (trialUntil ?? this.trialUntil),
    autoCreate: autoCreate ?? this.autoCreate,
    goalId: goalId,
    goalPicked: goalPicked,
    person: person,
    debtSub: debtSub,
    direction: direction,
  );

  @override
  bool operator ==(Object other) =>
      other is RecurringDraft &&
      other.kind == kind &&
      other.rule == rule &&
      other.name == name &&
      other.description == description &&
      other.note == note &&
      other.amount == amount &&
      other.iconCode == iconCode &&
      other.type == type &&
      other.accountId == accountId &&
      other.toAccountId == toAccountId &&
      other.categoryId == categoryId &&
      other.trialUntil == trialUntil &&
      other.autoCreate == autoCreate &&
      other.goalId == goalId &&
      other.goalPicked == goalPicked &&
      other.person == person &&
      other.debtSub == debtSub &&
      other.direction == direction &&
      setEquals(other.tagIds, tagIds);

  @override
  int get hashCode => Object.hash(
    kind,
    rule,
    name,
    description,
    note,
    amount,
    iconCode,
    type,
    accountId,
    toAccountId,
    categoryId,
    trialUntil,
    autoCreate,
    goalId,
    goalPicked,
    person,
    debtSub,
    direction,
    Object.hashAllUnordered(tagIds),
  );
}
