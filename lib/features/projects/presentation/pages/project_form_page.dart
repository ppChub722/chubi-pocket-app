import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
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
      _name.text = p.name;
      _type.text = p.type ?? '';
      _description.text = p.description ?? '';
    } on ApiException catch (e) {
      _error = e.message;
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
        );
      } else {
        await cubit.create(
          name: _name.text.trim(),
          type: _type.text.trim().isEmpty ? null : _type.text.trim(),
          description:
              _description.text.trim().isEmpty ? null : _description.text.trim(),
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
