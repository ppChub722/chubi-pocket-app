import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/avatar_presets.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../../../shared/widgets/icon_color_picker_sheet.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/user_profile_preview.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _currencies = ['THB', 'USD', 'EUR', 'GBP', 'JPY'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _avatarUrlCtrl;
  late String _currency;
  late User _initial;

  bool _submitting = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final user = _userOrNull(context.read<AuthCubit>().state);
    _initial = user!;
    _displayNameCtrl = TextEditingController(text: user.displayName);
    _avatarUrlCtrl = TextEditingController(text: user.avatarUrl ?? '');
    _currency = user.currency;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _avatarUrlCtrl.dispose();
    super.dispose();
  }

  bool get _dirty {
    return _displayNameCtrl.text.trim() != _initial.displayName ||
        _currency != _initial.currency ||
        (_avatarUrlCtrl.text.trim().isEmpty ? null : _avatarUrlCtrl.text.trim()) !=
            _initial.avatarUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = context.read<UsersRepository>();
      final newUrl = _avatarUrlCtrl.text.trim();
      final updated = await repo.updateMe(
        displayName: _displayNameCtrl.text.trim() != _initial.displayName
            ? _displayNameCtrl.text.trim()
            : null,
        currency: _currency != _initial.currency ? _currency : null,
        avatarUrl: newUrl.isNotEmpty ? newUrl : null,
        clearAvatar: newUrl.isEmpty && _initial.avatarUrl != null,
      );
      if (!mounted) return;
      context.read<AuthCubit>().updateUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.editProfileSnackSuccess)),
      );
      context.pop();
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openAvatarPicker() async {
    final l = AppLocalizations.of(context)!;
    final displayName = _displayNameCtrl.text.trim().isEmpty
        ? _initial.displayName
        : _displayNameCtrl.text.trim();
    final initial = AvatarPresetSelection.tryParse(_avatarUrlCtrl.text) ??
        AvatarPresetSelection.defaultSelection;

    final result = await showIconColorPickerSheet(
      context: context,
      iconOptions: [
        for (final p in AvatarPreset.all)
          IconPickerOption(
            id: p.id,
            icon: p.icon,
            assetPath: p.assetPath,
            // The Initials preset draws the user's first letter on the
            // swatch instead of an icon — domain rendering the avatar
            // context owns, surfaced to the generic picker via customThumb.
            customThumb: p.id == AvatarPreset.initials.id
                ? (swatchColor) => _initialsThumb(displayName, swatchColor)
                : null,
          ),
      ],
      swatches: [
        for (final c in AvatarColor.all)
          IconPickerSwatch(id: c.id, color: c.color),
      ],
      initialIconId: initial.preset.id,
      initialSwatchId: initial.color.id,
      iconSectionLabel: l.avatarPickerStyleLabel,
      colorSectionLabel: l.avatarPickerColorLabel,
      useThisLabel: l.avatarPickerUseThis,
      removeLabel: l.commonRemove,
      uploadComingSoonLabel: l.avatarPickerUploadDisabled,
      cropComingSoonLabel: l.avatarPickerCropDisabled,
      previewBuilder: (icon, swatch) => UserProfilePreview(
        displayName: displayName,
        avatarUrl: 'preset:${icon.id}:${swatch.id}',
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      switch (result) {
        case IconColorPickerSelected(:final iconId, :final swatchId):
          _avatarUrlCtrl.text = AvatarPresetSelection(
            preset: AvatarPreset.byId(iconId),
            color: AvatarColor.byId(swatchId),
          ).encode();
        case IconColorPickerRemoved():
          _avatarUrlCtrl.text = '';
      }
    });
  }

  Widget _initialsThumb(String displayName, Color swatchColor) {
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: swatchColor,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editProfileDiscardTitle),
        content: Text(l.editProfileDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.editProfileDiscardKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.editProfileDiscardConfirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (!context.mounted) return;
        if (ok) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final ok = await _confirmDiscard();
              if (!context.mounted) return;
              if (ok) context.pop();
            },
          ),
          title: Text(l.editProfileTitle),
          actions: [
            TextButton(
              onPressed: (_dirty && !_submitting) ? _save : null,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.commonSave),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        _ErrorBanner(message: _error!.message),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _AvatarSection(
                        displayName: _displayNameCtrl.text.isEmpty
                            ? _initial.displayName
                            : _displayNameCtrl.text,
                        avatarUrl: _avatarUrlCtrl.text.trim().isEmpty
                            ? null
                            : _avatarUrlCtrl.text.trim(),
                        onTap: _submitting ? null : _openAvatarPicker,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _displayNameCtrl,
                        enabled: !_submitting,
                        decoration: InputDecoration(
                          labelText: l.editProfileDisplayNameLabel,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return l.commonRequired;
                          if (s.length > 100) {
                            return l.authRegisterDisplayNameTooLong;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: InputDecoration(
                          labelText: l.editProfileCurrencyLabel,
                          helperText: l.editProfileCurrencyHelper,
                          helperMaxLines: 2,
                        ),
                        items: _currencies
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (v) => setState(() => _currency = v ?? 'THB'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _avatarUrlCtrl,
                        enabled: !_submitting,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: l.editProfileAvatarUrlLabel,
                          helperText: l.editProfileAvatarUrlHelper,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ReadOnlyField(
                        label: l.editProfileUsernameLabel,
                        value: '@${_initial.username}',
                        helper: l.editProfileReadOnlyHelper,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ReadOnlyField(
                        label: l.editProfileEmailLabel,
                        value: _initial.email ?? l.editProfileEmailNone,
                        helper: l.editProfileReadOnlyHelper,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

User? _userOrNull(AuthState state) {
  if (state is AuthAuthenticated) return state.user;
  if (state is AuthLoading && state.previous is AuthAuthenticated) {
    return (state.previous as AuthAuthenticated).user;
  }
  return null;
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.displayName,
    required this.onTap,
    this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EditableCircle(
        size: 96,
        onTap: onTap,
        child: UserAvatar(
          displayName: displayName,
          avatarUrl: avatarUrl,
          size: 96,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.helper,
  });
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
