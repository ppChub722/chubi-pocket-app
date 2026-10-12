/// The app's shared UI kit — one import for every reusable widget.
///
/// ```dart
/// import '../../../../shared/widgets/ui.dart';
/// ```
///
/// Browse them live at `/dev/widgets` (Dev hub → Widget gallery).
library;

// Buttons
export 'atoms/app_avatar.dart';
export 'atoms/app_button.dart';
export 'atoms/app_card.dart';
export 'atoms/corner_badge.dart';
export 'atoms/app_icon.dart';
export 'atoms/app_spinner.dart';
export 'tokens/avatar_metrics.dart';
export 'tokens/icon_size.dart';
export 'atoms/app_icon_button.dart';
export 'atoms/input_formatters.dart';
export 'atoms/count_badge.dart';
export 'organisms/app_date_picker.dart';
export 'organisms/app_date_range_picker.dart';
export 'organisms/period_picker_sheet.dart';
export 'organisms/description_picker_sheet.dart';
export 'organisms/collapsible_section.dart';
export 'atoms/app_avatar_button.dart';
export 'atoms/bulk_delete_button.dart';

// Inputs
export 'molecules/amount_input.dart';
export 'molecules/chat_dial.dart';
export 'atoms/app_divider.dart';
export 'atoms/app_input.dart';
export 'atoms/app_input_type.dart';
export 'atoms/app_switch.dart';
export 'atoms/app_text.dart';
export 'atoms/ui_config.dart';
export 'templates/form_sheet.dart';
export 'domain/l10n/app_ui_config.dart';
export 'tokens/typography.dart';
export 'domain/money/currency_tile.dart';
export 'molecules/month_picker.dart';
export 'molecules/stepper_pill.dart';
export 'molecules/pick_card.dart';
export 'molecules/split_row.dart';
export 'molecules/select_card_group.dart';
export 'atoms/select_check.dart';
export 'molecules/theme_mode_chips.dart';

// Charts
export 'organisms/charts/chart_palette.dart';
export 'organisms/charts/donut_chart.dart';
export 'organisms/charts/paired_bar_chart.dart';

// Chips & pills
export 'atoms/app_chip.dart';
export 'molecules/chip_row.dart';
export 'molecules/filter_bar.dart';
export 'molecules/pinned_tab_bar.dart';
export 'molecules/selection_toolbar.dart';
export 'molecules/centered_form_body.dart';
export 'molecules/card_grid.dart';
export 'molecules/segmented_bar.dart';
export 'tokens/chip_size.dart';
export 'atoms/app_badge.dart';
export 'tokens/tone.dart';

// Layout
export 'atoms/add_tile.dart';
export 'molecules/app_tab_bar.dart';
export 'molecules/compact_hero_bar.dart';
export 'molecules/danger_row.dart';
export 'molecules/detail_meta.dart';
export 'molecules/detail_rows.dart';
export 'organisms/header_card.dart';
export 'molecules/list_row.dart';
export 'molecules/hero_shell.dart';
export 'molecules/hero_style.dart';
export 'molecules/hero_description.dart';
export 'atoms/locked_in_edit.dart';
export 'organisms/manage_section.dart';
export 'molecules/pinned_bar.dart';
export 'molecules/section_header.dart';
export 'molecules/selectable_frame.dart';
export 'atoms/icon_tile.dart';
export 'molecules/mode_action_bar.dart';
export 'organisms/reorder/reorder.dart';

// Feedback
export 'organisms/async_state_view.dart';
export 'organisms/page_skeletons.dart';
export 'molecules/empty_view.dart';
export 'molecules/error_view.dart';
export 'molecules/app_snackbar.dart';
export 'molecules/choice_dialog.dart';
export 'molecules/confirm_dialog.dart';
export 'molecules/error_snackbar.dart';
export 'molecules/app_message.dart';
export 'molecules/action_bar.dart';
export 'molecules/chip_path.dart';
export 'molecules/progress_row.dart';
export 'organisms/saving_overlay.dart';
export 'molecules/loading_view.dart';
export 'organisms/pull_to_refresh.dart';
export 'atoms/skeletons.dart';

// Popovers (short lists) & sheets (long / searchable lists)
export 'molecules/option_menu.dart';
export 'organisms/action_sheet.dart';
export 'organisms/app_sheet.dart';
export 'molecules/day_of_month_picker.dart';
export 'organisms/option_sheet.dart';
export 'organisms/picker_sheet.dart';
export 'organisms/side_sheet.dart';

// Data display
export 'domain/money/money_list_tile.dart';
export 'domain/money/money_text.dart';
export 'domain/money/settle_sheet.dart';
export 'domain/people/people.dart';
export 'domain/people/person_mark.dart';
export 'molecules/summary_stats.dart';
export 'domain/transactions/entry_card.dart';
export 'domain/transactions/entry_card_skeleton.dart';
export 'domain/transactions/tx_hero_card.dart';
export 'domain/transactions/quick_create_sheet.dart';
export 'domain/transactions/tx_row.dart';
export 'domain/transactions/tx_filter_sheet.dart';
export 'domain/money/account_picker_sheet.dart';
export 'domain/transactions/event_target_sheet.dart';
export 'domain/brand/brand_logo.dart';
export 'domain/brand/bank_brand.dart';
export 'domain/people/wire_names_sheet.dart';
export 'domain/people/contact_picker_sheet.dart';
export 'domain/pickers/tag_picker_sheet.dart';
export 'domain/pickers/category_picker_sheet.dart';
export 'domain/people/wallet_invite_sheet.dart';
export 'domain/money/identifier_kind_sheet.dart';
export 'domain/brand/bank_picker_sheet.dart';
export 'domain/money/adjust_balance_sheet.dart';
export 'atoms/editable_circle.dart';
export 'debug/secret_tap.dart';
export 'atoms/user_avatar.dart';

// Tokens, icons and mixins features reach for (absorbed from direct imports).
export 'atoms/skeleton_box.dart';
export 'domain/feedback/offline_banner.dart';
export 'domain/icons/color_token.dart';
export 'domain/icons/icon_code.dart';
export 'domain/icons/icon_code_widget.dart';
export 'domain/icons/icon_display.dart';
export 'domain/icons/icon_maker_sheet.dart';
export 'domain/icons/icon_registry.dart';
export 'domain/icons/icon_shape.dart';
export 'domain/icons/icon_type.dart';
export 'domain/people/user_profile_preview.dart';
export 'organisms/reorder/reorder_outline.dart';
export 'templates/dashboard_page_body.dart';
export 'templates/detail_page_body.dart';
export 'templates/edit_mode_scope.dart';
export 'templates/edit_mode_mixin.dart';
export 'templates/list_page_body.dart';
export 'templates/list_toolbar.dart';
export 'tokens/app/app_colors.dart';
export 'tokens/app/app_icons.dart';
export 'tokens/app/currencies.dart';
export 'tokens/app/fonts/font_registry.dart';
export 'tokens/app/module_colors.dart';
export 'tokens/app/text_limits.dart';
export 'tokens/app/theme/app_theme.dart';
export 'tokens/app/theme/theme_registry.dart';
export 'tokens/app_durations.dart';
export 'tokens/app_radius.dart';
export 'tokens/app_spacing.dart';
export 'domain/projects/project_member_avatar.dart';
export 'domain/projects/member_pick_card.dart';
export 'domain/notifications/notification_tile.dart';
export 'domain/projects/event_resolve_sheet.dart';
export 'domain/projects/add_member_sheet.dart';
