import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../domain/refs.dart';

class SplitDraft {
  SplitDraft({
    String? personName,
    this.contactId,
    this.contactDisplayName,
    this.owedAmount,
    this.debtId,
    this.settledAmount = 0,
    this.cancelled = false,
    EmbeddedPerson? savedPerson,
  }) : personName = personName ?? '',
       _savedName = personName ?? '',
       _savedContactId = contactId,
       _savedPerson = savedPerson,
       person = savedPerson;

  String personName;
  String? contactId;
  String? contactDisplayName;
  double? owedAmount;

  EmbeddedPerson? person;
  final EmbeddedPerson? _savedPerson;

  final String? debtId;

  final String _savedName;
  final String? _savedContactId;
  String? get savedContactId => _savedContactId;

  final double settledAmount;

  final bool cancelled;

  bool get isSaved => debtId != null;
  bool get hasRepayments => settledAmount > 0.005;

  void setPerson(String name, {String? contact, EmbeddedPerson? look}) {
    personName = name;
    contactId = contact;
    contactDisplayName = contact == null ? null : name;
    person = contact == null
        ? null
        : look ??
              (_savedPerson?.contactId == contact
                  ? _savedPerson
                  : (person?.contactId == contact ? person : null));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'debt_id': ?debtId,
    'person_name': personName.trim(),
    if (contactId != null) 'contact_id': contactId,
    'owed_amount': owedAmount ?? 0,
    'split_type': 'fixed',
  };

  Map<String, dynamic> toUpdateJson() {
    if (!isSaved) {
      return {
        'person_name': personName.trim(),
        'contact_id': ?contactId,
        'owed_amount': owedAmount ?? 0,
      };
    }
    final out = <String, dynamic>{
      'debt_id': debtId,
      'owed_amount': owedAmount ?? 0,
    };
    if (contactId != _savedContactId) {
      out['contact_id'] = contactId; // null = drop the contact
      out['person_name'] = personName.trim();
    } else if (personName.trim() != _savedName.trim()) {
      out['person_name'] = personName.trim();
    }
    return out;
  }

  bool get isComplete => personName.trim().isNotEmpty && (owedAmount ?? 0) > 0;

  bool get isWired => contactId != null;
}

({double each, double me}) splitEquallyWithMe(double total, int people) {
  final cents = (total * 100).round();
  final each = cents ~/ (people + 1);
  return (each: each / 100, me: (cents - each * people) / 100);
}

double splitLeft(double total, double? me, Iterable<SplitDraft> drafts) {
  var left = total - (me ?? 0);
  for (final d in drafts) {
    left -= d.owedAmount ?? 0;
  }
  return double.parse(left.toStringAsFixed(2));
}

/// Puts the picked person on [d] (a contact with its look, else the name).
void applyContactPick(SplitDraft d, ContactPick r) {
  switch (r) {
    case ContactPicked(:final contact):
      d.setPerson(
        contact.name,
        contact: contact.id,
        look: EmbeddedPerson(
          name: contact.name,
          contactId: contact.id,
          iconCode: contact.iconCode,
          linked: contact.isLinked,
          linkedUserId: contact.linkedUser?.id,
        ),
      );
    case ContactNameTyped(:final name) || ContactNamePicked(:final name):
      d.setPerson(name.trim());
  }
}

/// The status line of a ผูกกับ card: [left] = what's still to place (> 0
/// ยังขาด, < 0 เกินยอด); [ok] is the ✓ words.
ShareStatus linkCardStatus(BuildContext context, double left, String ok) {
  final l = AppLocalizations.of(context)!;
  if (left.abs() <= 0.005) return ShareStatus(ok, ok: true);
  return ShareStatus(
    left > 0
        ? l.txLinkCardShort(moneyString(context, left))
        : l.txLinkCardOver(moneyString(context, -left)),
    ok: false,
  );
}

class SplitsSection extends StatefulWidget {
  const SplitsSection({
    required this.label,
    required this.totalAmount,
    required this.drafts,
    required this.onChanged,
    this.me,
    this.onMeChanged,
    this.meAuto = false,
    this.onMeAutoChanged,
    this.overText,
    this.embedded = false,
    this.compact = false,
    this.helper,
    super.key,
  });

