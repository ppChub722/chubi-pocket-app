/// chubiPocket's names for the ppForge kit. The kit's pieces are `PpForge*`
/// (owner 2026-10-16: a host app names its own layer on top); this app keeps
/// the `App*` names it was written with, as plain aliases — same types, so
/// `extension<AppColors>()`, `AppSpacing.md`, `AppAvatar.icon(…)` and
/// patterns all keep working. New code may use either name.
library;

import 'package:pp_forge/pp_forge.dart';

// Tokens
typedef AppColors = PpForgeColors;
typedef AppDurations = PpForgeDurations;
typedef AppFont = PpForgeFont;
typedef AppIconSize = PpForgeIconSize;
typedef AppIcons = PpForgeIcons;
typedef AppPageTransitionsBuilder = PpForgePageTransitionsBuilder;
typedef AppRadius = PpForgeRadius;
typedef AppSpacing = PpForgeSpacing;
typedef AppTextRole = PpForgeTextRole;
typedef AppTheme = PpForgeTheme;
typedef AppTypography = PpForgeTypography;

// Atoms
typedef AppAvatar = PpForgeAvatar;
typedef AppAvatarButton = PpForgeAvatarButton;
typedef AppBadge = PpForgeBadge;
typedef AppButton = PpForgeButton;
typedef AppButtonSize = PpForgeButtonSize;
typedef AppButtonVariant = PpForgeButtonVariant;
typedef AppCard = PpForgeCard;
typedef AppCardStyle = PpForgeCardStyle;
typedef AppChip = PpForgeChip;
typedef AppChipTone = PpForgeChipTone;
typedef AppChipTrailing = PpForgeChipTrailing;
typedef AppDivider = PpForgeDivider;
typedef AppIcon = PpForgeIcon;
typedef AppIconButton = PpForgeIconButton;
typedef AppInput = PpForgeInput;
typedef AppInputLabelPlacement = PpForgeInputLabelPlacement;
typedef AppInputSize = PpForgeInputSize;
typedef AppInputType = PpForgeInputType;
typedef AppSpinner = PpForgeSpinner;
typedef AppSpinnerSize = PpForgeSpinnerSize;
typedef AppSwitch = PpForgeSwitch;
typedef AppText = PpForgeText;
typedef UiConfig = PpForgeConfig;
typedef UiErrorInfo = PpForgeErrorInfo;
typedef UiErrors = PpForgeErrors;
typedef UiStrings = PpForgeStrings;

// Molecules
typedef AppMessage = PpForgeMessage;
typedef AppMessageAction = PpForgeMessageAction;
typedef AppTab<T> = PpForgeTab<T>;
typedef AppTabBar<T> = PpForgeTabBar<T>;
typedef AppTabPager<T> = PpForgeTabPager<T>;
const showAppMessage = showPpForgeMessage;
const showAppMessageOn = showPpForgeMessageOn;
const showAppSnackBar = showPpForgeSnackBar;
const showAppSnackBarOn = showPpForgeSnackBarOn;

// Organisms
typedef AppDateCleared = PpForgeDateCleared;
typedef AppDatePicked = PpForgeDatePicked;
typedef AppDatePickerSheet = PpForgeDatePickerSheet;
typedef AppDateRangePickerSheet = PpForgeDateRangePickerSheet;
typedef AppDateRangePreset = PpForgeDateRangePreset;
typedef AppDateResult = PpForgeDateResult;
typedef AppSheetScaffold = PpForgeSheetScaffold;
const showAppDatePicker = showPpForgeDatePicker;
const showAppDateRangePicker = showPpForgeDateRangePicker;
const showAppSheet = showPpForgeSheet;
const showAppSheetCustom = showPpForgeSheetCustom;
