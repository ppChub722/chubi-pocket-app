import 'package:flutter/material.dart';

import '../../ui.dart';

/// The words of [ChangePasswordSection] — the caller passes its localised
/// strings (the kit never reads the app's l10n).
class ChangePasswordStrings {
  const ChangePasswordStrings({
    required this.title,
    required this.primaryLabel,
    required this.currentLabel,
    required this.newLabel,
    required this.newHelper,
    required this.confirmLabel,
    required this.requiredError,
    required this.tooShort,
    required this.tooLong,
    required this.mustDiffer,
    required this.mismatch,
    required this.success,
  });

  /// The section heading ("Change password").
  final String title;

  /// The section's own button ("Change password").
  final String primaryLabel;
  final String currentLabel;
  final String newLabel;

  /// Under "New password" ("at least 8 characters").
  final String newHelper;
  final String confirmLabel;
  final String requiredError;
  final String tooShort;
  final String tooLong;
  final String mustDiffer;
  final String mismatch;

  /// The toast after a change.
  final String success;
}

/// Why a change-password call failed: a wrong current password is a FIELD
/// error ([currentError]); anything else is a banner ([message]).
class ChangePasswordFailure {
  const ChangePasswordFailure({this.currentError, this.message});

  final String? currentError;
  final String? message;
}

/// "Change password" as a collapsible section of the profile page (owner
/// 2026-10-12): closed by default; open it for three password fields that look
/// exactly like a detail page's note in edit (label above, framed value, the
/// eye inside the frame), the helper under the new one, and the section's own
/// primary button. No global edit mode: the section saves itself, with the
/// saving overlay; success clears the fields, collapses and toasts; a wrong
/// current password / a mismatch are field errors, a failed call a message.
///
/// [onSubmit] makes the API call and answers null when it worked.
class ChangePasswordSection extends StatefulWidget {
  const ChangePasswordSection({
    required this.strings,
    required this.onSubmit,
    super.key,
  });

  final ChangePasswordStrings strings;
  final Future<ChangePasswordFailure?> Function(
    String current,
    String newPassword,
  )
  onSubmit;

  @override
  State<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<ChangePasswordSection> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _banner;
  String? _currentError;

  /// A new key re-creates the section closed (after a success).
  int _epoch = 0;

  ChangePasswordStrings get _s => widget.strings;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _banner = null;
      _currentError = null;
    });
    final failure = await widget.onSubmit(_current.text, _new.text);
    if (!mounted) return;
    if (failure == null) {
      _current.clear();
      _new.clear();
      _confirm.clear();
      setState(() {
        _saving = false;
        _epoch++;
      });
      showAppSnackBar(context, _s.success, tone: Tone.success);
      return;
    }
    setState(() {
      _saving = false;
      _banner = failure.message;
      _currentError = failure.currentError;
    });
    if (_currentError != null) _formKey.currentState?.validate();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    String? helper,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) => DetailTextField(
    label: label,
    controller: controller,
    editing: true,
    obscurable: true,
    helper: helper,
    errorText: errorText,
    validator: validator,
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      key: ValueKey(_epoch),
      title: _s.title,
      initiallyOpen: false,
      children: [
        SavingOverlay(
          saving: _saving,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_banner != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppMessage(tone: Tone.danger, message: _banner!),
                  ),
                _field(
                  controller: _current,
                  label: _s.currentLabel,
                  errorText: _currentError,
                  onChanged: (_) {
                    if (_currentError != null) {
                      setState(() => _currentError = null);
                    }
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? _s.requiredError : null,
                ),
                _field(
                  controller: _new,
                  label: _s.newLabel,
                  helper: _s.newHelper,
                  validator: (v) {
                    if (v == null || v.length < 8) return _s.tooShort;
                    if (v.length > 128) return _s.tooLong;
                    if (v == _current.text) return _s.mustDiffer;
                    return null;
                  },
                ),
                _field(
                  controller: _confirm,
                  label: _s.confirmLabel,
                  validator: (v) => v != _new.text ? _s.mismatch : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    label: _s.primaryLabel,
                    expand: true,
                    loading: _saving,
                    onPressed: _saving ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
