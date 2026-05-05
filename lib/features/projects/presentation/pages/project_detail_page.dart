import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/personal_debt.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/add_member_sheet.dart';

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
    final length = p.isResolveReady ? 4 : 3;
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
      const Tab(text: 'Members'),
      const Tab(text: 'Summary'),
      if (p != null && p.isResolveReady) const Tab(text: 'Resolve'),
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
                        _TxList(
                          trees: buildProjectTxTree(_txs),
                          memberLookup: _memberOrPlaceholder,
                          myMemberId: _myMember?.id,
                          projectId: widget.id,
                          isLocked: p?.isLocked ?? true,
                          onChanged: _load,
                        ),
                        _MembersList(
                          members: _members,
                          projectId: widget.id,
                          isOwner: _isOwner,
                          onChanged: _load,
                        ),
                        _SummaryView(summary: _summary),
                        if (p != null && p.isResolveReady)
                          _ResolveSummary(
                            trees: buildProjectTxTree(_txs),
                            memberLookup: _memberOrPlaceholder,
                            myMember: _myMember,
                            projectId: widget.id,
                            currency:
                                _txs.isNotEmpty ? _txs.first.currency : 'THB',
                            suppressed: _resolvedThisSession,
                            onResolved: (key) {
                              setState(() => _resolvedThisSession.add(key));
                            },
                          ),
                      ],
                    ),
    );
  }

  /// Two stacked FABs at bottom-right: transaction (primary, on top) and
  /// add-member (secondary, below). Both visible at the same time so the
  /// owner can record a tx or add a participant without switching tabs.
  /// Returns null when there's nothing to surface (project locked, etc).
  Widget? _buildFabs(Project? p) {
    if (p == null || p.isLocked) return null;
    final canAddMember = _isOwner;
    final children = <Widget>[
      FloatingActionButton(
        heroTag: 'add-tx',
        tooltip: 'New project transaction',
        onPressed: () =>
            context.push('/projects/${widget.id}/transactions/new'),
        child: const Icon(Icons.add),
      ),
      if (canAddMember) ...[
        const SizedBox(height: 12),
        FloatingActionButton.small(
          heroTag: 'add-member',
          tooltip: 'Add member',
          onPressed: _onAddMemberPressed,
          child: const Icon(Icons.person_add),
        ),
      ],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Future<void> _onAddMemberPressed() async {
    final added = await showAddMemberSheet(context, projectId: widget.id);
    if (added == true) await _load();
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

// ─── Transactions tab — accordion (parent → children) ────────────────────────

class _TxList extends StatelessWidget {
  const _TxList({
    required this.trees,
    required this.memberLookup,
    required this.myMemberId,
    required this.projectId,
    required this.isLocked,
    required this.onChanged,
  });
  final List<ProjectTxTree> trees;
  final ProjectMember Function(String memberId) memberLookup;
  final String? myMemberId;
  final String projectId;
  final bool isLocked;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    if (trees.isEmpty) {
      return RefreshIndicator(
        onRefresh: onChanged,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: Text('No project transactions yet')),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onChanged,
      child: ListView.separated(
        itemCount: trees.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final tree = trees[i];
          return _TxTreeTile(
            tree: tree,
            memberLookup: memberLookup,
            myMemberId: myMemberId,
            projectId: projectId,
            isLocked: isLocked,
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

class _TxTreeTile extends StatelessWidget {
  const _TxTreeTile({
    required this.tree,
    required this.memberLookup,
    required this.myMemberId,
    required this.projectId,
    required this.isLocked,
    required this.onChanged,
  });
  final ProjectTxTree tree;
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
    final iMarkedParent = myId != null && parent.isMarkedBy(myId);
    final hasChildren = tree.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(
            parent.type == 'expense'
                ? Icons.arrow_upward
                : Icons.arrow_downward,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                    '${parent.amount.toStringAsFixed(2)} ${parent.currency}'),
              ),
              if (iMarkedParent)
                const Icon(Icons.check_circle, size: 18, color: Colors.green),
            ],
          ),
          subtitle: Text(
            '${actor.displayName} · ${parent.date}'
            '${hasChildren ? " · split ×${tree.children.length}" : ""}',
          ),
          trailing: parent.note != null
              ? IconButton(
                  icon: const Icon(Icons.notes),
                  onPressed: () => _showNote(context, parent.note!),
                )
              : null,
          onTap: () => _showRowSheet(
            context,
            tx: parent,
            actor: actor,
            isParent: true,
          ),
        ),
        if (hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                for (final child in tree.children)
                  _ChildTile(
                    child: child,
                    parent: parent,
                    debtor: memberLookup(child.transactionMemberId),
                    creditor: actor,
                    iMarked: myId != null && child.isMarkedBy(myId),
                    onTap: () => _showRowSheet(
                      context,
                      tx: child,
                      actor: memberLookup(child.transactionMemberId),
                      isParent: false,
                      parent: parent,
                      parentActor: actor,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _showNote(BuildContext context, String note) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Note'),
        content: Text(note),
      ),
    );
  }

  Future<void> _showRowSheet(
    BuildContext context, {
    required ProjectTransaction tx,
    required ProjectMember actor,
    required bool isParent,
    ProjectTransaction? parent,
    ProjectMember? parentActor,
  }) async {
    final myId = myMemberId;
    final iMarked = myId != null && tx.isMarkedBy(myId);
    final canMark = myId != null && !isLocked;
    final canDelete = isParent && !isLocked;
    final canResolve = _canResolve(tx,
        isParent: isParent, parent: parent, parentActor: parentActor);

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                  '${tx.amount.toStringAsFixed(2)} ${tx.currency} · ${actor.displayName}'),
              subtitle: Text(
                  '${tx.type} · ${tx.date}${isParent ? "" : " · split"}'),
            ),
            const Divider(height: 1),
            if (canMark)
              ListTile(
                leading: Icon(iMarked
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked),
                title: Text(
                    iMarked ? 'Unmark resolved' : 'Mark resolved on board'),
                subtitle: const Text(
                    'Local flag — does not create personal entries'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _toggleMark(context, tx, !iMarked);
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
                  await _showResolveSheet(
                    context,
                    tx: tx,
                    isParent: isParent,
                    parent: parent,
                    parentActor: parentActor,
                  );
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
    if (isParent) {
      // Resolve a parent row only if I'm the actor (the one who paid).
      return tx.transactionMemberId == my;
    }
    // Child: I can resolve if I'm the debtor OR the parent's actor (creditor).
    final isDebtor = tx.transactionMemberId == my;
    final isCreditor = parentActor != null && parentActor.id == my;
    return isDebtor || isCreditor;
  }

  Future<void> _toggleMark(
      BuildContext context, ProjectTransaction tx, bool marked) async {
    try {
      await context.read<ProjectsRepository>().toggleMark(
          projectId, tx.id, marked);
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
    // Counterparty for debt mode: parent's actor if I'm the debtor on a
    // child; child's debtor if I'm the creditor on a child.
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
        parentChildrenTotal:
            isParent ? _parentChildrenTotal(tx) : 0,
        myMemberId: myId,
        counterparty: counterparty,
        onDone: onChanged,
      ),
    );
  }

  double _parentChildrenTotal(ProjectTransaction parent) {
    // The tree is in a parent context only; recompute from passed-in tree
    // (the caller has it). For this widget we already have it via [tree].
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
    required this.iMarked,
    required this.onTap,
  });
  final ProjectTransaction child;
  final ProjectTransaction parent;
  final ProjectMember debtor;
  final ProjectMember creditor;
  final bool iMarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${debtor.displayName} owes ${creditor.displayName} '
              '${child.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (iMarked)
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
      onTap: onTap,
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
      Navigator.pop(context);
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
                'Full ${widget.tx.amount.toStringAsFixed(2)} · '
                'post-split ${(widget.tx.amount - widget.parentChildrenTotal).toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
              'Amount: ${_amount.toStringAsFixed(2)} ${widget.tx.currency}'),
          const SizedBox(height: 12),
          if (_mode == _ResolveMode.asTransaction)
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration:
                  const InputDecoration(labelText: 'Account *'),
              items: accounts
                  .map((a) =>
                      DropdownMenuItem(value: a.id, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            )
          else
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
    required this.onChanged,
  });
  final List<ProjectMember> members;
  final String projectId;
  final bool isOwner;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    // The "add member" affordance moved up to the scaffold-level FAB
    // stack so it's visible alongside "add transaction" on every tab.
    // This list is just the roster.
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final m = members[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              m.displayName.isNotEmpty
                  ? m.displayName[0].toUpperCase()
                  : '?',
            ),
          ),
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

