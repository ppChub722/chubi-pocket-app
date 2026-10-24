import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _wallet = Account(
  id: 'w1',
  name: 'KBank',
  type: AccountType.bank,
  currency: 'THB',
  balance: 0,
);

const _mom = EmbeddedPerson(name: 'Mom', contactId: 'c1');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the + follows the newest page that is showing', () {
    const debtPage = QuickCreatePreset.debt(person: _mom);
    const walletPage = QuickCreatePreset(account: _wallet);
    var debtShowing = true;
    var walletShowing = false;
    final registry = QuickCreateContext();
    addTearDown(registry.dispose);

    QuickCreatePreset current() => registry.active() ?? QuickCreatePreset.none;

    expect(current().mode, QuickCreateMode.tx, reason: 'no page offers one');
    registry.add(QuickCreateEntry(debtPage, () => debtShowing));
    registry.add(QuickCreateEntry(walletPage, () => walletShowing));
    expect(current(), debtPage, reason: 'the debt page is the one showing');
    expect(current().mode, QuickCreateMode.debt);
    expect(current().person, _mom, reason: 'debt person page: this person');

    walletShowing = true;
    expect(current(), walletPage, reason: 'the newest showing wins');
    expect(current().mode, QuickCreateMode.tx);
    expect(current().account, _wallet);

    walletShowing = false;
    debtShowing = false;
    expect(current(), QuickCreatePreset.none, reason: 'other tab / covered');
    expect(current().mode, QuickCreateMode.tx);
  });

  test('presets compare by what they open, not by their closure', () {
    expect(
      const QuickCreatePreset.debt(person: _mom),
      const QuickCreatePreset.debt(person: _mom),
    );
    expect(
      const QuickCreatePreset.debt(person: _mom),
      isNot(const QuickCreatePreset.debt()),
    );
    expect(
      QuickCreatePreset.custom(
        word: 'bill',
        color: const Color(0xFF7A5AE0),
        onCreate: () {},
      ),
      QuickCreatePreset.custom(
        word: 'bill',
        color: const Color(0xFF7A5AE0),
        onCreate: () {},
      ),
    );
  });
}
