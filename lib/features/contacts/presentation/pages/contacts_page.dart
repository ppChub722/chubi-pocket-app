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

/// `/contacts` — long, searchable list (add = dashed tile at the end).
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
        .where(
          (c) =>
              c.effectiveName.toLowerCase().contains(q) ||
              (c.effectiveEmail?.toLowerCase().contains(q) ?? false) ||
              (c.phone?.contains(q) ?? false),
        )
        .toList();
  }

  void _add() => context.push('/contacts/new');

  /// End-of-list add (the top bar carries no page actions).
  Widget _addTile(AppLocalizations l) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      0,
    ),
    child: AddTile(label: l.contactsAddNew, onTap: _add),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusLabels = {
      'active': l.contactsFilterActive,
      'archived': l.contactsFilterArchived,
      'all': l.contactsFilterAll,
    };
    return Scaffold(
      appBar: AppTopBar(title: l.moreContacts, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<ContactsCubit, ContactsState>(
        builder: (ctx, state) => AsyncStateView(
          loading:
              state.status == ContactsStatus.initial ||
              state.status == ContactsStatus.loading,
          error: state.error,
          isEmpty: state.contacts.isEmpty,
          onRetry: ctx.read<ContactsCubit>().load,
          skeleton: Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(ctx).top),
            child: const LoadingView(skeleton: ContactsListSkeleton()),
          ),
          // Empty lives under the search/filter bar (below).
          builder: (context) {
            final shown = _filter(state.contacts);
            return Column(
              children: [
                // Clear the floating top bar; search + filter stay pinned.
                SizedBox(height: MediaQuery.paddingOf(context).top),
                AppSearchBar(
                  hint: l.contactsSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
                FilterBar(
                  chips: [
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
                  ],
                ),
                Expanded(
                  // A filter (เก็บถาวร / ทั้งหมด) with no rows is a no-match,
                  // not "add your first contact".
                  child:
                      state.contacts.isEmpty && state.statusFilter == 'active'
                      ? EmptyView(
                          icon: AppIcons.contact,
                          title: l.contactsEmptyTitle,
                          message: l.contactsEmptyMessage,
                          cta: AddTile(label: l.contactsAddNew, onTap: _add),
                        )
                      : PullToRefresh(
                          onRefresh: () => ctx.read<ContactsCubit>().load(),
                          child: shown.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  // Explicit: the bar inset is already above.
                                  padding: const EdgeInsets.only(bottom: 96),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xxl,
                                      ),
                                      child: Text(
                                        l.contactsNoMatch,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _addTile(l),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 96),
                                  // + the dashed add tile at the end.
                                  itemCount: shown.length + 1,
                                  separatorBuilder: (_, i) =>
                                      i < shown.length - 1
                                      ? const RowDivider()
                                      : const SizedBox.shrink(),
                                  itemBuilder: (context, i) => i < shown.length
                                      ? _ContactRow(contact: shown[i])
                                      : _addTile(l),
                                ),
                        ),
                ),
              ],
            );
          },
        ),
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
