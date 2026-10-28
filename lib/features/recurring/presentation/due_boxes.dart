import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/recurring_item.dart';
import 'occurrence_actions.dart';
import 'recurring_rows.dart';

/// ต้องจัดการ as one รอยืนยัน card that folds to its head line. Every row
/// has a check, an amount field and a ✓: the field holds the amount it will
/// be recorded with (filled in when known, still editable; empty = รอใส่ยอด).
/// One เลือกทั้งหมด row with ข้าม / จ่ายแล้ว / ยืนยันที่เลือก. A row with no
/// amount can't be confirmed (it's left out), only skipped or marked paid.
/// [shownCount] rows, then ดูทั้ง n / ย่อ.
class DueBoxes extends StatefulWidget {
  const DueBoxes({
    required this.items,
    required this.leading,
    required this.onChanged,
    required this.onOpen,
    this.tag,
    this.caption,
    this.titleOf,
    this.shownCount = 3,
    this.showDate = true,
    this.more,
    this.footer,
    super.key,
  });

  final List<RecurringItem> items;
  final Widget Function(RecurringItem item) leading;

  /// A pill beside the name; none by default (the card says รอยืนยัน).
  final ListRowChip? Function(RecurringItem item)? tag;

  /// An extra bit for the muted line ("เฉลี่ย ฿1,305").
  final String? Function(RecurringItem item)? caption;

  /// The row's name; defaults to the occurrence's full one.
  final String Function(RecurringItem item)? titleOf;
  final ValueChanged<ItemWriteResult> onChanged;
  final ValueChanged<RecurringItem> onOpen;
  final int shownCount;

  /// The date on the muted line; off when [leading] shows it already.
  final bool showDate;

  /// After the opened list: more than [items] holds (to the ประวัติ tab).
  final Widget? more;

  /// After the rows (ครั้งถัดไป).
  final Widget? footer;

  @override
  State<DueBoxes> createState() => _DueBoxesState();
}

class _DueBoxesState extends State<DueBoxes> {
  final _picked = <String>{};

  /// Amounts changed in the rows' fields, by occurrence (untouched = the
  /// occurrence's own amount).
  final _amounts = <String, double?>{};
  bool _open = false;
  bool _folded = false;

  @override
  void didUpdateWidget(DueBoxes old) {
    super.didUpdateWidget(old);
    final ids = {for (final i in widget.items) i.id};
    _picked.retainWhere(ids.contains);
    _amounts.removeWhere((id, _) => !ids.contains(id));
  }

  Map<String, double> get _typed => {
    for (final MapEntry(:key, :value) in _amounts.entries) key: ?value,
  };

  Future<void> _settle(
    List<RecurringItem> items, {
    required SettleAction action,
  }) async {
    if (items.isEmpty) return;
    FocusScope.of(context).unfocus();
    final typed = _typed;
    await settleSelected(
      context,
      items,
      action: action,
      amounts: typed,
      onChanged: widget.onChanged,
    );
    if (!mounted) return;
    // A row left out for want of an amount stays picked.
    setState(
      () => _picked.removeAll([
        for (final i in items)
          if (action != SettleAction.confirm || settleAmount(i, typed) != null)
            i.id,
      ]),
    );
  }

