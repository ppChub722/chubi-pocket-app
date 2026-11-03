import 'package:flutter/widgets.dart';

import 'app/app_icons.dart';

/// What a button does, which fixes its icon: one table, so every Save /
/// Cancel / Clear in the app wears the same icon. `AppButton(kind:)` reads it;
/// an explicit `icon:` still wins.
enum ButtonIconKind {
  save(AppIcons.save),
  submit(AppIcons.send),
  confirm(AppIcons.check),
  apply(AppIcons.check),
  cancel(AppIcons.close),
  delete(AppIcons.delete),
  clear(AppIcons.clear),
  reset(AppIcons.reset),
  retry(AppIcons.refresh),
  undo(AppIcons.undo),
  add(AppIcons.add),
  edit(AppIcons.edit),
  share(AppIcons.share),
  connect(AppIcons.link),
  disconnect(AppIcons.unlink),
  split(AppIcons.split),
  settle(AppIcons.settle),
  today(AppIcons.today),
  photo(AppIcons.photo),
  skip(AppIcons.skip),
  paid(AppIcons.success),
  viewAll(AppIcons.chevronRight, trailing: true);

  const ButtonIconKind(this.icon, {this.trailing = false});

  final IconData icon;

  /// A button that leads on: the icon goes after the label.
  final bool trailing;
}
