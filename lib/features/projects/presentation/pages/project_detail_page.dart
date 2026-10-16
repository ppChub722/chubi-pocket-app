import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../event_errors.dart';
import '../../../../ui/ui.dart';
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
    this.initialBillId,
    super.key,
  });

  final String id;
  final bool startEditing;

  /// A bill to show (tx detail's "อยู่ในอีเวนต์ … ›"): the page opens on
  /// รายการ, scrolled to it. Null = read `?bill=` from the route.
  final String? initialBillId;

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

  /// The รายการ tab's tag filter (a tag chip's "ดูบิลที่ติดแท็กนี้").
  BoardTag? _tagFilter;

  /// The hero (the compact bar watches it), the page's outer scroll and the
  /// tab pager.
  final _heroKey = GlobalKey();
  final _outerScroll = ScrollController();
  late final PageController _pages;

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
    _outerScroll.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// The page's one "open" call (also pull-to-refresh and the reload after a
  /// write whose response can't patch the page yet).
  Future<void> _load({bool enterEdit = false}) async {
    try {
      final repo = context.read<ProjectsRepository>();
      final projects = context.read<ProjectsCubit>();
      final auth = context.read<AuthCubit>().state;
      final user = auth is AuthAuthenticated ? auth.user : null;
      final detail = await repo.detail(widget.id);
      if (!mounted) return;
      // The list shows this event too: keep it fresh without its own reload.
      projects.patch(detail.project);
      _show(ProjectView.of(detail, currentUserId: user?.id));
      if (enterEdit && _view!.isOwner) this.enterEdit();
    } catch (e, st) {
      // ANY failure (a parse error too) lands in the error + retry view.
      if (mounted) setState(() => _error = ApiException.from(e, st));
    }
  }

  /// The bill to scroll to once (`?bill=`), cleared after.
  String? _focusBill;
  bool _focusRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusRead) return;
    _focusRead = true;
    _focusBill = widget.initialBillId ?? _routeBill();
    if (_focusBill != null) _tab = _Tab.transactions;
    // The pager starts on the opening tab (สรุป = 0, รายการ = 1).
    _pages = PageController(initialPage: _tab == _Tab.transactions ? 1 : 0);
  }

  /// `?bill=` on this page's route; null outside a router (tests).
  String? _routeBill() {
    try {
      return GoRouterState.of(context).uri.queryParameters['bill'];
    } catch (_) {
      return null;
    }
  }

  /// Puts [view] on screen (a load, or a write's response patched in).
  void _show(ProjectView view) {
    setState(() {
      _view = view;
      _error = null;
      if (_tab == _Tab.resolve && !view.project.isResolveReady) {
        _tab = _Tab.dashboard;
      }
    });
    resetDraft(_InfoDraft.from(view.project));
  }

  /// A write's [EventPatch]: the page and the events list patched in
  /// place (no reload).
  void _applyPatch(EventPatch p) {
    final v = _view;
    if (v == null || !mounted) return;
    context.read<ProjectsCubit>().patch(p.project);
    context.read<AccountsCubit>().patchBalances(p.accountBalances);
    setState(() => _view = v.apply(p));
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
    final l = AppLocalizations.of(context)!;
    final w = working;
    final s = w.startDate;
    final e = w.endDate;
    if (s != null && e != null && e.isBefore(s)) {
      showAppSnackBar(context, l.eventDatesInvalid, tone: Tone.danger);
      return;
    }
    final planned = AmountInput.parse(w.planned);
    final hadPlan = original.planned.trim().isNotEmpty;
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final updated = await context.read<ProjectsCubit>().update(
        widget.id,
        name: w.name.trim(),
        // '' clears (migration 51).
        description: w.description.trim(),
        note: w.note.trim(),
        startDate: s == null ? null : projectDay(s),
        endDate: e == null ? null : projectDay(e),
        // A date taken away → explicit null clears it.
        clearStartDate: s == null && original.startDate != null,
        clearEndDate: e == null && original.endDate != null,
        iconCode: w.iconCode,
        plannedAmount: planned,
        // Blanked an existing plan → explicit null hides it (§10/4.23).
        clearPlannedAmount: planned == null && hadPlan,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      // The PUT returns the patch (event + summary): no reload.
      _show(_view!.apply(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(
        context,
        eventErrorText(AppLocalizations.of(context)!, e),
        tone: Tone.danger,
      );
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final p = _view!.project;
    final linked = p.linkedTxCount;
    // ยังก่อน · ยืนยัน ไม่ลบรายการ · ยืนยันและลบ [x] รายการ (owner
    // 2026-10-13); without linked transactions: ยังก่อน · ยืนยันลบ.
    final choice = await showChoiceDialog<_DeleteChoice>(
      context,
      title: l.projectDeleteTitle(p.name),
      message: linked > 0 ? l.eventDeleteBody : null,
      choices: [
        DialogChoice(
          value: _DeleteChoice.notYet,
          label: l.eventDeleteNotYet,
          variant: AppButtonVariant.primary,
        ),
        if (linked > 0) ...[
          DialogChoice(
            value: _DeleteChoice.keepTxs,
            label: l.eventDeleteKeepTxs,
          ),
          DialogChoice(
            value: _DeleteChoice.withTxs,
            label: l.eventDeleteWithTxs(linked),
            variant: AppButtonVariant.destructive,
          ),
        ] else
          DialogChoice(
            value: _DeleteChoice.keepTxs,
            label: l.eventDeleteConfirm,
            variant: AppButtonVariant.destructive,
          ),
      ],
    );
    if (choice == null || choice == _DeleteChoice.notYet || !mounted) return;
    final withTxs = choice == _DeleteChoice.withTxs;
    setSaving(true);
    try {
      final accounts = context.read<AccountsCubit>();
      final balances = await context.read<ProjectsCubit>().delete(
        p.id,
        deleteLinkedTxs: withTxs,
      );
      // My book lost transactions: wallets from the answer, the lists
      // refresh themselves.
      accounts.patchBalances(balances);
      if (withTxs) await TransactionsCubit.bookChanged();
      if (!mounted) return;
      showAppSnackBar(context, l.projectDeleted, tone: Tone.success);
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(
        context,
        eventErrorText(AppLocalizations.of(context)!, e),
        tone: Tone.danger,
      );
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

  /// Start / end bound each other (end ≥ start); both optional.
  Future<void> _pickDate({required bool start}) async {
    final l = AppLocalizations.of(context)!;
    final w = working;
    final first = start ? null : w.startDate;
    final last = start ? w.endDate : null;
    final current = start ? w.startDate : w.endDate;
    var initial = current ?? DateTime.now();
    if (first != null && initial.isBefore(first)) initial = first;
    if (last != null && initial.isAfter(last)) initial = last;
    final r = await showAppDatePicker(
      context,
      title: start ? l.eventStartDateLabel : l.eventEndDateLabel,
      initial: initial,
      first: first,
      last: last,
      clearable: current != null,
    );
    if (!mounted || r == null) return;
    final picked = r is AppDatePicked ? r.date : null;
    applyChange(
      start
          ? w.copyWith(startDate: () => picked)
          : w.copyWith(endDate: () => picked),
    );
  }

  // ── Status / members / rows ─────────────────────────────────────────

  Future<void> _changeStatus(ProjectStatus next) async {
    final l = AppLocalizations.of(context)!;
    final current = _view!.project.status;
    if (next == current || !mounted) return;
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
      final updated = await context.read<ProjectsCubit>().update(
        widget.id,
        status: next,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.projectStatusChanged(projectStatusLabel(l, next)),
      );
      _show(_view!.apply(updated));
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

  Future<void> _openMembers() async {
    await context.push('/projects/${widget.id}/members');
    if (mounted) await _load();
  }

  Future<void> _invite() async {
    final l = AppLocalizations.of(context)!;
    final added = await showAddMemberSheet(context, projectId: widget.id);
    if (added == null || !mounted) return;
    _applyPatch(added.patch);
    showAppSnackBar(
      context,
      l.projectAddMemberAdded(added.name),
      tone: Tone.success,
    );
  }

  /// Quick create in event mode hands back the write's patch.
  Future<void> _addTx() async {
    final view = _view;
    if (view == null) return;
    await showQuickCreateSheet(
      context,
      project: view,
      onEventSaved: _applyPatch,
    );
  }

  /// The board's next page (the unfiltered รายการ list).
  Future<void> _loadMoreRows() async {
    final v = _view;
    if (v == null || !v.hasMoreRows) return;
    final rows = await context.read<ProjectsRepository>().listTransactions(
      widget.id,
      page: v.page + 1,
      perPage: 50,
    );
    if (!mounted || !identical(_view, v)) return;
    setState(() => _view = v.withMore(rows, page: v.page + 1));
  }

  /// Copies event tags into MY personal set ([ids] empty = all I don't
  /// have): one call; the event's tags come back with `mine` updated.
  Future<void> _importTags([List<String> ids = const []]) async {
    final l = AppLocalizations.of(context)!;
    final tags = context.read<TagsCubit>();
    try {
      final r = await context.read<ProjectsRepository>().importTags(
        widget.id,
        tagIds: ids,
      );
      if (!mounted) return;
      setState(() => _view = _view?.withEventTags(r.tags));
      // TODO(tags owner): TagsCubit has no patch-in; refresh it once so the
      // pickers see the new tags.
      if (r.created.isNotEmpty) unawaited(tags.load());
      showAppSnackBar(
        context,
        l.eventTagsImported(r.created.length),
        tone: Tone.success,
      );
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

  // ── Build ───────────────────────────────────────────────────────────

  void _goTab(_Tab t) => setState(() => _tab = t);

  void _scrollToHero() {
    if (!_outerScroll.hasClients) return;
    _outerScroll.animateTo(
      0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.chrome,
      curve: AppDurations.chromeCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = _view;
    if (v == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.navProjects, showBack: true),
        extendBodyBehindAppBar: true,
        // Builder: the bar height is only in the body's MediaQuery.
        body: Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: AsyncStateView.fallback(
              loading: _error == null,
              error: _error,
              onRetry: _load,
              notFound: EmptyView(
                icon: AppIcons.empty,
                title: l.navProjects,
                message: '',
              ),
            ),
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
    final values = [for (final t in tabs) t.value];
    // Edit mode lives on แดชบอร์ด (the tabs are locked while editing).
    if (isEditing || !values.contains(_tab)) _tab = _Tab.dashboard;
    final palette = Theme.of(context).extension<AppColors>()!;
    final style = HeroStyle.tinted(
      color: working.iconCode.tintFor(palette),
      glyph: AppIcons.project,
    );
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          // The saved name, in both modes (titles never change, owner
          // 2026-10-11).
          title: p.name,
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: the bar height is only in the body's MediaQuery.
          child: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              final texts = _texts(l, v);
              // The hero (+ info) scrolls away; the tab bar pins right under
              // the top bar; each tab scrolls inside. Once the hero is gone
              // the compact bar floats under the tabs (tap: back to it).
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: CompactHeroScope(
                  heroKey: _heroKey,
                  top: isEditing ? 0 : PinnedTabBarDelegate.height,
                  bar: CompactHeroBar(
                    style: style,
                    leading: IconDisplay(
                      type: IconType.project,
                      size: 28,
                      iconCode: p.iconCode,
                    ),
                    title: Text(p.name),
                    trailing: AppChip(
                      label: projectStatusLabel(l, p.status),
                      dot: true,
                      tone: projectStatusTone(p.status),
                      selected: true,
                      size: ChipSize.chip,
                    ),
                    onTap: _scrollToHero,
                  ),
                  child: NestedScrollView(
                    controller: _outerScroll,
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KeyedSubtree(
                                key: _heroKey,
                                child: _header(l, v, style),
                              ),
                              // My own tags on the event, right under the
                              // hero (detail-page order).
                              if (!isEditing) ...[
                                const SizedBox(height: AppSpacing.md),
                                _tagRow(l, v),
                              ],
                              if (texts != null) ...[
                                const SizedBox(height: HeroSpacing.after),
                                texts,
                              ],
                              if (lock != null && !isEditing) ...[
                                const SizedBox(height: AppSpacing.lg),
                                AppMessage(
                                  message: lock,
                                  tone: Tone.neutral,
                                  icon: AppIcons.lock,
                                ),
                              ],
                              // Delete sits under the edit-mode info (the
                              // tabs below are locked while editing, so this
                              // is the page's last live row).
                              if (isEditing) ...[
                                ManageSection(
                                  deleteLabel: l.projectDeleteThis,
                                  onDelete: isSaving ? null : _delete,
                                ),
                                DetailMeta(
                                  lines: detailMetaLines(
                                    context,
                                    createdAt: p.createdAt,
                                    updatedAt: p.updatedAt,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!isEditing)
                        const SliverToBoxAdapter(
                          child: SizedBox(height: HeroSpacing.after),
                        ),
                      if (!isEditing)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: PinnedTabBarDelegate(
                            background: scheme.surface,
                            child: AppTabBar<_Tab>(
                              selected: _tab,
                              onChanged: _goTab,
                              pager: _pages,
                              tabs: tabs,
                            ),
                          ),
                        ),
                    ],
                    body: LockedInEdit(
                      locked: isEditing,
                      child: AppTabPager<_Tab>(
                        controller: _pages,
                        values: values,
                        selected: _tab,
                        onChanged: _goTab,
                        enabled: !isEditing,
                        builder: (context, t) => _tabBody(l, v, t),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  /// "ดูบิลที่ติดแท็กนี้": the รายการ tab, filtered by [tag].
  void _showTag(BoardTag tag) => setState(() {
    _tagFilter = tag;
    _tab = _Tab.transactions;
  });

  Widget _tabBody(AppLocalizations l, ProjectView v, _Tab t) => switch (t) {
    _Tab.dashboard => ProjectDashboardTab(
      view: v,
      onChanged: _load,
      onAdd: v.canAddTx ? _addTx : null,
      onOpenMembers: _openMembers,
      onInvite: v.isOwner && v.project.status != ProjectStatus.archived
          ? _invite
          : null,
      onShowTag: _showTag,
      onImportTags: v.eventTags.any((t) => !t.mine) ? _importTags : null,
    ),
    _Tab.transactions => ProjectTxListTab(
      view: v,
      onChanged: _load,
      onPatch: _applyPatch,
      onLoadMore: _loadMoreRows,
      onAddTagToMine: (t) => _importTags([t.id]),
      onAdd: v.canAddTx ? _addTx : null,
      tagFilter: _tagFilter,
      focusBillId: _focusBill,
      onFocused: () => _focusBill = null,
      onTagFilterChanged: (tag) => setState(() => _tagFilter = tag),
    ),
    _Tab.resolve => EmptyView(
      icon: AppIcons.settle,
      title: l.projectTabResolve,
      message: l.projectResolveComingSoon,
    ),
  };

  Widget _header(AppLocalizations l, ProjectView v, HeroStyle style) {
    final editing = isEditing;
    final project = v.project;
    return HeaderCard(
      heroStyle: style,
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
      title: HeroNameInput(
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
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: editing,
        hint: l.commonDescription,
        maxLength: TextLimits.description,
        focusNode: _focus[_Field.description],
        onChanged: (t) => _onText(_Field.description, t),
        onEnterEdit: v.isOwner
            ? () => enterEdit(focus: _focus[_Field.description])
            : null,
      ),
      topRow: [
        OptionMenuAnchor<ProjectStatus>(
          selected: project.status,
          onSelected: _changeStatus,
          options: [
            for (final s in ProjectStatus.values)
              SheetOption(value: s, label: projectStatusLabel(l, s)),
          ],
          builder: (context, toggle) => AppChip(
            label: projectStatusLabel(l, project.status),
            dot: true,
            tone: projectStatusTone(project.status),
            selected: true,
            // Owner only; not while editing the info.
            trailing: v.isOwner && !editing
                ? AppChipTrailing.dropdown
                : AppChipTrailing.none,
            onTap: v.isOwner && !editing ? toggle : null,
          ),
        ),
      ],
      footer: editing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                AmountInput(
                  controller: _ctrl[_Field.planned]!,
                  label: l.projectFormPlannedLabel,
                  currencySymbol: context.readUserCurrencySymbol,
                  onChanged: (t) => _onText(_Field.planned, t),
                  validator: (t) {
                    if (t == null || t.trim().isEmpty) return null;
                    final n = AmountInput.parse(t);
                    return (n == null || n <= 0)
                        ? l.projectFormPlannedInvalid
                        : null;
                  },
                ),
                AppText(l.projectFormPlannedHelper, role: AppTextRole.caption),
              ],
            )
          : null,
    );
  }

  /// MY personal tags on the event (private to me; any member sets theirs):
  /// one PUT, its patch applied.
  Widget _tagRow(AppLocalizations l, ProjectView v) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return ChipRow(
      icon: AppIcons.tag,
      chips: [
        for (final t in v.project.tags)
          AppChip(
            label: t.name,
            icon: IconRegistry.get(t.iconCode?.icon, fallback: AppIcons.tag),
            color: EventTagRef(t.name, iconCode: t.iconCode).colorOf(palette),
            selected: true,
            size: ChipSize.chip,
            onTap: _pickMyTags,
          ),
      ],
      onMore: _pickMyTags,
    );
  }

  Future<void> _pickMyTags() async {
    final l = AppLocalizations.of(context)!;
    final v = _view;
    if (v == null) return;
    final picked = await showTagPickerSheet(
      context,
      selected: {for (final t in v.project.tags) t.id},
      title: l.transactionFormTagsLabel,
    );
    if (picked == null || !mounted) return;
    try {
      final p = await context.read<ProjectsCubit>().update(
        widget.id,
        tagIds: picked.toList(),
      );
      _applyPatch(p);
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

  /// คำอธิบาย / โน้ต under the header — both while editing; in view mode
  /// the description only when filled; the note always (empty shows the
  /// long-press hint).
  Widget? _texts(AppLocalizations l, ProjectView v) {
    final editing = isEditing;
    Widget? row(
      _Field f,
      String label,
      String value,
      int max, {
      bool always = false,
    }) {
      if (!editing && !always && value.trim().isEmpty) return null;
      return DetailStacked(
        label: label,
        child: AppInput.inline(
          editing: editing,
          controller: _ctrl[f]!,
          focusNode: _focus[f],
          maxLines: 3,
          maxLength: max,
          viewHint: AppLocalizations.of(context)!.commonLongPressToEdit,
          onEnterEdit: v.isOwner ? () => enterEdit(focus: _focus[f]) : null,
          onChanged: (t) => _onText(f, t),
        ),
      );
    }

    String? day(DateTime? d) =>
        d == null ? null : projectDateRange(context, projectDay(d), null);
    // The dates: pick rows while editing; in view only the ones set.
    Widget? date({required bool start}) {
      final d = start ? working.startDate : working.endDate;
      if (!editing && d == null) return null;
      return DetailRow.pick(
        label: start ? l.eventStartDateLabel : l.eventEndDateLabel,
        icon: AppIcons.date,
        value: day(d),
        emptyText: l.eventDateNone,
        onTap: editing ? () => _pickDate(start: start) : null,
        onLongPress: !editing && v.isOwner ? enterEdit : null,
      );
    }

    final rows = [
      ?date(start: true),
      ?date(start: false),
      ?row(
        _Field.note,
        l.commonNote,
        working.note,
        TextLimits.note,
        always: true,
      ),
    ];
    if (rows.isEmpty) return null;
    return SectionCard(first: true, children: rows);
  }
}

enum _DeleteChoice { notYet, keepTxs, withTxs }

class _InfoDraft {
  const _InfoDraft({
    this.name = '',
    this.description = '',
    this.note = '',
    this.planned = '',
    this.startDate,
    this.endDate,
    this.iconCode,
  });

  factory _InfoDraft.from(Project p) => _InfoDraft(
    name: p.name,
    description: p.description ?? '',
    note: p.note ?? '',
    planned: p.plannedAmount == null
        ? ''
        : AmountInput.format(p.plannedAmount!),
    startDate: DateFormatter.parseDay(p.startDate),
    endDate: DateFormatter.parseDay(p.endDate),
    iconCode: p.iconCode,
  );

  final String name;
  final String description;
  final String note;

  /// Formatted, as in the field; empty = no plan.
  final String planned;
  final DateTime? startDate;
  final DateTime? endDate;
  final IconCode? iconCode;

  _InfoDraft copyWith({
    String? name,
    String? description,
    String? note,
    String? planned,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    IconCode? iconCode,
  }) => _InfoDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    planned: planned ?? this.planned,
    startDate: startDate == null ? this.startDate : startDate(),
    endDate: endDate == null ? this.endDate : endDate(),
    iconCode: iconCode ?? this.iconCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _InfoDraft &&
      other.name == name &&
      other.description == description &&
      other.note == note &&
      other.planned == planned &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(
    name,
    description,
    note,
    planned,
    startDate,
    endDate,
    iconCode,
  );
}
