import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
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
import '../widgets/adjust_balance_sheet.dart';
import '../widgets/identifier_widgets.dart';
import '../widgets/wallet_members_view.dart';
import '../widgets/wallet_compact_hero.dart';
import '../widgets/wallet_savings_section.dart';

/// The wallet page's tabs.
enum AccountDetailTab { overview, transactions }

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
    this.openMembers = false,
    this.popOnCreate = false,
    this.onAddSaving,
    super.key,
  });

  /// Null = create a new wallet.
  final String? accountId;

  /// Open the member actions sheet once the members are loaded (the
  /// `/accounts/:id/members` link).
  final bool openMembers;

  /// Create pushed over a picker (Navigator, not the router): saving pops
  /// with the new [Account] instead of becoming its view, so the page
  /// underneath stays (QA W2).
  final bool popOnCreate;

  /// Overrides what the wallet bar's "เพิ่มเงินออม" does (default: quick create
  /// in ออม mode on this wallet).
  final VoidCallback? onAddSaving;

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
            openMembers: widget.openMembers,
            onAccount: _onAccount,
            onMembers: _onMembers,
            onRefresh: _fetch,
            onAddSaving: widget.onAddSaving,
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
    this.openMembers = false,
    this.popOnCreate = false,
    this.onAccount,
    this.onMembers,
    this.onRefresh,
    this.onAddSaving,
  });

  /// See [AccountDetailPage.popOnCreate].
  final bool popOnCreate;

  /// The persisted wallet (fresh from the cubit on every rebuild); null
  /// while creating.
  final Account? account;

  /// The whole membership (`members_history`: active, pending, left); null
  /// until the page's detail call lands.
  final List<WalletMember>? members;

  /// Open the member actions sheet once the members are loaded (the
  /// `/accounts/:id/members` link).
  final bool openMembers;

  /// A write returned the wallet — the page keeps its copy in step.
  final void Function(Account)? onAccount;

  /// A members action returned the wallet + members list.
  final void Function(MembersResult)? onMembers;

  /// Pull-to-refresh: the page's one detail call again.
  final Future<void> Function()? onRefresh;

  /// See [AccountDetailPage.onAddSaving].
  final VoidCallback? onAddSaving;

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
    }
    onDraftRestored();
    _txType.addListener(_onTxType);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenMembers());
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenMembers());
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
    _txType
      ..removeListener(_onTxType)
      ..dispose();
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
      // Edit: the saved state (the switch applies on save); create: live.
      trackBalance: base?.trackBalance ?? w.trackBalance,
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

    // Edit: tracking turned back on asks the balance ONCE, before saving; it
    // goes in the same update call. Cancelling the sheet cancels the save.
    double? currentBalance;
    final prev = widget.account;
    if (prev != null && !prev.trackBalance && w.trackBalance) {
      currentBalance = await showSetBalanceSheet(context, prev);
      if (currentBalance == null || !mounted) return;
    }

    FocusScope.of(context).unfocus();
    setSaving(true);
    Account? created;
    try {
      if (_isCreate) {
        final opening = w.trackBalance
            ? (AmountInput.parse(w.opening) ?? 0)
            : 0.0;
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
            trackBalance: w.trackBalance,
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
            trackBalance: w.trackBalance,
            minimumPayment: minPayment,
            members: p.members,
            myReportScope: p.myReportScope,
            isShared: p.isShared,
            identifiers: w.cleanIdentifiers,
          ),
          currentBalance: currentBalance,
        );
        // A balance given = an adjustment was booked: the lists catch up.
        if (currentBalance != null) await TransactionsCubit.bookChanged();
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

  final PageController _pages = PageController();
  AccountDetailTab _tab = AccountDetailTab.overview;

  List<AccountDetailTab> get _tabs => const [
    AccountDetailTab.overview,
    AccountDetailTab.transactions,
  ];

  /// The month tiles filter the รายการ tab by type (null = all); a second
  /// tap on the same tile clears it.
  final _txType = ValueNotifier<TransactionType?>(null);

  bool _membersOpened = false;

  /// The members link: the sheet opens once, as soon as the members are here.
  void _maybeOpenMembers() {
    final a = widget.account;
    if (!mounted || _membersOpened || !widget.openMembers) return;
    if (a == null || widget.members == null) return;
    _membersOpened = true;
    _openMembers(a);
  }

  void _onTxType() {
    if (mounted) setState(() {});
  }

  void _toggleTxType(TransactionType t) {
    _txType.value = _txType.value == t ? null : t;
    if (_txType.value != null) _goTab(AccountDetailTab.transactions);
  }

  void _goTab(AccountDetailTab t) => setState(() => _tab = t);

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = widget.account;
    final tabs = _tabs;
    // Edit mode is its own form (no tabs).
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
              if (a == null || isEditing) {
                return _editBody(l, a, barInset, bottom);
              }
              return _viewBody(l, a, barInset, bottom);
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
  };

  /// Titles never change with the mode (owner, QA T1): the wallet's name in
  /// view and edit alike — the action bar shows it's edit mode.
  String _title(AppLocalizations l) =>
      _isCreate ? l.accountFormTitle : widget.account!.name;

  // ── View mode ───────────────────────────────────────────────────────

  /// hero → actions → swipe tabs [ภาพรวม · รายการ (· สมาชิก when shared)].
  /// The hero (+ actions) scrolls away; the tab bar pins under the top bar;
  /// the kit's compact bar floats under it once the hero is gone.
  Widget _viewBody(
    AppLocalizations l,
    Account a,
    double barInset,
    double bottom,
  ) {
    final tabs = _tabs;
    final scheme = Theme.of(context).colorScheme;
    final actions = _actionBar(l, a);
    return Padding(
      padding: EdgeInsets.only(top: barInset),
      child: CompactHeroScope(
        heroKey: _heroKey,
        top: _PinnedTabBar._height,
        bar: walletCompactHero(context, a, onTap: _scrollToHero),
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
                child: KeyedSubtree(key: _heroKey, child: _viewHero(l, a)),
              ),
            ),
            if (actions != null) SliverToBoxAdapter(child: actions),
            // 16 from the hero to the tabs (HeroSpacing.after).
            const SliverToBoxAdapter(
              child: SizedBox(height: HeroSpacing.after),
            ),
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
            builder: (context, t) => switch (t) {
              AccountDetailTab.overview => _overviewTab(l, a, bottom),
              // The full list — search, filters, paging — on its own cubit,
              // so the global one isn't narrowed.
              AccountDetailTab.transactions => BlocProvider(
                create: (ctx) => TransactionsCubit(
                  repository: ctx.read<TransactionsRepository>(),
                ),
                child: TransactionsListPage(
                  embedded: true,
                  lockedAccount: a,
                  typeFilter: _txType,
                ),
              ),
            },
          ),
        ),
      ),
    );
  }

  /// ภาพรวม: info (one box) → การตั้งค่า → สมาชิก → บันทึก → meta, then the
  /// page dots at the end of the content.
  Widget _overviewTab(AppLocalizations l, Account a, double bottom) {
    return PullToRefresh(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, bottom),
        children: [
          DetailSections(
            info: _overviewInfo(l, a),
            settings: _settingsSection(l, a),
            people: _peopleStrip(l, a),
            note: NoteSection(
              label: l.commonNote,
              editing: false,
              text: a.note,
              hint: l.commonLongPressToEdit,
              onLongPress: _enterOn(_noteFocus),
            ),
          ),
          DetailMeta(
            lines: detailMetaLines(
              context,
              createdAt: a.createdAt,
              updatedAt: a.updatedAt,
            ),
          ),
          const PageDotsFooter(),
        ],
      ),
    );
  }

  /// The facts box, then — when something is saved here — the savings by
  /// goal + spare (owner: the wallet page shows saved per goal).
  Widget? _overviewInfo(AppLocalizations l, Account a) {
    final info = _infoBox(l, a);
    if (!WalletSavingsSection.shows(a)) return info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?info,
        if (info != null) const SizedBox(height: HeroSpacing.after),
        WalletSavingsSection(account: a, first: true),
      ],
    );
  }

  /// A tab's list padding under the pinned tab bar.
  EdgeInsets _tabInsets(double bottom) =>
      EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, bottom);

  /// The wallet's hero card (reference §6): type · reference · shared chips,
  /// icon + description, the balance (a card: the debt), the split / limit
  /// bar, the month's in / out tiles (a card: the due-date alert).
  Widget _viewHero(AppLocalizations l, Account a) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = a.iconCode.tintFor(palette, fallback: a.colorOf(context));
    final symbol = context.readUserCurrencySymbol;
    final locale = Localizations.localeOf(context).languageCode;
    final ref = a.identifiers.isEmpty ? null : a.identifiers.first;
    final members = a.members.where((m) => m.isActive).length;
    final month = DateFormat.MMM(locale).format(DateTime.now());
    final savings = a.savings;
    final due = a.dueDateNext;
    return HeroCard(
      style: accountHeroStyle(context, a),
      chips: [
        AppChip(
          label: accountTypeLabel(context, a.type),
          icon: a.type.icon,
          color: a.colorOf(context),
          selected: true,
        ),
        if (ref != null) AppChip(label: ref.masked),
        if (a.isShared)
          AppChip(
            label: l.accountSharedWith(members),
            icon: AppIcons.link,
            color: accent,
            selected: true,
          ),
      ],
      onEdit: _isOwner ? enterEdit : null,
      icon: AccountIconCircle(
        account: a,
        size: 40,
        onLongPress: _isOwner ? _enterEditThenOpenMaker : null,
      ),
      description: HeroDescription(
        controller: _descriptionController,
        editing: false,
        focusNode: _descriptionFocus,
        hint: l.accountFormDescriptionExample,
        maxLength: TextLimits.description,
        onEnterEdit: _enterOn(_descriptionFocus),
      ),
      number: a.showsBalance
          ? HeroNumber(
              label: a.isLiability
                  ? l.accountsSummaryCardDebt
                  : l.fpWalletBalanceLabel,
              value: MoneyText(
                a.isLiability ? a.creditUsed : accountDisplayBalance(a),
                symbol: symbol,
              ),
              color: accountBalanceColor(context, a),
            )
          : AppText(l.walletTrackOffHero, role: AppTextRole.caption),
      bar: _heroBar(l, a, accent, symbol, savings),
      tiles: a.isLiability || !a.trackBalance
          ? const []
          : [
              SummaryTileView(
                tile: SummaryTile(
                  label: l.fpWalletMonthIn(month),
                  value: '+${moneyString(context, a.monthIn, symbol: symbol)}',
                  tone: SummaryTileTone.green,
                  selected: _txType.value == TransactionType.income,
                  onTap: () => _toggleTxType(TransactionType.income),
                ),
              ),
              SummaryTileView(
                tile: SummaryTile(
                  label: l.fpWalletMonthOut(month),
                  value: '−${moneyString(context, a.monthOut, symbol: symbol)}',
                  tone: SummaryTileTone.red,
                  selected: _txType.value == TransactionType.expense,
                  onTap: () => _toggleTxType(TransactionType.expense),
                ),
              ),
            ],
      alert: a.isLiability && due != null && a.daysUntilDue != null
          ? HeroAlert(
              text: l.fpWalletDueAlert(
                DateFormatter.short(due, locale: locale),
                a.daysUntilDue!,
              ),
            )
          : null,
    );
  }

  /// Row D: a card's used-of-limit bar, or a wallet's ใช้ได้ / ออมไว้ split.
  Widget? _heroBar(
    AppLocalizations l,
    Account a,
    Color accent,
    String symbol,
    WalletSavings? savings,
  ) {
    if (!a.showsBalance) return null;
    final usedPct = a.creditUsedPct;
    final left = a.creditAvailable;
    if (usedPct != null && left != null) {
      return HeroBar(
        value: (usedPct / 100).clamp(0.0, 1.0),
        color: accent,
        left: l.fpWalletCardUsed(
          usedPct,
          moneyString(context, a.creditLimit!, symbol: symbol),
        ),
        right: l.fpWalletCardLeft(moneyString(context, left, symbol: symbol)),
      );
    }
    final available = savings?.available;
    if (savings == null || savings.isEmpty || available == null) return null;
    final total = a.balance;
    if (total <= 0) return null;
    return HeroBar.split(
      parts: [
        ((available / total).clamp(0.0, 1.0), accent),
        (
          (savings.saved / total).clamp(0.0, 1.0),
          accent.withValues(alpha: 0.4),
        ),
      ],
      left: l.fpWalletAvailableLegend(
        moneyString(context, available, symbol: symbol),
      ),
      right: l.fpWalletSavedLegend(
        moneyString(context, savings.saved, symbol: symbol),
      ),
    );
  }

  /// Under the card: a bank-like wallet gets ปรับยอด + ออม, a card gets
  /// ชำระบัตร + ปรับยอด. รายการ / โอน are the bottom +'s job. Null with
  /// fewer than two actions (a wallet that doesn't track its balance).
  Widget? _actionBar(AppLocalizations l, Account a) {
    if (!a.trackBalance) return null;
    final adjust = ActionBarItem(
      label: l.accountDetailAdjustBalance,
      icon: AppIcons.refresh,
      onPressed: _adjustBalance,
    );
    final items = a.isLiability
        ? [
            ActionBarItem(
              label: l.fpWalletPayCard,
              icon: AppIcons.creditCard,
              primary: true,
              onPressed: () => showQuickCreateSheet(
                context,
                toAccount: a,
                type: TransactionType.transfer,
              ),
            ),
            adjust,
          ]
        : [
            adjust,
            ActionBarItem(
              label: l.fpWalletSave,
              icon: AppIcons.savingDeposit,
              onPressed:
                  widget.onAddSaving ??
                  () => showQuickCreateSheet(
                    context,
                    account: a,
                    preset: const QuickCreatePreset.saving(),
                  ),
            ),
          ];
    return ActionBar(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      actions: items,
    );
  }

  /// ภาพรวม's one box of facts: the reference numbers (slips), a card's
  /// limit / due day / statement day / minimum. Null when there is nothing.
  Widget? _infoBox(AppLocalizations l, Account a) {
    final symbol = context.readUserCurrencySymbol;
    final hidden = isMoneyHidden(context);
    final rows = <InfoRow>[
      for (final id in a.identifiers)
        InfoRow(
          label: identifierKindLine(context, id, _providers),
          value: hidden ? id.masked : id.formatted,
        ),
      if (a.isLiability) ...[
        if (a.creditLimit != null)
          InfoRow(
            label: l.accountFormCreditLimitLabel,
            value: moneyString(context, a.creditLimit!, symbol: symbol),
          ),
        if (a.paymentDueDate != null)
          InfoRow(
            label: l.accountDetailPaymentDue,
            value: dayOfMonthLabel(context, a.paymentDueDate),
          ),
        if (a.statementDate != null)
          InfoRow(
            label: l.accountDetailStatementDate,
            value: dayOfMonthLabel(context, a.statementDate),
          ),
        if (a.minimumPayment != null)
          InfoRow(
            label: l.accountDetailMinimumPayment,
            value: moneyString(context, a.minimumPayment!, symbol: symbol),
          ),
      ],
    ];
    if (rows.isEmpty) return null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _isOwner ? enterEdit : null,
      child: InfoBox(rows: rows),
    );
  }

  /// การตั้งค่า: ติดตามยอดเงิน (a live switch is edit-only for now: turning
  /// it back on asks the balance on save) and ในรายงานของฉัน (live).
  Widget _settingsSection(AppLocalizations l, Account a) {
    return SettingsSection(
      title: l.settingsTitle,
      description: a.isLiability
          ? l.fpWalletCardSettingsDesc
          : l.fpWalletSettingsDesc,
      children: [
        if (!a.isLiability)
          SettingSummaryRow(
            label: l.walletTrackLabel,
            summary: a.trackBalance ? null : l.fpWalletTrackOff,
            onTap: _isOwner ? enterEdit : null,
          ),
        _scopeRow(l, a),
      ],
    );
  }

  /// The caller's report scope — live, applies immediately (not part of
  /// the edit).
  Widget _scopeRow(AppLocalizations l, Account a) {
    final scope = _effectiveScope(a);
    return OptionMenuAnchor<WalletReportScope>(
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
      builder: (context, toggle) => SettingSummaryRow(
        label: l.walletReportScopeTitle,
        summary: _scopeLabel(l, scope),
        onTap: _scopeBusy ? null : toggle,
      ),
    );
  }

  /// สมาชิก as the events' member strip: me (owner crown) + the others, and
  /// a ＋ เชิญ card for the owner.
  Widget? _peopleStrip(AppLocalizations l, Account a) {
    final members = [for (final m in a.members) m, ..._pendingInvites];
    final solo = !_hasMembersTab(a);
    if (solo && !_isOwner) return null;
    return PeopleStrip(
      title: l.walletMembersTitle,
      description: l.accountMembersSectionDescription,
      members: [
        for (final m in members)
          PeopleStripMember(
            avatar: MemberAvatarStack(members: [m], size: 36, maxVisible: 1),
            name: m.name,
            caption: m.isMe ? l.fpWalletOwnerCaption : l.fpWalletMemberCaption,
          ),
      ],
      inviteLabel: l.fpWalletInviteLabel,
      onInvite: _isOwner
          ? () => inviteWalletMember(
              context,
              account: a,
              members: widget.members ?? members,
              onResult: (r) => widget.onMembers?.call(r),
            )
          : null,
      onMemberTap: widget.members == null ? null : (_) => _openMembers(a),
    );
  }

  /// A member card → the member actions (role / remove / leave / history)
  /// in a sheet; an action closes it and the page patches from its answer.
  Future<void> _openMembers(Account a) async {
    final members = widget.members;
    if (members == null) return;
    final cubit = context.read<AccountsCubit>();
    await showAppSheetCustom<void>(
      context,
      builder: (sheetContext) => BlocProvider<AccountsCubit>.value(
        value: cubit,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: WalletMembersView(
            account: a,
            members: members,
            onRefresh: _refresh,
            padding: _tabInsets(AppSpacing.lg),
            onResult: (r) {
              widget.onMembers?.call(r);
              Navigator.of(sheetContext).pop();
            },
          ),
        ),
      ),
    );
  }

  // ── Edit / create mode ──────────────────────────────────────────────

  /// Edit mode is its own form (reference §0): the card keeps only the
  /// editable bits (type ▾, icon, name, description, and the opening balance
  /// while creating); then ONE box of numbers / card terms, the settings, the
  /// note and the end zone.
  Widget _editBody(
    AppLocalizations l,
    Account? a,
    double barInset,
    double bottom,
  ) {
    final preview = _preview(l);
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = preview.iconCode.tintFor(
      palette,
      fallback: preview.colorOf(context),
    );
    final w = working;
    return DetailLayout(
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      hero: KeyedSubtree(
        key: _heroKey,
        child: HeroCard(
          style: accountHeroStyle(context, preview),
          editing: true,
          chips: [
            OptionMenuAnchor<AccountType>(
              selected: w.type,
              onSelected: (t) => applyChange(w.copyWith(type: t)),
              options: [
                for (final t in AccountType.values)
                  SheetOption(
                    value: t,
                    label: accountTypeLabel(context, t),
                    leading: AppIcon(t.icon),
                  ),
              ],
              builder: (context, toggle) => AppChip(
                label: accountTypeLabel(context, w.type),
                icon: w.type.icon,
                color: w.type.colorOf(context),
                selected: true,
                trailing: AppChipTrailing.dropdown,
                onTap: toggle,
              ),
            ),
          ],
          icon: AccountIconCircle(
            account: preview,
            size: 44,
            onTap: _openIconMaker,
          ),
          name: HeroNameInput(
            editing: true,
            controller: _nameController,
            focusNode: _nameFocus,
            hint: l.accountFormNameExample,
            maxLength: TextLimits.name,
            maxLines: 2,
            onChanged: (v) => _onText(_Field.name, v),
            validator: (v) {
              final name = v?.trim() ?? '';
              if (name.isEmpty) return l.accountFormNameRequired;
              if (name.length > TextLimits.name) {
                return l.accountFormNameTooLong;
              }
              return null;
            },
          ),
          description: HeroDescription(
            controller: _descriptionController,
            editing: true,
            focusNode: _descriptionFocus,
            hint: l.accountFormDescriptionExample,
            maxLength: TextLimits.description,
            onChanged: (v) => _onText(_Field.description, v),
          ),
          // Create: the opening balance is typed here, positive for every
          // type (a card: what is owed); the balance can't be edited later —
          // ปรับยอด moves it.
          amountField: _isCreate && w.trackBalance
              ? HeroAmountField(
                  controller: _openingController,
                  label: l.accountFormBalanceLabel,
                  accent: accent,
                  symbol: context.readUserCurrencySymbol,
                  onChanged: (v) => _onText(_Field.opening, v),
                )
              : null,
        ),
      ),
      info: _editInfo(l),
      settings: _editSettings(l, a),
      note: NoteSection(
        label: l.commonNote,
        editing: true,
        controller: _noteController,
        maxLength: TextLimits.note,
        editField: DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: true,
            controller: _noteController,
            focusNode: _noteFocus,
            maxLines: 3,
            maxLength: TextLimits.note,
            hint: l.accountFormNoteHelper,
            onChanged: (v) => _onText(_Field.note, v),
          ),
        ),
      ),
      endZone: a == null || !_isOwner
          ? null
          : EndZone(
              actions: [
                EndZoneAction(
                  kind: EndZoneKind.archive,
                  label: l.accountDetailArchive,
                  consequence: l.fpWalletArchiveConsequence,
                  onTap: isSaving ? null : _archive,
                ),
              ],
            ),
      metaLines: a == null
          ? const []
          : detailMetaLines(
              context,
              createdAt: a.createdAt,
              updatedAt: a.updatedAt,
            ),
    );
  }

  /// A card's terms (limit, statement + due day, minimum) in ONE box; null
  /// for the other types.
  Widget? _creditBox(AppLocalizations l) {
    if (!working.type.isCredit) return null;
    return SectionCard(
      title: l.accountCreditSectionTitle,
      description: l.accountCreditSectionDescription,
      children: _creditRows(l, context.readUserCurrencySymbol),
    );
  }

  /// ติดตามยอดเงิน (owner) + ในรายงานของฉัน (existing wallet, live).
  Widget? _editSettings(AppLocalizations l, Account? a) {
    final children = <Widget>[
      if (_isOwner)
        SettingToggleRow(
          label: l.walletTrackLabel,
          caption: l.walletTrackHelper,
          value: working.trackBalance,
          submits: false,
          onChanged: (v) => applyChange(working.copyWith(trackBalance: v)),
        ),
      if (a != null) _scopeRow(l, a),
    ];
    if (children.isEmpty) return null;
    return SettingsSection(
      title: l.settingsTitle,
      description: working.type.isCredit
          ? l.fpWalletCardSettingsDesc
          : l.fpWalletSettingsDesc,
      children: children,
    );
  }

  /// A card's terms box, then the reference numbers (slips) — both headed
  /// boxes, in the info slot.
  Widget? _editInfo(AppLocalizations l) {
    final credit = _creditBox(l);
    final numbers = _identifiersSection(l, first: false);
    if (credit == null) return numbers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        credit,
        if (numbers != null) ...[
          const SizedBox(height: HeroSpacing.after),
          numbers,
        ],
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
    this.trackBalance = true,
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

  /// "ติดตามยอดเงิน" ([Account.trackBalance]).
  final bool trackBalance;

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
    trackBalance: a.trackBalance,
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
    bool? trackBalance,
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
      trackBalance: trackBalance ?? this.trackBalance,
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
      other.trackBalance == trackBalance &&
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
    trackBalance,
  );
}
