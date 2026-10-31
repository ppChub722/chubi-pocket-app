import 'package:flutter/material.dart';

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
    this.loadMoreFailed = "Couldn't load more",
    this.pickDatesHint = 'Tap the days to pick them',
    this.more = 'More',
    this.comingSoon = 'Coming soon',
  });

  final String close;
  final String more;

  /// The badge of a row that is not built yet ("เร็วๆ นี้").
  final String comingSoon;

  final String loadMoreFailed;

  final String pickDatesHint;
  final String cancel;
  final String save;
  final String undo;
  final String search;
  final String retry;

  final String fieldName;
  final String fieldDescription;
  final String clear;
  final String edit;

  final String longPressToEdit;

  final String discardTitle;
  final String discardMessage;
  final String discardConfirm;
  final String keepEditing;

  final String monthPickerTitle;
  final String monthPrev;
  final String monthNext;

  final String currencySymbol;
  final String pickDate;
  final String today;
  final String periodPrev;
  final String periodNext;
  final String yearPrev;
  final String yearNext;
  final String thisMonth;

  final String dayNone;
  final String dayLast;

  final String dayLastShort;
  final String Function(int day) dayEveryMonth;

  final String manageTitle;

  final String recordCreated;
  final String recordUpdated;

  final String reorderOutdent;
  final String reorderMoveUp;
  final String reorderMoveDown;
  final String reorderIndent;

  static String _dayEveryMonth(int d) => '$d of every month';
}

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

/// One form's saves, so a retry is safe: the app sends each write of [run]
/// with a key the server remembers (B2). One runner per edit, kept until it
/// saves or is cancelled.
abstract interface class SaveRunner {
  Future<T> run<T>(Future<T> Function() save);
}

class UiConfig extends InheritedWidget {
  const UiConfig({
    required this.strings,
    required this.errors,
    required super.child,
    this.saveRunner,
    super.key,
  });

  final UiStrings strings;
  final UiErrors errors;

  /// A new [SaveRunner] for an edit; null = saves run as they are.
  final SaveRunner Function()? saveRunner;

  static const _defaults = UiConfig(
    strings: UiStrings(),
    errors: _DefaultErrors(),
    child: SizedBox.shrink(),
  );

  static UiConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UiConfig>() ?? _defaults;

  static UiStrings stringsOf(BuildContext context) => of(context).strings;

  @override
  bool updateShouldNotify(UiConfig old) =>
      strings != old.strings ||
      errors != old.errors ||
      saveRunner != old.saveRunner;
}
