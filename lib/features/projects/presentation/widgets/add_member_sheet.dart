import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// "เชิญสมาชิก" — `POST /projects/:id/members`. With an email the matching
/// app user gets an invite; without one it's a member without an account
/// (can be linked later). "เลือกจากผู้ติดต่อ" fills name + email. Returns
/// the added name, or null when dismissed.
Future<String?> showAddMemberSheet(
  BuildContext context, {
  required String projectId,
}) {
  return showAppSheet<String>(
    context,
    title: AppLocalizations.of(context)!.projectMembersInvite,
    builder: (_) => _AddMemberSheet(projectId: projectId),
  );
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.projectId});
  final String projectId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _fromContacts() async {
    final r = await showContactPickerSheet(context, allowFreeText: false);
    if (r is! ContactPicked) return;
    setState(() {
      _name.text = r.contact.effectiveName;
      _email.text = r.contact.effectiveEmail ?? '';
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    setState(() => _saving = true);
    try {
      // New members start as members; the owner can make them view-only
      // from the members page (contract §6b).
      await context.read<ProjectsRepository>().addMember(
        widget.projectId,
        displayName: name,
        email: email.isEmpty ? null : email,
        role: MemberRole.contributor,
        adHoc: email.isEmpty,
      );
      if (mounted) Navigator.pop(context, name);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          // No keyboard inset here — AppSheetScaffold (showAppSheet) adds it.
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: l.projectAddMemberFromContacts,
              icon: AppIcons.contact,
              variant: AppButtonVariant.tonal,
              onPressed: _saving ? null : _fromContacts,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _name,
              label: l.projectAddMemberName,
              prefixIcon: AppIcons.member,
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? l.projectAddMemberNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _email,
              label: l.projectAddMemberEmail,
              helper: l.projectAddMemberEmailHint,
              prefixIcon: AppIcons.send,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.projectAddMemberSubmit,
              icon: AppIcons.inviteMember,
              expand: true,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
