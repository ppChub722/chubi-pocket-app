import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../pending/presentation/pending_errors.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import 'account_picker_sheet.dart';
import 'event_section.dart' show quickCreateErrorMessage;
import 'splits_section.dart';

/// The `+` quick create (owner design 2026-10-08). A near-full-height sheet
/// — never a new page:
///
///   type · big amount · recent-category chips · wallet + date · note
///   ── รายละเอียดเพิ่ม (visible, scroll for more) ──
///   tags · หารกับ… · เพิ่มเข้าอีเวนต์
///
/// Save sits pinned above the keyboard. Scrolling past the amount slides
/// in a compact summary (type · amount · category) at the top; tap it to
/// scroll back. Closing with anything entered asks first.
///
/// Defaults: the last wallet used (else the first), today, and the 6
/// categories used most recently for the type. "เพิ่มเข้าอีเวนต์" files the
/// bill into a new event or an existing one (POST /projects/quick or
/// /projects/:id/bills). "บันทึกร่าง" parks it in รอยืนยัน instead.
///
/// With [draft] the same sheet edits a pending draft (title "แก้ร่าง"):
/// "บันทึกร่าง" saves it back, "ยืนยันรายการนี้" submits it, "ทิ้ง" removes
/// it; the event tile is hidden (drafts don't go to events).
///
/// Returns true when something was saved.
Future<bool> showQuickCreateSheet(BuildContext context,
    {PendingTransaction? draft}) async {
  context.read<AccountsCubit>().loadIfNeeded();
  context.read<CategoriesCubit>().loadIfNeeded();
  context.read<TagsCubit>().loadIfNeeded();
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Drag-to-dismiss would skip the "discard?" question; the ✕, the
    // barrier and back all go through PopScope instead.
    enableDrag: false,
    builder: (_) => _QuickCreateSheet(prefs: prefs, draft: draft),
  );
  return saved ?? false;
}

// ── Remembered defaults ───────────────────────────────────────────────

const _kLastAccount = 'quick.last_account_id';
String _kRecent(CategoryType t) => 'quick.recent_categories.${t.name}';
const _recentMax = 6;

enum _CloseChoice { draft, keepEditing, discard }

/// Where "เพิ่มเข้าอีเวนต์" files the bill.
sealed class _EventTarget {
  const _EventTarget();
}

class _NewEvent extends _EventTarget {
  const _NewEvent(this.name);
  final String name;
}

class _ExistingEvent extends _EventTarget {
  const _ExistingEvent(this.project);
  final Project project;
}

class _QuickCreateSheet extends StatefulWidget {
  const _QuickCreateSheet({required this.prefs, this.draft});
  final SharedPreferences prefs;

  /// Editing this pending draft instead of creating.
  final PendingTransaction? draft;

  @override
  State<_QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<_QuickCreateSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _scroll = ScrollController();

  TransactionType _type = TransactionType.expense;
  Category? _category;
  Account? _account;
  Account? _toAccount;
  bool _accountTouched = false;
  DateTime _date = DateTime.now();
  final Set<String> _tagIds = {};
  List<SplitDraft> _splits = const [];
  _EventTarget? _event;
  bool _saving = false;

  /// Scrolled past the amount → show the compact summary bar.
  bool _collapsed = false;
  static const _collapseAt = 170.0;

  bool get _isTransfer => _type == TransactionType.transfer;
  double get _amountValue => AmountField.parse(_amount.text) ?? 0;

  bool get _editingDraft => widget.draft != null;