// ─── Summary tab ─────────────────────────────────────────────────────────────

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});
  final ProjectSummary? summary;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = summary!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(context, 'Transactions', s.transactionCount.toString()),
        _row(context, 'Members', s.memberCount.toString()),
        _row(context, 'Total expense', s.totalExpense.toStringAsFixed(2)),
        _row(context, 'Total income', s.totalIncome.toStringAsFixed(2)),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child:
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
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
    final me = myMember;
    if (me == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'You are not a linked member of this project. Resolve actions are disabled.'),
        ),
      );
    }
    final spent = _collectSpent(me);
    final netDebts = _collectNetDebts(me);

    if (spent.isEmpty && netDebts.isEmpty) {
      return const Center(child: Text('Nothing left to resolve'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (spent.isNotEmpty) ...[
          Text('I spent', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in spent) _SpentLine(line: line, projectId: projectId, currency: currency, onResolved: onResolved),
          const SizedBox(height: 24),
        ],
        if (netDebts.isNotEmpty) ...[
          Text('Net debts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final d in netDebts)
            _NetDebtLine(
              debt: d,
              currency: currency,
              onResolved: onResolved,
            ),
        ],
      ],
    );
  }

  List<_SpentItem> _collectSpent(ProjectMember me) {
    final out = <_SpentItem>[];
    for (final t in trees) {
      final parent = t.parent;
      // Parent rows where I'm the actor → contribute (amount - children).
      if (parent.transactionMemberId == me.id) {
        final key = 'spent:parent:${parent.id}';
        if (parent.isMarkedBy(me.id) || suppressed.contains(key)) continue;
        final share = parent.amount - t.childrenTotal;
        if (share > 0.005) {
          out.add(_SpentItem(
            key: key,
            label: parent.note ?? 'Project entry',
            amount: share,
            tx: parent,
            isParent: true,
            parentChildrenTotal: t.childrenTotal,
          ));
        }
      }
      // Child rows where I'm the debtor → I "spent" my share; resolve as
      // expense or as i_owe debt.
      for (final c in t.children) {
        if (c.transactionMemberId != me.id) continue;
        final key = 'spent:child:${c.id}';
        if (c.isMarkedBy(me.id) || suppressed.contains(key)) continue;
        out.add(_SpentItem(
          key: key,
          label: parent.note ?? 'Split share',
          amount: c.amount,
          tx: c,
          isParent: false,
          parentChildrenTotal: 0,
          parent: parent,
          parentActor: memberLookup(parent.transactionMemberId),
        ));
      }
    }
    return out;
  }

  List<_NetDebtItem> _collectNetDebts(ProjectMember me) {
    // Aggregate per counterparty user_id (skip ad-hoc — no user link).
    final byUser = <String, _NetDebtAccumulator>{};
    for (final t in trees) {
      final parent = t.parent;
      for (final c in t.children) {
        // Skip child rows the user has already personally marked.
        if (c.isMarkedBy(me.id) || suppressed.contains('spent:child:${c.id}')) {
          continue;
        }
        // I am the debtor on this child → I owe parent's actor.
        if (c.transactionMemberId == me.id) {
          final cred = memberLookup(parent.transactionMemberId);
          final key = cred.userId ?? 'adhoc:${cred.id}';
          (byUser[key] ??= _NetDebtAccumulator(member: cred)).delta -=
              c.amount;
        }
        // I am the parent's actor on this child → child debtor owes me.
        if (parent.transactionMemberId == me.id &&
            c.transactionMemberId != me.id) {
          final deb = memberLookup(c.transactionMemberId);
          final key = deb.userId ?? 'adhoc:${deb.id}';
          (byUser[key] ??= _NetDebtAccumulator(member: deb)).delta +=
              c.amount;
        }
      }
    }
    final out = <_NetDebtItem>[];
    for (final entry in byUser.entries) {
      final acc = entry.value;
      if (acc.delta.abs() < 0.005) continue;
      final key = 'netdebt:${entry.key}';
      if (suppressed.contains(key)) continue;
      out.add(_NetDebtItem(
        key: key,
        counterparty: acc.member,
        amount: acc.delta.abs(),
        // delta < 0 → I owe; delta > 0 → owed to me.
        direction: acc.delta < 0 ? DebtDirection.iOwe : DebtDirection.owedToMe,
      ));
    }
    return out;
  }
}

