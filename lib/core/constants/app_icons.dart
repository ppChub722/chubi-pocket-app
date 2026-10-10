import 'package:flutter/material.dart';

/// The app's one source of UI icons, named by **meaning**, not by glyph.
/// Change a glyph here and every screen that shows that concept follows.
///
/// Rules:
/// - New UI code uses `AppIcons.x`, never `Icons.x` directly.
/// - One meaning → one glyph. If two things need different glyphs they get
///   two names (e.g. [debt] vs [bank], [category] vs [iconPicker]).
/// - User-chosen icons (icon maker art) are NOT here — see `IconRegistry`.
///
/// Browse them live at `/dev/widgets` → ไอคอน.
abstract final class AppIcons {
  // ── Tabs / chrome ────────────────────────────────────────────────────
  static const dashboard = Icons.dashboard_outlined;
  static const dashboardActive = Icons.dashboard;
  static const transactions = Icons.list_alt_outlined;
  static const transactionsActive = Icons.list_alt;
  static const wallet = Icons.account_balance_wallet_outlined;
  static const walletActive = Icons.account_balance_wallet;
  static const more = Icons.more_horiz;
  static const back = Icons.arrow_back;
  static const arrowForward = Icons.arrow_forward;
  static const close = Icons.close;
  static const notifications = Icons.notifications_outlined;
  static const pending = Icons.move_to_inbox_outlined;
  static const settings = Icons.settings_outlined;
  static const markAllRead = Icons.done_all;
  static const profile = Icons.person_outline;

  // ── Features ─────────────────────────────────────────────────────────
  static const category = Icons.category_outlined;
  static const tag = Icons.sell_outlined;
  static const contact = Icons.contacts_outlined;
  static const project = Icons.groups_outlined;
  static const debt = Icons.handshake_outlined;
  static const budget = Icons.savings_outlined;
  static const savingGoal = Icons.flag_outlined;
  static const scheduled = Icons.schedule_outlined;
  static const member = Icons.person_outline;
  static const inviteMember = Icons.person_add_alt_1_outlined;
  static const addContact = Icons.person_add_outlined;
  static const addDebt = Icons.note_add_outlined;
  static const settle = Icons.price_check;
  static const history = Icons.history;

  // ── Money / account kinds ────────────────────────────────────────────
  static const bank = Icons.account_balance_outlined;
  static const cash = Icons.payments_outlined;
  static const eWallet = Icons.qr_code_2_outlined;
  static const creditCard = Icons.credit_card_outlined;
  static const payLater = Icons.access_time_outlined;
  // A wallet number of kind "other" (spec 15 §5) — not a bank / PromptPay / card.
  static const accountNumber = Icons.pin_outlined;
  static const income = Icons.add;
  static const expense = Icons.remove;
  static const transfer = Icons.swap_horiz;
  static const noWallet = Icons.money_off_outlined;

  /// "ไม่ระบุหมวด" — rows without a category (filters, pickers).
  static const noCategory = Icons.label_off_outlined;
  static const currency = Icons.currency_exchange;
  static const date = Icons.calendar_today_outlined;
  static const note = Icons.sticky_note_2_outlined;
  static const split = Icons.call_split;
  static const link = Icons.link;
  static const unlink = Icons.link_off;
  static const trendUp = Icons.arrow_upward;
  static const trendDown = Icons.arrow_downward;
  static const trendFlat = Icons.remove;

  // ── Preferences / account ────────────────────────────────────────────
  static const language = Icons.language_outlined;
  static const font = Icons.text_fields_outlined;
  static const lightMode = Icons.light_mode_outlined;
  static const darkMode = Icons.dark_mode_outlined;
  static const email = Icons.mail_outline;

  // ── Actions ──────────────────────────────────────────────────────────
  static const add = Icons.add;
  static const edit = Icons.edit_outlined;
  static const editBadge = Icons.edit; // small filled pencil on avatars
  static const delete = Icons.delete_outline;
  static const archive = Icons.archive_outlined;
  static const unarchive = Icons.unarchive_outlined;
  static const undo = Icons.undo;
  static const reset = Icons.restart_alt;
  static const refresh = Icons.refresh;
  static const search = Icons.search;
  static const clear = Icons.clear;
  static const sort = Icons.sort;
  static const reorder = Icons.drag_indicator;
  static const share = Icons.ios_share;
  static const copy = Icons.content_copy;
  static const send = Icons.send_outlined;
  static const importSlip = Icons.document_scanner_outlined;
  static const chat = Icons.chat_bubble_outline;
  static const logout = Icons.logout;
  static const iconPicker = Icons.interests_outlined;
  static const colorPicker = Icons.palette_outlined;
  static const eyedropper = Icons.colorize_outlined;
  static const useDefaultIcon = Icons.hide_image_outlined;
  static const pause = Icons.pause_circle_outline;
  static const resume = Icons.play_circle_outline;
  static const stop = Icons.stop_circle_outlined;

