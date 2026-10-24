import '../../../app/shell/quick_create_context.dart';
import '../../transactions/domain/refs.dart';
import '../domain/debt_ledger.dart';
import 'debt_wiring.dart';

/// A key starting with `c:` is a contact; any other key is a bare name.
EmbeddedPerson debtPersonOf({
  required String personKey,
  required String name,
  PersonBalance? balance,
}) {
  final p = balance?.person;
  if (p != null) return p;
  return EmbeddedPerson(
    name: name,
    contactId: personKey.startsWith('c:') ? personKey.substring(2) : null,
  );
}

/// What the + opens on a person's page: debt mode, this person, and the side
/// the balance points to.
QuickCreatePreset debtPersonPreset({
  required String personKey,
  required String name,
  PersonBalance? balance,
}) => QuickCreatePreset.debt(
  person: debtPersonOf(personKey: personKey, name: name, balance: balance),
  debtDirection: debtDirectionFor(balance?.net),
);
