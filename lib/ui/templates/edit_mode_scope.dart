import 'package:flutter/widgets.dart';

/// Tells the templates below an `editScope` whether the page is being edited
/// or saved. `DetailPageBody` reads it to switch pull-to-refresh OFF in edit
/// mode, so a refresh can never overwrite what the user has typed. Installed by
/// `EditModeMixin.editScope`; nothing else needs it.
class EditModeScope extends InheritedWidget {
  const EditModeScope({required this.busy, required super.child, super.key});

  /// Editing or saving — refresh must not run.
  final bool busy;

  /// Whether the nearest scope says the page is busy (false with no scope).
  static bool isBusy(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditModeScope>()?.busy ??
      false;

  @override
  bool updateShouldNotify(EditModeScope old) => busy != old.busy;
}
