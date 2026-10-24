import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/debt_person_preset.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

PersonBalance _balance(EmbeddedPerson person, double net) =>
    PersonBalance(key: 'k', person: person, net: net);

void main() {
  test('the person page + is debt mode, this person, the balance side', () {
    const mom = EmbeddedPerson(name: 'Mom', contactId: 'c1');
    const walkIn = EmbeddedPerson(name: 'Ben');
    final cases = <(String, QuickCreatePreset, QuickCreatePreset)>[
      (
        'contact key, no balance yet',
        debtPersonPreset(personKey: 'c:c1', name: 'Mom'),
        const QuickCreatePreset.debt(person: mom),
      ),
      (
        'name key has no contact',
        debtPersonPreset(personKey: 'n:ben', name: 'Ben'),
        const QuickCreatePreset.debt(person: walkIn),
      ),
      (
        'they owe me → received',
        debtPersonPreset(
          personKey: 'c:c1',
          name: 'Mom',
          balance: _balance(mom, 120),
        ),
        const QuickCreatePreset.debt(
          person: mom,
          debtDirection: DebtEntryDirection.received,
        ),
      ),
      (
        'I owe them → paid',
        debtPersonPreset(
          personKey: 'c:c1',
          name: 'Mom',
          balance: _balance(mom, -120),
        ),
        const QuickCreatePreset.debt(
          person: mom,
          debtDirection: DebtEntryDirection.paid,
        ),
      ),
      (
        'settled → no side',
        debtPersonPreset(
          personKey: 'c:c1',
          name: 'Mom',
          balance: _balance(mom, 0.001),
        ),
        const QuickCreatePreset.debt(person: mom),
      ),
    ];
    for (final (name, got, want) in cases) {
      expect(got, want, reason: name);
      expect(got.mode, QuickCreateMode.debt, reason: name);
    }
  });

  test('the loaded balance\'s person wins over the key and the name', () {
    const linked = EmbeddedPerson(
      name: 'Mum',
      contactId: 'c9',
      linked: true,
      linkedUserId: 'u1',
    );
    expect(
      debtPersonOf(
        personKey: 'c:c1',
        name: 'Mom',
        balance: _balance(linked, 10),
      ),
      linked,
    );
  });
}
