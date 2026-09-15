import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/pages/transaction_form_body.dart';
import '../../../transactions/presentation/widgets/splits_section.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/projects_cubit.dart';

/// Quick create project from bills — spec §10/4.24, API §10 "Quick
/// create". Routed at `/projects/quick`; entry point is the labeled FAB
/// on the transactions tab root (see `MainShell`).
///
/// Three sections:
/// 1. **New bill** — the regular transaction form body embedded
///    (account / category / split pickers included; transfers and tags
///    hidden — see [TransactionFormBody.allowTransfer] /
///    [TransactionFormBody.showTags]).
/// 2. **Past bills picker** — the caller's loose transactions
///    (`project_id IS NULL`, last ~90 days) with a search box; ticking
///    is optional (zero ticks = project born from the one new bill).
/// 3. **Name** — prefilled members+date default
///    ("แฟน, บี · 15 ก.ย. 2026"), recomputed as splits change until the
///    user edits it manually.
///
/// The create button posts `POST /v1/projects/quick` (atomic on the BE)
/// and replaces this route with the new project's detail page.
class QuickCreateProjectPage extends StatefulWidget {
  const QuickCreateProjectPage({super.key});

  @override
  State<QuickCreateProjectPage> createState() =>
      _QuickCreateProjectPageState();
}

enum _BillsStatus { loading, loaded, error }

class _QuickCreateProjectPageState extends State<QuickCreateProjectPage> {
  final _bodyKey = GlobalKey<TransactionFormBodyState>();
  final _nameFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  /// True once the user typed a name of their own — stops the
  /// suggestion from overwriting it (spec §10/4.24: default is
  /// "editable before saving"). Clearing the field re-arms the
  /// suggestion.
  bool _nameEdited = false;
  String _lastSuggestion = '';

  /// Distinct split-counterparty names from the new bill's drafts, in
  /// entry order — feeds the members+date default name.
  List<String> _memberNames = const [];

  // ── Past-bills picker state ─────────────────────────────────────────
  List<Transaction> _bills = const [];
  _BillsStatus _billsStatus = _BillsStatus.loading;
  String? _billsError;
  int _billsPage = 0;
  int _billsTotalPages = 0;
  bool _loadingMore = false;
  String _search = '';
  final Set<String> _selectedIds = <String>{};

  bool _submitting = false;

  bool get _hasMoreBills => _billsPage > 0 && _billsPage < _billsTotalPages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Warm the form's picker caches (same as TransactionFormPage).
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      _loadBills(reset: true);
      // Seed the default name (no splits yet → date-only variant).
      _onSplitsChanged(const []);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Past bills fetch ────────────────────────────────────────────────

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Eligible = the caller's own rows with `project_id IS NULL` (spec
  /// §10/4.24 — splits NOT required, any loose bill qualifies). The
  /// list endpoint has no null-project filter param (repository
  /// checked), so the filter is client-side. Transfers are excluded —
  /// a board row is a bill (expense / income), not an account move.
  static bool _eligible(Transaction t) =>
      t.projectId == null && t.type != TransactionType.transfer;

