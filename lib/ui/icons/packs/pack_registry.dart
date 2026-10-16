import '../icon_type.dart';
import 'icon_pack.dart';

/// The packs the icon maker offers for a [PpForgeIconType].
///
/// **Base packs are per-type** — each type carries its own curated set
/// ([PpForgeIconType.basePack]; ppForge ships them in `packs/base/`). Non-tag
/// base packs share `commonBaseBackgrounds` + `commonBaseBorders`.
///
/// **Extra packs (DLC, seasonal, paid) are global** — the host app registers
/// them by id ([registerExtra]) and every type's picker shows the ones in
/// `grantedPackIds`.
class PackRegistry {
  PackRegistry._();

  static final Map<String, IconPack> _extraPacks = {};

  /// Makes [pack] available as an extra (keyed by [IconPack.id]).
  static void registerExtra(IconPack pack) => _extraPacks[pack.id] = pack;

  /// Returns the type's base pack followed by any granted extras in the
  /// order they appear in [grantedPackIds]. Unknown ids are skipped.
  static List<IconPack> packs({
    required PpForgeIconType type,
    List<String> grantedPackIds = const [],
  }) {
    final result = <IconPack>[];
    final base = type.basePack;
    if (base != null) result.add(base);
    for (final id in grantedPackIds) {
      final pack = _extraPacks[id];
      if (pack != null) result.add(pack);
    }
    return result;
  }
}
