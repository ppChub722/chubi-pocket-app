import 'package:flutter/material.dart';

import '../../ui.dart';

class AddMemberLabels {
  const AddMemberLabels({
    required this.title,
    required this.submit,
    required this.fromContacts,
    required this.name,
    required this.nameRequired,
    required this.email,
    required this.emailHint,
  });

  final String title;
  final String submit;
  final String fromContacts;
  final String name;
  final String nameRequired;
  final String email;
  final String emailHint;
}

@immutable
class AddMemberFill {
  const AddMemberFill({required this.name, this.email});
  final String name;
  final String? email;
}

Future<String?> showAddMemberFormSheet(
  BuildContext context, {
  required AddMemberLabels labels,
  required Future<AddMemberFill?> Function() onFromContacts,
  required Future<bool> Function(String name, String? email) onSubmit,
}) {
  return showAppSheetCustom<String>(
    context,
    builder: (_) => AddMemberSheet(
      labels: labels,
      onFromContacts: onFromContacts,
      onSubmit: onSubmit,
    ),
  );
}

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({
    required this.labels,
    required this.onFromContacts,
    required this.onSubmit,
    super.key,
  });

  final AddMemberLabels labels;
  final Future<AddMemberFill?> Function() onFromContacts;
  final Future<bool> Function(String name, String? email) onSubmit;

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _fromContacts() async {
    final r = await widget.onFromContacts();
    if (r == null || !mounted) return;
    setState(() {
      _name.text = r.name;
      _email.text = r.email ?? '';
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    setState(() => _saving = true);
    final ok = await widget.onSubmit(name, email.isEmpty ? null : email);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, name);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    return FormSheet(
      title: l.title,
      primaryLabel: l.submit,
      onPrimary: _submit,
      saving: _saving,
      dirty: _name.text.trim().isNotEmpty || _email.text.trim().isNotEmpty,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: l.fromContacts,
              icon: AppIcons.contact,
              variant: AppButtonVariant.tonal,
              onPressed: _saving ? null : _fromContacts,
            ),
            SectionCard(
              fields: true,
              dividers: false,
              children: [
                AppInput(
                  controller: _name,
                  label: l.name,
                  prefixIcon: AppIcons.member,
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l.nameRequired : null,
                ),
                AppInput(
                  controller: _email,
                  label: l.email,
                  helper: l.emailHint,
                  prefixIcon: AppIcons.send,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
