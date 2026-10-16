/// THE GATE — chubiPocket's one import for UI: the ppForge kit, the app's
/// `App*` names for it, and the app's own pieces (money, people, icons…).
///
/// ```dart
/// import '../../../../ui/ui.dart';
/// ```
///
/// Browse them live at `/dev/ui` (the app hub).
library;

// The kit (tokens → templates, icons) — ../pp-forge.
export 'package:pp_forge/pp_forge.dart';

// chubiPocket's App* names for the PpForge* pieces.
export 'app_aliases.dart';

// The app's own pieces.
export 'debug/secret_tap.dart';
export 'domain/brand/bank_brand.dart';
export 'domain/brand/bank_picker_sheet.dart';
export 'domain/brand/brand_header.dart';
export 'domain/brand/brand_logo.dart';
export 'domain/events/event_bill_row.dart';
export 'domain/events/event_card.dart';
export 'domain/events/position_row.dart';
export 'domain/feedback/offline_banner.dart';
export 'domain/icons/icon_type.dart';
export 'domain/l10n/app_ui_config.dart';
export 'domain/money/account_multi_picker_sheet.dart';
export 'domain/money/account_picker_sheet.dart';
export 'domain/money/adjust_balance_sheet.dart';
export 'domain/money/currencies.dart';
export 'domain/money/currency_tile.dart';
export 'domain/money/debt_summary_card.dart';
export 'domain/money/identifier_kind_sheet.dart';
export 'domain/money/ledger_row.dart';
export 'domain/money/money_list_tile.dart';
export 'domain/money/money_text.dart';
export 'domain/money/net_balance.dart';
export 'domain/money/settle_sheet.dart';
export 'domain/money/summary_stats.dart';
export 'domain/money/wallet_value_chip.dart';
export 'domain/notifications/notification_tile.dart';
export 'domain/people/contact_picker_sheet.dart';
export 'domain/people/people.dart';
export 'domain/people/person_balance_row.dart';
export 'domain/people/person_mark.dart';
export 'domain/people/person_row.dart';
export 'domain/people/user_avatar.dart';
export 'domain/people/user_profile_preview.dart';
export 'domain/people/wallet_invite_sheet.dart';
export 'domain/people/wire_names_sheet.dart';
export 'domain/pickers/category_multi_picker_sheet.dart';
export 'domain/pickers/category_picker_sheet.dart';
export 'domain/pickers/tag_picker_sheet.dart';
export 'domain/progress/breakdown_row.dart';
export 'domain/progress/progress_card.dart';
export 'domain/progress/progress_hero_footer.dart';
export 'domain/progress/progress_summary.dart';
export 'domain/progress/progress_tone.dart';
export 'domain/progress/source_chips.dart';
export 'domain/projects/add_member_sheet.dart';
export 'domain/projects/event_resolve_sheet.dart';
export 'domain/projects/member_pick_card.dart';
export 'domain/projects/project_member_avatar.dart';
export 'domain/recurring/due_text.dart';
export 'domain/recurring/occurrence_state_chip.dart';
export 'domain/recurring/recurrence_rule.dart';
export 'domain/recurring/recurrence_sheet.dart';
export 'domain/recurring/recurrence_text.dart';
export 'domain/saving/close_goal_dialog.dart';
export 'domain/saving/saving_move_sheet.dart';
export 'domain/saving/saving_tx_row.dart';
export 'domain/tokens/chubi_themes.dart';
export 'domain/tokens/module_colors.dart';
export 'domain/tokens/quick_create_mode.dart';
export 'domain/tokens/text_limits.dart';
export 'domain/transactions/entry_card.dart';
export 'domain/transactions/entry_card_skeleton.dart';
export 'domain/transactions/event_target_sheet.dart';
export 'domain/transactions/quick_create_button.dart';
export 'domain/transactions/quick_create_mode_chips.dart';
export 'domain/transactions/quick_create_sheet.dart';
export 'domain/transactions/split_event_section.dart';
export 'domain/transactions/tx_filter_sheet.dart';
export 'domain/transactions/tx_hero_card.dart';
export 'domain/transactions/tx_row.dart';
