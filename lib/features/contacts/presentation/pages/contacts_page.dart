import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

/// `/contacts` — list of the user's contacts.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New contact',
            onPressed: () => context.push('/contacts/new'),
          ),
        ],
      ),
      body: BlocConsumer<ContactsCubit, ContactsState>(
        listenWhen: (a, b) => a.errorMessage != b.errorMessage,
        listener: (ctx, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (ctx, state) {
          if (state.status == ContactsStatus.loading &&
              state.contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'active', label: Text('Active')),
                    ButtonSegment(value: 'archived', label: Text('Archived')),
                    ButtonSegment(value: 'all', label: Text('All')),
                  ],
                  selected: {state.statusFilter},
                  onSelectionChanged: (v) =>
                      ctx.read<ContactsCubit>().load(statusFilter: v.first),
                ),
              ),
              Expanded(
                child: state.contacts.isEmpty
                    ? const Center(child: Text('No contacts yet'))
                    : RefreshIndicator(
                        onRefresh: () => ctx.read<ContactsCubit>().load(),
                        child: ListView.separated(
                          itemCount: state.contacts.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = state.contacts[i];
                            return _ContactRow(contact: c);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          contact.effectiveName.isNotEmpty
              ? contact.effectiveName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(contact.effectiveName),
      subtitle: Text([
        if (contact.email != null) contact.email!,
        if (contact.phone != null) contact.phone!,
      ].join(' · ')),
      trailing: contact.isLinked
          ? const Icon(Icons.link, size: 18)
          : (contact.isArchived
              ? const Icon(Icons.archive_outlined, size: 18)
              : null),
      onTap: () => context.push('/contacts/${contact.id}'),
    );
  }
}
