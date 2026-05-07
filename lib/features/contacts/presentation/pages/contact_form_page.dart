import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

/// `/contacts/new` and `/contacts/:id/edit`.
///
/// Modes:
/// - **Create** (no params) — plain new contact.
/// - **Edit existing** (editingId set) — load + update. When the loaded
///   contact is linked to a user, display_name + email become
///   read-only (those fields project live from the linked user; the
///   stored values exist only as a fallback for after unlink).
/// - **Link-create** (linkRequestId set, contactId null) — post-accept
///   tap flow when B has no matching contact yet. Display_name + email
///   are read-only and pre-filled from the sender's profile (BE pulls
///   them server-side at save time too). Save calls
///   `createLinkedContactFromLinkRequest`.
/// - **Link-existing** (linkRequestId + contactId) — post-accept tap
///   flow when B has an unlinked email-match. Loads the existing
///   contact, locks display_name + email (about to become linked-driven
///   anyway), keeps phone/notes editable. Save calls
///   `linkExistingContactFromLinkRequest`.
class ContactFormPage extends StatefulWidget {
  const ContactFormPage({
    this.editingId,
    this.linkRequestId,
    this.lockedDisplayName,
    this.lockedEmail,
    super.key,
  });

  final String? editingId;

  /// Notification id of an *actioned* `contact_link_request`. When set,
  /// save calls one of the link-request endpoints instead of plain
  /// create / update. The endpoint chosen is determined by whether
  /// [editingId] is also set:
  /// - editingId null → `createLinkedContactFromLinkRequest`
  /// - editingId set  → `linkExistingContactFromLinkRequest`
  final String? linkRequestId;

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
  final _notes = TextEditingController();

  bool _loading = false;
  String? _error;

  /// Set after [_loadExisting]; drives the "lock display_name + email"
  /// rule for already-linked contacts in plain edit mode.
  Contact? _existing;

  bool get _isEditExisting => widget.editingId != null;
  bool get _isLinkFlow => widget.linkRequestId != null;
  bool get _isLinkCreate => _isLinkFlow && !_isEditExisting;
  bool get _isLinkExisting => _isLinkFlow && _isEditExisting;

  /// True when display_name + email should be read-only:
  ///   - link-create: locked to the sender profile values shown.
  ///   - link-existing: locked because the contact is about to become
  ///     linked-driven (BE will project user values on the next read).
  ///   - plain edit on an already-linked contact: locked because the
  ///     user values are what's actually displayed across the app.
  bool get _displayFieldsLocked {
    if (_isLinkFlow) return true;
    return _existing?.isLinked ?? false;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditExisting) {
      _loadExisting();
    } else if (_isLinkCreate) {
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
      final c =
          await context.read<ContactsRepository>().get(widget.editingId!);
      if (!mounted) return;
      _existing = c;
      // For linked / link-existing flows we render the linked user's
      // current values; otherwise the contact's own stored values.
      _name.text = c.effectiveDisplayName;
      _email.text = c.effectiveEmail ?? '';
      _phone.text = c.phone ?? '';
      _notes.text = c.notes ?? '';
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
    final name = _name.text.trim();
    final email = _email.text.trim().isEmpty ? null : _email.text.trim();
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    try {
      if (_isLinkExisting) {
        await repo.linkExistingContactFromLinkRequest(
          widget.linkRequestId!,
          widget.editingId!,
          phone: phone,
          notes: notes,
        );
        await cubit.load();
        if (!mounted) return;
        context.pushReplacement('/contacts/${widget.editingId!}');
      } else if (_isLinkCreate) {
        final created = await repo.createLinkedContactFromLinkRequest(
          widget.linkRequestId!,
          phone: phone,
          notes: notes,
        );
        await cubit.load();
        if (!mounted) return;
        context.pushReplacement('/contacts/${created.id}');
      } else if (_isEditExisting) {
        // Plain edit. When the contact is linked, the form locked
        // display_name + email — but the BE allows the update either
        // way; we just don't surface a path to change them. For an
        // unlinked contact, send everything.
        await cubit.update(
          widget.editingId!,
          displayName: _displayFieldsLocked ? null : name,
          email: _displayFieldsLocked ? null : email,
          phone: phone,
          notes: notes,
        );
        if (!mounted) return;
        context.pop<Contact?>(null);
      } else {
        await cubit.create(
          displayName: name,
          email: email,
          phone: phone,
          notes: notes,
        );
        if (!mounted) return;
        context.pop<Contact?>(null);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLinkCreate
        ? 'Add linked contact'
        : _isLinkExisting
            ? 'Link contact'
            : _isEditExisting
                ? 'Edit contact'
                : 'New contact';
    final saveLabel = _isLinkFlow
        ? 'Link & save'
        : _isEditExisting
            ? 'Save'
            : 'Create';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading && _isEditExisting && _existing == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isLinkFlow)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LinkBanner(
                        senderName: _name.text,
                        isExisting: _isLinkExisting,
                      ),
                    ),
                  TextFormField(
                    controller: _name,
                    readOnly: _displayFieldsLocked,
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      // Chain icon visually marks "this field is linked"
                      // — same hint as the helper text but at-a-glance.
                      prefixIcon: _displayFieldsLocked
                          ? const Icon(Icons.link, size: 20)
                          : null,
                      helperText: _displayFieldsLocked
                          ? 'Linked from this user\'s account'
                          : null,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    readOnly: _displayFieldsLocked,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: _displayFieldsLocked
                          ? const Icon(Icons.link, size: 20)
                          : null,
                      helperText: _displayFieldsLocked
                          ? 'Linked from this user\'s account'
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(saveLabel),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }
}

class _LinkBanner extends StatelessWidget {
  const _LinkBanner({required this.senderName, required this.isExisting});
  final String senderName;
  final bool isExisting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = isExisting
        ? (senderName.isEmpty
            ? 'Saving will link this contact to the sender of the request.'
            : 'Saving will link this contact to $senderName.')
        : (senderName.isEmpty
            ? 'Saving will create a new linked contact.'
            : 'Saving will create a new contact linked to $senderName.');
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.link, color: scheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              body,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
