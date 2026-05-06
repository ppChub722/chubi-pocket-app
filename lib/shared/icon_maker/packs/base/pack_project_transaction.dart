import '../icon_pack.dart';
import '_shared.dart';

// Project transactions represent spending categories within a project,
// so they share the same icon set as categories.
const basePackProjectTransaction = IconPack(
  id: 'base',
  icons: [
    // Food & Drinks
    IconPackItem(id: 'restaurant', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'shopping_basket', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'delivery_dining', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'convenience_store', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'restaurant_menu', colors: ['@presetThemeColorOnIcon']),
    // Transportation
    IconPackItem(id: 'directions_car', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'local_gas_station', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'local_parking', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'directions_bus', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'local_taxi', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'car_repair', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'policy', colors: ['@presetThemeColorOnIcon']),
    // Shopping
    IconPackItem(id: 'shopping_bag', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'checkroom', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'headphones', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'tv', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'face_retouching', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'cleaning_services', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'palette', colors: ['@presetThemeColorOnIcon']),
    // Bills
    IconPackItem(id: 'receipt_long', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'home', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'wifi', colors: ['@presetThemeColorOnIcon']),
    // Services
    IconPackItem(id: 'handshake', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'subscriptions', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'spa', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'fitness_center', colors: ['@presetThemeColorOnIcon']),
    // Health
    IconPackItem(id: 'local_hospital', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'medical_services', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'visibility', colors: ['@presetThemeColorOnIcon']),
    // Entertainment
    IconPackItem(id: 'movie', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'sports_esports', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'theaters', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'nightlife', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'flight', colors: ['@presetThemeColorOnIcon']),
    // Investments
    IconPackItem(id: 'trending_up', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'savings', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'casino', colors: ['@presetThemeColorOnIcon']),
    // Debt
    IconPackItem(id: 'credit_card', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'schedule', colors: ['@presetThemeColorOnIcon']),
    // Other
    IconPackItem(id: 'more_horiz', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'tune', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'volunteer_activism', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'category', colors: ['@presetThemeColorOnIcon']),
    // Income
    IconPackItem(id: 'payments', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'work', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'storefront', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'swap_horiz', colors: ['@presetThemeColorOnIcon']),
    IconPackItem(id: 'redeem', colors: ['@presetThemeColorOnIcon']),
  ],
  backgrounds: commonBaseBackgrounds,
  borders: commonBaseBorders,
);
