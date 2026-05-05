import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

/// `/contacts/new` and `/contacts/:id/edit`.
class ContactFormPage extends StatefulWidget {
  const ContactFormPage({this.editingId, super.key});
  final String? editingId;

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.editingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final c = await context.read<ContactsRepository>().get(widget.editingId!);
      if (!mounted) return;
      _name.text = c.displayName;
      _email.text = c.email ?? '';
      _phone.text = c.phone ?? '';
      _notes.text = c.notes ?? '';
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final cubit = context.read<ContactsCubit>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await cubit.update(
          widget.editingId!,
          displayName: _name.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      } else {
        await cubit.create(
          displayName: _name.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      }
      if (!mounted) return;
      context.pop<Contact?>(null);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit contact' : 'New contact')),
      body: _loading && _isEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
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
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }
}
