import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';
import 'project_common.dart';

/// One member of an event (who paid, who a split is for). [members] = the
/// event's members as the page has them.
abstract final class EventMemberPicker {
  static Future<ProjectMember?> one(
    BuildContext context, {
    required List<ProjectMember> members,
    String? selectedId,
    String? title,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final r = await showItemPicker(
      context,
      useRootNavigator: useRootNavigator,
      ItemPickerSheet(
        title: title ?? l.projectMembersTitle,
        items: [
          for (final m in members)
            PickerItem(
              id: m.id,
              title: m.displayName,
              leading: memberAvatar(m, size: 28),
            ),
        ],
        selected: {?selectedId},
        searchHint: l.debtsSearchHint,
        noMatchText: l.contactPickerNoMatch,
      ),
    );
    final id = r?.id;
    return id == null ? null : members.where((m) => m.id == id).firstOrNull;
  }
}
