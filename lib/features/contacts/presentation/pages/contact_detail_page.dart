import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

/// `/contacts/:id` — contact detail with link/unlink/archive/delete actions.
class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({required this.id, super.key});
  final String id;

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  Contact? _contact;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await context.read<ContactsRepository>().get(widget.id);
      if (!mounted) return;
      setState(() {
        _contact = c;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contact?.effectiveName ?? 'Contact'),
        actions: [
          if (_contact != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () =>
                  context.push('/contacts/${_contact!.id}/edit').then((_) => _load()),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _contact == null
                  ? const Center(child: Text('Contact not found'))
                  : _ContactBody(
                      contact: _contact!,
                      onChanged: _load,
                    ),
    );
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.contact, required this.onChanged});
  final Contact contact;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContactsCubit>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            child: Text(contact.effectiveName.isNotEmpty
                ? contact.effectiveName[0].toUpperCase()
                : '?'),
          ),
        ),
        const SizedBox(height: 16),
        _Field(label: 'Display name', value: contact.displayName),
        if (contact.nickname != null)
          _Field(label: 'Nickname', value: contact.nickname!),
        if (contact.email != null)
          _Field(label: 'Email', value: contact.email!),
        if (contact.phone != null)
          _Field(label: 'Phone', value: contact.phone!),
        if (contact.notes != null)
          _Field(label: 'Notes', value: contact.notes!),
        const Divider(height: 32),
        if (contact.isLinked)
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Linked'),
            subtitle: const Text('This contact is linked to an app user.'),
            trailing: TextButton(
              onPressed: () async {
                await cubit.unlink(contact.id);
                await onChanged();
              },
              child: const Text('Unlink'),
            ),
          )
        else if (contact.email != null)
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: const Text('Send link request'),
            subtitle: const Text(
              'If this email matches a user, they get a notification to link.',
            ),
            trailing: TextButton(
              onPressed: () => _requestLink(context),
              child: const Text('Request'),
            ),
          ),
        ListTile(
          leading: Icon(contact.isArchived ? Icons.unarchive : Icons.archive),
          title: Text(contact.isArchived ? 'Restore' : 'Archive'),
          onTap: () async {
            if (contact.isArchived) {
              await cubit.restore(contact.id);
            } else {
              await cubit.archive(contact.id);
            }
            await onChanged();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
          title: const Text('Delete contact',
              style: TextStyle(color: Colors.redAccent)),
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _requestLink(BuildContext context) async {
    final cubit = context.read<ContactsCubit>();
    try {
      await cubit.requestLink(contact.id);
      if (!context.mounted) return;
      // Privacy preservation: same toast on hit and miss.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link request sent')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete contact?'),
        content: const Text(
            'Splits referencing this contact will keep the typed name as a fallback.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final cubit = context.read<ContactsCubit>();
    await cubit.delete(contact.id);
    if (!context.mounted) return;
    context.pop();
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
