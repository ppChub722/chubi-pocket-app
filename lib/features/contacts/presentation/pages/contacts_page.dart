import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';
import '../widgets/contacts_list_skeleton.dart';

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
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(
        title: l.moreContacts,
        showBack: true,
        actions: [
          AppBarAction(
            icon: Icons.add,
            tooltip: l.contactsAddNew,
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
            return const LoadingView(skeleton: ContactsListSkeleton());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'active', label: Text(l.contactsFilterActive)),
                    ButtonSegment(
                        value: 'archived',
                        label: Text(l.contactsFilterArchived)),
                    ButtonSegment(
                        value: 'all', label: Text(l.contactsFilterAll)),
                  ],
                  selected: {state.statusFilter},
                  onSelectionChanged: (v) =>
                      ctx.read<ContactsCubit>().load(statusFilter: v.first),
                ),
              ),
              Expanded(
                child: state.contacts.isEmpty
                    ? EmptyView(
                        icon: Icons.people_outline,
                        title: l.contactsEmptyTitle,
                        message: l.contactsEmptyMessage,
                      )
                    : PullToRefresh(
                        onRefresh: () => ctx.read<ContactsCubit>().load(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxl),
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
      leading: UserAvatar(
        displayName: contact.effectiveName,
        iconCode: contact.effectiveIconCode,
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
