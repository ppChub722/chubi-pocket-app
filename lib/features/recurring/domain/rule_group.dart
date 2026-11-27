import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import 'recurring_page.dart';

/// Which rules a page pulls (spec §3 "rules live everywhere"): a rule matches
/// when ANY given column does. A wallet page gives its id as both
/// [accountId] and [toAccountId]; a debt page its [debtKey] (c: / n: / i:).
class RuleFilter extends Equatable {
  const RuleFilter({
    this.accountId,
    this.toAccountId,
    this.goalId,
    this.contactId,
    this.institutionId,
    this.debtPlanId,
    this.debtKey,
  });

  /// A wallet's page (incl. a card wallet): rules from it or into it.
  const RuleFilter.wallet(String id)
    : accountId = id,
      toAccountId = id,
      goalId = null,
      contactId = null,
      institutionId = null,
      debtPlanId = null,
      debtKey = null;

  final String? accountId;
  final String? toAccountId;
  final String? goalId;
  final String? contactId;
  final String? institutionId;
  final String? debtPlanId;
  final String? debtKey;

  Map<String, String> toQuery() => {
    'account_id': ?accountId,
    'to_account_id': ?toAccountId,
    'goal_id': ?goalId,
    'contact_id': ?contactId,
    'institution_id': ?institutionId,
    'debt_plan_id': ?debtPlanId,
    'debt_key': ?debtKey,
  };

  @override
  List<Object?> get props => [
    accountId,
    toAccountId,
    goalId,
    contactId,
    institutionId,
    debtPlanId,
    debtKey,
  ];
}

/// The rules of one recurring that touch a page, under its name
/// (BE `RecurringRuleGroupList.data[]`).
class RuleGroup extends Equatable {
  const RuleGroup({
    required this.recurringId,
    required this.name,
    required this.rules,
    this.iconCode,
    this.trackingType = 'other',
    this.rulesCount = 1,
    this.monthTotal = 0,
  });

  factory RuleGroup.fromJson(Map<String, dynamic> json) {
    final head = (json['recurring'] as Map<String, dynamic>?) ?? const {};
    final item = <String, dynamic>{
      'id': head['id'],
      'name': head['name'],
      'icon_code': head['icon_code'],
    };
    return RuleGroup(
      recurringId: (head['id'] as String?) ?? '',
      name: (head['name'] as String?) ?? '',
      iconCode: head['icon_code'] is Map<String, dynamic>
          ? PpForgeIconCode.fromJson(head['icon_code'] as Map<String, dynamic>)
          : null,
      trackingType: (head['tracking_type'] as String?) ?? 'other',
      rulesCount: (head['rules_count'] as num?)?.toInt() ?? 1,
      monthTotal: (json['month_total'] as num?)?.toDouble() ?? 0,
      rules: [
        for (final r in (json['rules'] as List?) ?? const [])
          if (r is Map<String, dynamic>) RecurringLine.fromJson(r, item: item),
      ],
    );
  }

  final String recurringId;
  final String name;
  final PpForgeIconCode? iconCode;
  final String trackingType;

  /// All its rules ("rule 1 จาก 2" when only some touch the page).
  final int rulesCount;
  final double monthTotal;
  final List<RecurringLine> rules;

  @override
  List<Object?> get props => [
    recurringId,
    name,
    iconCode,
    trackingType,
    rulesCount,
    monthTotal,
    rules,
  ];
}
