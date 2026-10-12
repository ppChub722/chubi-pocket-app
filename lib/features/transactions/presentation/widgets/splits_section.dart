import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../domain/refs.dart';

/// One person of the transaction form's "หารกับ" — who (a contact, or just
/// a name) and what they owe. A contact comes from the picker
/// ([showContactPickerSheet], tap the avatar); a name that isn't a contact
/// is typed in the row itself (owner 2026-10-11):
///   - a contact picked ⇒ [contactId] set, [personName] its name (read-only
///     in the row — a link can't be broken by typing);
///   - a name typed in the row ⇒ [personName] only.
///
/// A saved split ([debtId]) remembers who it was saved with. Anyone can be
/// renamed or swapped via the picker (owner 2026-10-12): a typed name or a
/// plain contact in place; a contact linked to an app user is a
/// remove + add on the BE (the row comes back with a NEW debt_id — the
/// caller re-reads the splits from the response).
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

  /// The person's look (icon, linked 🔗) as the API embedded it on a saved
  /// split, or as the contact picker returned it — no contacts cache. Null
  /// = a typed name, or a contact whose look isn't known (plain contact).
  EmbeddedPerson? person;
  final EmbeddedPerson? _savedPerson;

  /// A saved transaction's split: the debt row it made.
  final String? debtId;

  /// Who it was saved with (a saved row's identity as loaded).
  final String _savedName;
  final String? _savedContactId;
  String? get savedContactId => _savedContactId;

  /// Already paid back on that debt — shown, never a limit: the amount may
  /// go below it (then it's overpaid) and the row may be removed.
  final double settledAmount;

  /// That debt was cancelled (it stays so; its amount can still change).
  final bool cancelled;

  bool get isSaved => debtId != null;
  bool get hasRepayments => settledAmount > 0.005;

  /// Picks [name] (and [contact], when it's one from the book) as this
  /// row's person.
  /// [look] is the picked contact's look; going back to the saved contact
  /// restores the saved look.
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

  /// One entry of PUT /transactions/:id/splits (the whole list goes up).
  /// A saved split by its debt; unless locked, plus what changed about who
  /// (contract 2026-10-11): a rename → `person_name`; another contact →
  /// `contact_id` (+ its name); back to a typed name → `"contact_id": null`
  /// EXPLICITLY + `person_name`. Omitted `contact_id` = unchanged. A new
  /// one like at create.
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

/// "หารเท่ากัน" (owner 2026-10-11): [total] over [people] rows AND me, the
/// same to the satang each — the rounding remainder goes on me, so nothing
/// is left to split.
({double each, double me}) splitEquallyWithMe(double total, int people) {
  final cents = (total * 100).round();
  final each = cents ~/ (people + 1);
  return (each: each / 100, me: (cents - each * people) / 100);
}

/// What's still to split: [total] − (me + the people's amounts). 0 =
/// balanced (the only state that saves once ฉัน is there), negative = over.
double splitLeft(double total, double? me, Iterable<SplitDraft> drafts) {
  var left = total - (me ?? 0);
  for (final d in drafts) {
    left -= d.owedAmount ?? 0;
  }
  return double.parse(left.toStringAsFixed(2));
}

