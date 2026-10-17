import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring.dart';

/// The create-form presets of `/recurring/new?...` (owner 2026-10-17: the
/// picker's "+ สร้างรายการประจำใหม่จากรายการนี้" opens the form filled from a
/// transaction): any of them may be absent.
@immutable
class RecurringPreset {
  const RecurringPreset({
    this.kind,
    this.type,
    this.amount,
    this.categoryId,
    this.name,
    this.accountId,
  });

  /// Reads `kind`, `type`, `amount`, `category` (id), `name`, `account` (id).
  factory RecurringPreset.fromQuery(Map<String, String> q) {
    final type = q['type'];
    return RecurringPreset(
      kind: q['kind'] == null ? null : RecurringKind.fromJson(q['kind']),
      type: type == null ? null : TransactionType.fromJson(type),
      amount: double.tryParse(q['amount'] ?? ''),
      categoryId: q['category'],
      name: q['name'],
      accountId: q['account'],
    );
  }

  final RecurringKind? kind;
  final TransactionType? type;
  final double? amount;
  final String? categoryId;
  final String? name;
  final String? accountId;
}

/// The editing snapshot of the recurring form (dirty check + undo).
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
  });

  /// A blank form for [kind]: monthly on today's day, no end (an installment
  /// starts at 12 payments).
  factory RecurringDraft.blank({
    RecurringKind kind = RecurringKind.subscription,
    RecurringPreset preset = const RecurringPreset(),
  }) {
    // A transaction's type picks the kind when none was asked for: income →
    // รายรับ, transfer → เตือนจ่าย (the only kind that can transfer).
    final k =
        preset.kind ??
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
      categoryId: preset.categoryId,
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
  );

  final RecurringKind kind;
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

  /// Subscription only.
  final DateTime? trialUntil;

  bool get isTransfer => type == TransactionType.transfer;

  /// An amount is optional for a reminder only.
  bool get amountOptional => kind == RecurringKind.reminder;

  /// Switching the kind switches the money direction with it (a reminder
  /// keeps expense / transfer) and gives an installment its count.
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
      // A category belongs to its direction.
      categoryId: nextType == type ? categoryId : null,
      tagIds: tagIds,
      trialUntil: k == RecurringKind.subscription ? trialUntil : null,
    );
  }

  /// A change to what the items carry (not the rule / name / icon): the save
  /// asks which items take it.
  bool valuesDiffer(RecurringDraft o) =>
      description.trim() != o.description.trim() ||
      note.trim() != o.note.trim() ||
      AmountInput.parse(amount) != AmountInput.parse(o.amount) ||
      kind != o.kind ||
      type != o.type ||
      accountId != o.accountId ||
      toAccountId != o.toAccountId ||
      categoryId != o.categoryId ||
      !setEquals(tagIds, o.tagIds);

  /// Missing parts the save needs: a wallet (and a target for a transfer), an
  /// amount (a reminder's is optional), a count (an installment).
  bool get walletOk =>
      accountId != null && (!isTransfer || toAccountId != null);

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
      categoryId: isTransfer ? null : categoryId,
      tagIds: tagIds.toList(),
      rule: rule,
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
    String? toAccountId,
    String? categoryId,
    bool clearCategory = false,
    Set<String>? tagIds,
    DateTime? trialUntil,
    bool clearTrial = false,
  }) => RecurringDraft(
    kind: kind ?? this.kind,
    rule: rule ?? this.rule,
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    tagIds: tagIds ?? this.tagIds,
    trialUntil: clearTrial ? null : (trialUntil ?? this.trialUntil),
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
    Object.hashAllUnordered(tagIds),
  );
}
