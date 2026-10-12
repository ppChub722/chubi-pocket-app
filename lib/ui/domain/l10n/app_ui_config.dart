import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../atoms/ui_config.dart';
import '../../tokens/app/app_icons.dart';

/// The app's Thai: fills the generic kit's [UiConfig] from the app
/// localisation and maps [ApiException] to the three failure descriptions
/// (no connection / server / unexpected). Installed once, in the app's
/// `MaterialApp.builder`, so every page, sheet and dialog sees it.
class AppUiConfig extends StatelessWidget {
  const AppUiConfig({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return UiConfig(
      strings: UiStrings(
        close: l.commonClose,
        cancel: l.commonCancel,
        save: l.commonSave,
        undo: l.commonUndo,
        search: l.commonSearch,
        retry: l.commonRetry,
        clear: l.commonClear,
        pickDate: l.uiPickDate,
        today: l.commonToday,
        edit: l.commonEdit,
        longPressToEdit: l.commonLongPressToEdit,
        discardTitle: l.editDiscardTitle,
        discardMessage: l.editDiscardMessage,
        discardConfirm: l.editDiscardConfirm,
        keepEditing: l.editKeepEditing,
        monthPickerTitle: l.monthPickerTitle,
        monthPrev: l.monthPickerPrevMonth,
        monthNext: l.monthPickerNextMonth,
        periodPrev: l.txPeriodPrev,
        periodNext: l.txPeriodNext,
        yearPrev: l.monthPickerPrevYear,
        yearNext: l.monthPickerNextYear,
        thisMonth: l.monthPickerThisMonth,
        dayNone: l.dayPickerNone,
        dayLast: l.dayPickerLastDay,
        dayLastShort: l.dayPickerLastShort,
        dayEveryMonth: l.dayPickerEveryMonth,
        manageTitle: l.detailManageTitle,
        fieldName: l.commonName,
        fieldDescription: l.commonDescription,
        recordCreated: l.txDetailCreatedAt,
        recordUpdated: l.txDetailUpdatedAt,
        reorderOutdent: l.reorderOutdent,
        reorderMoveUp: l.reorderMoveUp,
        reorderMoveDown: l.reorderMoveDown,
        reorderIndent: l.reorderIndent,
      ),
      errors: _AppErrors(l),
      child: child,
    );
  }
}

class _AppErrors extends UiErrors {
  const _AppErrors(this.l);

  final AppLocalizations l;

  @override
  UiErrorInfo describe(Object error) {
    final e = error is ApiException ? error : null;
    final network =
        e != null && (e.code == 'NETWORK_ERROR' || e.code == 'NETWORK_TIMEOUT');
    final server = e != null && (e.statusCode ?? 0) >= 500;
    if (network) {
      return UiErrorInfo(
        icon: AppIcons.offline,
        title: l.errorNetworkTitle,
        message: l.errorNetworkMessage,
      );
    }
    if (server) {
      return UiErrorInfo(
        icon: AppIcons.serverDown,
        title: l.errorServerTitle,
        message: l.errorServerMessage,
      );
    }
    return UiErrorInfo(
      icon: AppIcons.error,
      title: l.errorUnknownTitle,
      message: l.errorUnknownMessage,
    );
  }

  // Rebuilt with the localisation, so a language switch re-describes.
  @override
  bool operator ==(Object other) => other is _AppErrors && other.l == l;

  @override
  int get hashCode => l.hashCode;
}
