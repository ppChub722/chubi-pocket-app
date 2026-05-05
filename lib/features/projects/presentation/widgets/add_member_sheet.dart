import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// `POST /projects/:id/members` — add a participant to the project.
///
/// One form, two outcomes (variant inferred at submit time):
///   - Email field has a value     → invite-by-email (BE generates a
///                                     project_invite notification on
///                                     match)
///   - Email field is empty        → ad-hoc member (no app account, can
///                                     be linked to a real user later
///                                     once they accept a contact link)
///
/// Name field is a typeahead over the caller's contacts. Picking a
/// contact auto-fills name + email so the common case ("invite my
/// existing contact") is one tap + Add.
Future<bool?> showAddMemberSheet(
  BuildContext context, {
  required String projectId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
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
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  MemberRole _role = MemberRole.contributor;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Warm contacts cache so the typeahead has data ready on first focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ContactsCubit>();
      if (cubit.state.contacts.isEmpty) cubit.load();
    });
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _isAdHoc => _email.text.trim().isEmpty;

  Future<void> _submit() async {
    final name = _displayName.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Display name is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = context.read<ProjectsRepository>();
      if (_isAdHoc) {
        await repo.addMember(
          widget.projectId,
          displayName: name,
          role: _role,
          adHoc: true,
        );
      } else {
        await repo.addMember(
          widget.projectId,
          email: _email.text.trim(),
          displayName: name,
          role: _role,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Iterable<Contact> _contactSuggestions(String query, List<Contact> all) {
    final active = all.where((c) => c.status == ContactStatus.active);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return active;
    return active.where((c) =>
        c.displayName.toLowerCase().contains(q) ||
        (c.email?.toLowerCase().contains(q) ?? false));
  }

  void _onContactPicked(Contact c) {
    _displayName.text = c.displayName;
    _email.text = c.email ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add member', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            _isAdHoc
                ? 'No email → ad-hoc member. Link to a user later via a contact request.'
                : 'Email present → invites the matching user. They get a notification.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<ContactsCubit, ContactsState>(
            builder: (context, state) {
              return Autocomplete<Contact>(
                initialValue: TextEditingValue(text: _displayName.text),
                displayStringForOption: (c) => c.displayName,
                optionsBuilder: (te) =>
                    _contactSuggestions(te.text, state.contacts),
                onSelected: _onContactPicked,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmit) {
                  // Keep the external controller in sync with the inline
                  // one Autocomplete creates so other widgets reading
                  // `_displayName.text` see the current value.
                  if (controller.text != _displayName.text) {
                    controller.text = _displayName.text;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Display name *',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      _displayName.text = v;
                      setState(() {});
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final list = options.toList(growable: false);
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 280,
                          maxWidth: 360,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final c = list[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text(
                                  c.displayName.isNotEmpty
                                      ? c.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(c.displayName),
                              subtitle: c.email != null
                                  ? Text(c.email!,
                                      style: const TextStyle(fontSize: 11))
                                  : null,
                              trailing: c.isLinked
                                  ? const Icon(Icons.link, size: 14)
                                  : null,
                              onTap: () => onSelected(c),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              helperText:
                  'Leave blank for ad-hoc · provide to invite an app user',
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MemberRole>(
            initialValue: _role,
            items: const [
              DropdownMenuItem(
                  value: MemberRole.contributor, child: Text('Contributor')),
              DropdownMenuItem(
                  value: MemberRole.viewer, child: Text('Viewer')),
            ],
            onChanged: (v) =>
                setState(() => _role = v ?? MemberRole.contributor),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? 'Adding…' : 'Add Member'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