  void _confirmOne(RecurringItem i) {
    if (!canSettleSelected(i)) {
      widget.onOpen(i);
      return;
    }
    if (settleAmount(i, _typed) == null) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.occurrenceNeedsAmount,
        tone: Tone.warning,
      );
      return;
    }
    unawaited(_settle([i], action: SettleAction.confirm));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = widget.items;
    final shown = _open ? items : items.take(widget.shownCount).toList();
    final pickable = [
      for (final i in items)
        if (canSettleSelected(i)) i,
    ];
    final picked = [
      for (final i in pickable)
        if (_picked.contains(i.id)) i,
    ];
    return DueCard(
      key: const ValueKey('dueCard'),
      title: l.occurrenceStateNotCreated,
      trailing: '${items.length}',
      open: !_folded,
      onToggle: () => setState(() => _folded = !_folded),
      children: [
        if (pickable.isNotEmpty)
          DueSelectBar(
            selected: picked.length,
            total: pickable.length,
            selectLabel: picked.isEmpty
                ? l.occurrenceSelectAll
                : l.occurrenceSelectedCount(picked.length),
            skipLabel: l.occurrenceSkipSelected,
            paidLabel: l.occurrencePaidSelected,
            confirmLabel: l.occurrenceConfirmSelected(picked.length),
            onSelectAll: () => setState(() {
              if (picked.length == pickable.length) {
                _picked.removeAll(pickable.map((i) => i.id));
              } else {
                _picked.addAll(pickable.map((i) => i.id));
              }
            }),
            onSkip: () => unawaited(_settle(picked, action: SettleAction.skip)),
            onPaid: () =>
                unawaited(_settle(picked, action: SettleAction.markPaid)),
            onConfirm: () =>
                unawaited(_settle(picked, action: SettleAction.confirm)),
          ),
        for (final i in shown) _row(l, i),
        if (items.length > widget.shownCount)
          DueMoreRow(
            key: const ValueKey('dueMore'),
            label: _open
                ? l.occurrenceShowLess
                : l.occurrenceDueMore(items.length),
            onTap: () => setState(() => _open = !_open),
          ),
        if (_open && widget.more != null) widget.more!,
        ?widget.footer,
      ],
    );
  }

  /// A due row: the check, [DueBoxes.leading], the name, then the wallet
  /// and date | caption; the amount field (filled in when known) and ✓.
  Widget _row(AppLocalizations l, RecurringItem i) {
    final extra = widget.caption?.call(i);
    return AppListRow(
      key: ValueKey('due-${i.id}'),
      checked: canSettleSelected(i) ? _picked.contains(i.id) : null,
      onCheck: () => setState(() {
        if (!_picked.remove(i.id)) _picked.add(i.id);
      }),
      leading: widget.leading(i),
      title: widget.titleOf?.call(i) ?? i.title,
      status: widget.tag?.call(i),
      // On this page the wallet leads line 2, so the name keeps its room.
      line2: ListRowLine(
        lead: occurrenceWalletChip(context, i.account),
        parts: [
          // หนี้: with whom, จดหนี้ | จ่ายหนี้ (one rule's list has them in
          // its hero already).
          if (widget.showDate) ...occurrenceDebtParts(l, i),
          if (widget.showDate)
            DateFormat.MMMEd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(i.date),
          ?extra,
        ],
      ),
      actions: [
        ListRowAction.amount(
          key: ValueKey('dueAmount-${i.id}'),
          value: _amounts.containsKey(i.id) ? _amounts[i.id] : knownAmount(i),
          onChanged: (v) => _amounts[i.id] = v,
          hint: l.fpRecurringAwaitingAmount,
        ),
        ListRowAction.button(
          AppIcons.check,
          tooltip: l.occurrenceConfirm,
          onTap: () => _confirmOne(i),
        ),
      ],
      onTap: () => widget.onOpen(i),
    );
  }
}

/// The amount an occurrence already has, or null while it waits for one.
double? knownAmount(RecurringItem i) => needsAmountInput(i) ? null : i.amount;

/// A list row's ✓ (the month, a picked day): records [i] with the amount in
/// its field. With no amount it only says so (enter one first). A row that
/// can't be written by slot opens [onOpen] instead.
void confirmOccurrenceRow(
  BuildContext context,
  RecurringItem i, {
  required double? typed,
  required ValueChanged<ItemWriteResult> onChanged,
  required VoidCallback onOpen,
}) {
  if (!canSettleSelected(i)) {
    onOpen();
    return;
  }
  final amounts = {i.id: ?typed};
  if (settleAmount(i, amounts) == null) {
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.occurrenceNeedsAmount,
      tone: Tone.warning,
    );
    return;
  }
  FocusScope.of(context).unfocus();
  unawaited(
    settleSelected(
      context,
      [i],
      action: SettleAction.confirm,
      amounts: amounts,
      onChanged: onChanged,
    ),
  );
}
