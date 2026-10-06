import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../../shared/widgets/user_profile_preview.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';

/// `/settings/profile` (§7) — opens straight in edit mode: header card
/// (avatar → icon maker, name inline), username (locked), email. Default
/// currency lives on the settings page only.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

enum _Field { name, email }

class _EditProfilePageState extends State<EditProfilePage>
    with EditModeMixin<EditProfilePage, _ProfileDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  late final User _user;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Reached from settings, so the user is signed in (possibly refreshing).
    final s = context.read<AuthCubit>().state;
    _user = s is AuthAuthenticated
        ? s.user
        : ((s as AuthLoading).previous as AuthAuthenticated).user;
    initDraft(_ProfileDraft.from(_user), editing: true);
    onDraftRestored();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  bool get leaveOnCancel => true;

  @override
  void leavePage() {
    if (context.canPop()) context.pop();
  }

  @override
  void onDraftRestored() {
    if (_nameCtrl.text != working.name) _nameCtrl.text = working.name;
    if (_emailCtrl.text != working.email) _emailCtrl.text = working.email;
  }

  Future<void> _pickAvatar() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.userProfile,
      title: l.editProfileTitle,
      initial: working.iconCode,
      removeLabel: l.commonRemove,
      previewBuilder: (code) => UserProfilePreview(
        displayName: working.name.trim().isEmpty ? _user.displayName : working.name,
        iconCode: code,
      ),
    );
    if (!mounted || r == null) return;
    if (r is IconMakerSelected) applyChange(working.copyWith(iconCode: r.iconCode));
    if (r is IconMakerRemoved) applyChange(working.copyWith(clearIcon: true));
  }

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context)!;
    final w = working;
    final o = original;
    final email = w.email.trim();
    final emailChanged = email.isNotEmpty && email != o.email;
    final iconChanged = w.iconCode != o.iconCode;
    final auth = context.read<AuthCubit>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    setState(() => _emailError = null);
    try {
      final updated = await context.read<UsersRepository>().updateMe(
            displayName: w.name.trim() != o.name ? w.name.trim() : null,
            email: emailChanged ? email : null,
            iconCode: iconChanged ? w.iconCode : null,
            clearIconCode: iconChanged && w.iconCode == null,
          );
      auth.updateUser(updated);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showAppSnackBar(context, l.editProfileSnackSuccess, tone: Tone.success);
      commitSaved(w);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      if (e.code == 'EMAIL_EXISTS') {
        setState(() => _emailError = l.editProfileEmailTaken);
      } else {
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final w = working;
    return editScope(Scaffold(
      appBar: AppTopBar(
        title: l.editProfileTitle,
        showBack: true,
        editing: true,
        onBack: handleBack,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
          children: [
            HeaderCard(
              leading: EditableCircle(
                size: 64,
                onTap: _pickAvatar,
                child: UserAvatar(
                  displayName: w.name.trim().isEmpty ? _user.displayName : w.name,
                  iconCode: w.iconCode,
                  size: 64,
                ),
              ),
              title: InlineTitleField(
                editing: true,
                controller: _nameCtrl,
                hint: l.editProfileDisplayNameLabel,
                onChanged: (v) =>
                    applyTextChange(_Field.name, working.copyWith(name: v)),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return l.commonRequired;
                  if (s.length > 100) return l.authRegisterDisplayNameTooLong;
                  return null;
                },
              ),
              subtitle: Text('@${_user.username}'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              children: [
                DetailRow(
                  leading: const Icon(AppIcons.lock),
                  label: l.editProfileUsernameLabel,
                  helper: l.profileUsernameLocked,
                  trailing: Text('@${_user.username}'),
                ),
                const RowDivider(),
                DetailStacked(
                  label: l.editProfileEmailLabel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InlineField(
                        editing: true,
                        controller: _emailCtrl,
                        maxLength: 255,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) {
                          if (_emailError != null) setState(() => _emailError = null);
                          applyTextChange(_Field.email, working.copyWith(email: v));
                        },
                        validator: (v) {
                          if (_emailError != null) return _emailError;
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return null;
                          if (s.length > 255) return l.editProfileEmailTooLong;
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                              ? null
                              : l.editProfileEmailInvalid;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l.editProfileEmailHelper,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: editActionBar(onSave: _save),
    ));
  }
}

class _ProfileDraft {
  const _ProfileDraft({required this.name, required this.email, this.iconCode});

  factory _ProfileDraft.from(User u) =>
      _ProfileDraft(name: u.displayName, email: u.email ?? '', iconCode: u.iconCode);

  final String name;
  final String email;
  final IconCode? iconCode;

  _ProfileDraft copyWith({
    String? name,
    String? email,
    IconCode? iconCode,
    bool clearIcon = false,
  }) =>
      _ProfileDraft(
        name: name ?? this.name,
        email: email ?? this.email,
        iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
      );

  @override
  bool operator ==(Object other) =>
      other is _ProfileDraft &&
      other.name == name &&
      other.email == email &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(name, email, iconCode);
}
