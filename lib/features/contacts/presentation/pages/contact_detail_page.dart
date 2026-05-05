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
        _WireNamesTile(contact: contact, onChanged: onChanged),
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

/// "Wire split names → N" tile. N = total un-wired person_name occurrences
/// across all of the user's personal_debts. Loads lazily on mount; tapping
/// opens [_WireNamesSheet] which lets the user multi-select names to wire
/// to this contact in one absorb call.
class _WireNamesTile extends StatefulWidget {
  const _WireNamesTile({required this.contact, required this.onChanged});
  final Contact contact;
  final Future<void> Function() onChanged;

  @override
  State<_WireNamesTile> createState() => _WireNamesTileState();
}

class _WireNamesTileState extends State<_WireNamesTile> {
  List<UnlinkedName>? _names;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      final list = await context.read<ContactsCubit>().unlinkedNames();
      if (!mounted) return;
      setState(() => _names = list);
    } on ApiException {
      // Silent — tile just shows "—" until next refresh. Errors here would
      // be noisy; the user didn't trigger this load.
      if (mounted) setState(() => _names = const []);
    }
  }

  int get _totalSplits =>
      _names == null ? 0 : _names!.fold<int>(0, (a, n) => a + n.count);

  @override
  Widget build(BuildContext context) {
    final names = _names;
    final total = _totalSplits;
    final loading = names == null;
    final empty = !loading && names.isEmpty;

    final summary = loading
        ? 'Loading…'
        : empty
            ? 'No un-wired split names found'
            : 'Pick which typed names belong to this contact '
                '(${names.length} ${names.length == 1 ? "name" : "names"} '
                '· $total ${total == 1 ? "split" : "splits"})';

    return ListTile(
      leading: const Icon(Icons.link_outlined),
      title: const Text('Wire split names'),
      subtitle: Text(summary),
      enabled: !loading && !empty,
      onTap: () => _openSheet(names ?? const []),
    );
  }

  Future<void> _openSheet(List<UnlinkedName> names) async {
    final wired = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WireNamesSheet(
        contact: widget.contact,
        names: names,
      ),
    );
    if (!mounted || wired == null || wired <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Wired $wired ${wired == 1 ? "split" : "splits"} to '
          '${widget.contact.effectiveName}',
        ),
      ),
    );
    await _refresh();
    await widget.onChanged();
  }
}

/// Modal: search + multi-select list of un-wired person_names. Tapping
/// "Save" calls `cubit.absorb(contactId, selectedNames)` and pops with the
/// rewritten count so the parent tile can show a snackbar + refresh.
class _WireNamesSheet extends StatefulWidget {
  const _WireNamesSheet({required this.contact, required this.names});
  final Contact contact;
  final List<UnlinkedName> names;

  @override
  State<_WireNamesSheet> createState() => _WireNamesSheetState();
}

class _WireNamesSheetState extends State<_WireNamesSheet> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = <String>{};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UnlinkedName> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.names;
    return widget.names
        .where((n) => n.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final wired = await context.read<ContactsCubit>().absorb(
            widget.contact.id,
            _selected.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(wired);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wire to ${widget.contact.effectiveName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick the typed names from your splits that should be linked '
              'to this contact. All matching transactions get updated.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search names',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.names.isEmpty
                            ? 'No un-wired names'
                            : 'No matches',
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final n = filtered[i];
                        final picked = _selected.contains(n.name);
                        return CheckboxListTile(
                          value: picked,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(n.name);
                                    } else {
                                      _selected.remove(n.name);
                                    }
                                  }),
                          title: Text(n.name.isEmpty ? '(empty)' : n.name),
                          subtitle: Text(
                            '${n.count} ${n.count == 1 ? "split" : "splits"}',
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_selected.isEmpty || _saving) ? null : _save,
                    child: Text(
                      _saving
                          ? 'Saving…'
                          : _selected.isEmpty
                              ? 'Pick names'
                              : 'Wire ${_selected.length}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
