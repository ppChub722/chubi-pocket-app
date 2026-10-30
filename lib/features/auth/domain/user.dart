import 'package:equatable/equatable.dart';
import '../../../ui/ui.dart';
import '../../categories/domain/category.dart';
import '../../users/domain/avatar_settings.dart';

export '../../users/domain/avatar_settings.dart';

class DefaultWalletRef extends Equatable {
  const DefaultWalletRef({required this.id, required this.name, this.iconCode});

  factory DefaultWalletRef.fromJson(Map<String, dynamic> json) =>
      DefaultWalletRef(
        id: json['id'] as String,
        name: json['name'] as String,
        iconCode: json['icon_code'] is Map
            ? IconCode.fromJson(
                (json['icon_code'] as Map).cast<String, dynamic>(),
              )
            : null,
      );

  final String id;
  final String name;
  final IconCode? iconCode;

  @override
  List<Object?> get props => [id, name, iconCode];
}

/// How many notification types are on, of all there are.
class NotificationSummary extends Equatable {
  const NotificationSummary({required this.on, required this.total});

  factory NotificationSummary.fromJson(Map<String, dynamic> json) =>
      NotificationSummary(
        on: (json['on'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  final int on;
  final int total;

  @override
  List<Object?> get props => [on, total];
}

/// The page ids the server keeps a remembered choice for (`page_prefs`).
abstract final class PagePrefIds {
  static const wallets = 'wallets';
  static const budgets = 'budgets';
  static const goals = 'goals';
  static const recurring = 'recurring';
  static const events = 'events';
  static const categories = 'categories';
  static const tags = 'tags';
  static const contacts = 'contacts';
  static const debts = 'debts';
  static const pending = 'pending';

  static const all = [
    wallets,
    budgets,
    goals,
    recurring,
    events,
    categories,
    tags,
    contacts,
    debts,
    pending,
  ];
}

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.currency,
    this.email,
    this.iconCode,
    this.feeCategoryId,
    this.feeCategory,
    this.moneyStyle,
    this.moneyDecimals,
    this.themeMode,
    this.themeId,
    this.language,
    this.fontTh,
    this.fontEn,
    this.pagePrefs = const {},
    this.defaultAccount,
    this.autoSyncEvents = true,
    this.autoSyncDebts = true,
    this.autoAcceptEvents = true,
    this.autoAcceptDebts = false,
    this.notificationSummary,
    this.createdAt,
    this.updatedAt,
    AvatarData? avatar,
    this.avatarSettings,
    this.hasPassword = true,
  }) : _avatar = avatar;

  final String id;
  final String username;
  final String displayName;

  /// The user's one currency: a label, never converted; editable on the
  /// settings home.
  final String currency;
  final String? email;

  /// My icon (the icon maker; `avatar.icon_code` on the wire, PUT /users/me
  /// still takes `icon_code`).
  final IconCode? iconCode;
  final AvatarData? _avatar;

  /// 0.4.2 1b: my resolved avatar, as others see it.
  AvatarData get avatar =>
      _avatar ?? AvatarData.forName(displayName, iconCode: iconCode);

  /// The picture I picked (GET /users/me only; null on the login answer).
  final AvatarSettings? avatarSettings;

  /// 0.4.2 1b-2: false = an account made through an outside app with no
  /// password yet ("ตั้งรหัสผ่าน").
  final bool hasPassword;

  final String? feeCategoryId;

  /// The fee category as the เงิน page shows it (null = none set).
  final CategoryRef? feeCategory;

  final String? moneyStyle;

  /// Server preference `money_decimals`: always / never / auto (null = auto).
  final String? moneyDecimals;

  /// Server preferences; null = never saved (the app fills it from the
  /// device once after login).
  final String? themeMode;
  final String? themeId;
  final String? language;
  final String? fontTh;
  final String? fontEn;

  /// Remembered list choices per page ([PagePrefIds]); a missing page = the
  /// page's defaults.
  final Map<String, Map<String, dynamic>> pagePrefs;

  final DefaultWalletRef? defaultAccount;

  /// The two auto-sync switches (one value each, shared by every page).
  final bool autoSyncEvents;
  final bool autoSyncDebts;

  /// รับบิลใหม่อัตโนมัติ (owner 2026-10-28): a NEW shared bill lands in my
  /// book at once (on) or as a "เพิ่มในสมุด" notice (off). Events default on,
  /// debts / split bills off.
  final bool autoAcceptEvents;
  final bool autoAcceptDebts;

