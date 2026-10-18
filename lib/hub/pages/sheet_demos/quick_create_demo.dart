import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../../ui/ui.dart';

/// Demo of [QuickCreateSheetShell] — the frame of the `+` quick create sheet
/// with a fake body (hero card + chips). Save / close just pop.
Widget buildQuickCreateDemo(BuildContext context) => Wrap(
  spacing: AppSpacing.sm,
  runSpacing: AppSpacing.sm,
  children: [
    AppButton(
      label: 'New transaction',
      onPressed: () => _open(context, _Variant.create),
    ),
    AppButton(
      label: 'Edit draft (delete)',
      variant: AppButtonVariant.outlined,
      onPressed: () => _open(context, _Variant.draft),
    ),
    AppButton(
      label: 'Single save button',
      variant: AppButtonVariant.outlined,
      onPressed: () => _open(context, _Variant.single),
    ),
  ],
);

enum _Variant { create, draft, single }

Future<void> _open(BuildContext context, _Variant variant) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      // The shell drags itself (the discard question must not be skipped).
      enableDrag: false,
      builder: (_) => _DemoSheet(variant),
    );

class _DemoSheet extends StatefulWidget {
  const _DemoSheet(this.variant);
  final _Variant variant;

  @override
  State<_DemoSheet> createState() => _DemoSheetState();
}

class _DemoSheetState extends State<_DemoSheet> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _heroKey = GlobalKey();
  TransactionType _type = TransactionType.expense;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_rebuild);
    _title.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  bool get _empty => _amount.text.trim().isEmpty && _title.text.trim().isEmpty;

  /// Fakes a save in flight (shows the overlay), then pops.
  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _ask() async {
    final discard = await showConfirmDialog(
      context,
      title: 'Discard this entry?',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    return QuickCreateSheetShell(
      heroKey: _heroKey,
      title: switch (v) {
        _Variant.create => 'New transaction',
        _Variant.draft => 'Edit draft',
        _Variant.single => 'New scheduled entry',
      },
      summaryBuilder: v == _Variant.create
          ? (scrollToTop) => GestureDetector(
              onTap: scrollToTop,
              child: Text(
                '${_type.name} · ${_amount.text.isEmpty ? '0' : _amount.text}'
                ' · Food',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : null,
      saveLabel: switch (v) {
        _Variant.create => 'Save',
        _Variant.draft => 'Confirm this one',
        _Variant.single => 'Save',
      },
      draftLabel: v == _Variant.single ? null : 'Save as draft',
      closeTooltip: 'Close',
      deleteTooltip: 'Delete',
      onDelete: v == _Variant.draft ? () => Navigator.of(context).pop() : null,
      saving: _saving,
      dirty: !_empty,
      onCloseBlocked: _ask,
      onSave: _empty ? null : _save,
      onSaveDraft: _empty || _saving ? null : () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionHeroCard(
            key: _heroKey,
            type: _type,
            amount: _amount,
            title: _title,
            dateLabel: 'Today',
            inline: true,
            onTypeChanged: (t) => setState(() => _type = t),
            onPickDate: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(label: 'Food'),
              AppChip(label: 'Cash'),
              AppChip(label: 'Lunch'),
              AppChip(label: 'Work'),
            ],
          ),
          // Tall enough to scroll, so the title-row summary can show.
          for (var i = 1; i <= 12; i++) ...[
            const SizedBox(height: AppSpacing.md),
            AppChip(label: 'Filler row $i'),
          ],
        ],
      ),
    );
  }
}
