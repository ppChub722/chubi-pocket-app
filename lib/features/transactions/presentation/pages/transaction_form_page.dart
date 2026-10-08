import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../cubit/transactions_cubit.dart';
import 'transaction_form_body.dart';

/// Full-page wrapper around [TransactionFormBody] — used for:
/// - `/transactions/new` (empty-state "add first transaction" tiles; the
///   `+` button opens the quick-create sheet instead)
/// - `/transactions/:id/edit` (edit always opens full-page)
///
/// Differences vs the quick-create sheet:
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
              appBar: AppTopBar(
                  title: l.transactionFormTitleEdit, showBack: true),
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
            // Ex-member row on a shared wallet (spec §14/2.3): whole
            // form read-only — the body shows the explanatory banner,
            // the scaffold drops the Save buttons.
            readOnly: tx.isLocked,
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

/// The full-page form chrome. A form is edit mode (§1.4): ✕ (asks before
/// discarding) + ยกเลิก · บันทึก, nav hidden (route wraps ShellChromeHider).
/// "บันทึกแล้วเพิ่มต่อ" (create only) sits at the end of the form.
class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.initial,
    required this.isEdit,
    required this.bodyKey,
    this.readOnly = false,
  });

  final TransactionFormInitial initial;
  final bool isEdit;
  final bool readOnly;
  final GlobalKey<TransactionFormBodyState> bodyKey;

  Future<void> _leave(BuildContext context) async {
    final dirty = bodyKey.currentState?.isDirty ?? false;
    if (dirty) {
      final l = AppLocalizations.of(context)!;
      final ok = await showConfirmDialog(
        context,
        title: isEdit
            ? l.transactionFormDiscardTitleEdit
            : l.transactionFormDiscardTitle,
        message: l.transactionFormDiscardBody,
        confirmLabel: l.commonDiscard,
        destructive: true,
      );
      if (!ok) return;
    }
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: isEdit ? l.transactionFormTitleEdit : l.transactionFormTitleNew,
          showBack: true,
          editing: true,
          onBack: () => _leave(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.huge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionFormBody(
                key: bodyKey,
                allowSaveAndAddAnother: !isEdit,
                collapsibleNote: false,
                initial: initial,
                enableEventSection: !isEdit,
                onSaved: ({required addedAnother}) {
                  if (addedAnother) return; // body resets itself
                  if (context.mounted) context.pop();
                },
              ),
              if (!isEdit && !readOnly) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l.transactionFormSaveAndAddAnother,
                  icon: AppIcons.add,
                  variant: AppButtonVariant.tonal,
                  expand: true,
                  onPressed: () => bodyKey.currentState?.save(keepOpen: true),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: readOnly
            ? null
            : ModeActionBar(
                canUndo: false,
                canSave: true,
                cancelLabel: l.commonCancel,
                saveLabel: l.transactionFormSave,
                undoTooltip: l.commonUndo,
                onCancel: () => _leave(context),
                onUndo: () {},
                onSave: () => bodyKey.currentState?.save(keepOpen: false),
              ),
      ),
    );
  }
}
