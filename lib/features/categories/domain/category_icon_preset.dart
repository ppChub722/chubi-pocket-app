import 'package:flutter/material.dart';

/// Icon registry for categories.
///
/// Defined as a flat enum so the create / edit form maps directly onto
/// `IconPickerOption` (the picker widget knows nothing about categories).
/// Icons here are tuned for finance categories — restaurants, transit,
/// medical, etc. — distinct from the wallet-shaped icons in
/// [`AccountIconPreset`](../../accounts/domain/account_icon_preset.dart).
///
/// Adding an icon = one new enum entry. Server stores the [id]; the icon
/// itself can later be replaced by a designer asset by setting an
/// `assetPath` (mirrors avatar / account preset patterns).
enum CategoryIconPreset {
  // Food & Drinks
  restaurant('restaurant', Icons.restaurant),
  shoppingBasket('shopping_basket', Icons.shopping_basket_outlined),
  deliveryDining('delivery_dining', Icons.delivery_dining_outlined),
  convenienceStore('convenience_store', Icons.local_convenience_store_outlined),
  restaurantMenu('restaurant_menu', Icons.restaurant_menu_outlined),

  // Transportation & Vehicle
  directionsCar('directions_car', Icons.directions_car_outlined),
  localGasStation('local_gas_station', Icons.local_gas_station_outlined),
  localParking('local_parking', Icons.local_parking_outlined),
  directionsBus('directions_bus', Icons.directions_bus_outlined),
  localTaxi('local_taxi', Icons.local_taxi_outlined),
  carRepair('car_repair', Icons.car_repair_outlined),
  policy('policy', Icons.policy_outlined),

  // Shopping
  shoppingBag('shopping_bag', Icons.shopping_bag_outlined),
  checkroom('checkroom', Icons.checkroom_outlined),
  headphones('headphones', Icons.headphones_outlined),
  tv('tv', Icons.tv_outlined),
  faceRetouching('face_retouching', Icons.face_retouching_natural_outlined),
  cleaningServices('cleaning_services', Icons.cleaning_services_outlined),
  palette('palette', Icons.palette_outlined),

  // Bills
  receiptLong('receipt_long', Icons.receipt_long_outlined),
  home('home', Icons.home_outlined),
  wifi('wifi', Icons.wifi),

  // Services
  handshake('handshake', Icons.handshake_outlined),
  subscriptions('subscriptions', Icons.subscriptions_outlined),
  spa('spa', Icons.spa_outlined),
  fitnessCenter('fitness_center', Icons.fitness_center_outlined),

  // Health
  localHospital('local_hospital', Icons.local_hospital_outlined),
  medicalServices('medical_services', Icons.medical_services_outlined),
  visibility('visibility', Icons.visibility_outlined),

  // Entertainment
  movie('movie', Icons.movie_outlined),
  sportsEsports('sports_esports', Icons.sports_esports_outlined),
  theaters('theaters', Icons.theaters_outlined),
  nightlife('nightlife', Icons.nightlife_outlined),
  flight('flight', Icons.flight_outlined),

  // Investments
  trendingUp('trending_up', Icons.trending_up),
  savings('savings', Icons.savings_outlined),
  casino('casino', Icons.casino_outlined),

  // Debt
  creditCard('credit_card', Icons.credit_card_outlined),
  schedule('schedule', Icons.schedule_outlined),

  // Other
  moreHoriz('more_horiz', Icons.more_horiz),
  tune('tune', Icons.tune),
  volunteerActivism('volunteer_activism', Icons.volunteer_activism_outlined),
  category('category', Icons.category_outlined),

  // Income
  payments('payments', Icons.payments_outlined),
  work('work', Icons.work_outline),
  storefront('storefront', Icons.storefront_outlined),
  swapHoriz('swap_horiz', Icons.swap_horiz),
  redeem('redeem', Icons.redeem_outlined),

  // System (for completeness, used by the 8 hidden seed entries)
  systemTransfer('system_transfer', Icons.swap_vert),
  systemAdjustment('system_adjustment', Icons.tune),
  systemOpening('system_opening', Icons.flag_outlined),
  systemDebtReceived('system_debt_received', Icons.call_received),
  systemDebtPaid('system_debt_paid', Icons.payments_outlined);

  const CategoryIconPreset(this.id, this.icon);

  final String id;
  final IconData icon;

  static CategoryIconPreset byId(String id) {
    return values.firstWhere(
      (p) => p.id == id,
      orElse: () => CategoryIconPreset.category,
    );
  }
}

/// Color palette for categories — duplicates [`AccountColor`]'s 12 swatches.
///
/// Pending P2 polish: extract into a single shared `BrandSwatch` palette
/// so accounts, categories, and future modules pull from one place.
/// Duplicating now to avoid a cross-feature import; behavior is identical.
class CategoryColor {
  const CategoryColor._(this.id, this.color);

  final String id;
  final Color color;

  static const red = CategoryColor._('red', Color(0xFFE57373));
  static const pink = CategoryColor._('pink', Color(0xFFF06292));
  static const purple = CategoryColor._('purple', Color(0xFFBA68C8));
  static const deepPurple = CategoryColor._('deep_purple', Color(0xFF9575CD));
  static const indigo = CategoryColor._('indigo', Color(0xFF7986CB));
  static const blue = CategoryColor._('blue', Color(0xFF64B5F6));
  static const lightBlue = CategoryColor._('light_blue', Color(0xFF4FC3F7));
  static const cyan = CategoryColor._('cyan', Color(0xFF4DD0E1));
  static const green = CategoryColor._('green', Color(0xFFAED581));
  static const yellow = CategoryColor._('yellow', Color(0xFFFFD54F));
  static const orange = CategoryColor._('orange', Color(0xFFFFB74D));
  static const brown = CategoryColor._('brown', Color(0xFFA1887F));

  static const all = <CategoryColor>[
    red,
    pink,
    purple,
    deepPurple,
    indigo,
    blue,
    lightBlue,
    cyan,
    green,
    yellow,
    orange,
    brown,
  ];

  static CategoryColor byId(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => CategoryColor.blue,
    );
  }

  /// `#RRGGBB` representation. The BE stores `categories.color` as
  /// `VARCHAR(7)` containing exactly this format (spec §3.1).
  String toHex() {
    int channel(double c) => (c * 255).round() & 0xff;
    final r = channel(color.r).toRadixString(16).padLeft(2, '0');
    final g = channel(color.g).toRadixString(16).padLeft(2, '0');
    final b = channel(color.b).toRadixString(16).padLeft(2, '0');
    return '#${(r + g + b).toUpperCase()}';
  }

  /// Resolve a `#RRGGBB` from the BE back to one of the 12 swatches.
  /// Falls back to [blue] when the hex doesn't match a known swatch
  /// (e.g. legacy data or a future swatch added by another client).
  static CategoryColor fromHex(String? hex) {
    if (hex == null) return CategoryColor.blue;
    final normalized = hex.toUpperCase();
    for (final c in all) {
      if (c.toHex() == normalized) return c;
    }
    return CategoryColor.blue;
  }
}
