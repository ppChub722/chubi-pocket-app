/// One item (icon, background, or border variant) inside an [IconPack].
///
/// [colors] serves two purposes:
/// - length → how many color slots this item needs in the picker
/// - values → hex defaults pre-filled when the user first selects this item
class IconPackItem {
  const IconPackItem({required this.id, required this.colors});

  final String id;
  final List<String> colors;
}

/// A named set of icons, backgrounds, and borders available to a user.
///
/// Every [IconType] always has access to the base pack. Extra packs are
/// granted via [user_pack_permissions] and loaded by [PackRegistry].
class IconPack {
  const IconPack({
    required this.id,
    required this.icons,
    this.backgrounds = const [],
    this.borders = const [],
  });

  final String id;
  final List<IconPackItem> icons;
  final List<IconPackItem> backgrounds;
  final List<IconPackItem> borders;
}
