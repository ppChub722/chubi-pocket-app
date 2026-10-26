import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../../transactions/domain/transaction.dart' show EmbeddedTag;
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../event_delete_choice.dart';
import '../event_errors.dart';
import '../project_board_controller.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/event_bill_sheet.dart';
import '../widgets/event_tags_manager.dart';
import '../widgets/project_common.dart';
import '../widgets/project_tx_tiles.dart';

enum _Field { name, description, note, planned }

enum _Tab { bills, summary }

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    this.id,
    this.startEditing = false,
    this.initialBillId,
    super.key,
  });

  final String? id;
  final bool startEditing;

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

  _Tab _tab = _Tab.bills;

  /// Who pays whom (the สรุป tab); null = not loaded since the last change.
  EventSettle? _settle;
  bool _settleLoading = false;
  ApiException? _settleError;

  final _toolbarOpen = AppListToolbarState.local();
  final _billSearch = TextEditingController();
  Timer? _debounce;
  ProjectBoardController? _board;

  ProjectView? _view;
  ApiException? _error;

  bool _loadingMore = false;
  bool _moreFailed = false;

  String? _focusBill;
  bool _focusRead = false;
  final _focusKey = GlobalKey();
  bool _focusScheduled = false;
  String? _focusDone;

  bool get _isCreate => widget.isCreate;

  @override
  void initState() {
    super.initState();
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
    _board?.dispose();
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
      final detail = await repo.detail(widget.id!);
      if (!mounted) return;
      // The list shows this event too: keep it fresh without its own reload.
      projects.patch(detail.project);
      _show(ProjectView.of(detail, currentUserId: user?.id));
      if (enterEdit && _view!.isOwner) this.enterEdit();
    } catch (e, st) {
      if (mounted) setState(() => _error = ApiException.from(e, st));
    }
  }

  Future<void> _refresh() async {
    await _load();
    if (mounted && (_board?.serverFiltered ?? false)) await _board!.reload();
  }

  void _show(ProjectView view) {
    final before = _view;
    setState(() {
      _view = view;
      _error = null;
    });
    if (before != null) _board?.viewChanged(before, view);
    resetDraft(_Draft.from(view.project));
  }

  void _applyPatch(EventPatch p) {
    final v = _view;
    if (v == null || !mounted) return;
    context.read<ProjectsCubit>().patch(p.project);
    context.read<AccountsCubit>().patchBalances(p.accountBalances);
    final next = v.apply(p);
    setState(() {
      _view = next;
      _settle = null;
    });
    if (_tab == _Tab.summary) unawaited(_loadSettle());
    final board = _board;
    if (board == null) return;
    board.viewChanged(v, next);
    final picked = board.tagId;
    if (picked != null && !p.tags.any((t) => t.id == picked)) {
      board.change(tagId: null);
    } else if (board.serverFiltered && !listEquals(v.eventTags, p.tags)) {
      board.reload();
    }
  }

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
        description: w.description.trim(),
        note: w.note.trim(),
        startDate: s == null ? null : projectDay(s),
        endDate: e == null ? null : projectDay(e),
        clearStartDate: s == null && original.startDate != null,
        clearEndDate: e == null && original.endDate != null,
        iconCode: w.iconCode,
        plannedAmount: planned,
        clearPlannedAmount: planned == null && hadPlan,
        tagIds: setEquals(w.tagIds, original.tagIds) ? null : w.tagIds.toList(),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      _show(_view!.apply(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      _showError(e);
    }
  }

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
    final choice = await showChoiceDialog<DeleteChoice>(
      context,
      title: l.projectDeleteTitle(p.name),
      message: linked > 0 ? [?numbers, l.eventDeleteBody].join('\n') : numbers,
      choices: [
        DialogChoice(
          value: DeleteChoice.notYet,
          label: l.eventDeleteNotYet,
          variant: AppButtonVariant.primary,
        ),
        if (linked > 0) ...[
          DialogChoice(
            value: DeleteChoice.keepTxs,
            label: l.eventDeleteKeepTxs,
          ),
          DialogChoice(
            value: DeleteChoice.withTxs,
            label: l.eventDeleteWithTxs(linked),
            variant: AppButtonVariant.destructive,
          ),
        ] else
          DialogChoice(
            value: DeleteChoice.keepTxs,
            label: l.eventDeleteConfirm,
            variant: AppButtonVariant.destructive,
          ),
      ],
    );
    final withTxs = deleteLinkedTxsOf(choice);
    if (withTxs == null || !mounted) return;
    setSaving(true);
    try {
      final accounts = context.read<AccountsCubit>();
      final balances = await context.read<ProjectsCubit>().delete(
        p.id,
        deleteLinkedTxs: withTxs,
      );
      accounts.patchBalances(balances);
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

  Future<void> _pickRange() async {
    final l = AppLocalizations.of(context)!;
    final w = working;
    final start = w.startDate ?? w.endDate;
    final end = w.endDate ?? w.startDate;
    final r = await AppDatePicker.range(
      context,
      title: l.fpEventsDatesLabel,
      initial: start == null ? null : DateTimeRange(start: start, end: end!),
    );
    if (!mounted || r == null) return;
    applyChange(w.copyWith(startDate: () => r.start, endDate: () => r.end));
  }

  void _clearRange() =>
      applyChange(working.copyWith(startDate: () => null, endDate: () => null));

  Future<void> _pickMyTags() async {
    final l = AppLocalizations.of(context)!;
    final editing = isEditing;
    final current = editing
        ? working.tagIds
        : {for (final t in _view?.project.tags ?? const <EmbeddedTag>[]) t.id};
    final r = await TagPicker.many(
      context,
      selected: current,
      title: l.transactionFormTagsLabel,
    );
    if (r == null || !mounted) return;
    final picked = r.ids;
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

  Future<void> _addTx() async {
    final view = _view;
    if (view == null) return;
    await showEventBillSheet(context, view: view, onPatch: _applyPatch);
  }

  Future<void> _loadSettle() async {
    if (_settleLoading || widget.id == null) return;
    setState(() {
      _settleLoading = true;
      _settleError = null;
    });
    try {
      final s = await context.read<ProjectsRepository>().settle(widget.id!);
      if (mounted) setState(() => _settle = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _settleError = e);
    } finally {
      if (mounted) setState(() => _settleLoading = false);
    }
  }

  void _onTab(_Tab t) {
    setState(() => _tab = t);
    if (t == _Tab.summary && _settle == null) unawaited(_loadSettle());
  }

  /// สรุป: ยอดแต่ละคน (everyone, me first), then จัดการ: the fewest
  /// transfers. A line with me in it can be recorded as my debt; a tap
  /// records the payback in the event (anyone may).
  Widget _summaryTab(AppLocalizations l, ProjectView v) {
    final s = _settle;
    final lines = s?.simplified ?? const <SettleLine>[];
    Widget line(SettleLine x) => SettleRow(
      key: ValueKey('settle:${x.from.id}:${x.to.id}'),
      fromAvatar: ProjectMemberAvatar(
        name: x.from.name,
        iconCode: x.from.iconCode,
        size: 32,
      ),
      fromName: x.from.name,
      toAvatar: ProjectMemberAvatar(
        name: x.to.name,
        iconCode: x.to.iconCode,
        size: 20,
      ),
      toName: x.to.name,
      amount: MoneyText(x.amount),
      mine: x.mine,
      recordedLabel: x.recorded ? l.evbSettleRecorded : null,
      onRecord: x.mine ? () => _recordSettle(l, v, x) : null,
      recordTooltip: l.evbSettleRecord,
      onTap: v.canAddTx
          ? () => showEventBillSheet(
              context,
              view: v,
              kind: EventEntryKind.payback,
              from: x.from.id,
              to: x.to.id,
              amount: x.amount,
              onPatch: _applyPatch,
            )
          : null,
    );
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: false,
      onRetry: () async {
        await _refresh();
        await _loadSettle();
      },
      topInset: AppSpacing.sm,
      empty: EmptyView.compact(message: l.evbAllSettled),
      children: [
        _nets(l, v),
        SectionCard(
          title: l.evbSettleSection,
          children: [
            if (s == null && _settleError != null)
              ErrorView(error: _settleError!, onRetry: _loadSettle)
            else if (s == null)
              const ListRowSkeleton()
            else if (lines.isEmpty)
              EmptyView.compact(message: l.evbAllSettled)
            else ...[
              for (final x in lines) line(x),
              AppText(l.evbSettleHint, role: AppTextRole.caption),
            ],
          ],
        ),
      ],
    );
  }

  /// ยอดแต่ละคน: avatar and name, what they paid, what they get back / owe.
  Widget _nets(AppLocalizations l, ProjectView v) {
    final meId = v.me?.id;
    final rows = [...?v.summary?.positions]
      ..sort(
        (a, b) => (b.memberId == meId ? 1 : 0) - (a.memberId == meId ? 1 : 0),
      );
    return SectionCard(
      title: l.evbNets,
      children: [
        for (final p in rows)
          AppListRow(
            key: ValueKey('net:${p.memberId}'),
            leading: ProjectMemberAvatar(
              name: p.displayName,
              iconCode: p.iconCode,
              size: 32,
            ),
            title: p.displayName,
            line2: ListRowLine(
              parts: [l.fpEventsMemberPaid(moneyString(context, p.paid))],
            ),
            trailing: p.receivable > 0
                ? ListRowTrailing.text(
                    l.fpEventsMemberOwed(moneyString(context, p.receivable)),
                    tone: Tone.success,
                  )
                : p.payable > 0
                ? ListRowTrailing.text(
                    l.fpEventsMemberOwe(moneyString(context, p.payable)),
                    tone: Tone.danger,
                  )
                : null,
          ),
      ],
    );
  }

  /// จดเป็นหนี้: my side of a จัดการ line into my debts, after a confirm.
  Future<void> _recordSettle(
    AppLocalizations l,
    ProjectView v,
    SettleLine x,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: l.evbSettleRecord,
      message: l.evbSettleRecordBody(
        x.from.name,
        x.to.name,
        moneyString(context, x.amount),
      ),
      confirmLabel: l.evbSettleRecord,
    );
    if (!ok || !mounted) return;
    final other = x.from.isMe ? x.to : x.from;
    String? contactId;
    for (final m in v.members) {
      if (m.id == other.id) contactId = m.contactId;
    }
    try {
      await context.read<PersonalDebtsRepository>().createEntry(
        contactId != null
            ? debtPersonKey(contactId: contactId)
            : debtPersonKey(name: other.name),
        direction: x.from.isMe
            ? DebtEntryDirection.received
            : DebtEntryDirection.paid,
        amount: x.amount,
        personName: other.name,
        eventId: v.project.id,
      );
      if (!mounted) return;
      showAppSnackBar(context, l.quickSaved, tone: Tone.success);
      await _loadSettle();
    } on ApiException catch (e) {
      _showError(e);
    }
  }

  Widget _billsTab(AppLocalizations l, ProjectView v) {
    final board = _board!;
    final more = board.rows != null ? board.hasMore : v.hasMoreRows;
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: false,
      onRetry: _refresh,
      topInset: 0,
      hasMore: more && !_moreFailed,
      loadingMore: _loadingMore,
      onLoadMore: _loadMoreRows,
      empty: EmptyView.compact(message: l.projectTxEmpty),
      children: [_records(l, v)],
    );
  }

  void _onBillSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _board?.change(query: v.trim());
    });
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = _view;
    if (v == null && !_isCreate) {
      return Scaffold(
        appBar: AppTopBar(title: l.navProjects, showBack: true),
        extendBodyBehindAppBar: true,
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
    if (v == null || isEditing || _isCreate || !v.canAddTx) return page;
    // The centre capsule is this event's "เพิ่มบิล" (the event's colour).
    return QuickCreatePresetScope(
      preset: QuickCreatePreset.custom(
        word: l.evbNewBill,
        color: v.project.iconCode.tintFor(
          Theme.of(context).extension<AppColors>()!,
        ),
        onCreate: _addTx,
      ),
      child: page,
    );
  }

  Widget _viewBody(
    AppLocalizations l,
    ProjectView v,
    double barInset,
    double bottom,
  ) {
    final p = v.project;
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
    return TabbedDetailBody<_Tab>(
      hero: _viewHero(l, v),
      belowHero: [
        ?banner,
        _tagRow(l, p.tags.map(_myTagRef).toList(), editing: false),
        NoteSection(
          label: l.commonNote,
          editing: false,
          text: p.note,
          hint: l.commonLongPressToEdit,
          onLongPress: _enterOn(_focus[_Field.note]!),
        ),
        _people(l, v),
      ],
      tabs: [
        AppTab(value: _Tab.bills, label: l.evbTabBills, icon: AppIcons.receipt),
        AppTab(
          value: _Tab.summary,
          label: l.evbTabSummary,
          icon: AppIcons.project,
        ),
      ],
      selected: _tab,
      onChanged: _onTab,
      tabBuilder: (context, t) => switch (t) {
        _Tab.bills => _billsTab(l, v),
        _Tab.summary => _summaryTab(l, v),
      },
    );
  }

  EventTagRef _myTagRef(EmbeddedTag t) =>
      EventTagRef(t.name, iconCode: t.iconCode);

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

  /// Edit mode: the status is a setting (the view hero keeps the chip).
  Widget _statusRow(AppLocalizations l, ProjectStatus status) {
    final canChange = _isOwner && !_isCreate;
    return SettingDropdownRow<ProjectStatus>(
      label: l.projectsStatusLabel,
      value: projectStatusLabel(l, status),
      selected: status,
      onSelected: canChange ? _changeStatus : null,
      options: [
        for (final s in ProjectStatus.values)
          SheetOption(value: s, label: projectStatusLabel(l, s), submits: true),
      ],
    );
  }

  Widget _viewHero(AppLocalizations l, ProjectView v) {
    final p = v.project;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = p.iconCode.tintFor(palette);
    final range = projectDateRange(context, p.startDate, p.endDate);
    final planned = p.plannedAmount;
    final owe = p.myPayable > 0;
    final owed = p.myReceivable > 0;
    final sideColor = owe ? palette.expense : (owed ? palette.income : null);
    final myPos = v.summary?.positions
        .where((x) => x.memberId == v.me?.id)
        .firstOrNull;
    final myBacks = (
      received: myPos?.received ?? 0.0,
      sent: myPos?.sent ?? 0.0,
    );
    String money(double x) => moneyString(context, x);
    return AppHeroCard(
      style: HeroStyle.tinted(color: tint, glyph: AppIcons.project),
      content: [
        HeroIdentity(
          icon: IconDisplay(
            type: IconType.project,
            size: 40,
            iconCode: p.iconCode,
          ),
          name: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          description: HeroDescription(
            controller: _ctrl[_Field.description]!,
            editing: false,
            hint: l.commonDescription,
            onEnterEdit: _enterOn(_focus[_Field.description]!),
          ),
          actions: [
            if (v.isOwner)
              CardActionButton(
                key: const ValueKey('heroEdit'),
                icon: AppIcons.edit,
                tooltip: UiConfig.stringsOf(context).edit,
                onTap: enterEdit,
              ),
          ],
        ),
        HeroNumber(
          label: l.fpEventsSpentTotal,
          value: MoneyText(p.totalExpense),
        ),
        if (planned != null) _budgetBar(l, v, planned),
        // Read top to bottom like a sum: what I paid − my part (± the
        // paybacks) = what I get back / still owe.
        HeroFactList(
          facts: [
            HeroFact(l.evbIPaid, money(p.myPaid), icon: AppIcons.wallet),
            HeroFact(l.fpEventsMyShare, money(p.myShare), icon: AppIcons.split),
            if (myBacks.received > 0.005)
              HeroFact(
                l.evbBackReceived,
                money(myBacks.received),
                icon: AppIcons.transfer,
              ),
            if (myBacks.sent > 0.005)
              HeroFact(
                l.evbBackSent,
                money(myBacks.sent),
                icon: AppIcons.transfer,
              ),
            HeroFact(
              owe ? l.fpEventsOwe : l.fpEventsOwed,
              money(owe ? p.myPayable : p.myReceivable),
              icon: owe ? AppIcons.flowOut : AppIcons.flowIn,
              iconColor: sideColor,
              color: sideColor,
            ),
            if (p.totalIncome > 0)
              HeroFact(
                l.fpEventsIncomeTotal,
                money(p.totalIncome),
                icon: AppIcons.income,
                iconColor: palette.income,
                color: palette.income,
              ),
          ],
        ),
        HeroChipRow(
          chips: [
            _statusChip(l, p.status),
            if (range != null) AppChip(label: range, icon: AppIcons.date),
          ],
        ),
      ],
    );
  }

  Widget _budgetBar(AppLocalizations l, ProjectView v, double planned) {
    final p = v.project;
    final spent = v.summary?.spentNet ?? p.totalExpense;
    final ratio = planned > 0 ? spent / planned : 0.0;
    return HeroBar(
      value: ratio,
      fillLabel: '${(ratio * 100).round()}%',
      endLabel: moneyString(context, planned),
    );
  }

  /// สมาชิก under the note: small cards, no numbers (they are in สรุป).
  Widget _people(AppLocalizations l, ProjectView v) {
    final members = [...v.currentMembers]
      ..sort((a, b) => (b.isMe ? 1 : 0) - (a.isMe ? 1 : 0));
    return PeopleStrip(
      title: l.evbMembersTitle,
      compact: true,
      actionLabel: l.evbManageMembers,
      onAction: _openMembers,
      members: [
        for (final m in members)
          PeopleStripMember(
            avatar: ProjectMemberAvatar(
              name: m.displayName,
              iconCode: m.iconCode,
              level: projectMemberLevel(m),
              size: 32,
            ),
            name: m.displayName,
          ),
      ],
      inviteLabel: l.fpEventsInvite,
      onInvite: v.isOwner && v.project.status != ProjectStatus.archived
          ? _invite
          : null,
      onMemberTap: (_) => _openMembers(),
    );
  }

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
        onlyMine: board.mine,
      );
    }

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

    final searched = [
      board.query.isNotEmpty,
      board.payerId != null,
      board.tagId != null,
      board.sort != BoardSort.newest,
    ].where((on) => on).length;
    // Search + "only mine", at the toolbar's chip size.
    final tools = ChipSizeScope(
      size: ChipSize.chip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppChip(
            key: const ValueKey('billsSearch'),
            label: '',
            icon: AppIcons.search,
            tooltip: l.commonSearch,
            // Active = the search is open; shut with filters on, their count.
            selected: _toolbarOpen.value,
            count: _toolbarOpen.value ? 0 : searched,
            onTap: () => setState(_toolbarOpen.toggle),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChip(
            key: const ValueKey('billsOnlyMine'),
            label: l.evbOnlyMine,
            icon: AppIcons.member,
            selected: board.mine,
            onTap: () => board.change(mine: !board.mine),
          ),
        ],
      ),
    );
    // A filter loading: a card of skeleton rows in place of the old list.
    final loadingBills = board.loading && board.rows == null;
    // Shut: on the first date header. Open: their own row over the search.
    final headed =
        !_toolbarOpen.value &&
        (loadingBills || (groups.isNotEmpty && groups.first.$1 != null));
    final toolsRow = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: tools,
    );
    return DetailRecords(
      children: [
        if (!headed && !_toolbarOpen.value) toolsRow,
        // Open: the buttons, then the search a small step under them.
        if (_toolbarOpen.value)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolsRow,
              const SizedBox(height: AppSpacing.xs),
              AppListToolbar(
                sidePadding: 0,
                search: ListToolbarSearch(
                  controller: _billSearch,
                  hint: l.fpEventsBillsSearchHint,
                  onChanged: _onBillSearch,
                ),
                filters: [
                  OptionMenuAnchor<String?>(
                    selected: board.payerId,
                    onSelected: (id) => board.change(payerId: id),
                    options: [
                      SheetOption<String?>(
                        value: null,
                        label: l.fpEventsPayerAll,
                      ),
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
                  if (v.eventTags.isNotEmpty)
                    AppChip(
                      key: const ValueKey('billsTagFilter'),
                      label:
                          v.eventTags
                              .where((t) => t.id == board.tagId)
                              .firstOrNull
                              ?.name ??
                          l.transactionFormTagsLabel,
                      icon: AppIcons.tag,
                      selected: board.tagId != null,
                      trailing: AppChipTrailing.dropdown,
                      onTap: () => _pickBoardTag(v, board),
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
        if (loadingBills)
          SectionCard(
            first: true,
            // The date header's bar, as the list skeletons draw it.
            leading: SkeletonText(style: (t) => t.labelLarge, width: 80),
            trailing: headed ? tools : null,
            children: const [
              ListRowSkeleton(),
              ListRowSkeleton(),
              ListRowSkeleton(),
            ],
          )
        else ...[
          if (trees.isEmpty)
            EmptyView.compact(
              message: board.filtered ? l.projectTxNoMatch : l.projectTxEmpty,
            ),
          for (final (i, (day, list)) in groups.indexed)
            SectionCard(
              first: i == 0,
              title: day == null ? null : projectTxDateLabel(context, day),
              trailing: i == 0 && headed ? tools : null,
              children: [for (final t in list) tile(t)],
            ),
          if (_loadingMore)
            const SectionCard(children: [ListRowSkeleton(), ListRowSkeleton()]),
        ],
        if (v.canAddTx)
          AddTile(
            label: l.evbNewBill,
            variant: AddTileVariant.row,
            onTap: _addTx,
          ),
      ],
    );
  }

  /// The bills of one event tag (the tag picker over the event's tags).
  Future<void> _pickBoardTag(
    ProjectView v,
    ProjectBoardController board,
  ) async {
    final l = AppLocalizations.of(context)!;
    final r = await TagPicker.one(
      context,
      selectedId: board.tagId,
      allowNone: true,
      noneLabel: l.fpEventsTagAll,
      allowCreate: false,
      tags: [
        for (final t in v.eventTags)
          Tag(id: t.id, name: t.name, iconCode: t.iconCode),
      ],
    );
    if (!mounted || r == null) return;
    await board.change(tagId: r is TagPicked ? r.tag.id : null);
  }

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
      onRefresh: null,
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      hero: AppHeroCard(
        style: HeroStyle.tinted(color: tint, glyph: AppIcons.project),
        mode: HeroCardMode.edit,
        content: [
          HeroIdentity(
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
          ),
          HeroAmountField(
            controller: _ctrl[_Field.planned]!,
            label: l.fpEventsBudgetLabel,
            helper: l.fpEventsBudgetHelper,
            onChanged: (t) => _onText(_Field.planned, t),
            validator: (t) {
              if (t == null || t.trim().isEmpty) return null;
              final n = AmountInput.parse(t);
              return (n == null || n <= 0) ? l.projectFormPlannedInvalid : null;
            },
          ),
        ],
      ),
      tags: _tagRow(l, _draftTags(w.tagIds), editing: true),
      settings: SettingsSection(
        title: l.settingsTitle,
        children: [
          if (p != null) _statusRow(l, p.status),
          SettingSummaryRow(
            key: const ValueKey('eventDates'),
            label: l.fpEventsDatesLabel,
            onTap: _pickRange,
            trailing: range == null
                ? null
                : AppChip(
                    label: range,
                    icon: AppIcons.date,
                    selected: true,
                    trailing: AppChipTrailing.remove,
                    onTap: _pickRange,
                    onRemove: _clearRange,
                  ),
          ),
          if (v != null)
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
            hint: l.projectNoteHint,
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

  final String planned;
  final DateTime? startDate;
  final DateTime? endDate;
  final IconCode? iconCode;

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
