import 'package:flutter/material.dart';

/// The words and error descriptions the generic kit needs (owner 2026-10-12:
/// generic pieces never read the app's localisation). The app supplies the
/// real ones once, at its root, with [PpForgeConfig] (see `AppUiConfig` in
/// `ui/domain/l10n/`); a generic piece reads them with [PpForgeConfig.of]. With no
/// provider (a test, a future host app) the English defaults below apply.
@immutable
class PpForgeStrings {
  const PpForgeStrings({
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
    this.iconMaker = const PpForgeIconMakerStrings(),
  });

  final String close;

  /// The paging footer of a list when the next page failed.
  final String loadMoreFailed;

  /// The multi-date picker's line while nothing is picked.
  final String pickDatesHint;
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

  /// The icon maker sheet and the icon shapes.
  final PpForgeIconMakerStrings iconMaker;

  static String _dayEveryMonth(int d) => '$d of every month';
}

/// The icon maker's words ([PpForgeStrings.iconMaker]).
@immutable
class PpForgeIconMakerStrings {
  const PpForgeIconMakerStrings({
    this.title = 'Icon',
    this.useThis = 'Use this',
    this.useDefault = "Use the app's default icon",
    this.tabStyle = 'Style',
    this.tabColor = 'Color',
    this.roleIcon = 'Icon',
    this.roleBackground = 'Background',
    this.roleBorder = 'Border',
    this.searchHint = 'Search icons, e.g. car, home',
    this.all = 'All',
    this.noMatch = _noMatch,
    this.shape = 'Shape',
    this.pattern = 'Pattern',
    this.themeColors = 'Theme',
    this.commonColors = 'Common',
    this.customColors = 'Custom',
    this.layerOff = _layerOff,
    this.notRecolorable = 'This style has fixed colors',
    this.pickColor = 'Pick a color',
    this.resetSlot = 'Reset this color',
    this.reset = 'Reset to default',
    this.resetConfirmTitle = 'Reset icon?',
    this.resetConfirmBody =
        'Icon, colors, background and border go back to the defaults. '
        'You can undo it.',
    this.colorWheelTitle = 'Pick a colour',
    this.colorWheelUse = 'Use colour',
    this.shapeCircle = 'Circle',
    this.shapeSquircle = 'Squircle',
    this.shapeRounded = 'Rounded',
    this.shapeSquare = 'Square',
    this.shapeLeaf = 'Leaf',
    this.shapeDrop = 'Drop',
  });

  /// The sheet's default heading.
  final String title;
  final String useThis;

  /// The ⋯ menu row that drops the custom icon.
  final String useDefault;
  final String tabStyle;
  final String tabColor;

  /// The three editable layers.
  final String roleIcon;
  final String roleBackground;
  final String roleBorder;
  final String searchHint;

  /// The search's "every group" chip.
  final String all;
  final String Function(String query) noMatch;
  final String shape;
  final String pattern;

  /// The colour tab's swatch sections.
  final String themeColors;
  final String commonColors;
  final String customColors;

  /// A layer with no style yet ("{layer}: none — pick a style first").
  final String Function(String layer) layerOff;
  final String notRecolorable;
  final String pickColor;
  final String resetSlot;
  final String reset;
  final String resetConfirmTitle;
  final String resetConfirmBody;

  /// The HSV colour wheel dialog.
  final String colorWheelTitle;
  final String colorWheelUse;

  /// The background outlines (`IconShape`).
  final String shapeCircle;
  final String shapeSquircle;
  final String shapeRounded;
  final String shapeSquare;
  final String shapeLeaf;
  final String shapeDrop;

  static String _noMatch(String q) => 'No icons match "$q"';
  static String _layerOff(String layer) => '$layer: none — pick a style first';
}

/// How a failure reads to the user: an icon, a headline, a sentence.
@immutable
class PpForgeErrorInfo {
  const PpForgeErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

/// Turns any error object into [PpForgeErrorInfo]. The app maps its own exception
/// type (network / server / unknown); the default describes everything as
/// unexpected.
abstract class PpForgeErrors {
  const PpForgeErrors();

  PpForgeErrorInfo describe(Object error);
}

class _DefaultErrors extends PpForgeErrors {
  const _DefaultErrors();

  @override
  PpForgeErrorInfo describe(Object error) => const PpForgeErrorInfo(
    icon: Icons.error_outline,
    title: 'Unexpected error',
    message: 'Something we did not expect happened. Please try again.',
  );
}

/// Provides [PpForgeStrings] and [PpForgeErrors] to everything below it.
class PpForgeConfig extends InheritedWidget {
  const PpForgeConfig({
    required this.strings,
    required this.errors,
    required super.child,
    super.key,
  });

  final PpForgeStrings strings;
  final PpForgeErrors errors;

  static const _defaults = PpForgeConfig(
    strings: PpForgeStrings(),
    errors: _DefaultErrors(),
    child: SizedBox.shrink(),
  );

  static PpForgeConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PpForgeConfig>() ?? _defaults;

  /// Shorthand for `PpForgeConfig.of(context).strings`.
  static PpForgeStrings stringsOf(BuildContext context) => of(context).strings;

  @override
  bool updateShouldNotify(PpForgeConfig old) =>
      strings != old.strings || errors != old.errors;
}
