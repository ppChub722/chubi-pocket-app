import 'package:flutter/material.dart';

/// Maps every stable icon ID to its [IconData].
///
/// IDs are persisted server-side in `icon_code.icon` — never rename them.
/// Per-domain icon lists have moved to `packs/base/pack_*.dart`.
/// When adding a new icon: add the ID here in [_all] and reference it in the
/// relevant pack file.
class IconRegistry {
  IconRegistry._();

  static IconData get(String? id, {IconData fallback = Icons.category_outlined}) {
    if (id == null) return fallback;
    return _all[id] ?? fallback;
  }

  static const Map<String, IconData> _all = {
    // accounts
    'wallet': Icons.account_balance_wallet,
    'cash': Icons.payments_outlined,
    'bank': Icons.account_balance,
    'card': Icons.credit_card,
    'contactless_card': Icons.contactless,
    'e_wallet': Icons.qr_code_2,
    'gift_card': Icons.card_giftcard,
    'travel': Icons.flight,
    'shopping': Icons.shopping_bag_outlined,
    'business': Icons.business_center_outlined,
    'loan': Icons.receipt_long_outlined,

    // categories – food
    'restaurant': Icons.restaurant,
    'shopping_basket': Icons.shopping_basket_outlined,
    'delivery_dining': Icons.delivery_dining_outlined,
    'convenience_store': Icons.local_convenience_store_outlined,
    'restaurant_menu': Icons.restaurant_menu_outlined,

    // categories – transport
    'directions_car': Icons.directions_car_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'local_parking': Icons.local_parking_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'local_taxi': Icons.local_taxi_outlined,
    'car_repair': Icons.car_repair_outlined,
    'policy': Icons.policy_outlined,

    // categories – shopping
    'shopping_bag': Icons.shopping_bag_outlined,
    'checkroom': Icons.checkroom_outlined,
    'headphones': Icons.headphones_outlined,
    'tv': Icons.tv_outlined,
    'face_retouching': Icons.face_retouching_natural_outlined,
    'cleaning_services': Icons.cleaning_services_outlined,
    'palette': Icons.palette_outlined,

    // categories – bills
    'receipt_long': Icons.receipt_long_outlined,
    'home': Icons.home_outlined,
    'wifi': Icons.wifi,

    // categories – services
    'handshake': Icons.handshake_outlined,
    'spa': Icons.spa_outlined,
    'fitness_center': Icons.fitness_center_outlined,

    // categories – health
    'local_hospital': Icons.local_hospital_outlined,
    'medical_services': Icons.medical_services_outlined,
    'visibility': Icons.visibility_outlined,

    // categories – entertainment
    'movie': Icons.movie_outlined,
    'sports_esports': Icons.sports_esports_outlined,
    'theaters': Icons.theaters_outlined,
    'nightlife': Icons.nightlife_outlined,

    // categories – investments
    'trending_up': Icons.trending_up,
    'casino': Icons.casino_outlined,

    // categories – other
    'more_horiz': Icons.more_horiz,
    'tune': Icons.tune,
    'volunteer_activism': Icons.volunteer_activism_outlined,
    'category': Icons.category_outlined,
    'storefront': Icons.storefront_outlined,

    // shared (accounts + categories + tags)
    'savings': Icons.savings_outlined,
    'flight': Icons.flight,
    'subscriptions': Icons.subscriptions_outlined,
    'swap_horiz': Icons.swap_horiz,
    'schedule': Icons.schedule,
    'credit_card': Icons.credit_card_outlined,
    'redeem': Icons.redeem_outlined,
    'payments': Icons.payments_outlined,
    'work': Icons.work_outline,

    // user avatars
    'person': Icons.person_outline,
    'man': Icons.man,
    'woman': Icons.woman,
    'face_smile': Icons.sentiment_very_satisfied_outlined,
    'bakery_dining': Icons.bakery_dining,

    // tags only
    'label': Icons.label_outline,
    'flag': Icons.flag_outlined,
    'star': Icons.star_outline,
    'favorite': Icons.favorite_outline,
    'bolt': Icons.bolt,
    'card_giftcard': Icons.card_giftcard,
    'work_outline': Icons.work_outline,
    'local_offer': Icons.local_offer_outlined,
    'sell': Icons.sell_outlined,
    'emoji_events': Icons.emoji_events_outlined,

    // projects
    'folder': Icons.folder_outlined,
    'folder_open': Icons.folder_open,
    'groups': Icons.groups,
    'campaign': Icons.campaign,

    // contacts
    'contact_page': Icons.contact_page_outlined,
    'apartment': Icons.apartment,
    'badge': Icons.badge,

    // project members
    'engineering': Icons.engineering,

    // system (not pickable — used by seed categories)
    'system_transfer': Icons.swap_vert,
    'system_adjustment': Icons.tune,
    'system_opening': Icons.flag_outlined,
    'system_debt_received': Icons.call_received,
    'system_debt_paid': Icons.payments_outlined,
  };
}
