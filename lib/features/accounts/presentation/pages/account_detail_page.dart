import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/pages/transactions_list_page.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account.dart';
import '../../domain/account_identifier.dart';
import '../../domain/payment_provider.dart';
import '../../domain/account_type.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../wallet_errors.dart';
import '../widgets/account_card.dart';
import '../widgets/adjust_balance_sheet.dart';
import '../widgets/identifier_widgets.dart';
import '../widgets/member_avatar_stack.dart';
import '../widgets/wallet_members_view.dart';
import '../widgets/wallet_compact_hero.dart';

/// The wallet page's tabs.
enum AccountDetailTab { overview, transactions, members }

/// One wallet — create (`/accounts/new`), view (`/accounts/:id`) and edit
/// in place (§10; owner 2026-10-10):
///
///   hero: [type][🔗 แชร์ n คน]                 ✏️ (owner)
///         icon · name / description · balance · credit "เหลือ x จาก y"
///   [ปรับยอด] [+ รายการ] [⇄ โอน]       (every member; view mode)
///   ภาพรวม · รายการ · สมาชิก         (pinned once the hero scrolls away;
///                                     its name + balance go up to the bar)
///
/// ภาพรวม: info → the slip numbers → my report scope (live) → archive (edit
/// mode, owner). รายการ: the wallet's own list, this month to start.
/// สมาชิก (shared, or the owner — to invite): members and their actions
/// (`/accounts/:id/members` opens here). ✏️ (owner only — the BE checks
/// too) edits in place; the hero is the live preview. Create mode is the
/// hero + ภาพรวม with the opening balance, no tabs.
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    this.accountId,
    this.initialTab = AccountDetailTab.overview,
    this.popOnCreate = false,
    super.key,
  });

  /// Null = create a new wallet.
  final String? accountId;
  final AccountDetailTab initialTab;

  /// Create pushed over a picker (Navigator, not the router): saving pops
  /// with the new [Account] instead of becoming its view, so the page
  /// underneath stays (QA W2).
  final bool popOnCreate;

  bool get isCreate => accountId == null;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

