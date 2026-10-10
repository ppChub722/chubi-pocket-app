import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/project_common.dart';
import '../widgets/project_dashboard_tab.dart';
import '../widgets/project_tx_list_tab.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';

enum _Tab { dashboard, transactions, resolve }

enum _Field { name, description, note, planned }

/// `/projects/:id` (§12b). Header card (icon · name · status pill · type),
/// คำอธิบาย / โน้ต (only the filled ones in view mode — the tabs need the
/// room), a lock banner when the status restricts rows, then แดชบอร์ด / รายการ /
/// เคลียร์ยอด. ✏️ on the header card edits the project info in place (owner
/// only — the BE allows nobody else); status changes from the pill; a
/// delete row under the info in edit mode; "+ เพิ่มรายการ" in the รายการ tab.
class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    required this.id,
    this.startEditing = false,
    super.key,
  });

  final String id;
  final bool startEditing;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with EditModeMixin<ProjectDetailPage, _InfoDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _focus = {for (final f in _Field.values) f: FocusNode()};

  ProjectView? _view;
  ApiException? _error;
  _Tab _tab = _Tab.dashboard;

  @override
  void initState() {
    super.initState();
    initDraft(const _InfoDraft());
    _load(enterEdit: widget.startEditing);
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool enterEdit = false}) async {
    try {
      final repo = context.read<ProjectsRepository>();
      final auth = context.read<AuthCubit>().state;
      final results = await Future.wait([
        repo.get(widget.id),
        repo.listMembers(widget.id),
        repo.listTransactions(widget.id, perPage: 100),
        repo.summary(widget.id),
      ]);
      if (!mounted) return;
      final view = ProjectView(
        project: results[0] as Project,
        members: results[1] as List<ProjectMember>,
        txs: results[2] as List<ProjectTransaction>,
        summary: results[3] as ProjectSummary,
        currentUserId: auth is AuthAuthenticated ? auth.user.id : null,
      );
      setState(() {
        _view = view;
        _error = null;
        if (_tab == _Tab.resolve && !view.project.isResolveReady) {
          _tab = _Tab.dashboard;
        }
      });
      resetDraft(_InfoDraft.from(view.project));
      if (enterEdit && view.isOwner) this.enterEdit();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  void onDraftRestored() {
    void sync(_Field f, String v) {
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }

    sync(_Field.name, working.name);
    sync(_Field.description, working.description);
    sync(_Field.note, working.note);
    sync(_Field.planned, working.planned);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.description => working.copyWith(description: v),
    _Field.note => working.copyWith(note: v),
    _Field.planned => working.copyWith(planned: v),
  });

  // ── Info save / delete ──────────────────────────────────────────────

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    final planned = AmountField.parse(w.planned);
    final hadPlan = original.planned.trim().isNotEmpty;
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      await context.read<ProjectsCubit>().update(
        widget.id,
        name: w.name.trim(),
        // '' clears (migration 51).
        description: w.description.trim(),
        note: w.note.trim(),
        iconCode: w.iconCode,
        plannedAmount: planned,
        // Blanked an existing plan → explicit null hides it (§10/4.23).
        clearPlannedAmount: planned == null && hadPlan,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final p = _view!.project;
    final ok = await showConfirmDialog(
      context,
      title: l.projectDeleteTitle(p.name),
      message: l.projectDeleteBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await context.read<ProjectsCubit>().delete(p.id);
      if (!mounted) return;
      showAppSnackBar(context, l.projectDeleted, tone: Tone.success);
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.project,
      title: l.projectIconLabel,
      initial: working.iconCode,
    );
    if (!mounted || r is! IconMakerSelected) return;
    applyChange(working.copyWith(iconCode: r.iconCode));
  }

  // ── Status / members / rows ─────────────────────────────────────────

  Future<void> _changeStatus() async {
    final l = AppLocalizations.of(context)!;
    final current = _view!.project.status;
    final next = await showOptionSheet<ProjectStatus>(
      context,
      title: l.projectStatusChangeTitle,
      selected: current,
      options: [
        for (final s in ProjectStatus.values)
          SheetOption(value: s, label: projectStatusLabel(l, s)),
      ],
    );
    if (next == null || next == current || !mounted) return;
    final locks =
        next == ProjectStatus.cancelled || next == ProjectStatus.archived;
    if (locks) {
      final ok = await showConfirmDialog(
        context,
        title: l.projectStatusLockTitle(projectStatusLabel(l, next)),
        message: l.projectStatusLockBody,
        confirmLabel: projectStatusLabel(l, next),
      );
      if (!ok || !mounted) return;
    }
    try {
      await context.read<ProjectsCubit>().update(widget.id, status: next);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.projectStatusChanged(projectStatusLabel(l, next)),
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _openMembers() async {
    await context.push('/projects/${widget.id}/members');
    if (mounted) await _load();
  }

  Future<void> _invite() async {
    final l = AppLocalizations.of(context)!;
    final name = await showAddMemberSheet(context, projectId: widget.id);
    if (name == null || !mounted) return;
    showAppSnackBar(context, l.projectAddMemberAdded(name), tone: Tone.success);
    await _load();
  }

  Future<void> _addTx() async {
    final view = _view;
    if (view == null) return;
    final saved = await showQuickCreateSheet(context, project: view);
    if (saved && mounted) await _load();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = _view;
    if (v == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.navProjects, showBack: true),
        extendBodyBehindAppBar: true,
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _load)
            : Builder(
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: const LoadingView(),
                ),
              ),
      );
    }
    final p = v.project;
    final lock = projectLockMessage(l, p.status);
    final tabs = [
      AppTab(value: _Tab.dashboard, label: l.projectTabDashboard),
      AppTab(value: _Tab.transactions, label: l.projectTabTransactions),
      if (p.isResolveReady)
        AppTab(value: _Tab.resolve, label: l.projectTabResolve),
    ];
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: isEditing ? l.projectEditTitle : p.name,
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: the bar height is only in the body's MediaQuery.
          child: Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (+ edit fields + delete) scrolls on its own and only
                // takes the room it needs — when space runs short (keyboard
                // up in edit mode on a small phone) it scrolls instead of
                // overflowing; the tabs get the rest.
                Flexible(
                  flex: isEditing ? 3 : 1,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      MediaQuery.paddingOf(context).top + AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(l, v),
                        ?_texts(l, v),
                        // Delete sits under the edit-mode info (the tabs below
                        // are locked while editing, so this is the page's last
                        // live row).
                        if (isEditing)
                          DangerRow(
                            icon: AppIcons.delete,
                            label: l.projectDeleteThis,
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            onTap: isSaving ? null : _delete,
                          ),
                      ],
                    ),
                  ),
                ),
                if (lock != null && !isEditing) _LockBanner(message: lock),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: LockedInEdit(
                    locked: isEditing,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTabBar<_Tab>(
                          selected: _tab,
                          onChanged: (t) => setState(() => _tab = t),
                          tabs: tabs,
                        ),
                        Expanded(child: _tabBody(l, v)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  Widget _tabBody(AppLocalizations l, ProjectView v) => switch (_tab) {
    _Tab.dashboard => ProjectDashboardTab(
      view: v,
      onChanged: _load,
      onSeeAll: () => setState(() => _tab = _Tab.transactions),
      onAdd: v.canAddTx ? _addTx : null,
      onOpenMembers: _openMembers,
      onInvite: v.isOwner && v.project.status != ProjectStatus.archived
          ? _invite
          : null,
    ),
    _Tab.transactions => ProjectTxListTab(
      view: v,
      onChanged: _load,
      onAdd: v.canAddTx ? _addTx : null,
    ),
    _Tab.resolve => EmptyView(
      icon: AppIcons.settle,
      title: l.projectTabResolve,
      message: l.projectResolveComingSoon,
    ),
  };

  Widget _header(AppLocalizations l, ProjectView v) {
    final editing = isEditing;
    final project = v.project;
    return HeaderCard(
      onEdit: v.isOwner && !editing ? enterEdit : null,
      leading: EditableCircle(
        size: 48,
        onTap: editing ? _openIconMaker : null,
        child: IconDisplay(
          type: IconType.project,
          size: 48,
          iconCode: working.iconCode,
        ),
      ),
      title: InlineTitleField(
        editing: editing,
        controller: _ctrl[_Field.name]!,
        focusNode: _focus[_Field.name],
        hint: l.commonName,
        maxLength: TextLimits.name,
        onEnterEdit: v.isOwner
            ? () => enterEdit(focus: _focus[_Field.name])
            : null,
        onChanged: (t) => _onText(_Field.name, t),
        validator: (t) =>
            (t?.trim().isEmpty ?? true) ? l.projectNameRequired : null,
      ),
      subtitle: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ProjectStatusPill(
            status: project.status,
            dense: true,
            // Owner only; not while editing the info.
            onTap: v.isOwner && !editing ? _changeStatus : null,
          ),
          if (project.type?.isNotEmpty ?? false) Text(project.type!),
        ],
      ),
      footer: editing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                AmountField(
                  controller: _ctrl[_Field.planned]!,
                  label: l.projectFormPlannedLabel,
                  currencySymbol: v.symbol,
                  onChanged: (t) => _onText(_Field.planned, t),
                  validator: (t) {
                    if (t == null || t.trim().isEmpty) return null;
                    final n = AmountField.parse(t);
                    return (n == null || n <= 0)
                        ? l.projectFormPlannedInvalid
                        : null;
                  },
                ),
                Text(
                  l.projectFormPlannedHelper,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : null,
    );
  }

  /// คำอธิบาย / โน้ต under the header — both while editing; in view mode
  /// only the filled ones (null when neither is), so an empty project
  /// doesn't push the tabs down.
  Widget? _texts(AppLocalizations l, ProjectView v) {
    final editing = isEditing;
    Widget? row(_Field f, String label, String value, int max) {
      if (!editing && value.trim().isEmpty) return null;
      return DetailStacked(
        label: label,
        child: InlineField(
          editing: editing,
          controller: _ctrl[f]!,
          focusNode: _focus[f],
          maxLines: 3,
          maxLength: max,
          onEnterEdit: v.isOwner ? () => enterEdit(focus: _focus[f]) : null,
          onChanged: (t) => _onText(f, t),
        ),
      );
    }

    final rows = [
      ?row(
        _Field.description,
        l.commonDescription,
        working.description,
        TextLimits.description,
      ),
      ?row(_Field.note, l.commonNote, working.note, TextLimits.note),
    ];
    if (rows.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SectionCard(first: true, children: rows),
    );
  }
}

class _LockBanner extends StatelessWidget {
  const _LockBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(AppIcons.lock, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDraft {
  const _InfoDraft({
    this.name = '',
    this.description = '',
    this.note = '',
    this.planned = '',
    this.iconCode,
  });

  factory _InfoDraft.from(Project p) => _InfoDraft(
    name: p.name,
    description: p.description ?? '',
    note: p.note ?? '',
    planned: p.plannedAmount == null
        ? ''
        : AmountField.format(p.plannedAmount!),
    iconCode: p.iconCode,
  );

  final String name;
  final String description;
  final String note;

  /// Formatted, as in the field; empty = no plan.
  final String planned;
  final IconCode? iconCode;

  _InfoDraft copyWith({
    String? name,
    String? description,
    String? note,
    String? planned,
    IconCode? iconCode,
  }) => _InfoDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    planned: planned ?? this.planned,
    iconCode: iconCode ?? this.iconCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _InfoDraft &&
      other.name == name &&
      other.description == description &&
      other.note == note &&
      other.planned == planned &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(name, description, note, planned, iconCode);
}
