import 'app_theme.dart';
import 'themes/mint_theme.dart';
import 'themes/sweet_theme.dart';

/// The themes the app offers. ppForge ships [builtIn] (Mint, Sweet); a host
/// app swaps in its own list — or the built-ins with its own extensions
/// ([PpForgeTheme.withExtensions]) — once, before `runApp`, with [configure].
class ThemeRegistry {
  const ThemeRegistry._();

  static final List<PpForgeTheme> builtIn = [mintTheme, sweetTheme];

  static List<PpForgeTheme> _all = builtIn;
  static String _defaultThemeId = 'mint';

  static List<PpForgeTheme> get all => _all;

  static String get defaultThemeId => _defaultThemeId;

  /// Replaces the offered themes; [defaultThemeId] must be one of them
  /// (default: the first).
  static void configure(List<PpForgeTheme> themes, {String? defaultThemeId}) {
    assert(themes.isNotEmpty, 'ThemeRegistry needs at least one theme');
    final id = defaultThemeId ?? themes.first.id;
    assert(
      themes.any((t) => t.id == id),
      'default theme "$id" is not in the list',
    );
    _all = List.unmodifiable(themes);
    _defaultThemeId = id;
  }

  static PpForgeTheme byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.firstWhere((t) => t.id == defaultThemeId),
    );
  }
}
