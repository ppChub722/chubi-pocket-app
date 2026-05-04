import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';

/// Modal sheet for `POST /projects/:id/members` (2 variants post-migration 27).
/// The previous "from contact" variant was dropped — contacts are user-scoped,
/// so they can't be referenced from a shared project_members row. To "add my
/// contact": resolve the contact's email/linkedUserId locally and use the
/// by-email or ad-hoc variant here.
Future<bool?> showAddMemberSheet(
  BuildContext context, {
  required String projectId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddMemberSheet(projectId: projectId),
  );
}

enum _Variant { email, adHoc }

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.projectId});
  final String projectId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  _Variant _variant = _Variant.email;
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  MemberRole _role = MemberRole.contributor;

  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = context.read<ProjectsRepository>();
      switch (_variant) {
        case _Variant.email:
          await repo.addMember(
            widget.projectId,
            email: _email.text.trim(),
            displayName: _displayName.text.trim(),
            role: _role,
          );
        case _Variant.adHoc:
          await repo.addMember(
            widget.projectId,
            displayName: _displayName.text.trim(),
            role: _role,
            adHoc: true,
          );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add member', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<_Variant>(
            segments: const [
              ButtonSegment(value: _Variant.email, label: Text('By email')),
              ButtonSegment(value: _Variant.adHoc, label: Text('Ad-hoc')),
            ],
            selected: {_variant},
            onSelectionChanged: (v) => setState(() => _variant = v.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayName,
            decoration:
                const InputDecoration(labelText: 'Display name *'),
          ),
          if (_variant == _Variant.email)
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MemberRole>(
            initialValue: _role,
            items: const [
              DropdownMenuItem(
                  value: MemberRole.contributor, child: Text('Contributor')),
              DropdownMenuItem(
                  value: MemberRole.viewer, child: Text('Viewer')),
            ],
            onChanged: (v) => setState(() => _role = v ?? MemberRole.contributor),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: const Text('Add'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    super.dispose();
  }
}
