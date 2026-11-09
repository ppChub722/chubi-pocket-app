import 'package:flutter/widgets.dart';

import 'pp_forge_icons.dart';

/// What a button does, which fixes its icon: one table, so every Save /
/// Cancel / Clear in the app wears the same icon. `PpForgeButton(kind:)` reads it;
/// an explicit `icon:` still wins.
enum ButtonIconKind {
  save(PpForgeIcons.save),
  submit(PpForgeIcons.send),
  confirm(PpForgeIcons.check),
  apply(PpForgeIcons.check),
  cancel(PpForgeIcons.close),
  delete(PpForgeIcons.delete),
  clear(PpForgeIcons.clear),
  reset(PpForgeIcons.reset),
  retry(PpForgeIcons.refresh),
  undo(PpForgeIcons.undo),
  add(PpForgeIcons.add),
  edit(PpForgeIcons.edit),
  share(PpForgeIcons.share),
  connect(PpForgeIcons.link),
  disconnect(PpForgeIcons.unlink),
  split(PpForgeIcons.split),
  settle(PpForgeIcons.settle),
  today(PpForgeIcons.today),
  photo(PpForgeIcons.photo),
  skip(PpForgeIcons.skip),
  paid(PpForgeIcons.success),
  viewAll(PpForgeIcons.chevronRight, trailing: true);

  const ButtonIconKind(this.icon, {this.trailing = false});

  final IconData icon;

  /// A button that leads on: the icon goes after the label.
  final bool trailing;
}
