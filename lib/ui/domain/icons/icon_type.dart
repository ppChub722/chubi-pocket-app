import 'package:flutter/material.dart';

import 'icon_code.dart';

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

  bool get hasPicker => this != IconType.transaction;

  IconCode applyDisplayRules(IconCode code) => switch (this) {
    IconType.tag => IconCode(icon: code.icon, iconColors: code.iconColors),
    _ => code,
  };

  ({bool icon, bool bg, bool border}) get defaultPreviewHides => switch (this) {
    IconType.tag => (icon: false, bg: true, border: true),
    _ => (icon: false, bg: false, border: false),
  };
}
