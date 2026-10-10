import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';

/// One person of the transaction form's "หารกับ" — who (a contact, or just
/// a name) and what they owe. The person always comes from the contact
/// picker ([showContactPickerSheet]), never a free text field, so a link
/// can't be broken by typing (owner 2026-10-10):
///   - linked: picked a contact ⇒ [contactId] set, [personName] its name;
///   - unlinked: typed a name in the picker ⇒ [personName] only.
///
/// A saved split ([debtId]) remembers who it was saved with. Unlinked, it
/// can be renamed or linked in place (the debt and its repayments stay);
/// linked, it's [identityLocked] — to change who, remove it and add again.
class SplitDraft {
  SplitDraft({
    String? personName,
    this.contactId,
    this.contactDisplayName,
    this.owedAmount,
    this.debtId,
    this.settledAmount = 0,
    this.cancelled = false,
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

  /// Already paid back on that debt — shown, never a limit: the amount may
  /// go below it (then it's overpaid) and the row may be removed.
  final double settledAmount;

  /// That debt was cancelled (it stays so; its amount can still change).
  final bool cancelled;

  bool get isSaved => debtId != null;
  bool get hasRepayments => settledAmount > 0.005;

  /// Saved with a contact: who it is can't change here (the BE refuses,
  /// SPLIT_IDENTITY_LOCKED) — remove + add instead.
  bool get identityLocked => isSaved && _savedContactId != null;

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
  /// A saved split by its debt — plus, unlinked and changed, its new name
  /// (rename in place) and / or contact (link in place); unchanged fields
  /// are left out. A new one like at create.
  Map<String, dynamic> toUpdateJson() {
    if (!isSaved) {
      return {
        'person_name': personName.trim(),
        'contact_id': ?contactId,
        'owed_amount': owedAmount ?? 0,
      };
    }
    final renamed = !identityLocked && personName.trim() != _savedName.trim();
    final linked = !identityLocked && contactId != null;
    return {
      'debt_id': debtId,
      'owed_amount': owedAmount ?? 0,
      if (renamed) 'person_name': personName.trim(),
      if (linked) 'contact_id': contactId,
    };
  }

  bool get isComplete => personName.trim().isNotEmpty && (owedAmount ?? 0) > 0;

  bool get isWired => contactId != null;
}

/// The "หารกับ" editor of the transaction form, always open (owner
/// 2026-10-10):
///
///   หารกับ                      [+ เพิ่มคน] [หารเท่ากัน]
///   [👤 ลี]                                ฿120.00  ✕
///
/// One line per person. [+ เพิ่มคน] opens the contact picker first (pick
/// a contact, or type a name there) — cancel it and no row is added. The
/// person is a chip; tapping it re-opens the picker (a saved row linked to
/// a contact is locked). "ส่วนของคุณ" isn't here: the hero card shows it
/// under the total. Returns the drafts via [onChanged].
class SplitsSection extends StatefulWidget {
  const SplitsSection({
    required this.label,
    required this.totalAmount,
    required this.drafts,
    required this.onChanged,
    this.overText,
    this.sectioned = false,
    this.helper,
    super.key,
  });

  /// A small line under the title ("การหารนี้จะอยู่ในอีเวนต์ …").
  final String? helper;

  /// "หารกับ" (expense: they owe me) / "แบ่งให้" (income: I owe them).
  final String label;

  /// What the splits may add up to — the transaction's amount, or for an
  /// event bill my share of it. Used by "split equally" + the over check.
  final double totalAmount;

  /// The over-the-limit line; default "ยอดหารรวมเกินยอดรายการ".
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
  double get _splitTotal {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final overflow = _splitTotal > widget.totalAmount + 0.005;
    final sectioned = widget.sectioned;
    final pills = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionPill(
          icon: AppIcons.add,
          label: l.txSplitAddPerson,
          size: PillSize.medium,
          onTap: _addPerson,
        ),
        const SizedBox(width: AppSpacing.xs),
        ActionPill(
          icon: AppIcons.split,
          label: l.txSplitEqually,
          size: PillSize.medium,
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
      for (var i = 0; i < widget.drafts.length; i++)
        inset(
          _DraftRow(
            // Key by the draft object itself: removing a middle row must
            // drop THAT row's controller, not shift amounts onto siblings.
            key: ObjectKey(widget.drafts[i]),
            draft: widget.drafts[i],
            onChange: () => widget.onChanged(List.of(widget.drafts)),
            onChangePerson: () => _changePerson(widget.drafts[i]),
            onRemove: () {
              final next = List<SplitDraft>.of(widget.drafts)..removeAt(i);
              widget.onChanged(next);
            },
          ),
        ),
    ];
    final over = overflow
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              sectioned ? AppSpacing.lg : 0,
              AppSpacing.xs,
              sectioned ? AppSpacing.lg : 0,
              0,
            ),
            child: Text(
              widget.overText ?? l.txSplitOver,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          )
        : null;

    // The detail page: its own section, the pills in the title row, a
    // hairline between people.
    final helper = widget.helper == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(
              sectioned ? AppSpacing.lg : 0,
              0,
              sectioned ? AppSpacing.lg : 0,
              AppSpacing.xs,
            ),
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
          ?over,
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
        ?over,
      ],
    );
  }

  void _splitEqually() {
    final n = widget.drafts.length;
    if (n == 0 || widget.totalAmount <= 0) return;
    final per = (widget.totalAmount / (n + 1)); // +1 = the user's own share
    for (final d in widget.drafts) {
      d.owedAmount = double.parse(per.toStringAsFixed(2));
    }
    widget.onChanged(List.of(widget.drafts));
  }
}

