import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();

  bool _loading = false;

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
      final c = (await context.read<ContactsRepository>().get(
        widget.editingId!,
      )).contact;
      if (!mounted) return;
      _existing = c;
      // The BE-resolved values.
      _name.text = c.name;
      _email.text = c.email ?? '';
      _phone.text = c.phone ?? '';
      _description.text = c.description ?? '';
      _note.text = c.note ?? '';
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.contactNameRequired,
        tone: Tone.danger,
      );
      return;
    }
    final cubit = context.read<ContactsCubit>();
    setState(() => _loading = true);
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final description = _description.text.trim().isEmpty
        ? null
        : _description.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      if (_isLinkExisting) {
        // The cubit patches its list from the returned contact.
        await cubit.linkExistingFromRequest(
          widget.linkRequestId,
          widget.editingId!,
          phone: phone,
          description: description,
          note: note,
        );
        if (!mounted) return;
        context.pushReplacement('/contacts/${widget.editingId!}');
      } else {
        final res = await cubit.createLinkedFromRequest(
          widget.linkRequestId,
          phone: phone,
          description: description,
          note: note,
        );
        if (!mounted) return;
        final id = res.contact?.id;
        if (id != null) context.pushReplacement('/contacts/$id');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
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
    // Display_name + email are read-only in both flows: link-create shows
    // the sender's profile, link-existing is about to become linked-driven.
    final lockedHelper = l.contactLinkedLockedHint;
    final loadingExisting = _loading && _isLinkExisting && _existing == null;
    final name = _name.text;
    final name2 = name.isEmpty ? '…' : name;
    return Scaffold(
      appBar: AppTopBar(title: title, showBack: true, editing: true),
      extendBodyBehindAppBar: true,
      // Builder: its context sees the floating bar's height.
      body: Builder(
        builder: (context) {
          final top = MediaQuery.paddingOf(context).top;
          // First load (linking an existing contact): the template's detail
          // skeleton, never a spinner; it clears the floating bar itself.
          if (loadingExisting) return const DetailPageSkeleton();
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              top + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              AppMessage(
                tone: Tone.info,
                message: _isLinkExisting
                    ? l.contactLinkBannerExisting(name2)
                    : l.contactLinkBannerNew(name2),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                first: true,
                children: [
                  DetailRow(
                    label: l.commonName,
                    locked: true,
                    helper: lockedHelper,
                    trailing: AppText(name),
                  ),
                  // The contact's own — editable even when name/email are
                  // locked.
                  DetailStacked(
                    label: l.commonDescription,
                    child: AppInput.inline(
                      editing: true,
                      controller: _description,
                      hint: l.contactDescriptionHint,
                      maxLines: 3,
                      maxLength: TextLimits.description,
                    ),
                  ),
                  DetailRow(
                    label: l.contactEmailLabel,
                    locked: true,
                    helper: lockedHelper,
                    trailing: _email.text.isEmpty
                        ? DetailPlaceholder(l.contactFieldNotSet)
                        : AppText(_email.text),
                  ),
                  DetailStacked(
                    label: l.contactPhoneLabel,
                    child: AppInput.inline(
                      editing: true,
                      controller: _phone,
                      maxLength: TextLimits.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  DetailStacked(
                    label: l.commonNote,
                    child: AppInput.inline(
                      editing: true,
                      controller: _note,
                      hint: l.contactNoteHint,
                      maxLines: 3,
                      maxLength: TextLimits.note,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: loadingExisting
          ? null
          : ModeActionBar(
              canSave: !_loading,
              saving: _loading,
              cancelLabel: l.commonCancel,
              saveLabel: l.contactLinkSave,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _submit,
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
