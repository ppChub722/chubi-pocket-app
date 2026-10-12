import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../transactions/presentation/save_failure.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/draft_form.dart';
import '../cubit/pending_cubit.dart';

/// `/pending/new` — jot several drafts at once (owner design 2026-10-08).
/// Every row is the [DraftForm] in its chip layout — the same as "แก้ร่าง"
/// (the hero — type, amount, description, date — then a wallet chip row
/// above a category chip row, tags, the note, and a collapsible
/// "หารกับ / อีเวนต์"); a row only needs an amount.
/// "เก็บเป็นร่าง" parks them in รอยืนยัน (half-filled splits stay for later);
/// "ยืนยันเลยทั้งหมด" also submits, and then every split must balance.
class PendingBatchAddPage extends StatefulWidget {
  const PendingBatchAddPage({super.key});

  @override
  State<PendingBatchAddPage> createState() => _PendingBatchAddPageState();
}

class _PendingBatchAddPageState extends State<PendingBatchAddPage> {
  final List<DraftFormController> _rows = [DraftFormController()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final r in _rows) {
      r.addListener(_onChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _addRow() => setState(() {
    _rows.add(DraftFormController()..addListener(_onChanged));
  });

  void _removeRow(int i) {
    final removed = _rows.removeAt(i);
    setState(() {});
    // After this frame — the row's form is still listening until it unmounts.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  List<DraftFormController> get _filled =>
      _rows.where((r) => r.amountValue > 0).toList();

  Future<void> _save({required bool submit}) async {
    final l = AppLocalizations.of(context)!;
    final rows = _filled;
    if (rows.isEmpty) {
      showAppSnackBar(context, l.quickAmountRequired, tone: Tone.warning);
      return;
    }
    // Confirming needs the splits whole and balanced (a draft doesn't).
    if (submit && rows.any((r) => !r.splitsBalanced)) {
      showAppSnackBar(context, l.txSplitUnbalanced, tone: Tone.danger);
      return;
    }
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final created = await pending.add([
        for (final r in rows) r.toDraft(keepIncomplete: !submit),
      ]);
      var msg = l.pendingSavedCount(created.length);
      var tone = Tone.success;
      if (submit) {
        final r = await pending.submit([for (final p in created) p.id]);
        if (r.submitted.isNotEmpty) {
          accounts.patchBalances(r.accountBalances);
          await TransactionsCubit.bookChanged();
        }
        msg = l.pendingResult(r.submitted.length, r.failed.length);
        if (r.failed.isNotEmpty) tone = Tone.warning;
      }
      navigator.pop(true);
      showAppSnackBarOn(messenger, msg, tone: tone);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSaveFailure(context, e, retry: () => _save(submit: submit));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final n = _filled.length;
    // A save in flight dims the page and blocks input.
    return SavingOverlay(
      saving: _saving,
      child: Scaffold(
        appBar: AppTopBar(
          title: l.pendingAdd,
          showBack: true,
          showUniversal: false,
        ),
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            // Clear the floating top bar (read inside the body to see it).
            Builder(
              builder: (context) =>
                  SizedBox(height: MediaQuery.paddingOf(context).top),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppText(l.pendingBatchHint, role: AppTextRole.caption),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  for (var i = 0; i < _rows.length; i++) ...[
                    _RowCard(
                      key: ObjectKey(_rows[i]),
                      controller: _rows[i],
                      autofocus: i == _rows.length - 1,
                      onRemove: _rows.length == 1 ? null : () => _removeRow(i),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AddTile(
                    label: l.pendingAddRow,
                    variant: AddTileVariant.row,
                    onTap: _addRow,
                  ),
                ],
              ),
            ),
            // The text button below brings its own bottom space.
            PinnedBar(
              bottomGap: AppSpacing.sm,
              keyboardGap: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: l.pendingSaveAsDrafts(n),
                    expand: true,
                    loading: _saving,
                    onPressed: n == 0 ? null : () => _save(submit: false),
                  ),
                  AppButton(
                    label: l.pendingSubmitAllNow(n),
                    variant: AppButtonVariant.text,
                    onPressed: _saving || n == 0
                        ? null
                        : () => _save(submit: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One draft in the list: the chip-layout form in a card, a big ✕ to drop
/// the row (only when there are several).
class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.controller,
    required this.autofocus,
    required this.onRemove,
    super.key,
  });

  final DraftFormController controller;
  final bool autofocus;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: AppIconButton.close(
                tooltip: l.pendingRemoveRow,
                iconSize: AppIconSize.lg,
                color: scheme.onSurfaceVariant,
                onPressed: onRemove,
              ),
            ),
          DraftForm(
            controller: controller,
            compact: true,
            autofocus: autofocus,
            chipLayout: true,
            // A row with an amount but no wallet / category is an incomplete
            // draft: outline what's still missing.
            missing: {
              if (controller.amountValue > 0) ...[
                if (controller.account == null) EntryField.wallet,
                if (!controller.isTransfer && controller.category == null)
                  EntryField.category,
              ],
            },
          ),
        ],
      ),
    );
  }
}
