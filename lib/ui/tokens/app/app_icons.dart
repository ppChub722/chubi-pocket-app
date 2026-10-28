import 'package:flutter/material.dart';

abstract final class AppIcons {
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

  /// Into my books (ลงบัญชี / จดเป็นหนี้).
  static const bookIn = Icons.save_alt;
  static const settings = Icons.settings_outlined;
  static const markAllRead = Icons.done_all;
  static const profile = Icons.person_outline;

  static const category = Icons.category_outlined;
  static const tag = Icons.sell_outlined;
  static const amount = Icons.payments_outlined;
  static const contact = Icons.contacts_outlined;
  static const project = Icons.groups_outlined;
  static const debt = Icons.handshake_outlined;
  static const budget = Icons.donut_large;
  static const savingGoal = Icons.flag_outlined;
  // Saving txs (goals v2): a record of its own, never a real tx.
  static const savingDeposit = Icons.savings; // ออม
  static const quickSaving = Icons.inventory_2_outlined;
  static const savingWithdraw = Icons.keyboard_return; // ถอนออม
  static const savingAllocate = Icons.shuffle; // จัดสรร
  // A saving row's money in / out (a pair, unlike the pig).
  static const savingIn = Icons.input;
  static const savingOut = Icons.output;
  static const goalClose = Icons.flag; // ปิดเป้าหมาย
  static const scheduled = Icons.schedule_outlined;

  static const recurring = Icons.repeat;
  static const progress = Icons.timelapse;
  static const subscription = Icons.subscriptions_outlined;
  static const member = Icons.person_outline;
  static const inviteMember = Icons.person_add_alt_1_outlined;
  static const addContact = Icons.person_add_outlined;
  static const addDebt = Icons.note_add_outlined;
  static const settle = Icons.price_check;
  static const history = Icons.history;

  static const bank = Icons.account_balance_outlined;
  static const cash = Icons.payments_outlined;
  static const eWallet = Icons.qr_code_2_outlined;
  static const creditCard = Icons.credit_card_outlined;
  static const payLater = Icons.access_time_outlined;
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

  /// A row's mark for a shared bill, with the head count beside it.
  static const shared = Icons.group_outlined;

  static const auto = Icons.auto_mode;
  static const link = Icons.link;
  static const unlink = Icons.link_off;
  static const trendUp = Icons.arrow_upward;
  static const trendDown = Icons.arrow_downward;
  static const trendFlat = Icons.remove;

  // Hero fact labels (HeroFact.icon).
  static const savings = Icons.savings_outlined;
  static const receipt = Icons.receipt_long_outlined;
  static const trendingUp = Icons.trending_up;
  static const pie = Icons.pie_chart_outline;
  static const layers = Icons.layers_outlined;
  static const coin = Icons.monetization_on_outlined;
  static const hourglass = Icons.hourglass_empty;
  static const target = Icons.track_changes;

  // A month's money in / out (HeroFlowRow).
  static const flowIn = Icons.south_west;
  static const flowOut = Icons.north_east;

  static const language = Icons.language_outlined;
  static const font = Icons.text_fields_outlined;
  static const lightMode = Icons.light_mode_outlined;
  static const darkMode = Icons.dark_mode_outlined;
  static const systemMode = Icons.smartphone_outlined;
  static const email = Icons.mail_outline;
  static const phone = Icons.phone_outlined;

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

  /// Auto sync (settings › ซิงก์อัตโนมัติ, the event / person switches).
  static const sync = Icons.sync;

  /// Filters and sorting (settings › ตัวกรองและการเรียง).
  static const filter = Icons.tune;
  static const reorder = Icons.drag_indicator;
  static const share = Icons.ios_share;
  static const copy = Icons.content_copy;
  static const download = Icons.file_download_outlined;
  static const send = Icons.send_outlined;
  static const importSlip = Icons.document_scanner_outlined;
  static const chat = Icons.chat_bubble_outline;
  static const logout = Icons.logout;
  static const iconPicker = Icons.interests_outlined;
  static const colorPicker = Icons.palette_outlined;

  static const moneyStyle = Icons.exposure_outlined;

  static const moneyDecimals = Icons.pin_outlined;
  static const eyedropper = Icons.colorize_outlined;
  static const useDefaultIcon = Icons.hide_image_outlined;
  static const pause = Icons.pause_circle_outline;
  static const resume = Icons.play_circle_outline;
  static const stop = Icons.stop_circle_outlined;

  static const chevronRight = Icons.chevron_right;
  static const chevronLeft = Icons.chevron_left;
  static const dropdown = Icons.arrow_drop_down;
  static const expand = Icons.expand_more;
  static const collapse = Icons.expand_less;
  static const check = Icons.check;
  static const save = Icons.save_outlined;
  static const none = Icons.block;
  static const lock = Icons.lock_outline;

  static const visible = Icons.visibility_outlined;
  static const hidden = Icons.visibility_off_outlined;

  static const success = Icons.check_circle_outline;
  static const error = Icons.error_outline;
  static const warning = Icons.warning_amber_outlined;
  static const info = Icons.info_outline;
  static const offline = Icons.wifi_off_outlined;
  static const serverDown = Icons.cloud_off_outlined;
  static const empty = Icons.inbox_outlined;

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
      'amount': amount,
      'contact': contact,
      'project': project,
      'debt': debt,
      'budget': budget,
      'savingGoal': savingGoal,
      'savingDeposit': savingDeposit,
      'savingWithdraw': savingWithdraw,
      'savingAllocate': savingAllocate,
      'goalClose': goalClose,
      'scheduled': scheduled,
      'recurring': recurring,
      'progress': progress,
      'subscription': subscription,
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
      'shared': shared,
      'auto': auto,
      'link': link,
      'unlink': unlink,
      'trendUp': trendUp,
      'trendDown': trendDown,
      'trendFlat': trendFlat,
    },
    'Hero facts': {
      'savings': savings,
      'receipt': receipt,
      'trendingUp': trendingUp,
      'pie': pie,
      'layers': layers,
      'coin': coin,
      'hourglass': hourglass,
      'target': target,
      'flowIn': flowIn,
      'flowOut': flowOut,
    },
    'Preferences / account': {
      'language': language,
      'font': font,
      'lightMode': lightMode,
      'darkMode': darkMode,
      'systemMode': systemMode,
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
      'collapse': collapse,
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
