import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient(this._dio);
  final Dio _dio;

  @override
  Dio get dio => _dio;
}

/// A wallet as the BE sends it.
Map<String, dynamic> _json({bool track = true, double balance = 1234.5}) => {
  'id': 'w1',
  'name': 'KBank',
  'type': 'bank',
  'group': 'asset',
  'balance': balance,
  'currency': 'THB',
  'icon_code': {'icon': 'bank', 'color': 'blue'},
  'status': 'active',
  'sort_order': 0,
  'my_role': 'owner',
  'can_edit': true,
  'is_shared': false,
  'track_balance': track,
};

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  test('untracked: no credit figures, showsBalance false', () {
    final a = Account.fromJson({
      ..._json(track: false, balance: -2000),
      'type': 'credit_card',
      'credit_limit': 10000,
    });
    expect(a.showsBalance, isFalse);
    expect(a.creditUsed, 0);
  });

  test('track_balance bodies: create, edit and the view switch', () async {
    final tracked = Account.fromJson(_json());
    final untracked = Account.fromJson(_json(track: false));

    final create = tracked.toCreateJson();
    expect(create['track_balance'], true);
    expect(create['balance'], 1234.5);
    final createOff = untracked.toCreateJson();
    expect(createOff['track_balance'], false);
    expect(createOff.containsKey('balance'), isFalse);

    final turnOn = tracked.toUpdateJson(currentBalance: 500);
    expect(turnOn['track_balance'], true);
    expect(turnOn['current_balance'], 500);
    final turnOff = untracked.toUpdateJson();
    expect(turnOff['track_balance'], false);
    expect(turnOff.containsKey('current_balance'), isFalse);
    final offWithBalance = untracked.toUpdateJson(currentBalance: 500);
    expect(offWithBalance.containsKey('current_balance'), isFalse);

    final dio = _MockDio();
    final repo = AccountsRepository(client: _FakeApiClient(dio));
    final sent = <Object?>[];
    when(
      () => dio.put<Map<String, dynamic>>(
        '/accounts/w1',
        data: any(named: 'data'),
      ),
    ).thenAnswer((i) async {
      sent.add(i.namedArguments[#data]);
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: _json(),
      );
    });
    await repo.setTrackBalance('w1', on: false);
    await repo.setTrackBalance('w1', on: true, currentBalance: 500);
    expect(sent, [
      {'track_balance': false},
      {'track_balance': true, 'current_balance': 500},
    ]);
  });
}
