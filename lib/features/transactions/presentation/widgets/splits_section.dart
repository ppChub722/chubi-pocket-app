import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';

/// One debtor row in the create-transaction "Split with…" section.
///
/// Two binding modes for the same row:
///   - free text: user typed a name that doesn't match any contact ⇒
///     `personName` set, `contactId` null. BE stores as a typed person_name
///     on the resulting personal_debts row; the user can later wire it to
///     a contact from the contact detail page.
///   - wired: user picked a suggestion from the typeahead ⇒ `contactId`
///     set + `personName` snapshotted to the contact's effective name.
class SplitDraft {
  SplitDraft({
    String? personName,
    this.contactId,
    this.contactDisplayName,
    this.owedAmount,
    this.debtId,
    this.settledAmount = 0,
    this.cancelled = false,
  }) : personName = personName ?? '';

  String personName;
  String? contactId;
  String? contactDisplayName;
  double? owedAmount;

  /// A saved transaction's split: the debt row it made. Its person is fixed
  /// (to change who, remove + add); only the amount changes.
  final String? debtId;

  /// Already paid back on that debt — shown, never a limit: the amount may
  /// go below it (then it's overpaid) and the row may be removed.
  final double settledAmount;

  /// That debt was cancelled (it stays so; its amount can still change).
  final bool cancelled;

  bool get isSaved => debtId != null;
  bool get hasRepayments => settledAmount > 0.005;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'debt_id': ?debtId,
    'person_name': personName.trim(),
    if (contactId != null) 'contact_id': contactId,
    'owed_amount': owedAmount ?? 0,
    'split_type': 'fixed',
  };

  /// One entry of PUT /transactions/:id/splits: a saved split by its debt
  /// (only the amount is read), a new one like at create.
  Map<String, dynamic> toUpdateJson() => isSaved
      ? {'debt_id': debtId, 'owed_amount': owedAmount ?? 0}
      : {
          'person_name': personName.trim(),
          'contact_id': ?contactId,
          'owed_amount': owedAmount ?? 0,
        };

  bool get isComplete => personName.trim().isNotEmpty && (owedAmount ?? 0) > 0;

  bool get isWired => contactId != null;
}

/// The "หารกับ" editor of the transaction form, always open (owner
/// 2026-10-10). Empty, it's just [+ เพิ่มคน] — no blank row; with rows:
/// each row, then [+ เพิ่มคน] [หารเท่ากัน] · "ส่วนของคุณ ฿x". Removing the
/// last row empties it again. The row's label ("หารกับ" / "แบ่งให้") sits
/// beside it in the form. Returns the drafts via [onChanged].
class SplitsSection extends StatefulWidget {
  const SplitsSection({
    required this.totalAmount,
    required this.drafts,
    required this.onChanged,
    super.key,
  });

  /// Parent transaction's amount — used for "split equally" + validation
  /// of total ≤ tx amount.
  final double totalAmount;

  final List<SplitDraft> drafts;
  final ValueChanged<List<SplitDraft>> onChanged;

  @override
  State<SplitsSection> createState() => _SplitsSectionState();
}

