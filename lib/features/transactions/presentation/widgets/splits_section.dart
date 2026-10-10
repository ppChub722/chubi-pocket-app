import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';

/// One person of the transaction form's "หารกับ" — who (a contact, or just
/// a name) and what they owe. The person always comes from the contact
/// picker ([showContactPickerSheet]), never a free text field, so a link
/// can't be broken by typing (owner 2026-10-10):
///   - a contact picked ⇒ [contactId] set, [personName] its name;
///   - a name typed in the picker ⇒ [personName] only.
///
/// A saved split ([debtId]) remembers who it was saved with. Only a contact
/// linked to an app user ([PersonLevel.linked], [savedContactLinked]) locks
/// it ([identityLocked] — remove + add instead; the BE says
/// SPLIT_IDENTITY_LOCKED); a typed name or a plain contact can be renamed
/// or re-picked in place, keeping the debt and its repayments (owner
/// 2026-10-11).
class SplitDraft {
  SplitDraft({
    String? personName,
    this.contactId,
    this.contactDisplayName,
    this.owedAmount,
    this.debtId,
    this.settledAmount = 0,
    this.cancelled = false,
    this.savedContactLinked = false,
  }) : personName = personName ?? '',
       _savedName = personName ?? '',
       _savedContactId = contactId;

  String personName;
  String? contactId;
  String? contactDisplayName;
  double? owedAmount;

  /// A saved transaction's split: the debt row it made.
  final String? debtId;

  /// Who it was saved with (a saved row's identity as loaded).
  final String _savedName;
  final String? _savedContactId;
  String? get savedContactId => _savedContactId;

  /// The saved contact is linked to an app user (filled in from the
  /// contacts once they're known) — that, and only that, locks the row.
  bool savedContactLinked;

  /// Already paid back on that debt — shown, never a limit: the amount may
  /// go below it (then it's overpaid) and the row may be removed.
  final double settledAmount;

  /// That debt was cancelled (it stays so; its amount can still change).
  final bool cancelled;

  bool get isSaved => debtId != null;
  bool get hasRepayments => settledAmount > 0.005;

  /// Saved with a contact linked to an app user: who it is can't change
  /// here — remove + add instead.
  bool get identityLocked =>
      isSaved && _savedContactId != null && savedContactLinked;

