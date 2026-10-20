import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/domain/pickers` — the new-tag name sheet (the tag picker's create
/// flow; the pickers themselves are on the entity pickers page).
Widget buildSheetsPickersPage(BuildContext context) => const _PickersPage();

class _PickersPage extends StatefulWidget {
  const _PickersPage();

  @override
  State<_PickersPage> createState() => _PickersPageState();
}

class _PickersPageState extends State<_PickersPage> {
  String _result = 'nothing picked yet';

  void _say(Object? v) => setState(() => _result = '$v');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'showNewTagNameSheet',
          note:
              'The name sheet the tag picker opens when its search box is '
              'empty. Resolves the typed name / null (dismissed).',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'New-tag name sheet',
                variant: AppButtonVariant.outlined,
                onPressed: () async {
                  final n = await showNewTagNameSheet(
                    context,
                    title: 'New tag',
                    saveLabel: 'Save',
                    hint: 'Tag name',
                  );
                  _say(n ?? 'dismissed');
                },
              ),
            ],
          ),
        ),
        HubDemo(title: 'Last result', child: AppText(_result)),
      ],
    );
  }
}
