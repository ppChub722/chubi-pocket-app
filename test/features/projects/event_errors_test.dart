import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/projects/presentation/event_errors.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('th'));

  String text(String code) =>
      eventErrorText(l, ApiException(code: code, message: 'server says'));

  test('the BE event codes map to plain Thai', () {
    expect(text('PROJECT_LOCKED'), l.eventErrLocked);
    expect(text('FORBIDDEN_ROLE'), l.eventErrNotOwner);
    expect(text('INVALID_DATE_RANGE'), l.eventDatesInvalid);
    expect(text('OWNER_CANNOT_LEAVE'), l.eventErrOwnerCannotLeave);
  });

  test('an unknown code keeps the server message', () {
    expect(text('SOMETHING_ELSE'), 'server says');
  });
}
