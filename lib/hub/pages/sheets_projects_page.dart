import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// `/dev/domain/sheets-projects` — the event sheets: invite a member. Sample
/// data, live sheet.
Widget buildSheetsProjectsPage(BuildContext context) =>
    const _SheetsProjectsPage();

class _SheetsProjectsPage extends StatefulWidget {
  const _SheetsProjectsPage();

  @override
  State<_SheetsProjectsPage> createState() => _SheetsProjectsPageState();
}

class _SheetsProjectsPageState extends State<_SheetsProjectsPage> {
  String _result = 'nothing yet';

  Future<void> _addMember() async {
    final name = await showAddMemberFormSheet(
      context,
      labels: const AddMemberLabels(
        title: 'Invite member',
        submit: 'Add',
        fromContacts: 'From contacts',
        name: 'Name',
        nameRequired: 'Enter a name',
        email: 'Email',
        emailHint: 'Optional — with an email they get an invite.',
      ),
      onFromContacts: () async =>
          const AddMemberFill(name: 'Somchai', email: 'somchai@example.com'),
      onSubmit: (name, email) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return true;
      },
    );
    if (mounted) setState(() => _result = 'member: $name');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText('Last result: $_result'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Add member',
            variant: AppButtonVariant.outlined,
            onPressed: _addMember,
          ),
        ],
      ),
    );
  }
}
