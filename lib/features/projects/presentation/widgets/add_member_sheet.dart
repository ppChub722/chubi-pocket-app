import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// "เชิญสมาชิก" — `POST /projects/:id/members`. With an email the matching
/// app user gets an invite; without one it's a member without an account
/// (can be linked later). "เลือกจากผู้ติดต่อ" fills name + email. Returns
/// the added name, or null when dismissed. Thin wrapper over the kit's
/// [AddMemberSheet]: the POST + snackbar live here.
Future<String?> showAddMemberSheet(
  BuildContext context, {
  required String projectId,
}) {
  final l = AppLocalizations.of(context)!;
  final repo = context.read<ProjectsRepository>();
  return showAddMemberFormSheet(
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
        // New members start as members; the owner can make them view-only
        // from the members page (contract §6b).
        await repo.addMember(
          projectId,
          displayName: name,
          email: email,
          role: MemberRole.contributor,
          adHoc: email == null,
        );
        return true;
      } on ApiException catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, e.message, tone: Tone.danger);
        }
        return false;
      }
    },
  );
}
