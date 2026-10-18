import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';
import '../../../users/presentation/refresh_me.dart';

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
  late User _user;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    final s = context.read<AuthCubit>().state;
    _user = s is AuthAuthenticated
        ? s.user
        : ((s as AuthLoading).previous as AuthAuthenticated).user;
    initDraft(_ProfileDraft.from(_user), editing: false);
    onDraftRestored();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
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
        displayName: working.name.trim().isEmpty
            ? _user.displayName
            : working.name,
        iconCode: code,
      ),
    );
    if (!mounted || r == null) return;
    if (r is IconMakerSelected) {
      applyChange(working.copyWith(iconCode: r.iconCode));
    }
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
      _user = updated;
      commitSaved(_ProfileDraft.from(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      if (e.code == 'EMAIL_EXISTS') {
        setState(() => _emailError = l.editProfileEmailTaken);
        _formKey.currentState?.validate();
      } else {
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
    }
  }

  String get _shownName =>
      working.name.trim().isEmpty ? _user.displayName : working.name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final editing = isEditing;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && !isEditing) {
          _user = state.user;
          resetDraft(_ProfileDraft.from(state.user));
        }
      },
      child: editScope(
        Scaffold(
          appBar: AppTopBar(
            title: l.profileTitle,
            showBack: true,
            editing: editing,
            onBack: handleBack,
          ),
          extendBodyBehindAppBar: true,
          body: Form(
            key: _formKey,
            child: Builder(
              builder: (context) => DetailLayout(
                onRefresh: () => refreshMe(context),
                physics: const AlwaysScrollableScrollPhysics(),
                topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                bottomInset:
                    AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
                hero: _hero(l, editing),
                info: SectionCard(
                  children: [
                    DetailTextField(
                      label: l.editProfileEmailLabel,
                      controller: _emailCtrl,
                      editing: editing,
                      placeholderWhenEmpty: true,
                      notSetLabel: l.contactFieldNotSet,
                      maxLength: TextLimits.email,
                      keyboardType: TextInputType.emailAddress,
                      viewHint: l.commonLongPressToEdit,
                      onEnterEdit: () => enterEdit(),
                      onChanged: (v) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                        applyTextChange(
                          _Field.email,
                          working.copyWith(email: v),
                        );
                      },
                      validator: (v) {
                        if (_emailError != null) return _emailError;
                        final s = v?.trim() ?? '';
                        // Once set, the email can't go back to empty.
                        if (s.isEmpty) {
                          return original.email.isEmpty
                              ? null
                              : l.profileEmailCannotClear;
                        }
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                            ? null
                            : l.editProfileEmailInvalid;
                      },
                    ),
                  ],
                ),
                settings: editing
                    ? null
                    : SettingsSection(
                        title: l.profileSectionSecurity,
                        children: [
                          DetailRow(
                            leading: const AppIcon(AppIcons.lock),
                            label: l.editProfileUsernameLabel,
                            helper: l.profileUsernameLocked,
                            locked: true,
                            trailing: Text('@${_user.username}'),
                          ),
                          DetailRow(
                            leading: const AppIcon(AppIcons.lock),
                            label: l.settingsChangePassword,
                            showChevron: true,
                            onTap: () => context.push('/settings/password'),
                          ),
                        ],
                      ),
                metaLines: detailMetaLines(
                  context,
                  createdAt: _user.createdAt,
                  updatedAt: _user.updatedAt,
                ),
              ),
            ),
          ),
          bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
        ),
      ),
    );
  }

  Widget _hero(AppLocalizations l, bool editing) {
    final w = working;
    final style = HeroStyle.tinted(
      color: w.iconCode.tintFor(
        Theme.of(context).extension<AppColors>()!,
        avatarName: _shownName,
      ),
      glyph: AppIcons.profile,
    );
    if (editing) {
      return AppHeroCard(
        style: style,
        mode: HeroCardMode.edit,
        content: [
          HeroIdentity(
            icon: EditableCircle(
              size: 44,
              onTap: _pickAvatar,
              child: UserAvatar(
                displayName: _shownName,
                iconCode: w.iconCode,
                size: 44,
              ),
            ),
            name: HeroNameInput(
              editing: true,
              controller: _nameCtrl,
              hint: l.editProfileDisplayNameLabel,
              maxLength: TextLimits.name,
              onChanged: (v) =>
                  applyTextChange(_Field.name, working.copyWith(name: v)),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return l.commonRequired;
                if (s.length > TextLimits.name) {
                  return l.authRegisterDisplayNameTooLong;
                }
                return null;
              },
            ),
          ),
        ],
      );
    }
    return AppHeroCard(
      style: style,
      header: HeroHeader(onEdit: enterEdit),
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: 40,
            onLongPress: () => enterEdit(),
            child: UserAvatar(
              displayName: _shownName,
              iconCode: w.iconCode,
              size: 40,
            ),
          ),
          name: Text(_shownName),
          fact: Text('@${_user.username}'),
        ),
      ],
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({required this.name, required this.email, this.iconCode});

  factory _ProfileDraft.from(User u) => _ProfileDraft(
    name: u.displayName,
    email: u.email ?? '',
    iconCode: u.iconCode,
  );

  final String name;
  final String email;
  final IconCode? iconCode;

  _ProfileDraft copyWith({
    String? name,
    String? email,
    IconCode? iconCode,
    bool clearIcon = false,
  }) => _ProfileDraft(
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