  final String? helper;

  final String label;

  /// What the people + ฉัน must add up to — the transaction's amount, or for an
  /// event bill my share of it.
  final double totalAmount;

  final double? me;

  final ValueChanged<double?>? onMeChanged;

  final bool meAuto;

  final ValueChanged<bool>? onMeAutoChanged;

  /// The over-the-limit line without ฉัน; default "ยอดหารรวมเกินยอดรายการ".
  final String? overText;

  final bool embedded;

  final bool compact;

  final List<SplitDraft> drafts;
  final ValueChanged<List<SplitDraft>> onChanged;

  @override
  State<SplitsSection> createState() => _SplitsSectionState();
}

class _SplitsSectionState extends State<SplitsSection> {
  bool get _withMe => widget.onMeChanged != null && widget.drafts.isNotEmpty;

  double get _peopleTotal {
    var total = 0.0;
    for (final d in widget.drafts) {
      total += d.owedAmount ?? 0;
    }
    return total;
  }

  SplitDraft? _justAdded;

  void _addPerson() {
    final d = SplitDraft();
    _justAdded = d;
    widget.onChanged([...widget.drafts, d]);
  }

  Future<void> _changePerson(SplitDraft d) async {
    final r = await ContactPicker.one(
      context,
      selectedId: d.contactId,
      allowFreeText: true,
      allowCreate: true,
      initialName: d.personName.trim().isEmpty ? null : d.personName,
    );
    if (r == null || !mounted) return;
    applyContactPick(d, r);
    widget.onChanged(List.of(widget.drafts));
  }

  void _splitEqually() {
    final n = widget.drafts.length;
    if (n == 0 || widget.totalAmount <= 0) return;
    if (widget.onMeChanged == null) {
      final per = widget.totalAmount / (n + 1);
      for (final d in widget.drafts) {
        d.owedAmount = double.parse(per.toStringAsFixed(2));
      }
      widget.onChanged(List.of(widget.drafts));
      return;
    }
    final r = splitEquallyWithMe(widget.totalAmount, n);
    for (final d in widget.drafts) {
      d.owedAmount = r.each;
    }
    widget.onChanged(List.of(widget.drafts));
    if (!widget.meAuto) widget.onMeChanged!(r.me);
  }

