import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';

/// Collapsible "create an event from this bill" section inside the
/// transaction form (spec §10/4.24) — same interaction pattern as the
/// "Split with..." expander below which it sits.
///
/// Collapsed: a single TextButton. Expanded (= the quick-create flow is
/// armed): event name (members+date suggestion) + a checklist of the
/// caller's loose past bills to pull in. The form's Save button submits
/// via `POST /v1/projects/quick` when [EventSectionState.enabled].
class EventSection extends StatefulWidget {
  const EventSection({super.key});

  @override
  State<EventSection> createState() => EventSectionState();
}

enum _BillsStatus { loading, loaded, error }

class EventSectionState extends State<EventSection> {
  final _nameFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  bool _expanded = false;

  /// True once the user typed a name of their own — stops the
  /// suggestion from overwriting it. Clearing the field re-arms it.
  bool _nameEdited = false;
  String _lastSuggestion = '';
  List<String> _memberNames = const [];

  List<Transaction> _bills = const [];
  _BillsStatus _billsStatus = _BillsStatus.loading;
  String? _billsError;
  int _billsPage = 0;
  int _billsTotalPages = 0;
  bool _loadingMore = false;
  bool _billsLoadedOnce = false;
  String _search = '';
  final Set<String> _selectedIds = <String>{};

  bool get _hasMoreBills => _billsPage > 0 && _billsPage < _billsTotalPages;

  // ── Public surface (read by the form's save flow) ───────────────────

  /// The quick-create flow is armed iff the section is expanded.
  bool get enabled => _expanded;

  String get name => _nameController.text.trim();

  List<String> get selectedTransactionIds => _selectedIds.toList();

  bool validateName() => _nameFormKey.currentState?.validate() ?? false;

  bool get isDirty => _expanded && (_selectedIds.isNotEmpty || _nameEdited);

  /// Fed by the form whenever the new bill's split drafts change —
  /// drives the members+date default name.
  void setMemberNames(List<String> names) {
    _memberNames = names;
    if (_expanded) _recomputeSuggestion();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _recomputeSuggestion();
      if (!_billsLoadedOnce) _loadBills(reset: true);
    }
  }

  // ── Past bills fetch ────────────────────────────────────────────────

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Eligible = the caller's own rows with `project_id IS NULL` (spec
  /// §10/4.24 — splits NOT required). Transfers excluded — a board row
  /// is a bill, not an account move. Filter is client-side (the list
  /// endpoint has no null-project param).
  static bool _eligible(Transaction t) =>
      t.projectId == null && t.type != TransactionType.transfer;

  Future<void> _loadBills({required bool reset}) async {
    final repo = context.read<TransactionsRepository>();
    final now = DateTime.now();
    final from = _ymd(now.subtract(const Duration(days: 90)));
    final to = _ymd(now);

    setState(() {
      _billsLoadedOnce = true;
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

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.celebration_outlined, size: 18),
          label: Text(l.quickCreateToggle),
          onPressed: _toggle,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.celebration_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l.quickCreateToggle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l.commonClose,
              visualDensity: VisualDensity.compact,
              onPressed: _toggle,
            ),
          ],
        ),
        Text(
          l.quickCreateOldBillsHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _nameFormKey,
          child: TextFormField(
            controller: _nameController,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: l.quickCreateNameLabel,
              isDense: true,
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l.quickCreateNameRequired : null,
            onChanged: (v) {
              _nameEdited = v.trim().isNotEmpty && v != _lastSuggestion;
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.quickCreateOldBillsSection,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l.quickCreateSearchHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildBillsList(l),
      ],
    );
  }

  Widget _buildBillsList(AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    switch (_billsStatus) {
      case _BillsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
}

/// Maps the pinned quick-create error codes (API §10) to friendly copy;
/// falls back to the BE message for anything unmapped.
String quickCreateErrorMessage(AppLocalizations l, ApiException e) {
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
