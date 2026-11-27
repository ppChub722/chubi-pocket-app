import 'package:chubi_pocket/features/recurring/domain/recurrence_rule.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_summary.dart';
import 'package:chubi_pocket/features/recurring/domain/rule_draft.dart';
import 'package:chubi_pocket/features/recurring/presentation/pages/recurring_form_page.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recurring_fixtures.dart';

void main() {
  test('the rule round-trips through the API shape', () {
    final r = Recurring.fromJson(prodRecurringJson());
    expect(r.rule.freq, RecurrenceFreq.monthly);
    expect(r.rule.monthDays, {3});
    expect(r.rule.end.count, 12);
    final json = recurrenceToJson(r.rule);
    expect(json['start_date'], '2026-10-03');
    expect(json['end'], {'kind': 'count', 'count': 12});
    expect(
      recurrenceFromJson(
        json['rule'] as Map<String, dynamic>,
        start: json['start_date'] as String,
        end: json['end'] as Map<String, dynamic>,
      ),
      r.rule,
    );
  });

  test('the 0.4.0 fields parse; a reminder has no amount', () {
    final r = Recurring.fromJson(prodRecurringJson());
    expect(r.kind, RecurringKind.expense);
    expect(r.yearlyCost, 5028);
    expect(r.savedCount, 1);
    expect(r.pendingCount, 2);
    expect(r.hasAmount, isTrue);
    final w = Recurring.fromJson(reminderJson());
    // 0.4.3: an old "reminder" reads as บิล.
    expect(w.kind, RecurringKind.expense);
    expect(w.amount, isNull);
    expect(w.hasAmount, isFalse);
    expect(w.currentOccurrence?.status, OccurrenceState.pending);
    expect(w.currentOccurrence?.amount, isNull);
  });

  test('the summary is the BE\'s: 30-day total, awaiting, by kind', () {
    final s = RecurringSummary.fromJson(recurringSummaryJson())!;
    expect(s.due30dTotal, 6860);
    expect(s.awaitingAmountCount, 3);
    expect(s.byKind[RecurringKind.expense]?.yearly, 5028);
    expect(s.nextAmount, 419);
  });

  test('an item takes its state and link from the BE', () {
    final i = RecurringItem.fromJson(prodItemJson());
    expect(i.state, OccurrenceState.done);
    expect(i.transaction?.id, 'tx1');
    expect(i.linked, isTrue);
    expect(i.title, 'Netflix');
    expect(RecurringItem.fromJson(prodItemJson(amount: null)).amount, isNull);
  });

  test('a bill rule asking its amount sends no amount', () {
    final body = RuleDraft.blank(RecurringKind.expense)
        .copyWith(
          ask: true,
          account: const AccountRef(id: 'a1', name: 'KBank'),
        )
        .toJson();
    expect(body['type'], 'expense');
    expect(body['amount_mode'], 'ask');
    expect(body.containsKey('amount'), isFalse);
    expect(body['source'], {'account_id': 'a1'});
  });

  test('quick create preset: type / amount / category / name / account / '
      'pick from the query', () {
    final p = RecurringFormPreset.fromQuery({
      'type': 'income',
      'amount': '30000',
      'category': 'c9',
      'name': 'Salary',
      'account': 'a1',
      'pick': '1',
    });
    expect(RecurringKind.fromJson(p.type), RecurringKind.income);
    expect(p.amount, 30000);
    expect(p.categoryId, 'c9');
    expect(p.name, 'Salary');
    expect(p.accountId, 'a1');
    expect(p.pick, isTrue, reason: 'the picker picks the new one');
    expect(RecurringFormPreset.fromQuery(const {}).pick, isFalse);
  });
}
