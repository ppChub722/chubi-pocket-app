import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/top_bar_crumbs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../contacts/data/contacts_repository.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/member_picker.dart';

class ProjectMembersPage extends StatefulWidget {
  const ProjectMembersPage({required this.projectId, super.key});
  final String projectId;

  @override
  State<ProjectMembersPage> createState() => _ProjectMembersPageState();
}

class _ProjectMembersPageState extends State<ProjectMembersPage> {
  Project? _project;
  List<ProjectMember> _members = const [];
  ApiException? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _project == null;
      _error = null;
    });
    try {
      final repo = context.read<ProjectsRepository>();
      final results = await Future.wait([
        repo.get(widget.projectId),
        repo.listMembers(widget.projectId),
      ]);
      if (!mounted) return;
      setState(() {
        _project = results[0] as Project;
        _members = results[1] as List<ProjectMember>;
        _loading = false;
      });
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e, st);
          _loading = false;
        });
      }
    }
  }

  String? get _uid {
    final s = context.read<AuthCubit>().state;
    return s is AuthAuthenticated ? s.user.id : null;
  }

  bool get _isOwner =>
      _project != null && (_project!.isOwner || _project!.ownerUserId == _uid);

  /// "เพิ่มสมาชิก" (owner 2026-11-03): the contact picker of quick create — a
  /// contact (an app user is invited with the row's เชิญ) or a typed name.
  Future<void> _add() async {
    final l = AppLocalizations.of(context)!;
    final r = await ContactPicker.one(
      context,
      allowFreeText: true,
      allowCreate: true,
      title: l.projectMembersAdd,
    );
    if (r == null || !mounted) return;
    final repo = context.read<ProjectsRepository>();
    final (name, call) = switch (r) {
      ContactPicked(:final contact) => (
        contact.name,
        () => repo.addMember(widget.projectId, contactId: contact.id),
      ),
      ContactNamePicked(:final name) || ContactNameTyped(:final name) => (
        name,
        () =>
            repo.addMember(widget.projectId, displayName: name, adHoc: true),
      ),
    };
    await _run(call, done: l.projectAddMemberAdded(name));
  }

  /// เชิญ / เชิญแล้ว (again): the event invite to my contact using the app.
  Future<void> _sendInvite(ProjectMember m) => _run(
    () => context.read<ProjectsRepository>().inviteMember(
      widget.projectId,
      m.id,
    ),
    done: AppLocalizations.of(context)!.projectMemberInviteSent(m.displayName),
  );

  /// The row's end: the role (เชิญ lives in the ⋯ menu).
  ListRowTrailing? _trailing(AppLocalizations l, ProjectMember m) {
    // A plain member shows no word (owner 2026-11-03: "Member" says nothing).
    if (m.isOwner) {
      return ListRowTrailing.text(l.projectRoleOwner, tone: Tone.primary);
    }
    if (m.role == MemberRole.viewer) {
      return ListRowTrailing.text(l.projectRoleViewer);
    }
    return null;
  }

  /// F3: which of MY contacts a plain member is is mine to say, owner or not
  /// (a linked member finds my contact linked to them by itself).
  bool _contactActions(ProjectMember m) => !m.isMe && !m.isLinked;

  bool _ownerActions(ProjectMember m, bool readOnly) =>
      _isOwner && !readOnly && !m.isOwner;

  /// The row's ⋯ menu (owner 2026-11-03: no sheet; เชิญ and ออก in it too).
  List<SheetOption<String>> _memberOptions(
    AppLocalizations l,
    ProjectMember m, {
    required bool owner,
    required bool readOnly,
  }) => [
    // เชิญ / เชิญแล้ว (sent again) to my contact using the app.
    if (_isOwner && !readOnly && m.contactLinked && m.userId == null)
      SheetOption(
        value: 'invite',
        leading: AppIcon(m.invited ? AppIcons.check : AppIcons.inviteMember),
        label: m.invited ? l.projectMemberInvited : l.projectMemberInvite,
      ),
    if (_contactActions(m)) ...[
      SheetOption(
        value: 'bind',
        leading: const AppIcon(AppIcons.link),
        label: l.projectMemberBindContact,
      ),
      if (m.contactId != null)
        SheetOption(
          value: 'unbind',
          leading: const AppIcon(AppIcons.unlink),
          label: l.projectMemberUnbindContact,
        )
      else
        SheetOption(
          value: 'add-contact',
          leading: const AppIcon(AppIcons.add),
          label: l.projectMemberAddContact,
        ),
    ],
    if (owner) ...[
      SheetOption(
        value: 'role',
        leading: AppIcon(
          m.role == MemberRole.viewer ? AppIcons.edit : AppIcons.visible,
        ),
        label: m.role == MemberRole.viewer
            ? l.projectMemberMakeContributor
            : l.projectMemberMakeViewer,
      ),
      // Only a joined app user can own the event.
      if (m.isLinked && m.status == MemberStatus.active)
        SheetOption(
          value: 'transfer',
          leading: const AppIcon(AppIcons.member),
          label: l.projectMemberTransfer,
        ),
      SheetOption(
        value: 'remove',
        leading: const AppIcon(AppIcons.delete),
        label: l.projectMemberRemove,
        destructive: true,
      ),
    ],
    if (m.isMe && !readOnly)
      SheetOption(
        value: 'leave',
        leading: const AppIcon(AppIcons.logout),
        label: l.projectLeave,
        destructive: true,
      ),
  ];

  Future<void> _memberAction(ProjectMember m, String action) async {
    final l = AppLocalizations.of(context)!;
    final repo = context.read<ProjectsRepository>();
    if (action == 'invite') {
      await _sendInvite(m);
    } else if (action == 'leave') {
      await _leave();
    } else if (action == 'bind') {
      final c = await ContactPicker.contactFor(
        context,
        name: m.displayName,
        title: l.projectMemberBindContact,
      );
      if (c == null || !mounted) return;
      await _run(
        () => repo.setMyContact(widget.projectId, m.id, c.id),
        done: l.projectMemberContactBound(c.name),
      );
    } else if (action == 'add-contact') {
      await _run(() async {
        final c = await context.read<ContactsRepository>().create(
          displayName: m.displayName,
        );
        return repo.setMyContact(widget.projectId, m.id, c.contact.id);
      }, done: l.projectMemberContactAdded(m.displayName));
    } else if (action == 'unbind') {
      await _run(
        () => repo.setMyContact(widget.projectId, m.id, null),
        done: l.projectMemberContactUnbound,
      );
    } else if (action == 'role') {
      await _run(
        () => repo.updateMemberRole(
          widget.projectId,
          m.id,
          m.role == MemberRole.viewer
              ? MemberRole.contributor
              : MemberRole.viewer,
        ),
        done: l.projectMemberRoleChanged,
      );
    } else if (action == 'remove') {
      final ok = await showConfirmDialog(
        context,
        title: l.projectMemberRemoveTitle(m.displayName),
        confirmLabel: l.projectMemberRemove,
        destructive: true,
      );
      if (!ok) return;
      await _run(
        () => repo.removeMember(widget.projectId, m.id),
        done: l.projectMemberRemoved,
      );
    } else if (action == 'transfer') {
      final ok = await showConfirmDialog(
        context,
        title: l.projectMemberTransferTitle(m.displayName),
        message: l.projectMemberTransferBody(m.displayName),
        confirmLabel: l.projectMemberTransfer,
      );
      if (!ok) return;
      await _run(
        () => repo.transferOwnership(widget.projectId, m.userId!),
        done: l.projectMemberTransferred,
      );
    }
  }

  /// ออกจากอีเวนต์; the owner hands the event to a joined app user first.
  Future<void> _leave() async {
    final l = AppLocalizations.of(context)!;
    final repo = context.read<ProjectsRepository>();
    ProjectMember? heir;
    if (_isOwner) {
      final can = [
        for (final m in _members)
          if (!m.isMe && m.isLinked && m.status == MemberStatus.active) m,
      ];
      if (can.isEmpty) {
        showAppSnackBar(
          context,
          l.projectMemberTransferNeedsAccount,
          tone: Tone.danger,
        );
        return;
      }
      heir = await EventMemberPicker.one(
        context,
        members: can,
        title: l.projectLeavePickOwner,
      );
      if (heir == null || !mounted) return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l.projectLeaveTitle(_project!.name),
      message: l.projectLeaveBody,
      confirmLabel: l.projectLeave,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      if (heir != null) {
        await repo.transferOwnership(widget.projectId, heir.userId!);
      }
      await repo.leave(widget.projectId);
      if (!mounted) return;
      showAppSnackBar(context, l.projectLeft);
      context.go('/projects');
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          errorText(AppLocalizations.of(context)!, e),
          tone: Tone.danger,
        );
      }
    }
  }

  void _apply(EventPatch p) {
    context.read<ProjectsCubit>().patch(p.project);
    setState(() {
      _project = p.project;
      _members = p.members;
    });
  }

  Future<void> _run(
    Future<EventPatch> Function() action, {
    required String done,
  }) async {
    try {
      final p = await action();
      if (!mounted) return;
      _apply(p);
      showAppSnackBar(context, done, tone: Tone.success);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          errorText(AppLocalizations.of(context)!, e),
          tone: Tone.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _project;
    final readOnly =
        p?.status == ProjectStatus.archived || (p?.isCompleted ?? false);
    final groups = <(String, String, List<ProjectMember>)>[
      (
        l.projectMembersUsers,
        l.projectMembersUsersDescription,
        _members
            .where((m) => m.status == MemberStatus.active && m.isLinked)
            .toList(),
      ),
      (
        l.projectMembersNames,
        l.projectMembersNamesDescription,
        _members
            .where((m) => m.status == MemberStatus.active && !m.isLinked)
            .toList(),
      ),
      (
        l.projectMembersPending,
        l.projectMembersPendingDescription,
        _members.where((m) => m.status == MemberStatus.pending).toList(),
      ),
      (
        l.projectMembersLeft,
        l.projectMembersLeftDescription,
        _members.where((m) => m.status == MemberStatus.left).toList(),
      ),
    ].where((g) => g.$3.isNotEmpty).toList();
    final body = Builder(
      builder: (context) => ListPageBody(
        loading: _loading,
        error: p == null ? _error : null,
        isEmpty: false,
        onRetry: _load,
        empty: EmptyView(
          icon: AppIcons.member,
          title: l.projectMembersTitle,
          message: '',
        ),
        topInset: 0,
        children: [
          for (final (i, (title, description, list)) in groups.indexed)
            SectionCard(
              first: i == 0,
              title: '$title | ${list.length}',
              description: description,
              children: [
                for (final m in list)
                  _MemberRow(
                    key: ValueKey('member:${m.id}'),
                    member: m,
                    trailing: _trailing(l, m),
                    options: _memberOptions(
                      l,
                      m,
                      owner: _ownerActions(m, readOnly),
                      readOnly: readOnly,
                    ),
                    onSelected: (a) => _memberAction(m, a),
                  ),
              ],
            ),
          if (_isOwner && readOnly == false)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AddTile(
                label: l.projectMembersAdd,
                variant: AddTileVariant.row,
                icon: AppIcons.inviteMember,
                onTap: _add,
              ),
            ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppTopBar(
        title: l.projectMembersTitle,
        showBack: true,
        parent: p == null
            ? null
            : TopBarCrumb(
                label: p.name,
                path: '/projects/${p.id}',
                routeName: 'project-detail',
              ),
      ),
      extendBodyBehindAppBar: true,
      body: body,
    );
  }
}

/// A member row: its actions in a ⋯ menu at the end (owner 2026-11-03).
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.trailing,
    required this.options,
    required this.onSelected,
    super.key,
  });

  final ProjectMember member;
  final ListRowTrailing? trailing;
  final List<SheetOption<String>> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final m = member;
    return AppListRow(
      dimmed: m.status != MemberStatus.active,
      // The level reads from the mark (owner 2026-11-03): no "ไม่มีบัญชีแอป"
      // line.
      leading: PersonMark(
        name: m.displayName,
        level: m.level,
        avatar: m.avatar,
        size: 40,
      ),
      title: m.displayName,
      trailing: trailing,
      actions: [
        if (options.isNotEmpty)
          ListRowAction.menu<String>(options: options, onSelected: onSelected),
      ],
    );
  }
}
