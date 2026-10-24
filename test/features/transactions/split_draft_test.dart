import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// PUT /transactions/:id/splits entries (contract 2026-10-11): a saved row
/// sends a new person only when it changed and isn't locked — and only a
/// contact linked to an app user locks it.
void main() {
  SplitDraft saved({String name = 'ลี', String? contact}) => SplitDraft(
    debtId: 'd1',
    personName: name,
    contactId: contact,
    owedAmount: 100,
  );

  test('SplitDraft.toUpdateJson / isWired table', () {
    final cases = <({String name, SplitDraft draft, Map<String, dynamic> json})>[
      (
        name: 'a new row: name, contact, amount — no debt_id',
        draft: SplitDraft()
          ..setPerson('ลี', contact: 'c1')
          ..owedAmount = 50,
        json: {'person_name': 'ลี', 'contact_id': 'c1', 'owed_amount': 50},
      ),
      (
        name: 'a saved row, person unchanged: debt + amount only',
        draft: saved(),
        json: {'debt_id': 'd1', 'owed_amount': 100},
      ),
      (
        name: 'saved + unlinked, renamed: sends the new name',
        draft: saved()..setPerson('ลีลา'),
        json: {'debt_id': 'd1', 'owed_amount': 100, 'person_name': 'ลีลา'},
      ),
      (
        name: 'saved typed name, linked to a contact: sends contact_id + name',
        draft: saved()..setPerson('ลี', contact: 'c9'),
        json: {
          'debt_id': 'd1',
          'owed_amount': 100,
          'contact_id': 'c9',
          'person_name': 'ลี',
        },
      ),
      (
        name: 'saved + unlinked, renamed back: nothing to change',
        draft: saved()
          ..setPerson('ลีลา')
          ..setPerson('ลี'),
        json: {'debt_id': 'd1', 'owed_amount': 100},
      ),
      (
        name: 'saved contact swapped for another: contact_id + name',
        draft: saved(contact: 'c1')..setPerson('ต้น', contact: 'c2'),
        json: {
          'debt_id': 'd1',
          'owed_amount': 100,
          'contact_id': 'c2',
          'person_name': 'ต้น',
        },
      ),
      (
        name: 'saved contact back to a typed name: contact_id null, name kept',
        draft: saved(contact: 'c1')..setPerson('ลี'),
        json: {
          'debt_id': 'd1',
          'owed_amount': 100,
          'contact_id': null,
          'person_name': 'ลี',
        },
      ),
    ];
    for (final c in cases) {
      expect(c.draft.toUpdateJson(), c.json, reason: c.name);
    }

    final unsaved = SplitDraft()..setPerson('ลี', contact: 'c1');
    expect(unsaved.isWired, isTrue, reason: 'an unsaved row with a contact');
    unsaved.setPerson('ลีลา');
    expect(unsaved.isWired, isFalse, reason: 'an unsaved row renamed');
  });
}
