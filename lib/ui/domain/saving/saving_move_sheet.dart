import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import '../money/money_text.dart';

/// One end of a move (the "from" / "to" card): a small caption, a name, a
/// sub line (the balance).
class SavingMoveEnd {
  const SavingMoveEnd({
    required this.caption,
    required this.name,
    this.subtitle,
    this.leading,
  });

  /// "จาก" / "ไป".
  final String caption;
  final String name;

  /// e.g. the bucket's current amount, or the wallets' names.
  final String? subtitle;

  /// A glyph before the name.
  final Widget? leading;
}

/// One wallet row of the split: how much of the move comes from / goes to it.
class SavingSplitRow {
  const SavingSplitRow({
    required this.walletId,
    required this.name,
    required this.amount,
    this.availableText,
    this.leading,
  });

  final String walletId;
  final String name;

  /// The proposed part (the caller's largest-first auto split).
  final double amount;

  /// "มี ฿40,000" — what the wallet can give (move) / holds (withdraw).
  final String? availableText;
  final Widget? leading;
}

/// What the sheet returns: the user's final split.
typedef SavingMoveSplit = ({String walletId, double amount});

/// The move sheet (goals v2 frame 5), also used for ถอน (the "to" card is the
/// wallet(s)):
///
///   title
///   [จาก card] → [ไป card]
///   amount
///   แบ่งตามกระเป๋า (อัตโนมัติ)                      [✏️ แก้ไข]
///   (icon) wallet · มี ฿x                              ฿part
///   รวม ฿x ✓ …
///   [ ย้าย ]
///
/// The caller computes the split (largest-first across wallets); the sheet
/// only edits and checks `sum == amount`. [autoSplit] (optional) re-proposes
/// the split when the amount changes and the rows have not been edited by
/// hand. Every word is a param. Resolves the rows with a non-zero part, or
/// null when dismissed. Save is disabled until the amount is > 0 and the
/// parts add up to it.
Future<List<SavingMoveSplit>?> showSavingMoveSheet(
  BuildContext context, {
  required String title,
  required SavingMoveEnd from,
  required SavingMoveEnd to,
  required double amount,
  required List<SavingSplitRow> splits,
  required String amountLabel,
  required String splitTitle,
  required String editLabel,
  required String saveLabel,
  required String Function(double sum) sumOkText,
  required String Function(double sum, double amount) sumOffText,
  List<SavingMoveSplit> Function(double amount)? autoSplit,
  String currencySymbol = '฿',
}) {
  return showPpForgeSheetCustom<List<SavingMoveSplit>>(
    context,
    builder: (_) => SavingMoveSheet(
      title: title,
      from: from,
      to: to,
      amount: amount,
      splits: splits,
      amountLabel: amountLabel,
      splitTitle: splitTitle,
      editLabel: editLabel,
      saveLabel: saveLabel,
      sumOkText: sumOkText,
      sumOffText: sumOffText,
      autoSplit: autoSplit,
      currencySymbol: currencySymbol,
    ),
  );
}

/// The body of [showSavingMoveSheet] (exposed for the hub and tests).
class SavingMoveSheet extends StatefulWidget {
  const SavingMoveSheet({
    required this.title,
    required this.from,
    required this.to,
    required this.amount,
    required this.splits,
    required this.amountLabel,
    required this.splitTitle,
    required this.editLabel,
    required this.saveLabel,
    required this.sumOkText,
    required this.sumOffText,
    this.autoSplit,
    this.currencySymbol = '฿',
    super.key,
  });

  final String title;
  final SavingMoveEnd from;
  final SavingMoveEnd to;
  final double amount;
  final List<SavingSplitRow> splits;
  final String amountLabel;
  final String splitTitle;
  final String editLabel;
  final String saveLabel;
  final String Function(double sum) sumOkText;
  final String Function(double sum, double amount) sumOffText;
  final List<SavingMoveSplit> Function(double amount)? autoSplit;
  final String currencySymbol;

  @override
  State<SavingMoveSheet> createState() => _SavingMoveSheetState();
}

