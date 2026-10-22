import 'package:flutter/material.dart';

import '../../ui.dart';

enum EventResolveMode { asTransaction, asDebt }

@immutable
class ResolvePickValue {
  const ResolvePickValue({
    required this.label,
    this.icon,
    this.color,
    this.ref,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Object? ref;
}

@immutable
class ResolvePickResult {
  const ResolvePickResult(this.value);
  final ResolvePickValue? value;
}

@immutable
class EventResolveResult {
  const EventResolveResult({
    required this.mode,
    required this.shareOnly,
    this.account,
    this.category,
  });

  final EventResolveMode mode;
  final bool shareOnly;
  final ResolvePickValue? account;
  final ResolvePickValue? category;
}

class EventResolveLabels {
  const EventResolveLabels({
    required this.title,
    required this.confirm,
    required this.amount,
    required this.shareOnly,
    required this.account,
    required this.accountEmpty,
    required this.accountRequired,
    required this.category,
    required this.categoryEmpty,
    required this.asTransaction,
    required this.asDebt,
    required this.debtRow,
    required this.debtHint,
  });

  final String title;
  final String confirm;
  final String amount;
  final String shareOnly;
  final String account;
  final String accountEmpty;

  /// Shown under the account row when confirming without one.
  final String accountRequired;
  final String category;
  final String categoryEmpty;
  final String asTransaction;
  final String asDebt;

  final String debtRow;
  final String debtHint;
}

Future<bool> showEventResolveSheet(
  BuildContext context, {
  required EventResolveLabels labels,
  required double amount,
  required String currencySymbol,
  required Future<ResolvePickResult?> Function(ResolvePickValue? current)
  onPickAccount,
  required Future<ResolvePickResult?> Function(ResolvePickValue? current)
  onPickCategory,
  required Future<bool> Function(EventResolveResult result) onSubmit,
  double? shareAmount,
  String? shareHint,
  bool showModeTabs = false,
}) async {
  final ok = await showAppSheetCustom<bool>(
    context,
    builder: (_) => EventResolveSheet(
      labels: labels,
      amount: amount,
      currencySymbol: currencySymbol,
      shareAmount: shareAmount,
      shareHint: shareHint,
      showModeTabs: showModeTabs,
      onPickAccount: onPickAccount,
      onPickCategory: onPickCategory,
      onSubmit: onSubmit,
    ),
  );
  return ok == true;
}

class EventResolveSheet extends StatefulWidget {
  const EventResolveSheet({
    required this.labels,
    required this.amount,
    required this.currencySymbol,
    required this.onPickAccount,
    required this.onPickCategory,
    required this.onSubmit,
    this.shareAmount,
    this.shareHint,
    this.showModeTabs = false,
    super.key,
  });

  final EventResolveLabels labels;
  final double amount;
  final String currencySymbol;

  final double? shareAmount;
  final String? shareHint;

  final bool showModeTabs;
  final Future<ResolvePickResult?> Function(ResolvePickValue? current)
  onPickAccount;
  final Future<ResolvePickResult?> Function(ResolvePickValue? current)
  onPickCategory;
  final Future<bool> Function(EventResolveResult result) onSubmit;

  @override
  State<EventResolveSheet> createState() => _EventResolveSheetState();
}

class _EventResolveSheetState extends State<EventResolveSheet> {
  EventResolveMode _mode = EventResolveMode.asTransaction;
  ResolvePickValue? _account;
  ResolvePickValue? _category;
  bool _shareOnly = false;
  bool _saving = false;
  bool _accountMissing = false;

  double get _shownAmount => _shareOnly && widget.shareAmount != null
      ? widget.shareAmount!
      : widget.amount;

  Widget? _chip(ResolvePickValue? v) => v == null
      ? null
      : AppChip(
          label: v.label,
          icon: v.icon,
          color: v.color,
          size: ChipSize.chip,
        );

  Future<void> _pickAccount() async {
    final r = await widget.onPickAccount(_account);
    if (r == null || !mounted) return;
    setState(() {
      _account = r.value;
      _accountMissing = false;
    });
  }

  Future<void> _pickCategory() async {
    final r = await widget.onPickCategory(_category);
    if (r == null || !mounted) return;
    setState(() => _category = r.value);
  }

  Future<void> _submit() async {
    if (_mode == EventResolveMode.asTransaction && _account == null) {
      setState(() => _accountMissing = true);
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSubmit(
      EventResolveResult(
        mode: _mode,
        shareOnly: _shareOnly,
        account: _account,
        category: _category,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    final hasShare = widget.shareAmount != null;
    return FormSheet(
      title: l.title,
      primaryLabel: l.confirm,
      onPrimary: _submit,
      saving: _saving,
      dirty: _account != null || _category != null || _shareOnly,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showModeTabs) ...[
            AppTabBar<EventResolveMode>(
              selected: _mode,
              onChanged: (m) => setState(() => _mode = m),
              tabs: [
                AppTab(
                  value: EventResolveMode.asTransaction,
                  label: l.asTransaction,
                  icon: AppIcons.transactions,
                ),
                AppTab(
                  value: EventResolveMode.asDebt,
                  label: l.asDebt,
                  icon: AppIcons.debt,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SectionCard(
            first: !widget.showModeTabs,
            children: [
              DetailRow(
                label: l.amount,
                trailing: MoneyText(
                  _shownAmount,
                  symbol: widget.currencySymbol,
                ),
              ),
              if (hasShare)
                DetailRow(
                  label: l.shareOnly,
                  trailing: AppSwitch(
                    value: _shareOnly,
                    onChanged: (v) => setState(() => _shareOnly = v),
                  ),
                  onTap: () => setState(() => _shareOnly = !_shareOnly),
                  helper: widget.shareHint,
                ),
            ],
          ),
          if (_mode == EventResolveMode.asTransaction)
            SectionCard(
              children: [
                DetailRow.pick(
                  label: l.account,
                  valueChip: _chip(_account),
                  emptyText: l.accountEmpty,
                  leading: const AppIcon(AppIcons.bank),
                  onTap: _pickAccount,
                ),
                if (_accountMissing)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: AppMessage(
                      message: l.accountRequired,
                      tone: Tone.danger,
                    ),
                  ),
                DetailRow.pick(
                  label: l.category,
                  valueChip: _chip(_category),
                  emptyText: l.categoryEmpty,
                  leading: const AppIcon(AppIcons.category),
                  onTap: _pickCategory,
                ),
              ],
            )
          else
            SectionCard(
              children: [
                DetailRow(
                  leading: const AppIcon(AppIcons.debt),
                  label: l.debtRow,
                  helper: l.debtHint,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
