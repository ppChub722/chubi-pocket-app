import 'package:flutter/widgets.dart';

class EditModeScope extends InheritedWidget {
  const EditModeScope({required this.busy, required super.child, super.key});

  /// Editing or saving — refresh must not run.
  final bool busy;

  static bool isBusy(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditModeScope>()?.busy ??
      false;

  @override
  bool updateShouldNotify(EditModeScope old) => busy != old.busy;
}
