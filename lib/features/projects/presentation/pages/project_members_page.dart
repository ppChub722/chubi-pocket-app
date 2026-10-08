import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/top_bar_crumbs.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/project_common.dart';

/// `/projects/:id/members` (§12b): members / waiting / left groups, owner
/// pill, "+ เชิญสมาชิก" (owner), member sheet (remove · make owner), and
/// "ออกจากโปรเจกต์" for non-owners (the BE won't let the owner leave).
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
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  String? get _uid {
    final s = context.read<AuthCubit>().state;
    return s is AuthAuthenticated ? s.user.id : null;
  }

  bool get _isOwner => _project != null && _project!.ownerUserId == _uid;

  Future<void> _invite() async {
    final l = AppLocalizations.of(context)!;
    final name = await showAddMemberSheet(context, projectId: widget.projectId);
    if (name == null || !mounted) return;
    showAppSnackBar(context, l.projectAddMemberAdded(name), tone: Tone.success);
    await _load();
  }

  Future<void> _memberActions(ProjectMember m) async {
    final l = AppLocalizations.of(context)!;
    final action = await showAppSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ProjectMemberAvatar(member: m, size: 40),
            title: Text(m.displayName),
            subtitle: Text(m.isLinked ? l.projectMemberLinked : l.projectMemberAdHoc),
          ),
          const Divider(height: 1),
          // Viewer = read-only (contract §6b); toggles back to member.
          ListTile(
            leading: Icon(m.role == MemberRole.viewer
                ? Icons.edit_outlined
                : Icons.visibility_outlined),
            title: Text(m.role == MemberRole.viewer
                ? l.projectMemberMakeContributor
                : l.projectMemberMakeViewer),
            onTap: () => Navigator.pop(sheet, 'role'),
          ),
          ListTile(
            leading: const Icon(AppIcons.member),
            title: Text(l.projectMemberTransfer),
            subtitle: m.isLinked ? null : Text(l.projectMemberTransferNeedsAccount),
            enabled: m.isLinked && m.status == MemberStatus.active,
            onTap: () => Navigator.pop(sheet, 'transfer'),
          ),
          ListTile(
            leading: Icon(AppIcons.delete,
                color: Theme.of(context).colorScheme.error),
            title: Text(l.projectMemberRemove,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => Navigator.pop(sheet, 'remove'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
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
                  : MemberRole.viewer),
          done: l.projectMemberRoleChanged);
    } else if (action == 'remove') {
      final ok = await showConfirmDialog(
        context,
        title: l.projectMemberRemoveTitle(m.displayName),
        confirmLabel: l.projectMemberRemove,
        destructive: true,
      );
      if (!ok) return;
      await _run(() => repo.removeMember(widget.projectId, m.id),
          done: l.projectMemberRemoved);
    } else if (action == 'transfer') {
      final ok = await showConfirmDialog(
        context,
        title: l.projectMemberTransferTitle(m.displayName),
        message: l.projectMemberTransferBody(m.displayName),
        confirmLabel: l.projectMemberTransfer,
      );
      if (!ok) return;
      await _run(() => repo.transferOwnership(widget.projectId, m.userId!),
          done: l.projectMemberTransferred);
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
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _run(Future<void> Function() action, {required String done}) async {
    try {
      await action();
      if (!mounted) return;
      showAppSnackBar(context, done, tone: Tone.success);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _project;
    Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_error != null && p == null) {
      body = ErrorView(error: _error!, onRetry: _load);
    } else {
      final readOnly = p!.status == ProjectStatus.archived;
      final groups = <(String, List<ProjectMember>)>[
        (l.projectMembersTitle,
            _members.where((m) => m.status == MemberStatus.active).toList()),
        (l.projectMembersPending,
            _members.where((m) => m.status == MemberStatus.pending).toList()),
        (l.projectMembersLeft,
            _members.where((m) => m.status == MemberStatus.left).toList()),
      ];
      final amMember = _members.any((m) => m.userId == _uid);
      body = PullToRefresh(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final (title, list) in groups)
              if (list.isNotEmpty) ...[
                SectionHeader(title: title, count: list.length),
                for (final m in list)
                  Opacity(
                    opacity: m.status == MemberStatus.active ? 1 : 0.6,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      leading: ProjectMemberAvatar(member: m, size: 40),
                      title: Text(m.displayName),
                      subtitle: Text(m.isLinked
                          ? l.projectMemberLinked
                          : l.projectMemberAdHoc),
                      trailing: StatusPill(
                        label: m.isOwner
                            ? l.projectRoleOwner
                            : m.role == MemberRole.viewer
                                ? l.projectRoleViewer
                                : l.projectRoleMember,
                        tone: m.isOwner ? Tone.primary : Tone.neutral,
                        dense: true,
                      ),
                      // Owner manages everyone but themself.
                      onTap: _isOwner && !readOnly && !m.isOwner
                          ? () => _memberActions(m)
                          : null,
                    ),
                  ),
              ],
            if (_isOwner && !readOnly)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AddTile(
                  label: l.projectMembersInvite,
                  variant: AddTileVariant.row,
                  icon: AppIcons.inviteMember,
                  onTap: _invite,
                ),
              ),
            if (!_isOwner && amMember)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton(
                  label: l.projectLeave,
                  icon: AppIcons.logout,
                  variant: AppButtonVariant.destructive,
                  expand: true,
                  onPressed: _leave,
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppTopBar(
        title: l.projectMembersTitle,
        showBack: true,
        // The parent is this project, not the project list.
        parent: p == null
            ? null
            : TopBarCrumb(
                label: p.name,
                path: '/projects/${p.id}',
                routeName: 'project-detail',
              ),
      ),
      body: body,
    );
  }
}
