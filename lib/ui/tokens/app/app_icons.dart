import 'package:flutter/material.dart';

import '../pp_forge_icons.dart';

abstract final class AppIcons {
  static const dashboard = Icons.dashboard_outlined;
  static const dashboardActive = Icons.dashboard;
  static const transactions = Icons.list_alt_outlined;
  static const transactionsActive = Icons.list_alt;
  static const wallet = PpForgeIcons.wallet;
  static const walletActive = Icons.account_balance_wallet;
  static const more = PpForgeIcons.more;
  static const back = PpForgeIcons.back;
  static const arrowForward = PpForgeIcons.arrowForward;
  static const close = PpForgeIcons.close;
  static const notifications = Icons.notifications_outlined;
  static const pending = Icons.move_to_inbox_outlined;

  /// Into my books (ลงบัญชี / จดเป็นหนี้).
  static const bookIn = Icons.save_alt;
  static const settings = Icons.settings_outlined;
  static const markAllRead = Icons.done_all;
  static const profile = Icons.person_outline;

  static const category = PpForgeIcons.category;
  static const tag = PpForgeIcons.tag;
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
  static const settle = PpForgeIcons.settle;
  static const history = PpForgeIcons.history;

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
  static const date = PpForgeIcons.date;
  static const note = PpForgeIcons.note;
  static const split = PpForgeIcons.split;

  /// A row's mark for a shared bill, with the head count beside it.
  static const shared = Icons.group_outlined;

  static const auto = PpForgeIcons.auto;
  static const link = PpForgeIcons.link;
  static const unlink = PpForgeIcons.unlink;
  static const trendUp = PpForgeIcons.trendUp;
  static const trendDown = PpForgeIcons.trendDown;
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
  static const flowIn = PpForgeIcons.flowIn;
  static const flowOut = PpForgeIcons.flowOut;

  static const language = PpForgeIcons.language;
  static const font = Icons.text_fields_outlined;
  static const lightMode = PpForgeIcons.lightMode;
  static const darkMode = PpForgeIcons.darkMode;
  static const systemMode = PpForgeIcons.systemMode;
  static const email = Icons.mail_outline;

  /// The theme-mode setting (light / dark / system).
  static const themeMode = Icons.contrast;

  /// The red / green money colour setting.
  static const moneyColor = Icons.water_drop_outlined;

  /// Change password (a key; the lock marks a locked value).
  static const password = Icons.key_outlined;
  static const phone = Icons.phone_outlined;

  static const add = PpForgeIcons.add;
  static const edit = PpForgeIcons.edit;
  static const editBadge = PpForgeIcons.editBadge;
  static const delete = PpForgeIcons.delete;
  static const archive = PpForgeIcons.archive;
  static const unarchive = Icons.unarchive_outlined;
  static const undo = PpForgeIcons.undo;
  static const reset = PpForgeIcons.reset;
  static const refresh = PpForgeIcons.refresh;
  static const search = PpForgeIcons.search;
  static const clear = PpForgeIcons.clear;
  static const sort = PpForgeIcons.sort;

  /// Auto sync (settings › ซิงก์อัตโนมัติ, the event / person switches).
  static const sync = Icons.sync;

  /// Filters and sorting (settings › ตัวกรองและการเรียง).
  static const filter = Icons.tune;
  static const reorder = PpForgeIcons.reorder;
  static const share = PpForgeIcons.share;
  static const copy = Icons.content_copy;
  static const download = Icons.file_download_outlined;
  static const send = PpForgeIcons.send;
  static const today = PpForgeIcons.today;
  static const photo = PpForgeIcons.photo;
  static const skip = PpForgeIcons.skip;
  static const importSlip = Icons.document_scanner_outlined;
  static const chat = PpForgeIcons.chat;
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

  static const chevronRight = PpForgeIcons.chevronRight;
  static const chevronLeft = PpForgeIcons.chevronLeft;
  static const dropdown = PpForgeIcons.dropdown;
  static const expand = PpForgeIcons.expand;
  static const collapse = PpForgeIcons.collapse;
  static const check = PpForgeIcons.check;
  static const save = PpForgeIcons.save;
  static const none = Icons.block;
  static const lock = PpForgeIcons.lock;

  static const visible = PpForgeIcons.visible;
  static const hidden = PpForgeIcons.hidden;

  static const success = PpForgeIcons.success;
  static const error = PpForgeIcons.error;
  static const warning = PpForgeIcons.warning;
  static const info = PpForgeIcons.info;
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
      'themeMode': themeMode,
      'email': email,
      'password': password,
      'moneyColor': moneyColor,
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
      'today': today,
      'photo': photo,
      'skip': skip,
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
