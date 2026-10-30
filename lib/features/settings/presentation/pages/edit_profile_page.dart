import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../connections/data/connections_repository.dart';
import '../../../connections/domain/connection.dart';
import '../../../connections/presentation/connection_actions.dart';
import '../../../connections/presentation/connection_view.dart';
import '../../../connections/presentation/cubit/connections_cubit.dart';
import '../../../users/data/users_repository.dart';
import '../../../users/presentation/refresh_me.dart';
import '../profile_avatar.dart';
import '../profile_changes.dart';

/// โปรไฟล์ (0.4.2 1b, like the contact page). View: the hero (picture +
/// colour dots, name, @username, ✏️, the email row), "การเชื่อมต่อ" (one row
/// per outside app) and "ความปลอดภัย". Edit (✏️ / long-press): the hero
/// with the name and email inputs and the picture preview (tap = the icon
/// maker: full for the icon, colour-only for a photo), then the
/// "รูปโปรไฟล์" radio list. ยกเลิก / บันทึก.
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
  final _usernameCtrl = TextEditingController();
  late User _user;
  String? _emailError;

  /// An import / delete of a picture is running.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AuthCubit>().state;
    _user = s is AuthAuthenticated
        ? s.user
        : ((s as AuthLoading).previous as AuthAuthenticated).user;
    initDraft(_ProfileDraft.from(_user), editing: false);
    onDraftRestored();
    // One call on open: the connection rows (logos, links, pictures).
    context.read<ConnectionsCubit>().load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  void onDraftRestored() {
    if (_nameCtrl.text != working.name) _nameCtrl.text = working.name;
    if (_emailCtrl.text != working.email) _emailCtrl.text = working.email;
  }

  Future<void> _refresh() async {
    final connections = context.read<ConnectionsCubit>();
    await Future.wait([refreshMe(context), connections.load()]);
  }

  String get _shownName =>
      working.name.trim().isEmpty ? _user.displayName : working.name;

  String _date(DateTime? d) => d == null
      ? ''
      : DateFormatter.medium(
          d.toLocal(),
          locale: Localizations.localeOf(context).toLanguageTag(),
        );

  /// The picture the draft will give me (the edit hero's preview).
  AvatarData _preview(List<Connection> items) {
    final w = working;
    String? photoUrl;
    for (final c in items) {
      if (c.provider == w.settings.source) photoUrl = c.photo?.url;
    }
    return profilePreviewAvatar(
      name: _shownName,
      iconCode: w.iconCode,
      settings: w.settings,
      photoUrl: photoUrl,
    );
  }

  Color _tint(AvatarData avatar) => ProfileColors.main(
    avatar,
    palette: Theme.of(context).extension<AppColors>()!,
    surface: Theme.of(context).colorScheme.surface,
  );

  // ── Picture ─────────────────────────────────────────────────────────

  /// Tap on the preview: the full icon maker for the icon, the colour-only
  /// mode for a photo.
  void _editPicture(List<Connection> items) =>
      working.settings.isIcon ? _openIconMaker() : _openColors(items);

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.userProfile,
      title: l.editProfileTitle,
      initial: working.iconCode,
      removeLabel: l.commonRemove,
      previewBuilder: (code) =>
          UserProfilePreview(displayName: _shownName, iconCode: code),
    );
    if (!mounted || r == null) return;
    if (r is IconMakerSelected) {
      applyChange(working.copyWith(iconCode: r.iconCode));
    }
    if (r is IconMakerRemoved) applyChange(working.copyWith(clearIcon: true));
  }

  Future<void> _openColors(List<Connection> items) async {
    final l = AppLocalizations.of(context)!;
    final settings = working.settings;
    String? photoUrl;
    for (final c in items) {
      if (c.provider == settings.source) photoUrl = c.photo?.url;
    }
    final r = await showAvatarColorsSheet(
      context: context,
      title: l.avatarColorsTitle,
      initial: AvatarColorsDraft.from(settings.colors, settings.border),
      previewBuilder: (d) => Avatar(
        profilePreviewAvatar(
          name: _shownName,
          iconCode: working.iconCode,
          settings: withColorsDraft(settings, d),
          photoUrl: photoUrl,
        ),
        size: 72,
      ),
    );
    if (!mounted || r == null) return;
    applyChange(
      working.copyWith(settings: withColorsDraft(working.settings, r)),
    );
  }

  void _pick(String source) {
    if (working.settings.source == source) return;
    applyChange(
      working.copyWith(settings: working.settings.copyWith(source: source)),
    );
  }

  Future<void> _importPhoto(Connection c) async {
    if (_busy) return;
    final repo = context.read<ConnectionsRepository>();
    final cubit = context.read<ConnectionsCubit>();
    setState(() => _busy = true);
    try {
      cubit.put(await repo.importPhoto(c.provider));
    } on ApiException catch (e) {
      if (mounted) showConnectionError(context, c, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePhoto(Connection c) async {
    if (_busy) return;
    setState(() => _busy = true);
    final done = await deleteConnectionPhoto(
      context,
      c,
      inUse:
          original.settings.source == c.provider ||
          working.settings.source == c.provider,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!done) return;
    // The server dropped the pick when it was this picture; the draft
    // follows, the other edits stay.
    AvatarSettings drop(AvatarSettings s) =>
        s.source == c.provider ? s.copyWith(source: AvatarSource.icon) : s;
    rebaseEdit(
      original: original.copyWith(settings: drop(original.settings)),
      working: working.copyWith(settings: drop(working.settings)),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context)!;
    final w = working;
    final o = original;
    final changes = profileChanges(
      name: w.name,
      email: w.email,
      iconCode: w.iconCode,
      originalName: o.name,
      originalEmail: o.email,
      originalIconCode: o.iconCode,
    );
    final auth = context.read<AuthCubit>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    setState(() => _emailError = null);
    try {
      final updated = await context.read<UsersRepository>().updateMe(
        displayName: changes.displayName,
        email: changes.email,
        iconCode: changes.iconCode,
        clearIconCode: changes.clearIconCode,
        avatarSettings: avatarSettingsChange(o.settings, w.settings),
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
        showErrorSnackBar(context, e);
      }
    }
  }

  String? _stamp(BuildContext context) {
    final lines = detailMetaLines(
      context,
      createdAt: _user.createdAt,
      updatedAt: _user.updatedAt,
    );
    return lines.isEmpty ? null : lines.join('\n');
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final editing = isEditing;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _user = state.user;
          if (!isEditing) resetDraft(_ProfileDraft.from(state.user));
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
            child: BlocBuilder<ConnectionsCubit, ConnectionsState>(
              builder: (context, cs) => DetailPageBody(
                onRefresh: _refresh,
                refreshEnabled: !editing,
                physics: const AlwaysScrollableScrollPhysics(),
                topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                bottomInset:
                    AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
                hero: editing
                    ? _editHero(l, cs.items ?? const [])
                    : _viewHero(l, cs.items ?? const []),
                sections: editing
                    ? [(first) => _pictureSection(l, first, cs)]
                    : [
                        (first) => _connectionsSection(l, first, cs),
                        (first) => _securitySection(l, first),
                      ],
                // The record stamp, inset like a card title (owner
                // 2026-10-28; this page only).
                footnote: _stamp(context),
              ),
            ),
          ),
          bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
        ),
      ),
    );
  }

  Widget _viewHero(AppLocalizations l, List<Connection> items) {
    final avatar = _user.avatar;
    final source = avatar.kind == AvatarKind.photo
        ? pictureSourceApp(_user.avatarSettings, items)
        : null;
    final email = _user.email ?? '';
    final faint = Theme.of(context).colorScheme.onSurfaceVariant;
    return ProfileHeroCard(
      tint: _tint(avatar),
      onLongPress: enterEdit,
      picture: ProfileHeroAvatar(
        avatar: avatar,
        badge: source == null
            ? null
            : ProviderLogo(url: source.logoUrl, name: source.name),
        onLongPress: enterEdit,
        dotsLabel: l.profileColorsLabel,
      ),
      name: _user.displayName,
      handle: '@${_user.username}',
      actions: [
        CardActionButton(
          key: const ValueKey('heroEdit'),
          icon: AppIcons.edit,
          tooltip: UiConfig.stringsOf(context).edit,
          onTap: enterEdit,
        ),
      ],
      facts: [
        HeroFact(
          l.editProfileEmailLabel,
          email.isEmpty ? l.commonLongPressToEdit : email,
          icon: AppIcons.email,
          color: email.isEmpty ? faint : null,
        ),
      ],
    );
  }

  Widget _editHero(AppLocalizations l, List<Connection> items) {
    final preview = _preview(items);
    final text = Theme.of(context).textTheme;
    final handle = l.profileUsernameReadOnly(_user.username);
    if (_usernameCtrl.text != handle) _usernameCtrl.text = handle;
    return ProfileHeroCard(
      editing: true,
      tint: _tint(preview),
      picture: ProfileHeroAvatar(
        avatar: preview,
        editing: true,
        onTap: () => _editPicture(items),
        dotsLabel: l.profileColorsLabel,
      ),
      fields: [
        AppInput.card(
          controller: _nameCtrl,
          label: l.editProfileDisplayNameLabel,
          style: text.titleMedium,
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
        AppInput.card(
          controller: _usernameCtrl,
          label: l.editProfileUsernameLabel,
          locked: true,
        ),
        AppInput.card(
          controller: _emailCtrl,
          label: l.editProfileEmailLabel,
          maxLength: TextLimits.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) {
            if (_emailError != null) setState(() => _emailError = null);
            applyTextChange(_Field.email, working.copyWith(email: v));
          },
          validator: (v) {
            if (_emailError != null) return _emailError;
            final s = v?.trim() ?? '';
            // Once set, the email can't go back to empty.
            if (s.isEmpty) {
              return original.email.isEmpty ? null : l.profileEmailCannotClear;
            }
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                ? null
                : l.editProfileEmailInvalid;
          },
        ),
      ],
    );
  }

  Widget? _connectionsSection(
    AppLocalizations l,
    bool first,
    ConnectionsState cs,
  ) {
    final items = cs.items;
    if (items == null && cs.error == null) return null;
    return SectionCard(
      first: first,
      title: l.profileSectionConnections,
      children: [
        if (items == null)
          // Nothing loaded and the load failed: one row to try again.
          AppDetailRow(
            icon: AppIcons.refresh,
            label: UiConfig.stringsOf(context).retry,
            helper: ErrorView.titleFor(context, cs.error!),
            onTap: () => context.read<ConnectionsCubit>().load(),
          )
        else
          for (final c in items)
            ConnectionRow(
              name: c.name,
              logoUrl: c.logoUrl,
              state: connectionRowState(c),
              brand: c.brand,
              photoUrl: c.photo?.url,
              account: c.account,
              notLinkedLabel: l.connectionsNotLinked,
              tapToLinkLabel: l.connectionsTapToLink,
              onTap: () =>
                  context.push('/settings/profile/connections/${c.provider}'),
            ),
      ],
    );
  }

  Widget _securitySection(AppLocalizations l, bool first) => SectionCard(
    first: first,
    title: l.profileSectionSecurity,
    children: [
      // The lock after the value marks it locked.
      AppDetailRow(
        icon: AppIcons.profile,
        label: l.editProfileUsernameLabel,
        helper: l.profileUsernameLocked,
        locked: true,
        trailing: Text('@${_user.username}'),
      ),
      AppDetailRow(
        icon: AppIcons.password,
        label: _user.hasPassword
            ? l.settingsChangePassword
            : l.profileSetPassword,
        showChevron: true,
        onTap: () => context.push('/settings/password'),
      ),
    ],
  );

  Widget _pictureSection(AppLocalizations l, bool first, ConnectionsState cs) {
    final w = working;
    final source = w.settings.source;
    Widget photoThumb(String url, String name) => Avatar(
      AvatarData(
        kind: AvatarKind.photo,
        photoUrl: url,
        initials: AvatarData.initialsOf(name),
        colors: [AvatarData.nameColorHex(name)],
      ),
      size: AvatarSourceRow.thumbSize,
    );
    return SectionCard(
      first: first,
      title: l.profileSectionPicture,
      children: [
        AvatarSourceRow(
          title: l.profilePictureIcon,
          thumb: Avatar(
            AvatarData.forName(_shownName, iconCode: w.iconCode),
            size: AvatarSourceRow.thumbSize,
          ),
          selected: source == AvatarSource.icon,
          onTap: () => _pick(AvatarSource.icon),
          actions: [
            AppButton(
              label: l.profilePictureEdit,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.chip,
              onPressed: _openIconMaker,
            ),
          ],
        ),
        AvatarSourceRow(
          title: l.profilePictureUpload,
          selected: source == AvatarSource.upload,
          comingSoon: true,
        ),
        for (final c in photoSourceApps(cs.items ?? const []))
          AvatarSourceRow(
            title: c.name,
            subtitle: l.profilePictureImportedAt(_date(c.photo!.importedAt)),
            thumb: photoThumb(c.photo!.url, c.name),
            selected: source == c.provider,
            onTap: () => _pick(c.provider),
            actions: [
              AppButton(
                label: l.connectionsPhotoUpdate,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.chip,
                submits: true,
                onPressed: _busy ? null : () => _importPhoto(c),
              ),
              AppButton(
                label: l.commonDelete,
                variant: AppButtonVariant.destructiveOutlined,
                size: AppButtonSize.chip,
                submits: true,
                onPressed: _busy ? null : () => _deletePhoto(c),
              ),
            ],
          ),
      ],
    );
  }
}

class _ProfileDraft extends Equatable {
  const _ProfileDraft({
    required this.name,
    required this.email,
    required this.settings,
    this.iconCode,
  });

  factory _ProfileDraft.from(User u) => _ProfileDraft(
    name: u.displayName,
    email: u.email ?? '',
    iconCode: u.iconCode,
    settings: u.avatarSettings ?? const AvatarSettings(),
  );

  final String name;
  final String email;
  final IconCode? iconCode;

  /// The picture pick (source + a photo's colours and ring).
  final AvatarSettings settings;

  _ProfileDraft copyWith({
    String? name,
    String? email,
    IconCode? iconCode,
    bool clearIcon = false,
    AvatarSettings? settings,
  }) => _ProfileDraft(
    name: name ?? this.name,
    email: email ?? this.email,
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    settings: settings ?? this.settings,
  );

  @override
  List<Object?> get props => [name, email, iconCode, settings];
}