  Future<void> _loadBills({required bool reset}) async {
    final repo = context.read<TransactionsRepository>();
    final now = DateTime.now();
    final from = _ymd(now.subtract(const Duration(days: 90)));
    final to = _ymd(now);

    setState(() {
      if (reset) {
        _billsStatus = _BillsStatus.loading;
        _billsError = null;
        _bills = const [];
        _billsPage = 0;
        _billsTotalPages = 0;
        _selectedIds.clear();
      } else {
        _loadingMore = true;
      }
    });
    try {
      final page = await repo.list(
        from: from,
        to: to,
        page: reset ? 1 : _billsPage + 1,
        perPage: 50,
      );
      if (!mounted) return;
      setState(() {
        _bills = [
          if (!reset) ..._bills,
          ...page.transactions.where(_eligible),
        ];
        _billsPage = page.page;
        _billsTotalPages = page.totalPages;
        _billsStatus = _BillsStatus.loaded;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _billsStatus = _BillsStatus.error;
          _billsError = e.message;
        }
        _loadingMore = false;
      });
    }
  }

  // ── Default name suggestion ─────────────────────────────────────────

  void _onSplitsChanged(List<SplitDraft> drafts) {
    final names = <String>[];
    for (final d in drafts) {
      final n = d.personName.trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }
    _memberNames = names;
    _recomputeSuggestion();
  }

  void _recomputeSuggestion() {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormatter.medium(DateTime.now(), locale: locale);
    final suggestion = _memberNames.isEmpty
        ? l.quickCreateDefaultNameSolo(date)
        : l.quickCreateDefaultName(_memberNames.join(', '), date);
    _lastSuggestion = suggestion;
    if (!_nameEdited && _nameController.text != suggestion) {
      _nameController.text = suggestion;
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context)!;

    // Validate both sections so the user sees every field error at once.
    final nameOk = _nameFormKey.currentState?.validate() ?? false;
    final payload = _bodyKey.currentState?.buildCreatePayload();
    if (!nameOk || payload == null) return;

    final cubit = context.read<ProjectsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _submitting = true);
    try {
      final result = await cubit.quickCreate(
        name: _nameController.text.trim(),
        newTransaction: payload,
        transactionIds: _selectedIds.toList(),
      );
      // The BE created the new bill and re-tagged the ticked ones —
      // refresh the caches whose rows / balances changed server-side.
      // Fire-and-forget: the project page doesn't depend on either.
      unawaited(accountsCubit.load());
      unawaited(txCubit.load());
      if (!mounted) return;
      // Replace (not push) — back from the project page shouldn't
      // return to a spent creation form.
      router.pushReplacement('/projects/${result.project.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(l, e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Maps the pinned quick-create error codes (API §10) to friendly
  /// copy; falls back to the BE message for anything unmapped.
  static String _errorMessage(AppLocalizations l, ApiException e) {
    switch (e.code) {
      case 'TX_NOT_FOUND':
        return l.quickCreateErrorTxNotFound;
      case 'TX_ALREADY_IN_PROJECT':
        return l.quickCreateErrorTxAlreadyInProject;
      case 'VALIDATION_ERROR':
        return l.quickCreateErrorValidation;
      default:
        return e.message;
    }
  }

  bool get _isDirty =>
      (_bodyKey.currentState?.isDirty ?? false) ||
      _selectedIds.isNotEmpty ||
      _nameEdited;

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isDirty) {
          if (context.mounted) context.pop();
          return;
        }
        final ok = await _confirmDiscard(context, l);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.quickCreateTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Section 1: the new bill ─────────────────────────────
              _SectionHeader(label: l.quickCreateNewBillSection),
              TransactionFormBody(
                key: _bodyKey,
                allowSaveAndAddAnother: false,
                collapsibleNote: false,
                initial: const TransactionFormInitial(),
                // The page submits via buildCreatePayload — the body's
                // own save path is never invoked.
                onSaved: ({required addedAnother}) {},
                showTags: false,
                allowTransfer: false,
                onSplitsChanged: _onSplitsChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // ── Section 2: past bills picker ────────────────────────
              _SectionHeader(label: l.quickCreateOldBillsSection),
              Text(
                l.quickCreateOldBillsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l.quickCreateSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildBillsList(l),
              const SizedBox(height: AppSpacing.xl),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // ── Section 3: name ─────────────────────────────────────
              _SectionHeader(label: l.quickCreateNameSection),
              Form(
                key: _nameFormKey,
                child: TextFormField(
                  controller: _nameController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: l.quickCreateNameLabel,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l.quickCreateNameRequired
                      : null,
                  onChanged: (v) {
                    // Manual edits stop the auto-suggestion; clearing
                    // the field re-arms it (next splits change refills).
                    _nameEdited =
                        v.trim().isNotEmpty && v != _lastSuggestion;
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.quickCreateSubmit),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillsList(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    switch (_billsStatus) {
      case _BillsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        );
      case _BillsStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Text(
                _billsError ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => _loadBills(reset: true),
                child: Text(l.quickCreateOldBillsRetry),
              ),
            ],
          ),
        );
      case _BillsStatus.loaded:
        break;
    }

    final q = _search.trim().toLowerCase();
    final visible = q.isEmpty
        ? _bills
        : _bills.where((t) {
            final note = t.note?.toLowerCase() ?? '';
            final cat = t.category?.name.toLowerCase() ?? '';
            return note.contains(q) || cat.contains(q);
          }).toList();

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          _bills.isEmpty
              ? l.quickCreateOldBillsEmpty
              : l.quickCreateOldBillsSearchEmpty,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              l.quickCreateSelectedCount(_selectedIds.length),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
            ),
          ),
        for (final t in visible)
          _BillRow(
            tx: t,
            selected: _selectedIds.contains(t.id),
            onToggle: () => setState(() {
              if (!_selectedIds.add(t.id)) _selectedIds.remove(t.id);
            }),
          ),
        if (_hasMoreBills)
          Align(
            alignment: Alignment.centerLeft,
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(l.quickCreateOldBillsLoadMore),
                    onPressed: () => _loadBills(reset: false),
                  ),
          ),
      ],
    );
  }

  Future<bool> _confirmDiscard(
      BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.transactionFormDiscardTitle),
        content: Text(l.transactionFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.commonRemove),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// One eligible past bill: category icon + note (fallback category
/// name) + localized date + signed amount + checkbox (spec §10/4.24).
class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.tx,
    required this.selected,
    required this.onToggle,
  });

  final Transaction tx;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final signed = tx.signedAmount;
    final amountColor = signed > 0 ? Colors.green.shade400 : scheme.error;
    final sign = signed > 0 ? '+' : (signed < 0 ? '−' : '');

    // Same icon resolution as the transactions list rows: the embedded
    // ref carries no icon, so look the category up in the cache and
    // fall back to a type glyph.
    final categoriesCubit = context.watch<CategoriesCubit>();
    final cat =
        tx.category != null ? categoriesCubit.byId(tx.category!.id) : null;
    final iconData = IconRegistry.get(
      cat?.iconCode?.icon,
      fallback: tx.type == TransactionType.income ? Icons.add : Icons.remove,
    );
    final iconColor = cat?.iconCode?.accentColorFor(palette) ??
        (tx.type == TransactionType.income
            ? Colors.green.shade400
            : scheme.error);

    final title = (tx.note != null && tx.note!.isNotEmpty)
        ? tx.note!
        : (tx.category?.name ?? '—');
    final date = DateTime.tryParse(tx.date);
    final dateLabel = date == null
        ? tx.date
        : DateFormatter.medium(
            date,
            locale: Localizations.localeOf(context).toString(),
          );

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
              visualDensity: VisualDensity.compact,
            ),
            CircleAvatar(
              radius: 14,
              backgroundColor: iconColor.withValues(alpha: 0.18),
              child: Icon(iconData, size: 16, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$sign${CurrencyFormatter.format(tx.amount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
