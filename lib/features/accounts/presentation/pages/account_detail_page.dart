import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/period_summary_card.dart';
import '../../../transactions/presentation/pages/transactions_list_page.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../wallet_errors.dart';
import '../widgets/account_card.dart';
import '../widgets/adjust_balance_sheet.dart';
import '../widgets/member_avatar_stack.dart';

/// One wallet — create (`/accounts/new`), view (`/accounts/:id`) and edit
/// in place (§10), built like the category detail page.
///
/// Header = the wallet's grid card, enlarged (accent wash, faded type glyph,
/// big balance, credit bar); it is also the live preview while editing.
/// View mode below it: this-period summary → info rows → sharing & report
/// scope (live, applies immediately) → latest transactions. ✏️ on the
/// header (owner only — the BE checks too) enters edit mode, where archive
/// is the last row. Create mode adds the opening balance and drops the
/// sections that need a saved wallet.
///
/// [startEditing] opens an existing wallet straight in edit mode
/// (`/accounts/:id/edit`; ignored for non-owners).
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    this.accountId,
    this.startEditing = false,
    super.key,
  });

  /// Null = create a new wallet.
  final String? accountId;
  final bool startEditing;

  bool get isCreate => accountId == null;

  @override
  Widget build(BuildContext context) {
    if (isCreate) return const _AccountDetailView(account: null);
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final account = context.read<AccountsCubit>().byId(accountId!);
        if (account != null) {
          return _AccountDetailView(
            account: account,
            startEditing: startEditing,
          );
        }
        return Scaffold(
          appBar: AppTopBar(title: l.navAccounts, showBack: true),
          extendBodyBehindAppBar: true,
          body: AsyncStateView.fallback(
            loading: state.status == AccountsStatus.loading,
            error: state.error,
            onRetry: context.read<AccountsCubit>().load,
            skeleton: const _DetailSkeleton(),
            notFound: EmptyView(
              icon: AppIcons.empty,
              title: l.accountDetailNotFound,
              message: l.accountDetailNotFoundMessage,
            ),
          ),
        );
      },
    );
  }
}

/// Which text field a typing burst belongs to (undo grouping).
enum _Field {
  name,
  description,
  note,
  opening,
  creditLimit,
  statementDay,
  dueDay,
  minPayment,
}

class _AccountDetailView extends StatefulWidget {
  const _AccountDetailView({required this.account, this.startEditing = false});

  /// The persisted wallet (fresh from the cubit on every rebuild); null
  /// while creating.
  final Account? account;
  final bool startEditing;

  bool get isCreate => account == null;

  @override
  State<_AccountDetailView> createState() => _AccountDetailViewState();
}

