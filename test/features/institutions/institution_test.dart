import 'package:chubi_pocket/features/institutions/domain/institution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an institution page: provider, wallets, debt in short', () {
    final d = InstitutionDetail.fromJson({
      'id': 'inst1',
      'name': 'KTC',
      'kind': 'card',
      'provider_id': 'p1',
      'provider': {
        'id': 'p1',
        'name': 'KTC',
        'short_name': 'KTC',
        'color': '#F97316',
        'phone': '02 123 5000',
        'website': null,
      },
      'phone': null,
      'email': null,
      'icon_code': null,
      'description': '',
      'note': null,
      'status': 'active',
      'created_at': '2026-11-17T10:00:00Z',
      'updated_at': '2026-11-17T10:00:00Z',
      'accounts': [
        {'id': 'card1', 'name': 'บัตรเครดิต KTC', 'type': 'credit_card'},
      ],
      'debt': {
        'key': 'i:inst1',
        'net': -11095,
        'side': 'i_owe',
        'entry_count': 1,
        'recurring_count': 1,
      },
    });
    final i = d.institution;
    expect(i.kind, InstitutionKind.card);
    expect(i.description, isNull, reason: 'blank text reads as none');
    expect(i.shownPhone, '02 123 5000');
    expect(i.ref.debtKey, 'i:inst1');
    expect(d.accounts.single.id, 'card1');
    expect(d.debt.net, -11095);
    expect(institutionIdOfKey('i:inst1'), 'inst1');
    expect(institutionIdOfKey('c:x'), isNull);
  });

  test('the write sends every field', () {
    final w = const InstitutionWrite(
      name: 'Toyota Leasing',
      kind: InstitutionKind.finance,
      phone: '1734',
    ).toJson();
    expect(w['kind'], 'finance');
    expect(w['phone'], '1734');
    expect(w.containsKey('note'), isTrue);
  });
}
