import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/presentation/occurrence_actions.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 0.4.1-2 K12 / K13, app side: a หนี้ occurrence links an entry, never
/// sends a category / tags, and the person page lists the person's settings.
void main() {
  test('a หนี้ link sends debt_entry_id (replace only when asked)', () {
    expect(debtEntryLinkBody('e1'), {'debt_entry_id': 'e1'});
    expect(debtEntryLinkBody('e1', replace: true), {
      'debt_entry_id': 'e1',
      'replace': true,
    });
  });

  test('a หนี้ occurrence edit never sends category / tags / to wallet', () {
    const was = PendingDraft(type: TransactionType.expense, amount: 100);
    const now = PendingDraft(
      type: TransactionType.expense,
      amount: 150,
      categoryId: 'c1',
      tagIds: ['t1'],
      transferToAccountId: 'a2',
      accountId: 'a1',
    );
    expect(occurrenceFields(was, now, debt: true), {
      'amount': 150.0,
      'account_id': 'a1',
    });
    expect(
      occurrenceFields(was, now).keys,
      containsAll(['category_id', 'tag_ids', 'to_account_id']),
    );
  });

  test('entry query sends kind only when set', () {
    expect(const DebtEntryQuery().toQuery().containsKey('kind'), isFalse);
    expect(
      const DebtEntryQuery(
        kind: 'repayment',
        direction: DebtEntryDirection.paid,
      ).toQuery(),
      containsPair('kind', 'repayment'),
    );
  });

  group('person page recurring[] (DebtPersonPage)', () {
    Map<String, dynamic> page([List<Object>? recurring]) => {
      'key': 'c:c1',
      'person': {'name': 'แม่', 'contact_id': 'c1', 'linked': false},
      'net': -500,
      'open_count': 1,
      'entry_count': 2,
      'counts': {'entries': 2, 'money': 1, 'current': 2, 'earlier': 0},
      'summary_message': {'text': 'สรุปยอด', 'entries': 2, 'net': -500},
      'items': <Object>[],
      'days': <Object>[],
      'pagination': {'page': 1, 'per_page': 30, 'total': 0, 'total_pages': 1},
      'auto_sync_debts': false,
      'recurring': ?recurring,
    };

    test('parses each setting', () {
      final d = DebtPersonDetail.fromJson(
        page([
          {
            'id': 'r1',
            'name': 'คืนแม่',
            'icon_code': null,
            'debt_kind': 'repayment',
            'direction': 'paid',
            'amount': 300,
            'next_date': '2026-11-01',
            'next_amount': 200,
            'due_count': 1,
            'status': 'paused',
            'pause_reason': 'no_balance',
          },
          {
            'id': 'r2',
            'name': 'แม่ยืม',
            'icon_code': {'icon': 'handshake'},
            'debt_kind': 'debt',
            'direction': 'received',
            'amount': 1000,
            'next_date': null,
            'next_amount': null,
            'due_count': 0,
            'status': 'active',
            'pause_reason': null,
          },
        ]),
      );
      expect(d.recurring, hasLength(2));
      final r = d.recurring.first;
      expect(r.id, 'r1');
      expect(r.name, 'คืนแม่');
      expect(r.sub, DebtEntrySub.repay);
      expect(r.direction, DebtEntryDirection.paid);
      expect((r.amount, r.nextAmount, r.dueCount), (300.0, 200.0, 1));
      expect(r.nextDate, DateTime(2026, 11, 1));
      expect(r.status, RecurringStatus.paused);
      expect(r.pauseReason, RecurringPauseReason.noBalance);
      final r2 = d.recurring.last;
      expect(r2.sub, DebtEntrySub.record);
      expect(r2.direction, DebtEntryDirection.received);
      expect(r2.iconCode, isNotNull);
      expect((r2.nextDate, r2.nextAmount, r2.pauseReason), (null, null, null));
      expect(r2.status, RecurringStatus.active);
    });

    test('no recurring key (an older BE) = none', () {
      expect(DebtPersonDetail.fromJson(page()).recurring, isEmpty);
      expect(DebtPersonDetail.fromJson(page(const [])).recurring, isEmpty);
    });
  });
}
