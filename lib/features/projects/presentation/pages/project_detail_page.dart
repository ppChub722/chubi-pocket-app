import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../../transactions/domain/transaction.dart' show EmbeddedTag;
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../event_errors.dart';
import '../project_board_controller.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/event_tags_manager.dart';
import '../widgets/project_common.dart';
import '../widgets/project_tx_tiles.dart';

enum _Field { name, description, note, planned }

enum _DeleteChoice { notYet, keepTxs, withTxs }

/// `/projects/new` (create), `/projects/:id` (view) and its edit mode — the
/// 0.4.0 event page (reference §5): ONE page, no tabs.
///
/// View: hero card (status ▾ + dates, 🔍 / ✏️, icon + description, the total
/// spent, the planned-budget bar only when one is set, my share / what I'm
/// owed or owe tiles, the income line when there is income) → my tags →
/// member strip (who paid / who owes) → note → the bills (a filter row behind
/// the 🔍, the event-tag filter chips, grouped by day).
///
/// Edit / create is its own form (owner only): status ▾, icon + name +
/// description, the planned budget, my tags, the dates, "จัดการแท็กอีเวนต์",
/// the note, then the end zone (archive / delete). The totals, members and
/// bills are hidden there.
///
/// Every figure is the BE's (`GET /projects/:id/detail`, then each write's
/// patch). One load fills the page; pull-to-refresh runs it again and a
/// failed refresh keeps what is on screen.
class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    this.id,
    this.startEditing = false,
    this.initialBillId,
    super.key,
  });

  /// Null = create a new event.
  final String? id;
  final bool startEditing;

  /// A bill to show (tx detail's "อยู่ในอีเวนต์ … ›"): scrolled to and
  /// highlighted. Null = read `?bill=` from the route.
  final String? initialBillId;

  bool get isCreate => id == null;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with EditModeMixin<ProjectDetailPage, _Draft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _focus = {for (final f in _Field.values) f: FocusNode()};
  final _scroll = ScrollController();

  /// The 🔍 in the hero: shows / hides the bills' filter row.
  final _toolbarOpen = ToolbarToggleState.local();
  final _billSearch = TextEditingController();
  Timer? _debounce;
  ProjectBoardController? _board;

  ProjectView? _view;
  ApiException? _error;

  /// The next board page is in flight / its load failed (stop asking until
  /// the user scrolls again).
  bool _loadingMore = false;
  bool _moreFailed = false;

  /// The bill to scroll to once (`?bill=`).
  String? _focusBill;
  bool _focusRead = false;
  final _focusKey = GlobalKey();
  bool _focusScheduled = false;
  String? _focusDone;

  bool get _isCreate => widget.isCreate;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (_isCreate) {
      initDraft(const _Draft(), editing: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus[_Field.name]!.requestFocus();
      });
    } else {
      initDraft(const _Draft());
      _board = ProjectBoardController(
        repository: context.read<ProjectsRepository>(),
        projectId: widget.id!,
      );
      _load(enterEdit: widget.startEditing);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusRead) return;
    _focusRead = true;
    _focusBill = widget.initialBillId ?? _routeBill();
  }

  /// `?bill=` on this page's route; null outside a router (tests).
  String? _routeBill() {
    try {
      return GoRouterState.of(context).uri.queryParameters['bill'];
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _billSearch.dispose();
    _toolbarOpen.dispose();
    _scroll.dispose();
    _board?.dispose();
    super.dispose();
  }

  // ── Load ────────────────────────────────────────────────────────────

  /// The page's one "open" call (also pull-to-refresh and the reload after
  /// a write whose response can't patch the page yet). A failure keeps what
  /// is on screen and shows a banner; before the first load it is the
  /// error + retry view.
  Future<void> _load({bool enterEdit = false}) async {
    try {
      final repo = context.read<ProjectsRepository>();
      final projects = context.read<ProjectsCubit>();
      final auth = context.read<AuthCubit>().state;
      final user = auth is AuthAuthenticated ? auth.user : null;
      final detail = await repo.detail(widget.id!);
      if (!mounted) return;
      // The list shows this event too: keep it fresh without its own reload.
      projects.patch(detail.project);
      _show(ProjectView.of(detail, currentUserId: user?.id));
      if (enterEdit && _view!.isOwner) this.enterEdit();
    } catch (e, st) {
      // ANY failure (a parse error too) lands in the error banner / view.
      if (mounted) setState(() => _error = ApiException.from(e, st));
    }
  }

  /// Pull-to-refresh: the open call again (and the filtered bills when a
  /// filter is on, since they came from another call).
  Future<void> _refresh() async {
    await _load();
    if (mounted && (_board?.serverFiltered ?? false)) await _board!.reload();
  }

  /// Puts [view] on screen (a load, or a write's response patched in).
  void _show(ProjectView view) {
    final before = _view;
    setState(() {
      _view = view;
      _error = null;
    });
    if (before != null) _board?.viewChanged(before, view);
    resetDraft(_Draft.from(view.project));
  }

  /// A write's [EventPatch]: the page and the events list patched in place
  /// (no reload).
  void _applyPatch(EventPatch p) {
    final v = _view;
    if (v == null || !mounted) return;
    context.read<ProjectsCubit>().patch(p.project);
    context.read<AccountsCubit>().patchBalances(p.accountBalances);
    final next = v.apply(p);
    setState(() => _view = next);
    final board = _board;
    if (board == null) return;
    board.viewChanged(v, next);
    // The tag I was filtering by is gone (deleted in the manager).
    final picked = board.tagId;
    if (picked != null && !p.tags.any((t) => t.id == picked)) {
      board.change(tagId: null);
    } else if (board.serverFiltered && !listEquals(v.eventTags, p.tags)) {
      board.reload();
    }
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => _isCreate;

  @override
  void onDraftRestored() {
    void sync(_Field f, String v) {
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }

    final w = working;
    sync(_Field.name, w.name);
    sync(_Field.description, w.description);
    sync(_Field.note, w.note);
    sync(_Field.planned, w.planned);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.description => working.copyWith(description: v),
    _Field.note => working.copyWith(note: v),
    _Field.planned => working.copyWith(planned: v),
  });

  /// Only the owner edits the event (the BE checks too); create is mine.
  bool get _isOwner => _isCreate || (_view?.isOwner ?? false);

  VoidCallback? _enterOn(FocusNode focus) =>
      _isOwner ? () => enterEdit(focus: focus) : null;

  void _showError(ApiException e) {
    if (!mounted) return;
    showAppSnackBar(
      context,
      eventErrorText(AppLocalizations.of(context)!, e),
      tone: Tone.danger,
    );
  }

  // ── Save / archive / delete ─────────────────────────────────────────

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
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (_isCreate) {
        String? opt(String s) => s.trim().isEmpty ? null : s.trim();
        // One call: plan, dates and my tags included.
        final created = await context.read<ProjectsCubit>().create(
          name: w.name.trim(),
          description: opt(w.description),
          note: opt(w.note),
          startDate: s == null ? null : projectDay(s),
          endDate: e == null ? null : projectDay(e),
          plannedAmount: planned,
          tagIds: w.tagIds.toList(),
          iconCode: w.iconCode,
        );
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        commitSaved(w);
        context.pushReplacement('/projects/${created.id}');
        return;
      }
      final hadPlan = original.planned.trim().isNotEmpty;
      final updated = await context.read<ProjectsCubit>().update(
        widget.id!,
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
        // MY tags on the event, only when I changed them.
        tagIds: setEquals(w.tagIds, original.tagIds) ? null : w.tagIds.toList(),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      // The PUT returns the patch (event + summary): no reload.
      _show(_view!.apply(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _showError(e);
    }
  }

  /// เก็บถาวร: hidden, not counted, read-only; `POST /projects/:id/archive`.
  Future<void> _archive() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.fpEventsArchiveConfirmTitle,
      message: l.fpEventsArchiveConfirmBody,
      confirmLabel: l.projectStatusArchived,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      final p = await context.read<ProjectsCubit>().archive(widget.id!);
      if (!mounted) return;
      showAppSnackBarOn(pageMessenger!, l.fpEventsArchived, tone: Tone.success);
      _applyPatch(p);
      commitSaved(_Draft.from(p.project));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _showError(e);
    }
  }

  /// กู้คืน: an archived event back to active; `POST /projects/:id/restore`.
  Future<void> _restore() async {
    final l = AppLocalizations.of(context)!;
    setSaving(true);
    try {
      final p = await context.read<ProjectsCubit>().restore(widget.id!);
      if (!mounted) return;
      showAppSnackBarOn(pageMessenger!, l.fpEventsRestored, tone: Tone.success);
      _applyPatch(p);
      commitSaved(_Draft.from(p.project));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _showError(e);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final p = _view!.project;
    // ONE call on this button: what the delete removes (the BE's numbers).
    EventDeletePreview? preview;
    try {
      preview = (await context.read<ProjectsRepository>().detail(
        p.id,
        deletePreview: true,
      )).deletePreview;
    } on ApiException catch (e) {
      if (mounted) _showError(e);
      return;
    }
    if (!mounted) return;
    final linked = preview?.linkedTxCount ?? 0;
    final numbers = preview == null
        ? null
        : l.fpM5bEventDeleteNumbers(preview.bills, preview.members);
    // ยังก่อน · ยืนยัน ไม่ลบรายการ · ยืนยันและลบ [x] รายการ (owner
    // 2026-10-13); without linked transactions: ยังก่อน · ยืนยันลบ.
    final choice = await showChoiceDialog<_DeleteChoice>(
      context,
      title: l.projectDeleteTitle(p.name),
      message: linked > 0 ? [?numbers, l.eventDeleteBody].join('\n') : numbers,
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
      _showError(e);
    }
  }

  // ── Edit-mode pickers ───────────────────────────────────────────────

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

  /// Start – end in ONE range picker; both optional (✕ on the chip clears).
  Future<void> _pickRange() async {
    final l = AppLocalizations.of(context)!;
    final w = working;
    final start = w.startDate ?? w.endDate;
    final end = w.endDate ?? w.startDate;
    final r = await showAppDateRangePicker(
      context,
      title: l.fpEventsDatesLabel,
      initial: start == null ? null : DateTimeRange(start: start, end: end!),
    );
    if (!mounted || r == null) return;
    applyChange(w.copyWith(startDate: () => r.start, endDate: () => r.end));
  }

  void _clearRange() =>
      applyChange(working.copyWith(startDate: () => null, endDate: () => null));

  /// MY personal tags on the event (private to me; any member sets theirs).
  /// Edit / create: the draft's, saved with the form. View: one PUT right
  /// away, its patch applied.
  Future<void> _pickMyTags() async {
    final l = AppLocalizations.of(context)!;
    final editing = isEditing;
    final current = editing
        ? working.tagIds
        : {for (final t in _view?.project.tags ?? const <EmbeddedTag>[]) t.id};
    final picked = await showTagPickerSheet(
      context,
      selected: current,
      title: l.transactionFormTagsLabel,
    );
    if (picked == null || !mounted) return;
    if (editing) {
      applyChange(working.copyWith(tagIds: picked));
      return;
    }
    try {
      final p = await context.read<ProjectsCubit>().update(
        widget.id!,
        tagIds: picked.toList(),
      );
      _applyPatch(p);
    } on ApiException catch (e) {
      _showError(e);
    }
  }

  /// "จัดการแท็กอีเวนต์": the shared bill tags, every member may edit.
  Future<void> _manageTags() async {
    final v = _view;
    if (v == null) return;
    final l = AppLocalizations.of(context)!;
    final tags = context.read<TagsCubit>();
    await showEventTagsManager(
      context,
      projectId: widget.id!,
      tags: v.eventTags,
      onPatch: _applyPatch,
      onImported: (r) {
        // My personal set may have grown: the pickers need to see it.
        if (r.created.isNotEmpty) unawaited(tags.load());
        if (mounted) {
          showAppSnackBar(
            context,
            l.eventTagsImported(r.created.length),
            tone: Tone.success,
          );
        }
        if (mounted && _view != null) {
          setState(() => _view = _view!.withEventTags(r.tags));
        }
      },
    );
  }

  // ── Status / members / bills ────────────────────────────────────────

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
        widget.id!,
        status: next,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.projectStatusChanged(projectStatusLabel(l, next)),
      );
      _show(_view!.apply(updated));
    } on ApiException catch (e) {
      _showError(e);
    }
  }

  Future<void> _openMembers() async {
    await context.push('/projects/${widget.id}/members');
    if (mounted) await _load();
  }

  Future<void> _invite() async {
    final l = AppLocalizations.of(context)!;
    final added = await showAddMemberSheet(context, projectId: widget.id!);
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

  void _onBillSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _board?.change(query: v.trim());
    });
  }

  /// Near the end of the page: the next page of bills.
  void _onScroll() {
    if (!_scroll.hasClients || _loadingMore || _moreFailed) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent - pos.pixels < 600) _loadMoreRows();
  }

  Future<void> _loadMoreRows() async {
    final v = _view;
    final board = _board;
    if (v == null || board == null || _loadingMore) return;
    final filtered = board.rows != null;
    if (filtered ? !board.hasMore : !v.hasMoreRows) return;
    _loadingMore = true;
    if (mounted) setState(() {});
    try {
      if (filtered) {
        await board.loadMore();
      } else {
        final rows = await context.read<ProjectsRepository>().listTransactions(
          widget.id!,
          page: v.page + 1,
          perPage: 50,
        );
        if (!mounted || !identical(_view, v)) return;
        setState(() => _view = v.withMore(rows, page: v.page + 1));
      }
    } catch (_) {
      _moreFailed = true;
      if (mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.uiLoadMoreFailed,
          tone: Tone.danger,
        );
      }
    } finally {
      _loadingMore = false;
      if (mounted) setState(() {});
    }
  }

  void _scheduleFocus() {
    if (_focusScheduled || _focusDone == _focusBill) return;
    _focusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScheduled = false;
      final target = _focusKey.currentContext;
      if (!mounted || target == null) return;
      _focusDone = _focusBill;
      Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppDurations.chrome,
      );
    });
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = _view;
    if (v == null && !_isCreate) {
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
    final page = editScope(
      Scaffold(
        appBar: AppTopBar(
          // The saved name in both modes (titles never change).
          title: _isCreate ? l.projectNewTitle : v!.project.name,
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
              final barInset = MediaQuery.paddingOf(context).top;
              final bottom =
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom;
              if (isEditing || _isCreate) {
                return _editBody(l, v, barInset, bottom);
              }
              return ListenableBuilder(
                listenable: _board!,
                builder: (context, _) => _viewBody(l, v!, barInset, bottom),
              );
            },
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
    return page;
  }

  // ── View mode ───────────────────────────────────────────────────────

  Widget _viewBody(
    AppLocalizations l,
    ProjectView v,
    double barInset,
    double bottom,
  ) {
    final p = v.project;
    // A refresh that failed keeps the data on screen with a banner.
    final banner = _error == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              barInset + AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: AppMessage(
              message: l.fpEventsLoadFailed,
              tone: Tone.warning,
              actions: [
                AppMessageAction(label: l.commonRetry, onPressed: _load),
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?banner,
        Expanded(
          child: DetailLayout(
            controller: _scroll,
            onRefresh: _refresh,
            physics: const AlwaysScrollableScrollPhysics(),
            topInset: (banner == null ? barInset : 0) + AppSpacing.lg,
            bottomInset: bottom,
            hero: _viewHero(l, v),
            tags: _tagRow(l, p.tags.map(_myTagRef).toList(), editing: false),
            people: _people(l, v),
            note: NoteSection(
              label: l.commonNote,
              editing: false,
              text: p.note,
              hint: l.commonLongPressToEdit,
              onLongPress: _enterOn(_focus[_Field.note]!),
            ),
            records: _records(l, v),
            metaLines: detailMetaLines(
              context,
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
            ),
          ),
        ),
      ],
    );
  }

  EventTagRef _myTagRef(EmbeddedTag t) =>
      EventTagRef(t.name, iconCode: t.iconCode);

  /// "แท็กของฉัน": my personal tags on the event, the same row in view and
  /// edit; ＋ opens the existing tag picker.
  Widget _tagRow(
    AppLocalizations l,
    List<EventTagRef> tags, {
    required bool editing,
  }) {
    final canPick = editing || (_view?.project.myMemberId != null);
    return TagRow(
      label: l.fpEventsMyTags,
      tags: [for (final t in tags) t.chip(context, onTap: _pickMyTags)],
      onAdd: canPick ? _pickMyTags : null,
      addLabel: editing ? l.fpEventsTagPick : '',
    );
  }

  Widget _statusChip(AppLocalizations l, ProjectStatus status) {
    final canChange = _isOwner && !_isCreate;
    return OptionMenuAnchor<ProjectStatus>(
      selected: status,
      onSelected: _changeStatus,
      options: [
        for (final s in ProjectStatus.values)
          SheetOption(value: s, label: projectStatusLabel(l, s), submits: true),
      ],
      builder: (context, toggle) => AppChip(
        label: projectStatusLabel(l, status),
        dot: true,
        tone: projectStatusTone(status),
        selected: true,
        trailing: canChange ? AppChipTrailing.dropdown : AppChipTrailing.none,
        onTap: canChange ? toggle : null,
      ),
    );
  }

  Widget _viewHero(AppLocalizations l, ProjectView v) {
    final p = v.project;
    final board = _board!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = p.iconCode.tintFor(palette);
    final range = projectDateRange(context, p.startDate, p.endDate);
    final planned = p.plannedAmount;
    final owe = p.myPayable > 0;
    return HeroCard(
      style: HeroStyle.tinted(color: tint, glyph: AppIcons.project),
      chips: [
        _statusChip(l, p.status),
        if (range != null) AppChip(label: range, icon: AppIcons.date),
      ],
      search: ToolbarToggleButton(
        state: _toolbarOpen,
        filtered: board.filtered,
        tooltip: l.commonSearch,
      ),
      onEdit: v.isOwner ? enterEdit : null,
      icon: IconDisplay(type: IconType.project, size: 40, iconCode: p.iconCode),
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: false,
        hint: l.commonDescription,
        onEnterEdit: _enterOn(_focus[_Field.description]!),
      ),
      number: HeroNumber(
        label: l.fpEventsSpentTotal,
        value: MoneyText(p.totalExpense),
        color: tint,
      ),
      bar: planned == null ? null : _budgetBar(l, v, planned, tint),
      tiles: [
        // "ส่วนของฉัน" filters the bills to the ones I'm in (the BE's
        // `mine`); tap again clears.
        SummaryTileView(
          tile: SummaryTile(
            label: l.fpEventsMyShare,
            value: moneyString(context, p.myShare),
            selected: board.mine,
            onTap: () => board.change(mine: !board.mine),
          ),
        ),
        SummaryTileView(
          tile: SummaryTile(
            label: owe ? l.fpEventsOwe : l.fpEventsOwed,
            value: moneyString(context, owe ? p.myPayable : p.myReceivable),
            tone: owe
                ? SummaryTileTone.red
                : (p.myReceivable > 0
                      ? SummaryTileTone.green
                      : SummaryTileTone.neutral),
          ),
        ),
      ],
      embedded: p.totalIncome > 0
          ? HeroValueLine(
              label: l.fpEventsIncomeTotal,
              value: MoneyText(p.totalIncome, tone: MoneyTone.income),
            )
          : null,
    );
  }

  /// Row D, only when a budget is set: used of planned, what is left (or
  /// over). The numbers are the BE's; the fraction is just the bar's fill.
  Widget _budgetBar(
    AppLocalizations l,
    ProjectView v,
    double planned,
    Color tint,
  ) {
    final p = v.project;
    final spent = v.summary?.spentNet ?? p.totalExpense;
    final left = p.remaining ?? v.summary?.remaining ?? 0;
    return HeroBar(
      value: planned > 0 ? spent / planned : 0,
      color: tint,
      left: l.fpEventsBudgetUsed(
        moneyString(context, spent),
        moneyString(context, planned),
      ),
      right: left < 0
          ? l.fpEventsBudgetOver(moneyString(context, left.abs()))
          : l.fpEventsBudgetLeft(moneyString(context, left)),
    );
  }

  /// "สมาชิก · ใครจ่าย / ใครค้าง": one card per member (what they paid, and
  /// what they are owed / owe), ＋ เชิญ at the end.
  Widget _people(AppLocalizations l, ProjectView v) {
    final positions = {
      for (final pos in v.summary?.positions ?? const <ProjectMemberPosition>[])
        pos.memberId: pos,
    };
    final order = [for (final pos in positions.values) pos.memberId];
    final members = [...v.currentMembers]
      ..sort((a, b) {
        int rank(ProjectMember m) {
          final i = order.indexOf(m.id);
          return i < 0 ? order.length : i;
        }

        return rank(a).compareTo(rank(b));
      });
    PeopleStripMember card(ProjectMember m) {
      final pos = positions[m.id];
      final owed = (pos?.receivable ?? 0) > 0;
      final owe = (pos?.payable ?? 0) > 0;
      return PeopleStripMember(
        avatar: ProjectMemberAvatar(
          name: m.displayName,
          iconCode: m.iconCode,
          level: projectMemberLevel(m),
          size: 36,
        ),
        name: m.displayName,
        lead: l.fpEventsMemberPaid(moneyString(context, pos?.paid ?? 0)),
        caption: owed
            ? l.fpEventsMemberOwed(moneyString(context, pos!.receivable))
            : (owe
                  ? l.fpEventsMemberOwe(moneyString(context, pos!.payable))
                  : null),
        tone: owed
            ? PeopleTone.positive
            : (owe ? PeopleTone.negative : PeopleTone.neutral),
      );
    }

    return PeopleStrip(
      title: l.fpEventsMembersTitle,
      actionLabel: l.fpEventsManage,
      onAction: _openMembers,
      members: [for (final m in members) card(m)],
      inviteLabel: l.fpEventsInvite,
      onInvite: v.isOwner && v.project.status != ProjectStatus.archived
          ? _invite
          : null,
      onMemberTap: (_) => _openMembers(),
    );
  }

  /// The bills: the filter row behind the hero's 🔍, the event-tag chips,
  /// then the bills grouped by day.
  Widget _records(AppLocalizations l, ProjectView v) {
    final board = _board!;
    final trees = board.trees(v);
    final byDate = board.sort != BoardSort.amount;
    final payers = v.currentMembers;
    final sortLabels = {
      BoardSort.newest: l.fpEventsSortRecent,
      BoardSort.oldest: l.fpEventsSortOldest,
      BoardSort.amount: l.fpEventsSortAmount,
    };
    final palette = Theme.of(context).extension<AppColors>()!;
    ProjectTxTreeTile tile(ProjectTxTree t) {
      final focused = t.parent.id == _focusBill;
      return ProjectTxTreeTile(
        key: focused && _focusDone != _focusBill ? _focusKey : null,
        tree: t,
        highlighted: focused,
        view: v,
        onChanged: _load,
        onPatch: _applyPatch,
        onShowTag: (tag) => board.change(tagId: tag.id),
        onAddTagToMine: (tag) => _importOne(tag.id),
      );
    }

    // Groups of consecutive bills on the same day (a sort by amount is one
    // flat group).
    final groups = <(String?, List<ProjectTxTree>)>[];
    for (final t in trees) {
      final day = byDate ? t.parent.date : null;
      if (groups.isEmpty || groups.last.$1 != day) {
        groups.add((day, [t]));
      } else {
        groups.last.$2.add(t);
      }
    }
    if (_focusBill != null && _focusDone != _focusBill) _scheduleFocus();

    return DetailRecords(
      children: [
        ListToolbar(
          collapse: _toolbarOpen,
          sidePadding: 0,
          searchController: _billSearch,
          searchHint: l.fpEventsBillsSearchHint,
          onSearchChanged: _onBillSearch,
          chips: [
            OptionMenuAnchor<String?>(
              selected: board.payerId,
              onSelected: (id) => board.change(payerId: id),
              options: [
                SheetOption<String?>(value: null, label: l.fpEventsPayerAll),
                for (final m in payers)
                  SheetOption<String?>(
                    value: m.id,
                    label: m.displayName,
                    leading: memberAvatar(m, size: 28),
                  ),
              ],
              builder: (context, toggle) => AppChip(
                label: board.payerId == null
                    ? l.fpEventsPayerFilter
                    : '${l.fpEventsPayerFilter}: '
                          '${v.member(board.payerId!).displayName}',
                selected: board.payerId != null,
                trailing: AppChipTrailing.dropdown,
                onTap: toggle,
              ),
            ),
          ],
          trailing: OptionMenuAnchor<BoardSort>(
            selected: board.sort,
            onSelected: (s) => board.change(sort: s),
            options: [
              for (final e in sortLabels.entries)
                SheetOption(value: e.key, label: e.value),
            ],
            builder: (context, toggle) => AppChip(
              label: sortLabels[board.sort]!,
              icon: AppIcons.sort,
              trailing: AppChipTrailing.dropdown,
              onTap: toggle,
            ),
          ),
        ),
        if (v.eventTags.isNotEmpty)
          ChipRow(
            label: l.fpEventsTagsFilterLabel,
            chips: [
              AppChip(
                label: l.fpEventsTagAll,
                selected: board.tagId == null,
                onTap: () => board.change(tagId: null),
              ),
              for (final t in v.eventTags)
                AppChip(
                  label: t.name,
                  icon: IconRegistry.get(
                    t.iconCode?.icon,
                    fallback: AppIcons.tag,
                  ),
                  color: EventTagRef(
                    t.name,
                    iconCode: t.iconCode,
                  ).colorOf(palette),
                  selected: board.tagId == t.id,
                  onTap: () =>
                      board.change(tagId: board.tagId == t.id ? null : t.id),
                ),
            ],
          ),
        if (board.error != null)
          AppMessage(
            message: l.fpEventsLoadFailed,
            tone: Tone.warning,
            actions: [
              AppMessageAction(label: l.commonRetry, onPressed: board.reload),
            ],
          ),
        if (board.loading && board.rows == null)
          const ListRowSkeleton()
        else if (trees.isEmpty)
          EmptyView.compact(
            message: board.filtered ? l.projectTxNoMatch : l.projectTxEmpty,
          ),
        for (final (day, list) in groups)
          SectionCard(
            title: day == null ? null : projectTxDateLabel(context, day),
            children: [for (final t in list) tile(t)],
          ),
        if (v.canAddTx)
          AddTile(
            label: l.projectAddTransaction,
            variant: AddTileVariant.row,
            onTap: _addTx,
          ),
        if (_loadingMore) const ListRowSkeleton(),
      ],
    );
  }

  /// "+ เพิ่มเข้าแท็กของฉัน" on a bill's tag: one call, the tags come back
  /// with `mine` updated.
  Future<void> _importOne(String tagId) async {
    final l = AppLocalizations.of(context)!;
    final tags = context.read<TagsCubit>();
    try {
      final r = await context.read<ProjectsRepository>().importTags(
        widget.id!,
        tagIds: [tagId],
      );
      if (!mounted) return;
      setState(() => _view = _view?.withEventTags(r.tags));
      if (r.created.isNotEmpty) unawaited(tags.load());
      showAppSnackBar(
        context,
        l.eventTagsImported(r.created.length),
        tone: Tone.success,
      );
    } on ApiException catch (e) {
      _showError(e);
    }
  }

  // ── Edit / create mode ──────────────────────────────────────────────

  /// MY tags as the draft has them: a tag from my set, else the one the
  /// event already carried.
  List<EventTagRef> _draftTags(Set<String> ids) {
    final mine = context.read<TagsCubit>();
    final known = {
      for (final t in _view?.project.tags ?? const <EmbeddedTag>[]) t.id: t,
    };
    return [
      for (final id in ids)
        if (mine.byId(id) case final t?)
          EventTagRef(t.name, iconCode: t.iconCode)
        else if (known[id] case final t?)
          _myTagRef(t),
    ];
  }

  /// Edit mode is its own form: only what can be edited (the totals, the
  /// members and the bills are hidden — never greyed).
  Widget _editBody(
    AppLocalizations l,
    ProjectView? v,
    double barInset,
    double bottom,
  ) {
    final w = working;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = w.iconCode.tintFor(palette);
    final p = v?.project;
    final range = w.startDate == null && w.endDate == null
        ? null
        : projectDateRange(
            context,
            projectDay(w.startDate ?? w.endDate!),
            projectDay(w.endDate ?? w.startDate!),
          );
    final archived = p?.status == ProjectStatus.archived;
    return DetailLayout(
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      hero: HeroCard(
        style: HeroStyle.tinted(color: tint, glyph: AppIcons.project),
        editing: true,
        chips: [if (p != null) _statusChip(l, p.status)],
        icon: EditableCircle(
          size: 44,
          onTap: _openIconMaker,
          child: IconDisplay(
            type: IconType.project,
            size: 44,
            iconCode: w.iconCode,
          ),
        ),
        name: HeroNameInput(
          editing: true,
          controller: _ctrl[_Field.name]!,
          focusNode: _focus[_Field.name],
          hint: l.commonName,
          maxLength: TextLimits.name,
          onChanged: (t) => _onText(_Field.name, t),
          validator: (t) =>
              (t?.trim().isEmpty ?? true) ? l.projectNameRequired : null,
        ),
        description: HeroDescription(
          controller: _ctrl[_Field.description]!,
          editing: true,
          hint: l.commonDescription,
          maxLength: TextLimits.description,
          focusNode: _focus[_Field.description],
          onChanged: (t) => _onText(_Field.description, t),
        ),
        amountField: HeroAmountField(
          controller: _ctrl[_Field.planned]!,
          label: l.fpEventsBudgetLabel,
          helper: l.fpEventsBudgetHelper,
          accent: tint,
          onChanged: (t) => _onText(_Field.planned, t),
          validator: (t) {
            if (t == null || t.trim().isEmpty) return null;
            final n = AmountInput.parse(t);
            return (n == null || n <= 0) ? l.projectFormPlannedInvalid : null;
          },
        ),
      ),
      tags: _tagRow(l, _draftTags(w.tagIds), editing: true),
      info: InfoBox(
        rows: [
          InfoRow(
            label: l.fpEventsDatesLabel,
            valueChip: range == null
                ? null
                : AppChip(
                    label: range,
                    icon: AppIcons.date,
                    selected: true,
                    trailing: AppChipTrailing.remove,
                    onTap: _pickRange,
                    onRemove: _clearRange,
                  ),
            value: range == null ? l.eventDateNone : null,
            showChevron: range == null,
            onTap: _pickRange,
          ),
        ],
      ),
      // The shared bill tags live on the event: only once it exists.
      settings: v == null
          ? null
          : SettingsSection(
              title: l.settingsTitle,
              description: l.fpEventsSettingsDesc,
              children: [
                SettingSummaryRow(
                  label: l.fpEventsManageTags,
                  summary: l.fpEventsTagsCount(v.eventTags.length),
                  onTap: _manageTags,
                ),
              ],
            ),
      note: NoteSection(
        label: l.commonNote,
        editing: true,
        controller: _ctrl[_Field.note]!,
        maxLength: TextLimits.note,
        editField: DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: true,
            controller: _ctrl[_Field.note]!,
            focusNode: _focus[_Field.note],
            maxLines: 3,
            maxLength: TextLimits.note,
            onChanged: (t) => _onText(_Field.note, t),
          ),
        ),
      ),
      endZone: v == null
          ? null
          : EndZone(
              actions: [
                if (archived)
                  EndZoneAction(
                    kind: EndZoneKind.close,
                    label: l.fpEventsRestore,
                    consequence: l.fpEventsRestoreConsequence,
                    onTap: isSaving ? null : _restore,
                  )
                else
                  EndZoneAction(
                    kind: EndZoneKind.archive,
                    label: l.projectStatusArchived,
                    consequence: l.fpEventsArchiveConsequence,
                    onTap: isSaving ? null : _archive,
                  ),
                EndZoneAction(
                  kind: EndZoneKind.delete,
                  label: l.projectDeleteThis,
                  consequence: l.fpEventsDeleteConsequence,
                  onTap: isSaving ? null : _delete,
                ),
              ],
            ),
      metaLines: p == null
          ? const []
          : detailMetaLines(
              context,
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
            ),
    );
  }
}

