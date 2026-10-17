import 'app_font.dart';

class FontRegistry {
  const FontRegistry._();

  static const AppFont inter = AppFont(
    id: 'Inter',
    family: 'Inter',
    supportedLanguages: {'en'},
    previewSample: 'The quick brown fox 1,234',
  );

  static const AppFont nunito = AppFont(
    id: 'Nunito',
    family: 'Nunito',
    supportedLanguages: {'en'},
    previewSample: 'The quick brown fox 1,234',
  );

  static const AppFont poppins = AppFont(
    id: 'Poppins',
    family: 'Poppins',
    supportedLanguages: {'en'},
    previewSample: 'The quick brown fox 1,234',
  );

  static const AppFont ibmPlexSansThai = AppFont(
    id: 'IBM Plex Sans Thai',
    family: 'IBM Plex Sans Thai',
    supportedLanguages: {'th'},
    previewSample: 'สวัสดี นักกีฬา ชมพู่ ๑,๒๓๔',
  );

  static const AppFont mitr = AppFont(
    id: 'Mitr',
    family: 'Mitr',
    supportedLanguages: {'th'},
    previewSample: 'สวัสดี นักกีฬา ชมพู่ ๑,๒๓๔',
  );

  static const List<AppFont> all = [
    inter,
    nunito,
    poppins,
    ibmPlexSansThai,
    mitr,
  ];

  static const Map<String, String> defaultsByLanguage = {
    'en': 'Inter',
    'th': 'IBM Plex Sans Thai',
  };

  static String defaultIdFor(String languageCode) =>
      defaultsByLanguage[languageCode] ?? all.first.id;

  static AppFont byId(String id) {
    return all.firstWhere((f) => f.id == id, orElse: () => all.first);
  }

  static List<AppFont> availableFor(String languageCode) =>
      all.where((f) => f.supports(languageCode)).toList();
}
