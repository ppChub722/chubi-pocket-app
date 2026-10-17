class IconPackItem {
  const IconPackItem({required this.id, required this.colors});

  final String id;
  final List<String> colors;
}

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
