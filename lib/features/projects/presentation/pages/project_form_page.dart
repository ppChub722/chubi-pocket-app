import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/icon_color_picker_sheet.dart';
import '../../../categories/domain/category_icon_preset.dart';
import '../../data/projects_repository.dart';
import '../cubit/projects_cubit.dart';

/// `/projects/new` and `/projects/:id/edit`.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({this.editingId, super.key});
  final String? editingId;

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _type = TextEditingController();
  final _description = TextEditingController();

  String? _iconId;
  String? _colorId;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.editingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final p = await context.read<ProjectsRepository>().get(widget.editingId!);
      if (!mounted) return;
      setState(() {
        _name.text = p.name;
        _type.text = p.type ?? '';
        _description.text = p.description ?? '';
        _iconId = p.iconId;
        _colorId = p.colorId;
      });
    } on ApiException catch (e) {
      _error = e.message;
    }
  }

  Future<void> _pickIcon() async {
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
      initialIconId: _iconId ?? CategoryIconPreset.values.first.id,
      initialSwatchId: _colorId ?? CategoryColor.all.first.id,
    );
    if (result is IconColorPickerSelected) {
      setState(() {
        _iconId = result.iconId;
        _colorId = result.swatchId;
      });
    } else if (result is IconColorPickerRemoved) {
      setState(() {
        _iconId = null;
        _colorId = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cubit = context.read<ProjectsCubit>();
      if (_isEdit) {
        await cubit.update(
          widget.editingId!,
          name: _name.text.trim(),
          description:
              _description.text.trim().isEmpty ? null : _description.text.trim(),
          iconId: _iconId,
          colorId: _colorId,
        );
      } else {
        await cubit.create(
          name: _name.text.trim(),
          type: _type.text.trim().isEmpty ? null : _type.text.trim(),
          description:
              _description.text.trim().isEmpty ? null : _description.text.trim(),
          iconId: _iconId,
          colorId: _colorId,
        );
      }
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
    final iconPreset =
        _iconId != null ? CategoryIconPreset.byId(_iconId!) : null;
    final iconColor =
        _colorId != null ? CategoryColor.byId(_colorId!).color : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit project' : 'New project')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _type,
              decoration: const InputDecoration(
                  labelText: 'Type (e.g. trip, freelance)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: iconColor?.withValues(alpha: 0.18) ??
                    scheme.surfaceContainerHighest,
                child: Icon(
                  iconPreset?.icon ?? Icons.folder_shared_outlined,
                  color: iconColor ?? scheme.onSurfaceVariant,
                ),
              ),
              title: Text(_iconId != null ? 'Project icon set' : 'Project icon'),
              subtitle: Text(_iconId != null
                  ? 'Tap to change'
                  : 'Optional — tap to pick icon & color'),
              trailing: _iconId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _iconId = _colorId = null),
                    )
                  : null,
              onTap: _pickIcon,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _description.dispose();
    super.dispose();
  }
}
