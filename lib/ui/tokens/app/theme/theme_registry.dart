import 'app_theme.dart';
import 'themes/mint_theme.dart';
import 'themes/sweet_theme.dart';

class ThemeRegistry {
  const ThemeRegistry._();

  static const String defaultThemeId = 'mint';

  static final List<PpForgeTheme> all = [mintTheme, sweetTheme];

  static PpForgeTheme byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.firstWhere((t) => t.id == defaultThemeId),
    );
  }
}