/// One call on open — `GET /accounts/:id?include=summary,members` (any
/// status, archived included) — fills the wallet and its members history.
/// The wallet itself comes from the cubit's list when it is there (so
/// balance patches show live), else from that call. "Not found" only when
/// the call says so; writes patch [_detail] from their responses.
class _AccountDetailPageState extends State<AccountDetailPage> {
  AccountDetail? _detail;
  ApiException? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCreate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() async {
    final cubit = context.read<AccountsCubit>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await cubit.getDetail(widget.accountId!);
      // Keep the list's row as fresh as this read.
      cubit.patch(detail.account);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(e, st);
        _loading = false;
      });
    }
  }

  /// A write returned the wallet: keep the page's copy in step (the cubit
  /// patched its list already).
  void _onAccount(Account account) {
    final d = _detail;
    if (d == null) return;
    setState(() => _detail = d.copyWith(account: account));
  }

  /// A members action's response: the wallet + the whole members list.
  void _onMembers(MembersResult r) {
    final d = _detail;
    if (d == null) return;
    setState(
      () => _detail = d.copyWith(account: r.account, membersHistory: r.members),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCreate) {
      return _AccountDetailView(account: null, popOnCreate: widget.popOnCreate);
    }
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final account =
            context.read<AccountsCubit>().byId(widget.accountId!) ??
            _detail?.account;
        if (account != null) {
          return _AccountDetailView(
            account: account,
            members: _detail?.membersHistory,
            initialTab: widget.initialTab,
            onAccount: _onAccount,
            onMembers: _onMembers,
            onRefresh: _fetch,
          );
        }
        final notFound = _error?.code == 'NOT_FOUND';
        return Scaffold(
          appBar: AppTopBar(title: l.navAccounts, showBack: true),
          extendBodyBehindAppBar: true,
          body: AsyncStateView.fallback(
            loading: _loading || (_detail == null && _error == null),
            error: notFound ? null : _error,
            onRetry: _fetch,
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
  const _AccountDetailView({
    required this.account,
    this.members,
    this.initialTab = AccountDetailTab.overview,
    this.popOnCreate = false,
    this.onAccount,
    this.onMembers,
    this.onRefresh,
  });

  /// See [AccountDetailPage.popOnCreate].
  final bool popOnCreate;

  /// The persisted wallet (fresh from the cubit on every rebuild); null
  /// while creating.
  final Account? account;

  /// The whole membership (`members_history`: active, pending, left); null
  /// until the page's detail call lands.
  final List<WalletMember>? members;
  final AccountDetailTab initialTab;

  /// A write returned the wallet — the page keeps its copy in step.
  final void Function(Account)? onAccount;

  /// A members action returned the wallet + members list.
  final void Function(MembersResult)? onMembers;

  /// Pull-to-refresh: the page's one detail call again.
  final Future<void> Function()? onRefresh;

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

  /// Banks for the numbers section (names + the sheet's picker).
  List<PaymentProvider> _providers = const [];

  bool get _isCreate => widget.isCreate;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _currency = a?.currency ?? _defaultCurrency();
    if (a == null) {
      initDraft(const _AccountDraft(), editing: true);
    } else {
      initDraft(_AccountDraft.from(a));
      _tab = widget.initialTab;
      _pages = PageController(initialPage: _tabs.indexOf(_tab).clamp(0, 2));
    }
    onDraftRestored();
    context
        .read<AccountsRepository>()
        .paymentProviders()
        .then((p) {
          if (mounted) setState(() => _providers = p);
        })
        // Names fall back to the bank code; the picker shows "not set".
        .catchError((Object _) {});
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
    _outerScroll.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  String _defaultCurrency() {
    final auth = context.read<AuthCubit>().state;
    final c = auth is AuthAuthenticated ? auth.user.currency : null;
    return (c != null && Currencies.codes.contains(c)) ? c : 'THB';
  }

  /// Only the owner edits / archives (the BE says so: `can_edit`; it checks
  /// too). A wallet being created is the caller's own.
  bool get _isOwner => widget.account?.canEdit ?? true;

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => _isCreate;

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
    final opening = AmountInput.parse(w.opening) ?? 0;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    return Account(
      id: base?.id ?? 'preview',
      name: w.name.trim().isEmpty ? l.commonName : w.name,
      type: w.type,
      // Create: the opening balance (credit = debt, stored negative).
      balance: base?.balance ?? _openingBalance(w.type, opening),
      currency: _currency,
      iconCode: w.iconCode,
      description: opt(w.description),
      note: opt(w.note),
      creditLimit: w.type.isCredit ? AmountInput.parse(w.creditLimit) : null,
      members: base?.members ?? const [],
      myReportScope: base?.myReportScope,
      isShared: base?.isShared ?? false,
      logoUrl: base?.logoUrl,
      status: base?.status ?? AccountStatus.active,
      canEdit: base?.canEdit ?? true,
      myRole: base?.myRole ?? WalletRole.owner,
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
    final creditLimit = isCredit ? AmountInput.parse(w.creditLimit) : null;
    final statementDay = isCredit ? int.tryParse(w.statementDay.trim()) : null;
    final dueDay = isCredit ? int.tryParse(w.dueDay.trim()) : null;
    final minPayment = isCredit ? AmountInput.parse(w.minPayment) : null;

    FocusScope.of(context).unfocus();
    setSaving(true);
    Account? created;
    try {
      if (_isCreate) {
        final opening = AmountInput.parse(w.opening) ?? 0;
        // Server assigns the id (toCreateJson omits it) and books a
        // non-zero opening balance as an Opening Balance transaction.
        created = await cubit.add(
          Account(
            id: 'draft',
            name: w.name.trim(),
            type: w.type,
            balance: _openingBalance(w.type, opening),
            currency: _currency,
            iconCode: w.iconCode,
            description: opt(w.description),
            note: opt(w.note),
            creditLimit: creditLimit,
            statementDate: statementDay,
            paymentDueDate: dueDay,
            minimumPayment: minPayment,
            identifiers: w.cleanIdentifiers,
          ),
        );
      } else {
        final p = widget.account!;
        // Not copyWith: it treats null as "keep", so a cleared field would
        // silently survive — the BE's presence-tracked update DTO needs the
        // explicit nulls. Balance only moves through ปรับยอด (spec §2.4).
        final updated = await cubit.update(
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
            identifiers: w.cleanIdentifiers,
          ),
        );
        widget.onAccount?.call(updated);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, walletErrorMessage(l, e), tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    if (created != null && widget.popOnCreate) {
      // Pop without the discard prompt — the picker takes it from here.
      commitSaved(_AccountDraft.from(created));
      Navigator.of(context).pop(created);
      return;
    }
    if (created != null) {
      // Become the saved wallet right here — edit → view in place, as
      // categories / contacts do. `replace` keeps the page key (no
      // transition, this state stays); the route now carries the id.
      commitSaved(_AccountDraft.from(created));
      context.replace('/accounts/${created.id}');
      return;
    }
    commitSaved(working.trimmed());
  }

  /// A credit wallet's opening amount is debt, stored negative. Zero stays
  /// a plain 0 — `-0.0` would show as "-฿0.00".
  static double _openingBalance(AccountType type, double opening) =>
      opening == 0 ? 0 : (type.isCredit ? -opening : opening);

  /// Archive (owner, edit mode). A wallet that still has other members
  /// can't be archived (BE 409) — say so up front instead of failing.
  Future<void> _archive() async {
    final l = AppLocalizations.of(context)!;
    final a = widget.account!;
    if (a.isShared) {
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
    final open = pageOpener(context);
    try {
      final outcome = await cubit.adjustBalance(
        id: a.id,
        newBalance: result.balance,
        description: result.description,
        note: result.note,
      );
      // The cubit patched the wallet + every touched balance already.
      widget.onAccount?.call(outcome.account);
      // The wallet's own list and the app's list both re-fetch, each
      // keeping its filters (a bare load narrowed the global one to this
      // wallet with no chip saying so).
      await TransactionsCubit.bookChanged();
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.accountAdjustBalanceSuccess,
        tone: Tone.success,
        actionLabel: l.accountAdjustBalanceViewTransaction,
        onAction: outcome.transactionId == null
            ? null
            : () => open('/transactions/${outcome.transactionId}'),
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
      final updated = await cubit.setReportScope(accountId: a.id, scope: scope);
      widget.onAccount?.call(updated);
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

  /// Pull-to-refresh: the page's one detail call again.
  Future<void> _refresh() async => widget.onRefresh?.call();

  // ── Tabs ─────────────────────────────────────────────────────────────

  /// ภาพรวม · รายการ · สมาชิก — swipe or tap. สมาชิก only with someone else
  /// in the wallet (active > 1, or an invite pending — owner 2026-10-11);
  /// alone, ภาพรวม's สมาชิก section offers the invite.
  /// The hero (the compact bar watches it) and the page's outer scroll.
  final _heroKey = GlobalKey();
  final _outerScroll = ScrollController();

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

  late PageController _pages = PageController();
  AccountDetailTab _tab = AccountDetailTab.overview;

  List<AccountDetailTab> get _tabs => [
    AccountDetailTab.overview,
    AccountDetailTab.transactions,
    if (widget.account case final a? when _hasMembersTab(a))
      AccountDetailTab.members,
  ];

  void _goTab(AccountDetailTab t) => setState(() => _tab = t);

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = widget.account;
    final tabs = _tabs;
    // Edit mode lives on ภาพรวม (the other tabs have nothing to edit).
    if (isEditing || !tabs.contains(_tab)) _tab = AccountDetailTab.overview;
    final page = editScope(
      Scaffold(
        // The bar floats over the page; the hero is padded below it.
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
              final barInset = MediaQuery.paddingOf(context).top;
              final bottom =
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom;
              final heroBox = KeyedSubtree(key: _heroKey, child: _header(l));
              // Create: the hero and the form, one scroll, no tabs — the
              // DetailPage template.
              if (a == null) {
                return DetailPageBody(
                  topInset: barInset + AppSpacing.lg,
                  bottomInset: bottom,
                  hero: heroBox,
                  sections: _sectionBuilders(l),
                );
              }
              final hero = Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: heroBox,
              );
              final scheme = Theme.of(context).colorScheme;
              // The hero (+ actions) scrolls away; the tab bar pins right
              // under the top bar (the scroll view starts below it); each
              // tab scrolls inside.
              // Once the hero is gone under the pinned tabs, the kit's
              // compact bar (icon · name · balance) floats just below them,
              // over the tab's content — nothing below moves. Tap it → back
              // to the hero. In edit mode (no tabs) it sits under the top bar.
              return Padding(
                padding: EdgeInsets.only(top: barInset),
                child: CompactHeroScope(
                  heroKey: _heroKey,
                  top: isEditing ? 0 : _PinnedTabBar._height,
                  bar: walletCompactHero(
                    context,
                    _preview(l),
                    onTap: _scrollToHero,
                  ),
                  child: NestedScrollView(
                    controller: _outerScroll,
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(child: hero),
                      // [ปรับยอด] [+ รายการ] [⇄ โอน] right under the hero; it
                      // scrolls away with it (view mode only).
                      if (!isEditing)
                        SliverToBoxAdapter(child: _actionBar(l, a)),
                      // 16 from the hero to the tabs (HeroSpacing.after).
                      if (!isEditing)
                        const SliverToBoxAdapter(
                          child: SizedBox(height: HeroSpacing.after),
                        ),
                      if (!isEditing)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _PinnedTabBar(
                            background: scheme.surface,
                            child: AppTabBar<AccountDetailTab>(
                              selected: _tab,
                              onChanged: _goTab,
                              pager: _pages,
                              tabs: [
                                for (final t in tabs)
                                  AppTab(value: t, label: _tabLabel(l, t)),
                              ],
                            ),
                          ),
                        ),
                    ],
                    body: AppTabPager<AccountDetailTab>(
                      controller: _pages,
                      values: tabs,
                      selected: _tab,
                      onChanged: _goTab,
                      enabled: !isEditing,
                      builder: (context, t) => switch (t) {
                        AccountDetailTab.overview =>
                          // The hero lives above the pager, so none here; the
                          // list stays the nested scroll's primary one.
                          DetailPageBody(
                            onRefresh: _refresh,
                            physics: const AlwaysScrollableScrollPhysics(),
                            topInset: AppSpacing.md,
                            bottomInset: bottom,
                            sections: _sectionBuilders(l),
                            manage: isEditing
                                ? ManageSection(
                                    archiveLabel: l.accountDetailArchive,
                                    onArchive: isSaving ? null : _archive,
                                  )
                                : null,
                            metaLines: detailMetaLines(
                              context,
                              createdAt: a.createdAt,
                              updatedAt: a.updatedAt,
                            ),
                          ),
                        // The full list — search, filters, paging — on its
                        // own cubit, so the global one isn't narrowed.
                        AccountDetailTab.transactions => BlocProvider(
                          create: (ctx) => TransactionsCubit(
                            repository: ctx.read<TransactionsRepository>(),
                          ),
                          child: TransactionsListPage(
                            embedded: true,
                            lockedAccount: a,
                          ),
                        ),
                        AccountDetailTab.members =>
                          widget.members == null
                              ? ListView(
                                  padding: _tabInsets(bottom),
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    for (var i = 0; i < 3; i++)
                                      const SkeletonListTile(),
                                  ],
                                )
                              : WalletMembersView(
                                  account: a,
                                  members: widget.members!,
                                  onResult: (r) => widget.onMembers?.call(r),
                                  onRefresh: _refresh,
                                  padding: _tabInsets(bottom),
                                ),
                      },
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
    if (a == null) return page;
    // The shell's centre + opens the quick create on this wallet while
    // this page is on screen, any tab (owner 2026-10-11).
    return QuickCreatePresetScope(
      preset: QuickCreatePreset(account: a),
      child: page,
    );
  }

  String _tabLabel(AppLocalizations l, AccountDetailTab t) => switch (t) {
    AccountDetailTab.overview => l.accountDetailTabOverview,
    AccountDetailTab.transactions => l.accountDetailTransactionsTitle,
    AccountDetailTab.members => l.walletMembersTitle,
  };

  /// Titles never change with the mode (owner, QA T1): the wallet's name in
  /// view and edit alike — the action bar shows it's edit mode.
  String _title(AppLocalizations l) =>
      _isCreate ? l.accountFormTitle : widget.account!.name;

  /// The overview's sections (the ภาพรวม tab, and the whole body while
  /// creating) as DetailPage builders: info, the slip numbers, my report
  /// scope; the archive sits in `manage` (edit mode). Headless group first —
  /// owner 2026-10-12: the note sits right under the hero.
  List<Widget? Function(bool first)> _sectionBuilders(AppLocalizations l) {
    final a = widget.account;
    return [
      (f) => _noteSection(l, first: f),
      (f) => _typeSection(l, first: f),
      (f) => _creditSection(l, first: f),
      (f) => _identifiersSection(l, first: f),
      if (a != null) (f) => _membersSection(l, a, first: f),
      if (a != null) (f) => _scopeSection(l, a, first: f),
    ];
  }

  /// A tab's list padding under the pinned tab bar — shared by every tab.
  EdgeInsets _tabInsets(double bottom) =>
      EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, bottom);

  /// The wallet's actions under the hero. ปรับยอด: every member (as before);
  /// + รายการ / ⇄ โอน: the quick create with this wallet preset (a transfer
  /// starts from it). The sheet patches the cubits itself.
  Widget _actionBar(AppLocalizations l, Account a) => ActionBar(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      0,
    ),
    actions: [
      ActionBarItem(
        label: l.accountDetailAdjustBalance,
        icon: AppIcons.refresh,
        onPressed: _adjustBalance,
      ),
      ActionBarItem(
        label: l.navTransactions,
        icon: AppIcons.add,
        onPressed: () => showQuickCreateSheet(context, account: a),
      ),
      ActionBarItem(
        label: l.accountDetailTransfer,
        icon: AppIcons.transfer,
        onPressed: () => showQuickCreateSheet(
          context,
          account: a,
          type: TransactionType.transfer,
        ),
      ),
    ],
  );

  Widget _header(AppLocalizations l) {
    final editing = isEditing;
    final owner = _isOwner;
    final viewing = !editing && !_isCreate;
    return _HeroHeader(
      account: _preview(l),
      symbol: Currencies.symbolOf(_currency),
      balanceField: _isCreate ? _openingField(l) : null,
      nameField: HeroNameInput(
        editing: editing,
        controller: _nameController,
        focusNode: _nameFocus,
        hint: l.accountFormNameExample,
        maxLength: TextLimits.name,
        maxLines: 2,
        onEnterEdit: _enterOn(_nameFocus),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) {
          final name = v?.trim() ?? '';
          if (name.isEmpty) return l.accountFormNameRequired;
          if (name.length > TextLimits.name) return l.accountFormNameTooLong;
          return null;
        },
      ),
      descriptionField: HeroDescription(
        controller: _descriptionController,
        editing: editing,
        focusNode: _descriptionFocus,
        hint: l.accountFormDescriptionExample,
        maxLength: TextLimits.description,
        onEnterEdit: _enterOn(_descriptionFocus),
        onChanged: (v) => _onText(_Field.description, v),
      ),
      onEdit: viewing && owner ? enterEdit : null,
      onIconTap: editing ? _openIconMaker : null,
      onIconLongPress: viewing && owner ? _enterEditThenOpenMaker : null,
      showLabels: editing,
    );
  }

  /// Create: the hero's balance IS the opening-balance input. Typed as a
  /// positive amount for every type — assets: what the wallet holds; credit /
  /// pay-later: what is owed. The sign for the BE is mapped on save and in the
  /// preview by [_openingBalance] (credit = debt, stored negative).
  Widget _openingField(AppLocalizations l) {
    final base = AppTypography.of(context, AppTextRole.display);
    final accent = _preview(l).colorOf(context);
    final style = base?.copyWith(color: accent);
    return AppInput.card(
      controller: _openingController,
      type: AppInputType.amount,
      label: l.accountFormBalanceLabel,
      style: style,
      cursorColor: Theme.of(context).colorScheme.primary,
      focusColor: accent,
      symbolScale: 0.7,
      currencySymbol: Currencies.symbolOf(_currency),
      minWidth: 12,
      hint: '0',
      hintStyle: style?.copyWith(color: accent.withValues(alpha: 0.35)),
      hideHintOnFocus: true,
      onChanged: (v) => _onText(_Field.opening, v),
    );
  }

  /// ประเภท — edit / create only (view: the hero's pill). The big type
  /// cards in their group colour (have / owe), not the icon's.
  Widget? _typeSection(AppLocalizations l, {required bool first}) {
    if (!isEditing) return null;
    final w = working;
    return SectionCard(
      first: first,
      title: l.accountFormTypeLabel,
      description: l.accountTypeSectionDescription,
      dividers: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                  color: t.colorOf(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// บัตร / วงเงิน — credit types only. View: the set rows (the limit is
  /// in the hero's bar); none set → no section.
  Widget? _creditSection(AppLocalizations l, {required bool first}) {
    if (!working.type.isCredit) return null;
    final rows = _creditRows(l, Currencies.symbolOf(_currency));
    if (rows.isEmpty) return null;
    return SectionCard(
      first: first,
      title: l.accountCreditSectionTitle,
      description: l.accountCreditSectionDescription,
      children: rows,
    );
  }

  /// The heading-less top box: the note only (the description lives in the
  /// hero); empty in view mode reads "แตะค้างเพื่อแก้ไข".
  Widget _noteSection(AppLocalizations l, {required bool first}) {
    return SectionCard(
      first: first,
      children: [
        DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: isEditing,
            controller: _noteController,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            hint: l.accountFormNoteHelper,
            viewHint: AppLocalizations.of(context)!.commonLongPressToEdit,
            onEnterEdit: _enterOn(_noteFocus),
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ],
    );
  }

  /// สมาชิก — everyone in the wallet (me included, pending invites too)
  /// as one avatar row, › to the สมาชิก tab. Alone: an invite row instead
  /// (owner). Live, locked while editing.
  Widget? _membersSection(
    AppLocalizations l,
    Account a, {
    required bool first,
  }) {
    // Everyone in the wallet (me included) + the invites still pending.
    final members = [...a.members, ..._pendingInvites];
    final solo = !_hasMembersTab(a);
    if (solo && !_isOwner) return null;
    return SectionCard(
      first: first,
      title: l.walletMembersTitle,
      description: l.accountMembersSectionDescription,
      children: [
        if (solo)
          LockedInEdit(
            locked: isEditing,
            child: DetailAddRow(
              label: l.walletInviteFromContacts,
              onTap: () => inviteWalletMember(
                context,
                account: a,
                members: widget.members ?? members,
                onResult: (r) => widget.onMembers?.call(r),
              ),
            ),
          )
        else
          DetailRow(
            label: l.accountSharedWith(members.length),
            locked: isEditing,
            showChevron: true,
            onTap: isEditing ? null : () => _goTab(AccountDetailTab.members),
            trailing: MemberAvatarStack(
              members: members,
              size: 28,
              maxVisible: 5,
            ),
          ),
      ],
    );
  }

  /// The สมาชิก tab (and the avatar row) only once there's someone else:
  /// more than one active member, or an invite pending.
  bool _hasMembersTab(Account a) => a.isShared || _pendingInvites.isNotEmpty;

  /// Invites sent and not yet answered (from the members history).
  List<WalletMember> get _pendingInvites => [
    for (final m in widget.members ?? const <WalletMember>[])
      if (m.pending) m,
  ];

  /// The wallet's numbers (spec 15 §5) — what bank slips are matched
  /// against; edited like the splits section (owner 2026-10-11):
  /// - title row: "+ เพิ่มเลข" (edit), the app-wide 👁 (view)
  /// - edit: `[kind · bank ▾] [number] ✕` rows, typed in place
  /// - view: the list; long-press the section → edit mode (owner)
  /// Non-owners only see a list that has something in it.
  Widget? _identifiersSection(AppLocalizations l, {required bool first}) {
    final editing = isEditing;
    final owner = _isOwner;
    final list = working.identifiers;
    if (list.isEmpty && !owner) return null;
    final hidden = !editing && isMoneyHidden(context);
    final section = SectionCard(
      first: first,
      title: l.accountIdentifiersTitle,
      description: l.accountIdentifiersHint,
      trailing: editing
          ? AppChip(
              icon: AppIcons.add,
              label: l.accountIdentifiersAdd,
              tone: AppChipTone.primary,
              selected: true,
              onTap: _addIdentifier,
            )
          // 👁 — the same switch as the money privacy toggle.
          : IdentifiersVisibility(show: list.isNotEmpty),
      children: [
        if (list.isEmpty)
          // Tap: enter edit and add the first number.
          InkWell(
            onTap: () {
              if (!editing) enterEdit();
              _addIdentifier();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: DetailPlaceholder(l.accountIdentifiersEmpty),
            ),
          ),
        for (final (i, id) in list.indexed)
          if (editing)
            IdentifierEditRow(
              key: ValueKey('identifier-$i'),
              identifier: id,
              providers: _providers,
              autofocus: i == _focusIdentifier,
              onChanged: (next) => _changeIdentifier(i, next),
              onRemove: () => _removeIdentifier(i),
            )
          else
            IdentifierRow(
              identifier: id,
              providers: _providers,
              hidden: hidden,
            ),
      ],
    );
    if (editing || !owner) return section;
    return GestureDetector(onLongPress: enterEdit, child: section);
  }

  /// The row just added — its number field takes the focus.
  int? _focusIdentifier;

  /// "+ เพิ่มเลข": an empty account-number row at the end, focused. Left
  /// empty, it's dropped on save.
  void _addIdentifier() {
    final list = working.identifiers;
    _focusIdentifier = list.length;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusIdentifier = null,
    );
    applyChange(
      working.copyWith(
        identifiers: [
          ...list,
          const AccountIdentifier(kind: IdentifierKind.bankAccount, value: ''),
        ],
      ),
    );
  }

  /// Kind / bank changes are one undo step each; typing groups per row.
  void _changeIdentifier(int index, AccountIdentifier next) {
    final list = working.identifiers;
    final current = list[index];
    final updated = working.copyWith(identifiers: [...list]..[index] = next);
    if (current.kind == next.kind && current.bankCode == next.bankCode) {
      applyTextChange(('identifier', index), updated);
    } else {
      applyChange(updated);
    }
  }

  void _removeIdentifier(int index) => applyChange(
    working.copyWith(identifiers: [...working.identifiers]..removeAt(index)),
  );

  /// Card / pay-later billing: read-only rows in view mode (unset ones
  /// hidden), inputs in edit mode.
  List<Widget> _creditRows(AppLocalizations l, String symbol) {
    final w = working;
    if (!isEditing) {
      // The limit is in the hero's bar ("เหลือ x จาก y") — not again here.
      final statementDay = int.tryParse(w.statementDay);
      final dueDay = int.tryParse(w.dueDay);
      final minPayment = AmountInput.parse(w.minPayment);
      return [
        if (statementDay != null)
          DetailRow(
            label: l.accountDetailStatementDate,
            trailing: AppText(dayOfMonthLabel(context, statementDay)),
          ),
        if (dueDay != null)
          DetailRow(
            label: l.accountDetailPaymentDue,
            trailing: AppText(dayOfMonthLabel(context, dueDay)),
          ),
        if (minPayment != null)
          DetailRow(
            label: l.accountDetailMinimumPayment,
            trailing: MoneyText(minPayment, symbol: symbol),
          ),
      ];
    }
    Widget amountRow({
      required String label,
      required TextEditingController controller,
      required _Field field,
      FormFieldValidator<String>? validator,
    }) => DetailRow(
      label: label,
      trailing: SizedBox(
        width: 160,
        child: AppInput(
          controller: controller,
          type: AppInputType.amount,
          dense: true,
          currencySymbol: symbol,
          hint: '0',
          validator: validator,
          onChanged: (v) => _onText(field, v),
        ),
      ),
    );
    return [
      amountRow(
        label: l.accountFormCreditLimitLabel,
        controller: _creditLimitController,
        field: _Field.creditLimit,
        validator: (v) {
          final n = AmountInput.parse(v);
          if (n == null || n <= 0) return l.accountFormCreditLimitRequired;
          return null;
        },
      ),
      _dayRow(
        title: l.accountFormStatementDateLabel,
        value: w.statementDay,
        controller: _statementDayController,
        apply: (v) => working.copyWith(statementDay: v),
      ),
      _dayRow(
        title: l.accountFormPaymentDueLabel,
        value: w.dueDay,
        controller: _dueDayController,
        apply: (v) => working.copyWith(dueDay: v),
      ),
      amountRow(
        label: l.accountFormMinimumPaymentLabel,
        controller: _minPaymentController,
        field: _Field.minPayment,
      ),
      // A warning, not a block: the minimum can't sensibly exceed the
      // limit, but the user knows their card.
      if (_minOverLimit(w))
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: AppMessage(
            tone: Tone.warning,
            message: l.accountMinPaymentOverLimit,
          ),
        ),
    ];
  }

  /// ขั้นต่ำ > วงเงิน (both set).
  static bool _minOverLimit(_AccountDraft w) {
    final limit = AmountInput.parse(w.creditLimit);
    final min = AmountInput.parse(w.minPayment);
    return limit != null && min != null && min > limit;
  }

  /// A billing day as a picker row (`label  value ›`) that opens the kit's
  /// day-of-month grid (1–30, วันสุดท้ายของเดือน = 31, ไม่ระบุ) — no typing,
  /// nothing to validate. The draft keeps the day as text.
  Widget _dayRow({
    required String title,
    required String value,
    required TextEditingController controller,
    required _AccountDraft Function(String) apply,
  }) {
    final day = int.tryParse(value.trim());
    final label = dayOfMonthLabel(context, day);
    return DetailRow.pick(
      label: title,
      value: day == null ? null : label,
      emptyText: label,
      onTap: () async {
        final picked = await showDayOfMonthPicker(
          context,
          title: title,
          selected: day,
        );
        if (picked == null || !mounted) return;
        final text = picked.day == null ? '' : '${picked.day}';
        controller.text = text;
        applyChange(apply(text));
      },
    );
  }

  /// The caller's report scope — live, applies immediately (not part of
  /// the edit; locked while editing). Members moved to the สมาชิก tab.
  Widget _scopeSection(AppLocalizations l, Account a, {required bool first}) {
    final scope = _effectiveScope(a);
    return SectionCard(
      first: first,
      title: l.accountReportSectionTitle,
      description: l.accountReportSectionDescription,
      children: [
        // ≤3 short options → a popover anchored to the row.
        OptionMenuAnchor<WalletReportScope>(
          selected: scope,
          options: [
            for (final s in [
              WalletReportScope.none,
              // "own" only means something with more than one member.
              if (a.isShared) WalletReportScope.own,
              WalletReportScope.all,
            ])
              SheetOption(value: s, label: _scopeLabel(l, s)),
          ],
          onSelected: (picked) {
            if (mounted) _setScope(a, picked);
          },
          builder: (context, toggle) => DetailRow.pick(
            locked: isEditing,
            label: l.walletReportScopeTitle,
            helper: l.walletReportScopeHelper,
            value: _scopeLabel(l, scope),
            emptyText: _scopeLabel(l, scope),
            onTap: _scopeBusy || isEditing ? null : toggle,
          ),
        ),
      ],
    );
  }
}

/// The tab bar, pinned once the hero has scrolled away (the scroll view
/// sits below the top bar, so it pins right under it).
class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  _PinnedTabBar({required this.background, required this.child});

  final Color background;
  final Widget child;

  static const _height = 52.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: child,
        ),
      );

  @override
  bool shouldRebuild(_PinnedTabBar old) => true;
}

// ────────────────────────────────────────────────────────────────────
// Hero — the wallet's card, enlarged, laid out like the transaction hero
// (owner 2026-10-10). View: ✏️ → edit (owner), long-press the icon → edit
// + maker. Edit: tap the icon → maker, the name is an input.
// ────────────────────────────────────────────────────────────────────

///   [type][🔗 แชร์ n คน]                       ✏️
///   (icon)  name
///   ฿12,345
///   credit: ▓▓▓░░ เหลือ x จาก y · 40%
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.account,
    required this.symbol,
    required this.nameField,
    required this.descriptionField,
    this.balanceField,
    this.onEdit,
    this.onIconTap,
    this.onIconLongPress,
    this.showLabels = false,
  });

  /// The draft as a wallet (live preview).
  final Account account;
  final String symbol;
  final Widget nameField;

  /// A `HeroDescription` under the name.
  final Widget descriptionField;

  /// Create: the opening-balance input in place of the balance text; edit /
  /// view keep the read-only balance (it moves only via ปรับยอด).
  final Widget? balanceField;

  /// The ✏️ chip (owner, view mode); null leaves it out (its row keeps
  /// its height, so the card doesn't jump between modes).
  final VoidCallback? onEdit;

  final VoidCallback? onIconTap;
  final VoidCallback? onIconLongPress;

  /// Edit mode: a small ชื่อ / คำอธิบาย label slides in left of each field
  /// (owner 2026-10-10); view mode keeps the bare, label-less header.
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = account.iconCode.tintFor(palette);
    final utilization = account.creditUtilization;
    final available = account.creditAvailable;
    final members = account.members.where((m) => m.isActive).length;
    return AccountCardSurface(
      account: account,
      margin: EdgeInsets.zero,
      glyphSize: 132,
      // The kit's hero spacing (HeroContent / HeroTopRow).
      child: HeroContent(
        rows: [
          // What kind of wallet, and whether it's shared · ✏️ — all one
          // control height.
          HeroTopRow(
            leading: [
              AppChip(
                label: accountTypeLabel(context, account.type),
                icon: account.type.icon,
                color: account.colorOf(context),
                // A status-style chip like the others on the tinted surface (a
                // wallet-group token tint, not an unselected outline).
                selected: true,
              ),
              if (account.isShared)
                AppChip(
                  label: l.accountSharedWith(members),
                  icon: AppIcons.link,
                  color: accent,
                  selected: true,
                ),
            ],
            trailing: [
              if (onEdit != null)
                AppIconButton.edit(
                  size: HeroSpacing.controlHeight,
                  tooltip: l.commonEdit,
                  onPressed: onEdit,
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AccountIconCircle keeps a constant footprint with or
              // without onTap, so nothing shifts between modes.
              AccountIconCircle(
                account: account,
                size: 52,
                onTap: onIconTap,
                onLongPress: onIconLongPress,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EditLabel(
                      label: l.commonName,
                      show: showLabels,
                      child: nameField,
                    ),
                    // View: only when set; edit: always. HeroDescription draws
                    // its own field-name label in edit mode.
                    descriptionField,
                  ],
                ),
              ),
            ],
          ),
          balanceField ??
              MoneyText(
                accountDisplayBalance(account),
                symbol: symbol,
                style: AppTypography.of(
                  context,
                  AppTextRole.display,
                )?.copyWith(color: accountBalanceColor(context, account)),
              ),
          // Used credit only — an overpaid card uses none.
          if (utilization != null && available != null)
            ProgressRow(
              value: utilization,
              color: accent,
              label: l.accountDetailCreditAvailable(
                moneyString(context, available, symbol: symbol),
                moneyString(context, account.creditLimit!, symbol: symbol),
              ),
              trailing: '${(utilization * 100).round()}%',
            ),
        ],
      ),
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
    this.identifiers = const [],
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
  final List<AccountIdentifier> identifiers;

  factory _AccountDraft.from(Account a) => _AccountDraft(
    name: a.name,
    type: a.type,
    iconCode: a.iconCode,
    description: a.description ?? '',
    note: a.note ?? '',
    creditLimit: a.creditLimit == null
        ? ''
        : AmountInput.format(a.creditLimit!),
    statementDay: a.statementDate?.toString() ?? '',
    dueDay: a.paymentDueDate?.toString() ?? '',
    minPayment: a.minimumPayment == null
        ? ''
        : AmountInput.format(a.minimumPayment!),
    identifiers: a.identifiers,
  );

  /// What the server stores (text trimmed) — the post-save baseline.
  /// The numbers to save: rows left empty dropped, repeats once.
  List<AccountIdentifier> get cleanIdentifiers => [
    ...{
      for (final i in identifiers)
        if (i.value.isNotEmpty) i,
    },
  ];

  _AccountDraft trimmed() => copyWith(
    name: name.trim(),
    description: description.trim(),
    note: note.trim(),
    statementDay: statementDay.trim(),
    dueDay: dueDay.trim(),
    identifiers: cleanIdentifiers,
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
    List<AccountIdentifier>? identifiers,
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
      identifiers: identifiers ?? this.identifiers,
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
      other.minPayment == minPayment &&
      listEquals(other.identifiers, identifiers);

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
    Object.hashAll(identifiers),
  );
}

/// A header field with a small label to its left that slides in while
/// editing — the field shifts right instead of the card growing taller.
class _EditLabel extends StatelessWidget {
  const _EditLabel({
    required this.label,
    required this.show,
    required this.child,
  });

  final String label;
  final bool show;
  final Widget child;

  /// Wide enough for "คำอธิบาย" / "Description" at labelMedium, and the
  /// same for both rows so the fields line up.
  static const _width = 76.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: show ? 1 : 0),
      duration: AppDurations.chrome,
      curve: AppDurations.chromeCurve,
      builder: (context, t, field) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _width * t,
            child: Opacity(
              opacity: t,
              child: AppText(
                label,
                role: AppTextRole.caption,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
          Expanded(child: field!),
        ],
      ),
      child: child,
    );
  }
}