class _SavingMoveSheetState extends State<SavingMoveSheet> {
  late final TextEditingController _amount;
  late final Map<String, TextEditingController> _parts;
  bool _editing = false;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: AmountInput.format(widget.amount));
    _parts = {
      for (final r in widget.splits)
        r.walletId: TextEditingController(text: AmountInput.format(r.amount)),
    };
  }

  @override
  void dispose() {
    _amount.dispose();
    for (final c in _parts.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amountValue => AmountInput.parse(_amount.text) ?? 0;
  double _part(String id) => AmountInput.parse(_parts[id]?.text) ?? 0;
  double get _sum => [
    for (final r in widget.splits) _part(r.walletId),
  ].fold(0.0, (a, b) => a + b);
  bool get _ok => _amountValue > 0 && (_sum - _amountValue).abs() < 0.005;

  void _amountChanged() {
    final auto = widget.autoSplit;
    if (auto != null && !_touched) {
      final next = {for (final s in auto(_amountValue)) s.walletId: s.amount};
      for (final r in widget.splits) {
        _parts[r.walletId]!.text = AmountInput.format(next[r.walletId] ?? 0);
      }
    }
    setState(() {});
  }

  void _save() => Navigator.pop(context, [
    for (final r in widget.splits)
      if (_part(r.walletId) > 0)
        (walletId: r.walletId, amount: _part(r.walletId)),
  ]);

  Widget _end(BuildContext context, SavingMoveEnd e) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cap = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return PpForgeCard(
      padding: const EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.md,
        vertical: PpForgeSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.caption, style: cap),
          Row(
            children: [
              if (e.leading != null) ...[
                e.leading!,
                const SizedBox(width: PpForgeSpacing.xs),
              ],
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          if (e.subtitle != null)
            Text(
              e.subtitle!,
              style: cap,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, SavingSplitRow r) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.md,
        vertical: PpForgeSpacing.sm,
      ),
      child: Row(
        children: [
          if (r.leading != null) ...[
            r.leading!,
            const SizedBox(width: PpForgeSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (r.availableText != null)
                  Text(
                    r.availableText!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: PpForgeSpacing.sm),
          if (_editing)
            SizedBox(
              width: 140,
              child: PpForgeInput(
                controller: _parts[r.walletId],
                type: PpForgeInputType.amount,
                currencySymbol: widget.currencySymbol,
                dense: true,
                onChanged: (_) => setState(() => _touched = true),
              ),
            )
          else
            MoneyText(
              _part(r.walletId),
              symbol: widget.currencySymbol,
              style: text.titleSmall,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sum = _sum;
    final ok = _ok;
    return PpForgeSheetScaffold(
      title: widget.title,
      footer: PpForgeButton(
        label: widget.saveLabel,
        expand: true,
        onPressed: ok ? _save : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _end(context, widget.from)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PpForgeSpacing.sm,
                  ),
                  child: Text('→', style: text.titleMedium),
                ),
                Expanded(child: _end(context, widget.to)),
              ],
            ),
            const SizedBox(height: PpForgeSpacing.md),
            AmountInput(
              controller: _amount,
              label: widget.amountLabel,
              currencySymbol: widget.currencySymbol,
              onChanged: (_) => _amountChanged(),
            ),
            const SizedBox(height: PpForgeSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.splitTitle,
                    style: text.titleSmall?.copyWith(color: scheme.primary),
                  ),
                ),
                PpForgeChip(
                  label: widget.editLabel,
                  icon: Icons.edit_outlined,
                  size: ChipSize.mini,
                  selected: _editing,
                  onTap: () => setState(() => _editing = !_editing),
                ),
              ],
            ),
            const SizedBox(height: PpForgeSpacing.sm),
            PpForgeCard(
              child: Column(
                children: [for (final r in widget.splits) _row(context, r)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PpForgeSpacing.xs,
                vertical: PpForgeSpacing.sm,
              ),
              child: Text(
                ok
                    ? widget.sumOkText(sum)
                    : widget.sumOffText(sum, _amountValue),
                style: text.bodySmall?.copyWith(
                  color: ok ? scheme.onSurfaceVariant : scheme.error,
                  fontWeight: ok ? null : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
