import 'dart:ui';

import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/categories/presentation/category_label.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/debt_wiring.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Category _system(String kind) => Category(
  id: kind,
  name: 'stored $kind',
  type: CategoryType.expense,
  isSystem: true,
  systemKind: kind,
);

void main() {
  final th = lookupAppLocalizations(const Locale('th'));

  test('the four debt system categories show their l10n names', () {
    expect(categoryDisplayName(th, _system('LOAN_GIVEN')), 'ให้กู้ยืม');
    expect(categoryDisplayName(th, _system('LOAN_TAKEN')), 'กู้ยืม');
    expect(categoryDisplayName(th, _system('DEBT_PAID')), 'ชำระหนี้');
    expect(categoryDisplayName(th, _system('DEBT_RECEIVED')), 'รับชำระหนี้');
  });

  test('a debt with no description shows its kind = the category name', () {
    expect(debtKindName(th, out: true, repayment: false), 'ให้กู้ยืม');
    expect(debtKindName(th, out: false, repayment: false), 'กู้ยืม');
    expect(debtKindName(th, out: true, repayment: true), 'ชำระหนี้');
    expect(debtKindName(th, out: false, repayment: true), 'รับชำระหนี้');
  });
}
