import 'dart:async';
import 'dart:io';

import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// errorText is the ONE place an API error becomes words (B1, 0.4.2-3):
/// every code in the BE's OpenAPI `Error` enum must be worded, and a worded
/// code never shows the server's English message.
void main() {
  final l = lookupAppLocalizations(const Locale('th'));
  final spec = File('../chubi-pocket-be/internal/apidoc/openapi.yaml');

  String text(String code, {int? status}) => errorText(
    l,
    ApiException(code: code, message: 'server says', statusCode: status),
  );

  test(
    'every OpenAPI error code has a Thai sentence',
    () {
      final doc = loadYaml(spec.readAsStringSync()) as YamlMap;
      final codes =
          ((((doc['components'] as YamlMap)['schemas'] as YamlMap)['Error']
                      as YamlMap)['properties']['error']['properties']['code']['enum']
                  as YamlList)
              .cast<String>()
              .toList();
      expect(codes.length, greaterThan(100));
      final missing = [
        for (final c in codes)
          if (!mappedErrorCodes.contains(c)) c,
      ];
      expect(missing, isEmpty, reason: 'add them to app_error_text.dart');
    },
    skip: spec.existsSync() ? false : 'BE checkout not found next to the app',
  );

  test('a worded code never shows the server message', () {
    for (final c in mappedErrorCodes) {
      expect(text(c), isNot('server says'), reason: c);
      expect(text(c), isNotEmpty, reason: c);
    }
  });

  test('a specific code keeps its own sentence', () {
    expect(text('PROJECT_LOCKED'), l.eventErrLocked);
    expect(text('FORBIDDEN_ROLE'), l.eventErrNotOwner);
    expect(text('INVALID_DATE_RANGE'), l.eventDatesInvalid);
    expect(text('NOTHING_OWED'), l.occurrenceNothingOwed);
    expect(text('MAX_DEPTH_EXCEEDED'), l.categoryErrorMaxDepth);
    expect(text('MISSING_AMOUNT'), l.pendingErrMissingAmount);
    expect(text('UNAUTHORIZED'), l.errSessionExpired);
  });

  test('codes of a group share the sentence', () {
    expect(text('TRANSACTION_NOT_FOUND'), l.errNotFound);
    expect(text('NOT_FOUND'), l.errNotFound);
    expect(text('NOT_MEMBER'), l.errForbidden);
    expect(text('SYSTEM_TRANSACTION_IMMUTABLE'), l.errImmutable);
    expect(text('STATE_CONFLICT'), l.errStale);
    expect(text('INTERNAL_SERVER_ERROR'), l.errorGenericMessage);
  });

  test('an unknown code falls back on the status class, then on generic', () {
    expect(text('NEW_CODE', status: 404), l.errNotFound);
    expect(text('NEW_CODE', status: 403), l.errForbidden);
    expect(text('NEW_CODE', status: 422), l.errorValidationMessage);
    expect(text('NEW_CODE', status: 409), l.errStale);
    expect(text('NEW_CODE', status: 500), l.errorGenericMessage);
    expect(text('NEW_CODE'), l.errorGenericMessage);
  });

  test('offline, slow, server down and other throws', () {
    expect(text('NETWORK_ERROR'), l.errorNetworkMessage);
    expect(text('NETWORK_TIMEOUT'), l.errorSlowMessage);
    expect(text('SERVER_UNAVAILABLE'), l.errorServerDownMessage);
    expect(errorText(l, TimeoutException('slow')), l.errorSlowMessage);
    expect(errorText(l, TimeoutException('offline')), l.errorNetworkMessage);
    expect(errorText(l, StateError('boom')), l.errorGenericMessage);
  });

  test('a VALIDATION_ERROR names its fields (details[]) in Thai', () {
    final e = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'bad',
              'details': [
                {
                  'field': 'name',
                  'code': 'too_long',
                  'params': {'max': 100},
                },
                {'field': 'note', 'code': 'required', 'params': {}},
              ],
            },
          },
        ),
      ),
    );
    expect(e.fields.map((f) => f.field), ['name', 'note']);
    expect(fieldErrorText(l, e, 'name'), l.errFieldTooLong('100'));
    expect(fieldErrorText(l, e, 'note'), l.errFieldRequired);
    expect(fieldErrorText(l, e, 'amount'), isNull);
    // no slot on the form: the snack says the first field's problem
    expect(errorText(l, e), l.errFieldTooLong('100'));
  });

  test('one classifier: a Dio failure gets the code its kind says', () {
    final req = RequestOptions(path: '/x');
    ApiException of(DioExceptionType type, {int? status, Object? error}) =>
        ApiException.fromDioException(
          DioException(
            requestOptions: req,
            type: type,
            error: error,
            response: status == null
                ? null
                : Response(requestOptions: req, statusCode: status),
          ),
        );
    expect(of(DioExceptionType.connectionError).code, 'NETWORK_ERROR');
    expect(of(DioExceptionType.connectionTimeout).code, 'NETWORK_ERROR');
    expect(
      of(DioExceptionType.unknown, error: const SocketException('x')).code,
      'NETWORK_ERROR',
    );
    expect(of(DioExceptionType.receiveTimeout).code, 'NETWORK_TIMEOUT');
    expect(
      of(DioExceptionType.badResponse, status: 502).code,
      'SERVER_UNAVAILABLE',
    );
    expect(of(DioExceptionType.badResponse, status: 500).code, 'UNKNOWN_ERROR');
  });
}
