import '../icon_type.dart';
import 'package:pp_forge_core/ui.dart';
import 'base/pack_account.dart';
import 'base/pack_category.dart';
import 'base/pack_contact.dart';
import 'base/pack_project.dart';
import 'base/pack_project_member.dart';
import 'base/pack_project_transaction.dart';
import 'base/pack_tag.dart';
import 'base/pack_user_profile.dart';

class PackRegistry {
  PackRegistry._();

  static const Map<IconType, PpForgeIconPack> _basePacks = {
    IconType.account: basePackAccount,
    IconType.category: basePackCategory,
    IconType.contact: basePackContact,
    IconType.project: basePackProject,
    IconType.projectMember: basePackProjectMember,
    IconType.projectTransaction: basePackProjectTransaction,
    IconType.tag: basePackTag,
    IconType.userProfile: basePackUserProfile,
  };

  static const Map<String, PpForgeIconPack> _extraPacks = {};

  static List<PpForgeIconPack> packs({
    required IconType type,
    List<String> grantedPackIds = const [],
  }) {
    final result = <PpForgeIconPack>[];
    final base = _basePacks[type];
    if (base != null) result.add(base);
    for (final id in grantedPackIds) {
      final pack = _extraPacks[id];
      if (pack != null) result.add(pack);
    }
    return result;
  }
}