/// The edit form's fields (immutable: the mixin diffs it for dirty / undo).
class _Draft {
  const _Draft({
    this.name = '',
    this.description = '',
    this.note = '',
    this.planned = '',
    this.startDate,
    this.endDate,
    this.iconCode,
    this.tagIds = const {},
  });

  factory _Draft.from(Project p) => _Draft(
    name: p.name,
    description: p.description ?? '',
    note: p.note ?? '',
    planned: p.plannedAmount == null
        ? ''
        : AmountInput.format(p.plannedAmount!),
    startDate: DateFormatter.parseDay(p.startDate),
    endDate: DateFormatter.parseDay(p.endDate),
    iconCode: p.iconCode,
    tagIds: {for (final t in p.tags) t.id},
  );

  final String name;
  final String description;
  final String note;

  /// Formatted, as in the field; empty = no plan.
  final String planned;
  final DateTime? startDate;
  final DateTime? endDate;
  final IconCode? iconCode;

  /// MY personal tags on the event.
  final Set<String> tagIds;

  _Draft copyWith({
    String? name,
    String? description,
    String? note,
    String? planned,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    IconCode? iconCode,
    Set<String>? tagIds,
  }) => _Draft(
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    planned: planned ?? this.planned,
    startDate: startDate == null ? this.startDate : startDate(),
    endDate: endDate == null ? this.endDate : endDate(),
    iconCode: iconCode ?? this.iconCode,
    tagIds: tagIds ?? this.tagIds,
  );

  @override
  bool operator ==(Object other) =>
      other is _Draft &&
      other.name == name &&
      other.description == description &&
      other.note == note &&
      other.planned == planned &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.iconCode == iconCode &&
      setEquals(other.tagIds, tagIds);

  @override
  int get hashCode => Object.hash(
    name,
    description,
    note,
    planned,
    startDate,
    endDate,
    iconCode,
    Object.hashAllUnordered(tagIds),
  );
}
