import 'package:chubi_pocket/hub/api/openapi_model.dart';
import 'package:chubi_pocket/hub/api/page_flows.dart';
import 'package:flutter_test/flutter_test.dart';

import 'openapi_fixture.dart';

void main() {
  final doc = ApiDoc.parse(openApiFixture);

  test('info and the route totals', () {
    expect(doc.title, 'Chubi Pocket API');
    expect(doc.version, '0.3.1-9');
    expect(doc.registeredRoutes, 4);
    expect(doc.specified, 3);
  });

  test('endpoints: method, module, shared path params, breaking', () {
    expect(doc.endpoints.map((e) => e.id), [
      'GET /transactions',
      'POST /transactions',
      'DELETE /transactions/{id}',
    ]);
    expect(doc.modules, ['transactions']);
    final del = doc.endpoints.last;
    expect(del.params.single.name, 'id');
    expect(del.params.single.type, 'uuid');
    expect(del.params.single.required, isTrue);
    expect(del.breaking, ''); // true = breaking, no note
    expect(doc.endpoints[1].breaking, contains('splits_count'));
    expect(doc.endpoints[0].breaking, isNull);
  });

  test('request / response payloads and examples', () {
    final post = doc.endpoints[1];
    expect(post.request?.type, 'Transaction');
    expect(post.request?.example, {'amount': 120.5, 'note': 'Lunch'});
    expect(post.responses.map((r) => r.status), ['201', '422']);
    final get = doc.endpoints[0];
    expect(get.responses.single.type, 'array<Transaction>');
    expect(get.responses.single.ref, 'Transaction');
  });

  test('schemas: types, nullable, required, enum', () {
    final tx = doc.schemas.firstWhere((s) => s.name == 'Transaction');
    expect(tx.description, 'One income, expense or transfer.');
    final byName = {for (final p in tx.properties) p.name: p};
    expect(byName['amount']!.required, isTrue);
    expect(byName['amount']!.example, 120.5);
    expect(byName['note']!.type, 'string | null');
    expect(byName['note']!.required, isFalse);
    expect(doc.schemas.firstWhere((s) => s.name == 'Kind').enumValues, [
      'expense',
      'income',
      'transfer',
    ]);
  });

  test('pages → endpoints with call counts; unused endpoints', () {
    final pages = doc.pages;
    expect(pages.keys, ['home', 'quick-create-sheet', 'transactions-list']);
    expect(pages['transactions-list']!.single.$2, 2);
    expect(pages['home']!.single.$2, 1); // a plain string = 1 call
    expect(doc.unused.map((e) => e.id), ['DELETE /transactions/{id}']);
  });

  test('withFlows: used-by comes from the registry, not x-used-by', () {
    final d = doc.withFlows(const [
      PageFlow('p1', 'One.', [
        FlowStep.open([FlowCall('deleteTransaction')]),
        FlowStep.action('Button "x"', [FlowCall('deleteTransaction')]),
      ]),
    ]);
    expect(d.pages.keys, ['p1']);
    expect(d.pages['p1']!.single.$2, 2); // two steps call it
    expect(d.byOperation('deleteTransaction')!.usedBy.single.page, 'p1');
    expect(d.unused.map((e) => e.id), [
      'GET /transactions',
      'POST /transactions',
    ]);
  });

  test('a spec without the extensions still parses', () {
    final bare = ApiDoc.parse({
      'paths': {
        '/ping': {
          'get': {'summary': 'Ping'},
        },
      },
    });
    expect(bare.endpoints.single.module, 'ping');
    expect(bare.registeredRoutes, isNull);
    expect(bare.specified, 1);
  });
}
