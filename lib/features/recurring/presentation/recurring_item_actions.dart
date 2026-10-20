import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../data/recurring_repository.dart';
import '../domain/recurring_item.dart';

Future<bool> _sheetWrite(
  BuildContext context,
  Future<ItemWriteResult> Function(RecurringRepository repo) run,
  ValueChanged<ItemWriteResult> onChanged,
) async {
  final repo = RecurringRepository.of(context);
  final accounts = context.read<AccountsCubit>();
  try {
    final result = await run(repo);
    accounts.patchBalances(result.balances);
    HapticFeedback.mediumImpact();
    onChanged(result);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
    return false;
  }
}

Future<void> editRecurringItem(
  BuildContext context,
  RecurringItem item, {
  required ValueChanged<ItemWriteResult> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  return showEntrySheet(
    context,
    title: l.recurringItemEditTitle,
    initial: item.toDraft(),
    actions: [
      EntrySheetAction(
        label: l.commonSave,
        onPressed: (draft) async {
          var scope = EditScope.thisOne;
          if (item.recurring != null) {
            final picked = await askItemScope(context);
            if (picked == null) return false;
            scope = picked;
          }
          if (!context.mounted) return false;
          var alsoUpdateLink = false;
          if (item.linked) {
            final choice = await showLinkedPrompt(
              context,
              title: l.linkedSaveTitle,
              cancelLabel: l.linkedCancel,
              thisSideLabel: l.linkedSaveThisOnly,
              bothSidesLabel: l.linkedSaveBoth,
            );
            if (choice == null) return false;
            alsoUpdateLink = choice == LinkedChoice.bothSides;
          }
          if (!context.mounted) return false;
          return _sheetWrite(
            context,
            (r) => r.updateItem(
              item.id,
              draft,
              scope: scope,
              alsoUpdateLink: alsoUpdateLink,
            ),
            onChanged,
          );
        },
      ),
    ],
  );
}

Future<EditScope?> askItemScope(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return showEditScopeChoice(
    context,
    title: l.recurringScopeTitle,
    options: {
      EditScope.thisOne: l.recurringScopeThis,
      EditScope.following: l.recurringScopeFollowing,
      EditScope.past: l.recurringScopePast,
      EditScope.upcoming: l.recurringScopeUpcoming,
      EditScope.all: l.recurringScopeAll,
    },
    selected: EditScope.thisOne,
  );
}
