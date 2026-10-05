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
  String get commonEdit => 'แก้ไข';

  @override
  String get commonLongPressToEdit => 'แตะค้างเพื่อแก้ไข';

  @override
  String get commonSearch => 'ค้นหา';

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
      'เพิ่มกระเป๋าจากแท็บกระเป๋า แล้วกดปุ่ม + เพื่อเริ่มบันทึกรายการ';

  @override
  String get homeNetWorthLabel => 'ทรัพย์สินสุทธิ';

  @override
  String homeNetWorthAccountCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count กระเป๋า',
      one: '1 กระเป๋า',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentTitle => 'รายการล่าสุด';

  @override
  String get homeRecentViewAll => 'ดูทั้งหมด';

  @override
  String get homeSettingsTooltip => 'การตั้งค่า';

  @override
  String get navDashboard => 'แดชบอร์ด';

  @override
  String get navTransactions => 'รายการ';

  @override
  String get navAccounts => 'กระเป๋า';

  @override
  String get navAddTransaction => 'เพิ่มรายการ';

  @override
  String get navProjects => 'โปรเจกต์ & อีเวนต์';

  @override
  String get projectsCreateNew => 'สร้างใหม่';

  @override
  String get navMore => 'เพิ่มเติม';

  @override
  String get navNotificationsTooltip => 'การแจ้งเตือน';

  @override
  String get navProfileTooltip => 'โปรไฟล์และการตั้งค่า';

  @override
  String get addTransactionComingSoon => 'การบันทึกรายการจะมาในเฟส 1a';

  @override
  String get notificationsComingSoon => 'กล่องแจ้งเตือนจะมาในเฟส 1b';

  @override
  String get accountsPlaceholderTitle => 'ยังไม่มีกระเป๋า';

  @override
  String get accountsPlaceholderMessage => 'การเพิ่มกระเป๋าจะมาในเฟส 1a';

  @override
  String get accountsAddNew => 'เพิ่มกระเป๋า';

  @override
  String get accountTypeCash => 'เงินสด';

  @override
  String get accountTypeBank => 'ธนาคาร';

  @override
  String get accountTypeEWallet => 'อีวอลเล็ท';

  @override
  String get accountTypeCreditCard => 'บัตรเครดิต';

  @override
  String get accountTypePayLater => 'ผ่อนทีหลัง';

  @override
  String accountCreditUsedPercent(int percent) {
    return 'ใช้ $percent%';
  }

  @override
  String get accountDetailNotFound => 'ไม่พบกระเป๋า';

  @override
  String get accountDetailNotFoundMessage =>
      'กระเป๋านี้อาจถูกเก็บเข้าคลังหรือลบไปแล้ว';

  @override
  String get accountDetailEdit => 'แก้ไข';

  @override
  String get accountDetailAdjustBalance => 'ปรับยอด';

  @override
  String get accountDetailArchive => 'เก็บเข้าคลัง';

  @override
  String get accountDetailActionComingSoon => 'ฟังก์ชันนี้จะมาในเฟส 1a';

  @override
  String accountDetailCreditAvailable(String available, String limit) {
    return 'เหลือ $available จาก $limit';
  }

  @override
  String get accountDetailSummaryTitle => 'สรุป';

  @override
  String get accountDetailSummaryIncome => 'รายรับ';

  @override
  String get accountDetailSummaryExpense => 'รายจ่าย';

  @override
  String get accountDetailSummaryNet => 'สุทธิ';

  @override
  String accountDetailSummaryTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
      zero: 'ไม่มีรายการ',
    );
    return '$_temp0';
  }

  @override
  String get accountDetailBillingTitle => 'การเรียกเก็บเงิน';

  @override
  String get accountDetailStatementDate => 'วันสรุปยอด';

  @override
  String get accountDetailPaymentDue => 'วันครบกำหนด';

  @override
  String get accountDetailMinimumPayment => 'ขั้นต่ำที่ต้องจ่าย';

  @override
  String accountDetailDayOfMonth(int day) {
    return 'วันที่ $day ของทุกเดือน';
  }

  @override
  String get accountDetailTransactionsTitle => 'รายการ';

  @override
  String get accountDetailTransactionsEmptyTitle => 'ยังไม่มีรายการ';

  @override
  String get accountDetailTransactionsEmptyMessage =>
      'การบันทึกรายการจะมาในเฟส 1a';

  @override
  String get accountFormTitle => 'กระเป๋าใหม่';

  @override
  String get accountFormTitleEdit => 'แก้ไขกระเป๋า';

  @override
  String get accountFormSaveEdit => 'บันทึกการแก้ไข';

  @override
  String get accountFormPreviewLabel => 'ตัวอย่าง';

  @override
  String get accountFormTypeLabel => 'ประเภท';

  @override
  String get accountFormNameLabel => 'ชื่อกระเป๋า';

  @override
  String get accountFormNameRequired => 'จำเป็น';

  @override
  String get accountFormNameTooLong => 'สูงสุด 100 ตัวอักษร';

  @override
  String get accountFormIconLabel => 'ไอคอน';

  @override
  String get accountFormColorLabel => 'สี';

  @override
  String get accountFormUploadLogo => 'อัปโหลดโลโก้ (เฟส 2)';

  @override
  String get accountFormBalanceLabel => 'ยอดเริ่มต้น';

  @override
  String get accountFormBalanceHelper =>
      'เงินที่มีอยู่ในกระเป๋านี้ ณ วันที่เริ่มติดตาม';

  @override
  String get accountFormCreditSection => 'รายละเอียดบัตรเครดิต';

  @override
  String get accountFormCreditLimitLabel => 'วงเงิน';

  @override
  String get accountFormCreditLimitRequired => 'จำเป็นสำหรับกระเป๋าเครดิต';

  @override
  String get accountFormStatementDateLabel => 'วันสรุปยอด';

  @override
  String get accountFormStatementDateHelper => 'วันของเดือน (1–31)';

  @override
  String get accountFormPaymentDueLabel => 'วันครบกำหนดชำระ';

  @override
  String get accountFormPaymentDueHelper => 'วันของเดือน (1–31)';

  @override
  String get accountFormMinimumPaymentLabel => 'ขั้นต่ำที่ต้องจ่าย';

  @override
  String get accountFormDayInvalid => 'ต้องเป็น 1–31';

  @override
  String get accountFormSave => 'บันทึกกระเป๋า';

  @override
  String get accountFormDiscardTitle => 'ยกเลิกกระเป๋าใหม่?';

  @override
  String get accountFormDiscardBody => 'การเปลี่ยนแปลงของคุณจะหายไป';

  @override
  String get accountFormDiscardTitleEdit => 'ยกเลิกการแก้ไข?';

  @override
  String get accountAdjustBalanceTitle => 'ปรับยอดเงิน';

  @override
  String get accountAdjustBalanceBody =>
      'ตั้งยอดใหม่ ระบบจะบันทึกส่วนต่างเป็นรายการ Adjustment เพื่อให้ประวัติตรงกัน';

  @override
  String get accountAdjustBalanceCurrentLabel => 'ยอดปัจจุบัน';

  @override
  String get accountAdjustBalanceNewLabel => 'ยอดใหม่';

  @override
  String get accountAdjustBalanceNoteLabel => 'บันทึก (ไม่บังคับ)';

  @override
  String get accountAdjustBalanceInvalidAmount => 'ใส่ตัวเลข';

  @override
  String get accountAdjustBalanceNoChange => 'ยอดใหม่ต้องต่างจากยอดปัจจุบัน';

  @override
  String get accountAdjustBalanceConfirm => 'ปรับ';

  @override
  String get accountArchiveConfirmTitle => 'เก็บกระเป๋านี้?';

  @override
  String get accountArchiveConfirmBody =>
      'กระเป๋าจะถูกซ่อนจากรายการที่ใช้งาน รายการที่มีอยู่จะยังคงอ้างถึงได้';

  @override
  String get accountArchiveConfirmAction => 'เก็บ';

  @override
  String get accountFormCurrencyLabel => 'สกุลเงิน';

  @override
  String get accountFormCurrencyPhase2 => 'หลายสกุลเงินจะมาในเฟส 2';

  @override
  String get accountFormPhase2Badge => 'เฟส 2';

  @override
  String get accountFormDescriptionLabel => 'คำอธิบาย';

  @override
  String get accountFormDescriptionHelper =>
      'ใช้สำหรับอะไร เห็นเฉพาะคุณคนเดียว';

  @override
  String get accountFormDescriptionTooLong => 'สูงสุด 200 ตัวอักษร';

  @override
  String get accountFormNoteLabel => 'บันทึกย่อ';

  @override
  String get accountFormNoteHelper =>
      'บันทึกส่วนตัว (เช่น \"เงินไปเที่ยวญี่ปุ่น\")';

  @override
  String get accountFormNoteTooLong => 'สูงสุด 200 ตัวอักษร';

  @override
  String get iconPickerSectionStyle => 'สไตล์';

  @override
  String get iconPickerSectionColor => 'สี';

  @override
  String get iconPickerUseThis => 'ใช้รูปนี้';

  @override
  String get iconPickerRemove => 'ลบ';

  @override
  String get iconPickerUploadComingSoon => 'อัปโหลด (เฟส 2)';

  @override
  String get iconPickerCropComingSoon => 'ครอป (เฟส 2)';

  @override
  String get iconMakerRoleIcon => 'ไอคอน';

  @override
  String get iconMakerRoleBackground => 'พื้นหลัง';

  @override
  String get iconMakerRoleBorder => 'ขอบ';

  @override
  String get iconMakerColor => 'สี';

  @override
  String get iconMakerColorEditing => 'สีที่กำลังแก้';

  @override
  String get iconMakerColorHint => 'แตะจานสีด้านล่างเพื่อเปลี่ยนช่องที่เลือก';

  @override
  String get iconMakerRecentCustom => 'ล่าสุด · กำหนดเอง';

  @override
  String get iconMakerThemeColors => 'ตามธีม';

  @override
  String get iconMakerPresetColors => 'สำเร็จรูป';

  @override
  String get iconMakerHex => 'Hex';

  @override
  String get iconMakerReset => 'คืนค่าเริ่มต้น';

  @override
  String get iconMakerPresetLabel => 'พรีเซ็ต';

  @override
  String get colorPickerTitle => 'เลือกสี';

  @override
  String get colorPickerUse => 'ใช้สีนี้';

  @override
  String get projectsPlaceholderTitle => 'ยังไม่มีโปรเจกต์';

  @override
  String get projectsPlaceholderMessage => 'โปรเจกต์ร่วมจะมาในเฟส 1b';

  @override
  String get moreSheetTitle => 'เพิ่มเติม';

  @override
  String get morePhase1aHeader => 'เฟส 1a — เร็ว ๆ นี้';

  @override
  String get morePhase1bHeader => 'เฟส 1b — เร็ว ๆ นี้';

  @override
  String get morePhase1cHeader => 'เฟส 1c — เร็ว ๆ นี้';

  @override
  String get moreTransactions => 'รายการทั้งหมด';

  @override
  String get moreCategories => 'หมวดหมู่';

  @override
  String get moreProjects => 'โปรเจกต์ & อีเวนต์';

  @override
  String get moreTags => 'แท็ก';

  @override
  String get moreContacts => 'ผู้ติดต่อ';

  @override
  String get contactsAddNew => 'เพิ่มผู้ติดต่อ';

  @override
  String get contactsFilterActive => 'ใช้งาน';

  @override
  String get contactsFilterArchived => 'เก็บถาวร';

  @override
  String get contactsFilterAll => 'ทั้งหมด';

  @override
  String get contactsEmptyTitle => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get contactsEmptyMessage =>
      'คนที่คุณเพิ่มจะแสดงที่นี่ — เชื่อมเพื่อแชร์รายการและหนี้สินกันได้';

  @override
  String get moreDebts => 'หนี้สิน';

  @override
  String get moreNotifications => 'การแจ้งเตือน';

  @override
  String get moreBudgets => 'งบประมาณ';

  @override
  String get moreSavingGoals => 'เป้าหมายการออม';

  @override
  String get moreScheduled => 'รายการตามกำหนด';

  @override
  String get moreComingSoonBadge => 'เร็ว ๆ นี้';

  @override
  String get moreComingInPhase1a => 'จะมาในเฟส 1a';

  @override
  String get moreComingInPhase1b => 'จะมาในเฟส 1b';

  @override
  String get moreComingInPhase1c => 'จะมาในเฟส 1c';

  @override
  String get categoriesTitle => 'หมวดหมู่';

  @override
  String get categoriesSectionExpense => 'รายจ่าย';

  @override
  String get categoriesSectionIncome => 'รายรับ';

  @override
  String get categoriesEmptyTitle => 'ยังไม่มีหมวดหมู่';

  @override
  String get categoriesEmptyMessage => 'เพิ่มหมวดหมู่แรกเพื่อจัดระเบียบรายการ';

  @override
  String get categoriesLimitReached =>
      'ถึงขีดจำกัด 100 หมวดหมู่แล้ว เก็บเข้าคลังหรือลบหนึ่งรายการก่อนเพิ่มใหม่';

  @override
  String get categoryTypeExpense => 'รายจ่าย';

  @override
  String get categoryTypeIncome => 'รายรับ';

  @override
  String get categoryHiddenFromReport => 'ซ่อนจากรายงาน';

  @override
  String get categoryFormTitleNew => 'หมวดหมู่ใหม่';

  @override
  String get categoryFormTitleEdit => 'แก้ไขหมวดหมู่';

  @override
  String get categoryFormBadge => 'หมวดหมู่';

  @override
  String get categoryFormPreviewLabel => 'ตัวอย่าง';

  @override
  String get categoryFormNameLabel => 'ชื่อ';

  @override
  String get categoryFormNameRequired => 'จำเป็น';

  @override
  String get categoryFormNameTooLong => 'สูงสุด 100 ตัวอักษร';

  @override
  String get categoryFormNameDuplicate =>
      'มีหมวดหมู่ในระดับนี้ที่ใช้ชื่อนี้แล้ว';

  @override
  String get categoryFormTypeLabel => 'ประเภท';

  @override
  String get categoryFormTypeImmutableHelper =>
      'เปลี่ยนประเภทหลังสร้างไม่ได้ ถ้าต้องการเปลี่ยนให้ลบแล้วสร้างใหม่';

  @override
  String get categoryFormParentLabel => 'หมวดหลัก';

  @override
  String get categoryFormParentNone => 'ไม่มี';

  @override
  String get categoryFormParentDepthHint => 'หมวดหมู่ซ้อนกันได้สูงสุด 3 ระดับ';

  @override
  String get categoryFormIconLabel => 'ไอคอน';

  @override
  String get categoryFormColorLabel => 'สี';

  @override
  String get categoryFormDescriptionLabel => 'คำอธิบาย';

  @override
  String get categoryFormDescriptionHelper =>
      'ใช้สำหรับอะไร เห็นเฉพาะคุณคนเดียว';

  @override
  String get categoryFormDescriptionTooLong => 'สูงสุด 200 ตัวอักษร';

  @override
  String get categoryFormNoteLabel => 'บันทึกย่อ';

  @override
  String get categoryFormNoteHelper => 'บันทึกส่วนตัว (เช่น \"อย่าใช้กับขนม\")';

  @override
  String get categoryFormNoteTooLong => 'สูงสุด 200 ตัวอักษร';

  @override
  String get categoryFormIncludeInReportLabel => 'รวมในรายงาน';

  @override
  String get categoryFormIncludeInReportHelper =>
      'ปิด = รายการในหมวดนี้จะไม่ถูกนับในยอดรวมและกราฟ';

  @override
  String get categoryFormSave => 'บันทึกหมวดหมู่';

  @override
  String get categoryFormDiscardTitle => 'ยกเลิกการเปลี่ยนแปลง?';

  @override
  String get categoryFormDiscardBody => 'การแก้ไขของคุณจะหายไป';

  @override
  String get categoriesAddNew => 'เพิ่มหมวดหมู่';

  @override
  String get categoriesReorderEnter => 'จัดลำดับ';

  @override
  String get categoriesReorderSave => 'บันทึก';

  @override
  String get categoriesReorderDiscard => 'ยกเลิก';

  @override
  String get categoriesReorderHint =>
      'ลากเพื่อจัดลำดับ ปล่อยใกล้รายการอื่นเพื่อย้ายไปอยู่ใต้หมวดเดียวกัน';

  @override
  String get categoriesUndo => 'ย้อนกลับ';

  @override
  String get categoriesReorderTooDeep => 'การย้ายจะเกิน 3 ระดับที่อนุญาต';

  @override
  String get categoriesReorderCycle =>
      'ไม่สามารถย้ายหมวดหมู่เข้าสู่หมวดย่อยของตัวเองได้';

  @override
  String get categoriesReorderCancel => 'ยกเลิก';

  @override
  String get tagsTitle => 'แท็ก';

  @override
  String get tagsEmptyTitle => 'ยังไม่มีแท็ก';

  @override
  String get tagsEmptyMessage =>
      'ใช้แท็กกับรายการเพื่อแบ่งกลุ่มการใช้จ่ายตามที่ต้องการ';

  @override
  String get tagsAddNew => 'เพิ่มแท็ก';

  @override
  String tagsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '×$count',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get tagDeleteConfirmTitle => 'ลบแท็ก?';

  @override
  String get tagDeleteConfirmBody =>
      'จะลบแท็กออกจากรายการที่ใช้แท็กนี้ ไม่สามารถย้อนกลับได้';

  @override
  String get tagDeleteConfirmAction => 'ลบ';

  @override
  String get tagFormTitleNew => 'แท็กใหม่';

  @override
  String get tagFormTitleEdit => 'แก้ไขแท็ก';

  @override
  String get tagFormPreviewLabel => 'ตัวอย่าง';

  @override
  String get tagFormNameLabel => 'ชื่อ';

  @override
  String get tagFormNameRequired => 'จำเป็น';

  @override
  String get tagFormNameTooLong => 'สูงสุด 50 ตัวอักษร';

  @override
  String get tagFormNameDuplicate => 'มีแท็กที่ใช้ชื่อนี้อยู่แล้ว';

  @override
  String get tagFormIconLabel => 'ไอคอน';

  @override
  String get tagFormColorLabel => 'สี';

  @override
  String get tagFormSave => 'บันทึกแท็ก';

  @override
  String get tagFormDiscardTitle => 'ยกเลิกการเปลี่ยนแปลง?';

  @override
  String get tagFormDiscardBody => 'การแก้ไขของคุณจะหายไป';

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
  String get editProfileEmailHelper =>
      'ใช้เป็นรหัสบัญชีของคุณ และเป็นคีย์ที่คนอื่นใช้ค้นหาเพื่อส่งคำขอเชื่อมโยงผู้ติดต่อ';

  @override
  String get editProfileEmailInvalid => 'กรุณากรอกอีเมลให้ถูกต้อง';

  @override
  String get editProfileEmailTooLong => 'อีเมลยาวเกินไป';

  @override
  String get editProfileEmailTaken => 'อีเมลนี้ถูกใช้กับบัญชีอื่นแล้ว';

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

  @override
  String get transactionFormTitleNew => 'รายการใหม่';

  @override
  String get transactionFormTitleEdit => 'แก้ไขรายการ';

  @override
  String get transactionTypeExpense => 'รายจ่าย';

  @override
  String get transactionTypeIncome => 'รายรับ';

  @override
  String get transactionTypeTransfer => 'โอนเงิน';

  @override
  String get transactionFormAccountLabel => 'กระเป๋า';

  @override
  String get transactionFormFromAccountLabel => 'จากกระเป๋า';

  @override
  String get transactionFormToAccountLabel => 'ไปกระเป๋า';

  @override
  String get transactionFormAccountRequired => 'เลือกกระเป๋า';

  @override
  String get transactionFormAccountSameError =>
      'กระเป๋าต้นทางและปลายทางต้องไม่ใช่กระเป๋าเดียวกัน';

  @override
  String get transactionFormCategoryLabel => 'หมวดหมู่';

  @override
  String get transactionFormCategoryNone => 'ไม่ระบุหมวด';

  @override
  String get transactionFormTransferCategoryHint =>
      'ระบบจะตั้งหมวด Transfer In/Out ให้อัตโนมัติ';

  @override
  String get transactionFormDateLabel => 'วันที่';

  @override
  String get transactionFormAmountLabel => 'จำนวนเงิน';

  @override
  String get transactionFormAmountRequired => 'จำเป็น';

  @override
  String get transactionFormAmountInvalid => 'ใส่ตัวเลขที่ถูกต้อง';

  @override
  String get transactionFormAmountTooSmall => 'ต้องมากกว่า 0';

  @override
  String get transactionFormNoteLabel => 'บันทึก (ไม่บังคับ)';

  @override
  String get transactionFormNoteAddLabel => '+ เพิ่มบันทึก';

  @override
  String get transactionFormTagsLabel => 'แท็ก';

  @override
  String get transactionFormTagsEmpty => 'ยังไม่มีแท็ก สร้างได้จากหน้าแท็ก';

  @override
  String get transactionFormSave => 'บันทึก';

  @override
  String get transactionFormSaveAndAddAnother => 'บันทึกและเพิ่มอีกรายการ';

  @override
  String get transactionFormSavedAddedAnother =>
      'บันทึกแล้ว เพิ่มรายการต่อด้านล่างได้';

  @override
  String get transactionFormAccountNone => 'ไม่มีกระเป๋า';

  @override
  String get transactionFormMoveTransferTitle => 'ย้ายกระเป๋า';

  @override
  String get transactionFormAccountPickerTitle => 'เลือกกระเป๋า';

  @override
  String get transactionFormAccountPickerEmpty =>
      'ยังไม่มีกระเป๋าที่ใช้งาน เพิ่มกระเป๋าก่อน';

  @override
  String get transactionFormCategoryPickerTitle => 'เลือกหมวดหมู่';

  @override
  String get transactionFormCategoryPickerNoneOption => 'ไม่ระบุหมวด';

  @override
  String get transactionFormCategoryPickerEmpty => 'ยังไม่มีหมวดประเภทนี้';

  @override
  String get transactionFormDiscardTitle => 'ยกเลิกรายการ?';

  @override
  String get transactionFormDiscardTitleEdit => 'ยกเลิกการแก้ไข?';

  @override
  String get transactionFormDiscardBody => 'การเปลี่ยนแปลงของคุณจะหายไป';

  @override
  String get transactionDetailEdit => 'แก้ไข';

  @override
  String get transactionDetailDelete => 'ลบ';

  @override
  String get transactionDetailNotFound => 'ไม่พบรายการ';

  @override
  String get transactionDetailNotFoundMessage => 'รายการนี้อาจถูกลบไปแล้ว';

  @override
  String get transactionDetailDeleteConfirmTitle => 'ลบรายการนี้?';

  @override
  String get transactionDetailDeleteConfirmTitleTransfer => 'ลบการโอนนี้?';

  @override
  String get transactionDetailDeleteConfirmBody => 'ระบบจะย้อนยอดที่กระเป๋าให้';

  @override
  String get transactionDetailDeleteConfirmBodyTransfer =>
      'ทั้งสองรายการของการโอนจะถูกลบ และยอดที่ทั้งสองกระเป๋าจะย้อนกลับ';

  @override
  String get transactionDetailDeleteConfirmAction => 'ลบ';

  @override
  String get transactionDetailTransferReadonlyHint =>
      'หากต้องการเปลี่ยนกระเป๋า ให้ลบแล้วสร้างการโอนใหม่';

  @override
  String get transactionDetailSystemRowBanner =>
      'ระบบสร้างให้อัตโนมัติ หากต้องการแก้ไขให้ใช้การแก้ไขกระเป๋า หรือปรับยอดเงิน';

  @override
  String get transactionsRangeWeek => 'สัปดาห์นี้';

  @override
  String get transactionsRangeMonth => 'เดือนนี้';

  @override
  String get transactionsRangeYear => 'ปีนี้';

  @override
  String get transactionsRangeAll => 'ทั้งหมด';

  @override
  String get transactionsEmptyAccountTitle => 'ยังไม่มีรายการ';

  @override
  String get transactionsEmptyAccountMessage => 'กดปุ่ม + เพื่อเพิ่มรายการ';

  @override
  String get transactionsListTitle => 'รายการทั้งหมด';

  @override
  String get transactionsListFilterAll => 'ทั้งหมด';

  @override
  String get transactionsListFilterCategoryAll => 'ทุกหมวดหมู่';

  @override
  String get transactionsListEmptyMessage => 'ไม่มีรายการตรงตัวกรอง';

  @override
  String get transactionsListRetry => 'ลองใหม่';

  @override
  String get transactionsListDateToday => 'วันนี้';

  @override
  String get transactionsListDateYesterday => 'เมื่อวาน';

  @override
  String get accountAdjustBalanceViewTransaction => 'ดู';

  @override
  String get accountAdjustBalanceSuccess => 'ปรับยอดเรียบร้อย';

  @override
  String get savingGoalsTitle => 'เป้าหมายการออม';

  @override
  String get savingGoalsAddNew => 'เพิ่มเป้าหมาย';

  @override
  String get savingGoalsEmptyTitle => 'ยังไม่มีเป้าหมาย';

  @override
  String get savingGoalsEmptyMessage =>
      'ตั้งเป้าหมายซ้อนบนกระเป๋าของคุณ แล้วดูความคืบหน้าตามยอดเงิน';

  @override
  String savingGoalProgressLine(String current, String target) {
    return '$current จาก $target';
  }

  @override
  String get savingGoalCompletedLabel => 'ถึงเป้าแล้ว';

  @override
  String get savingGoalFormTitle => 'เป้าหมายใหม่';

  @override
  String get savingGoalFormTitleEdit => 'แก้ไขเป้าหมาย';

  @override
  String get savingGoalFormSave => 'สร้างเป้าหมาย';

  @override
  String get savingGoalFormSaveEdit => 'บันทึก';

  @override
  String get savingGoalFormIconLabel => 'ไอคอน';

  @override
  String get savingGoalFormNameLabel => 'ชื่อเป้าหมาย';

  @override
  String get savingGoalFormNameRequired => 'จำเป็น';

  @override
  String get savingGoalFormLinkedAccountLabel => 'กระเป๋าที่เชื่อม';

  @override
  String get savingGoalFormLinkedAccountHelper =>
      'ความคืบหน้า = ยอดกระเป๋า × % การจัดสรร';

  @override
  String get savingGoalFormLinkedAccountLockedHelper =>
      'เปลี่ยนกระเป๋าที่เชื่อมไม่ได้ ต้องลบแล้วสร้างใหม่';

  @override
  String get savingGoalFormAccountRequired => 'เลือกกระเป๋าที่เชื่อม';

  @override
  String get savingGoalFormTargetLabel => 'ยอดเป้าหมาย';

  @override
  String get savingGoalFormTargetInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get savingGoalFormAllocationLabel => 'การจัดสรร';

  @override
  String get savingGoalFormAllocationHelper =>
      'เว้นว่างเพื่อให้ระบบแนะนำ รวมทุกเป้าต่อกระเป๋าต้องไม่เกิน 100%';

  @override
  String get savingGoalFormAllocationInvalid => 'ต้องอยู่ระหว่าง 0 ถึง 100';

  @override
  String get savingGoalFormDeadlineLabel => 'วันที่ครบกำหนด';

  @override
  String get savingGoalFormDeadlinePlaceholder => 'ไม่ระบุ';

  @override
  String get savingGoalFormNoteLabel => 'หมายเหตุ';

  @override
  String get savingGoalDetailNotFound => 'ไม่พบเป้าหมาย';

  @override
  String get savingGoalDetailNotFoundMessage =>
      'เป้าหมายนี้อาจถูกลบหรือเก็บถาวรแล้ว';

  @override
  String get savingGoalDetailEdit => 'แก้ไข';

  @override
  String get savingGoalDetailArchive => 'เก็บถาวร';

  @override
  String get savingGoalDetailDelete => 'ลบ';

  @override
  String savingGoalDetailOfTarget(String target) {
    return 'จาก $target';
  }

  @override
  String get savingGoalDetailAllocation => 'การจัดสรร';

  @override
  String get savingGoalDetailRemaining => 'คงเหลือ';

  @override
  String get savingGoalDetailDeadline => 'วันที่ครบกำหนด';

  @override
  String get savingGoalDetailDaysRemaining => 'วันที่เหลือ';

  @override
  String savingGoalDetailDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
      one: '1 วัน',
    );
    return '$_temp0';
  }

  @override
  String get savingGoalDetailRequiredMonthly => 'แนะนำต่อเดือน';

  @override
  String get savingGoalArchiveConfirmTitle => 'เก็บถาวรเป้าหมายนี้?';

  @override
  String get savingGoalArchiveConfirmBody =>
      'การเก็บถาวรจะคืนสัดส่วนการจัดสรรให้กระเป๋า กู้คืนได้ภายหลังหากยังมีพื้นที่';

  @override
  String get savingGoalArchiveConfirmAction => 'เก็บถาวร';

  @override
  String get savingGoalDeleteConfirmTitle => 'ลบเป้าหมายนี้?';

  @override
  String get savingGoalDeleteConfirmBody =>
      'ลบถาวร กระเป๋าที่เชื่อมและรายการในกระเป๋าไม่ได้รับผลกระทบ';

  @override
  String get savingGoalDeleteConfirmAction => 'ลบ';

  @override
  String get budgetsTitle => 'งบประมาณ';

  @override
  String get budgetsAddNew => 'เพิ่มงบประมาณ';

  @override
  String get budgetsEmptyTitle => 'ยังไม่มีงบประมาณ';

  @override
  String get budgetsEmptyMessage =>
      'กำหนดเพดานต่อหมวดหมู่ ระบบจะตรวจการใช้จ่ายให้ในแต่ละรอบ';

  @override
  String get budgetPeriodWeekly => 'รายสัปดาห์';

  @override
  String get budgetPeriodMonthly => 'รายเดือน';

  @override
  String get budgetPeriodYearly => 'รายปี';

  @override
  String budgetSpentLine(String spent, String limit) {
    return '$spent จาก $limit';
  }

  @override
  String get budgetFormTitle => 'งบประมาณใหม่';

  @override
  String get budgetFormTitleEdit => 'แก้ไขงบประมาณ';

  @override
  String get budgetFormSave => 'สร้างงบประมาณ';

  @override
  String get budgetFormSaveEdit => 'บันทึก';

  @override
  String get budgetFormCategoryLabel => 'หมวดหมู่';

  @override
  String get budgetFormCategoryPlaceholder => 'เลือกหมวดหมู่';

  @override
  String get budgetFormCategoryHelper =>
      'ใช้กับหมวดหมู่รายจ่ายเท่านั้น เลือกหมวดหลักเพื่อนับรวมหมวดย่อยทั้งหมด';

  @override
  String get budgetFormCategoryLockedHelper =>
      'เปลี่ยนหมวดหมู่ไม่ได้ ต้องลบแล้วสร้างใหม่';

  @override
  String get budgetFormCategoryRequired => 'เลือกหมวดหมู่';

  @override
  String get budgetFormDescriptionLabel => 'คำอธิบาย';

  @override
  String get budgetFormDescriptionHelper =>
      'ไม่บังคับ ใช้เป็นชื่องบประมาณ ถ้าเว้นว่างจะใช้ชื่อหมวดหมู่แทน';

  @override
  String get budgetFormDescriptionTooLong => 'ไม่เกิน 200 ตัวอักษร';

  @override
  String get budgetFormAmountLabel => 'เพดานต่อรอบ';

  @override
  String get budgetFormAmountInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get budgetFormPeriodLabel => 'รอบ';

  @override
  String get budgetFormNoteLabel => 'หมายเหตุ';

  @override
  String get budgetFormNoteHelper =>
      'ไม่บังคับ ข้อความยาวที่จะแสดงในหน้ารายละเอียด';

  @override
  String get budgetDetailNotFound => 'ไม่พบงบประมาณ';

  @override
  String get budgetDetailNotFoundMessage =>
      'งบประมาณนี้อาจถูกลบหรือเก็บถาวรแล้ว';

  @override
  String get budgetDetailFallbackTitle => 'งบประมาณ';

  @override
  String get budgetDetailEdit => 'แก้ไข';

  @override
  String get budgetDetailArchive => 'เก็บถาวร';

  @override
  String get budgetDetailDelete => 'ลบ';

  @override
  String budgetDetailOfLimit(String limit) {
    return 'จาก $limit';
  }

  @override
  String budgetDetailRemainingLine(String amount) {
    return 'เหลือ $amount';
  }

  @override
  String budgetDetailPeriodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get budgetDetailOverLimitWarning => 'ใช้เกินเพดานงบประมาณรอบนี้แล้ว';

  @override
  String get budgetDetailBreakdownTitle => 'การใช้จ่ายตามหมวด';

  @override
  String get budgetArchiveConfirmTitle => 'เก็บถาวรงบประมาณนี้?';

  @override
  String get budgetArchiveConfirmBody =>
      'การเก็บถาวรจะซ่อนงบประมาณจากรายการที่ใช้งาน กู้คืนได้ภายหลัง';

  @override
  String get budgetArchiveConfirmAction => 'เก็บถาวร';

  @override
  String get budgetDeleteConfirmTitle => 'ลบงบประมาณนี้?';

  @override
  String get budgetDeleteConfirmBody => 'ลบถาวร รายการธุรกรรมไม่ได้รับผลกระทบ';

  @override
  String get budgetDeleteConfirmAction => 'ลบ';

  @override
  String get scheduledTitle => 'รายการตามกำหนด';

  @override
  String get scheduledAddNew => 'เพิ่มรายการ';

  @override
  String get scheduledEmptyTitle => 'ยังไม่มีรายการตามกำหนด';

  @override
  String get scheduledEmptyMessage =>
      'ตั้งค่าค่าสมาชิก ผ่อนชำระ หรือเงินกู้ ระบบจะสร้างรายการให้อัตโนมัติ';

  @override
  String get scheduledVariantRecurring => 'ประจำ';

  @override
  String get scheduledVariantInstallment => 'ผ่อนชำระ';

  @override
  String get scheduledVariantLoan => 'เงินกู้';

  @override
  String get scheduledTypeExpense => 'รายจ่าย';

  @override
  String get scheduledTypeIncome => 'รายรับ';

  @override
  String get scheduledCycleDaily => 'ทุกวัน';

  @override
  String get scheduledCycleWeekly => 'ทุกสัปดาห์';

  @override
  String get scheduledCycleMonthly => 'ทุกเดือน';

  @override
  String get scheduledCycleYearly => 'ทุกปี';

  @override
  String get scheduledStatusActive => 'ใช้งาน';

  @override
  String get scheduledStatusPaused => 'พักไว้';

  @override
  String get scheduledStatusCompleted => 'จบแล้ว';

  @override
  String get scheduledStatusCancelled => 'ยกเลิก';

  @override
  String scheduledNextDue(String date) {
    return 'ครบกำหนด $date';
  }

  @override
  String scheduledInstallmentsLeft(int remaining, int total) {
    return 'เหลือ $remaining/$total';
  }

  @override
  String get scheduledFormTitle => 'รายการตามกำหนดใหม่';

  @override
  String get scheduledFormTitleEdit => 'แก้ไขรายการ';

  @override
  String get scheduledFormSave => 'สร้าง';

  @override
  String get scheduledFormSaveEdit => 'บันทึก';

  @override
  String get scheduledFormIconLabel => 'ไอคอน';

  @override
  String get scheduledFormVariantLabel => 'ประเภท';

  @override
  String get scheduledFormTypeLabel => 'ทิศทาง';

  @override
  String get scheduledFormNameLabel => 'ชื่อ';

  @override
  String get scheduledFormNameRequired => 'จำเป็น';

  @override
  String get scheduledFormAmountLabel => 'จำนวนต่อรอบ';

  @override
  String get scheduledFormPaymentLabel => 'ค่างวดต่อรอบ';

  @override
  String get scheduledFormAmountInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get scheduledFormAccountLabel => 'กระเป๋า';

  @override
  String get scheduledFormAccountRequired => 'เลือกกระเป๋า';

  @override
  String get scheduledFormCategoryLabel => 'หมวดหมู่';

  @override
  String get scheduledFormCategoryRequired => 'เลือกหมวดหมู่';

  @override
  String get scheduledFormCycleLabel => 'รอบ';

  @override
  String get scheduledFormNextBillingLabel => 'วันที่งวดถัดไป';

  @override
  String get scheduledFormInstallmentSection => 'ข้อมูลการผ่อน';

  @override
  String get scheduledFormTotalAmountLabel => 'ยอดรวม';

  @override
  String get scheduledFormTotalAmountHelper => 'รวมทุกงวด + เงินดาวน์';

  @override
  String get scheduledFormTotalAmountHelperLoan =>
      'ยอดรวมตลอดสัญญา รวมต้นและดอกเบี้ย';

  @override
  String get scheduledFormDownPaymentLabel => 'เงินดาวน์';

  @override
  String get scheduledFormTotalInstallmentsLabel => 'งวดทั้งหมด';

  @override
  String get scheduledFormRemainingInstallmentsLabel => 'งวดที่เหลือ';

  @override
  String get scheduledFormInstallmentsInvalid => 'จำนวนไม่ถูกต้อง';

  @override
  String get scheduledFormRemainingExceeds => 'ห้ามเกินจำนวนงวดทั้งหมด';

  @override
  String get scheduledFormInterestRateLabel => 'อัตราดอกเบี้ย (ต่อปี)';

  @override
  String get scheduledFormInterestInvalid => 'ต้องอยู่ระหว่าง 0 ถึง 99.99';

  @override
  String get scheduledFormNoteLabel => 'หมายเหตุ';

  @override
  String get scheduledDetailNotFound => 'ไม่พบรายการ';

  @override
  String get scheduledDetailNotFoundMessage =>
      'รายการนี้อาจถูกลบหรือยกเลิกแล้ว';

  @override
  String get scheduledDetailEdit => 'แก้ไข';

  @override
  String get scheduledDetailPause => 'พักไว้';

  @override
  String get scheduledDetailResume => 'ใช้งานต่อ';

  @override
  String get scheduledDetailCancel => 'ยกเลิก';

  @override
  String get scheduledDetailDelete => 'ลบ';

  @override
  String scheduledDetailNextDue(String date) {
    return 'งวดถัดไป $date';
  }

  @override
  String get scheduledDetailAccount => 'กระเป๋า';

  @override
  String get scheduledDetailCategory => 'หมวดหมู่';

  @override
  String get scheduledDetailCycle => 'รอบ';

  @override
  String get scheduledDetailTotalAmount => 'ยอดรวม';

  @override
  String get scheduledDetailDownPayment => 'เงินดาวน์';

  @override
  String get scheduledDetailInstallments => 'งวด';

  @override
  String get scheduledDetailInterestRate => 'อัตราดอกเบี้ย';

  @override
  String get scheduledDetailNote => 'หมายเหตุ';

  @override
  String get scheduledGenerateNowTitle => 'สร้างตอนนี้';

  @override
  String get scheduledGenerateNowBody =>
      'สร้างรายการถัดไปและเลื่อนงวด — เฟส 1c เท่านั้น เฟส 3 จะมีระบบสร้างอัตโนมัติ';

  @override
  String get scheduledGenerateNowAction => 'สร้าง';

  @override
  String get scheduledGenerateNowSuccess => 'สร้างรายการแล้ว';

  @override
  String get scheduledGenerateNowViewTransaction => 'ดู';

  @override
  String get scheduledDetailHistoryTitle => 'รายการที่สร้างแล้ว';

  @override
  String get scheduledDetailHistoryEmpty => 'ยังไม่มีรายการที่ระบบสร้าง';

  @override
  String scheduledDetailHistoryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
      one: '1 รายการ',
    );
    return '$_temp0';
  }

  @override
  String get scheduledCancelConfirmTitle => 'ยกเลิกรายการนี้?';

  @override
  String get scheduledCancelConfirmBody =>
      'การยกเลิกถาวร ต้องสร้างใหม่หากต้องการตั้งใหม่';

  @override
  String get scheduledCancelConfirmAction => 'ยกเลิก';

  @override
  String get scheduledDeleteConfirmTitle => 'ลบรายการนี้?';

  @override
  String get scheduledDeleteConfirmBody =>
      'รายการที่ระบบสร้างแล้วยังคงอยู่ ลบเฉพาะรายการตามกำหนด';

  @override
  String get scheduledDeleteConfirmAction => 'ลบ';

  @override
  String get projectFormPlannedLabel => 'ตั้งงบไว้';

  @override
  String get projectFormPlannedHelper =>
      'ไม่บังคับ — ยอดรวมที่ตั้งใจจะใช้ ล้างค่าเพื่อปิดการแสดงแผน';

  @override
  String get projectFormPlannedInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get projectFormPlannedClearTooltip => 'ล้างค่า';

  @override
  String projectMetaPlanned(String amount) {
    return 'งบ $amount';
  }

  @override
  String get projectPlannedRemainingCardLabel => 'คงเหลือ';

  @override
  String projectPlannedLine(String planned, String remaining) {
    return 'ตั้งงบไว้ $planned · เหลือ $remaining';
  }

  @override
  String projectPlannedOverLine(String over) {
    return '🔴 เกินงบ $over';
  }

  @override
  String get projectSummaryPlannedLabel => 'ตั้งงบไว้';

  @override
  String get projectSummarySpentLabel => 'ใช้ไปสุทธิ';

  @override
  String get projectSummaryRemainingLabel => 'เหลือ';

  @override
  String get projectSummaryOverLabel => 'เกินงบ';

  @override
  String walletsHeaderMine(String amount) {
    return 'รวมของฉัน $amount';
  }

  @override
  String walletsHeaderShared(String amount) {
    return 'กองกลาง $amount';
  }

  @override
  String get walletSharedLabel => 'กระเป๋าร่วม';

  @override
  String get walletMembersTitle => 'สมาชิก';

  @override
  String walletMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'สมาชิก $count คน',
    );
    return '$_temp0';
  }

  @override
  String get walletMembersHistoryTitle => 'สมาชิกที่ออกแล้ว';

  @override
  String get walletMemberRoleOwner => 'เจ้าของ';

  @override
  String get walletMemberRoleMember => 'สมาชิก';

  @override
  String get walletMemberPending => 'รอตอบรับ';

  @override
  String get walletMemberYou => 'คุณ';

  @override
  String walletMemberJoined(String date) {
    return 'เข้าร่วม $date';
  }

  @override
  String walletMemberLeft(String date) {
    return 'ออกเมื่อ $date';
  }

  @override
  String get walletMembersInvite => 'เชิญทางอีเมล';

  @override
  String get walletInviteTitle => 'เชิญสมาชิก';

  @override
  String get walletInviteEmailLabel => 'อีเมล';

  @override
  String get walletInviteEmailInvalid => 'กรุณากรอกอีเมลให้ถูกต้อง';

  @override
  String get walletInviteSend => 'ส่งคำเชิญ';

  @override
  String get walletInviteSent => 'ส่งคำเชิญแล้ว';

  @override
  String walletConvertWarnTitle(String name) {
    return '⚠️ เชิญ \"$name\" เข้ากระเป๋านี้?';
  }

  @override
  String walletConvertWarnBody(String wallet, String name) {
    return 'กระเป๋า $wallet จะกลายเป็นกระเป๋าร่วม:\n• $nameจะเห็นรายการทั้งหมดที่ผ่านมาของกระเป๋านี้ (ย้อนหลังทุกรายการ)\n• ทั้งสองคนเพิ่ม/แก้/ลบรายการได้\n• กระเป๋านี้จะถูกเอาออกจากรายงานส่วนตัวอัตโนมัติ (เปิดกลับได้ในตั้งค่า)';
  }

  @override
  String get walletLeave => 'ออกจากกระเป๋า';

  @override
  String get walletLeaveConfirmTitle => 'ออกจากกระเป๋านี้?';

  @override
  String get walletLeaveConfirmBody =>
      'รายการที่คุณจดไว้จะยังอยู่ในกระเป๋า แต่คุณจะแก้ไขไม่ได้อีก สมาชิกที่เหลือยังจัดการรายการเหล่านั้นได้';

  @override
  String get walletLeaveAction => 'ออกจากกระเป๋า';

  @override
  String get walletRemoveMemberAction => 'เอาออกจากกระเป๋า';

  @override
  String walletRemoveMemberConfirmTitle(String name) {
    return 'เอา $name ออก?';
  }

  @override
  String get walletRemoveMemberConfirmBody =>
      'รายการที่เขาจดไว้จะยังอยู่ในกระเป๋า และจะอ่านได้อย่างเดียวสำหรับเขา';

  @override
  String get walletTransferOwnershipAction => 'โอนความเป็นเจ้าของ';

  @override
  String walletTransferOwnershipConfirmTitle(String name) {
    return 'โอนความเป็นเจ้าของให้ $name?';
  }

  @override
  String get walletTransferOwnershipConfirmBody =>
      'เขาจะเป็นเจ้าของกระเป๋านี้แทน ส่วนคุณยังเป็นสมาชิกอยู่';

  @override
  String get walletTransferOwnershipConfirm => 'โอน';

  @override
  String get walletTransferOwnershipSuccess => 'โอนความเป็นเจ้าของแล้ว';

  @override
  String get walletSettingsTitle => 'ตั้งค่ากระเป๋า';

  @override
  String get walletSettingsMembersSubtitlePersonal =>
      'ชวนคนอื่นมาใช้กระเป๋านี้ร่วมกัน';

  @override
  String get walletReportScopeTitle => 'ในรายงานของฉัน';

  @override
  String get walletReportScopeHelper =>
      'กำหนดว่ารายการของกระเป๋านี้จะถูกนับในสรุปและงบประมาณส่วนตัวของคุณอย่างไร หน้ากระเป๋าเองยังแสดงทุกรายการเสมอ';

  @override
  String get walletReportScopeNone => 'ไม่รวมในรายงาน';

  @override
  String get walletReportScopeOwn => 'เฉพาะที่ฉันจด';

  @override
  String get walletReportScopeAll => 'ทั้งกระเป๋า';

  @override
  String get walletReportScopeSaved => 'บันทึกการตั้งค่ารายงานแล้ว';

  @override
  String get transactionFormCategoryAuthorOnlyHint => 'หมวดแก้ได้เฉพาะคนจด';

  @override
  String get transactionFormLockedBanner =>
      'อ่านได้อย่างเดียว — คุณออกจากกระเป๋านี้แล้ว จึงแก้ไขรายการนี้ไม่ได้';

  @override
  String notificationWalletInviteTitle(String actor, String wallet) {
    return '$actor ชวนคุณเข้ากระเป๋า \"$wallet\"';
  }

  @override
  String get notificationAccept => 'ตอบรับ';

  @override
  String get notificationReject => 'ปฏิเสธ';

  @override
  String get walletErrorNotMember => 'คุณไม่ได้เป็นสมาชิกของกระเป๋านี้';

  @override
  String get walletErrorOwnerMustTransfer =>
      'ต้องโอนความเป็นเจ้าของก่อน เพราะกระเป๋านี้ยังมีสมาชิกคนอื่นอยู่';

  @override
  String get walletErrorHasMembers =>
      'กระเป๋านี้ยังมีสมาชิกคนอื่นอยู่ จึงเก็บเข้าคลังหรือลบไม่ได้';

  @override
  String get walletErrorCategoryAuthorOnly =>
      'หมวดของรายการนี้แก้ได้เฉพาะคนจดเท่านั้น';

  @override
  String get walletErrorRowLocked =>
      'รายการนี้ถูกล็อก เพราะคุณออกจากกระเป๋านี้แล้ว';

  @override
  String get walletErrorScopeNotAllowed =>
      'อดีตสมาชิกเลือกได้เฉพาะ \"ไม่รวมในรายงาน\" หรือ \"เฉพาะที่ฉันจด\"';

  @override
  String get walletErrorUserNotFound => 'ไม่พบผู้ใช้ที่ใช้อีเมลนี้';

  @override
  String get walletErrorAlreadyMember =>
      'ผู้ใช้นี้เป็นสมาชิกของกระเป๋านี้อยู่แล้ว';

  @override
  String get quickCreateToggle => 'สร้างอีเวนต์จากบิลนี้...';

  @override
  String get transactionSplitWithTitle => 'หารกับ...';

  @override
  String get transactionSplitShareTitle => 'แบ่งให้... (เราติดเงินเขา)';

  @override
  String get quickCreateOldBillsSection =>
      'รวมบิลเก่าเข้าอีเวนต์นี้ (ไม่บังคับ)';

  @override
  String get quickCreateOldBillsHint =>
      'บิลเดี่ยว ๆ ของคุณจาก 90 วันที่ผ่านมา — ติ๊กเลือกเพื่อดึงเข้าบอร์ดอีเวนต์';

  @override
  String get quickCreateSearchHint => 'ค้นหาบิลเก่า';

  @override
  String get quickCreateOldBillsEmpty => 'ไม่มีบิลเดี่ยว ๆ ใน 90 วันที่ผ่านมา';

  @override
  String get quickCreateOldBillsSearchEmpty => 'ไม่พบบิลที่ตรงกับคำค้นหา';

  @override
  String get quickCreateOldBillsLoadMore => 'โหลดเพิ่ม';

  @override
  String get quickCreateOldBillsRetry => 'ลองใหม่';

  @override
  String quickCreateSelectedCount(int count) {
    return 'เลือกแล้ว $count บิล';
  }

  @override
  String get quickCreateNameSection => 'ชื่ออีเวนต์';

  @override
  String get quickCreateNameLabel => 'ชื่ออีเวนต์';

  @override
  String get quickCreateNameRequired => 'ใส่ชื่ออีเวนต์ก่อนนะ';

  @override
  String quickCreateDefaultName(String members, String date) {
    return '$members · $date';
  }

  @override
  String quickCreateDefaultNameSolo(String date) {
    return 'อีเวนต์ · $date';
  }

  @override
  String get quickCreateSubmit => 'สร้างอีเวนต์';

  @override
  String get quickCreateErrorTxNotFound =>
      'บางบิลที่เลือกไม่มีอยู่แล้ว ลองรีเฟรชแล้วเลือกใหม่';

  @override
  String get quickCreateErrorTxAlreadyInProject =>
      'บางบิลที่เลือกอยู่ในอีเวนต์อื่นแล้ว ลองรีเฟรชแล้วเลือกใหม่';

  @override
  String get quickCreateErrorValidation =>
      'ข้อมูลบางอย่างยังไม่ถูกต้อง ลองตรวจดูอีกครั้ง';
}
