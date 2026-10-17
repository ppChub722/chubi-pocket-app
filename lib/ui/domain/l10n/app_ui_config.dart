import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../atoms/ui_config.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/currencies.dart';
import '../money/money_style.dart';

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
        loadMoreFailed: l.uiLoadMoreFailed,
        pickDatesHint: l.uiPickDatesHint,
        currencySymbol: _userCurrencySymbol(context),
      ),
      errors: _AppErrors(l),
      child: MoneyStyleScope(style: _userMoneyStyle(context), child: child),
    );
  }
}

MoneyStyle _userMoneyStyle(BuildContext context) {
  try {
    final (style, decimals) = context.select<AuthCubit, (String?, String?)>(
      (c) => switch (c.state) {
        AuthAuthenticated(:final user) => (user.moneyStyle, user.moneyDecimals),
        _ => (null, null),
      },
    );
    return MoneyStyle.fromPreferences(style: style, decimals: decimals);
  } on ProviderNotFoundException {
    return MoneyStyle.legacy;
  }
}

class _AppErrors extends UiErrors {
  const _AppErrors(this.l);

  final AppLocalizations l;

  @override
  UiErrorInfo describe(Object error) {
    final e = error is ApiException ? error : null;
    final network =
        error is TimeoutException ||
        (e != null &&
            (e.code == 'NETWORK_ERROR' || e.code == 'NETWORK_TIMEOUT'));
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
    final known = switch (e?.code) {
      'INVALID_CREDENTIALS' => l.authLoginInvalidCredentials,
      'WRONG_PASSWORD' => l.changePasswordCurrentWrong,
      'USERNAME_EXISTS' => l.authRegisterUsernameTaken,
      'EMAIL_EXISTS' => l.authRegisterEmailTaken,
      'VALIDATION_ERROR' => l.errorValidationMessage,
      _ => null,
    };
    if (known != null) {
      return UiErrorInfo(icon: AppIcons.error, title: known, message: known);
    }
    return UiErrorInfo(
      icon: AppIcons.error,
      title: l.errorUnknownTitle,
      message: l.errorUnknownMessage,
    );
  }

  @override
  bool operator ==(Object other) => other is _AppErrors && other.l == l;

  @override
  int get hashCode => l.hashCode;
}

String _userCurrencySymbol(BuildContext context) {
  const fallback = UiStrings();
  try {
    final code = context.select<AuthCubit, String?>(
      (c) => switch (c.state) {
        AuthAuthenticated(:final user) => user.currency,
        _ => null,
      },
    );
    return code == null ? fallback.currencySymbol : Currencies.symbolOf(code);
  } on ProviderNotFoundException {
    return fallback.currencySymbol;
  }
}
