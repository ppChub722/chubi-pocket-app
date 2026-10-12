import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _pending(String id, {Object? error}) => {
  'id': id,
  'source': 'manual',
  'kind': 'create',
  'draft': {
    'type': 'expense',
    'amount': 120,
    'account_id': 'a1',
    'splits': [
      {'person_name': 'Beam', 'owed_amount': 40},
    ],
  },
  'resolved': {
    'account': {
      'id': 'a1',
      'name': 'KBank',
      'icon_code': null,
      'logo_url': null,
      'type': 'bank',
      'group': 'asset',
      'currency': 'THB',
      'archived': false,
    },
    'transfer_to_account': null,
    'category': null,
    'tags': [
      {'id': 't1', 'name': 'trip', 'icon_code': null},
    ],
    'project': {
      'id': 'p1',
      'name': 'Trip',
      'icon_code': null,
      'status': 'active',
    },
    'splits': [
      {
        'person': {
          'name': 'Beam',
          'contact_id': null,
          'icon_code': null,
          'linked': false,
          'linked_user_id': null,
        },
        'owed_amount': 40,
      },
    ],
    'missing': ['category_id'],
  },
  'target_debt_id': null,
  'target_transaction_id': null,
  'source_ref': null,
  'last_error': error,
  'created_at': '2026-10-12T09:30:00Z',
  'updated_at': '2026-10-12T09:30:00Z',
};

void main() {
  test('PendingTransaction parses resolved', () {
    final p = PendingTransaction.fromJson(_pending('x'));
    expect(p.resolved.account?.name, 'KBank');
    expect(p.resolved.category, isNull);
    expect(p.resolved.tags.single.name, 'trip');
    expect(p.resolved.project?.name, 'Trip');
    expect(p.resolved.splits.single.person.name, 'Beam');
    expect(p.resolved.splits.single.owedAmount, 40);
    expect(p.resolved.missing, ['category_id']);
  });

  test('PendingSubmitResult parses submit response', () {
    final r = PendingSubmitResult.fromJson({
      'submitted': [
        {'id': 'a', 'rows': <Object>[]},
      ],
      'failed': [
        {
          'id': 'b',
          'error': {'code': 'MISSING_DATE', 'message': 'm'},
          'pending': _pending(
            'b',
            error: {'code': 'MISSING_DATE', 'message': 'm'},
          ),
        },
        {
          'id': 'c',
          'error': {'code': 'NOT_FOUND', 'message': 'gone'},
          'pending': null,
        },
      ],
      'account_balances': [
        {'account_id': 'a1', 'balance': 880.5},
      ],
      'badges': {'unread_notifications': 1, 'pending_drafts': 2},
    });
    expect(r.submitted, ['a']);
    expect(r.failed.keys, ['b', 'c']);
    expect(r.failedDrafts.keys, ['b']);
    expect(r.failedDrafts['b']!.lastError?.code, 'MISSING_DATE');
    expect(r.accountBalances, {'a1': 880.5});
    expect(r.pendingDrafts, 2);
  });

  test('DiscardResult parses', () {
    final r = DiscardResult.fromJson({
      'discarded': ['a'],
      'skipped': ['b'],
      'remaining_count': 3,
    });
    expect(r.discarded, ['a']);
    expect(r.skipped, ['b']);
    expect(r.remainingCount, 3);
  });
}
