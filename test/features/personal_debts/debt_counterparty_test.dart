import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

/// BE DebtPerson (0.4.3): an institution row with its first open debts.
Map<String, dynamic> institutionRowJson() => {
  'key': 'i:inst1',
  'kind': 'institution',
  'person': {'name': 'KTC'},
  'institution': {
    'id': 'inst1',
    'name': 'KTC',
    'kind': 'card',
    'icon_code': null,
  },
  'net': -11095,
  'entry_count': 4,
  'entries_preview': [
    {
      'id': 'e1',
      'kind': 'debt',
      'direction': 'received',
      'amount': 9000,
      'date': '2026-10-25',
      'description': 'ผ่อนค่าเครื่องบิน',
      'recurring': {
        'id': 'it9',
        'name': 'ผ่อนค่าเครื่องบิน',
        'icon_code': null,
        'installment_seq': 1,
        'installment_count': 3,
      },
    },
  ],
};

void main() {
  test('an institution row: kind, institution, preview rows', () {
    final p = PersonBalance.fromJson(institutionRowJson());
    expect(p.isInstitution, isTrue);
    expect(p.institution?.name, 'KTC');
    expect(p.entriesPreview.single.kind, DebtPreviewKind.entry);
    expect(p.entriesPreview.single.amount, -9000);
    final ref = p.entriesPreview.single.entry!.recurring!;
    expect(debtRecurringTagText(ref, const []), 'ผ่อนค่าเครื่องบิน 1/3');
  });

  test('an older person row reads as a person with no preview', () {
    final p = PersonBalance.fromJson({
      'key': 'n:แฟน',
      'person': {'name': 'แฟน'},
      'net': 300,
    });
    expect(p.isInstitution, isFalse);
    expect(p.entriesPreview, isEmpty);
  });

  test('the page: recurrings with plan + lines, card debts; the installment '
      'a repayment offers to tick', () {
    final d = DebtPersonDetail.fromJson({
      ...institutionRowJson(),
      'items': <dynamic>[],
      'recurrings': [
        {
          'id': 'it1',
          'name': 'ให้ยืมเงิน',
          'type': 'debt',
          'status': 'active',
          'debt_direction': 'paid',
          'reminders_count': 1,
          'plan': {
            'count': 5,
            'done': 2,
            'left_principal': 6000,
            'next': {'seq': 3, 'due_date': '2026-11-30', 'amount': 2000},
          },
          'reminders': [
            {
              'id': 'l1',
              'amount': 2000,
              'source': {'account_id': 'a1'},
              'account': {'id': 'a1', 'name': 'เงินในธนาคาร'},
              'debt_kind': 'repayment',
              'next_date': '2026-11-30',
            },
          ],
        },
      ],
      'card_debts': [
        {
          'account': {'id': 'card1', 'name': 'บัตรเครดิต KTC'},
          'amount': 2095,
        },
      ],
    });
    final r = d.recurrings.single;
    expect(r.owedToMe, isTrue);
    expect(r.signedLeft, 6000);
    expect(r.lines.single.accountName, 'เงินในธนาคาร');
    expect(r.lines.single.repayment, isTrue);
    expect(d.cardDebts.single.amount, 2095);
    final pick = installmentToMark(d.recurrings, owedToMe: true);
    expect(pick?.seq, 3);
    expect(installmentToMark(d.recurrings, owedToMe: false), isNull);
  });
}
