import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/features/transactions/presentation/transaction_edit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('th'));

  test('B1: an untouched 0 saves; a typed amount stays > 0', () {
    for (final c in [
      (name: 'system 0, untouched', saved: 0.0, typed: '0', ok: true),
      (name: 'system 0, cleared', saved: 0.0, typed: '', ok: true),
      (name: 'typed down to 0', saved: 120.0, typed: '0', ok: false),
      (name: 'new tx with 0', saved: null, typed: '0', ok: false),
      (name: 'system 0, amount typed', saved: 0.0, typed: '50', ok: true),
    ]) {
      final form = DraftFormController();
      addTearDown(form.dispose);
      form.amount.text = c.typed;
      final problem = transactionEditProblem(
        l,
        form,
        checkSplits: false,
        savedAmount: c.saved,
      );
      expect(problem == l.quickAmountRequired, !c.ok, reason: c.name);
    }
  });
}
