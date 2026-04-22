// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'chubiPocket';

  @override
  String get previewTitle => 'Core Preview';

  @override
  String get sectionTheme => 'Theme';

  @override
  String get sectionMode => 'Mode';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionFont => 'Font';

  @override
  String get sectionCurrentSelection => 'Current selection';

  @override
  String get sectionTypographySamples => 'Typography samples';

  @override
  String get sectionSemanticColors => 'Semantic colors';

  @override
  String get sectionFormatters => 'Formatters';

  @override
  String get sectionControls => 'Controls';

  @override
  String get sectionInput => 'Input';

  @override
  String get sectionCard => 'Card';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get modeSystem => 'System';

  @override
  String fontsAvailableFor(int count, String lang) {
    return '$count available for \"$lang\"';
  }

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountHint => '0.00';

  @override
  String get monthlyBalance => 'Monthly balance';
}
