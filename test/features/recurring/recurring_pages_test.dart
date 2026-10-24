import 'package:chubi_pocket/features/recurring/domain/recurrence_rule.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_summary.dart';
import 'package:chubi_pocket/features/recurring/presentation/recurring_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recurring_fixtures.dart';

void main() {
  test('the rule round-trips through the API shape', () {
    final r = Recurring.fromJson(prodRecurringJson());
    expect(r.rule.freq, RecurrenceFreq.monthly);
    expect(r.rule.monthly?.day, 3);
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
    expect(r.kind, RecurringKind.subscription);
    expect(r.yearlyCost, 5028);
    expect(r.savedCount, 1);
    expect(r.pendingCount, 2);
    expect(r.hasAmount, isTrue);
    final w = Recurring.fromJson(reminderJson());
    expect(w.kind, RecurringKind.reminder);
    expect(w.amount, isNull);
    expect(w.hasAmount, isFalse);
    expect(w.currentOccurrence?.status, OccurrenceState.pending);
    expect(w.currentOccurrence?.amount, isNull);
  });

  test('the summary is the BE\'s: 30-day total, awaiting, by kind', () {
    final s = RecurringSummary.fromJson(recurringSummaryJson())!;
    expect(s.due30dTotal, 6860);
    expect(s.awaitingAmountCount, 3);
    expect(s.byKind[RecurringKind.subscription]?.yearly, 5028);
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

  test('the write: a reminder sends amount 0, a create leaves trial out', () {
    final draft = RecurringDraft.blank(
      preset: const RecurringPreset(kind: RecurringKind.reminder),
    ).copyWith(name: 'Water', accountId: 'a1');
    final body = draft.toWrite().toJson();
    expect(body['kind'], 'reminder');
    expect(body['amount'], 0);
    expect(body.containsKey('trial_until'), isFalse);
    // A PUT clears the trial with "".
    expect(draft.toWrite().toJson(forUpdate: true)['trial_until'], '');
  });

  test('prefill: type / amount / category / name / account from the query', () {
    final p = RecurringPreset.fromQuery({
      'type': 'income',
      'amount': '30000',
      'category': 'c9',
      'name': 'Salary',
      'account': 'a1',
    });
    final d = RecurringDraft.blank(preset: p);
    // income → the รายรับ kind
    expect(d.kind, RecurringKind.income);
    expect(d.type, TransactionType.income);
    expect(d.name, 'Salary');
    expect(AmountInput.parse(d.amount), 30000);
    final body = d.toWrite().toJson();
    expect(body['category_id'], 'c9');
    expect(body['account_id'], 'a1');
    expect(body['type'], 'income');
  });
}
