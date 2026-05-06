import 'package:flutter/material.dart';

import 'icon_code.dart';

/// Identifies which entity type an icon belongs to.
///
/// Drives:
/// - which base pack [PackRegistry] returns,
/// - which fallback icon [IconDisplay] uses when the entity has no code,
/// - whether the IconMaker picker is available,
/// - per-type display rules (see [IconTypeX.applyDisplayRules]),
/// - per-type default hide-toggles in the picker preview
///   (see [IconTypeX.defaultPreviewHides]).
enum IconType {
  account,
  userProfile,
  category,
  tag,
  project,
  contact,
  projectMember,
  projectTransaction,
  transaction,
}

extension IconTypeX on IconType {
  IconData get fallbackIcon => switch (this) {
        IconType.account => Icons.account_balance_wallet_outlined,
        IconType.userProfile => Icons.person_outline,
        IconType.category => Icons.category_outlined,
        IconType.tag => Icons.label_outline,
        IconType.project => Icons.folder_outlined,
        IconType.contact => Icons.contacts_outlined,
        IconType.projectMember => Icons.person_outline,
        IconType.projectTransaction => Icons.receipt_outlined,
        IconType.transaction => Icons.receipt_outlined,
      };

  /// Whether this type has an IconMaker picker.
  /// [transaction] is display-only — no picker.
  bool get hasPicker => this != IconType.transaction;

  /// Strips layers this type ignores at render time.
  ///
  /// Tags only ever display the icon glyph + tint — bg + border layers are
  /// preserved in storage but suppressed everywhere they're rendered.
  /// All other types render the code as-is.
  IconCode applyDisplayRules(IconCode code) => switch (this) {
        IconType.tag => IconCode(
            icon: code.icon,
            iconColors: code.iconColors,
          ),
        _ => code,
      };

  /// Per-type default for the picker's hide-toggles row.
  ///
  /// The user can override these on a per-session basis from the picker —
  /// these flags control only the live preview render, never the saved code.
  /// For tags, bg + border default to hidden so the preview matches what
  /// will actually appear on screens once saved.
  ({bool icon, bool bg, bool border}) get defaultPreviewHides => switch (this) {
        IconType.tag => (icon: false, bg: true, border: true),
        _ => (icon: false, bg: false, border: false),
      };
}
