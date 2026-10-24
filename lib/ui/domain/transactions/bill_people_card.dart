import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';

/// One row of a [BillPeopleCard]: who, what they owe in the bill, who paid.
@immutable
class BillPerson {
  const BillPerson({
    required this.id,
    required this.name,
    required this.avatar,
    this.isMe = false,
    this.editableName = false,
    this.autofocusName = false,
    this.onName,
    this.onChangePerson,
    this.amount,
    this.auto = false,
    this.onAmount,
    this.onAuto,
    this.paid = false,
    this.onPay,
    this.chips = const [],
    this.tag,
    this.onRemove,
  });

  /// Stable across rebuilds (the row keeps its typed name by it).
  final Object id;
  final String name;
  final Widget avatar;
  final bool isMe;

  /// A name that was typed, not picked: an input in the row.
  final bool editableName;
  final bool autofocusName;
  final ValueChanged<String>? onName;

  /// Tap the avatar / the picked name to pick somebody else.
  final VoidCallback? onChangePerson;

  final double? amount;
  final bool auto;

  /// Null = the amount can't be typed (the payer's is what is left).
  final ValueChanged<double?>? onAmount;

  /// The "A" toggle at the end of the row (no remove then).
  final ValueChanged<bool>? onAuto;

  /// The one who paid: ✓ จ่าย; the others get a dashed chip when [onPay].
  final bool paid;
  final VoidCallback? onPay;

  /// More chips after "จ่าย" (คืนแล้ว).
  final List<Widget> chips;

  /// Under the name ("ใหม่ | เพิ่มเข้าอีเวนต์").
  final Widget? tag;

  /// × at the end of the row; null = none (or [onAuto]'s toggle instead).
  final VoidCallback? onRemove;
}

/// "คนในบิล | n": ONE card for the people of a bill, in the event bill sheet
/// and in quick create's แบ่ง tab. Rows keep the order given (ฉัน first; the
/// payer never moves, a "จ่าย" chip says who it is), a typed name is an input
/// that can be changed, and the header buttons are หารเท่ากัน / เพิ่มคน.
class BillPeopleCard extends StatelessWidget {
  const BillPeopleCard({
    required this.title,
    required this.people,
    required this.onAdd,
    this.onEqually,
    this.top,
    this.status,
    this.maxRows,
    super.key,
  });

  final String title;
  final List<BillPerson> people;
  final VoidCallback onAdd;

  /// Null = หารเท่ากัน is disabled.
  final VoidCallback? onEqually;

  /// A row above the header (the "add to event" row), set off by a divider.
  final Widget? top;
  final ShareStatus? status;

  /// More rows than this scroll inside the card.
  final int? maxRows;

  static const double _rowHeight = 56;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = [
      for (final p in people) _BillPersonRow(key: ValueKey(p.id), person: p),
    ];
    final max = maxRows;
    return ShareCard(
      top: top,
      title: title,
      actions: [
        AppButton(
          label: l.txSplitEqually,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.control,
          onPressed: onEqually,
        ),
        AppButton(
          icon: AppIcons.add,
          label: l.txSplitAddPerson,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.control,
          onPressed: onAdd,
        ),
      ],
      rows: [
        if (max == null)
          ...rows
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: max * _rowHeight),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: rows,
            ),
          ),
      ],
      status: status,
    );
  }
}

class _BillPersonRow extends StatefulWidget {
  const _BillPersonRow({required this.person, super.key});

  final BillPerson person;

  @override
  State<_BillPersonRow> createState() => _BillPersonRowState();
}

class _BillPersonRowState extends State<_BillPersonRow> {
  static const double _nameInputWidth = 150;

  late final TextEditingController _name = TextEditingController(
    text: widget.person.name,
  );
  final _nameFocus = FocusNode();

  @override
  void didUpdateWidget(covariant _BillPersonRow old) {
    super.didUpdateWidget(old);
    if (_name.text != widget.person.name) _name.text = widget.person.name;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.person;
    final Widget name = p.isMe
        ? SplitRowName.muted(p.name)
        : p.editableName
        // A name is short: the chips and the amount stay next to it.
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _nameInputWidth),
            child: SplitRowName.input(
              controller: _name,
              focusNode: _nameFocus,
              autofocus: p.autofocusName,
              maxLength: TextLimits.name,
              hint: l.txSplitNameHint,
              onChanged: p.onName,
            ),
          )
        : SplitRowName.picked(p.name, onTap: p.onChangePerson);
    final change = p.isMe ? null : p.onChangePerson;
    final avatar = change == null
        ? p.avatar
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: change,
            child: p.avatar,
          );
    final chips = [
      if (p.onPay != null || p.paid)
        PayChip(label: l.evbPays, paid: p.paid, onTap: p.onPay),
      ...p.chips,
    ];
    return ShareRow(
      avatar: avatar,
      name: name,
      nameTrailing: chips.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, c) in chips.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  c,
                ],
              ],
            ),
      amount: ShareAmountField(
        value: p.amount,
        auto: p.auto,
        onChanged: p.onAmount,
      ),
      trailing: p.onRemove != null
          ? SplitRowAction(
              icon: AppIcons.close,
              tooltip: l.txSplitRemove,
              onTap: p.onRemove,
            )
          : p.onAuto != null
          ? AutoToggleChip(
              value: p.auto,
              tooltip: l.txSplitAuto,
              onChanged: p.onAuto,
            )
          : null,
      tag: p.tag,
    );
  }
}
