import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

/// The contact form of the link-request flows only — plain create / edit
/// is the contact detail page. Reached from an accepted
/// `contact_link_request` (the inbox):
///
/// - **Link-create** (`/contacts/new` with `extra.linkRequestId`, no
///   [editingId]) — B has no matching contact yet. Display_name + email
///   are read-only, pre-filled from the sender's profile (the BE pulls them
///   server-side at save time too). Save calls
///   `createLinkedContactFromLinkRequest`.
/// - **Link-existing** (`/contacts/:id/edit` with `extra.linkRequestId`)
///   — B has an unlinked email-match. Loads that contact, locks
///   display_name + email (about to become linked-driven), keeps phone /
///   description / note editable. Save calls
///   `linkExistingContactFromLinkRequest`.
class ContactFormPage extends StatefulWidget {
  const ContactFormPage({
    required this.linkRequestId,
    this.editingId,
    this.lockedDisplayName,
    this.lockedEmail,
    super.key,
  });

  final String? editingId;

  /// Notification id of an *actioned* `contact_link_request`. Save calls
  /// the link-request endpoint picked by whether [editingId] is set:
  /// - editingId null → `createLinkedContactFromLinkRequest`
  /// - editingId set  → `linkExistingContactFromLinkRequest`
  final String linkRequestId;

  /// Pre-fill values for the locked display_name + email fields in
  /// link-create mode. Sourced by the inbox tap handler from the
  /// sender-profile endpoint.
  final String? lockedDisplayName;
  final String? lockedEmail;

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();

  bool _loading = false;
  String? _error;

  /// The contact being linked (link-existing), once loaded.
  Contact? _existing;

  bool get _isLinkExisting => widget.editingId != null;
  bool get _isLinkCreate => !_isLinkExisting;

  @override
  void initState() {
    super.initState();
    if (_isLinkExisting) {
      _loadExisting();
    } else {
      // Pre-fill (read-only) from the sender profile passed in by the
      // inbox tap handler. The BE will pull the canonical values from
      // the user record on save anyway — these fields are display-only.
      _name.text = widget.lockedDisplayName ?? '';
      _email.text = widget.lockedEmail ?? '';
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final c = await context.read<ContactsRepository>().get(widget.editingId!);
      if (!mounted) return;
      _existing = c;
      // The linked user's current values where the contact has them.
      _name.text = c.effectiveDisplayName;
      _email.text = c.effectiveEmail ?? '';
      _phone.text = c.phone ?? '';
      _description.text = c.description ?? '';
      _note.text = c.note ?? '';
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final cubit = context.read<ContactsCubit>();
    final repo = context.read<ContactsRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final description = _description.text.trim().isEmpty
        ? null
        : _description.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      if (_isLinkExisting) {
        await repo.linkExistingContactFromLinkRequest(
          widget.linkRequestId,
          widget.editingId!,
          phone: phone,
          description: description,
          note: note,
        );
        await cubit.load();
        if (!mounted) return;
        context.pushReplacement('/contacts/${widget.editingId!}');
      } else {
        final created = await repo.createLinkedContactFromLinkRequest(
          widget.linkRequestId,
          phone: phone,
          description: description,
          note: note,
        );
        await cubit.load();
        if (!mounted) return;
        context.pushReplacement('/contacts/${created.id}');
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = _isLinkCreate
        ? l.contactLinkCreateTitle
        : l.contactLinkExistingTitle;
    final saveLabel = l.contactLinkSave;
    // Display_name + email are read-only in both flows: link-create shows
    // the sender's profile, link-existing is about to become linked-driven.
    final lockedHelper = l.contactLinkedLockedHint;
    const lockedIcon = AppIcons.link;
    return Scaffold(
      appBar: AppTopBar(title: title, showBack: true, editing: true),
      extendBodyBehindAppBar: true,
      // Builder: its context sees the floating bar's height.
      body: Builder(
        builder: (context) {
          final top = MediaQuery.paddingOf(context).top;
          if (_loading && _isLinkExisting && _existing == null) {
            return Padding(
              padding: EdgeInsets.only(top: top),
              child: const LoadingView(),
            );
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg).add(
                EdgeInsets.only(
                  top: top,
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _LinkBanner(
                    senderName: _name.text,
                    isExisting: _isLinkExisting,
                  ),
                ),
                AppTextField(
                  controller: _name,
                  label: l.commonName,
                  readOnly: true,
                  prefixIcon: lockedIcon,
                  helper: lockedHelper,
                  maxLength: TextLimits.name,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.contactNameRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                // The contact's own — editable even when name/email are locked.
                AppTextField(
                  controller: _description,
                  label: l.commonDescription,
                  hint: l.contactDescriptionHint,
                  maxLines: 3,
                  maxLength: TextLimits.description,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _email,
                  label: l.contactEmailLabel,
                  readOnly: true,
                  prefixIcon: lockedIcon,
                  helper: lockedHelper,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: l.contactPhoneLabel,
                  maxLength: TextLimits.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _note,
                  label: l.commonNote,
                  hint: l.contactNoteHint,
                  maxLines: 3,
                  maxLength: TextLimits.note,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: saveLabel,
                  expand: true,
                  loading: _loading,
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }
}

class _LinkBanner extends StatelessWidget {
  const _LinkBanner({required this.senderName, required this.isExisting});
  final String senderName;
  final bool isExisting;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final name = senderName.isEmpty ? '…' : senderName;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(AppIcons.link, color: scheme.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isExisting
                  ? l.contactLinkBannerExisting(name)
                  : l.contactLinkBannerNew(name),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
