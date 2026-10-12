import 'package:flutter/material.dart';

/// The words and error descriptions the generic kit needs (owner 2026-10-12:
/// generic pieces never read the app's localisation). The app supplies the
/// real ones once, at its root, with [UiConfig] (see `AppUiConfig` in
/// `ui/domain/l10n/`); a generic piece reads them with [UiConfig.of]. With no
/// provider (a test, a future host app) the English defaults below apply.
@immutable
class UiStrings {
  const UiStrings({
    this.close = 'Close',
    this.cancel = 'Cancel',
    this.save = 'Save',
    this.undo = 'Undo',
    this.search = 'Search',
    this.retry = 'Retry',
    this.clear = 'Clear',
    this.edit = 'Edit',
    this.longPressToEdit = 'Long-press to edit',
    this.discardTitle = 'Discard your changes?',
    this.discardMessage = "What you changed won't be saved.",
    this.discardConfirm = 'Discard changes',
    this.keepEditing = 'Keep editing',
    this.monthPickerTitle = 'Pick a month',
    this.monthPrev = 'Previous month',
    this.monthNext = 'Next month',
    this.currencySymbol = '฿',
    this.pickDate = 'Pick a date',
    this.today = 'Today',
    this.periodPrev = 'Previous',
    this.periodNext = 'Next',
    this.yearPrev = 'Previous year',
    this.yearNext = 'Next year',
    this.thisMonth = 'This month',
    this.dayNone = 'Not set',
    this.dayLast = 'Last day of the month',
    this.dayLastShort = 'Last',
    this.dayEveryMonth = _dayEveryMonth,
    this.manageTitle = 'Manage',
    this.fieldName = 'Name',
    this.fieldDescription = 'Description',
    this.recordCreated = 'Created',
    this.recordUpdated = 'Last edited',
    this.reorderOutdent = 'Move out a level',
    this.reorderMoveUp = 'Move up',
    this.reorderMoveDown = 'Move down',
    this.reorderIndent = 'Move in a level',
  });

  final String close;
  final String cancel;
  final String save;
  final String undo;
  final String search;
  final String retry;

  /// The small field-name labels of an entity hero in create / edit mode.
  final String fieldName;
  final String fieldDescription;
  final String clear;
  final String edit;

  /// The view-mode hint of an empty, editable field.
  final String longPressToEdit;

  /// The dirty-close question of a form ("Discard your changes?").
  final String discardTitle;
  final String discardMessage;
  final String discardConfirm;
  final String keepEditing;

  final String monthPickerTitle;
  final String monthPrev;
  final String monthNext;

  /// The user's single currency symbol (the amount input's prefix).
  final String currencySymbol;
  final String pickDate;
  final String today;
  final String periodPrev;
  final String periodNext;
  final String yearPrev;
  final String yearNext;
  final String thisMonth;

  /// Day-of-month picker: "not set", "last day", and "{day} of every month".
  final String dayNone;
  final String dayLast;

  /// The same, short enough for a grid cell.
  final String dayLastShort;
  final String Function(int day) dayEveryMonth;

  /// A detail page's manage section (archive / delete).
  final String manageTitle;

  /// Record info lines at the bottom of a detail page.
  final String recordCreated;
  final String recordUpdated;

  /// Reorder bar buttons.
  final String reorderOutdent;
  final String reorderMoveUp;
  final String reorderMoveDown;
  final String reorderIndent;

  static String _dayEveryMonth(int d) => '$d of every month';
}

/// How a failure reads to the user: an icon, a headline, a sentence.
@immutable
class UiErrorInfo {
  const UiErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

/// Turns any error object into [UiErrorInfo]. The app maps its own exception
/// type (network / server / unknown); the default describes everything as
/// unexpected.
abstract class UiErrors {
  const UiErrors();

  UiErrorInfo describe(Object error);
}

class _DefaultErrors extends UiErrors {
  const _DefaultErrors();

  @override
  UiErrorInfo describe(Object error) => const UiErrorInfo(
    icon: Icons.error_outline,
    title: 'Unexpected error',
    message: 'Something we did not expect happened. Please try again.',
  );
}

/// Provides [UiStrings] and [UiErrors] to everything below it.
class UiConfig extends InheritedWidget {
  const UiConfig({
    required this.strings,
    required this.errors,
    required super.child,
    super.key,
  });

  final UiStrings strings;
  final UiErrors errors;

  static const _defaults = UiConfig(
    strings: UiStrings(),
    errors: _DefaultErrors(),
    child: SizedBox.shrink(),
  );

  static UiConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UiConfig>() ?? _defaults;

  /// Shorthand for `UiConfig.of(context).strings`.
  static UiStrings stringsOf(BuildContext context) => of(context).strings;

  @override
  bool updateShouldNotify(UiConfig old) =>
      strings != old.strings || errors != old.errors;
}
