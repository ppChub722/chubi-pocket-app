import 'package:flutter/material.dart';

import '../../icons/icon_type.dart';
import '../../icons/packs/base/pack_account.dart';
import '../../icons/packs/base/pack_category.dart';
import '../../icons/packs/base/pack_contact.dart';
import '../../icons/packs/base/pack_project.dart';
import '../../icons/packs/base/pack_project_member.dart';
import '../../icons/packs/base/pack_project_transaction.dart';
import '../../icons/packs/base/pack_tag.dart';
import '../../icons/packs/base/pack_user_profile.dart';

/// chubiPocket's icon types: which ppForge pack and fallback each thing that
/// has an icon uses (`IconType.account`, …).
abstract final class IconType {
  static const account = PpForgeIconType(
    'account',
    fallbackIcon: Icons.account_balance_wallet_outlined,
    basePack: basePackAccount,
  );
  static const userProfile = PpForgeIconType(
    'userProfile',
    fallbackIcon: Icons.person_outline,
    basePack: basePackUserProfile,
  );
  static const category = PpForgeIconType(
    'category',
    fallbackIcon: Icons.category_outlined,
    basePack: basePackCategory,
  );

  /// Tags only ever show the glyph + tint.
  static const tag = PpForgeIconType(
    'tag',
    fallbackIcon: Icons.label_outline,
    basePack: basePackTag,
    iconOnly: true,
  );
  static const project = PpForgeIconType(
    'project',
    fallbackIcon: Icons.folder_outlined,
    basePack: basePackProject,
  );
  static const contact = PpForgeIconType(
    'contact',
    fallbackIcon: Icons.contacts_outlined,
    basePack: basePackContact,
  );
  static const projectMember = PpForgeIconType(
    'projectMember',
    fallbackIcon: Icons.person_outline,
    basePack: basePackProjectMember,
  );
  static const projectTransaction = PpForgeIconType(
    'projectTransaction',
    fallbackIcon: Icons.receipt_outlined,
    basePack: basePackProjectTransaction,
  );

  /// Display-only — no icon maker.
  static const transaction = PpForgeIconType(
    'transaction',
    fallbackIcon: Icons.receipt_outlined,
  );
}
