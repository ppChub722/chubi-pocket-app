import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/draft_form.dart';
import '../cubit/pending_cubit.dart';

/// `/pending/new` — jot several drafts at once (owner design 2026-10-08).
/// Every row is the same [DraftForm] the `+` quick create uses (type, amount,
/// category + wallet cards, date, note, and the closed "รายละเอียดเพิ่ม"
/// section for tags / splits); a row only needs an amount.
/// "เก็บเป็นร่าง" parks them in รอยืนยัน; "ยืนยันเลยทั้งหมด" also submits.
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
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final created = await pending.add([for (final r in rows) r.toDraft()]);
      var msg = l.pendingSavedCount(created.length);
      var tone = Tone.success;
      if (submit) {
        final r = await pending.submit([for (final p in created) p.id]);
        if (r.submitted.isNotEmpty) {
          await Future.wait([accounts.load(), txCubit.load()]);
        }
        msg = l.pendingResult(r.submitted.length, r.failed.length);
        if (r.failed.isNotEmpty) tone = Tone.warning;
      }
      navigator.pop(true);
      showAppSnackBarOn(messenger, msg, tone: tone);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final n = _filled.length;
    return Scaffold(
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
            child: Text(
              l.pendingBatchHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
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
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: l.pendingSaveAsDrafts(n),
                  expand: true,
                  loading: _saving,
                  onPressed: n == 0 ? null : () => _save(submit: false),
                ),
                TextButton(
                  onPressed: _saving || n == 0
                      ? null
                      : () => _save(submit: true),
                  child: Text(l.pendingSubmitAllNow(n)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One draft in the list: the shared form in a card, ✕ to drop the row.
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: l.pendingRemoveRow,
                visualDensity: VisualDensity.compact,
                icon: const Icon(AppIcons.close, size: 18),
                onPressed: onRemove,
              ),
            ),
          DraftForm(
            controller: controller,
            compact: true,
            autofocus: autofocus,
          ),
        ],
      ),
    );
  }
}
