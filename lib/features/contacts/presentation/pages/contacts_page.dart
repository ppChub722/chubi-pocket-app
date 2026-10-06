import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';
import '../widgets/contacts_list_skeleton.dart';

/// `/contacts` — long, searchable list (add lives on the top bar, §1.2).
/// Search is client-side over name / email / phone; status is a popover.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContactsCubit>().load();
    });
  }

  List<Contact> _filter(List<Contact> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) =>
            c.effectiveName.toLowerCase().contains(q) ||
            (c.effectiveEmail?.toLowerCase().contains(q) ?? false) ||
            (c.phone?.contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusLabels = {
      'active': l.contactsFilterActive,
      'archived': l.contactsFilterArchived,
      'all': l.contactsFilterAll,
    };
    return Scaffold(
      appBar: AppTopBar(
        title: l.moreContacts,
        showBack: true,
        actions: [
          AppBarAction(
            icon: AppIcons.addContact,
            tooltip: l.contactsAddNew,
            onPressed: () => context.push('/contacts/new'),
          ),
        ],
      ),
      body: BlocConsumer<ContactsCubit, ContactsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, state) =>
            showAppSnackBar(ctx, state.errorMessage!, tone: Tone.danger),
        builder: (ctx, state) {
          if (state.status == ContactsStatus.loading &&
              state.contacts.isEmpty) {
            return const LoadingView(skeleton: ContactsListSkeleton());
          }
          final shown = _filter(state.contacts);
          return Column(
            children: [
              AppSearchBar(
                hint: l.contactsSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
              FilterBar(chips: [
                OptionMenuAnchor<String>(
                  selected: state.statusFilter,
                  onSelected: (v) =>
                      ctx.read<ContactsCubit>().load(statusFilter: v),
                  options: [
                    for (final e in statusLabels.entries)
                      SheetOption(value: e.key, label: e.value),
                  ],
                  builder: (context, toggle) => FilterDropdownChip(
                    label: l.contactsStatusLabel,
                    valueLabel: statusLabels[state.statusFilter],
                    active: state.statusFilter != 'active',
                    onTap: toggle,
                  ),
                ),
              ]),
              Expanded(
                child: state.contacts.isEmpty
                    ? EmptyView(
                        icon: AppIcons.contact,
                        title: l.contactsEmptyTitle,
                        message: l.contactsEmptyMessage,
                        cta: AddTile(
                          label: l.contactsAddNew,
                          onTap: () => context.push('/contacts/new'),
                        ),
                      )
                    : PullToRefresh(
                        onRefresh: () => ctx.read<ContactsCubit>().load(),
                        child: shown.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.xxl),
                                    child: Text(
                                      l.contactsNoMatch,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 96),
                                itemCount: shown.length,
                                separatorBuilder: (_, _) => const RowDivider(),
                                itemBuilder: (context, i) =>
                                    _ContactRow(contact: shown[i]),
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
    final scheme = Theme.of(context).colorScheme;
    final sub = [
      if (contact.effectiveEmail?.isNotEmpty ?? false) contact.effectiveEmail!,
      if (contact.phone?.isNotEmpty ?? false) contact.phone!,
    ].join(' · ');
    return Opacity(
      opacity: contact.isArchived ? 0.55 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        leading: UserAvatar(
          displayName: contact.effectiveName,
          iconCode: contact.effectiveIconCode,
        ),
        title: Text(contact.effectiveName),
        subtitle: sub.isEmpty ? null : Text(sub),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.isLinked)
              Icon(AppIcons.link, size: 18, color: scheme.primary),
            if (contact.isArchived)
              Icon(AppIcons.archive, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.chevronRight, color: scheme.onSurfaceVariant),
          ],
        ),
        onTap: () => context.push('/contacts/${contact.id}'),
      ),
    );
  }
}
