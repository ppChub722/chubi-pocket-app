import 'package:chubi_pocket/core/network/idempotency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

RequestOptions _post(Object body) =>
    RequestOptions(path: '/transactions', method: 'POST', data: body);

void main() {
  test('a retry of the same save sends the same keys, in order', () async {
    final idem = Idempotency();
    Future<List<String?>> save(Object body) => idem.run(
      () async => [
        Idempotency.keyFor(_post(body)),
        Idempotency.keyFor(_post({'second': true})),
      ],
    );
    final first = await save({'amount': 10});
    final retry = await save({'amount': 10});
    expect(first, retry);
    expect(first[0], isNot(first[1]));
    expect(first[0], startsWith(idem.base));
  });

  test('a changed form gets another key; reads and calls outside get none', () async {
    final idem = Idempotency();
    final a = await idem.run(() async => Idempotency.keyFor(_post({'a': 1})));
    final b = await idem.run(() async => Idempotency.keyFor(_post({'a': 2})));
    expect(a, isNot(b));
    expect(
      await idem.run(
        () async => Idempotency.keyFor(
          RequestOptions(path: '/transactions', method: 'GET'),
        ),
      ),
      isNull,
    );
    expect(Idempotency.keyFor(_post({'a': 1})), isNull);
    expect(Idempotency().base, isNot(idem.base));
  });
}