  void _remove(int i) =>
      widget.onChanged(List<SplitDraft>.of(widget.drafts)..removeAt(i));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final sectioned = widget.embedded && !widget.compact;
    const chipSize = ChipSize.control;
    final pillChildren = <Widget>[
      AppButton(
        icon: AppIcons.add,
        label: l.txSplitAddPerson,
        variant: AppButtonVariant.outlined,
        size: AppButtonSize.control,
        onPressed: _addPerson,
      ),
      if (!widget.embedded || widget.drafts.isNotEmpty) ...[
        const SizedBox(width: AppSpacing.xs),
        AppChip(
          icon: AppIcons.split,
          label: l.txSplitEqually,
          tone: AppChipTone.primary,
          selected: true,
          size: chipSize,
          enabled: widget.drafts.isNotEmpty && widget.totalAmount > 0,
          onTap: _splitEqually,
        ),
      ],
    ];
    final pills = widget.compact
        ? Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in pillChildren)
                if (c is! SizedBox) c,
            ],
          )
        : Row(mainAxisSize: MainAxisSize.min, children: pillChildren);
    Widget inset(Widget w) => sectioned
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: w,
          )
        : w;
    final rows = <Widget>[
      if (_withMe)
        inset(
          SplitMeRow(
            label: l.txSplitMe,
            amount: widget.me,
            auto: widget.meAuto,
            onAutoChanged: widget.onMeAutoChanged,
            onChanged: (v) => widget.onMeChanged!(v),
          ),
        ),
      for (var i = 0; i < widget.drafts.length; i++)
        inset(
          SplitDraftRow(
            // Key by the draft object itself: removing a middle row must drop
            // THAT row's controller, not shift amounts onto siblings.
            key: ObjectKey(widget.drafts[i]),
            draft: widget.drafts[i],
            autofocusName: identical(widget.drafts[i], _justAdded),
            onChange: () => widget.onChanged(List.of(widget.drafts)),
            onChangePerson: () => _changePerson(widget.drafts[i]),
            onRemove: () => _remove(i),
          ),
        ),
    ];
    final edge = sectioned ? AppSpacing.lg : 0.0;
    final Widget? closing;
    if (_withMe) {
      closing = Padding(
        padding: EdgeInsets.fromLTRB(edge, AppSpacing.xs, edge, AppSpacing.xs),
        child: _LeftLine(
          left: splitLeft(widget.totalAmount, widget.me, widget.drafts),
        ),
      );
    } else if (_peopleTotal > widget.totalAmount + 0.005) {
      closing = Padding(
        padding: EdgeInsets.fromLTRB(edge, AppSpacing.xs, edge, 0),
        child: Text(
          widget.overText ?? l.txSplitOver,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    } else {
      closing = null;
    }

    final helper = widget.helper == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(edge, 0, edge, AppSpacing.xs),
            child: Text(
              widget.helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
    if (widget.embedded && widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DraftFieldRow(label: widget.label, dense: true, child: pills),
          if (widget.helper != null)
            Padding(
              padding: EdgeInsets.only(
                left: DraftFieldRow.labelWidthOf(context),
                top: AppSpacing.xs,
              ),
              child: Text(
                widget.helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final r in rows) ...[const SizedBox(height: AppSpacing.xs), r],
          if (closing != null) ...[
            const SizedBox(height: AppSpacing.xs),
            closing,
          ],
        ],
      );
    }
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.label, style: detailLabelStyle(context)),
                ),
                pills,
              ],
            ),
          ),
          ?helper,
          ...rows,
          ?closing,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            pills,
          ],
        ),
        ?helper,
        for (final r in rows) ...[const SizedBox(height: AppSpacing.xs), r],
        ?closing,
      ],
    );
  }
}

class _LeftLine extends StatelessWidget {
  const _LeftLine({required this.left});
  final double left;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final style = Theme.of(context).textTheme.bodyMedium;
    final (IconData? icon, String text, Color color) = left.abs() <= 0.005
        ? (AppIcons.success, l.txSplitBalanced, palette.success)
        : left > 0
        ? (null, l.txSplitLeft(moneyString(context, left)), palette.warning)
        : (null, l.txSplitOverBy(moneyString(context, -left)), scheme.error);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (icon != null) ...[
          AppIcon(icon, size: AppIconSize.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.end,
            style: style?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

TextStyle? _fieldStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class _AmountBox extends StatefulWidget {
  const _AmountBox({required this.value, required this.onChanged});
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_AmountBox> createState() => _AmountBoxState();
}

class _AmountBoxState extends State<_AmountBox> {
  late final TextEditingController _amount = TextEditingController(
    text: _formatted(widget.value),
  );
  final _focus = FocusNode();

  static String _formatted(double? v) => v == null ? '' : AmountInput.format(v);

  @override
  void didUpdateWidget(covariant _AmountBox old) {
    super.didUpdateWidget(old);
    if (AmountInput.parse(_amount.text) != widget.value) {
      _amount.text = _formatted(widget.value);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ShareAmountField.sampleWidth(context, _fieldStyle(context)),
      height: SplitRow.height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AppInput.card(
          controller: _amount,
          focusNode: _focus,
          type: AppInputType.amount,
          style: _fieldStyle(context),
          hint: '0',
          onChanged: (v) => widget.onChanged(AmountInput.parse(v)),
        ),
      ),
    );
  }
}

/// My avatar (from the signed-in user), the same size as a person's mark.
class MyAvatar extends StatelessWidget {
  const MyAvatar({required this.fallbackName, super.key});

  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final me = context.select<AuthCubit, AvatarData?>((c) {
      final s = c.state;
      return s is AuthAuthenticated ? s.user.avatar : null;
    });
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(
          me ?? AvatarData.forName(fallbackName),
          size: SplitRow.avatarSize,
        ),
        SizedBox(width: PersonMark.linkSlotWidth(SplitRow.avatarSize)),
      ],
    );
  }
}

