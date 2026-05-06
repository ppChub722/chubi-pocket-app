import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// `/projects/:id/transactions/new` — record a project_transaction.
class ProjectTransactionFormPage extends StatefulWidget {
  const ProjectTransactionFormPage({required this.projectId, super.key});
  final String projectId;

  @override
  State<ProjectTransactionFormPage> createState() =>
      _ProjectTransactionFormPageState();
}

class _SplitEntry {
  _SplitEntry() : amountCtrl = TextEditingController();
  String? memberId;
  final TextEditingController amountCtrl;
}

class _CategoryDraft {
  _CategoryDraft({required this.name, required this.iconCode});
  final String name;
  final IconCode iconCode;
}

class _ProjectTransactionFormPageState
    extends State<ProjectTransactionFormPage> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'THB');
  final _date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final _note = TextEditingController();
  final _categoryName = TextEditingController();

  String _type = 'expense';
  String? _memberId;
  List<ProjectMember> _members = const [];
  List<_CategoryDraft> _pastCategories = const [];

  _CategoryDraft? _selectedCategory;

  final List<_SplitEntry> _splitEntries = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<ProjectsRepository>();
      final results = await Future.wait([
        repo.listMembers(widget.projectId),
        repo.listTransactions(widget.projectId, perPage: 100),
      ]);
      if (!mounted) return;
      final ms = results[0] as List<ProjectMember>;
      final txs = results[1] as List<ProjectTransaction>;

      final seen = <String, _CategoryDraft>{};
      for (final tx in txs) {
        if (tx.categoryName != null && tx.categoryIconCode != null) {
          final key = '${tx.categoryName}|${tx.categoryIconCode!.icon}';
          seen.putIfAbsent(
            key,
            () => _CategoryDraft(
              name: tx.categoryName!,
              iconCode: tx.categoryIconCode!,
            ),
          );
        }
      }

      setState(() {
        _members = ms.where((m) => m.status != MemberStatus.left).toList();
        _memberId = _members.firstOrNull?.id;
        _pastCategories = seen.values.toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      _error = e.message;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCategoryIcon() async {
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.projectTransaction,
      initial: _selectedCategory?.iconCode,
    );
    if (!mounted || result == null) return;
    if (result is IconMakerSelected) {
      setState(() {
        final name = _categoryName.text.trim().isNotEmpty
            ? _categoryName.text.trim()
            : (_selectedCategory?.name ?? '');
        _selectedCategory = _CategoryDraft(
          name: name,
          iconCode: result.iconCode,
        );
        if (name.isNotEmpty) _categoryName.text = name;
      });
    }
  }

  void _selectPastCategory(_CategoryDraft cat) {
    setState(() {
      _selectedCategory = cat;
      _categoryName.text = cat.name;
    });
  }

  List<ProjectSplitInput> _collectSplits() {
    final out = <ProjectSplitInput>[];
    for (final entry in _splitEntries) {
      final id = entry.memberId;
      final raw = entry.amountCtrl.text.trim();
      if (id == null || raw.isEmpty) continue;
      final n = double.tryParse(raw);
      if (n == null || n <= 0) continue;
      out.add(ProjectSplitInput(memberId: id, amount: n));
    }
    return out;
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_memberId == null) {
      setState(() => _error = 'Pick a member');
      return;
    }
    final catName = _categoryName.text.trim();
    if (catName.isEmpty || _selectedCategory == null) {
      setState(() => _error = 'Pick a category with icon & color');
      return;
    }
    final amount = double.parse(_amount.text);
    final splits = _collectSplits();
    final splitSum = splits.fold<double>(0, (acc, s) => acc + s.amount);
    if (splitSum > amount + 0.005) {
      setState(() =>
          _error = 'Sum of splits ($splitSum) exceeds total ($amount)');
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
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            categoryName: catName,
            categoryIconCode: _selectedCategory!.iconCode,
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
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final catBg = _selectedCategory?.iconCode.bgColorFor(palette);
    final catIcon = IconRegistry.get(
      _selectedCategory?.iconCode.icon,
      fallback: Icons.category_outlined,
    );

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
                      _splitEntries.removeWhere((e) {
                        if (e.memberId == v) {
                          e.amountCtrl.dispose();
                          return true;
                        }
                        return false;
                      });
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
                    controller: _description,
                    decoration:
                        const InputDecoration(labelText: 'Description *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Text('Category *',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (_pastCategories.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cat in _pastCategories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Builder(builder: (context) {
                                final bg = cat.iconCode.bgColorFor(palette);
                                final ic = IconRegistry.get(cat.iconCode.icon,
                                    fallback: Icons.category_outlined);
                                final selected =
                                    _selectedCategory?.name == cat.name &&
                                        _selectedCategory?.iconCode ==
                                            cat.iconCode;
                                return GestureDetector(
                                  onTap: () => _selectPastCategory(cat),
                                  child: Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor:
                                          (bg ?? scheme.primary).withValues(alpha: 0.18),
                                      child: Icon(ic,
                                          size: 14,
                                          color: bg ?? scheme.primary),
                                    ),
                                    label: Text(cat.name),
                                    backgroundColor: selected
                                        ? (bg ?? scheme.primary)
                                            .withValues(alpha: 0.18)
                                        : null,
                                    side: selected
                                        ? BorderSide(
                                            color: bg ?? scheme.primary)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _categoryName,
                          decoration: const InputDecoration(
                            labelText: 'Category name',
                            hintText: 'e.g. Meals, Accommodation',
                          ),
                          onChanged: (v) {
                            if (_selectedCategory != null) {
                              setState(() {
                                _selectedCategory = _CategoryDraft(
                                  name: v.trim(),
                                  iconCode: _selectedCategory!.iconCode,
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _pickCategoryIcon,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: catBg?.withValues(alpha: 0.18) ??
                              scheme.surfaceContainerHighest,
                          child: Icon(
                            catIcon,
                            color: catBg ?? scheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_memberId != null && _members.length > 1) ...[
                    Text(
                      'Splits (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add shares each member owes the actor. '
                      'Sum must be ≤ total; actor keeps the remainder.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < _splitEntries.length; i++)
                      Padding(
                        key: ValueKey(i),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _splitEntries[i].memberId,
                                hint: const Text('Member'),
                                decoration:
                                    const InputDecoration(isDense: true),
                                items: _members
                                    .where((m) => m.id != _memberId)
                                    .map((m) => DropdownMenuItem(
                                          value: m.id,
                                          child: Text(m.displayName),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => _splitEntries[i].memberId = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 96,
                              child: TextFormField(
                                controller: _splitEntries[i].amountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  hintText: 'Amount',
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              onPressed: () => setState(() {
                                _splitEntries[i].amountCtrl.dispose();
                                _splitEntries.removeAt(i);
                              }),
                            ),
                          ],
                        ),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add split'),
                      onPressed: () =>
                          setState(() => _splitEntries.add(_SplitEntry())),
                    ),
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
    _description.dispose();
    _amount.dispose();
    _currency.dispose();
    _date.dispose();
    _note.dispose();
    _categoryName.dispose();
    for (final e in _splitEntries) {
      e.amountCtrl.dispose();
    }
    super.dispose();
  }
}