class _SplitsSectionState extends State<SplitsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Warm the contacts cache so the typeahead has data ready.
      final cubit = context.read<ContactsCubit>();
      if (cubit.state.contacts.isEmpty) {
        cubit.load();
      }
    });
  }

  double get _splitTotal {
    var total = 0.0;
    for (final d in widget.drafts) {
      total += d.owedAmount ?? 0;
    }
    return total;
  }

  void _addPerson() => widget.onChanged([...widget.drafts, SplitDraft()]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final remaining = widget.totalAmount - _splitTotal;
    final overflow = remaining < -0.005;
    final addPerson = TextButton.icon(
      icon: const Icon(AppIcons.add, size: 18),
      label: Text(l.txSplitAddPerson),
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      onPressed: _addPerson,
    );

    if (widget.drafts.isEmpty) {
      return Align(alignment: Alignment.centerLeft, child: addPerson);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.drafts.length; i++) ...[
          _DraftRow(
            // Key by the draft object itself: removing a middle row must
            // drop THAT row's controllers, not shift names onto siblings.
            key: ObjectKey(widget.drafts[i]),
            draft: widget.drafts[i],
            onChange: () => widget.onChanged(List.of(widget.drafts)),
            onRemove: () {
              final next = List<SplitDraft>.of(widget.drafts)..removeAt(i);
              widget.onChanged(next);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            addPerson,
            TextButton.icon(
              icon: const Icon(AppIcons.split, size: 18),
              label: Text(l.txSplitEqually),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: widget.totalAmount <= 0 ? null : _splitEqually,
            ),
            const Spacer(),
            Flexible(
              child: Text(
                l.txSplitRemaining(moneyString(context, remaining)),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: overflow ? theme.colorScheme.error : null,
                  fontWeight: overflow ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
        if (overflow)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l.txSplitOver,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
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

/// A single draft row. The name field is a typeahead `Autocomplete<Contact>`:
/// suggestions narrow as the user types; picking one wires `contactId`,
/// otherwise the typed text becomes a free-text `person_name`.
class _DraftRow extends StatefulWidget {
  const _DraftRow({
    required this.draft,
    required this.onChange,
    required this.onRemove,
    super.key,
  });

  final SplitDraft draft;
  final VoidCallback onChange;
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

  /// Filtered + sorted contact list for the typeahead. Empty input shows
  /// every active contact ordered by `lastUsedAt DESC NULLS LAST` (BE
  /// already serves the list in this order, so we just preserve it).
  Iterable<Contact> _suggestionsFor(String text, List<Contact> all) {
    final active = all.where((c) => c.status == ContactStatus.active);
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return active;
    return active.where((c) {
      final hay = c.effectiveName.toLowerCase();
      return hay.contains(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final draft = widget.draft;
    return BlocBuilder<ContactsCubit, ContactsState>(
      builder: (context, state) {
        final row = Row(
          children: [
            // Visual cue: filled link icon when wired, outline when free text.
            Tooltip(
              message: draft.isWired
                  ? l.txSplitWiredContact
                  : l.txSplitFreeText,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  draft.isWired ? AppIcons.contact : AppIcons.profile,
                  color: draft.isWired
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              // A saved split's person is fixed (remove + add to change).
              child: draft.isSaved
                  ? InputDecorator(
                      decoration: InputDecoration(
                        labelText: l.txSplitName,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        draft.personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Autocomplete<Contact>(
                      initialValue: TextEditingValue(text: draft.personName),
                      displayStringForOption: (c) => c.effectiveName,
                      optionsBuilder: (textEditingValue) => _suggestionsFor(
                        textEditingValue.text,
                        state.contacts,
                      ),
                      onSelected: (c) {
                        setState(() {
                          draft.personName = c.effectiveName;
                          draft.contactId = c.id;
                          draft.contactDisplayName = c.effectiveName;
                        });
                        widget.onChange();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        return AppTextField(
                          controller: controller,
                          focusNode: focusNode,
                          label: l.txSplitName,
                          onChanged: (v) {
                            // Typing past or away from a picked contact clears
                            // the wire — otherwise the BE would receive a stale
                            // contact_id that no longer matches the name.
                            final stale =
                                draft.contactDisplayName != null &&
                                v != draft.contactDisplayName;
                            setState(() {
                              draft.personName = v;
                              if (stale) {
                                draft.contactId = null;
                                draft.contactDisplayName = null;
                              }
                            });
                            widget.onChange();
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        // Default Material 3 dropdown shape constrained so it
                        // doesn't grow taller than 280 px (typical 6 rows).
                        final list = options.toList(growable: false);
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 280,
                                maxWidth: 320,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: list.length,
                                itemBuilder: (context, i) {
                                  final c = list[i];
                                  return ListTile(
                                    dense: true,
                                    leading: UserAvatar(
                                      displayName: c.effectiveName,
                                      iconCode: c.effectiveIconCode,
                                      size: 28,
                                    ),
                                    title: Text(c.effectiveName),
                                    subtitle: c.email != null
                                        ? Text(
                                            c.email!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          )
                                        : null,
                                    trailing: c.isLinked
                                        ? const Icon(AppIcons.link, size: 14)
                                        : null,
                                    onTap: () => onSelected(c),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              // Same thousands formatting / parsing as [AmountField].
              child: AppTextField(
                controller: _amount,
                label: l.txSplitOwes,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsInputFormatter()],
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
              icon: const Icon(AppIcons.delete),
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
                left: AppSpacing.xl + AppSpacing.xs,
                top: AppSpacing.xs,
              ),
              child: Text(
                draft.cancelled
                    ? l.txSplitStatusCancelled
                    : l.txSplitRepaidSoFar(
                        moneyString(context, draft.settledAmount),
                      ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