class _AccountDetailViewState extends State<_AccountDetailView>
    with EditModeMixin<_AccountDetailView, _AccountDraft> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _openingController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _statementDayController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _minPaymentController = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// Create: the user's currency; edit: the wallet's own (not editable —
  /// multi-currency is Phase 2).
  late final String _currency;
  bool _scopeBusy = false;

  bool get _isCreate => widget.isCreate;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _currency = a?.currency ?? _defaultCurrency();
    if (a == null) {
      initDraft(const _AccountDraft(), editing: true);
    } else {
      initDraft(
        _AccountDraft.from(a),
        editing: widget.startEditing && _isOwner,
      );
    }
    onDraftRestored();
  }

  @override
  void didUpdateWidget(covariant _AccountDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The cubit row changed (save, adjust, refresh) — rebase the view; an
    // in-progress edit is left alone (resetDraft no-ops while editing).
    final a = widget.account;
    if (a != null && a != oldWidget.account) {
      final next = _AccountDraft.from(a);
      if (next != original) resetDraft(next);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _descriptionController,
      _noteController,
      _openingController,
      _creditLimitController,
      _statementDayController,
      _dueDayController,
      _minPaymentController,
    ]) {
      c.dispose();
    }
    _nameFocus.dispose();
    _pages.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  String _defaultCurrency() {
    final auth = context.read<AuthCubit>().state;
    final c = auth is AuthAuthenticated ? auth.user.currency : null;
    return (c != null && Currencies.codes.contains(c)) ? c : 'THB';
  }

  /// Only the owner edits / archives (the BE checks too). Personal wallets
  /// are always the caller's own.
  bool get _isOwner {
    final a = widget.account;
    if (a == null || !a.isShared) return true;
    final auth = context.read<AuthCubit>().state;
    final uid = auth is AuthAuthenticated ? auth.user.id : null;
    return a.members.any(
      (m) => m.userId == uid && m.isActive && m.role == WalletRole.owner,
    );
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => _isCreate;

  @override
  void leavePage() {
    if (context.canPop()) context.pop();
  }

  @override
  void onDraftRestored() {
    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    final w = working;
    sync(_nameController, w.name);
    sync(_descriptionController, w.description);
    sync(_noteController, w.note);
    sync(_openingController, w.opening);
    sync(_creditLimitController, w.creditLimit);
    sync(_statementDayController, w.statementDay);
    sync(_dueDayController, w.dueDay);
    sync(_minPaymentController, w.minPayment);
  }

  void _onText(_Field field, String v) =>
      applyTextChange(field, switch (field) {
        _Field.name => working.copyWith(name: v),
        _Field.description => working.copyWith(description: v),
        _Field.note => working.copyWith(note: v),
        _Field.opening => working.copyWith(opening: v),
        _Field.creditLimit => working.copyWith(creditLimit: v),
        _Field.statementDay => working.copyWith(statementDay: v),
        _Field.dueDay => working.copyWith(dueDay: v),
        _Field.minPayment => working.copyWith(minPayment: v),
      });

  /// Long-press entry into edit mode on a field — owner only.
  VoidCallback? _enterOn(FocusNode focus) =>
      _isOwner ? () => enterEdit(focus: focus) : null;

  void _enterEditThenOpenMaker() {
    enterEdit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openIconMaker();
    });
  }

  // ── Derived display ─────────────────────────────────────────────────

  /// The wallet as the draft describes it — drives the header (live
  /// preview) and the icon maker's preview card.
  Account _preview(AppLocalizations l) {
    final w = working;
    final base = widget.account;
    final opening = AmountField.parse(w.opening) ?? 0;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    return Account(
      id: base?.id ?? 'preview',
      name: w.name.trim().isEmpty ? l.accountFormNameLabel : w.name,
      type: w.type,
      // Create: the opening balance (credit = debt, stored negative).
      balance: base?.balance ?? (w.type.isCredit ? -opening : opening),
      currency: _currency,
      iconCode: w.iconCode,
      description: opt(w.description),
      note: opt(w.note),
      creditLimit: w.type.isCredit ? AmountField.parse(w.creditLimit) : null,
      members: base?.members ?? const [],
      myReportScope: base?.myReportScope,
      isShared: base?.isShared ?? false,
    );
  }

  /// A leftover `own` on a wallet that is no longer shared reads as `all`
  /// — `own` isn't offered there (one member: "own" = "all").
  WalletReportScope _effectiveScope(Account a) {
    final s = a.myReportScope ?? WalletReportScope.none;
    if (!a.isShared && s == WalletReportScope.own) return WalletReportScope.all;
    return s;
  }

  String _scopeLabel(AppLocalizations l, WalletReportScope s) => switch (s) {
    WalletReportScope.none => l.walletReportScopeNone,
    WalletReportScope.own => l.walletReportScopeOwn,
    WalletReportScope.all => l.walletReportScopeAll,
  };

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final preview = _preview(l);
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.account,
      initial: working.iconCode,
      title: l.accountFormIconLabel,
      iconSectionLabel: l.accountFormIconLabel,
      colorSectionLabel: l.accountFormColorLabel,
      previewBuilder: (iconCode) => AccountCard(
        account: preview.copyWith(iconCode: iconCode),
        horizontal: true,
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    applyChange(working.copyWith(iconCode: result.iconCode));
  }

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l = AppLocalizations.of(context)!;
    final cubit = context.read<AccountsCubit>();
    final w = working;
    final isCredit = w.type.isCredit;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    final creditLimit = isCredit ? AmountField.parse(w.creditLimit) : null;
    final statementDay = isCredit ? int.tryParse(w.statementDay.trim()) : null;
    final dueDay = isCredit ? int.tryParse(w.dueDay.trim()) : null;
    final minPayment = isCredit ? AmountField.parse(w.minPayment) : null;

    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (_isCreate) {
        final opening = AmountField.parse(w.opening) ?? 0;
        // Server assigns the id (toCreateJson omits it) and books a
        // non-zero opening balance as an Opening Balance transaction.
        await cubit.add(
          Account(
            id: 'draft',
            name: w.name.trim(),
            type: w.type,
            balance: isCredit ? -opening : opening,
            currency: _currency,
            iconCode: w.iconCode,
            description: opt(w.description),
            note: opt(w.note),
            creditLimit: creditLimit,
            statementDate: statementDay,
            paymentDueDate: dueDay,
            minimumPayment: minPayment,
          ),
        );
      } else {
        final p = widget.account!;
        // Not copyWith: it treats null as "keep", so a cleared field would
        // silently survive — the BE's presence-tracked update DTO needs the
        // explicit nulls. Balance only moves through ปรับยอด (spec §2.4).
        await cubit.update(
          Account(
            id: p.id,
            name: w.name.trim(),
            type: w.type,
            balance: p.balance,
            currency: p.currency,
            iconCode: w.iconCode,
            description: opt(w.description),
            note: opt(w.note),
            creditLimit: creditLimit,
            statementDate: statementDay,
            paymentDueDate: dueDay,
            minimumPayment: minPayment,
            members: p.members,
            myReportScope: p.myReportScope,
            isShared: p.isShared,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, walletErrorMessage(l, e), tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    if (_isCreate) {
      leavePage();
      return;
    }
    commitSaved(working.trimmed());
  }

  /// Archive (owner, edit mode). A wallet that still has other members
  /// can't be archived (BE 409) — say so up front instead of failing.
  Future<void> _archive() async {
    final l = AppLocalizations.of(context)!;
    final a = widget.account!;
    if (a.members.where((m) => m.isActive).length > 1) {
      showAppSnackBar(context, l.accountArchiveHasMembers, tone: Tone.warning);
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l.accountArchiveConfirmTitle,
      message: l.accountArchiveConfirmBody,
      confirmLabel: l.accountArchiveConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    // Captured up front: the row leaves the cubit, so this page unmounts.
    final cubit = context.read<AccountsCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setSaving(true);
    try {
      await cubit.remove(a.id);
      showAppSnackBarOn(messenger, l.accountArchived, tone: Tone.success);
      router.go('/accounts');
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  Future<void> _adjustBalance() async {
    final l = AppLocalizations.of(context)!;
    final a = widget.account!;
    final result = await showAdjustBalanceSheet(context, a);
    if (result == null || !mounted) return;
    final cubit = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final router = GoRouter.of(context);
    try {
      final outcome = await cubit.adjustBalance(
        id: a.id,
        newBalance: result.balance,
        note: result.note,
      );
      await txCubit.load(accountId: a.id);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.accountAdjustBalanceSuccess,
        tone: Tone.success,
        actionLabel: l.accountAdjustBalanceViewTransaction,
        onAction: () =>
            router.push('/transactions/${outcome.adjustmentTransactionId}'),
      );
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  /// Report scope — the caller's own membership, applied immediately.
  Future<void> _setScope(Account a, WalletReportScope scope) async {
    if (scope == _effectiveScope(a)) return;
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<AccountsCubit>();
    setState(() => _scopeBusy = true);
    try {
      await cubit.setReportScope(accountId: a.id, scope: scope);
      if (mounted) {
        showAppSnackBar(context, l.walletReportScopeSaved, tone: Tone.success);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, walletErrorMessage(l, e), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _scopeBusy = false);
    }
  }

  /// Bumped on pull-to-refresh — rebuilds the summary card, which fetches
  /// on its own.
  int _refreshes = 0;

  Future<void> _refresh() async {
    setState(() => _refreshes++);
    await context.read<AccountsCubit>().load();
  }

  // ── Tabs ─────────────────────────────────────────────────────────────

  /// ภาพรวม · รายการ — swipe or tap (owner 2026-10-09). The header card
  /// stays above both.
  final _pages = PageController();
  _Tab _tab = _Tab.overview;

  void _goTab(_Tab t) => setState(() => _tab = t);

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = widget.account;
    // Edit mode lives on ภาพรวม (the list has nothing to edit) — the pager
    // slides back on its own.
    if (isEditing) _tab = _Tab.overview;
    return editScope(
      Scaffold(
        // The bar floats over the page; the header is padded below it.
        extendBodyBehindAppBar: true,
        appBar: AppTopBar(
          title: _title(l),
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        body: Form(
          key: _formKey,
          // Builder: this context sits inside the Scaffold body, so it sees
          // the bar height in its top padding.
          child: Builder(
            builder: (context) {
              final header = Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: _header(l),
              );
              final overview = ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.huge,
                ),
                children: _overview(l),
              );
              if (a == null) {
                return Column(
                  children: [
                    header,
                    Expanded(child: overview),
                  ],
                );
              }
              return Column(
                children: [
                  header,
                  AnimatedSize(
                    duration: AppDurations.chrome,
                    curve: AppDurations.chromeCurve,
                    child: isEditing
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              0,
                            ),
                            child: AppTabBar<_Tab>(
                              selected: _tab,
                              onChanged: _goTab,
                              pager: _pages,
                              tabs: [
                                AppTab(
                                  value: _Tab.overview,
                                  label: l.accountDetailTabOverview,
                                ),
                                AppTab(
                                  value: _Tab.transactions,
                                  label: l.accountDetailTransactionsTitle,
                                ),
                              ],
                            ),
                          ),
                  ),
                  Expanded(
                    child: AppTabPager<_Tab>(
                      controller: _pages,
                      values: _Tab.values,
                      selected: _tab,
                      onChanged: _goTab,
                      enabled: !isEditing,
                      builder: (context, t) => switch (t) {
                        _Tab.overview => PullToRefresh(
                          enabled: !isEditing,
                          onRefresh: _refresh,
                          child: overview,
                        ),
                        // The full list — search, filters, paging — on its
                        // own cubit, so the global one isn't narrowed.
                        _Tab.transactions => BlocProvider(
                          create: (ctx) => TransactionsCubit(
                            repository: ctx.read<TransactionsRepository>(),
                          ),
                          child: TransactionsListPage(
                            embedded: true,
                            lockedAccount: a,
                          ),
                        ),
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  String _title(AppLocalizations l) {
    if (_isCreate) return l.accountFormTitle;
    if (isEditing) return l.accountFormTitleEdit;
    return widget.account!.name;
  }

  /// The ภาพรวม tab (and the whole body while creating). Transactions moved
  /// to their own tab.
  List<Widget> _overview(AppLocalizations l) {
    final editing = isEditing;
    final a = widget.account;
    return [
      // The summary has nothing to edit — hidden in edit mode.
      if (a != null && !editing) ...[
        PeriodSummaryCard(key: ValueKey(_refreshes), accountId: a.id),
        const SizedBox(height: AppSpacing.md),
      ],
      _infoSection(l),
      if (a != null) ...[
        const SizedBox(height: AppSpacing.md),
        LockedInEdit(locked: editing, child: _sharingSection(l, a)),
      ],
      // Archive lives at the bottom of the body in edit mode (the top bar
      // carries no page actions).
      if (editing && a != null)
        DangerRow(
          icon: AppIcons.archive,
          label: l.accountDetailArchive,
          onTap: isSaving ? null : _archive,
        ),
    ];
  }

  Widget _header(AppLocalizations l) {
    final editing = isEditing;
    final owner = _isOwner;
    final viewing = !editing && !_isCreate;
    final scheme = Theme.of(context).colorScheme;
    final hasDescription = working.description.trim().isNotEmpty;
    return _HeroHeader(
      account: _preview(l),
      symbol: Currencies.symbolOf(_currency),
      nameField: InlineTitleField(
        editing: editing,
        controller: _nameController,
        focusNode: _nameFocus,
        hint: l.accountFormNameLabel,
        maxLines: 2,
        onEnterEdit: _enterOn(_nameFocus),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) {
          final name = v?.trim() ?? '';
          if (name.isEmpty) return l.accountFormNameRequired;
          if (name.length > 100) return l.accountFormNameTooLong;
          return null;
        },
      ),
      // The description lives here now, edited in place (owner
      // 2026-10-09) — no separate row below. The owner always gets the line
      // (empty = the dim hint) so entering edit doesn't grow the card;
      // others only see one that's set.
      descriptionField: editing || hasDescription || owner
          ? InlineTitleField(
              editing: editing,
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              hint: l.accountFormDescriptionHelper,
              maxLength: 280,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
              onEnterEdit: owner ? _enterOn(_descriptionFocus) : null,
              onChanged: (v) => _onText(_Field.description, v),
            )
          : null,
      // Create has no actions; otherwise they stay in the layout and only
      // fade out while editing, so the name never reflows.
      onEdit: !_isCreate && owner ? enterEdit : null,
      onIconTap: editing ? _openIconMaker : null,
      onIconLongPress: viewing && owner ? _enterEditThenOpenMaker : null,
      onAdjust: _isCreate ? null : _adjustBalance,
      actionsActive: viewing,
    );
  }

  Widget _infoSection(AppLocalizations l) {
    final editing = isEditing;
    final owner = _isOwner;
    final w = working;
    final symbol = Currencies.symbolOf(_currency);
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    // The type's picked look follows the wallet's own colour.
    final accent = w.iconCode?.accentColorFor(palette) ?? palette.primary;
    // Non-owners can't fill an empty field, so don't show it.
    bool show(String v) => editing || owner || v.trim().isNotEmpty;
    return SectionCard(
      children: [
        if (editing)
          DetailStacked(
            label: l.accountFormTypeLabel,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SelectCardGroup<AccountType>(
                columns: 3,
                selected: w.type,
                onChanged: (t) => applyChange(w.copyWith(type: t)),
                options: [
                  for (final t in AccountType.values)
                    SelectCardOption(
                      value: t,
                      label: accountTypeLabel(context, t),
                      icon: t.icon,
                      color: accent,
                    ),
                ],
              ),
            ),
          )
        else
          DetailRow(
            label: l.accountFormTypeLabel,
            trailing: _TypeChip(type: w.type, accent: accent),
          ),
        if (_isCreate) ...[
          const RowDivider(),
          DetailStacked(
            label: w.type.isCredit
                ? l.accountFormOpeningDebtLabel
                : l.accountFormBalanceLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AmountField(
                  controller: _openingController,
                  currencySymbol: symbol,
                  // ± — e.g. an overdrawn account, or an overpaid card.
                  allowNegative: true,
                  onChanged: (v) => _onText(_Field.opening, v),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  w.type.isCredit
                      ? l.accountFormOpeningDebtHelper
                      : l.accountFormBalanceHelper,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (show(w.note)) ...[
          const RowDivider(),
          DetailStacked(
            label: l.accountDetailNote,
            child: InlineField(
              editing: editing,
              controller: _noteController,
              focusNode: _noteFocus,
              maxLines: 2,
              maxLength: 280,
              hint: l.accountFormNoteHelper,
              onEnterEdit: _enterOn(_noteFocus),
              onChanged: (v) => _onText(_Field.note, v),
            ),
          ),
        ],
        if (w.type.isCredit) ..._creditRows(l, symbol),
      ],
    );
  }

  /// Card / pay-later billing: read-only rows in view mode (unset ones
  /// hidden), inputs in edit mode.
  List<Widget> _creditRows(AppLocalizations l, String symbol) {
    final w = working;
    if (!isEditing) {
      final limit = AmountField.parse(w.creditLimit);
      final statementDay = int.tryParse(w.statementDay);
      final dueDay = int.tryParse(w.dueDay);
      final minPayment = AmountField.parse(w.minPayment);
      return [
        const RowDivider(),
        DetailRow(
          label: l.accountFormCreditLimitLabel,
          trailing: limit == null
              ? const Text('—')
              : MoneyText(limit, symbol: symbol),
        ),
        if (statementDay != null) ...[
          const RowDivider(),
          DetailRow(
            label: l.accountDetailStatementDate,
            trailing: Text(l.accountDetailDayOfMonth(statementDay)),
          ),
        ],
        if (dueDay != null) ...[
          const RowDivider(),
          DetailRow(
            label: l.accountDetailPaymentDue,
            trailing: Text(l.accountDetailDayOfMonth(dueDay)),
          ),
        ],
        if (minPayment != null) ...[
          const RowDivider(),
          DetailRow(
            label: l.accountDetailMinimumPayment,
            trailing: MoneyText(minPayment, symbol: symbol),
          ),
        ],
      ];
    }
    String? validateDay(String? v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return null; // optional
      final n = int.tryParse(t);
      if (n == null || n < 1 || n > 31) return l.accountFormDayInvalid;
      return null;
    }

    return [
      const RowDivider(),
      DetailStacked(
        label: l.accountFormCreditLimitLabel,
        child: AmountField(
          controller: _creditLimitController,
          currencySymbol: symbol,
          onChanged: (v) => _onText(_Field.creditLimit, v),
          validator: (v) {
            final n = AmountField.parse(v);
            if (n == null || n <= 0) return l.accountFormCreditLimitRequired;
            return null;
          },
        ),
      ),
      const RowDivider(),
      DetailRow(
        label: l.accountFormStatementDateLabel,
        helper: l.accountFormStatementDateHelper,
        trailing: _DayField(
          controller: _statementDayController,
          onChanged: (v) => _onText(_Field.statementDay, v),
          validator: validateDay,
        ),
      ),
      const RowDivider(),
      DetailRow(
        label: l.accountFormPaymentDueLabel,
        helper: l.accountFormPaymentDueHelper,
        trailing: _DayField(
          controller: _dueDayController,
          onChanged: (v) => _onText(_Field.dueDay, v),
          validator: validateDay,
        ),
      ),
      const RowDivider(),
      DetailStacked(
        label: l.accountFormMinimumPaymentLabel,
        child: AmountField(
          controller: _minPaymentController,
          currencySymbol: symbol,
          onChanged: (v) => _onText(_Field.minPayment, v),
        ),
      ),
    ];
  }

  /// Members + the caller's report scope (was the wallet settings sheet).
  /// Live in view mode; the scope applies immediately.
  Widget _sharingSection(AppLocalizations l, Account a) {
    final scope = _effectiveScope(a);
    return SectionCard(
      title: l.accountSharingSectionTitle,
      children: [
        DetailRow(
          label: l.walletMembersTitle,
          // Inviting the first member is how a personal wallet becomes
          // shared, so the row is always there.
          helper: a.isShared
              ? l.walletMembersCount(a.members.length)
              : l.walletSettingsMembersSubtitlePersonal,
          trailing: a.isShared
              ? MemberAvatarStack(members: a.members, size: 28)
              : null,
          showChevron: true,
          onTap: () => context.push('/accounts/${a.id}/members'),
        ),
        const RowDivider(),
        DetailRow(
          label: l.walletReportScopeTitle,
          helper: l.walletReportScopeHelper,
          trailing: OptionMenuAnchor<WalletReportScope>(
            selected: scope,
            onSelected: (s) => _setScope(a, s),
            options: [
              for (final s in [
                WalletReportScope.none,
                // "own" only means something with more than one member.
                if (a.isShared) WalletReportScope.own,
                WalletReportScope.all,
              ])
                SheetOption(value: s, label: _scopeLabel(l, s)),
            ],
            builder: (context, toggle) => _ValueBox(
              label: _scopeLabel(l, scope),
              onTap: _scopeBusy ? null : toggle,
            ),
          ),
        ),
      ],
    );
  }
}

enum _Tab { overview, transactions }

// ────────────────────────────────────────────────────────────────────
// Header — the wallet's grid card, enlarged. View mode: ✏️ → edit,
// long-press the icon → edit + maker, [ปรับยอด]. Edit mode: tap the icon →
// maker, the name is an input.
// ────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.account,
    required this.symbol,
    required this.nameField,
    this.descriptionField,
    this.onEdit,
    this.onIconTap,
    this.onIconLongPress,
    this.onAdjust,
    this.actionsActive = true,
  });

  /// The draft as a wallet (live preview).
  final Account account;
  final String symbol;
  final Widget nameField;

  /// Under the name; null hides it (a non-owner viewing, no description).
  final Widget? descriptionField;

  /// The ✏️ chip (owner); null leaves it out.
  final VoidCallback? onEdit;
  final VoidCallback? onIconTap;
  final VoidCallback? onIconLongPress;

  /// The ปรับยอด button; null leaves it out (create).
  final VoidCallback? onAdjust;

  /// false (edit mode) fades ✏️ / ปรับยอด out but keeps their space, so
  /// the name column — and the card — keep their size between modes.
  final bool actionsActive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = account.iconCode?.accentColorFor(palette) ?? palette.primary;
    final utilization = account.creditUtilization;
    final limit = account.creditLimit ?? 0;
    return AccountCardSurface(
      account: account,
      margin: EdgeInsets.zero,
      glyphSize: 132,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon · name over description · actions (owner 2026-10-09:
            // name beside the icon; ปรับยอด next to ✏️).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AccountIconCircle keeps a constant footprint with or
                // without onTap, so nothing shifts between modes.
                GestureDetector(
                  onLongPress: onIconLongPress,
                  child: AccountIconCircle(
                    account: account,
                    size: 52,
                    onTap: onIconTap,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [nameField, ?descriptionField],
                  ),
                ),
                if (account.isShared) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: OtherMembersStack(account: account, size: 24),
                  ),
                ],
                if (onAdjust != null || onEdit != null)
                  IgnorePointer(
                    ignoring: !actionsActive,
                    child: AnimatedOpacity(
                      duration: AppDurations.chrome,
                      curve: AppDurations.chromeCurve,
                      opacity: actionsActive ? 1 : 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onAdjust != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _PillButton(
                              icon: AppIcons.reset,
                              label: l.accountDetailAdjustBalance,
                              onPressed: onAdjust!,
                            ),
                          ],
                          if (onEdit != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            AppIconButton(
                              icon: AppIcons.edit,
                              size: 32,
                              tooltip: l.commonEdit,
                              onPressed: onEdit,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            MoneyText(
              account.balance,
              symbol: symbol,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            if (utilization != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ProgressRow(
                value: utilization,
                color: accent,
                label: l.accountDetailCreditAvailable(
                  moneyString(
                    context,
                    limit - account.balance.abs(),
                    symbol: symbol,
                  ),
                  moneyString(context, limit, symbol: symbol),
                ),
                trailing: '${(utilization * 100).round()}%',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact labelled chip beside the header's ✏️ — same look as
/// [AppIconButton] (32 high), with room for a word.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The wallet type as a tinted chip (view mode) — icon + label in the
/// wallet's accent.
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.accent});

  final AccountType type;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 18, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              accountTypeLabel(context, type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Day-of-month input (1–31) for the billing rows.
class _DayField extends StatelessWidget {
  const _DayField({
    required this.controller,
    required this.onChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: InlineField(
        editing: true,
        controller: controller,
        maxLength: 2,
        keyboardType: TextInputType.number,
        hint: '1–31',
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// The current choice + ▾ — the trigger of a popover picker in a row.
class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.label, required this.onTap});

  final String label;

  /// Null = busy (dimmed, not tappable).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.dropdown, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep-link skeleton while the wallets list loads: hero + rows.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: const [
        SkeletonBox(height: 188, borderRadius: AppRadius.lg),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 96, borderRadius: AppRadius.lg),
        SizedBox(height: AppSpacing.lg),
        SkeletonListTile(avatarSize: 24, lines: 1),
        SkeletonListTile(avatarSize: 24, lines: 1),
        SkeletonListTile(avatarSize: 24, lines: 1),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Immutable editing snapshot — drives dirty-check + undo history. Money /
// day fields hold the field text (formatted), parsed on save.
// ────────────────────────────────────────────────────────────────────

class _AccountDraft {
  const _AccountDraft({
    this.name = '',
    this.type = AccountType.cash,
    this.iconCode,
    this.description = '',
    this.note = '',
    this.opening = '',
    this.creditLimit = '',
    this.statementDay = '',
    this.dueDay = '',
    this.minPayment = '',
  });

  final String name;
  final AccountType type;
  final IconCode? iconCode;
  final String description;
  final String note;

  /// Create only — the opening balance (credit: the debt; may be negative).
  final String opening;
  final String creditLimit;
  final String statementDay;
  final String dueDay;
  final String minPayment;

  factory _AccountDraft.from(Account a) => _AccountDraft(
    name: a.name,
    type: a.type,
    iconCode: a.iconCode,
    description: a.description ?? '',
    note: a.note ?? '',
    creditLimit: a.creditLimit == null
        ? ''
        : AmountField.format(a.creditLimit!),
    statementDay: a.statementDate?.toString() ?? '',
    dueDay: a.paymentDueDate?.toString() ?? '',
    minPayment: a.minimumPayment == null
        ? ''
        : AmountField.format(a.minimumPayment!),
  );

  /// What the server stores (text trimmed) — the post-save baseline.
  _AccountDraft trimmed() => copyWith(
    name: name.trim(),
    description: description.trim(),
    note: note.trim(),
    statementDay: statementDay.trim(),
    dueDay: dueDay.trim(),
  );

  _AccountDraft copyWith({
    String? name,
    AccountType? type,
    IconCode? iconCode,
    String? description,
    String? note,
    String? opening,
    String? creditLimit,
    String? statementDay,
    String? dueDay,
    String? minPayment,
  }) {
    return _AccountDraft(
      name: name ?? this.name,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      opening: opening ?? this.opening,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      minPayment: minPayment ?? this.minPayment,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _AccountDraft &&
      other.name == name &&
      other.type == type &&
      other.iconCode == iconCode &&
      other.description == description &&
      other.note == note &&
      other.opening == opening &&
      other.creditLimit == creditLimit &&
      other.statementDay == statementDay &&
      other.dueDay == dueDay &&
      other.minPayment == minPayment;

  @override
  int get hashCode => Object.hash(
    name,
    type,
    iconCode,
    description,
    note,
    opening,
    creditLimit,
    statementDay,
    dueDay,
    minPayment,
  );
}
