import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
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
  }) : personName = personName ?? '';

  String personName;
  String? contactId;
  String? contactDisplayName;
  double? owedAmount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'person_name': personName.trim(),
        if (contactId != null) 'contact_id': contactId,
        'owed_amount': owedAmount ?? 0,
        'split_type': 'fixed',
      };

  bool get isComplete =>
      personName.trim().isNotEmpty && (owedAmount ?? 0) > 0;

  bool get isWired => contactId != null;
}

/// Collapsible splits editor. Sits inside the transaction form body for
/// non-transfer expense transactions. Returns the current draft list via
/// the `onChanged` callback so the parent can pass it to `cubit.add`.
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
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.drafts.isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = widget.totalAmount - _splitTotal;
    final overflow = remaining < -0.005;

    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.call_split, size: 18),
          label: const Text('Split with…'),
          onPressed: () {
            setState(() {
              _expanded = true;
              if (widget.drafts.isEmpty) {
                widget.onChanged([SplitDraft()]);
              }
            });
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Split with',
                style: theme.textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.balance, size: 18),
              label: const Text('Split equally'),
              onPressed: widget.drafts.isEmpty || widget.totalAmount <= 0
                  ? null
                  : _splitEqually,
            ),
            IconButton(
              tooltip: 'Collapse',
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _expanded = false;
                  widget.onChanged(const []);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < widget.drafts.length; i++) ...[
          _DraftRow(
            // Re-mount each row when its identity changes (e.g. after
            // remove). Without a key, the underlying TextEditingController
            // bleeds between siblings on list edits.
            key: ValueKey(i),
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
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add person'),
              onPressed: () {
                widget.onChanged([...widget.drafts, SplitDraft()]);
              },
            ),
            const Spacer(),
            Text(
              'Remaining: ${remaining.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: overflow ? theme.colorScheme.error : null,
                fontWeight: overflow ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
        if (overflow)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Splits exceed the transaction amount.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
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
    _amount = TextEditingController(
      text: widget.draft.owedAmount == null
          ? ''
          : widget.draft.owedAmount!.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant _DraftRow old) {
    super.didUpdateWidget(old);
    final ext = widget.draft.owedAmount == null
        ? ''
        : widget.draft.owedAmount!.toStringAsFixed(2);
    if (_amount.text != ext) {
      _amount.text = ext;
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
    final draft = widget.draft;
    return BlocBuilder<ContactsCubit, ContactsState>(
      builder: (context, state) {
        return Row(
          children: [
            // Visual cue: filled link icon when wired, outline when free text.
            Tooltip(
              message: draft.isWired
                  ? 'Wired to contact'
                  : 'Free text — pick a contact from suggestions to wire',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  draft.isWired ? Icons.contact_phone : Icons.person_outline,
                  color: draft.isWired
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Autocomplete<Contact>(
                initialValue: TextEditingValue(text: draft.personName),
                displayStringForOption: (c) => c.effectiveName,
                optionsBuilder: (textEditingValue) =>
                    _suggestionsFor(textEditingValue.text, state.contacts),
                onSelected: (c) {
                  setState(() {
                    draft.personName = c.effectiveName;
                    draft.contactId = c.id;
                    draft.contactDisplayName = c.effectiveName;
                  });
                  widget.onChange();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmit) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      // Typing past or away from a picked contact clears
                      // the wire — otherwise the BE would receive a stale
                      // contact_id that no longer matches the name.
                      final stale = draft.contactDisplayName != null &&
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
                      borderRadius: BorderRadius.circular(8),
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
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text(
                                  c.effectiveName.isNotEmpty
                                      ? c.effectiveName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(c.effectiveName),
                              subtitle: c.email != null
                                  ? Text(
                                      c.email!,
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                              trailing: c.isLinked
                                  ? const Icon(Icons.link, size: 14)
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
              child: TextField(
                controller: _amount,
                decoration: const InputDecoration(
                  labelText: 'Owes',
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  draft.owedAmount = double.tryParse(v);
                  widget.onChange();
                },
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onRemove,
            ),
          ],
        );
      },
    );
  }
}
