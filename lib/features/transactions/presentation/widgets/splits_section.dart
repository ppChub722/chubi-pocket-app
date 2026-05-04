import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';

/// One debtor row in the create-transaction "Split with…" section.
///
/// `personName` is required (always set per spec §06.2.5). `contactId` is
/// optional — when present, we display the contact's name instead. The
/// splits-creator hook on the BE rewrites `person_name` to the contact's
/// snapshot at insert time, so what the user types here is mostly for
/// preview / for free-text debtors.
class SplitDraft {
  SplitDraft({
    String? personName,
    this.contactId,
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
}

/// Collapsible splits editor. Sits inside the transaction form body for
/// non-transfer transactions. Returns the current draft list via the
/// `onChanged` callback so the parent can pass it to `cubit.add(splits:)`.
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
      // Warm the contacts cache so the picker has data ready.
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
            draft: widget.drafts[i],
            onPickContact: () => _pickContact(i),
            onChange: () {
              widget.onChanged(List.of(widget.drafts));
            },
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

  Future<void> _pickContact(int index) async {
    final picked = await showModalBottomSheet<Contact?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ContactPickerSheet(),
    );
    if (picked != null) {
      widget.drafts[index].contactId = picked.id;
      widget.drafts[index].contactDisplayName = picked.effectiveName;
      // Snapshot the contact's name into person_name (matches BE behavior).
      widget.drafts[index].personName = picked.effectiveName;
      widget.onChanged(List.of(widget.drafts));
    }
  }
}

class _DraftRow extends StatefulWidget {
  const _DraftRow({
    required this.draft,
    required this.onPickContact,
    required this.onChange,
    required this.onRemove,
  });

  final SplitDraft draft;
  final VoidCallback onPickContact;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  State<_DraftRow> createState() => _DraftRowState();
}

class _DraftRowState extends State<_DraftRow> {
  late final TextEditingController _name;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.personName);
    _amount = TextEditingController(
      text: widget.draft.owedAmount == null
          ? ''
          : widget.draft.owedAmount!.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant _DraftRow old) {
    super.didUpdateWidget(old);
    // Sync from external changes (split-equally button, contact pick).
    if (_name.text != widget.draft.personName) {
      _name.text = widget.draft.personName;
    }
    final ext = widget.draft.owedAmount == null
        ? ''
        : widget.draft.owedAmount!.toStringAsFixed(2);
    if (_amount.text != ext) {
      _amount.text = ext;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: widget.draft.contactId == null
              ? 'Pick contact'
              : 'Linked to contact',
          icon: Icon(
            widget.draft.contactId == null
                ? Icons.person_outline
                : Icons.contact_phone,
          ),
          onPressed: widget.onPickContact,
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              isDense: true,
            ),
            onChanged: (v) {
              widget.draft.personName = v;
              widget.onChange();
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
              widget.draft.owedAmount = double.tryParse(v);
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
  }
}

class _ContactPickerSheet extends StatelessWidget {
  const _ContactPickerSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactsCubit, ContactsState>(
      builder: (ctx, state) {
        final active = state.contacts
            .where((c) => c.status == ContactStatus.active)
            .toList();
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Pick a contact',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: active.isEmpty
                      ? const Center(child: Text('No contacts yet'))
                      : ListView.separated(
                          itemCount: active.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = active[i];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  c.effectiveName.isNotEmpty
                                      ? c.effectiveName[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(c.effectiveName),
                              subtitle: c.email != null ? Text(c.email!) : null,
                              onTap: () => Navigator.pop(context, c),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
