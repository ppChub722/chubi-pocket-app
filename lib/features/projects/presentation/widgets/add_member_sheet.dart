import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../event_errors.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

Future<({String name, EventPatch patch})?> showAddMemberSheet(
  BuildContext context, {
  required String projectId,
}) async {
  final l = AppLocalizations.of(context)!;
  final repo = context.read<ProjectsRepository>();
  EventPatch? patch;
  final name = await showAddMemberFormSheet(
    context,
    labels: AddMemberLabels(
      title: l.projectMembersInvite,
      submit: l.projectAddMemberSubmit,
      fromContacts: l.projectAddMemberFromContacts,
      name: l.projectAddMemberName,
      nameRequired: l.projectAddMemberNameRequired,
      email: l.projectAddMemberEmail,
      emailHint: l.projectAddMemberEmailHint,
    ),
    onFromContacts: () async {
      final r = await showContactPickerSheet(context, allowFreeText: false);
      if (r is! ContactPicked) return null;
      return AddMemberFill(name: r.contact.name, email: r.contact.email);
    },
    onSubmit: (name, email) async {
      try {
        patch = await repo.addMember(
          projectId,
          displayName: name,
          email: email,
          role: MemberRole.contributor,
          adHoc: email == null,
        );
        return true;
      } on ApiException catch (e) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            eventErrorText(AppLocalizations.of(context)!, e),
            tone: Tone.danger,
          );
        }
        return false;
      }
    },
  );
  final p = patch;
  return name == null || p == null ? null : (name: name, patch: p);
}
