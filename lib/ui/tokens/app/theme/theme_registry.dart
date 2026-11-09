import 'app_theme.dart';
import 'themes/mint_theme.dart';
import 'themes/sweet_theme.dart';

class ThemeRegistry {
  const ThemeRegistry._();

  static String _defaultThemeId = 'mint';
  static List<AppTheme> _all = [mintTheme, sweetTheme];

  static String get defaultThemeId => _defaultThemeId;

  static List<AppTheme> get all => _all;

  /// Replaces the built-in Mint / Sweet set — a host app registers its own
  /// themes (or the built-ins plus its [AppTheme.withExtensions]) once at
  /// start-up.
  static void configure(List<AppTheme> themes, {String? defaultThemeId}) {
    assert(themes.isNotEmpty);
    _all = List.unmodifiable(themes);
    _defaultThemeId = defaultThemeId ?? themes.first.id;
  }

  static AppTheme byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.firstWhere((t) => t.id == defaultThemeId),
    );
  }
}
