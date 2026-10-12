/// A small OpenAPI document shaped like the BE's (`GET /api/v1/openapi.json`):
/// tags as modules, `x-breaking`, `x-used-by`, and the injected route totals.
const Map<String, dynamic> openApiFixture = {
  'openapi': '3.1.0',
  'info': {'title': 'Chubi Pocket API', 'version': '0.3.1-9'},
  'x-registered-routes': 4,
  'x-spec-routes': 3,
  'paths': {
    '/transactions': {
      'get': {
        'tags': ['transactions'],
        'operationId': 'listTransactions',
        'summary': 'List transactions',
        'parameters': [
          {
            'name': 'limit',
            'in': 'query',
            'required': false,
            'schema': {'type': 'integer'},
            'description': 'Page size',
          },
        ],
        'responses': {
          '200': {
            'description': 'OK',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/Transaction'},
                },
              },
            },
          },
        },
        'x-used-by': [
          {'page': 'transactions-list', 'calls': 2},
          'home',
        ],
      },
      'post': {
        'tags': ['transactions'],
        'operationId': 'createTransaction',
        'summary': 'Create a transaction',
        'x-breaking': 'split_count renamed to splits_count',
        'requestBody': {
          'content': {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/Transaction'},
              'example': {'amount': 120.5, 'note': 'Lunch'},
            },
          },
        },
        'responses': {
          '201': {'description': 'Created'},
          '422': {'description': 'Validation failed'},
        },
        'x-used-by': [
          {'page': 'quick-create-sheet', 'calls': 1},
        ],
      },
    },
    '/transactions/{id}': {
      'parameters': [
        {
          'name': 'id',
          'in': 'path',
          'required': true,
          'schema': {'type': 'string', 'format': 'uuid'},
        },
      ],
      'delete': {
        'tags': ['transactions'],
        'operationId': 'deleteTransaction',
        'summary': 'Delete a transaction',
        'x-breaking': true,
        'responses': {
          '204': {'description': 'Deleted'},
        },
      },
    },
  },
  'components': {
    'schemas': {
      'Transaction': {
        'type': 'object',
        'description': 'One income, expense or transfer.',
        'required': ['amount'],
        'properties': {
          'amount': {
            'type': 'number',
            'description': 'In baht',
            'example': 120.5,
          },
          'note': {
            'type': ['string', 'null'],
          },
          'kind': {
            'type': 'string',
            'enum': ['expense', 'income'],
          },
        },
        'example': {'amount': 120.5, 'note': 'Lunch'},
      },
      'Kind': {
        'type': 'string',
        'enum': ['expense', 'income', 'transfer'],
      },
    },
  },
};