  /// Picks [name] (and [contact], when it's one from the book) as this
  /// row's person. Not for an [identityLocked] row.
  void setPerson(String name, {String? contact}) {
    assert(!identityLocked);
    personName = name;
    contactId = contact;
    contactDisplayName = contact == null ? null : name;
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
    if (identityLocked) return out;
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
///   [(me) ฉัน] [⟳ อัตโนมัติ]                  ฿400.00
///   [👤 ลี]                                 ฿300.00  ✕
///   [(🙂) บี]                                ฿300.00  ✕
///                                  ✓ แบ่งครบแล้ว
///
/// [onMeChanged] set → once there's anyone to split with, "ฉัน" heads the
/// list (my share) and a "ยังไม่ได้แบ่ง ฿x" line closes it: [totalAmount] −
/// (ฉัน + everyone). It must reach 0 to save ([splitLeft]). The
/// "อัตโนมัติ" chip on ฉัน ([meAuto]) keeps ฉัน at what's left; typing ฉัน
/// turns it off, tapping it turns it back on. [+ เพิ่มคน] opens the contact picker first — cancel
/// it and no row is added. A person is a chip in one of three looks
/// ([PersonLevel]); tapping it re-opens the picker (an app-linked saved row
/// is locked). Returns the drafts via [onChanged].
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
    this.sectioned = false,
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

  /// The detail page: a [SectionCard] of its own — [label] and the pills
  /// in its title row, one inset row per person with hairlines between.
  final bool sectioned;

  final List<SplitDraft> drafts;
  final ValueChanged<List<SplitDraft>> onChanged;

  @override
  State<SplitsSection> createState() => _SplitsSectionState();
}

class _SplitsSectionState extends State<SplitsSection> {
  @override
  void initState() {
    super.initState();
    // The people's looks and locks need the contacts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContactsCubit>().loadIfNeeded();
    });
  }

  bool get _withMe => widget.onMeChanged != null && widget.drafts.isNotEmpty;

  double get _peopleTotal {
    var total = 0.0;
    for (final d in widget.drafts) {
      total += d.owedAmount ?? 0;
    }
    return total;
  }

  Future<void> _addPerson() async {
    final r = await showContactPickerSheet(context);
    if (r == null || !mounted) return;
    final d = SplitDraft();
    _apply(d, r);
    widget.onChanged([...widget.drafts, d]);
  }

  /// The picker's answer onto [d]: a contact links it, a typed name
  /// unlinks it.
  static void _apply(SplitDraft d, ContactPickResult r) {
    switch (r) {
      case ContactPicked(:final contact):
        d.setPerson(contact.effectiveName, contact: contact.id);
      case ContactNameTyped(:final name):
        d.setPerson(name.trim());
    }
  }

  Future<void> _changePerson(SplitDraft d) async {
    final r = await showContactPickerSheet(
      context,
      selectedContactId: d.contactId,
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
    final sectioned = widget.sectioned;
    // Contacts by id — the people's looks, and which saved rows lock.
    final contacts = context.select<ContactsCubit, Map<String, Contact>>(
      (c) => {for (final x in c.state.contacts) x.id: x},
    );
    for (final d in widget.drafts) {
      final saved = d.savedContactId;
      d.savedContactLinked =
          saved != null && (contacts[saved]?.isLinked ?? false);
    }
    final pills = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionPill(
          icon: AppIcons.add,
          label: l.txSplitAddPerson,
          onTap: _addPerson,
        ),
        const SizedBox(width: AppSpacing.xs),
        ActionPill(
          icon: AppIcons.split,
          label: l.txSplitEqually,
          onTap: widget.drafts.isEmpty || widget.totalAmount <= 0
              ? null
              : _splitEqually,
        ),
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
            contact: contacts[widget.drafts[i].contactId],
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
    if (sectioned) {
      // The helper sits under the title, before the people (no hairline
      // between the two: one Column).
      return SectionCard(
        title: widget.label,
        trailing: pills,
        children: [
          if (helper != null || rows.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [?helper, ?rows.firstOrNull],
            ),
          ...rows.skip(1),
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
          Icon(icon, size: 16, color: color),
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

/// The amount field of a split row — thousands formatting, an underline,
/// synced from outside ("หารเท่ากัน") without clobbering what's typed.
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

  static String _formatted(double? v) => v == null ? '' : AmountField.format(v);

  @override
  void didUpdateWidget(covariant _AmountBox old) {
    super.didUpdateWidget(old);
    // Comparing values, not text, so a half-typed "1,234." isn't clobbered.
    if (AmountField.parse(_amount.text) != widget.value) {
      _amount.text = _formatted(widget.value);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      // Room for "฿96,248.33".
      width: 120,
      child: TextField(
        controller: _amount,
        textAlign: TextAlign.end,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ThousandsInputFormatter()],
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        // One line, an underline to show it's editable.
        decoration: InputDecoration(
          hintText: '0',
          prefixText: '฿',
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.primary),
          ),
        ),
        onChanged: (v) => widget.onChanged(AmountField.parse(v)),
      ),
    );
  }
}

/// The ✕ slot — the ฉัน row keeps the room so the amounts line up.
const double _removeSlot = 36;

/// `[(me) ฉัน] [⟳ อัตโนมัติ]  ฿amount` — my own share, the same layout as
/// a person row, with my own icon and no ✕. The chip is highlighted while
/// ฉัน follows what's left ([auto]).
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
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: RowChip(
                    label: l.txSplitMe,
                    leading: UserAvatar(
                      displayName: me?.$1 ?? l.txSplitMe,
                      iconCode: me?.$2,
                      size: 20,
                    ),
                  ),
                ),
                if (onAutoChanged != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  RowChip(
                    label: l.txSplitAuto,
                    icon: AppIcons.auto,
                    selected: auto,
                    onTap: () => onAutoChanged!(!auto),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _AmountBox(value: amount, onChanged: onChanged),
        const SizedBox(width: _removeSlot),
      ],
    );
  }
}

/// One person: `[mark name]  ฿amount  ✕`. The chip opens the picker
/// ([onChangePerson]) — locked (🔒, a hint on tap) for a saved row whose
/// contact is linked to an app user.
class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.draft,
    required this.contact,
    required this.onChange,
    required this.onChangePerson,
    required this.onRemove,
    super.key,
  });

  final SplitDraft draft;

  /// The picked contact, when it's loaded (its look: plain or linked).
  final Contact? contact;
  final VoidCallback onChange;
  final VoidCallback onChangePerson;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locked = draft.identityLocked;
    final c = contact;
    final level = draft.contactId == null
        ? PersonLevel.name
        : (c?.isLinked ?? false)
        ? PersonLevel.linked
        : PersonLevel.contact;
    final chip = RowChip(
      label: draft.personName,
      leading: PersonMark(
        name: draft.personName,
        level: level,
        iconCode: c?.effectiveIconCode,
      ),
      trailingIcon: locked ? AppIcons.lock : null,
      onTap: locked ? null : onChangePerson,
    );
    final row = Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: locked
                // Tap → why, instead of silently nothing.
                ? Tooltip(
                    message: l.txSplitPersonLockedLinked,
                    triggerMode: TooltipTriggerMode.tap,
                    child: chip,
                  )
                : chip,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _AmountBox(
          value: draft.owedAmount,
          onChanged: (v) {
            draft.owedAmount = v;
            onChange();
          },
        ),
        // Repayments don't limit edits (owner 2026-10-10): anyone can be
        // removed, whatever they paid back.
        IconButton(
          tooltip: l.txSplitRemove,
          icon: const Icon(AppIcons.close, size: 18),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: _removeSlot,
            minHeight: _removeSlot,
          ),
          color: scheme.onSurfaceVariant,
          onPressed: onRemove,
        ),
      ],
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
