import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/top_bar_crumbs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../event_errors.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../widgets/add_member_sheet.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/project_common.dart';

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

  Future<void> _invite() async {
    final l = AppLocalizations.of(context)!;
    final added = await showAddMemberSheet(
      context,
      projectId: widget.projectId,
    );
    if (added == null || !mounted) return;
    _apply(added.patch);
    showAppSnackBar(
      context,
      l.projectAddMemberAdded(added.name),
      tone: Tone.success,
    );
  }

  Future<void> _memberActions(ProjectMember m) async {
    final l = AppLocalizations.of(context)!;
    final action = await showActionSheet<String>(
      context,
      header: ActionSheetHeader(
        leading: memberAvatar(m, size: 40),
        title: m.displayName,
        subtitle: m.isLinked ? l.projectMemberLinked : l.projectMemberAdHoc,
      ),
      actions: [
        SheetAction(
          value: 'role',
          icon: m.role == MemberRole.viewer ? AppIcons.edit : AppIcons.visible,
          label: m.role == MemberRole.viewer
              ? l.projectMemberMakeContributor
              : l.projectMemberMakeViewer,
        ),
        SheetAction(
          value: 'transfer',
          icon: AppIcons.member,
          label: l.projectMemberTransfer,
          subtitle: m.isLinked ? null : l.projectMemberTransferNeedsAccount,
          enabled: m.isLinked && m.status == MemberStatus.active,
        ),
        SheetAction(
          value: 'remove',
          icon: AppIcons.delete,
          label: l.projectMemberRemove,
          destructive: true,
        ),
      ],
    );
    if (!mounted) return;
    final repo = context.read<ProjectsRepository>();
    if (action == 'role') {
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

  Future<void> _leave() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.projectLeaveTitle(_project!.name),
      message: l.projectLeaveBody,
      confirmLabel: l.projectLeave,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<ProjectsRepository>().leave(widget.projectId);
      if (!mounted) return;
      showAppSnackBar(context, l.projectLeft);
      context.go('/projects');
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          eventErrorText(AppLocalizations.of(context)!, e),
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
          eventErrorText(AppLocalizations.of(context)!, e),
          tone: Tone.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _project;
    final readOnly = p?.status == ProjectStatus.archived;
    final groups = <(String, String, List<ProjectMember>)>[
      (
        l.projectMembersTitle,
        l.projectMembersDescription,
        _members.where((m) => m.status == MemberStatus.active).toList(),
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
    final amMember = _members.any((m) => m.userId == _uid);
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
                  AppListRow(
                    dimmed: m.status != MemberStatus.active,
                    leading: memberAvatar(m, size: 40),
                    title: m.displayName,
                    line2: ListRowLine(
                      parts: [
                        m.isLinked
                            ? l.projectMemberLinked
                            : l.projectMemberAdHoc,
                      ],
                    ),
                    trailing: ListRowTrailing.text(
                      m.isOwner
                          ? l.projectRoleOwner
                          : m.role == MemberRole.viewer
                          ? l.projectRoleViewer
                          : l.projectRoleMember,
                      tone: m.isOwner ? Tone.primary : null,
                    ),
                    onTap: _isOwner && readOnly == false && !m.isOwner
                        ? () => _memberActions(m)
                        : null,
                  ),
              ],
            ),
          if (_isOwner && readOnly == false)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AddTile(
                label: l.projectMembersInvite,
                variant: AddTileVariant.row,
                icon: AppIcons.inviteMember,
                onTap: _invite,
              ),
            ),
          if (!_isOwner && amMember)
            DangerRow(
              icon: AppIcons.logout,
              label: l.projectLeave,
              onTap: _leave,
              padding: const EdgeInsets.only(top: AppSpacing.lg),
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
