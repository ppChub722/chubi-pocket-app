import 'dart:async';

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
import '../../../transactions/domain/transactions_summary.dart';
import '../../../transactions/presentation/pages/transactions_list_page.dart';
import '../../../transactions/presentation/tx_list_filters.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../../notifications/domain/notification_rows.dart' show AutoSwitch;
import '../../../settings/presentation/widgets/auto_sync_setting.dart'
    show RequestAutoSetting;
import '../../domain/account.dart';
import '../../domain/account_identifier.dart';
import '../../domain/payment_provider.dart';
import '../../domain/account_type.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../cubit/providers_cubit.dart';
import '../widgets/adjust_balance_sheet.dart';
import '../widgets/identifier_widgets.dart';
import '../widgets/wallet_members_view.dart';
import '../widgets/wallet_compact_hero.dart';

enum AccountDetailTab { overview, transactions }

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    this.accountId,
    this.openMembers = false,
    this.popOnCreate = false,
    this.onAddSaving,
    super.key,
  });

  final String? accountId;

  final bool openMembers;

  final bool popOnCreate;

  final VoidCallback? onAddSaving;

  bool get isCreate => accountId == null;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

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

  void _onAccount(Account account) {
    final d = _detail;
    if (d == null) return;
    setState(() => _detail = d.copyWith(account: account));
  }

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

  final bool popOnCreate;

  /// The persisted wallet (fresh from the cubit on every rebuild); null while
  /// creating.
  final Account? account;

  final List<WalletMember>? members;

  final bool openMembers;

  final void Function(Account)? onAccount;

  final void Function(MembersResult)? onMembers;

  final Future<void> Function()? onRefresh;

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

  late final String _currency;

  List<PaymentProvider> _providers = const [];
  StreamSubscription<ProvidersState>? _providersSub;

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
    _period.addListener(_onPeriod);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenMembers());
    final providers = context.read<ProvidersCubit>();
    _providers = providers.state.providers;
    _providersSub = providers.stream.listen((s) {
      if (mounted) setState(() => _providers = s.providers);
    });
    unawaited(providers.loadIfNeeded());
  }

  @override
  void didUpdateWidget(covariant _AccountDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenMembers());
    final a = widget.account;
    if (a != null && a != oldWidget.account) {
      final next = _AccountDraft.from(a);
      if (next != original) resetDraft(next);
      _flows.clear();
      unawaited(_loadFlow(a, _period.value));
    }
  }

  @override
  void dispose() {
    _providersSub?.cancel();
    _txType
      ..removeListener(_onTxType)
      ..dispose();
    _period
      ..removeListener(_onPeriod)
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

  bool get _isOwner => widget.account?.canEdit ?? true;

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

  VoidCallback? _enterOn(FocusNode focus) =>
      _isOwner ? () => enterEdit(focus: focus) : null;

  void _enterEditThenOpenMaker() {
    enterEdit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openIconMaker();
    });
  }

  Account _preview(AppLocalizations l) {
    final w = working;
    final base = widget.account;
    final opening = AmountInput.parse(w.opening) ?? 0;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    return Account(
      id: base?.id ?? 'preview',
      name: w.name.trim().isEmpty ? l.commonName : w.name,
      type: w.type,
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
      trackBalance: base?.trackBalance ?? w.trackBalance,
    );
  }

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

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final preview = _preview(l);
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.account,
      initial: preview.shownIconCode,
      title: l.accountFormIconLabel,
      iconSectionLabel: l.accountFormIconLabel,
      colorSectionLabel: l.accountFormColorLabel,
      removeLabel: l.iconMakerUseDefault,
      previewBuilder: (iconCode) => AccountCard(
        account: preview.copyWith(iconCode: iconCode),
        horizontal: true,
      ),
    );
    if (!mounted) return;
    // "Use default" = back to the type's icon, which then follows the type.
    if (result is IconMakerRemoved) {
      applyChange(working.copyWith(clearIcon: true));
    } else if (result is IconMakerSelected &&
        result.iconCode != preview.shownIconCode) {
      applyChange(working.copyWith(iconCode: result.iconCode));
    }
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
        // explicit nulls.
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
        widget.onAccount?.call(updated);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, errorText(l, e), tone: Tone.danger);
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
      commitSaved(_AccountDraft.from(created));
      context.replace('/accounts/${created.id}');
      return;
    }
    commitSaved(working.trimmed());
  }

  static double _openingBalance(AccountType type, double opening) =>
      opening == 0 ? 0 : (type.isCredit ? -opening : opening);

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
      showAppSnackBar(context, errorText(l, e), tone: Tone.danger);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final a = widget.account!;
    final cubit = context.read<AccountsCubit>();
    final AccountDeletePreview? preview;
    try {
      preview = await cubit.deletePreview(a.id);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, errorText(l, e), tone: Tone.danger);
      }
      return;
    }
    if (!mounted) return;
    if (preview == null) {
      showAppSnackBar(context, l.accountArchiveHasMembers, tone: Tone.warning);
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l.fpWalletDeleteTitle,
      message: l.fpWalletDeleteBody(
        preview.transactions,
        preview.transfers,
        preview.systemRowsDeleted,
        preview.recurring,
        preview.savingEntries,
        moneyString(context, preview.savingAmount),
      ),
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setSaving(true);
    try {
      await cubit.deleteForever(a.id);
      showAppSnackBarOn(messenger, l.fpWalletDeleted, tone: Tone.success);
      router.go('/accounts');
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, errorText(l, e), tone: Tone.danger);
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
      widget.onAccount?.call(outcome.account);
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
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  /// One call; [LiveSetting] shows it at once and puts it back on a failure.
  Future<bool> _setScope(Account a, WalletReportScope scope) async {
    final cubit = context.read<AccountsCubit>();
    final updated = await cubit.setReportScope(accountId: a.id, scope: scope);
    widget.onAccount?.call(updated);
    return true;
  }

  /// Off = one call. On asks the current balance first (closing the sheet
  /// puts the switch back), then sends it with the switch: still one call.
  Future<bool> _setTrack(Account a, bool on) async {
    final cubit = context.read<AccountsCubit>();
    double? balance;
    if (on) {
      balance = await showSetBalanceSheet(context, a);
      if (balance == null || !mounted) return false;
    }
    final updated = await cubit.setTrackBalance(
      a.id,
      on: on,
      currentBalance: balance,
    );
    widget.onAccount?.call(updated);
    return true;
  }

  Future<void> _refresh() async => widget.onRefresh?.call();

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

  final _txType = ValueNotifier<TransactionType?>(null);

  final _period = ValueNotifier<TxPeriod>(TxPeriod.month(DateTime.now()));
  final _flows = <TxPeriod, TransactionsSummary>{};
  final _flowLoading = <TxPeriod>{};

  bool _membersOpened = false;

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

  void _onPeriod() {
    final a = widget.account;
    if (a != null) unawaited(_loadFlow(a, _period.value));
    if (mounted) setState(() {});
  }

  static bool _isThisMonth(TxPeriod p) => p == TxPeriod.month(DateTime.now());

  Future<void> _loadFlow(Account a, TxPeriod p) async {
    if (_isThisMonth(p) || _flows.containsKey(p) || !_flowLoading.add(p)) {
      return;
    }
    final b = p.bounds;
    try {
      final s = await context.read<TransactionsRepository>().summaryForAccount(
        accountId: a.id,
        from: b.from,
        to: b.to,
      );
      if (mounted) setState(() => _flows[p] = s);
    } on ApiException {
      // The row shows "—" for this period; a period change or refresh retries.
    } finally {
      _flowLoading.remove(p);
    }
  }

  /// What came in and went out in [p]; null while it loads or after it failed.
  ({double income, double expense})? _flowOf(Account a, TxPeriod p) {
    if (_isThisMonth(p)) return (income: a.monthIn, expense: a.monthOut);
    final s = _flows[p];
    return s == null ? null : (income: s.totalIncome, expense: s.totalExpense);
  }

  void _toggleTxType(TransactionType t) {
    _txType.value = _txType.value == t ? null : t;
    if (_txType.value != null) _goTab(AccountDetailTab.transactions);
  }

  void _goTab(AccountDetailTab t) => setState(() => _tab = t);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = widget.account;
    final tabs = _tabs;
    if (isEditing || !tabs.contains(_tab)) _tab = AccountDetailTab.overview;
    final page = editScope(
      Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppTopBar(
          title: _title(l),
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        body: Form(
          key: _formKey,
          // Builder: this context sits inside the Scaffold body, so it sees the
          // bar height in its top padding.
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
    return QuickCreatePresetScope(
      preset: QuickCreatePreset(account: a),
      child: page,
    );
  }

  String _tabLabel(AppLocalizations l, AccountDetailTab t) => switch (t) {
    AccountDetailTab.overview => l.accountDetailTabOverview,
    AccountDetailTab.transactions => l.accountDetailTransactionsTitle,
  };

  String _title(AppLocalizations l) =>
      _isCreate ? l.accountFormTitle : widget.account!.name;

  Widget _viewBody(
    AppLocalizations l,
    Account a,
    double barInset,
    double bottom,
  ) {
    final tabs = _tabs;
    final actions = _actionBar(l, a);
    return Padding(
      padding: EdgeInsets.only(top: barInset),
      child: CompactHeroScope(
        heroKey: _heroKey,
        top: PinnedTabBarDelegate.height,
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
            SliverToBoxAdapter(
              child: SizedBox(height: HeroMetrics.of(context).after),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedTabBarDelegate(
                child: AppTabBar<AccountDetailTab>(
                  selected: _tab,
                  onChanged: _goTab,
                  pager: _pages,
                  tabs: [
                    for (final t in tabs)
                      AppTab(
                        value: t,
                        label: _tabLabel(l, t),
                        icon: switch (t) {
                          AccountDetailTab.overview => AppIcons.pie,
                          AccountDetailTab.transactions =>
                            AppIcons.transactions,
                        },
                      ),
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
              AccountDetailTab.transactions => BlocProvider(
                create: (ctx) => TransactionsCubit(
                  repository: ctx.read<TransactionsRepository>(),
                ),
                child: TransactionsListPage(
                  embedded: true,
                  lockedAccount: a,
                  typeFilter: _txType,
                  period: _period,
                ),
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _overviewTab(AppLocalizations l, Account a, double bottom) {
    final gap = SizedBox(height: HeroMetrics.of(context).after);
    return PullToRefresh(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, bottom),
        children: [
          for (final s in [
            _overviewInfo(l, a),
            _savedInSection(l, a),
            _peopleStrip(l, a),
            _settingsSection(l, a),
            NoteSection(
              label: l.commonNote,
              editing: false,
              text: a.note,
              hint: l.commonLongPressToEdit,
              onLongPress: _enterOn(_noteFocus),
            ),
          ])
            if (s != null) ...[gap, s],
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

  Widget? _overviewInfo(AppLocalizations l, Account a) => _infoBox(l, a);

  Widget? _savedInSection(AppLocalizations l, Account a) {
    final buckets = a.savings?.buckets ?? const [];
    if (buckets.isEmpty) return null;
    final symbol = context.readUserCurrencySymbol;
    final accent = a.colorOf(context);
    return SectionCard(
      first: true,
      title: l.fpWalletSavedInTitle,
      description: l.fpWalletSavedInDesc,
      children: [
        for (final b in buckets)
          AppListRow(
            title: b.isGoal ? b.name : l.sgv2SpareTitle,
            leading: IconCodeWidget(
              iconCode: b.isGoal ? b.iconCode : null,
              size: 36,
              fallbackIcon: b.isGoal
                  ? AppIcons.savingGoal
                  : AppIcons.savingDeposit,
              fallbackColor: accent,
            ),
            trailing: ListRowTrailing.value(
              MoneyText(b.amount, symbol: symbol),
            ),
            onTap: () => openPage(
              context,
              b.isGoal && b.id != null
                  ? '/saving-goals/${b.id}'
                  : '/saving-goals/spare',
            ),
          ),
      ],
    );
  }

  EdgeInsets _tabInsets(double bottom) =>
      EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, bottom);

  String _periodLabel(TxPeriod p) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    return switch (p.kind) {
      TxPeriodKind.month when p.start.year == now.year => DateFormat.MMM(
        locale,
      ).format(p.start),
      TxPeriodKind.month => DateFormat.yMMM(locale).format(p.start),
      TxPeriodKind.year => DateFormat.y(locale).format(p.start),
      TxPeriodKind.day => DateFormat.MMMd(locale).format(p.start),
      _ => p.label(context),
    };
  }

  Widget _flowRow(AppLocalizations l, Account a) {
    final p = _period.value;
    final flow = _flowOf(a, p);
    final symbol = context.readUserCurrencySymbol;
    String signed(num v, {required bool negative}) => v == 0
        ? moneyString(context, v, symbol: symbol)
        : signedMoneyString(context, v, negative: negative, symbol: symbol);
    final prev = p.step(-1);
    final next = p.step(1);
    final label = _periodLabel(p);
    return HeroFlowRow(
      incomeLabel: l.fpWalletFlowIn(label),
      expenseLabel: l.fpWalletFlowOut(label),
      income: flow == null ? '—' : signed(flow.income, negative: false),
      expense: flow == null ? '—' : signed(flow.expense, negative: true),
      onPrev: prev == null ? null : () => _period.value = prev,
      onNext: next == null ? null : () => _period.value = next,
      onTapIncome: () => _toggleTxType(TransactionType.income),
      onTapExpense: () => _toggleTxType(TransactionType.expense),
      selected: switch (_txType.value) {
        TransactionType.income => HeroFlowSelection.income,
        TransactionType.expense => HeroFlowSelection.expense,
        _ => HeroFlowSelection.none,
      },
    );
  }

  Widget _viewHero(AppLocalizations l, Account a) {
    final symbol = context.readUserCurrencySymbol;
    final locale = Localizations.localeOf(context).languageCode;
    final savings = a.savings;
    final due = a.dueDateNext;
    final split = _heroBar(l, a, symbol, savings);
    final flow = _flowRow(l, a);
    final members = [
      for (final m in a.members)
        if (m.isActive) m,
    ];
    return AppHeroCard(
      style: accountHeroStyle(context, a),
      content: [
        HeroIdentity(
          icon: AccountIconCircle(
            account: a,
            size: HeroIdentity.iconSize,
            onLongPress: _isOwner ? _enterEditThenOpenMaker : null,
          ),
          name: HeroNameInput(
            editing: false,
            controller: _nameController,
            maxLength: TextLimits.name,
            maxLines: 2,
            onEnterEdit: _isOwner ? _enterOn(_nameFocus) : null,
          ),
          description: HeroDescription(
            controller: _descriptionController,
            editing: false,
            focusNode: _descriptionFocus,
            hint: l.commonDescription,
            maxLength: TextLimits.description,
            onEnterEdit: _enterOn(_descriptionFocus),
          ),
          trailing: _isOwner
              ? CardActionButton(
                  key: const ValueKey('heroEdit'),
                  icon: AppIcons.edit,
                  tooltip: UiConfig.stringsOf(context).edit,
                  onTap: enterEdit,
                )
              : null,
        ),
        if (a.showsBalance)
          HeroNumber(
            label: a.isLiability
                ? l.fpWalletCreditUsedLabel
                : l.fpWalletBalanceLabel,
            value: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: MoneyText(
                a.isLiability ? a.creditUsed : accountDisplayBalance(a),
                symbol: symbol,
              ),
            ),
            color: accountBalanceColor(context, a),
          ),
        ...split,
        if (a.showsBalance && (savings?.savedExceedsBalance ?? false))
          HeroAlert(
            text: l.fpWalletSavedOverAlert(
              moneyString(context, savings!.overBy, symbol: symbol),
            ),
          ),
        if (a.isLiability && due != null && a.daysUntilDue != null)
          HeroAlert(
            text: l.fpWalletDueAlert(
              DateFormatter.short(due, locale: locale),
              a.daysUntilDue!,
            ),
          ),
        flow,
        HeroChipRow(
          chips: [
            AppChip(
              label: accountTypeLabel(context, a.type),
              icon: a.type.icon,
              color: a.colorOf(context),
              selected: true,
            ),
            // Border and text in one colour, like the type chip (owner
            // 2026-10-23): the card's own colour.
            Builder(
              builder: (context) => AppChip(
                label: _scopeChipLabel(l, _effectiveScope(a)),
                color: HeroColors.maybeOf(context)?.accent,
                selected: true,
              ),
            ),
            if (a.isShared)
              MemberChip(members: members, onTap: () => _openMembers(a)),
          ],
        ),
      ],
    );
  }

  String _scopeChipLabel(AppLocalizations l, WalletReportScope s) =>
      switch (s) {
        WalletReportScope.none => l.walletReportScopeNone,
        WalletReportScope.own => l.fpWalletScopeOwnChip,
        WalletReportScope.all => l.walletReportScopeAll,
      };

  /// The split bar and the facts under it that act as its legend; empty when
  /// the wallet has neither savings nor a card limit.
  List<Widget> _heroBar(
    AppLocalizations l,
    Account a,
    String symbol,
    WalletSavings? savings,
  ) {
    if (!a.showsBalance) return const [];
    final usedPct = a.creditUsedPct;
    final left = a.creditAvailable;
    String money(num v) => moneyString(context, v, symbol: symbol);
    // The colors come from the card, so these build inside it.
    Widget inCard(Widget Function(HeroColors hero) build) =>
        Builder(builder: (context) => build(HeroColors.maybeOf(context)!));
    if (usedPct != null && left != null) {
      return [
        inCard(
          (hero) => HeroBar(
            value: (usedPct / 100).clamp(0.0, 1.0),
            color: hero.accent,
            fillLabel: '$usedPct%',
          ),
        ),
        inCard(
          (hero) => HeroFactList(
            facts: [
              HeroFact(
                l.bgFactUsed,
                money(a.creditUsed),
                icon: AppIcons.creditCard,
                iconColor: hero.accent,
              ),
              HeroFact(
                l.fpWalletCardAvailableLabel(money(a.creditLimit!)),
                money(left),
                icon: AppIcons.coin,
                iconColor: hero.muted,
              ),
            ],
          ),
        ),
      ];
    }
    final available = savings?.available;
    if (savings == null || savings.isEmpty || available == null) {
      return const [];
    }
    final over = savings.savedExceedsBalance;
    final total = a.balance;
    if (total <= 0 && !over) return const [];
    Color saved(HeroColors hero) =>
        over ? hero.warning : hero.accent.withValues(alpha: 0.4);
    return [
      inCard(
        (hero) => HeroBar.split(
          parts: [
            (
              total <= 0 ? 0.0 : (available / total).clamp(0.0, 1.0),
              hero.accent,
            ),
            (
              total <= 0 ? 1.0 : (savings.saved / total).clamp(0.0, 1.0),
              saved(hero),
            ),
          ],
        ),
      ),
      inCard(
        (hero) => HeroFactList(
          facts: [
            HeroFact(
              l.fpWalletAvailableLabel,
              money(available),
              icon: AppIcons.coin,
              iconColor: hero.accent,
            ),
            HeroFact(
              l.fpWalletSavedLabel,
              money(savings.saved),
              icon: AppIcons.savings,
              iconColor: saved(hero),
              color: over ? hero.warning : null,
              onTap: () => _goTab(AccountDetailTab.overview),
            ),
          ],
        ),
      ),
    ];
  }

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

  Widget? _infoBox(AppLocalizations l, Account a) {
    final symbol = context.readUserCurrencySymbol;
    final rows = <InfoRow>[
      for (final id in a.identifiers)
        InfoRow(
          label: identifierKindLine(context, id, _providers),
          value: id.formatted,
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

  Widget _settingsSection(AppLocalizations l, Account a) {
    return SettingsSection(
      title: l.settingsTitle,
      description: a.isLiability
          ? l.fpWalletCardSettingsDesc
          : l.fpWalletSettingsDesc,
      children: [
        if (!a.isLiability)
          _isOwner
              ? LiveSetting<bool>(
                  value: a.trackBalance,
                  save: (on) => _setTrack(a, on),
                  failedMessage: (e) => _errorText(l, e),
                  builder: (context, value, onChanged) => SettingToggleRow(
                    label: l.walletTrackLabel,
                    caption: l.walletTrackHelper,
                    value: value,
                    onChanged: onChanged,
                  ),
                )
              : SettingSwitchViewRow(
                  label: l.walletTrackLabel,
                  caption: l.walletTrackHelper,
                  value: a.trackBalance,
                ),
        _scopeRow(l, a),
        const RequestAutoSetting(which: AutoSwitch.acceptWalletInvites),
      ],
    );
  }

  /// Saves at once, in view and edit mode alike: the scope is the viewer's
  /// own setting, not part of the wallet form.
  Widget _scopeRow(AppLocalizations l, Account a) => LiveSetting(
    value: _effectiveScope(a),
    save: (picked) => _setScope(a, picked),
    failedMessage: (e) => _errorText(l, e),
    builder: (context, scope, onChanged) =>
        SettingDropdownRow<WalletReportScope>(
          label: l.walletReportScopeTitle,
          value: _scopeLabel(l, scope),
          selected: scope,
          options: [
            for (final s in [
              WalletReportScope.none,
              if (a.isShared) WalletReportScope.own,
              WalletReportScope.all,
            ])
              SheetOption(value: s, label: _scopeLabel(l, s)),
          ],
          onSelected: onChanged,
        ),
  );

  String _errorText(AppLocalizations l, Object e) =>
      e is ApiException ? errorText(l, e) : l.errorGenericMessage;

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

  Widget _editBody(
    AppLocalizations l,
    Account? a,
    double barInset,
    double bottom,
  ) {
    final preview = _preview(l);
    final w = working;
    return DetailLayout(
      topInset: barInset + AppSpacing.lg,
      bottomInset: bottom,
      hero: KeyedSubtree(
        key: _heroKey,
        child: AppHeroCard(
          style: accountHeroStyle(context, preview),
          mode: _isCreate ? HeroCardMode.create : HeroCardMode.edit,
          content: [
            HeroIdentity(
              icon: AccountIconCircle(
                account: preview,
                size: 44,
                onTap: _openIconMaker,
              ),
              name: HeroNameInput(
                editing: true,
                controller: _nameController,
                focusNode: _nameFocus,
                hint: l.commonName,
                maxLength: TextLimits.name,
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
                hint: l.commonDescription,
                maxLength: TextLimits.description,
                onChanged: (v) => _onText(_Field.description, v),
              ),
            ),
            // Create: the opening balance is typed here, positive for every type
            // (a card: what is owed); the balance can't be edited later — ปรับยอด
            // moves it.
            if (_isCreate && w.trackBalance)
              HeroAmountField(
                controller: _openingController,
                label: l.accountFormBalanceLabel,
                symbol: context.readUserCurrencySymbol,
                onChanged: (v) => _onText(_Field.opening, v),
              ),
          ],
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
                EndZoneAction(
                  kind: EndZoneKind.delete,
                  label: l.fpWalletDeleteLabel,
                  consequence: l.fpWalletDeleteConsequence,
                  onTap: isSaving ? null : _delete,
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

  Widget? _creditBox(AppLocalizations l) {
    if (!working.type.isCredit) return null;
    return SectionCard(
      title: l.accountCreditSectionTitle,
      description: l.accountCreditSectionDescription,
      children: _creditRows(l, context.readUserCurrencySymbol),
    );
  }

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

  Widget? _editInfo(AppLocalizations l) {
    final credit = _creditBox(l);
    final numbers = _identifiersSection(l, first: false);
    final gap = SizedBox(height: HeroMetrics.of(context).after);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _typeCard(l),
        if (credit != null) ...[gap, credit],
        if (numbers != null) ...[gap, numbers],
      ],
    );
  }

  /// Edit: the wallet type is a field with the others below the hero, not a
  /// chip on the hero (owner 2026-10-23).
  Widget _typeCard(AppLocalizations l) {
    final w = working;
    return SectionCard(
      children: [
        AppDetailRow(
          label: l.accountFormTypeLabel,
          trailing: OptionMenuAnchor<AccountType>(
            selected: w.type,
            onSelected: (t) => applyChange(w.copyWith(type: t)),
            options: [
              for (final t in AccountType.values)
                SheetOption(
                  value: t,
                  label: accountTypeLabel(context, t),
                  leading: AppIcon(t.icon, color: t.iconDefault.color),
                ),
            ],
            builder: (context, toggle) => AppChip(
              label: accountTypeLabel(context, w.type),
              icon: w.type.icon,
              color: w.type.iconDefault.color,
              selected: true,
              trailing: AppChipTrailing.dropdown,
              onTap: toggle,
            ),
          ),
        ),
      ],
    );
  }

  bool _hasMembersTab(Account a) => a.isShared || _pendingInvites.isNotEmpty;

  List<WalletMember> get _pendingInvites => [
    for (final m in widget.members ?? const <WalletMember>[])
      if (m.pending) m,
  ];

  Widget? _identifiersSection(AppLocalizations l, {required bool first}) {
    final editing = isEditing;
    final owner = _isOwner;
    final list = working.identifiers;
    if (list.isEmpty && !owner) return null;
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
          : IdentifiersVisibility(show: list.isNotEmpty),
      children: [
        if (list.isEmpty)
          DetailAddRow(
            label: l.accountIdentifiersAdd,
            onTap: () {
              if (!editing) enterEdit();
              _addIdentifier();
            },
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
            IdentifierRow(identifier: id, providers: _providers),
      ],
    );
    if (editing || !owner) return section;
    return GestureDetector(onLongPress: enterEdit, child: section);
  }

  int? _focusIdentifier;

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

  List<Widget> _creditRows(AppLocalizations l, String symbol) {
    final w = working;
    if (!isEditing) {
      final statementDay = int.tryParse(w.statementDay);
      final dueDay = int.tryParse(w.dueDay);
      final minPayment = AmountInput.parse(w.minPayment);
      return [
        if (statementDay != null)
          AppDetailRow(
            label: l.accountDetailStatementDate,
            trailing: AppText(dayOfMonthLabel(context, statementDay)),
          ),
        if (dueDay != null)
          AppDetailRow(
            label: l.accountDetailPaymentDue,
            trailing: AppText(dayOfMonthLabel(context, dueDay)),
          ),
        if (minPayment != null)
          AppDetailRow(
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
    }) => AppDetailRow(
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
      // A warning, not a block: the minimum can't sensibly exceed the limit,
      // but the user knows their card.
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

  static bool _minOverLimit(_AccountDraft w) {
    final limit = AmountInput.parse(w.creditLimit);
    final min = AmountInput.parse(w.minPayment);
    return limit != null && min != null && min > limit;
  }

  Widget _dayRow({
    required String title,
    required String value,
    required TextEditingController controller,
    required _AccountDraft Function(String) apply,
  }) {
    final day = int.tryParse(value.trim());
    final label = dayOfMonthLabel(context, day);
    return AppDetailRow.pick(
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

  final String opening;
  final String creditLimit;
  final String statementDay;
  final String dueDay;
  final String minPayment;
  final List<AccountIdentifier> identifiers;

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
    bool clearIcon = false,
  }) {
    return _AccountDraft(
      name: name ?? this.name,
      type: type ?? this.type,
      iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
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
