import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../accounts/domain/account_type.dart';
import '../../institutions/domain/institution.dart';
import '../../pending/domain/pending_transaction.dart' show TagRef;
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import 'recurrence_rule.dart';
import 'recurring.dart';
import 'recurring_page.dart';

/// One rule as the rule page edits it (spec §3 rule page; mock RuleSheet /
/// RuleVariants): the money type, the amount (fixed / asked), category |
/// wallet + tags as quick create, from → to, goal, the debt target, the
/// schedule and the two switches. [toJson] = the BE's \`RecurringRuleInput\`.
class RuleDraft extends Equatable {
  const RuleDraft({
    required this.type,
    required this.rule,
    this.id,
    this.amount,
    this.ask = false,
    this.category,
    this.tags = const [],
    this.account,
    this.paidBy,
    this.toAccount,
    this.goal,
    this.goalPicked = false,
    this.person,
    this.institution,
    this.planId,
    this.planName,
    this.direction = DebtEntryDirection.received,
    this.debtRecord = false,
    this.repaysRuleId,
    this.notify,
    this.autoAccept,
  });

  /// A new rule starting [start], monthly on its day.
  factory RuleDraft.blank(RecurringKind type, {DateTime? start}) {
    final s = start ?? today();
    return RuleDraft(
      type: type,
      rule: RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: s,
        monthDays: {s.day},
      ),
    );
  }

  /// An existing rule (its view from the BE).
  factory RuleDraft.fromLine(RecurringLine line) {
    final v = line.view;
    final j = line.json;
    final cp = line.counterparty;
    final dir = j['debt_direction'];
    final cat = v.category;
    return RuleDraft(
      id: line.id,
      type: RecurringKind.fromJson(j['type'] as String?),
      rule: v.rule,
      amount: (j['amount'] as num?)?.toDouble(),
      ask: line.amountMode == 'ask',
      category: cat,
      tags: v.tags,
      account: v.account,
      paidBy: line.paidBy,
      toAccount: v.toAccount,
      goal: v.goal,
      goalPicked: v.goal != null || j['type'] == 'saving',
      person: cp?.institution == null ? cp?.asPerson : null,
      institution: cp?.institution,
      planId: line.debtPlanId,
      direction: dir is String
          ? DebtEntryDirection.parse(dir)
          : DebtEntryDirection.received,
      debtRecord: j['debt_kind'] == 'debt',
      repaysRuleId: line.repaysReminderId,
      notify: line.notify,
      autoAccept: line.autoAccept,
    );
  }

  /// null = a new rule.
  final String? id;
  final RecurringKind type;
  final RecurrenceRule rule;

  /// Fixed: every round's amount; asked: the hint each round starts with.
  final double? amount;

  /// ใส่ทุกงวด: the amount is typed on each round (expense / transfer / a
  /// person repayment); auto-accept is then always off.
  final bool ask;
  final EmbeddedCategory? category;
  final List<TagRef> tags;
  final AccountRef? account;

  /// คนจ่ายแทน: the person who pays for me (an expense, no wallet).
  final EmbeddedPerson? paidBy;
  final AccountRef? toAccount;
  final SavingGoalRef? goal;

  /// Saving: a goal was picked (null goal = ยังไม่จัดสรร).
  final bool goalPicked;
  final EmbeddedPerson? person;
  final InstitutionRef? institution;

  /// A plan's rule: its creditor, direction and amount are the plan's.
  final String? planId;
  final String? planName;

  /// The debt's side: received = I owe them, paid = they owe me.
  final DebtEntryDirection direction;

  /// จดหนี้ (borrow / lend) instead of จ่ายหนี้ (repay / collect).
  final bool debtRecord;
  final String? repaysRuleId;

  /// null = the user's default.
  final bool? notify;
  final bool? autoAccept;

  bool get isNew => id == null;

  /// The amount follows something else: a plan's installments, or the rule
  /// it repays.
  bool get amountFollows => planId != null || repaysRuleId != null;

  /// Which amount modes the type offers (mock RuleVariants): saving and a
  /// plan / payback take none of the switch.
  bool get canAsk =>
      !amountFollows &&
      (type == RecurringKind.expense ||
          type == RecurringKind.transfer ||
          (type == RecurringKind.debt && !debtRecord && institution == null));

  /// A transfer into a card wallet = the card's bill.
  bool get isCardBill =>
      type == RecurringKind.transfer &&
      (toAccount?.type == AccountType.creditCard ||
          toAccount?.type == AccountType.payLater);

  RuleDraft copyWith({
    RecurringKind? type,
    RecurrenceRule? rule,
    double? amount,
    bool clearAmount = false,
    bool? ask,
    EmbeddedCategory? category,
    bool clearCategory = false,
    List<TagRef>? tags,
    AccountRef? account,
    bool clearAccount = false,
    EmbeddedPerson? paidBy,
    bool clearPaidBy = false,
    AccountRef? toAccount,
    bool clearToAccount = false,
    SavingGoalRef? goal,
    bool clearGoal = false,
    bool? goalPicked,
    EmbeddedPerson? person,
    bool clearPerson = false,
    InstitutionRef? institution,
    bool clearInstitution = false,
    String? planId,
    String? planName,
    bool clearPlan = false,
    DebtEntryDirection? direction,
    bool? debtRecord,
    String? repaysRuleId,
    bool clearRepays = false,
    bool? notify,
    bool clearNotify = false,
    bool? autoAccept,
    bool clearAutoAccept = false,
  }) => RuleDraft(
    id: id,
    type: type ?? this.type,
    rule: rule ?? this.rule,
    amount: clearAmount ? null : (amount ?? this.amount),
    ask: ask ?? this.ask,
    category: clearCategory ? null : (category ?? this.category),
    tags: tags ?? this.tags,
    account: clearAccount ? null : (account ?? this.account),
    paidBy: clearPaidBy ? null : (paidBy ?? this.paidBy),
    toAccount: clearToAccount ? null : (toAccount ?? this.toAccount),
    goal: clearGoal ? null : (goal ?? this.goal),
    goalPicked: goalPicked ?? this.goalPicked,
    person: clearPerson ? null : (person ?? this.person),
    institution: clearInstitution ? null : (institution ?? this.institution),
    planId: clearPlan ? null : (planId ?? this.planId),
    planName: clearPlan ? null : (planName ?? this.planName),
    direction: direction ?? this.direction,
    debtRecord: debtRecord ?? this.debtRecord,
    repaysRuleId: clearRepays ? null : (repaysRuleId ?? this.repaysRuleId),
    notify: clearNotify ? null : (notify ?? this.notify),
    autoAccept: clearAutoAccept ? null : (autoAccept ?? this.autoAccept),
  );

  /// The BE's \`RecurringRuleInput\` (a full replace).
  Map<String, dynamic> toJson() {
    final debt = type == RecurringKind.debt;
    final saving = type == RecurringKind.saving;
    final noCategory = debt || saving || type == RecurringKind.transfer;
    final asked = ask && canAsk;
    return {
      'id': ?id,
      'type': type.toJson(),
      'category_id': noCategory ? null : category?.id,
      'tag_ids': debt || saving
          ? const <String>[]
          : [for (final t in tags) t.id],
      'goal_id': saving ? goal?.id : null,
      if (debt && planId != null)
        'debt_plan_id': planId
      else if (debt) ...{
        'counterparty': institution != null
            ? {'institution_id': institution!.id}
            : person?.contactId != null
            ? {'contact_id': person!.contactId}
            : {'person_name': person?.name},
        'debt_direction': direction.wire,
        'debt_kind': debtRecord ? 'debt' : 'repayment',
      },
      'repays_rule_id': ?repaysRuleId,
      if (!amountFollows) 'amount_mode': asked ? 'ask' : 'fixed',
      if (!amountFollows && (amount ?? 0) > 0) 'amount': amount,
      'source': paidBy != null
          ? {
              'paid_by': {
                'contact_id': paidBy!.contactId,
                'person_name': paidBy!.name,
              },
            }
          : {'account_id': account?.id},
      'to_account_id': type == RecurringKind.transfer ? toAccount?.id : null,
      'schedule': scheduleToJson(rule),
      'notify': notify,
      'auto_accept': asked ? null : autoAccept,
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    rule,
    amount,
    ask,
    category,
    tags,
    account,
    paidBy,
    toAccount,
    goal,
    goalPicked,
    person,
    institution,
    planId,
    planName,
    direction,
    debtRecord,
    repaysRuleId,
    notify,
    autoAccept,
  ];
}
