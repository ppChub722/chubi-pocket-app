import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// `/projects/:id/transactions/new` — record a project_transaction. Caller
/// picks the actor (transaction member) and may add per-member splits. The
/// BE wires the recorder = caller. No category picker — categories are
/// user-scoped, picked at resolve time.
class ProjectTransactionFormPage extends StatefulWidget {
  const ProjectTransactionFormPage({required this.projectId, super.key});
  final String projectId;

  @override
  State<ProjectTransactionFormPage> createState() =>
      _ProjectTransactionFormPageState();
}

class _ProjectTransactionFormPageState
    extends State<ProjectTransactionFormPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'THB');
  final _date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final _note = TextEditingController();

  String _type = 'expense';
  String? _memberId;
  List<ProjectMember> _members = const [];

  /// member_id -> share amount controller. Empty/0 means "not splitting to
  /// this member". `_memberId` (the actor) is excluded from this map.
  final Map<String, TextEditingController> _splitControllers = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final ms =
          await context.read<ProjectsRepository>().listMembers(widget.projectId);
      if (!mounted) return;
      setState(() {
        _members = ms.where((m) => m.status == MemberStatus.active).toList();
        _memberId = _members.firstOrNull?.id;
        _rebuildSplitControllers();
        _loading = false;
      });
    } on ApiException catch (e) {
      _error = e.message;
      if (mounted) setState(() => _loading = false);
    }
  }

  void _rebuildSplitControllers() {
    // Drop controllers for members no longer eligible (e.g., the new actor).
    final eligible =
        _members.where((m) => m.id != _memberId).map((m) => m.id).toSet();
    for (final id in _splitControllers.keys.toList()) {
      if (!eligible.contains(id)) {
        _splitControllers[id]?.dispose();
        _splitControllers.remove(id);
      }
    }
    for (final id in eligible) {
      _splitControllers.putIfAbsent(id, () => TextEditingController());
    }
  }

  List<ProjectSplitInput> _collectSplits() {
    final out = <ProjectSplitInput>[];
    for (final entry in _splitControllers.entries) {
      final raw = entry.value.text.trim();
      if (raw.isEmpty) continue;
      final n = double.tryParse(raw);
      if (n == null || n <= 0) continue;
      out.add(ProjectSplitInput(memberId: entry.key, amount: n));
    }
    return out;
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_memberId == null) {
      setState(() => _error = 'Pick a member');
      return;
    }
    final amount = double.parse(_amount.text);
    final splits = _collectSplits();
    final splitSum =
        splits.fold<double>(0, (acc, s) => acc + s.amount);
    if (splitSum > amount + 0.005) {
      setState(() => _error =
          'Sum of splits ($splitSum) exceeds total ($amount)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ProjectsRepository>().createTransaction(
            widget.projectId,
            transactionMemberId: _memberId!,
            type: _type,
            amount: amount,
            currency: _currency.text.trim().toUpperCase(),
            date: _date.text,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            splits: splits,
          );
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New project transaction')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (v) => setState(() => _type = v.first),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _memberId,
                    decoration:
                        const InputDecoration(labelText: 'Actor (member) *'),
                    items: _members
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.displayName),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _memberId = v;
                      _rebuildSplitControllers();
                    }),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    decoration: const InputDecoration(labelText: 'Amount *'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a positive amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currency,
                    decoration: const InputDecoration(labelText: 'Currency *'),
                    maxLength: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _date,
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  if (_memberId != null && _members.length > 1) ...[
                    Text(
                      'Splits (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amounts each other member owes the actor for this entry. '
                      'Leave blank to skip. Sum must be ≤ total amount; the '
                      'remainder is the actor\'s own share.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ..._members
                        .where((m) => m.id != _memberId)
                        .map((m) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: TextFormField(
                                controller: _splitControllers[m.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: m.displayName,
                                  hintText: '0',
                                ),
                              ),
                            )),
                  ],
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    _date.dispose();
    _note.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