/// One person: `[👤 name]  ฿amount  ✕`. The chip opens the picker
/// ([onChangePerson]) — locked (🔒, a hint on tap) for a saved row linked
/// to a contact.
class _DraftRow extends StatefulWidget {
  const _DraftRow({
    required this.draft,
    required this.onChange,
    required this.onChangePerson,
    required this.onRemove,
    super.key,
  });

  final SplitDraft draft;
  final VoidCallback onChange;
  final VoidCallback onChangePerson;
  final VoidCallback onRemove;

  @override
  State<_DraftRow> createState() => _DraftRowState();
}

class _DraftRowState extends State<_DraftRow> {
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _formatted(widget.draft.owedAmount));
  }

  static String _formatted(double? v) => v == null ? '' : AmountField.format(v);

  static const _amountWidth = 120.0;

  @override
  void didUpdateWidget(covariant _DraftRow old) {
    super.didUpdateWidget(old);
    // Sync only when the value changed from outside ("split equally") —
    // comparing values, not text, so a half-typed "1,234." isn't clobbered.
    final ext = widget.draft.owedAmount;
    if (AmountField.parse(_amount.text) != ext) {
      _amount.text = _formatted(ext);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final draft = widget.draft;
    final locked = draft.identityLocked;
    // Linked: the contact-card icon, tinted; a typed name: the person icon.
    final Widget chip = RowChip(
      label: draft.personName,
      icon: draft.isWired ? AppIcons.contact : AppIcons.profile,
      color: draft.isWired ? scheme.primary : null,
      selected: draft.isWired,
      onTap: locked ? null : widget.onChangePerson,
    );
    final row = Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: locked
                // Tap → why, instead of silently nothing.
                ? Tooltip(
                    message: l.txSplitPersonLocked,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: chip),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          AppIcons.lock,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  )
                : chip,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          // Room for "฿96,248.33".
          width: _amountWidth,
          // Same thousands formatting / parsing as [AmountField].
          child: TextField(
            controller: _amount,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsInputFormatter()],
            style: textStyle?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            // One line, an underline to show it's editable.
            decoration: InputDecoration(
              hintText: '0',
              prefixText: '฿',
              isDense: true,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
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
            onChanged: (v) {
              draft.owedAmount = AmountField.parse(v);
              widget.onChange();
            },
          ),
        ),
        // Repayments don't limit edits (owner 2026-10-10): anyone can be
        // removed, whatever they paid back.
        IconButton(
          tooltip: l.txSplitRemove,
          icon: const Icon(AppIcons.close, size: 18),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          color: scheme.onSurfaceVariant,
          onPressed: widget.onRemove,
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
