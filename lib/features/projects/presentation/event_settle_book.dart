import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/user_currency.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/widgets/account_picker.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// V12 "ลงในสมุดฉัน" (completed event, once): my fewest-transfers lines as
/// my debts, with the wallet of the money that really moves (one for all,
/// the paper model), then ONE confirm and ONE call. Answers the new settle,
/// or null (cancelled / refused, the error shown).
Future<EventSettle?> bookMySettle(
  BuildContext context, {
  required String projectId,
  required EventSettle settle,
}) async {
  final l = AppLocalizations.of(context)!;
  final repo = context.read<ProjectsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final symbol = context.readUserCurrencySymbol;
  final summary = <String>[
    for (final x in settle.mySimplified)
      x.from.isMe
          ? l.evbBookLinePay(
              x.to.name,
              moneyString(context, x.amount, symbol: symbol),
            )
          : l.evbBookLineGet(
              x.from.name,
              moneyString(context, x.amount, symbol: symbol),
            ),
  ];
  if (summary.isEmpty) return null;
  final wallet = await AccountPicker.one(
    context,
    title: l.evbSettleBookTitle,
    allowNone: true,
  );
  if (wallet == null || !context.mounted) return null;
  final ok = await showConfirmDialog(
    context,
    title: l.evbSettleBookTitle,
    message: [...summary, '', l.evbSettleBookBody].join('\n'),
    confirmLabel: l.evbSettleBook,
  );
  if (!ok) return null;
  try {
    final next = await repo.bookEventSettle(
      projectId,
      accountId: wallet is AccountPicked ? wallet.account.id : null,
    );
    showPpForgeSnackBarOn(messenger, l.evbSettleBooked, tone: Tone.success);
    return next;
  } on ApiException catch (e) {
    showPpForgeSnackBarOn(messenger, switch (e.code) {
      'SETTLE_BOOKED' => l.evbSettleAlreadyBooked,
      _ => errorText(l, e),
    }, tone: Tone.danger);
    return null;
  }
}
