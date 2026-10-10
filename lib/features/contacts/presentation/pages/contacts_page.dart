import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';
import '../widgets/contact_linked_mark.dart';
import '../widgets/contacts_list_skeleton.dart';

/// `/contacts` (owner 2026-10-10) — the library list look shared with
/// categories and tags:
///
///   [🔍 ค้นหา…                    ]
///   [สถานะ: ใช้งาน ▾] [การผูก: ทั้งหมด ▾]      [⇅ ใช้ล่าสุด ▾]
///   (avatar) name · description · email               🔗
///   … dashed "+ เพิ่มผู้ติดต่อ" at the end
///
/// Search is client-side over name / description / email / phone. Status
/// (ใช้งาน / เก็บถาวร / ทั้งหมด) loads from the server — archived ones
/// live here, dimmed, not on a page of their own. การผูก (ทั้งหมด /
/// ผูกแล้ว / ยังไม่ผูก) filters client-side on top of it. Sort is
/// client-side: ใช้ล่าสุด (the server's order), ชื่อ ก→ฮ, ชื่อ ฮ→ก.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

enum _ContactSort { recent, nameAsc, nameDesc }

/// The การผูก filter — linked to an app account or not.
enum _LinkFilter { all, linked, unlinked }

class _ContactsPageState extends State<ContactsPage> {
  String _query = '';
  _ContactSort _sort = _ContactSort.recent;
  _LinkFilter _link = _LinkFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContactsCubit>().load();
    });
  }

  List<Contact> _filter(List<Contact> all) {
    final q = _query.trim().toLowerCase();
    final hits = all.where((c) {
      final linkOk = switch (_link) {
        _LinkFilter.all => true,
        _LinkFilter.linked => c.isLinked,
        _LinkFilter.unlinked => !c.isLinked,
      };
      return linkOk &&
          (q.isEmpty ||
              c.effectiveName.toLowerCase().contains(q) ||
              (c.description?.toLowerCase().contains(q) ?? false) ||
              (c.effectiveEmail?.toLowerCase().contains(q) ?? false) ||
              (c.phone?.contains(q) ?? false));
    }).toList();
    int byName(Contact a, Contact b) =>
        a.effectiveName.toLowerCase().compareTo(b.effectiveName.toLowerCase());
    return switch (_sort) {
      _ContactSort.recent => hits,
      _ContactSort.nameAsc => [...hits]..sort(byName),
      _ContactSort.nameDesc => [...hits]..sort((a, b) => byName(b, a)),
    };
  }

  String _sortLabel(AppLocalizations l, _ContactSort s) => switch (s) {
    _ContactSort.recent => l.contactsSortRecent,
    _ContactSort.nameAsc => l.contactsSortNameAsc,
    _ContactSort.nameDesc => l.contactsSortNameDesc,
  };

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

  String _linkLabel(AppLocalizations l, _LinkFilter f) => switch (f) {
    _LinkFilter.all => l.contactsFilterAll,
    _LinkFilter.linked => l.contactLinked,
    _LinkFilter.unlinked => l.contactsLinkUnlinked,
  };

  /// Nothing to show under the current search / status / การผูก — the same
  /// [EmptyView] look as the first-run empty state, scrollable so
  /// pull-to-refresh still fires.
  Widget _noResults(AppLocalizations l, String statusFilter) {
    final searching = _query.trim().isNotEmpty;
    final linkFiltered = _link != _LinkFilter.all;
    final archived = !searching && !linkFiltered && statusFilter == 'archived';
    final (icon, title, message) = searching
        ? (
            AppIcons.search,
            l.contactsNoMatch,
            linkFiltered
                ? l.contactsNoMatchFilterMessage
                : l.contactsNoMatchMessage,
          )
        : linkFiltered
        ? (
            AppIcons.link,
            l.contactsNoFilterMatch,
            l.contactsNoFilterMatchMessage,
          )
        : archived
        ? (
            AppIcons.archive,
            l.contactsArchivedEmptyTitle,
            l.contactsArchivedEmptyMessage,
          )
        : (AppIcons.contact, l.contactsNoMatch, '');
    // A new contact is active and unlinked — only offer it where it would
    // show up.
    final canAdd = statusFilter != 'archived' && _link != _LinkFilter.linked;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 96),
          child: EmptyView(
            icon: icon,
            title: title,
            message: message,
            cta: canAdd ? AddTile(label: l.contactsAddNew, onTap: _add) : null,
          ),
        ),
      ),
    );
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
      appBar: AppTopBar(title: l.moreContacts, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<ContactsCubit, ContactsState>(
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
                  // Filters left, the sort right — as on the transactions
                  // list. Add is the dashed tile at the end of the list.
                  FilterBar(
                    trailing: OptionMenuAnchor<_ContactSort>(
                      selected: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      options: [
                        for (final s in _ContactSort.values)
                          SheetOption(value: s, label: _sortLabel(l, s)),
                      ],
                      builder: (context, toggle) => FilterDropdownChip(
                        label: _sortLabel(l, _sort),
                        icon: AppIcons.sort,
                        active: false,
                        onTap: toggle,
                      ),
                    ),
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
                      OptionMenuAnchor<_LinkFilter>(
                        selected: _link,
                        onSelected: (v) => setState(() => _link = v),
                        options: [
                          for (final f in _LinkFilter.values)
                            SheetOption(value: f, label: _linkLabel(l, f)),
                        ],
                        builder: (context, toggle) => FilterDropdownChip(
                          label: l.contactsLinkLabel,
                          valueLabel: _linkLabel(l, _link),
                          active: _link != _LinkFilter.all,
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
                                ? _noResults(l, state.statusFilter)
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      bottom:
                                          96 +
                                          MediaQuery.paddingOf(context).bottom,
                                    ),
                                    // + the dashed add tile at the end.
                                    itemCount: shown.length + 1,
                                    separatorBuilder: (_, i) =>
                                        i < shown.length - 1
                                        ? const RowDivider()
                                        : const SizedBox.shrink(),
                                    itemBuilder: (context, i) =>
                                        i < shown.length
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
      ),
    );
  }
}

/// A contact on the list: avatar · name · "description · email" (one line)
/// · 🔗 when linked. Archived ones are dimmed.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    // "description · email", either alone, or nothing — never the phone
    // (owner 2026-10-10; search still matches it).
    final sub = [
      contact.description?.trim() ?? '',
      contact.effectiveEmail?.trim() ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');
    return ListRow(
      leading: ContactAvatar(contact: contact),
      title: contact.effectiveName,
      subtitle: sub,
      dimmed: contact.isArchived,
      onTap: () => context.push('/contacts/${contact.id}'),
    );
  }
}
