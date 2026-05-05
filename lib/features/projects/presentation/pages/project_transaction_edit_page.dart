import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/icon_color_picker_sheet.dart';
import '../../../categories/domain/category_icon_preset.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// Pushed via Navigator (not GoRouter) so the caller can pass objects directly.
class ProjectTransactionEditPage extends StatefulWidget {
  const ProjectTransactionEditPage({
    required this.projectId,
    required this.tree,
    required this.members,
    super.key,
  });
  final String projectId;
  final ProjectTxTree tree;
  final List<ProjectMember> members;

  @override
  State<ProjectTransactionEditPage> createState() =>
      _ProjectTransactionEditPageState();
}

class _SplitEditEntry {
  _SplitEditEntry({required this.memberId, required double amount})
      : amountCtrl =
            TextEditingController(text: amount.toStringAsFixed(2));
  String? memberId;
  final TextEditingController amountCtrl;
}

class _ProjectTransactionEditPageState
    extends State<ProjectTransactionEditPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _date;
  late final TextEditingController _note;
  late final TextEditingController _categoryName;

  String? _categoryIconId;
  String? _categoryColorId;

  late List<_SplitEditEntry> _splits;

  bool _saving = false;
  String? _error;

  ProjectTransaction get _tx => widget.tree.parent;
  String get _actorId => _tx.transactionMemberId;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: _tx.description ?? '');
    _amount = TextEditingController(
        text: _tx.amount.toStringAsFixed(2));
    _date = TextEditingController(text: _tx.date);
    _note = TextEditingController(text: _tx.note ?? '');
    _categoryName = TextEditingController(text: _tx.categoryName ?? '');
    _categoryIconId = _tx.categoryIconId;
    _categoryColorId = _tx.categoryColorId;

    _splits = widget.tree.children
        .map((c) => _SplitEditEntry(
              memberId: c.transactionMemberId,
              amount: c.amount,
            ))
        .toList();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _date.dispose();
    _note.dispose();
    _categoryName.dispose();
    for (final e in _splits) {
      e.amountCtrl.dispose();
    }
    super.dispose();
  }

  String _memberName(String memberId) {
    return widget.members
        .firstWhere((m) => m.id == memberId,
            orElse: () => const ProjectMember(
                  id: '',
                  projectId: '',
                  displayName: '?',
                  role: MemberRole.contributor,
                  status: MemberStatus.active,
                ))
        .displayName;
  }

  Future<void> _pickCategoryIcon() async {
    final iconOptions = CategoryIconPreset.values
        .map((p) => IconPickerOption(id: p.id, icon: p.icon))
        .toList();
    final swatches = CategoryColor.all
        .map((c) => IconPickerSwatch(id: c.id, color: c.color))
        .toList();
    final result = await showIconColorPickerSheet(
      context: context,
      iconOptions: iconOptions,
      swatches: swatches,
      initialIconId:
          _categoryIconId ?? CategoryIconPreset.values.first.id,
      initialSwatchId: _categoryColorId ?? CategoryColor.all.first.id,
    );
    if (result is IconColorPickerSelected) {
      setState(() {
        _categoryIconId = result.iconId;
        _categoryColorId = result.swatchId;
      });
    }
  }

  List<ProjectSplitInput> _collectSplits() {
    final out = <ProjectSplitInput>[];
    for (final e in _splits) {
      final id = e.memberId;
      final n = double.tryParse(e.amountCtrl.text.trim());
      if (id == null || n == null || n <= 0) continue;
      out.add(ProjectSplitInput(memberId: id, amount: n));
    }
    return out;
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final catName = _categoryName.text.trim();
    if (catName.isEmpty || _categoryIconId == null || _categoryColorId == null) {
      setState(() => _error = 'Category name and icon are required');
      return;
    }
    final amount = double.parse(_amount.text.trim());
    final splits = _collectSplits();
    final splitSum = splits.fold<double>(0, (a, s) => a + s.amount);
    if (splitSum > amount + 0.005) {
      setState(() =>
          _error = 'Sum of splits (${splitSum.toStringAsFixed(2)}) exceeds total');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ProjectsRepository>().updateTransaction(
            widget.projectId,
            _tx.id,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            amount: amount,
            date: _date.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            categoryName: catName,
            categoryIconId: _categoryIconId,
            categoryColorId: _categoryColorId,
            splits: splits,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catIconPreset = _categoryIconId != null
        ? CategoryIconPreset.byId(_categoryIconId!)
        : null;
    final catColor = _categoryColorId != null
        ? CategoryColor.byId(_categoryColorId!).color
        : null;
    final actor = _memberName(_actorId);
    final isExpense = _tx.type == 'expense';
    final nonActorMembers =
        widget.members.where((m) => m.id != _actorId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit transaction')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Read-only info strip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(isExpense ? Icons.remove : Icons.add,
                      size: 16,
                      color: isExpense ? scheme.error : Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    '${isExpense ? 'Expense' : 'Income'} · ${_tx.currency} · $actor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
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
              controller: _amount,
              decoration:
                  const InputDecoration(labelText: 'Amount *'),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a positive amount';
                return null;
              },
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
            Text('Category *',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryName,
                    decoration: const InputDecoration(
                        labelText: 'Category name'),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickCategoryIcon,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: catColor?.withValues(alpha: 0.18) ??
                        scheme.surfaceContainerHighest,
                    child: Icon(
                      catIconPreset?.icon ?? Icons.category_outlined,
                      color: catColor ?? scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nonActorMembers.isNotEmpty) ...[
              Text('Splits (optional)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (int i = 0; i < _splits.length; i++)
                Padding(
                  key: ValueKey(i),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _splits[i].memberId,
                          hint: const Text('Member'),
                          decoration:
                              const InputDecoration(isDense: true),
                          items: nonActorMembers
                              .map((m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.displayName),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _splits[i].memberId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          controller: _splits[i].amountCtrl,
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
                        icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20),
                        onPressed: () => setState(() {
                          _splits[i].amountCtrl.dispose();
                          _splits.removeAt(i);
                        }),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add split'),
                onPressed: () => setState(() => _splits.add(
                      _SplitEditEntry(memberId: null, amount: 0),
                    )),
              ),
            ],
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style:
                        const TextStyle(color: Colors.redAccent)),
              ),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
