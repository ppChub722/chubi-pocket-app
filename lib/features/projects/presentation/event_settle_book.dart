import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/user_currency.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/widgets/account_picker.dart';
import '../../categories/domain/category_type.dart';
import '../../categories/presentation/widgets/category_picker.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// V12 "ลงในสมุดฉัน" (completed event, once): for each of my
/// fewest-transfers lines I pick the wallet and the category of the money
/// that really moves (Q-E5), then ONE confirm and ONE call. Answers the new
/// settle, or null (cancelled / refused, the error shown).
Future<EventSettle?> bookMySettle(
  BuildContext context, {
  required String projectId,
  required EventSettle settle,
}) async {
  final l = AppLocalizations.of(context)!;
  final repo = context.read<ProjectsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final symbol = context.readUserCurrencySymbol;
  final lines = <Map<String, dynamic>>[];
  final summary = <String>[];
  for (final x in settle.mySimplified) {
    final iPay = x.from.isMe;
    final other = iPay ? x.to : x.from;
    final money = moneyString(context, x.amount, symbol: symbol);
    final what = iPay
        ? l.evbBookLinePay(other.name, money)
        : l.evbBookLineGet(other.name, money);
    final wallet = await AccountPicker.one(
      context,
      title: what,
      allowNone: true,
    );
    if (wallet == null || !context.mounted) return null;
    final category = await CategoryPicker.one(
      context,
      types: {iPay ? CategoryType.expense : CategoryType.income},
      allowNone: true,
      title: what,
    );
    if (category == null || !context.mounted) return null;
    lines.add({
      'member_id': other.id,
      'account_id': wallet is AccountPicked ? wallet.account.id : null,
      'category_id': category is CategoryPicked ? category.category.id : null,
    });
    summary.add(what);
  }
  if (lines.isEmpty || !context.mounted) return null;
  final ok = await showConfirmDialog(
    context,
    title: l.evbSettleBookTitle,
    message: [...summary, '', l.evbSettleBookBody].join('\n'),
    confirmLabel: l.evbSettleBook,
  );
  if (!ok) return null;
  try {
    final next = await repo.bookEventSettle(projectId, lines: lines);
    showAppSnackBarOn(messenger, l.evbSettleBooked, tone: Tone.success);
    return next;
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, switch (e.code) {
      'SETTLE_BOOKED' => l.evbSettleAlreadyBooked,
      _ => errorText(l, e),
    }, tone: Tone.danger);
    return null;
  }
}
