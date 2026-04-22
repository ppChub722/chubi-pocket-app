// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'chubiPocket';

  @override
  String get previewTitle => 'ตัวอย่างคอร์';

  @override
  String get sectionTheme => 'ธีม';

  @override
  String get sectionMode => 'โหมด';

  @override
  String get sectionLanguage => 'ภาษา';

  @override
  String get sectionFont => 'ฟอนต์';

  @override
  String get sectionCurrentSelection => 'การเลือกปัจจุบัน';

  @override
  String get sectionTypographySamples => 'ตัวอย่างตัวอักษร';

  @override
  String get sectionSemanticColors => 'สีเชิงความหมาย';

  @override
  String get sectionFormatters => 'รูปแบบการแสดงผล';

  @override
  String get sectionControls => 'ปุ่ม';

  @override
  String get sectionInput => 'ช่องกรอก';

  @override
  String get sectionCard => 'การ์ด';

  @override
  String get modeLight => 'สว่าง';

  @override
  String get modeDark => 'มืด';

  @override
  String get modeSystem => 'ระบบ';

  @override
  String fontsAvailableFor(int count, String lang) {
    return 'มี $count รายการสำหรับ \"$lang\"';
  }

  @override
  String get amountLabel => 'จำนวนเงิน';

  @override
  String get amountHint => '0.00';

  @override
  String get monthlyBalance => 'ยอดคงเหลือรายเดือน';
}
