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
    this.color,
    this.amount,
    this.auto = false,
    this.onAmount,
    this.onAuto,
    this.paid = false,
    this.onPay,
    this.canPaidBack = false,
    this.paidBack = false,
    this.onPaidBack,
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

  /// The picked name pill's colour (the person's colour 1); null = the
  /// name-hash colour.
  final Color? color;

  final double? amount;
  final bool auto;

  /// Null = the amount can't be typed (the payer's is what is left).
  final ValueChanged<double?>? onAmount;

  /// The "A" toggle at the end of the row (no remove then).
  final ValueChanged<bool>? onAuto;

  /// The one who paid: ✓ จ่าย; the others get a dashed chip when [onPay]
  /// (no chip with neither).
  final bool paid;
  final VoidCallback? onPay;

  /// "คืนแล้ว" applies to this row: ✓ when [paidBack], tap = [onPaidBack]
  /// (none: shown, not tappable yet).
  final bool canPaidBack;
  final bool paidBack;
  final VoidCallback? onPaidBack;

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
    this.payLabel,
    this.addLabel,
    this.showEqually = true,
    this.flat = false,
    this.statusLeading,
    this.readOnly = false,
    super.key,
  });

  /// A saved bill being viewed (owner 2026-11-04): no header buttons, no ×
  /// or auto toggle, only the chips that are on, amounts in fixed boxes.
  final bool readOnly;

  /// See [ShareCard.flat].
  final bool flat;

  /// See [ShareCard.statusLeading].
  final Widget? statusLeading;

  final String title;
  final List<BillPerson> people;
  final VoidCallback onAdd;

  /// The add button's word (default "+ เพิ่มคน"); the bill form's คนจ่าย
  /// section says "+ เพิ่มคนจ่าย" (0.4.1-2 multi-payer).
  final String? addLabel;

  /// False: no หารเท่ากัน button (a list of payers, not shares).
  final bool showEqually;

  /// The payer chip's word; default "จ่าย" (an income: "รับ").
  final String? payLabel;

  /// Null = หารเท่ากัน is disabled.
  final VoidCallback? onEqually;

  /// A row above the header (the "add to event" row), set off by a divider.
  final Widget? top;
  final ShareStatus? status;

  /// More rows than this scroll inside the card.
  final int? maxRows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = [
      for (final p in people)
        _BillPersonRow(
          key: ValueKey(p.id),
          person: p,
          payLabel: payLabel ?? l.evbPays,
          readOnly: readOnly,
        ),
    ];
    final max = maxRows;
    // A row: the name line, the chips line, a little for a tag.
    final rowHeight =
        SplitRow.height + ChipSize.mini.heightOf(context) + PpForgeSpacing.md;
    return ShareCard(
      flat: flat,
      statusLeading: statusLeading,
      top: top,
      title: title,
      showHeader: !readOnly,
      actions: [
        if (showEqually && !readOnly)
          PpForgeButton(
            kind: ButtonIconKind.split,
            label: l.txSplitEqually,
            variant: PpForgeButtonVariant.outlined,
            size: PpForgeButtonSize.control,
            onPressed: onEqually,
          ),
        if (!readOnly)
          PpForgeButton(
            icon: AppIcons.add,
            label: addLabel ?? l.txSplitAddPerson,
            variant: PpForgeButtonVariant.outlined,
            size: PpForgeButtonSize.control,
            onPressed: onAdd,
          ),
      ],
      rows: [
        if (max == null)
          ...rows
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: max * rowHeight),
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
  const _BillPersonRow({
    required this.person,
    required this.payLabel,
    this.readOnly = false,
    super.key,
  });

  final BillPerson person;
  final String payLabel;
  final bool readOnly;

  @override
  State<_BillPersonRow> createState() => _BillPersonRowState();
}

class _BillPersonRowState extends State<_BillPersonRow> {
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
    final readOnly = widget.readOnly;
    final Widget name = p.isMe
        ? SplitRowName.muted(p.name)
        : readOnly
        ? SplitRowName.picked(p.name, onTap: null, color: p.color)
        : p.editableName
        ? SplitRowName.input(
            controller: _name,
            focusNode: _nameFocus,
            autofocus: p.autofocusName,
            maxLength: TextLimits.name,
            hint: l.txSplitNameHint,
            onChanged: p.onName,
          )
        : SplitRowName.picked(p.name, onTap: p.onChangePerson, color: p.color);
    final change = p.isMe || readOnly ? null : p.onChangePerson;
    final avatar = change == null
        ? p.avatar
        : BusyLock(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: change,
              child: p.avatar,
            ),
          );
    return ShareRow(
      avatar: avatar,
      name: name,
      chips: Wrap(
        spacing: PpForgeSpacing.xs,
        runSpacing: PpForgeSpacing.xs,
        children: [
          if (p.paid || (p.onPay != null && !readOnly))
            PayChip(
              label: widget.payLabel,
              paid: p.paid,
              onTap: readOnly ? null : p.onPay,
            ),
          if (p.canPaidBack && (p.paidBack || !readOnly))
            PaidBackChip(
              label: l.evbPaidBack,
              paidBack: p.paidBack,
              onTap: readOnly ? null : p.onPaidBack,
            ),
        ],
      ),
      amount: ShareAmountField(
        value: p.amount,
        auto: p.auto,
        onChanged: readOnly ? null : p.onAmount,
      ),
      trailing: readOnly
          ? null
          : p.onRemove != null
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
