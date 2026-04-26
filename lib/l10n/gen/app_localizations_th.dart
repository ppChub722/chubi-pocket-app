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
  String get commonRequired => 'จำเป็น';

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get commonSave => 'บันทึก';

  @override
  String get commonRetry => 'ลองอีกครั้ง';

  @override
  String get commonRemove => 'ลบ';

  @override
  String get commonOk => 'ตกลง';

  @override
  String get commonBack => 'ย้อนกลับ';

  @override
  String get commonClose => 'ปิด';

  @override
  String get errorNetworkTitle => 'ไม่มีการเชื่อมต่อ';

  @override
  String get errorNetworkMessage => 'ตรวจสอบอินเทอร์เน็ตของคุณแล้วลองใหม่';

  @override
  String get errorServerTitle => 'เกิดข้อผิดพลาด';

  @override
  String get errorServerMessage => 'เซิร์ฟเวอร์มีปัญหาชั่วคราว กรุณาลองใหม่';

  @override
  String get errorUnknownTitle => 'ข้อผิดพลาดที่ไม่คาดคิด';

  @override
  String get errorUnknownMessage => 'เกิดสิ่งที่ไม่คาดคิด กรุณาลองใหม่';

  @override
  String get errorBannerNoConnection =>
      'ไม่มีการเชื่อมต่อ ตรวจสอบอินเทอร์เน็ตของคุณ';

  @override
  String get errorBannerNoConnectionShort => 'ไม่มีการเชื่อมต่อ ลองใหม่';

  @override
  String get offlineBanner => 'คุณกำลังออฟไลน์';

  @override
  String get authLoginTitle => 'เข้าสู่ระบบ';

  @override
  String get authLoginIdentifierLabel => 'ชื่อผู้ใช้หรืออีเมล';

  @override
  String get authLoginPasswordLabel => 'รหัสผ่าน';

  @override
  String get authLoginSubmit => 'เข้าสู่ระบบ';

  @override
  String get authLoginInvalidCredentials => 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get authLoginGoToRegister => 'ยังไม่มีบัญชี? สมัครสมาชิก';

  @override
  String get authRegisterTitle => 'สร้างบัญชี';

  @override
  String get authRegisterUsernameLabel => 'ชื่อผู้ใช้';

  @override
  String get authRegisterUsernameInvalid =>
      '3–50 ตัวอักษร; ใช้ a–z พิมพ์เล็ก, 0–9, _, -';

  @override
  String get authRegisterDisplayNameLabel => 'ชื่อที่แสดง';

  @override
  String get authRegisterDisplayNameTooLong => 'สูงสุด 100 ตัวอักษร';

  @override
  String get authRegisterEmailLabel => 'อีเมล (ไม่บังคับ)';

  @override
  String get authRegisterPasswordLabel => 'รหัสผ่าน';

  @override
  String get authRegisterPasswordTooShort => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get authRegisterPasswordTooLong => 'สูงสุด 128 ตัวอักษร';

  @override
  String get authRegisterConfirmLabel => 'ยืนยันรหัสผ่าน';

  @override
  String get authRegisterConfirmMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get authRegisterCurrencyLabel => 'สกุลเงิน';

  @override
  String get authRegisterSubmit => 'สร้างบัญชี';

  @override
  String get authRegisterGoToLogin => 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ';

  @override
  String get authRegisterUsernameTaken => 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';

  @override
  String get authRegisterEmailTaken => 'อีเมลนี้ถูกใช้แล้ว';

  @override
  String get authRegisterFixErrors => 'กรุณาแก้ไขข้อผิดพลาดด้านล่าง';

  @override
  String get authRegisterUsernameTakenInline => 'ถูกใช้แล้ว';

  @override
  String get authRegisterEmailTakenInline => 'ถูกใช้แล้ว';

  @override
  String get homeEmptyTitle => 'ยังไม่มีรายการ';

  @override
  String get homeEmptyMessage =>
      'หน้าหลักเฟส 0 — โมดูลฟีเจอร์ (บัญชี, รายการ, งบประมาณ) จะมาในเฟส 1';

  @override
  String get homeSettingsTooltip => 'การตั้งค่า';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsSectionAccount => 'บัญชี';

  @override
  String get settingsSectionPreferences => 'การตั้งค่าส่วนตัว';

  @override
  String get settingsSectionAbout => 'เกี่ยวกับ';

  @override
  String get settingsChangePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get settingsDefaultCurrency => 'สกุลเงินเริ่มต้น';

  @override
  String get settingsTheme => 'ธีม';

  @override
  String get settingsAppearance => 'การแสดงผล';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsFont => 'ฟอนต์';

  @override
  String get settingsAppVersion => 'เวอร์ชันแอป';

  @override
  String get settingsAppVersionValue => 'เฟส 0 (1.0.0+1)';

  @override
  String get settingsLogout => 'ออกจากระบบ';

  @override
  String get settingsLogoutDialogTitle => 'ออกจากระบบ ChubiPocket?';

  @override
  String get settingsLogoutDialogBody => 'คุณจะถูกนำกลับไปยังหน้าเข้าสู่ระบบ';

  @override
  String get editProfileTitle => 'แก้ไขโปรไฟล์';

  @override
  String get editProfileDisplayNameLabel => 'ชื่อที่แสดง';

  @override
  String get editProfileCurrencyLabel => 'สกุลเงินเริ่มต้น';

  @override
  String get editProfileCurrencyHelper =>
      'ใช้เป็นค่าเริ่มต้นสำหรับรายการใหม่ รายการเดิมยังใช้สกุลเงินเดิม';

  @override
  String get editProfileAvatarUrlLabel => 'URL รูปโปรไฟล์ (ไม่บังคับ)';

  @override
  String get editProfileAvatarUrlHelper =>
      'เฟส 0: วาง URL หรือเว้นว่างเพื่อใช้ตัวอักษรย่อ';

  @override
  String get editProfileUsernameLabel => 'ชื่อผู้ใช้';

  @override
  String get editProfileEmailLabel => 'อีเมล';

  @override
  String get editProfileReadOnlyHelper => 'ไม่สามารถเปลี่ยนได้ในเวอร์ชันนี้';

  @override
  String get editProfileEmailNone => '—';

  @override
  String get editProfileSnackSuccess => 'อัปเดตโปรไฟล์แล้ว';

  @override
  String get editProfileDiscardTitle => 'ยกเลิกการเปลี่ยนแปลง?';

  @override
  String get editProfileDiscardBody => 'การแก้ไขของคุณจะหายไป';

  @override
  String get editProfileDiscardKeep => 'แก้ไขต่อ';

  @override
  String get editProfileDiscardConfirm => 'ยกเลิก';

  @override
  String get changePasswordTitle => 'เปลี่ยนรหัสผ่าน';

  @override
  String get changePasswordCurrentLabel => 'รหัสผ่านปัจจุบัน';

  @override
  String get changePasswordNewLabel => 'รหัสผ่านใหม่';

  @override
  String get changePasswordNewHelper => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get changePasswordConfirmLabel => 'ยืนยันรหัสผ่านใหม่';

  @override
  String get changePasswordCurrentWrong => 'รหัสผ่านปัจจุบันไม่ถูกต้อง';

  @override
  String get changePasswordNewMustDiffer => 'ต้องต่างจากรหัสผ่านปัจจุบัน';

  @override
  String get changePasswordConfirmMismatch => 'ไม่ตรงกับรหัสผ่านใหม่';

  @override
  String get changePasswordSubmit => 'อัปเดตรหัสผ่าน';

  @override
  String get changePasswordSnackSuccess => 'อัปเดตรหัสผ่านแล้ว';

  @override
  String get avatarPickerStyleLabel => 'สไตล์';

  @override
  String get avatarPickerColorLabel => 'สี';

  @override
  String get avatarPickerUseThis => 'ใช้รูปนี้';

  @override
  String get avatarPickerUploadDisabled => 'อัปโหลด (เฟส 2)';

  @override
  String get avatarPickerCropDisabled => 'ครอป (เฟส 2)';

  @override
  String get avatarPresetInitials => 'ตัวอักษรย่อ';

  @override
  String get avatarPresetMale => 'ชาย';

  @override
  String get avatarPresetFemale => 'หญิง';

  @override
  String get avatarPresetChubby => 'อ้วนน่ารัก';

  @override
  String get avatarPresetSnacker => 'นักกินขนม';

  @override
  String get avatarPresetStrong => 'แข็งแรง';

  @override
  String get avatarColorRed => 'แดง';

  @override
  String get avatarColorGreen => 'เขียว';

  @override
  String get avatarColorBlue => 'น้ำเงิน';

  @override
  String get avatarColorTeal => 'เขียวอมฟ้า';

  @override
  String get avatarColorPink => 'ชมพู';

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
