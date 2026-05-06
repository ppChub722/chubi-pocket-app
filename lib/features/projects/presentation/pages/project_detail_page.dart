import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/personal_debt.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/add_member_sheet.dart';
import 'project_transaction_edit_page.dart';

/// `/projects/:id` — detail view. Tabs: Transactions, Members, Summary, and
/// (when status ∈ {completed, archived}) Resolve.
class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({required this.id, super.key});
  final String id;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;

  Project? _project;
  List<ProjectMember> _members = const [];
  List<ProjectTransaction> _txs = const [];
  ProjectSummary? _summary;

  /// Locally-suppressed resolve summary line keys for this session — set
  /// when the user just resolved a row from the summary tab so it doesn't
  /// reappear before they navigate away. Re-opening the page reloads.
  final Set<String> _resolvedThisSession = {};

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
      final repo = context.read<ProjectsRepository>();
      final p = await repo.get(widget.id);
      final ms = await repo.listMembers(widget.id);
      final ts = await repo.listTransactions(widget.id);
      final s = await repo.summary(widget.id);
      if (!mounted) return;
      setState(() {
        _project = p;
        _members = ms;
        _txs = ts;
        _summary = s;
        _loading = false;
        _ensureTabs();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _ensureTabs() {
    final p = _project;
    if (p == null) return;
    final length = (p.isResolveReady || kDebugMode) ? 3 : 2;
    if (_tabs?.length == length) return;
    _tabs?.dispose();
    _tabs = TabController(length: length, vsync: this);
  }

  String? get _currentUserId {
    final s = context.read<AuthCubit>().state;
    if (s is AuthAuthenticated) return s.user.id;
    return null;
  }

  ProjectMember? get _myMember {
    final uid = _currentUserId;
    if (uid == null) return null;
    for (final m in _members) {
      if (m.userId == uid) return m;
    }
    return null;
  }

  bool get _isOwner {
    final p = _project;
    final uid = _currentUserId;
    if (p == null || uid == null) return false;
    return p.ownerUserId == uid;
  }

  String get _currency => _txs.isNotEmpty ? _txs.first.currency : 'THB';

  ProjectMember _memberOrPlaceholder(String memberId) {
    return _members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => const ProjectMember(
        id: '',
        projectId: '',
        displayName: '?',
        role: MemberRole.contributor,
        status: MemberStatus.active,
      ),
    );
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final p = _project;
    final tabLabels = <Tab>[
      const Tab(text: 'Transactions'),
      const Tab(text: 'Report'),
      if (p != null && (p.isResolveReady || kDebugMode)) const Tab(text: 'Resolve'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? 'Project'),
        actions: [
          if (p != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context
                  .push('/projects/${widget.id}/edit')
                  .then((_) => _load()),
            ),
          if (p != null) _buildLifecycleMenu(p),
        ],
        bottom: tabs == null
            ? null
            : TabBar(controller: tabs, tabs: tabLabels),
      ),
      floatingActionButton: _buildFabs(p),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : tabs == null
                  ? const SizedBox.shrink()
                  : TabBarView(
                      controller: tabs,
                      children: [
                        _ProjectDashboard(
                          trees: buildProjectTxTree(_txs),
                          summary: _summary,
                          members: _members,
                          memberLookup: _memberOrPlaceholder,
                          myMemberId: _myMember?.id,
                          projectId: widget.id,
                          isLocked: p?.isLocked ?? true,
                          onChanged: _load,
                          projectName: p?.name ?? '',
                          projectType: p?.type,
                          projectDescription: p?.description,
                          projectIconCode: p?.iconCode,
                          isOwner: _isOwner,
                          onAddMember: _onAddMemberPressed,
                          onMembersTap: _onMembersTap,
                          currency: _currency,
                        ),
                        _ReportTab(
                          trees: buildProjectTxTree(_txs),
                          members: _members,
                          summary: _summary,
                          currency: _currency,
                        ),
                        if (p != null && (p.isResolveReady || kDebugMode))
                          _ResolveSummary(
                            trees: buildProjectTxTree(_txs),
                            memberLookup: _memberOrPlaceholder,
                            myMember: _myMember,
                            projectId: widget.id,
                            currency: _currency,
                            suppressed: _resolvedThisSession,
                            onResolved: (key) {
                              setState(() => _resolvedThisSession.add(key));
                            },
                          ),
                      ],
                    ),
    );
  }

  Widget? _buildFabs(Project? p) {
    if (p == null || p.isLocked) return null;
    return FloatingActionButton(
      heroTag: 'add-tx',
      tooltip: 'New project transaction',
      onPressed: () => context
          .push('/projects/${widget.id}/transactions/new')
          .then((_) => _load()),
      child: const Icon(Icons.add),
    );
  }

  Future<void> _onAddMemberPressed() async {
    final added = await showAddMemberSheet(context, projectId: widget.id);
    if (added == true) await _load();
  }

  Future<void> _onMembersTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProjectMembersScreen(
          projectId: widget.id,
          isOwner: _isOwner,
        ),
      ),
    );
    await _load();
  }

  PopupMenuButton<String> _buildLifecycleMenu(Project p) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        switch (action) {
          case 'leave':
            await _confirmLeave();
          case 'delete':
            await _confirmDelete();
          case 'mark_completed':
            await context
                .read<ProjectsCubit>()
                .update(widget.id, status: ProjectStatus.completed);
            await _load();
          case 'cancel':
            await context
                .read<ProjectsCubit>()
                .update(widget.id, status: ProjectStatus.cancelled);
            await _load();
          case 'archive':
            await context
                .read<ProjectsCubit>()
                .update(widget.id, status: ProjectStatus.archived);
            await _load();
          case 'reactivate':
            await context
                .read<ProjectsCubit>()
                .update(widget.id, status: ProjectStatus.active);
            await _load();
        }
      },
      itemBuilder: (_) => [
        if (p.isActive)
          const PopupMenuItem(
              value: 'mark_completed', child: Text('Mark completed')),
        if (p.isActive || p.status == ProjectStatus.completed)
          const PopupMenuItem(value: 'cancel', child: Text('Cancel project')),
        if (p.status != ProjectStatus.archived)
          const PopupMenuItem(value: 'archive', child: Text('Archive')),
        if (p.status == ProjectStatus.archived ||
            p.status == ProjectStatus.cancelled ||
            p.status == ProjectStatus.completed)
          const PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
        const PopupMenuItem(value: 'leave', child: Text('Leave project')),
        const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
      ],
    );
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ProjectsRepository>().leave(widget.id);
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete project?'),
        content: const Text(
            'This cannot be undone. Projects with any transactions cannot be deleted.'),
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
    if (ok != true || !mounted) return;
    try {
      await context.read<ProjectsCubit>().delete(widget.id);
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

// ─── Transactions dashboard tab ──────────────────────────────────────────────

enum _TxSort { time, amount, member, description, category }

class _ProjectDashboard extends StatefulWidget {
  const _ProjectDashboard({
    required this.trees,
    required this.summary,
    required this.members,
    required this.memberLookup,
    required this.myMemberId,
    required this.projectId,
    required this.isLocked,
    required this.onChanged,
    required this.projectName,
    required this.isOwner,
    required this.onAddMember,
    required this.onMembersTap,
    required this.currency,
    this.projectType,
    this.projectDescription,
    this.projectIconCode,
  });
  final List<ProjectTxTree> trees;
  final ProjectSummary? summary;
  final List<ProjectMember> members;
  final ProjectMember Function(String memberId) memberLookup;
  final String? myMemberId;
  final String projectId;
  final bool isLocked;
  final Future<void> Function() onChanged;
  final String projectName;
  final String? projectType;
  final String? projectDescription;
  final IconCode? projectIconCode;
  final bool isOwner;
  final Future<void> Function() onAddMember;
  final Future<void> Function() onMembersTap;
  final String currency;

  @override
  State<_ProjectDashboard> createState() => _ProjectDashboardState();
}

class _ProjectDashboardState extends State<_ProjectDashboard> {
  String? _filterType; // null = all, 'expense', 'income'
  bool _filterMine = false;
  _TxSort _sortBy = _TxSort.time;

  List<ProjectTxTree> _filteredSorted() {
    var list = widget.trees.where((t) {
      if (_filterType != null && t.parent.type != _filterType) return false;
      if (_filterMine) {
        final my = widget.myMemberId;
        if (my == null) return false;
        final involved = t.parent.transactionMemberId == my ||
            t.children.any((c) => c.transactionMemberId == my);
        if (!involved) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      switch (_sortBy) {
        case _TxSort.time:
          return b.parent.date.compareTo(a.parent.date);
        case _TxSort.amount:
          return b.parent.amount.compareTo(a.parent.amount);
        case _TxSort.member:
          return widget
              .memberLookup(a.parent.transactionMemberId)
              .displayName
              .compareTo(widget
                  .memberLookup(b.parent.transactionMemberId)
                  .displayName);
        case _TxSort.description:
          return (a.parent.description ?? '')
              .compareTo(b.parent.description ?? '');
        case _TxSort.category:
          return (a.parent.categoryName ?? '')
              .compareTo(b.parent.categoryName ?? '');
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final scheme = Theme.of(context).colorScheme;
    final activeMembers =
        widget.members.where((m) => m.status != MemberStatus.left).toList();
    final visibleCount = activeMembers.length.clamp(0, 6);
    final overflow = activeMembers.length - 5;
    final displayTrees = _filteredSorted();

    return RefreshIndicator(
      onRefresh: widget.onChanged,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project name + icon
                  Row(
                    children: [
                      if (widget.projectIconCode != null) ...[
                        IconDisplay(
                          type: IconType.project,
                          size: 36,
                          iconCode: widget.projectIconCode,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          widget.projectName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  Builder(builder: (_) {
                    final parts = [
                      if (widget.projectType != null &&
                          widget.projectType!.isNotEmpty)
                        widget.projectType!,
                      if (widget.projectDescription != null &&
                          widget.projectDescription!.isNotEmpty)
                        widget.projectDescription!,
                    ];
                    if (parts.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        parts.join(' | '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Expense',
                          value: s != null
                              ? _fmtCurrency(s.totalExpense, widget.currency)
                              : '—',
                          valueColor: scheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Income',
                          value: s != null
                              ? _fmtCurrency(s.totalIncome, widget.currency)
                              : '—',
                          valueColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onMembersTap(),
                        child: Text(
                          'Members',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.isOwner)
                        GestureDetector(
                          onTap: () => widget.onAddMember(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.person_add_alt_1,
                                size: 18, color: scheme.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (activeMembers.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onMembersTap(),
                      child: Row(
                        children: [
                          for (int i = 0; i < visibleCount; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            if (i == 5 && overflow > 1)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    scheme.surfaceContainerHighest,
                                child: Text(
                                  '+$overflow',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant),
                                ),
                              )
                            else
                              Tooltip(
                                message: activeMembers[i].displayName,
                                child: _MemberAvatar(
                                  member: activeMembers[i],
                                  radius: 16,
                                ),
                              ),
                          ],
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right,
                              size: 16, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ── Filter + sort bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterType == null,
                      onSelected: (_) =>
                          setState(() => _filterType = null),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Expense'),
                      selected: _filterType == 'expense',
                      onSelected: (_) => setState(() =>
                          _filterType =
                              _filterType == 'expense' ? null : 'expense'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Income'),
                      selected: _filterType == 'income',
                      onSelected: (_) => setState(() =>
                          _filterType =
                              _filterType == 'income' ? null : 'income'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Only me'),
                      selected: _filterMine,
                      onSelected: (v) => setState(() => _filterMine = v),
                    ),
                    const SizedBox(width: 12),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    const SizedBox(width: 8),
                    PopupMenuButton<_TxSort>(
                      tooltip: 'Sort',
                      initialValue: _sortBy,
                      onSelected: (v) => setState(() => _sortBy = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: _TxSort.time, child: Text('Sort by time')),
                        PopupMenuItem(
                            value: _TxSort.amount,
                            child: Text('Sort by amount')),
                        PopupMenuItem(
                            value: _TxSort.member,
                            child: Text('Sort by member')),
                        PopupMenuItem(
                            value: _TxSort.description,
                            child: Text('Sort by description')),
                        PopupMenuItem(
                            value: _TxSort.category,
                            child: Text('Sort by category')),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort,
                              size: 16,
                              color: _sortBy != _TxSort.time
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            switch (_sortBy) {
                              _TxSort.time => 'Time',
                              _TxSort.amount => 'Amount',
                              _TxSort.member => 'Member',
                              _TxSort.description => 'Description',
                              _TxSort.category => 'Category',
                            },
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: _sortBy != _TxSort.time
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (displayTrees.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: Text('No project transactions yet')),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Column(
                  children: [
                    _TxTreeTile(
                      tree: displayTrees[i],
                      members: widget.members,
                      memberLookup: widget.memberLookup,
                      myMemberId: widget.myMemberId,
                      projectId: widget.projectId,
                      isLocked: widget.isLocked,
                      onChanged: widget.onChanged,
                    ),
                    const Divider(height: 1),
                  ],
                ),
                childCount: displayTrees.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxTreeTile extends StatelessWidget {
  const _TxTreeTile({
    required this.tree,
    required this.members,
    required this.memberLookup,
    required this.myMemberId,
    required this.projectId,
    required this.isLocked,
    required this.onChanged,
  });
  final ProjectTxTree tree;
  final List<ProjectMember> members;
  final ProjectMember Function(String memberId) memberLookup;
  final String? myMemberId;
  final String projectId;
  final bool isLocked;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final parent = tree.parent;
    final actor = memberLookup(parent.transactionMemberId);
    final myId = myMemberId;
    final iMarked = myId != null && parent.isMarkedBy(myId);
    final hasChildren = tree.children.isNotEmpty;
    final isExpense = parent.type == 'expense';
    final amountColor =
        isExpense ? Theme.of(context).colorScheme.error : Colors.green;
    final sign = isExpense ? '−' : '+';
    final formattedAmount = '$sign${_fmtCurrency(parent.amount, parent.currency)}';
    final palette = Theme.of(context).extension<AppColors>()!;
    final catBg = parent.categoryIconCode?.bgColorFor(palette);
    final catIcon = IconRegistry.get(parent.categoryIconCode?.icon,
        fallback: isExpense ? Icons.remove : Icons.add);

    return Opacity(
      opacity: iMarked ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _showActionMenu(context,
                tx: parent, actor: actor, isParent: true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => iMarked
                        ? _showActionMenu(context,
                            tx: parent, actor: actor, isParent: true)
                        : _onCheckTap(context, parent, isParent: true),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: (catBg ?? amountColor)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            catIcon,
                            color: catBg ?? amountColor,
                            size: 18,
                          ),
                        ),
                        if (iMarked)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(Icons.check,
                                  size: 9, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.description ?? '—',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _MemberAvatar(member: actor, radius: 8),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${actor.displayName} · ${parent.date}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        if (parent.note != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            parent.note!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedAmount,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                children: [
                  for (final child in tree.children)
                    _ChildTile(
                      child: child,
                      parent: parent,
                      debtor: memberLookup(child.transactionMemberId),
                      creditor: actor,
                      myMemberId: myMemberId,
                      projectId: projectId,
                      isLocked: isLocked,
                      iMarked: myId != null && child.isMarkedBy(myId),
                      onChanged: onChanged,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onCheckTap(
    BuildContext context,
    ProjectTransaction tx, {
    required bool isParent,
    ProjectTransaction? parent,
    ProjectMember? parentActor,
  }) async {
    final canResolve = _canResolve(tx,
        isParent: isParent, parent: parent, parentActor: parentActor);
    if (canResolve && myMemberId != null) {
      await _resolveAndMark(context,
          tx: tx, isParent: isParent, parent: parent, parentActor: parentActor);
    } else {
      await _toggleMark(context, tx, true);
    }
  }

  Future<void> _resolveAndMark(
    BuildContext context, {
    required ProjectTransaction tx,
    required bool isParent,
    ProjectTransaction? parent,
    ProjectMember? parentActor,
  }) async {
    final myId = myMemberId!;
    final actor = parentActor ?? memberLookup(tx.transactionMemberId);
    final counterparty = isParent
        ? null
        : tx.transactionMemberId == myId
            ? actor
            : memberLookup(tx.transactionMemberId);

    final resolved = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ResolveSheet(
        tx: tx,
        isParent: isParent,
        parentChildrenTotal: isParent ? _parentChildrenTotal(tx) : 0,
        myMemberId: myId,
        counterparty: counterparty,
        onDone: () async {},
      ),
    );
    if (resolved == true && context.mounted) {
      await _toggleMark(context, tx, true);
    }
  }

  Future<void> _showActionMenu(
    BuildContext context, {
    required ProjectTransaction tx,
    required ProjectMember actor,
    required bool isParent,
    ProjectTransaction? parent,
    ProjectMember? parentActor,
  }) async {
    final myId = myMemberId;
    final iMarked = myId != null && tx.isMarkedBy(myId);
    final canDelete = isParent && !isLocked;
    final isExpense = tx.type == 'expense';
    final canResolve = _canResolve(tx,
        isParent: isParent, parent: parent, parentActor: parentActor);
    final menuPalette = Theme.of(context).extension<AppColors>()!;
    final menuCatBg = tx.categoryIconCode?.bgColorFor(menuPalette);
    final menuCatIcon = IconRegistry.get(tx.categoryIconCode?.icon,
        fallback: isExpense ? Icons.remove : Icons.add);
    final menuAmountColor =
        isExpense ? Theme.of(context).colorScheme.error : Colors.green;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (menuCatBg ?? menuAmountColor)
                        .withValues(alpha: 0.15),
                    child: Icon(
                      menuCatIcon,
                      color: menuCatBg ?? menuAmountColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description ?? '—',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _MemberAvatar(member: actor, radius: 8),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${actor.displayName} · ${tx.date}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        if (tx.note != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            tx.note!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isExpense ? '−' : '+'}${_fmtCurrency(tx.amount, tx.currency)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: menuAmountColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (iMarked && !isLocked)
              ListTile(
                leading: const Icon(Icons.radio_button_unchecked),
                title: const Text('Unmark'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _toggleMark(context, tx, false);
                },
              ),
            if (canResolve)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Resolve to personal book'),
                subtitle:
                    const Text('Create a personal transaction or debt entry'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _showResolveSheet(context,
                      tx: tx,
                      isParent: isParent,
                      parent: parent,
                      parentActor: parentActor);
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit transaction'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectTransactionEditPage(
                        projectId: projectId,
                        tree: tree,
                        members: members,
                      ),
                    ),
                  );
                  if (updated == true && context.mounted) await onChanged();
                },
              ),
            if (canDelete)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete row',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _delete(context, tx.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _canResolve(
    ProjectTransaction tx, {
    required bool isParent,
    ProjectTransaction? parent,
    ProjectMember? parentActor,
  }) {
    final my = myMemberId;
    if (my == null) return false;
    if (isParent) return tx.transactionMemberId == my;
    final isDebtor = tx.transactionMemberId == my;
    final isCreditor = parentActor != null && parentActor.id == my;
    return isDebtor || isCreditor;
  }

  Future<void> _toggleMark(
      BuildContext context, ProjectTransaction tx, bool marked) async {
    try {
      await context
          .read<ProjectsRepository>()
          .toggleMark(projectId, tx.id, marked);
      await onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, String txId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete row?'),
        content: const Text('Splits attached to this row are deleted too.'),
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
    try {
      await context
          .read<ProjectsRepository>()
          .deleteTransaction(projectId, txId);
      await onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showResolveSheet(
    BuildContext context, {
    required ProjectTransaction tx,
    required bool isParent,
    ProjectTransaction? parent,
    ProjectMember? parentActor,
  }) async {
    final myId = myMemberId!;
    final actor = parentActor ?? memberLookup(tx.transactionMemberId);
    final counterparty = isParent
        ? null
        : tx.transactionMemberId == myId
            ? actor
            : memberLookup(tx.transactionMemberId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ResolveSheet(
        tx: tx,
        isParent: isParent,
        parentChildrenTotal: isParent ? _parentChildrenTotal(tx) : 0,
        myMemberId: myId,
        counterparty: counterparty,
        onDone: onChanged,
      ),
    );
  }

  double _parentChildrenTotal(ProjectTransaction parent) {
    if (tree.parent.id != parent.id) return 0;
    return tree.childrenTotal;
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.child,
    required this.parent,
    required this.debtor,
    required this.creditor,
    required this.myMemberId,
    required this.projectId,
    required this.isLocked,
    required this.iMarked,
    required this.onChanged,
  });
  final ProjectTransaction child;
  final ProjectTransaction parent;
  final ProjectMember debtor;
  final ProjectMember creditor;
  final String? myMemberId;
  final String projectId;
  final bool isLocked;
  final bool iMarked;
  final Future<void> Function() onChanged;

  bool _canResolve() {
    final my = myMemberId;
    if (my == null) return false;
    return debtor.id == my || creditor.id == my;
  }

  Future<void> _toggleMark(BuildContext context, bool marked) async {
    try {
      await context
          .read<ProjectsRepository>()
          .toggleMark(projectId, child.id, marked);
      await onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _onCheckTap(BuildContext context) async {
    if (_canResolve() && myMemberId != null) {
      final myId = myMemberId!;
      final isDebtor = debtor.id == myId;
      final counterparty = isDebtor ? creditor : debtor;
      final resolved = await showModalBottomSheet<bool?>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ResolveSheet(
          tx: child,
          isParent: false,
          parentChildrenTotal: 0,
          myMemberId: myId,
          counterparty: counterparty,
          onDone: () async {},
        ),
      );
      if (resolved == true && context.mounted) {
        await _toggleMark(context, true);
      }
    } else {
      await _toggleMark(context, true);
    }
  }

  Future<void> _onTickTap(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                  '${_fmtCurrency(child.amount, child.currency)} · ${debtor.displayName}'),
              subtitle: Text('owes ${creditor.displayName}'),
            ),
            const Divider(height: 1),
            if (!isLocked)
              ListTile(
                leading: const Icon(Icons.radio_button_unchecked),
                title: const Text('Unmark'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _toggleMark(context, false);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: iMarked ? 0.5 : 1.0,
      child: InkWell(
        onTap: () => iMarked ? _onTickTap(context) : _onCheckTap(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    iMarked ? _onTickTap(context) : _onCheckTap(context),
                child: Icon(
                  iMarked ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: iMarked ? Colors.green : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              _MemberAvatar(member: debtor, radius: 10),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  debtor.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                _fmtCurrency(child.amount, child.currency),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Resolve action sheet ────────────────────────────────────────────────────

class _ResolveSheet extends StatefulWidget {
  const _ResolveSheet({
    required this.tx,
    required this.isParent,
    required this.parentChildrenTotal,
    required this.myMemberId,
    required this.counterparty,
    required this.onDone,
  });
  final ProjectTransaction tx;
  final bool isParent;
  final double parentChildrenTotal;
  final String myMemberId;

  /// For child rows only: the counterparty member (parent's actor if I'm
  /// the debtor; child's debtor if I'm the creditor). Null for parent rows.
  final ProjectMember? counterparty;
  final Future<void> Function() onDone;

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

enum _ResolveMode { asTransaction, asDebt }

class _ResolveSheetState extends State<_ResolveSheet> {
  _ResolveMode _mode = _ResolveMode.asTransaction;
  String? _accountId;
  String? _categoryId;
  bool _useFullAmount = true; // parent-only: full vs post-split
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final accountsCubit = context.read<AccountsCubit>();
    if (accountsCubit.state.accounts.isEmpty) {
      accountsCubit.load();
    }
    context.read<CategoriesCubit>().loadIfNeeded();
  }

  double get _amount {
    if (widget.isParent && !_useFullAmount) {
      final share = widget.tx.amount - widget.parentChildrenTotal;
      return share < 0 ? 0 : share;
    }
    return widget.tx.amount;
  }

  /// As transaction → expense for debtor (parent actor or child debtor),
  /// income for creditor (child where I'm the parent's actor).
  TransactionType get _txType {
    if (widget.isParent) {
      // Parent: I am the actor; sign matches the parent.type.
      return widget.tx.type == 'expense'
          ? TransactionType.expense
          : TransactionType.income;
    }
    // Child: if I'm the debtor → expense; if creditor → income.
    final iAmDebtor = widget.tx.transactionMemberId == widget.myMemberId;
    return iAmDebtor ? TransactionType.expense : TransactionType.income;
  }

  /// As debt → i_owe when I'm the debtor, owed_to_me when I'm the creditor.
  DebtDirection get _debtDirection {
    final iAmDebtor = widget.tx.transactionMemberId == widget.myMemberId;
    return iAmDebtor ? DebtDirection.iOwe : DebtDirection.owedToMe;
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_mode == _ResolveMode.asTransaction) {
        if (_accountId == null) {
          setState(() => _error = 'Pick an account');
          return;
        }
        await context.read<TransactionsRepository>().create(
              type: _txType,
              accountId: _accountId!,
              amount: _amount,
              date: widget.tx.date,
              note: widget.tx.note,
              categoryId: _categoryId,
              sourceProjectTransactionId: widget.tx.id,
            );
      } else {
        // Debt mode — child rows only.
        await context.read<PersonalDebtsRepository>().create(
              direction: _debtDirection,
              counterpartyPersonName: widget.counterparty?.displayName ?? '?',
              amount: _amount,
              currency: widget.tx.currency,
              note: widget.tx.note,
            );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      await widget.onDone();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final allCategories =
        context.watch<CategoriesCubit>().state.categories;
    final matchType = _txType == TransactionType.expense
        ? CategoryType.expense
        : CategoryType.income;
    final categories =
        allCategories.where((c) => c.type == matchType).toList();
    final canPickDebt = !widget.isParent;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resolve to personal book',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (canPickDebt)
            SegmentedButton<_ResolveMode>(
              segments: const [
                ButtonSegment(
                    value: _ResolveMode.asTransaction,
                    label: Text('As transaction')),
                ButtonSegment(
                    value: _ResolveMode.asDebt, label: Text('As debt')),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
          if (canPickDebt) const SizedBox(height: 12),
          if (widget.isParent && widget.parentChildrenTotal > 0) ...[
            SwitchListTile(
              value: !_useFullAmount,
              onChanged: (v) => setState(() => _useFullAmount = !v),
              title: const Text('Use post-split share only'),
              subtitle: Text(
                'Full ${_fmtCurrency(widget.tx.amount, widget.tx.currency)} · '
                'post-split ${_fmtCurrency(widget.tx.amount - widget.parentChildrenTotal, widget.tx.currency)}',
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text('Amount: ${_fmtCurrency(_amount, widget.tx.currency)}'),
          const SizedBox(height: 12),
          if (_mode == _ResolveMode.asTransaction) ...[
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration:
                  const InputDecoration(labelText: 'Account *'),
              items: accounts
                  .map((a) =>
                      DropdownMenuItem(value: a.id, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration:
                    const InputDecoration(labelText: 'Category (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— none —')),
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
          ] else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.handshake_outlined),
              title: Text(
                _debtDirection == DebtDirection.iOwe
                    ? 'I owe ${widget.counterparty?.displayName ?? "?"}'
                    : '${widget.counterparty?.displayName ?? "?"} owes me',
              ),
              subtitle: const Text(
                  'Counterparty is auto-filled from the project actor'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: const Text('Resolve'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Members tab ─────────────────────────────────────────────────────────────

class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.members,
    required this.projectId,
    required this.isOwner,
    required this.canAddMember,
    required this.onAddMember,
    required this.onChanged,
  });
  final List<ProjectMember> members;
  final String projectId;
  final bool isOwner;
  final bool canAddMember;
  final Future<void> Function() onAddMember;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final count = members.length + (canAddMember ? 1 : 0);
    return ListView.separated(
      itemCount: count,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (canAddMember && i == members.length) {
          return ListTile(
            leading: const Icon(Icons.person_add_outlined),
            title: const Text('Add Member'),
            onTap: () => onAddMember(),
          );
        }
        final m = members[i];
        return ListTile(
          leading: _MemberAvatar(member: m, radius: 20),
          title: Text(m.displayName),
          subtitle: Text(
              '${m.role.wire} · ${m.status.wire}${m.isLinked ? ' · linked' : ''}'),
          trailing: isOwner && !m.isOwner
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await context
                        .read<ProjectsRepository>()
                        .removeMember(projectId, m.id);
                    await onChanged();
                  },
                )
              : null,
        );
      },
    );
  }
}

// ─── Resolve summary tab ─────────────────────────────────────────────────────

class _ResolveSummary extends StatelessWidget {
  const _ResolveSummary({
    required this.trees,
    required this.memberLookup,
    required this.myMember,
    required this.projectId,
    required this.currency,
    required this.suppressed,
    required this.onResolved,
  });

  final List<ProjectTxTree> trees;
  final ProjectMember Function(String memberId) memberLookup;
  final ProjectMember? myMember;
  final String projectId;
  final String currency;
  final Set<String> suppressed;
  final void Function(String key) onResolved;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_outlined, size: 48),
          SizedBox(height: 12),
          Text('Coming soon in Phase 2'),
        ],
      ),
    );
  }

}

// ─── Report tab ──────────────────────────────────────────────────────────────

class _ReportTab extends StatelessWidget {
  const _ReportTab({
    required this.trees,
    required this.members,
    required this.summary,
    required this.currency,
  });
  final List<ProjectTxTree> trees;
  final List<ProjectMember> members;
  final ProjectSummary? summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 48),
          SizedBox(height: 12),
          Text('Coming soon in Phase 2'),
        ],
      ),
    );
  }
}

// ─── Members screen ───────────────────────────────────────────────────────────

class _ProjectMembersScreen extends StatefulWidget {
  const _ProjectMembersScreen({
    required this.projectId,
    required this.isOwner,
  });
  final String projectId;
  final bool isOwner;

  @override
  State<_ProjectMembersScreen> createState() =>
      _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<_ProjectMembersScreen> {
  List<ProjectMember> _members = const [];
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
      final ms = await context
          .read<ProjectsRepository>()
          .listMembers(widget.projectId);
      if (!mounted) return;
      setState(() {
        _members = ms;
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

  Future<void> _onAddMember() async {
    final added =
        await showAddMemberSheet(context, projectId: widget.projectId);
    if (added == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _MembersList(
                  members: _members,
                  projectId: widget.projectId,
                  isOwner: widget.isOwner,
                  canAddMember: widget.isOwner,
                  onAddMember: _onAddMember,
                  onChanged: _load,
                ),
    );
  }
}

// ─── Member avatar ────────────────────────────────────────────────────────────

/// Shows the member's avatar. Uses iconCode if set; falls back to
/// deterministic colored initial from their member id.
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, this.radius = 16});
  final ProjectMember member;
  final double radius;

  static const _palette = <Color>[
    Color(0xFF64B5F6),
    Color(0xFFAED581),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF4DD0E1),
    Color(0xFFF06292),
    Color(0xFF9575CD),
    Color(0xFFFFD54F),
    Color(0xFFA1887F),
    Color(0xFF4FC3F7),
    Color(0xFF7986CB),
    Color(0xFFE57373),
  ];

  Color get _bgColor {
    final idx = member.id.hashCode.abs() % _palette.length;
    return _palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (member.iconCode != null) {
      return IconDisplay(
        type: IconType.projectMember,
        size: radius * 2,
        iconCode: member.iconCode,
      );
    }
    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: _bgColor.withValues(alpha: 0.28),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.75,
          color: _bgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Formats [amount] with thousands separators and currency symbol.
/// THB → `฿1,234.00`; other currencies → `USD 1,234.00`.
String _fmtCurrency(double amount, String currency) {
  final fixed = amount.toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final intPart = fixed.substring(0, dot);
  final decPart = fixed.substring(dot);
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final sym = currency == 'THB' ? '฿' : '$currency ';
  return '$sym${buf.toString()}$decPart';
}
