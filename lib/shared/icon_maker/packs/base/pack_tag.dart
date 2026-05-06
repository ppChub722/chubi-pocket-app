import '../icon_pack.dart';
import '_shared.dart';

/// Tag base pack — icons sized for label use, plus the shared bg + borders
/// so the picker offers full customization. Display-time rendering strips
/// bg + border via `IconType.applyDisplayRules`, so saved bg/border data is
/// preserved but never shown when a tag is rendered on screen.
const basePackTag = IconPack(
  id: 'base',
  icons: [
    IconPackItem(id: 'label', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'flag', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'star', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'favorite', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'bolt', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'swap_horiz', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'card_giftcard', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'subscriptions', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'flight', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'work_outline', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'schedule', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'local_offer', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'sell', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'emoji_events', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'redeem', colors: ['@presetThemeColor1']),
    IconPackItem(id: 'savings', colors: ['@presetThemeColor1']),
  ],
  backgrounds: commonBaseBackgrounds,
  borders: commonBaseBorders,
);