/// The "หารกับ" editor of the transaction form, create + edit only (owner
/// 2026-10-10 / 11):
///
///   หารกับ                      [+ เพิ่มคน] [หารเท่ากัน]
///   (me) ฉัน                              ฿400.00  ⟳
///   (👤) [ลี____]                         ฿300.00  ✕
///   (🙂) บี                                ฿300.00  ✕
///                                  ✓ แบ่งครบแล้ว
///
/// [onMeChanged] set → once there's anyone to split with, "ฉัน" heads the
/// list (my share) and a "ยังไม่ได้แบ่ง ฿x" line closes it: [totalAmount] −
/// (ฉัน + everyone). It must reach 0 to save ([splitLeft]). The ⟳ icon in
/// ฉัน's ✕ slot ([meAuto], "อัตโนมัติ") keeps ฉัน at what's left; typing ฉัน
/// turns it off, tapping it turns it back on. [+ เพิ่มคน] adds an empty row
/// with its name input focused. A person's avatar is one of three looks
/// ([PersonLevel]); tapping it opens the contact picker (search, or
/// "สร้างผู้ติดต่อใหม่"); an app-linked saved row is locked. The name is a text
/// input for a typed name, plain text (same size) for a contact. Returns
/// the drafts via [onChanged].
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
    this.helper,
    super.key,
  });

  /// A small line under the title ("การหารนี้จะอยู่ในอีเวนต์ …").
  final String? helper;

  /// "หารกับ" (expense: they owe me) / "แบ่งให้" (income: I owe them).
  final String label;

  /// What the people + ฉัน must add up to — the transaction's amount, or
  /// for an event bill my share of it.
  final double totalAmount;

  /// My own share (ฉัน); null = not typed yet.
  final double? me;

  /// Null = no ฉัน row (the old over-the-total check only).
  final ValueChanged<double?>? onMeChanged;

  /// ฉัน follows what's left ([me] is that); the chip shows highlighted.
  final bool meAuto;

  /// The "อัตโนมัติ" chip; null = no chip.
  final ValueChanged<bool>? onMeAutoChanged;

  /// The over-the-limit line without ฉัน; default "ยอดหารรวมเกินยอดรายการ".
  final String? overText;

  /// Inside the one "แบ่งรายการ" section ([SplitEventSection]): no card of
  /// its own — a row-label line ([label], "แบ่งยอด") with เพิ่มคน and (only
  /// with at least one person) หารเท่ากัน, then the people, inset like
  /// the detail rows around them.
  final bool embedded;

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

  /// The row just added by "+ เพิ่มคน": its name input takes the focus.
  SplitDraft? _justAdded;

  void _addPerson() {
    final d = SplitDraft();
    _justAdded = d;
    widget.onChanged([...widget.drafts, d]);
  }

  /// The picker's answer onto [d]: a contact links it, a typed name
  /// unlinks it.
  static void _apply(SplitDraft d, ContactPickResult r) {
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
          ),
        );
      case ContactNameTyped(:final name):
        d.setPerson(name.trim());
    }
  }

  Future<void> _changePerson(SplitDraft d) async {
    final r = await showContactPickerSheet(
      context,
      selectedContactId: d.contactId,
      // A typed name lives in the row; a new contact is made over the picker.
      allowFreeText: false,
      allowCreate: true,
      // A contact's row can go back to a typed name, keeping this one.
      unlinkAs: d.contactId != null && d.personName.trim().isNotEmpty
          ? d.personName
          : null,
    );
    if (r == null || !mounted) return;
    _apply(d, r);
    widget.onChanged(List.of(widget.drafts));
  }

  void _splitEqually() {
    final n = widget.drafts.length;
    if (n == 0 || widget.totalAmount <= 0) return;
    if (widget.onMeChanged == null) {
      // No ฉัน row: the others get total / headcount (me counted in).
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
    // On auto, ฉัน already comes out as the remainder; typed, set it.
    if (!widget.meAuto) widget.onMeChanged!(r.me);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final sectioned = widget.embedded;
    final pills = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppChip(
          icon: AppIcons.add,
          label: l.txSplitAddPerson,
          tone: AppChipTone.primary,
          selected: true,
          onTap: _addPerson,
        ),
        if (!widget.embedded || widget.drafts.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          AppChip(
            icon: AppIcons.split,
            label: l.txSplitEqually,
            tone: AppChipTone.primary,
            selected: true,
            enabled: widget.drafts.isNotEmpty && widget.totalAmount > 0,
            onTap: _splitEqually,
          ),
        ],
      ],
    );
    // A section row is inset like the detail rows around it.
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
          _MeRow(
            amount: widget.me,
            auto: widget.meAuto,
            onAutoChanged: widget.onMeAutoChanged,
            onChanged: (v) => widget.onMeChanged!(v),
          ),
        ),
      for (var i = 0; i < widget.drafts.length; i++)
        inset(
          _DraftRow(
            // Key by the draft object itself: removing a middle row must
            // drop THAT row's controller, not shift amounts onto siblings.
            key: ObjectKey(widget.drafts[i]),
            draft: widget.drafts[i],
            autofocusName: identical(widget.drafts[i], _justAdded),
            onChange: () => widget.onChanged(List.of(widget.drafts)),
            onChangePerson: () => _changePerson(widget.drafts[i]),
            onRemove: () {
              final next = List<SplitDraft>.of(widget.drafts)..removeAt(i);
              widget.onChanged(next);
            },
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

    // The detail page: its own section, the pills in the title row, a
    // hairline between people.
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
    if (widget.embedded) {
      // The one section's "แบ่งยอด" row: the row label (same style as
      // "อีเวนต์") with the actions, then the people. No separators.
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

/// `ยังไม่ได้แบ่ง ฿x` · `✓ แบ่งครบแล้ว` · `แบ่งเกิน ฿x` (red), right-aligned
/// under the amounts.
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

/// The amount field of a split row — thousands formatting, the ฿ stuck to
/// the digits like the hero's amount, the whole box a tap target; synced
/// from outside ("หารเท่ากัน") without clobbering what's typed.
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
    // Comparing values, not text, so a half-typed "1,234." isn't clobbered.
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
    // The in-card underline field: the symbol hugs the digits, thousands
    // formatting and right alignment come from the amount type.
    return SizedBox(
      // Room for "฿96,248.33".
      width: 104,
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

/// `(me) ส่วนของฉัน  ฿amount  ⟳` — my own share, the same slots as a person
/// row ([SplitRow]), with my own avatar. The ⟳ ("อัตโนมัติ") sits in the
/// trailing slot, a tinted circle while ฉัน follows what's left ([auto]).
class _MeRow extends StatelessWidget {
  const _MeRow({
    required this.amount,
    required this.auto,
    required this.onAutoChanged,
    required this.onChanged,
  });
  final double? amount;
  final bool auto;
  final ValueChanged<bool>? onAutoChanged;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final me = context.select<AuthCubit, (String, IconCode?)?>((c) {
      final s = c.state;
      return s is AuthAuthenticated
          ? (s.user.displayName, s.user.iconCode)
          : null;
    });
    return SplitRow(
      // The 🔗's slot keeps names lined up with the people's.
      avatar: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            displayName: me?.$1 ?? l.txSplitMe,
            iconCode: me?.$2,
            size: SplitRow.avatarSize,
          ),
          SizedBox(width: PersonMark.linkSlotWidth(SplitRow.avatarSize)),
        ],
      ),
      name: SplitRowName.muted(l.txSplitMe),
      amount: _AmountBox(value: amount, onChanged: onChanged),
      trailing: onAutoChanged == null
          ? null
          : SplitRowAction(
              icon: AppIcons.auto,
              tooltip: l.txSplitAuto,
              selected: auto,
              onTap: () => onAutoChanged!(!auto),
            ),
    );
  }
}