  // ── Disclosure / selection ───────────────────────────────────────────
  static const chevronRight = Icons.chevron_right;
  static const chevronLeft = Icons.chevron_left;
  static const dropdown = Icons.arrow_drop_down;
  static const expand = Icons.expand_more;
  static const check = Icons.check;
  static const none = Icons.block;
  static const lock = Icons.lock_outline;

  // ── Visibility ───────────────────────────────────────────────────────
  static const visible = Icons.visibility_outlined;
  static const hidden = Icons.visibility_off_outlined;

  // ── Feedback / states ────────────────────────────────────────────────
  static const success = Icons.check_circle_outline;
  static const error = Icons.error_outline;
  static const warning = Icons.warning_amber_outlined;
  static const info = Icons.info_outline;
  static const offline = Icons.wifi_off_outlined;
  static const serverDown = Icons.cloud_off_outlined;
  static const empty = Icons.inbox_outlined;

  /// Every icon above, grouped, for the `/dev/widgets` icon gallery.
  /// **Add new icons here too** (same file, so it stays in sync).
  static const Map<String, Map<String, IconData>> catalog = {
    'Tabs / chrome': {
      'dashboard': dashboard,
      'dashboardActive': dashboardActive,
      'transactions': transactions,
      'transactionsActive': transactionsActive,
      'wallet': wallet,
      'walletActive': walletActive,
      'more': more,
      'back': back,
      'close': close,
      'notifications': notifications,
      'pending': pending,
      'settings': settings,
      'markAllRead': markAllRead,
      'profile': profile,
    },
    'Features': {
      'category': category,
      'tag': tag,
      'contact': contact,
      'project': project,
      'debt': debt,
      'budget': budget,
      'savingGoal': savingGoal,
      'scheduled': scheduled,
      'member': member,
      'inviteMember': inviteMember,
      'addContact': addContact,
      'addDebt': addDebt,
      'settle': settle,
      'history': history,
    },
    'Money / accounts': {
      'bank': bank,
      'cash': cash,
      'eWallet': eWallet,
      'creditCard': creditCard,
      'accountNumber': accountNumber,
      'payLater': payLater,
      'income': income,
      'expense': expense,
      'transfer': transfer,
      'noWallet': noWallet,
      'noCategory': noCategory,
      'currency': currency,
      'date': date,
      'note': note,
      'split': split,
      'link': link,
      'unlink': unlink,
      'trendUp': trendUp,
      'trendDown': trendDown,
      'trendFlat': trendFlat,
    },
    'Preferences / account': {
      'language': language,
      'font': font,
      'lightMode': lightMode,
      'darkMode': darkMode,
      'email': email,
    },
    'Actions': {
      'add': add,
      'edit': edit,
      'editBadge': editBadge,
      'delete': delete,
      'archive': archive,
      'unarchive': unarchive,
      'undo': undo,
      'reset': reset,
      'refresh': refresh,
      'search': search,
      'clear': clear,
      'sort': sort,
      'reorder': reorder,
      'share': share,
      'copy': copy,
      'send': send,
      'importSlip': importSlip,
      'chat': chat,
      'logout': logout,
      'iconPicker': iconPicker,
      'colorPicker': colorPicker,
      'eyedropper': eyedropper,
      'useDefaultIcon': useDefaultIcon,
      'pause': pause,
      'resume': resume,
      'stop': stop,
    },
    'Disclosure / selection': {
      'chevronRight': chevronRight,
      'chevronLeft': chevronLeft,
      'dropdown': dropdown,
      'expand': expand,
      'check': check,
      'none': none,
      'lock': lock,
      'visible': visible,
      'hidden': hidden,
    },
    'Feedback / states': {
      'success': success,
      'error': error,
      'warning': warning,
      'info': info,
      'offline': offline,
      'serverDown': serverDown,
      'empty': empty,
    },
  };
}