/// My row: [label] ("ส่วนของฉัน", "ฉันจ่ายเอง (จากกระเป๋า)", "ฉัน"), the
/// amount, and the auto toggle (typing turns it off).
class SplitMeRow extends StatelessWidget {
  const SplitMeRow({
    required this.label,
    required this.amount,
    required this.auto,
    required this.onAutoChanged,
    required this.onChanged,
    super.key,
  });
  final String label;
  final double? amount;
  final bool auto;
  final ValueChanged<bool>? onAutoChanged;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final toggle = onAutoChanged;
    return SplitRow(
      avatar: MyAvatar(fallbackName: l.txSplitMe),
      name: SplitRowName.muted(label),
      amount: _AmountBox(value: amount, onChanged: onChanged),
      // The same auto toggle in and out of the card (owner 2026-10-23).
      trailing: toggle == null
          ? null
          : AutoToggleChip(
              value: auto,
              tooltip: l.txSplitAuto,
              onChanged: toggle,
            ),
    );
  }
}

/// One person's row: the person, what they owe ([SplitDraft.owedAmount]), ×.
class SplitDraftRow extends StatefulWidget {
  const SplitDraftRow({
    required this.draft,
    required this.onChange,
    required this.onChangePerson,
    required this.onRemove,
    this.autofocusName = false,
    super.key,
  });

  final SplitDraft draft;

  final VoidCallback onChange;
  final VoidCallback onChangePerson;
  final VoidCallback onRemove;

  final bool autofocusName;

  @override
  State<SplitDraftRow> createState() => _SplitDraftRowState();
}

class _SplitDraftRowState extends State<SplitDraftRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.draft.personName,
  );
  final _nameFocus = FocusNode();

  @override
  void didUpdateWidget(covariant SplitDraftRow old) {
    super.didUpdateWidget(old);
    if (_name.text != widget.draft.personName) {
      _name.text = widget.draft.personName;
    }
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
    final scheme = Theme.of(context).colorScheme;
    final draft = widget.draft;
    final person = draft.person;
    final level = draft.contactId == null
        ? PersonLevel.name
        : (person?.linked ?? false)
        ? PersonLevel.linked
        : PersonLevel.contact;

    final mark = PersonMark(
      name: draft.personName,
      level: level,
      iconCode: person?.iconCode,
      avatar: person?.avatar,
      size: SplitRow.avatarSize,
      reserveLinkSlot: true,
      tappable: true,
    );
    final Widget name = level == PersonLevel.name
        ? SplitRowName.input(
            controller: _name,
            focusNode: _nameFocus,
            autofocus: widget.autofocusName,
            maxLength: TextLimits.name,
            hint: l.txSplitNameHint,
            onChanged: (v) {
              draft.personName = v;
              widget.onChange();
            },
          )
        : SplitRowName.picked(
            draft.personName,
            onTap: widget.onChangePerson,
            color: ProfileColors.of(
              context,
              person?.avatar ?? AvatarData.forName(draft.personName),
            ),
          );

    final avatar = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onChangePerson,
      child: mark,
    );
    final remove = SplitRowAction(
      icon: AppIcons.close,
      tooltip: l.txSplitRemove,
      onTap: widget.onRemove,
    );
    final row = SplitRow(
      avatar: avatar,
      name: name,
      amount: _AmountBox(
        value: draft.owedAmount,
        onChanged: (v) {
          draft.owedAmount = v;
          widget.onChange();
        },
      ),
      trailing: remove,
    );
    if (!draft.hasRepayments && !draft.cancelled) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            top: AppSpacing.xs,
          ),
          child: Text(
            draft.cancelled
                ? l.txSplitStatusCancelled
                : l.txSplitRepaidSoFar(
                    moneyString(context, draft.settledAmount),
                  ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