class _SpentItem {
  _SpentItem({
    required this.key,
    required this.label,
    required this.amount,
    required this.tx,
    required this.isParent,
    required this.parentChildrenTotal,
    this.parent,
    this.parentActor,
  });
  final String key;
  final String label;
  final double amount;
  final ProjectTransaction tx;
  final bool isParent;
  final double parentChildrenTotal;
  final ProjectTransaction? parent;
  final ProjectMember? parentActor;
}

class _NetDebtAccumulator {
  _NetDebtAccumulator({required this.member});
  final ProjectMember member;
  double delta = 0;
}

class _NetDebtItem {
  _NetDebtItem({
    required this.key,
    required this.counterparty,
    required this.amount,
    required this.direction,
  });
  final String key;
  final ProjectMember counterparty;
  final double amount;
  final DebtDirection direction;
}

class _SpentLine extends StatelessWidget {
  const _SpentLine({
    required this.line,
    required this.projectId,
    required this.currency,
    required this.onResolved,
  });
  final _SpentItem line;
  final String projectId;
  final String currency;
  final void Function(String key) onResolved;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${line.amount.toStringAsFixed(2)} $currency · ${line.label}'),
        subtitle:
            Text(line.isParent ? 'Parent · post-split share' : 'Split debtor share'),
        trailing: FilledButton.tonal(
          onPressed: () => _resolve(context),
          child: const Text('Resolve'),
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context) async {
    final accountsCubit = context.read<AccountsCubit>();
    if (accountsCubit.state.accounts.isEmpty) {
      await accountsCubit.load();
    }
    if (!context.mounted) return;
    final accounts = accountsCubit.state.accounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account available')),
      );
      return;
    }
    String accountId = accounts.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resolve as expense'),
        content: StatefulBuilder(
          builder: (_, setState) => DropdownButtonFormField<String>(
            initialValue: accountId,
            items: accounts
                .map((a) =>
                    DropdownMenuItem(value: a.id, child: Text(a.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => accountId = v);
            },
            decoration: const InputDecoration(labelText: 'Account'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<TransactionsRepository>().create(
            type: TransactionType.expense,
            accountId: accountId,
            amount: line.amount,
            date: line.tx.date,
            note: line.tx.note,
            sourceProjectTransactionId: line.tx.id,
          );
      onResolved(line.key);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Resolved')));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _NetDebtLine extends StatelessWidget {
  const _NetDebtLine({
    required this.debt,
    required this.currency,
    required this.onResolved,
  });
  final _NetDebtItem debt;
  final String currency;
  final void Function(String key) onResolved;

  @override
  Widget build(BuildContext context) {
    final iOwe = debt.direction == DebtDirection.iOwe;
    return Card(
      child: ListTile(
        title: Text(
          iOwe
              ? 'I owe ${debt.counterparty.displayName} ${debt.amount.toStringAsFixed(2)} $currency'
              : '${debt.counterparty.displayName} owes me ${debt.amount.toStringAsFixed(2)} $currency',
        ),
        trailing: FilledButton.tonal(
          onPressed: () => _resolve(context),
          child: const Text('Record debt'),
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record net debt?'),
        content: Text(
          debt.direction == DebtDirection.iOwe
              ? 'Add an "I owe" entry for ${debt.counterparty.displayName}?'
              : 'Add an "owed to me" entry from ${debt.counterparty.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<PersonalDebtsRepository>().create(
            direction: debt.direction,
            counterpartyPersonName: debt.counterparty.displayName,
            amount: debt.amount,
            currency: currency,
          );
      onResolved(debt.key);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Recorded')));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
