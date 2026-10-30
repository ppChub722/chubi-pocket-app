import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../contacts/presentation/widgets/contact_picker.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';
import 'widgets/member_picker.dart';
import 'widgets/project_common.dart';

/// The BillPerson body for a picked person (me, a contact or a name).
Map<String, dynamic> billPersonOf(PayerPick pick) => switch (pick) {
  PayerMe() => {'me': true},
  PayerPerson(:final pick) => switch (pick) {
    ContactPicked(:final contact) => {'contact_id': contact.id},
    ContactNamePicked(:final name) ||
    ContactNameTyped(:final name) => {'person_name': name},
  },
};

/// V15: who takes a removed member's empty spots ("( ) ____"): [billIds]
/// = those bills only, empty = all of theirs. ONE call; null when cancelled
/// or refused (the error is shown).
Future<EventPatch?> assignEmptySpots(
  BuildContext context, {
  required ProjectView view,
  required ProjectMember removed,
  List<String> billIds = const [],
}) async {
  final l = AppLocalizations.of(context)!;
  final pick = await ContactPicker.payer(
    context,
    me: PickerNone(label: l.evbAssignMe, icon: AppIcons.profile),
    title: l.evbAssignTitle,
  );
  if (pick == null || !context.mounted) return null;
  final repo = context.read<ProjectsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final patch = await repo.assignRemovedMember(
      view.project.id,
      removed.id,
      to: billPersonOf(pick),
      billIds: billIds,
    );
    showAppSnackBarOn(messenger, l.evbAssigned, tone: Tone.success);
    return patch;
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, errorText(l, e), tone: Tone.danger);
    return null;
  }
}

/// The ต้องจัดการ "ใส่คน": which removed member first when there are
/// several, then [assignEmptySpots] over all of their bills.
Future<EventPatch?> assignAllEmptySpots(
  BuildContext context, {
  required ProjectView view,
}) async {
  final l = AppLocalizations.of(context)!;
  final removed = [
    for (final m in view.members)
      if (m.isRemoved) m,
  ];
  if (removed.isEmpty) return null;
  final who = removed.length == 1
      ? removed.single
      : await EventMemberPicker.one(
          context,
          members: removed,
          title: l.evbAssignWhose,
        );
  if (who == null || !context.mounted) return null;
  return assignEmptySpots(context, view: view, removed: who);
}
