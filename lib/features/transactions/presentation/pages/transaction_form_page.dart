import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../cubit/transactions_cubit.dart';
import 'transaction_form_body.dart';

/// Full-page wrapper around [TransactionFormBody]. Used for:
/// - `/transactions/new` (create from More menu / FAB-on-tablet)
/// - `/transactions/:id/edit` (edit always opens full-page)
///
/// Differences vs [showTransactionFormSheet]:
/// - Note field always visible (not collapsible).
/// - "Save & add another" shown alongside Save when creating.
/// - Has its own AppBar + back nav + PopScope discard-confirm.
///
/// Make sure caches are warm before opening: this page does NOT call
/// `loadIfNeeded` on accounts / categories — the underlying nav points
/// (home / accounts list / categories list) typically have. If those
/// caches are empty when the form mounts, pickers will be empty too.
/// The form's `loadIfNeeded` calls cover that defensively.
class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({this.editingId, super.key});

  final String? editingId;

  bool get isEdit => editingId != null;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _bodyKey = GlobalKey<TransactionFormBodyState>();

  @override
  void initState() {
    super.initState();
    // Warm the picker caches even if the user deep-linked here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TransactionsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Edit mode: resolve the transaction from the cubit cache.
    if (widget.isEdit) {
      return BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
          final tx = context.read<TransactionsCubit>().byId(widget.editingId!);
          if (tx == null) {
            // Either still loading or the row doesn't exist locally.
            if (state.status == TransactionsStatus.loading ||
                state.status == TransactionsStatus.initial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return Scaffold(
              appBar: AppBar(title: Text(l.transactionFormTitleEdit)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l.transactionDetailNotFoundMessage,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return _Scaffold(
            initial: TransactionFormInitial(editingTransaction: tx),
            isEdit: true,
            bodyKey: _bodyKey,
          );
        },
      );
    }

    return _Scaffold(
      initial: const TransactionFormInitial(),
      isEdit: false,
      bodyKey: _bodyKey,
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.initial,
    required this.isEdit,
    required this.bodyKey,
  });

  final TransactionFormInitial initial;
  final bool isEdit;
  final GlobalKey<TransactionFormBodyState> bodyKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final state = bodyKey.currentState;
        if (state == null || !state.isDirty) {
          if (context.mounted) context.pop();
          return;
        }
        final ok = await _confirmDiscard(context, l, isEdit);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEdit ? l.transactionFormTitleEdit : l.transactionFormTitleNew,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          child: TransactionFormBody(
            key: bodyKey,
            allowSaveAndAddAnother: !isEdit,
            collapsibleNote: false,
            initial: initial,
            onSaved: ({required addedAnother}) {
              if (addedAnother) return; // stay on page, body resets itself
              if (context.mounted) context.pop();
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => bodyKey.currentState?.save(keepOpen: false),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l.transactionFormSave),
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          bodyKey.currentState?.save(keepOpen: true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        l.transactionFormSaveAndAddAnother,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDiscard(
      BuildContext context, AppLocalizations l, bool isEdit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit
            ? l.transactionFormDiscardTitleEdit
            : l.transactionFormDiscardTitle),
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

/// Modal bottom-sheet wrapper. Quick-add — note collapsed, no
/// "Save & add another" button, no full Scaffold.
///
/// Returns true if at least one transaction was saved before the
/// sheet was dismissed. Callers can use that to refresh local views
/// (though the cubit's surgical updates already cover most cases).
Future<bool> showTransactionFormSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SheetWrapper(),
  );
  return saved ?? false;
}

class _SheetWrapper extends StatefulWidget {
  const _SheetWrapper();

  @override
  State<_SheetWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends State<_SheetWrapper> {
  final _bodyKey = GlobalKey<TransactionFormBodyState>();
  bool _anySaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      // Lift content above the keyboard.
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                l.transactionFormTitleNew,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TransactionFormBody(
              key: _bodyKey,
              allowSaveAndAddAnother: false,
              collapsibleNote: true,
              initial: const TransactionFormInitial(),
              onSaved: ({required addedAnother}) {
                _anySaved = true;
                if (!mounted) return;
                Navigator.of(context).pop(_anySaved);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => _bodyKey.currentState?.save(keepOpen: false),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.transactionFormSave),
            ),
          ],
        ),
      ),
    );
  }
}