/// One person: `(avatar) name  ฿amount  ✕` on a [SplitRow]. The avatar
/// opens the contact picker ([onChangePerson]). Level 1 (a typed name): an
/// outlined input; level 2 / 3 (a contact, linked): the name on a faint
/// highlight in the avatar's colour — tap → the picker (which can also go
/// back to a typed name, "ไม่ผูกผู้ติดต่อ").
class _DraftRow extends StatefulWidget {
  const _DraftRow({
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

  /// A row just added: focus its name input.
  final bool autofocusName;

  @override
  State<_DraftRow> createState() => _DraftRowState();
}

class _DraftRowState extends State<_DraftRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.draft.personName,
  );
  final _nameFocus = FocusNode();

  @override
  void didUpdateWidget(covariant _DraftRow old) {
    super.didUpdateWidget(old);
    // A contact picked / re-picked changes the name from outside.
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
      size: SplitRow.avatarSize,
      reserveLinkSlot: true,
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
        : SplitRowName.picked(draft.personName, onTap: widget.onChangePerson);

    final row = SplitRow(
      avatar: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChangePerson,
        child: mark,
      ),
      name: name,
      amount: _AmountBox(
        value: draft.owedAmount,
        onChanged: (v) {
          draft.owedAmount = v;
          widget.onChange();
        },
      ),
      // Repayments don't limit edits (owner 2026-10-10): anyone can be
      // removed, whatever they paid back.
      trailing: SplitRowAction(
        icon: AppIcons.close,
        tooltip: l.txSplitRemove,
        onTap: widget.onRemove,
      ),
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