  bool get _dirty => _editingDraft
      ? _currentDraft() != widget.draft!.draft
      : _amount.text.isNotEmpty ||
          _note.text.trim().isNotEmpty ||
          _tagIds.isNotEmpty ||
          _splits.any((s) => s.isComplete) ||
          _event != null;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > _collapseAt;
      if (c != _collapsed) setState(() => _collapsed = c);
    });
    final p = widget.draft;
    if (p != null) _prefill(p.draft);
  }

  /// Loads a pending draft into the fields (wallet "none" stays none).
  void _prefill(PendingDraft d) {
    final accounts = context.read<AccountsCubit>().state.accounts;
    final categories = context.read<CategoriesCubit>().state.categories;
    _type = d.type ?? TransactionType.expense;
    final amount = d.amount;
    if (amount != null && amount > 0) _amount.text = AmountField.format(amount);
    _note.text = d.note ?? '';
    _date = DateTime.tryParse(d.date ?? '') ?? _date;
    _accountTouched = true;
    _account = accounts.where((a) => a.id == d.accountId).firstOrNull;
    _toAccount = accounts.where((a) => a.id == d.transferToAccountId).firstOrNull;
    _category = categories.where((c) => c.id == d.categoryId).firstOrNull;
    _tagIds.addAll(d.tagIds);
    _splits = [
      for (final s in d.splits)
        SplitDraft(
          personName: s['person_name'] as String?,
          contactId: s['contact_id'] as String?,
          owedAmount: (s['owed_amount'] as num?)?.toDouble(),
        ),
    ];
  }

  /// The fields as a draft — no validation, anything may be empty.
  PendingDraft _currentDraft() {
    final amount = AmountField.parse(_amount.text);
    final note = _note.text.trim();
    return PendingDraft(
      type: _type,
      amount: amount,
      accountId: _account?.id,
      categoryId: _isTransfer ? null : _category?.id,
      date: _ymd(_date),
      note: note.isEmpty ? null : note,
      transferToAccountId: _isTransfer ? _toAccount?.id : null,
      tagIds: _tagIds.toList(),
      splits: _isTransfer
          ? const []
          : [for (final s in _splits.where((s) => s.isComplete)) s.toJson()],
    );
  }

  /// "บันทึกร่าง": park it in รอยืนยัน (new) or save the edits back.
  Future<void> _saveDraft() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final d = _currentDraft();
      final p = widget.draft;
      if (p == null) {
        await pending.add([d]);
      } else {
        await pending.updateDraft(p.id, d);
      }
      await _remember();
      navigator.pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.pendingSavedAsDraft)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  /// Draft mode "ยืนยันรายการนี้": save the edits, then submit just this one.
  Future<void> _submitDraft() async {
    final l = AppLocalizations.of(context)!;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.draft!.id;
    setState(() => _saving = true);
    try {
      await pending.updateDraft(id, _currentDraft());
      final result = await pending.submit([id]);
      final failed = result.failed[id];
      if (failed != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(pendingErrorText(l, failed));
        return;
      }
      await Future.wait([accounts.load(), txCubit.load()]);
      await _remember();
      navigator.pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.quickSaved)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  /// Draft mode "ทิ้ง".
  Future<void> _discardDraft() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l.pendingDiscardTitle,
      confirmLabel: l.quickDiscardConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await pending.discard(widget.draft!.id);
      navigator.pop(true);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Wallet default: the one used last, else the first — re-evaluated until
  /// the user picks one, so a cold cache doesn't leave it empty.
  Account? _defaultAccount(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    final last = widget.prefs.getString(_kLastAccount);
    return accounts.where((a) => a.id == last).firstOrNull ?? accounts.first;
  }

  /// Recent categories for the current type, topped up with top-level ones.
  List<Category> _recentCategories(List<Category> all) {
    final type =
        _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final usable = all.where((c) => c.type == type && !c.isSystem).toList();
    final byId = {for (final c in usable) c.id: c};
    final ids = widget.prefs.getStringList(_kRecent(type)) ?? const [];
    final out = <Category>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    final roots = usable.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final c in roots) {
      if (out.length >= _recentMax) break;
      if (!out.contains(c)) out.add(c);
    }
    final picked = _category;
    if (picked != null && !out.contains(picked)) out.insert(0, picked);
    return out.take(_recentMax).toList();
  }

  Future<void> _remember() async {
    final acc = _account;
    if (acc != null) await widget.prefs.setString(_kLastAccount, acc.id);
    final cat = _category;
    if (cat != null) {
      final key = _kRecent(cat.type);
      final list = [
        cat.id,
        ...(widget.prefs.getStringList(key) ?? const []).where((id) => id != cat.id),
      ].take(12).toList();
      await widget.prefs.setStringList(key, list);
    }
  }

  void _setType(TransactionType t) => setState(() {
        _type = t;
        _category = null; // a category belongs to one type
        if (t == TransactionType.transfer) {
          _splits = const [];
          _event = null;
        }
      });

  // ── Pickers ───────────────────────────────────────────────────────

  Future<void> _pickCategory() async {
    final r = await showCategoryPickerSheet(
      context: context,
      categories: context.read<CategoriesCubit>().state.categories,
      type: _type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      selected: _category,
    );
    if (!mounted || r == null) return;
    setState(() => _category = r is CategoryPickerSelected ? r.category : null);
  }

  Future<void> _pickAccount({bool to = false}) async {
    final l = AppLocalizations.of(context)!;
    final accounts = context.read<AccountsCubit>().state.accounts;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selected: to ? _toAccount : _account,
      excludeId: to ? _account?.id : (_isTransfer ? _toAccount?.id : null),
      title: to ? l.quickTo : l.transactionFormAccountLabel,
      // Expense / income may be floating; a transfer needs real wallets.
      allowNone: !_isTransfer && !to,
    );
    if (!mounted || r == null) return;
    setState(() {
      if (to) {
        if (r is AccountPickerSelected) _toAccount = r.account;
      } else {
        _accountTouched = true;
        _account = r is AccountPickerSelected ? r.account : null;
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickEvent() async {
    final picked = await showModalBottomSheet<_EventTarget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EventTargetSheet(
        suggestedName: _suggestEventName(),
      ),
    );
    if (picked != null && mounted) setState(() => _event = picked);
  }

  String _suggestEventName() {
    final l = AppLocalizations.of(context)!;
    final names = _splits
        .where((s) => s.personName.trim().isNotEmpty)
        .map((s) => s.personName.trim())
        .toList();
    final date = DateFormatter.medium(_date,
        locale: Localizations.localeOf(context).toLanguageTag());
    return names.isEmpty
        ? '${l.quickEventDefaultName} · $date'
        : '${names.join(', ')} · $date';
  }

  // ── Close / save ──────────────────────────────────────────────────

  /// Closing with something entered: keep it as a draft, keep editing, or
  /// throw it away. (Editing a draft: keep editing or drop the changes.)
  Future<void> _confirmClose() async {
    final l = AppLocalizations.of(context)!;
    final choice = await showDialog<_CloseChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_editingDraft ? l.pendingDropEditsTitle : l.quickDiscardTitle),
        content: Text(_editingDraft ? l.pendingDropEditsMessage : l.quickDiscardMessage),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: AppSpacing.sm,
        actions: [
          if (!_editingDraft)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _CloseChoice.draft),
              child: Text(l.pendingKeepAsDraft),
            ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, _CloseChoice.keepEditing),
            child: Text(l.quickDiscardKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _CloseChoice.discard),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l.quickDiscardConfirm),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _CloseChoice.draft:
        await _saveDraft();
      case _CloseChoice.discard:
        Navigator.of(context).pop(false);
      case _CloseChoice.keepEditing || null:
        break;
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Every rule the server would reject, said here first.
  String? _problem(AppLocalizations l) {
    if (_amountValue <= 0) return l.quickAmountRequired;
    if (_isTransfer) {
      if (_account == null || _toAccount == null) return l.txTransferNeedsTo;
      if (_account!.id == _toAccount!.id) return l.txTransferSameWallet;
    }
    final splitTotal = _splits
        .where((s) => s.isComplete)
        .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
    if (splitTotal > _amountValue + 0.005) return l.txSplitExceeds;
    if (_event != null && _account == null) return l.quickEventNeedsWallet;
    return null;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      _toast(problem);
      return;
    }
    final txCubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    final projects = context.read<ProjectsRepository>();
    final txRepo = context.read<TransactionsRepository>();
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final splits = _splits.where((s) => s.isComplete).map((s) => s.toJson()).toList();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final event = _event;

    setState(() => _saving = true);
    String? warn;
    String? openProject;
    try {
      if (event == null) {
        try {
          await txCubit.add(
            type: _type,
            accountId: _account?.id,
            amount: _amountValue,
            date: _ymd(_date),
            categoryId: _isTransfer ? null : _category?.id,
            note: note,
            transferToAccountId: _isTransfer ? _toAccount?.id : null,
            tagIds: _tagIds.toList(),
            splits: splits.isEmpty ? null : splits,
          );
        } on TagsAttachFailed {
          warn = l.txSavedTagsFailed; // saved — just the tags
        }
      } else {
        final body = <String, dynamic>{
          'type': _type.toJson(),
          'amount': _amountValue,
          'date': _ymd(_date),
          'account_id': ?_account?.id,
          'category_id': ?_category?.id,
          'note': ?note,
          if (splits.isNotEmpty) 'splits': splits,
        };
        final result = switch (event) {
          _NewEvent(:final name) =>
            await projects.quickCreate(name: name, newTransaction: body),
          _ExistingEvent(:final project) =>
            await projects.addBills(project.id, newTransaction: body),
        };
        openProject = result.project.id;
        final txId = result.transactionId;
        if (txId != null && _tagIds.isNotEmpty) {
          try {
            await txRepo.attachTags(transactionId: txId, tagIds: _tagIds.toList());
          } on ApiException {
            warn = l.txSavedTagsFailed;
          }
        }
        await txCubit.load();
      }
      await accounts.load();
      await _remember();
      navigator.pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(warn ?? l.quickSaved)));
      if (openProject != null) router.push('/projects/$openProject');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(event == null ? walletErrorMessage(l, e) : quickCreateErrorMessage(l, e));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    if (!_accountTouched) _account = _defaultAccount(accounts);
    final categories = context.watch<CategoriesCubit>().state.categories;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.94,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xs, AppSpacing.xs, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          _editingDraft
                              ? l.pendingEditTitle
                              : l.transactionFormTitleNew,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (_editingDraft)
                      TextButton(
                        onPressed: _saving ? null : _discardDraft,
                        style: TextButton.styleFrom(
                            foregroundColor: scheme.error),
                        child: Text(l.quickDiscardConfirm),
                      ),
                    IconButton(
                      tooltip: l.commonClose,
                      icon: const Icon(AppIcons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                      children: [
                        _TypeSwitch(type: _type, onChanged: _setType),
                        const SizedBox(height: AppSpacing.sm),
                        _AmountInput(
                          controller: _amount,
                          type: _type,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_isTransfer)
                          _TransferRow(
                            from: _account,
                            to: _toAccount,
                            onFrom: () => _pickAccount(),
                            onTo: () => _pickAccount(to: true),
                            onSwap: () => setState(() {
                              final f = _account;
                              _account = _toAccount;
                              _toAccount = f;
                              _accountTouched = true;
                            }),
                          )
                        else
                          _CategoryChips(
                            categories: _recentCategories(categories),
                            selected: _category,
                            onPick: (c) => setState(
                                () => _category = _category == c ? null : c),
                            onAll: _pickCategory,
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            if (!_isTransfer) ...[
                              Expanded(
                                child: _Pill(
                                  icon: _account == null
                                      ? AppIcons.noWallet
                                      : AppIcons.wallet,
                                  label: _account?.name ??
                                      l.transactionFormAccountNone,
                                  onTap: () => _pickAccount(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: _Pill(
                                icon: AppIcons.date,
                                label: DateFormatter.friendly(
                                  _date,
                                  today: l.commonToday,
                                  yesterday: l.commonYesterday,
                                  locale:
                                      Localizations.localeOf(context).languageCode,
                                ),
                                onTap: _pickDate,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _note,
                          maxLength: 500,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l.quickNoteHint,
                            counterText: '',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel(l.quickMore),
                        const SizedBox(height: AppSpacing.sm),
                        _TagsBlock(
                          selected: _tagIds,
                          onToggle: (id) => setState(() =>
                              _tagIds.contains(id) ? _tagIds.remove(id) : _tagIds.add(id)),
                        ),
                        if (!_isTransfer) ...[
                          const SizedBox(height: AppSpacing.sm),
                          SplitsSection(
                            totalAmount: _amountValue,
                            drafts: _splits,
                            onChanged: (d) => setState(() => _splits = d),
                            title: _type == TransactionType.income
                                ? l.transactionSplitShareTitle
                                : l.transactionSplitWithTitle,
                          ),
                          // Drafts don't go to events (submit is a plain
                          // create) — the tile only exists when creating.
                          if (!_editingDraft) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _EventTile(
                              target: _event,
                              onTap: _pickEvent,
                              onClear: () => setState(() => _event = null),
                            ),
                          ],
                        ],
                      ],
                    ),
                    // Compact summary — slides in once the amount scrolls off.
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.xs,
                      child: IgnorePointer(
                        ignoring: !_collapsed,
                        child: AnimatedSlide(
                          offset: _collapsed ? Offset.zero : const Offset(0, -0.6),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _collapsed ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: _SummaryBar(
                              type: _type,
                              amount: _amountValue,
                              category: _category,
                              onTap: () => _scroll.animateTo(0,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pinned above the keyboard: draft (→ รอยืนยัน) · save for real.
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                    AppSpacing.lg, insets > 0 ? AppSpacing.sm : AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l.pendingSaveDraft,
                        variant: AppButtonVariant.outlined,
                        expand: true,
                        // A draft can't go to an event.
                        onPressed: _saving || _event != null ? null : _saveDraft,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 3,
                      child: AppButton(
                        label: _editingDraft ? l.pendingSubmitThis : l.quickSave,
                        expand: true,
                        loading: _saving,
                        onPressed: _editingDraft ? _submitDraft : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────

class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({required this.type, required this.onChanged});
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<TransactionType>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment(
            value: TransactionType.expense, label: Text(l.transactionTypeExpense)),
        ButtonSegment(
            value: TransactionType.income, label: Text(l.transactionTypeIncome)),
        ButtonSegment(
            value: TransactionType.transfer, label: Text(l.transactionTypeTransfer)),
      ],
      selected: {type},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

Color _typeColor(BuildContext context, TransactionType t) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return switch (t) {
    TransactionType.expense => palette.expense,
    TransactionType.income => palette.income,
    TransactionType.transfer => Theme.of(context).colorScheme.onSurface,
  };
}

String _typeSign(TransactionType t) => switch (t) {
      TransactionType.expense => '−',
      TransactionType.income => '+',
      TransactionType.transfer => '',
    };

/// The big centred amount — focused on open, numeric keyboard, coloured by
/// type. Rebuilds the sheet on every keystroke (split totals stay live).
class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.type,
    required this.onChanged,
  });
  final TextEditingController controller;
  final TransactionType type;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _typeColor(context, type);
    final big = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return TextField(
      controller: controller,
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [ThousandsInputFormatter()],
      onChanged: (_) => onChanged(),
      style: big,
      cursorColor: Theme.of(context).colorScheme.primary,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: '0',
        hintStyle: big?.copyWith(color: color.withValues(alpha: 0.35)),
        prefixText: '${_typeSign(type)}฿ ',
        prefixStyle: big?.copyWith(fontSize: (big.fontSize ?? 36) * 0.6),
        semanticCounterText: l.transactionFormAmountLabel,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onPick,
    required this.onAll,
  });
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onPick;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in categories) ...[
            ChoiceChip(
              label: Text(c.name),
              selected: selected?.id == c.id,
              showCheckmark: false,
              onSelected: (_) => onPick(c),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          ActionChip(
            label: Text(l.quickAllCategories),
            avatar: const Icon(AppIcons.category, size: 16),
            onPressed: onAll,
          ),
        ],
      ),
    );
  }
}

/// A compact tappable field: icon · value · ▾.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap, this.caption, this.warn = false});
  final IconData icon;
  final String label;
  final String? caption;
  final VoidCallback onTap;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final warnColor = Theme.of(context).extension<AppColors>()!.warning;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: warn ? warnColor : scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (caption != null)
                        Text(caption!,
                            style: textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                              color: warn ? warnColor : null,
                              fontWeight: caption != null ? FontWeight.w600 : null)),
                    ],
                  ),
                ),
                Icon(AppIcons.dropdown, size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.from,
    required this.to,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
  });
  final Account? from;
  final Account? to;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _Pill(
            icon: AppIcons.wallet,
            caption: l.quickFrom,
            label: from?.name ?? l.quickPickWallet,
            warn: from == null,
            onTap: onFrom,
          ),
        ),
        IconButton(
          tooltip: l.quickSwap,
          icon: const Icon(AppIcons.transfer),
          onPressed: onSwap,
        ),
        Expanded(
          child: _Pill(
            icon: AppIcons.wallet,
            caption: l.quickTo,
            label: to?.name ?? l.quickPickWallet,
            warn: to == null,
            onTap: onTo,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tags = context.watch<TagsCubit>().state.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.tag, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(l.transactionFormTagsLabel,
                style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (tags.isEmpty)
          Text(l.transactionFormTagsEmpty,
              style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in tags)
                FilterChip(
                  label: Text('#${t.name}'),
                  selected: selected.contains(t.id),
                  showCheckmark: false,
                  onSelected: (_) => onToggle(t.id),
                ),
            ],
          ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.target, required this.onTap, required this.onClear});
  final _EventTarget? target;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = target;
    if (t == null) {
      return AddTile(
        label: l.quickAddToEvent,
        variant: AddTileVariant.row,
        icon: AppIcons.project,
        onTap: onTap,
      );
    }
    final name = switch (t) {
      _NewEvent(:final name) => l.quickEventNewNamed(name),
      _ExistingEvent(:final project) => project.name,
    };
    return DetailRow(
      leading: const Icon(AppIcons.project),
      label: l.quickEventLabel,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          IconButton(
            tooltip: l.quickEventRemove,
            icon: const Icon(AppIcons.clear, size: 18),
            onPressed: onClear,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Slides in at the top once the amount scrolls away.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.type,
    required this.amount,
    required this.category,
    required this.onTap,
  });
  final TransactionType type;
  final double amount;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final typeLabel = switch (type) {
      TransactionType.expense => l.transactionTypeExpense,
      TransactionType.income => l.transactionTypeIncome,
      TransactionType.transfer => l.transactionTypeTransfer,
    };
    return Material(
      color: scheme.surface,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Text(typeLabel,
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MoneyText(
                  amount,
                  tone: switch (type) {
                    TransactionType.expense => MoneyTone.expense,
                    TransactionType.income => MoneyTone.income,
                    TransactionType.transfer => MoneyTone.plain,
                  },
                  hideable: false,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (category != null)
                Chip(
                  label: Text(category!.name),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "เพิ่มเข้าอีเวนต์": a new event (named here) or one of my active ones.
class _EventTargetSheet extends StatefulWidget {
  const _EventTargetSheet({required this.suggestedName});
  final String suggestedName;

  @override
  State<_EventTargetSheet> createState() => _EventTargetSheetState();
}

class _EventTargetSheetState extends State<_EventTargetSheet> {
  late final _name = TextEditingController(text: widget.suggestedName);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectsCubit>().load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<ProjectsCubit>().state;
    final active = state.projects.where((p) => p.isActive).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.quickAddToEvent,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Text(l.quickEventNew, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _name,
                  label: l.quickEventNameLabel,
                  maxLength: 100,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.quickEventCreate,
                onPressed: () {
                  final n = _name.text.trim();
                  if (n.isNotEmpty) Navigator.of(context).pop(_NewEvent(n));
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.quickEventExisting, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          if (state.status == ProjectsStatus.loading && active.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (active.isEmpty)
            Text(l.quickEventNoneYet, style: Theme.of(context).textTheme.bodySmall)
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in active)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(AppIcons.project),
                      title: Text(p.name),
                      trailing: const Icon(AppIcons.chevronRight),
                      onTap: () => Navigator.of(context).pop(_ExistingEvent(p)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
