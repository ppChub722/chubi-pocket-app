import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/projects/presentation/event_errors.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('th'));

  String text(String code) =>
      eventErrorText(l, ApiException(code: code, message: 'server says'));

  test('the BE event codes map to plain Thai; an unknown code keeps the '
      'server message', () {
    for (final c in [
      (code: 'PROJECT_LOCKED', want: l.eventErrLocked),
      (code: 'FORBIDDEN_ROLE', want: l.eventErrNotOwner),
      (code: 'INVALID_DATE_RANGE', want: l.eventDatesInvalid),
      (code: 'OWNER_CANNOT_LEAVE', want: l.eventErrOwnerCannotLeave),
      (code: 'EVENT_COMPLETED', want: l.eventErrCompleted),
      (code: 'PROJECT_NOT_ACTIVE', want: l.eventErrNotActive),
      (code: 'EVENT_HAS_EMPTY_PERSON', want: l.eventErrEmptyPerson),
      (code: 'SOMETHING_ELSE', want: 'server says'),
    ]) {
      expect(text(c.code), c.want, reason: c.code);
    }
  });
}
