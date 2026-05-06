import '../icon_type.dart';
import 'icon_pack.dart';
import 'base/pack_account.dart';
import 'base/pack_category.dart';
import 'base/pack_contact.dart';
import 'base/pack_project.dart';
import 'base/pack_project_member.dart';
import 'base/pack_project_transaction.dart';
import 'base/pack_tag.dart';
import 'base/pack_user_profile.dart';

/// Central registry for IconMaker packs.
///
/// **Base packs are per-type** — each [IconType] maps to its own curated
/// icon set in `packs/base/pack_<type>.dart`. Non-tag base packs share the
/// same `commonBaseBackgrounds` + `commonBaseBorders` (see `base/_shared.dart`).
///
/// **Extra packs (DLC, seasonal, paid) are global** — keyed by pack id and
/// available to every [IconType] when present in `grantedPackIds`. Each
/// extra pack ships its own icons + bg + borders and shows up in every
/// type's picker once owned.
///
/// To add a new extra pack:
///   1. Create `packs/<pack_id>/pack.dart` with a top-level const.
///   2. Register it in [_extraPacks] below.
class PackRegistry {
  PackRegistry._();

  static const Map<IconType, IconPack> _basePacks = {
    IconType.account: basePackAccount,
    IconType.category: basePackCategory,
    IconType.contact: basePackContact,
    IconType.project: basePackProject,
    IconType.projectMember: basePackProjectMember,
    IconType.projectTransaction: basePackProjectTransaction,
    IconType.tag: basePackTag,
    IconType.userProfile: basePackUserProfile,
    // `IconType.transaction` has no picker — see `IconTypeX.hasPicker`.
  };

  /// Global extra packs, keyed by pack id. Empty for now; future:
  ///   'christmas2026': christmas2026Pack,
  ///   'songkran2026':  songkran2026Pack,
  static const Map<String, IconPack> _extraPacks = {};

  /// Returns the per-type base pack followed by any granted global extras
  /// in the order they appear in [grantedPackIds]. Unknown ids are skipped.
  static List<IconPack> packs({
    required IconType type,
    List<String> grantedPackIds = const [],
  }) {
    final result = <IconPack>[];
    final base = _basePacks[type];
    if (base != null) result.add(base);
    for (final id in grantedPackIds) {
      final pack = _extraPacks[id];
      if (pack != null) result.add(pack);
    }
    return result;
  }
}
