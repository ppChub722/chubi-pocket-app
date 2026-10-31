import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/idempotency.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../atoms/ui_config.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/currencies.dart';
import '../money/money_style.dart';
import 'app_error_text.dart';

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
        more: l.commonMore,
        comingSoon: l.settingsComingSoon,
        currencySymbol: _userCurrencySymbol(context),
      ),
      errors: _AppErrors(l),
      saveRunner: _IdempotentSaves.new,
      child: MoneyStyleScope(style: _userMoneyStyle(context), child: child),
    );
  }
}

/// B2: every edit page's save sends its writes with Idempotency-Key.
class _IdempotentSaves implements SaveRunner {
  final _keys = Idempotency();

  @override
  Future<T> run<T>(Future<T> Function() save) => _keys.run(save);
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
    if (isNetworkError(error)) {
      final slow = isSlowNetworkError(error);
      return UiErrorInfo(
        icon: AppIcons.offline,
        title: slow ? l.errorSlowTitle : l.errorNetworkTitle,
        message: slow ? l.errorSlowMessage : l.errorNetworkMessage,
      );
    }
    if (error is ApiException && error.code == 'SERVER_UNAVAILABLE') {
      return UiErrorInfo(
        icon: AppIcons.error,
        title: l.errorServerDownTitle,
        message: l.errorServerDownMessage,
      );
    }
    final text = errorText(l, error);
    // The generic sentence keeps its own headline; every other one is the
    // headline itself.
    if (text == l.errorGenericMessage) {
      return UiErrorInfo(
        icon: AppIcons.error,
        title: l.errorGenericTitle,
        message: l.errorGenericMessage,
      );
    }
    return UiErrorInfo(icon: AppIcons.error, title: text, message: text);
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
