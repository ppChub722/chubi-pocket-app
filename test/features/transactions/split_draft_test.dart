import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// PUT /transactions/:id/splits entries (contract 2026-10-10): a saved row
/// sends a new person only when it's unlinked and actually changed.
void main() {
  SplitDraft saved({String name = 'ลี', String? contact}) => SplitDraft(
    debtId: 'd1',
    personName: name,
    contactId: contact,
    owedAmount: 100,
  );

  test('a new row: name, contact, amount — no debt_id', () {
    final d = SplitDraft()
      ..setPerson('ลี', contact: 'c1')
      ..owedAmount = 50;
    expect(d.toUpdateJson(), {
      'person_name': 'ลี',
      'contact_id': 'c1',
      'owed_amount': 50,
    });
  });

  test('a saved row, person unchanged: debt + amount only', () {
    expect(saved().toUpdateJson(), {'debt_id': 'd1', 'owed_amount': 100});
  });

  test('saved + unlinked, renamed: sends the new name', () {
    final d = saved()..setPerson('ลีลา');
    expect(d.identityLocked, isFalse);
    expect(d.toUpdateJson(), {
      'debt_id': 'd1',
      'owed_amount': 100,
      'person_name': 'ลีลา',
    });
  });

  test('saved + unlinked, linked to a contact: sends contact_id', () {
    final d = saved()..setPerson('ลี', contact: 'c9');
    expect(d.toUpdateJson(), {
      'debt_id': 'd1',
      'owed_amount': 100,
      'contact_id': 'c9',
    });
  });

  test('saved + unlinked, renamed back: nothing to change', () {
    final d = saved()
      ..setPerson('ลีลา')
      ..setPerson('ลี');
    expect(d.toUpdateJson(), {'debt_id': 'd1', 'owed_amount': 100});
  });

  test('saved + linked: identity locked, never sent', () {
    final d = saved(contact: 'c1');
    expect(d.identityLocked, isTrue);
    expect(d.isWired, isTrue);
    expect(d.toUpdateJson(), {'debt_id': 'd1', 'owed_amount': 100});
  });

  test('an unsaved row is never locked, whoever it is', () {
    final d = SplitDraft()..setPerson('ลี', contact: 'c1');
    expect(d.identityLocked, isFalse);
    d.setPerson('ลีลา');
    expect(d.isWired, isFalse);
  });
}