  final NotificationSummary? notificationSummary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The remembered choices of [page], empty = its defaults.
  Map<String, dynamic> pagePref(String page) => pagePrefs[page] ?? const {};

  factory User.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] is Map
        ? (json['preferences'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    String? pref(String k) => prefs[k] is String ? prefs[k] as String : null;
    final rawPages = prefs['page_prefs'] ?? json['page_prefs'];
    final displayName = json['display_name'] as String;
    final avatar = AvatarData.parse(json, name: displayName);
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: displayName,
      currency: (json['currency'] as String?) ?? 'THB',
      email: json['email'] as String?,
      iconCode: avatar.iconCode,
      avatar: avatar,
      avatarSettings: json['avatar_settings'] is Map
          ? AvatarSettings.fromJson(
              (json['avatar_settings'] as Map).cast<String, dynamic>(),
            )
          : null,
      hasPassword: (json['has_password'] as bool?) ?? true,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      feeCategoryId: pref('fee_category_id'),
      feeCategory: json['fee_category'] is Map
          ? CategoryRef.fromJson(
              (json['fee_category'] as Map).cast<String, dynamic>(),
            )
          : null,
      moneyStyle: pref('money_style'),
      moneyDecimals: pref('money_decimals'),
      themeMode: pref('theme_mode'),
      themeId: pref('theme_id'),
      language: pref('language'),
      fontTh: pref('font_th'),
      fontEn: pref('font_en'),
      pagePrefs: {
        if (rawPages is Map)
          for (final e in rawPages.entries)
            if (e.value is Map)
              e.key as String: (e.value as Map).cast<String, dynamic>(),
      },
      defaultAccount: json['default_account'] is Map
          ? DefaultWalletRef.fromJson(
              (json['default_account'] as Map).cast<String, dynamic>(),
            )
          : null,
      autoSyncEvents: (json['auto_sync_events'] as bool?) ?? true,
      autoSyncDebts: (json['auto_sync_debts'] as bool?) ?? true,
      autoAcceptEvents: (json['auto_accept_events'] as bool?) ?? true,
      autoAcceptDebts: (json['auto_accept_debts'] as bool?) ?? false,
      notificationSummary: json['notification_summary'] is Map
          ? NotificationSummary.fromJson(
              (json['notification_summary'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  User copyWith({
    String? displayName,
    String? email,
    IconCode? iconCode,
    bool clearEmail = false,
    bool clearIconCode = false,
    String? feeCategoryId,
    bool clearFeeCategory = false,
    AvatarData? avatar,
    AvatarSettings? avatarSettings,
    bool? hasPassword,
  }) {
    final nextIcon = clearIconCode ? null : (iconCode ?? this.iconCode);
    return User(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      currency: currency,
      email: clearEmail ? null : (email ?? this.email),
      iconCode: nextIcon,
      avatar:
          avatar ??
          (iconCode != null || clearIconCode
              ? this.avatar.withIcon(nextIcon)
              : _avatar),
      avatarSettings: avatarSettings ?? this.avatarSettings,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt,
      updatedAt: updatedAt,
      defaultAccount: defaultAccount,
      autoSyncEvents: autoSyncEvents,
      autoSyncDebts: autoSyncDebts,
      autoAcceptEvents: autoAcceptEvents,
      autoAcceptDebts: autoAcceptDebts,
      notificationSummary: notificationSummary,
      feeCategoryId: clearFeeCategory
          ? null
          : (feeCategoryId ?? this.feeCategoryId),
      feeCategory: clearFeeCategory || feeCategoryId != null
          ? null
          : feeCategory,
      moneyStyle: moneyStyle,
      moneyDecimals: moneyDecimals,
      themeMode: themeMode,
      themeId: themeId,
      language: language,
      fontTh: fontTh,
      fontEn: fontEn,
      pagePrefs: pagePrefs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    currency,
    email,
    iconCode,
    feeCategoryId,
    feeCategory,
    moneyStyle,
    moneyDecimals,
    themeMode,
    themeId,
    language,
    fontTh,
    fontEn,
    pagePrefs,
    defaultAccount,
    autoSyncEvents,
    autoSyncDebts,
    autoAcceptEvents,
    autoAcceptDebts,
    notificationSummary,
    createdAt,
    updatedAt,
    _avatar,
    avatarSettings,
    hasPassword,
  ];
}
