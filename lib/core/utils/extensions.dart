import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  AppColors get appColors => theme.extension<AppColors>()!;

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  EdgeInsets get viewInsets => mq.viewInsets;
  EdgeInsets get viewPadding => mq.viewPadding;

  bool get isDark => theme.brightness == Brightness.dark;
}
