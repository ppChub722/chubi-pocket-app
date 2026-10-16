import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/templates/form-sheet` — the form sheet template.
Widget buildFormSheetPage(BuildContext context) => const _FormSheetPage();

class _FormSheetPage extends StatefulWidget {
  const _FormSheetPage();

  @override
  State<_FormSheetPage> createState() => _FormSheetPageState();
}

class _FormSheetPageState extends State<_FormSheetPage> {
  String _last = '—';

  Future<void> _open({
    required bool fail,
    bool destructive = false,
    bool showCancel = true,
  }) async {
    final result = await showPpForgeSheetCustom<String>(
      context,
      builder: (ctx) => _DemoForm(
        fail: fail,
        destructive: destructive,
        showCancel: showCancel,
      ),
    );
    if (mounted) setState(() => _last = result ?? 'closed without saving');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'FormSheet',
          note:
              'A bottom sheet that edits something and ends with Cancel · '
              'Save. It owns the chrome, the pinned footer, the dim + spinner '
              'while saving (back and buttons disabled), and the '
              '“Discard your changes?” question when a changed form is '
              'closed. A failed save stays on the sheet with a retry '
              'snackbar — nothing typed is lost.',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              PpForgeButton(
                label: 'Save succeeds',
                onPressed: () => _open(fail: false),
              ),
              PpForgeButton(
                label: 'Save fails (retry)',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _open(fail: true),
              ),
              PpForgeButton(
                label: 'Destructive',
                variant: PpForgeButtonVariant.destructiveOutlined,
                onPressed: () => _open(fail: false, destructive: true),
              ),
              PpForgeButton(
                label: 'Primary only',
                variant: PpForgeButtonVariant.tonal,
                onPressed: () => _open(fail: false, showCancel: false),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Last result',
          child: PpForgeText(_last, role: PpForgeTextRole.body),
        ),
        const HubDemo(
          title: 'Rules',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PpForgeText(
                '· Open it with showPpForgeSheetCustom; return FormSheet from the builder.',
              ),
              PpForgeText(
                '· Primary disabled until the form is valid; dirty = anything changed.',
              ),
              PpForgeText(
                '· Saving: set `saving`, call the API, on failure set it back and showErrorSnackBar(retry).',
              ),
              PpForgeText(
                '· Never add viewInsets padding inside — the sheet already handles the keyboard.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DemoForm extends StatefulWidget {
  const _DemoForm({
    required this.fail,
    required this.destructive,
    required this.showCancel,
  });

  final bool fail;
  final bool destructive;
  final bool showCancel;

  @override
  State<_DemoForm> createState() => _DemoFormState();
}

class _DemoFormState extends State<_DemoForm> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  int _attempt = 0;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _attempt++;
    if (widget.fail && _attempt < 2) {
      setState(() => _saving = false);
      showErrorSnackBar(
        context,
        const ApiException(code: 'NETWORK_ERROR', message: 'offline'),
        onRetry: _save,
      );
      return;
    }
    Navigator.of(context).pop('saved “${_name.text.trim()}”');
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'New wallet',
      primaryLabel: widget.destructive ? 'Delete' : 'Save',
      destructive: widget.destructive,
      showCancel: widget.showCancel,
      saving: _saving,
      dirty: _name.text.isNotEmpty || _note.text.isNotEmpty,
      onPrimary: _name.text.trim().isEmpty ? null : _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PpForgeInput(
            controller: _name,
            label: 'Name',
            hint: 'e.g. Savings',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PpForgeSpacing.md),
          PpForgeInput(
            controller: _note,
            label: 'Note',
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PpForgeSpacing.md),
        ],
      ),
    );
  }
}
