import 'package:flutter/material.dart';

/// Curated icon set the user picks from when creating / editing an account.
///
/// Stored on the server as `accounts.icon = '<id>'`. We use Material icon
/// names so the app can render them without bundled assets — Phase 2 may add
/// custom illustrations.
///
/// Mirrors the `avatar_presets` pattern but tuned for account semantics
/// (wallet shapes, card shapes, bank shapes, etc.).
enum AccountIconPreset {
  wallet('wallet', Icons.account_balance_wallet),
  cash('cash', Icons.payments_outlined),
  bank('bank', Icons.account_balance),
  savings('savings', Icons.savings),
  card('card', Icons.credit_card),
  contactlessCard('contactless_card', Icons.contactless),
  eWallet('e_wallet', Icons.qr_code_2),
  giftCard('gift_card', Icons.card_giftcard),
  travel('travel', Icons.flight),
  shopping('shopping', Icons.shopping_bag_outlined),
  business('business', Icons.business_center_outlined),
  loan('loan', Icons.receipt_long_outlined);

  const AccountIconPreset(this.id, this.icon);

  /// Stable identifier persisted on the server.
  final String id;
  final IconData icon;

  static AccountIconPreset byId(String id) {
    return values.firstWhere(
      (p) => p.id == id,
      orElse: () => AccountIconPreset.wallet,
    );
  }
}

/// 12-color palette — same as the user-avatar `_hashPalette` so accounts and
/// avatars feel like part of the same brand world (one palette to maintain).
///
/// Stored on the server as `accounts.color = '#RRGGBB'`. The picker UI
/// constrains the user to these 12 swatches; we don't allow free-form color
/// picking in Phase 1 to keep visual cohesion.
class AccountColor {
  const AccountColor._(this.id, this.color);

  final String id;
  final Color color;

  static const red = AccountColor._('red', Color(0xFFE57373));
  static const pink = AccountColor._('pink', Color(0xFFF06292));
  static const purple = AccountColor._('purple', Color(0xFFBA68C8));
  static const deepPurple = AccountColor._('deep_purple', Color(0xFF9575CD));
  static const indigo = AccountColor._('indigo', Color(0xFF7986CB));
  static const blue = AccountColor._('blue', Color(0xFF64B5F6));
  static const lightBlue = AccountColor._('light_blue', Color(0xFF4FC3F7));
  static const cyan = AccountColor._('cyan', Color(0xFF4DD0E1));
  static const green = AccountColor._('green', Color(0xFFAED581));
  static const yellow = AccountColor._('yellow', Color(0xFFFFD54F));
  static const orange = AccountColor._('orange', Color(0xFFFFB74D));
  static const brown = AccountColor._('brown', Color(0xFFA1887F));

  static const all = <AccountColor>[
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

  /// Hex form `#RRGGBB` — what the spec stores in `accounts.color`.
  String get hex {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static AccountColor byId(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => AccountColor.blue,
    );
  }

  /// Best-effort lookup by hex string. Used when the server returns a
  /// `#RRGGBB` that wasn't picked from the palette (legacy data) — falls
  /// through to the closest swatch.
  static AccountColor byHex(String hex) {
    final normalized = hex.toUpperCase();
    return all.firstWhere(
      (c) => c.hex == normalized,
      orElse: () => AccountColor.blue,
    );
  }
}
