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
  String get commonName => 'ชื่อ';

  @override
  String get commonDescription => 'คำอธิบาย';

  @override
  String get commonNote => 'โน้ต';

  @override
  String get editDiscardTitle => 'ยกเลิกการแก้ไข?';

  @override
  String get editDiscardMessage => 'สิ่งที่แก้ไว้จะไม่ถูกบันทึก';

  @override
  String get editKeepEditing => 'แก้ต่อ';

  @override
  String get editDiscardConfirm => 'ยกเลิกการแก้ไข';

  @override
  String get categorySystemOpening => 'ยอดยกมา';

  @override
  String get categorySystemAdjustment => 'ปรับยอด';

  @override
  String get categorySystemTransferIn => 'โอนเข้า';

  @override
  String get categorySystemTransferOut => 'โอนออก';

  @override
  String get categorySystemDebtReceived => 'รับชำระหนี้';

  @override
  String get categorySystemDebtPaid => 'ชำระหนี้';

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
  String get commonClose => 'ปิด';

  @override
  String get commonEdit => 'แก้ไข';

  @override
  String get commonLongPressToEdit => 'แตะค้างเพื่อแก้ไข';

  @override
  String get commonSearch => 'ค้นหา';

  @override
  String get commonCustomValue => 'ใส่เอง';

  @override
  String get uiPickDate => 'เลือกวันที่';

  @override
  String get commonToday => 'วันนี้';

  @override
  String get commonYesterday => 'เมื่อวาน';

  @override
  String get commonInvite => 'เชิญ';

  @override
  String get commonClear => 'ล้าง';

  @override
  String get commonUndo => 'เลิกทำ';

  @override
  String get commonCurrency => 'สกุลเงิน';

  @override
  String get currencyNameTHB => 'บาท';

  @override
  String get currencyNameUSD => 'ดอลลาร์สหรัฐ';

  @override
  String get currencyNameEUR => 'ยูโร';

  @override
  String get currencyNameGBP => 'ปอนด์สเตอร์ลิง';

  @override
  String get currencyNameJPY => 'เยน';

  @override
  String get contactPickerTitle => 'กับใคร';

  @override
  String get contactPickerEmpty => 'ยังไม่มีผู้ติดต่อ — พิมพ์ชื่อด้านบนได้เลย';

  @override
  String get errorNetworkTitle => 'ไม่มีการเชื่อมต่อ';

  @override
  String get errorNetworkMessage => 'ตรวจสอบอินเทอร์เน็ตของคุณแล้วลองใหม่';

  @override
  String get errorSlowTitle => 'การเชื่อมต่อช้า';

  @override
  String get errorSlowMessage => 'เซิร์ฟเวอร์ตอบช้า กรุณาลองใหม่อีกครั้ง';

  @override
  String get errorServerDownTitle => 'เซิร์ฟเวอร์ไม่พร้อมใช้งาน';

  @override
  String get errorServerDownMessage =>
      'ระบบขัดข้องชั่วคราว ลองใหม่ในอีกสักครู่';

  @override
  String get errFieldRequired => 'กรุณากรอกช่องนี้';

  @override
  String errFieldTooLong(String max) {
    return 'ยาวเกิน $max ตัวอักษร';
  }

  @override
  String errFieldTooShort(String min) {
    return 'ต้องมีอย่างน้อย $min ตัวอักษร';
  }

  @override
  String errFieldTooMany(String max) {
    return 'ได้ไม่เกิน $max รายการ';
  }

  @override
  String errFieldTooFew(String min) {
    return 'ต้องมีอย่างน้อย $min รายการ';
  }

  @override
  String get errFieldOutOfRange => 'ค่านี้อยู่นอกช่วงที่รับได้';

  @override
  String get errFieldInvalid => 'รูปแบบไม่ถูกต้อง';

  @override
  String get errFieldTooLarge => 'ไฟล์ใหญ่เกินไป';

  @override
  String get errorGenericTitle => 'เกิดข้อผิดพลาด';

  @override
  String get errorGenericMessage => 'กรุณาลองใหม่อีกครั้ง';

  @override
  String get errorValidationMessage => 'ข้อมูลบางช่องไม่ถูกต้อง กรุณาตรวจสอบ';

  @override
  String get errNotFound => 'ไม่พบรายการนี้ อาจถูกลบไปแล้ว';

  @override
  String get errForbidden => 'คุณไม่มีสิทธิ์ทำรายการนี้';

  @override
  String get errImmutable => 'รายการนี้แก้ไขหรือลบไม่ได้';

  @override
  String get errStale => 'สถานะเปลี่ยนไปแล้ว รีเฟรชแล้วลองใหม่';

  @override
  String get errSessionExpired => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String get errAppOutdated => 'ต้องอัปเดตแอปก่อนใช้งานต่อ';

  @override
  String get errAccountInactive =>
      'บัญชีนี้ถูกปิดใช้งาน เปิดใช้งานอีกครั้งเพื่อดำเนินการต่อ';

  @override
  String get errRateLimited => 'ลองหลายครั้งเกินไป รอสักครู่แล้วลองใหม่';

  @override
  String get errLoginCodeInvalid =>
      'ลิงก์เข้าสู่ระบบหมดอายุหรือถูกใช้ไปแล้ว เริ่มใหม่อีกครั้ง';

  @override
  String get errCategoryNameDuplicate => 'มีหมวดชื่อนี้ในระดับเดียวกันแล้ว';

  @override
  String get errCategoryCycle =>
      'ย้ายหมวดไปไว้ใต้ตัวเองหรือหมวดย่อยของตัวเองไม่ได้';

  @override
  String get errTagExists => 'มีแท็กชื่อนี้แล้ว';

  @override
  String get errPaidByExceeds => 'ยอดที่ผู้จ่ายออกให้เกินยอดบิล';

  @override
  String get errPayersSum => 'ยอดของผู้จ่ายรวมกันต้องเท่ากับยอดบิล';

  @override
  String get errInsufficientSaving => 'เงินออมตรงนั้นไม่พอ';

  @override
  String get errGoalNotActive => 'เป้าหมายออมนี้ไม่ได้ใช้งานอยู่';

  @override
  String get errGoalReached => 'เป้าหมายออมนี้ครบยอดแล้ว';

  @override
  String get errGoalHasSavings => 'เป้าหมายนี้ยังมีเงินออมอยู่ ปิดเป้าหมายก่อน';

  @override
  String get errUnsupportedImage => 'ใช้รูปนี้ไม่ได้ ใช้ไฟล์ PNG หรือ JPEG';

  @override
  String get errOcrUnavailable => 'ตอนนี้อ่านสลิปไม่ได้';

  @override
  String get errOcrTimeout => 'อ่านสลิปนานเกินไป ลองใหม่อีกครั้ง';

  @override
  String get errProvider => 'แอปที่เชื่อมไว้ไม่ตอบ ลองใหม่อีกครั้ง';

  @override
  String get errNoPhoto => 'แอปที่เชื่อมไว้ไม่มีรูปให้ใช้';

  @override
  String get errAvatarSource => 'แหล่งรูปนี้ไม่มีรูปให้ใช้แล้ว';

  @override
  String get errCurrencyLocked => 'เปลี่ยนสกุลเงินไม่ได้';

  @override
  String get errPermissionUnavailable => 'เปิดสิทธิ์นี้ให้แอปนี้ไม่ได้';

  @override
  String get errCannotLinkSelf => 'ผูกผู้ติดต่อกับตัวคุณเองไม่ได้';

  @override
  String get errEndTooFar => 'วันสิ้นสุดต้องไม่เกิน 2 ปีหลังวันเริ่ม';

  @override
  String get errAmountRequired => 'ใส่จำนวนเงินก่อน';

  @override
  String get errSaveInProgress => 'กำลังบันทึกอยู่ รอสักครู่แล้วลองใหม่';

  @override
  String get errBillChanged => 'บิลนี้ถูกแก้ไขแล้ว เปิดใหม่อีกครั้ง';

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
  String get authRegisterCurrencyLabel => 'สกุลเงิน';

  @override
  String get authRegisterSubmit => 'สร้างบัญชี';

  @override
  String get authRegisterIncomplete => 'กรอกข้อมูลให้ครบและถูกต้อง';

  @override
  String get authTelegramWaitTitle => 'รอยืนยันใน Telegram';

  @override
  String get authTelegramWaitBody =>
      'กด “ยืนยัน” ในแชตกับบอท แล้วกลับมาที่แอปนี้';

  @override
  String get authTelegramReopen => 'เปิด Telegram อีกครั้ง';

  @override
  String get authTelegramCheck => 'ตรวจสอบอีกครั้ง';

  @override
  String get authTelegramExpired =>
      'ลิงก์หมดอายุ กรุณาเริ่มเข้าสู่ระบบด้วย Telegram ใหม่';

  @override
  String get authTelegramOpenFailed =>
      'เปิด Telegram ไม่ได้ ติดตั้งแอป Telegram แล้วหรือยัง';

  @override
  String get authTelegramSignupTitle => 'สร้างบัญชีด้วย Telegram';

  @override
  String get authTelegramSignupPhoto =>
      'รูปโปรไฟล์ Telegram จะถูกใช้เป็นรูปของคุณ';

  @override
  String get authTelegramUsernameTaken =>
      'ชื่อผู้ใช้นี้ถูกใช้แล้ว ใส่ชื่อที่แนะนำให้แล้ว';

  @override
  String get authTelegramAlreadyLinked =>
      'Telegram นี้ผูกกับบัญชีแล้ว ลองเข้าสู่ระบบด้วย Telegram อีกครั้ง';

  @override
  String get authTelegramUnavailable => 'ตอนนี้ยังใช้ Telegram ไม่ได้';

  @override
  String get authRegistrationClosed => 'ตอนนี้ปิดรับสมัครสมาชิก';

  @override
  String get authRegisterGoToLogin => 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ';

  @override
  String get authRegisterUsernameTaken => 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';

  @override
  String get authRegisterEmailTaken => 'อีเมลนี้ถูกใช้แล้ว';

  @override
  String get authRegisterUsernameTakenInline => 'ถูกใช้แล้ว';

  @override
  String get authRegisterEmailTakenInline => 'ถูกใช้แล้ว';

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
  String get navDashboard => 'แดชบอร์ด';

  @override
  String get homeComingSoonTitle => 'Coming Soon';

  @override
  String get homeComingSoonMessage =>
      'หน้าภาพรวมกำลังปรับปรุง ระหว่างนี้ใช้เมนูด้านล่างได้เลย';

  @override
  String get navTransactions => 'รายการ';

  @override
  String get navAccounts => 'กระเป๋า';

  @override
  String get navAddTransaction => 'เพิ่มรายการ';

  @override
  String get appExitTitle => 'ปิดแอป?';

  @override
  String get appExitConfirm => 'ปิดแอป';

  @override
  String get navProjects => 'อีเวนต์';

  @override
  String get navMore => 'เพิ่มเติม';

  @override
  String get navNotificationsTooltip => 'การแจ้งเตือน';

  @override
  String get navProfileTooltip => 'โปรไฟล์และการตั้งค่า';

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
  String get accountDetailNotFound => 'ไม่พบกระเป๋า';

  @override
  String get accountDetailNotFoundMessage =>
      'กระเป๋านี้อาจถูกเก็บถาวรหรือลบไปแล้ว';

  @override
  String get accountDetailAdjustBalance => 'ปรับยอด';

  @override
  String get accountDetailArchive => 'เก็บถาวร';

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
  String get accountDetailStatementDate => 'วันสรุปยอด';

  @override
  String get accountDetailPaymentDue => 'วันครบกำหนด';

  @override
  String get accountDetailMinimumPayment => 'ขั้นต่ำที่ต้องจ่าย';

  @override
  String get accountDetailTransactionsTitle => 'รายการ';

  @override
  String get accountDetailTabOverview => 'ภาพรวม';

  @override
  String get accountFormTitle => 'กระเป๋าใหม่';

  @override
  String get accountFormTypeLabel => 'ประเภท';

  @override
  String get accountFormNameRequired => 'จำเป็น';

  @override
  String get accountFormNameTooLong => 'สูงสุด 100 ตัวอักษร';

  @override
  String get accountFormIconLabel => 'ไอคอน';

  @override
  String get accountFormColorLabel => 'สี';

  @override
  String get accountFormBalanceLabel => 'ยอดเริ่มต้น';

  @override
  String get accountFormCreditLimitLabel => 'วงเงิน';

  @override
  String get accountFormCreditLimitRequired => 'จำเป็นสำหรับกระเป๋าเครดิต';

  @override
  String get accountFormStatementDateLabel => 'วันสรุปยอด';

  @override
  String get accountFormPaymentDueLabel => 'วันครบกำหนดชำระ';

  @override
  String get accountFormMinimumPaymentLabel => 'ขั้นต่ำที่ต้องจ่าย';

  @override
  String get accountAdjustBalanceTitle => 'ปรับยอดเงิน';

  @override
  String get accountAdjustBalanceCurrentLabel => 'ยอดปัจจุบัน';

  @override
  String get accountAdjustBalanceNewLabel => 'ยอดใหม่';

  @override
  String get accountAdjustBalanceNoChange => 'ยอดใหม่ต้องต่างจากยอดปัจจุบัน';

  @override
  String get accountArchiveConfirmTitle => 'เก็บกระเป๋านี้?';

  @override
  String get accountArchiveConfirmBody =>
      'กระเป๋าจะถูกซ่อนจากรายการที่ใช้งาน รายการที่มีอยู่จะยังคงอ้างถึงได้';

  @override
  String get accountArchiveConfirmAction => 'เก็บ';

  @override
  String get accountFormNoteHelper => 'อะไรที่อยากจดไว้ สมาชิกกระเป๋าเห็นด้วย';

  @override
  String get iconPickerUseThis => 'ใช้รูปนี้';

  @override
  String get iconMakerRoleIcon => 'ไอคอน';

  @override
  String get iconMakerRoleBackground => 'พื้นหลัง';

  @override
  String get iconMakerRoleBorder => 'ขอบ';

  @override
  String get iconMakerThemeColors => 'ตามธีม';

  @override
  String get iconMakerReset => 'คืนค่าเริ่มต้น';

  @override
  String get iconMakerTitle => 'ไอคอน';

  @override
  String get iconMakerTabStyle => 'รูปแบบ';

  @override
  String get iconMakerTabColor => 'สี';

  @override
  String get iconMakerShape => 'ทรง';

  @override
  String get iconMakerPattern => 'ลาย';

  @override
  String get iconMakerCommonColors => 'สีทั่วไป';

  @override
  String get iconMakerCustomColors => 'เลือกเอง';

  @override
  String get iconMakerSearchHint => 'ค้นหาไอคอน เช่น car, home';

  @override
  String iconMakerNoMatch(String query) {
    return 'ไม่พบไอคอน \"$query\"';
  }

  @override
  String iconMakerLayerOff(String layer) {
    return '$layer: ไม่มี — เลือกแบบในแท็บรูปแบบก่อน';
  }

  @override
  String get iconMakerNotRecolorable => 'แบบนี้เปลี่ยนสีไม่ได้';

  @override
  String get iconMakerResetSlot => 'คืนสีตั้งต้นของช่องนี้';

  @override
  String get iconMakerPickColor => 'เลือกสีเอง';

  @override
  String get iconMakerResetConfirmTitle => 'รีเซ็ตไอคอน?';

  @override
  String get iconMakerResetConfirmBody =>
      'ไอคอน สี พื้น และขอบ จะกลับเป็นค่าเริ่มต้น กดเลิกทำได้ภายหลัง';

  @override
  String get iconMakerUseDefault => 'ใช้ไอคอนเริ่มต้นของแอป';

  @override
  String get iconShapeCircle => 'วงกลม';

  @override
  String get iconShapeSquircle => 'มนมาก';

  @override
  String get iconShapeRounded => 'มน';

  @override
  String get iconShapeSquare => 'เหลี่ยม';

  @override
  String get iconShapeLeaf => 'ใบไม้';

  @override
  String get iconShapeDrop => 'หยดน้ำ';

  @override
  String get colorPickerTitle => 'เลือกสี';

  @override
  String get colorPickerUse => 'ใช้สีนี้';

  @override
  String get moreCategories => 'หมวดหมู่';

  @override
  String get moreProjects => 'อีเวนต์';

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
  String get contactsSearchHint => 'ค้นหาชื่อ อีเมล หรือเบอร์';

  @override
  String get contactsStatusLabel => 'สถานะ';

  @override
  String get contactsNoMatch => 'ไม่พบผู้ติดต่อที่ค้นหา';

  @override
  String get contactsNoMatchMessage => 'ลองคำค้นอื่น หรือเปลี่ยนตัวกรองสถานะ';

  @override
  String get contactsArchivedEmptyTitle => 'ไม่มีผู้ติดต่อที่เก็บถาวร';

  @override
  String get contactsArchivedEmptyMessage =>
      'ผู้ติดต่อที่เก็บถาวรจะแสดงที่นี่ — ซ่อนจากตัวเลือก แต่ข้อมูลเดิมยังอยู่';

  @override
  String get contactTitleNew => 'ผู้ติดต่อใหม่';

  @override
  String get contactNotFound => 'ไม่พบผู้ติดต่อ';

  @override
  String get contactNameLabel => 'ชื่อ';

  @override
  String get contactNameHint => 'ชื่อ (จำเป็น)';

  @override
  String get contactEmailHint => 'ไม่บังคับ | name@example.com';

  @override
  String get contactPhoneHint => 'ไม่บังคับ | 081-234-5678';

  @override
  String get contactNameRequired => 'ต้องใส่ชื่อ';

  @override
  String get contactNameTooLong => 'ไม่เกิน 100 ตัวอักษร';

  @override
  String get contactEmailLabel => 'อีเมล';

  @override
  String get contactEmailInvalid => 'อีเมลไม่ถูกต้อง';

  @override
  String get contactPhoneLabel => 'เบอร์โทร';

  @override
  String get contactDescriptionHint => 'ไม่บังคับ | เช่น เพื่อนที่ทำงาน';

  @override
  String get contactNoteHint => 'ไม่บังคับ | เช่น ชอบให้โอนผ่านพร้อมเพย์';

  @override
  String get contactLinkedLockedHint => 'ชื่อและอีเมลมาจากบัญชีของเขา';

  @override
  String get contactArchivedBadge => 'เก็บถาวร';

  @override
  String get contactLinkRequest => 'ส่งคำขอเชื่อม';

  @override
  String get contactLinkRequestHint =>
      'ถ้าอีเมลนี้เป็นของผู้ใช้ในแอป เขาจะได้รับคำขอ';

  @override
  String get contactEmailFromAccount => 'จากบัญชีของเขา';

  @override
  String get contactLinkNeedsEmail => 'ใส่อีเมลก่อนเพื่อส่งคำขอเชื่อม';

  @override
  String get contactLinkRequested => 'ส่งคำขอเชื่อมแล้ว';

  @override
  String get contactUnlink => 'ยกเลิกการเชื่อม';

  @override
  String contactUnlinkTitle(String name) {
    return 'ยกเลิกการเชื่อมกับ $name?';
  }

  @override
  String get contactUnlinkBody =>
      'ผู้ติดต่อจะกลับไปใช้ชื่อและอีเมลที่คุณบันทึกไว้เอง';

  @override
  String get contactUnlinked => 'ยกเลิกการเชื่อมแล้ว';

  @override
  String get contactWireTitle => 'ผูกชื่อที่เคยพิมพ์ไว้';

  @override
  String contactWireHint(int names, int splits) {
    return '$names ชื่อ | $splits รายการ ยังไม่ได้ผูกกับใคร';
  }

  @override
  String get contactWireNone => 'ไม่มีชื่อที่ยังไม่ผูก';

  @override
  String contactWireSheetTitle(String name) {
    return 'ผูกชื่อกับ $name';
  }

  @override
  String get contactWireSheetBody =>
      'เลือกชื่อที่พิมพ์ไว้ในรายการหารที่เป็นคนนี้ — หนี้ที่ใช้ชื่อนั้นจะผูกกับผู้ติดต่อนี้';

  @override
  String get contactWireSearch => 'ค้นหาชื่อ';

  @override
  String contactWireCount(int count) {
    return '$count รายการ';
  }

  @override
  String contactWireSave(int count) {
    return 'ผูก $count ชื่อ';
  }

  @override
  String contactWireDone(int count, String name) {
    return 'ผูก $count รายการกับ $name แล้ว';
  }

  @override
  String get contactArchive => 'เก็บถาวร';

  @override
  String get contactArchiveHint => 'ซ่อนจากตัวเลือก ข้อมูลเดิมยังอยู่';

  @override
  String get contactRestore => 'กู้คืน';

  @override
  String get contactDebts => 'หนี้กับคนนี้';

  @override
  String contactDeleteTitle(String name) {
    return 'ลบ $name?';
  }

  @override
  String get contactDeleteBody =>
      'รายการหารและหนี้ที่อ้างถึงคนนี้จะเก็บชื่อไว้เป็นข้อความแทน';

  @override
  String contactDeleted(String name) {
    return 'ลบ $name แล้ว';
  }

  @override
  String get contactLinkCreateTitle => 'เพิ่มผู้ติดต่อที่เชื่อมบัญชี';

  @override
  String get contactLinkExistingTitle => 'เชื่อมผู้ติดต่อ';

  @override
  String get contactLinkSave => 'เชื่อมและบันทึก';

  @override
  String contactLinkBannerNew(String name) {
    return 'บันทึกแล้วจะสร้างผู้ติดต่อใหม่ที่เชื่อมกับ $name';
  }

  @override
  String contactLinkBannerExisting(String name) {
    return 'บันทึกแล้วจะเชื่อมผู้ติดต่อนี้กับ $name';
  }

  @override
  String get debtsOwedToMe => 'ลูกหนี้';

  @override
  String get debtsIOwe => 'เจ้าหนี้';

  @override
  String get debtsEven => 'เคลียร์แล้ว';

  @override
  String get debtsSearchHint => 'ค้นหาชื่อ';

  @override
  String get debtsStatusAll => 'ทั้งหมด';

  @override
  String get debtsEmptyMessage =>
      'จดว่าใครเป็นลูกหนี้ ใครเป็นเจ้าหนี้ — หรือหารบิลจากรายการ';

  @override
  String get debtsNoMatch => 'ไม่พบคนที่ค้นหา';

  @override
  String get debtsPersonAddContact => 'เพิ่มผู้ติดต่อ';

  @override
  String get debtsPersonAddContactHint =>
      'เพิ่มชื่อนี้ในผู้ติดต่อที่มีอยู่แล้ว หรือสร้างผู้ติดต่อใหม่';

  @override
  String debtsPersonLinked(int count, String name) {
    return 'ผูก $count รายการกับ $name แล้ว';
  }

  @override
  String get debtsPersonOpenContact => 'ดูผู้ติดต่อ';

  @override
  String get debtPay => 'จ่ายคืน';

  @override
  String get debtCounterpartyRequired => 'ใส่ชื่อคนก่อน';

  @override
  String get debtDirectionOwedToMe => 'จดให้ยืม';

  @override
  String get debtDirectionIOwe => 'จดยืมมา';

  @override
  String get projectStatusActive => 'กำลังดำเนินการ';

  @override
  String get projectStatusCompleted => 'เสร็จสิ้น';

  @override
  String get projectStatusCancelled => 'ยกเลิก';

  @override
  String get projectStatusArchived => 'เก็บถาวร';

  @override
  String get projectsStatusLabel => 'สถานะ';

  @override
  String get projectsSearchHint => 'ค้นหาอีเวนต์';

  @override
  String get projectsSortName => 'ชื่อ';

  @override
  String get projectsEmptyTitle => 'ยังไม่มีอีเวนต์';

  @override
  String get projectsEmptyMessage =>
      'รวมรายจ่ายของทริปหรืองานไว้ที่เดียว แล้วเคลียร์ยอดกับเพื่อนตอนจบ';

  @override
  String get projectsNoMatch => 'ไม่พบอีเวนต์ที่ค้นหา';

  @override
  String get projectNewTitle => 'อีเวนต์ใหม่';

  @override
  String get projectNameRequired => 'ต้องใส่ชื่อ';

  @override
  String get projectIconLabel => 'ไอคอนอีเวนต์';

  @override
  String projectStatusLockTitle(String status) {
    return 'เปลี่ยนเป็น $status?';
  }

  @override
  String get projectStatusLockBody =>
      'อีเวนต์จะถูกล็อก — เพิ่มหรือแก้รายการไม่ได้จนกว่าจะเปิดอีกครั้ง';

  @override
  String projectStatusChanged(String status) {
    return 'เปลี่ยนสถานะเป็น $status แล้ว';
  }

  @override
  String get projectLockedCompleted => 'เสร็จสิ้นแล้ว — เพิ่มรายการไม่ได้';

  @override
  String get projectLockedCancelled =>
      'ยกเลิกแล้ว — เพิ่ม แก้ หรือลบรายการไม่ได้';

  @override
  String get projectLockedArchived => 'เก็บถาวรแล้ว — อ่านอย่างเดียว';

  @override
  String projectDeleteTitle(String name) {
    return 'ลบ $name?';
  }

  @override
  String get projectDeleted => 'ลบอีเวนต์แล้ว';

  @override
  String get projectTxEmpty => 'ยังไม่มีรายการในอีเวนต์';

  @override
  String get projectTxNoMatch => 'ไม่พบรายการที่ค้นหา';

  @override
  String get projectTxDelete => 'ลบรายการ';

  @override
  String get projectTxDeleteTitle => 'ลบรายการนี้?';

  @override
  String get projectResolveAmount => 'ยอด';

  @override
  String get projectResolveCategory => 'หมวดหมู่ (ไม่บังคับ)';

  @override
  String get projectResolveCategoryNone => 'ไม่ระบุหมวด';

  @override
  String get projectMembersTitle => 'สมาชิก';

  @override
  String get projectMembersPending => 'รอตอบรับ';

  @override
  String get projectMembersLeft => 'ออกแล้ว';

  @override
  String get projectRoleOwner => 'เจ้าของ';

  @override
  String get projectRoleMember => 'สมาชิก';

  @override
  String get projectRoleViewer => 'ดูอย่างเดียว';

  @override
  String get projectMemberMakeViewer => 'ให้ดูได้อย่างเดียว';

  @override
  String get projectMemberMakeContributor => 'ให้แก้ไขได้ (สมาชิก)';

  @override
  String get projectMemberRoleChanged => 'เปลี่ยนสิทธิ์แล้ว';

  @override
  String get projectMemberLinked => 'มีบัญชีในแอป';

  @override
  String get projectMemberAdHoc => 'ไม่มีบัญชีในแอป';

  @override
  String get projectMembersInvite => 'เชิญสมาชิก';

  @override
  String get projectLeave => 'ออกจากอีเวนต์';

  @override
  String projectLeaveTitle(String name) {
    return 'ออกจาก $name?';
  }

  @override
  String get projectLeaveBody =>
      'คุณจะไม่เห็นอีเวนต์นี้อีก จนกว่าจะได้รับเชิญใหม่';

  @override
  String get projectLeft => 'ออกจากอีเวนต์แล้ว';

  @override
  String get projectMemberRemove => 'นำออกจากอีเวนต์';

  @override
  String get projectMemberBindContact => 'ผูกกับผู้ติดต่อของฉัน';

  @override
  String get projectMemberAddContact => 'เพิ่มเข้าผู้ติดต่อของฉัน';

  @override
  String get projectMemberUnbindContact => 'เลิกผูกกับผู้ติดต่อของฉัน';

  @override
  String get projectMemberMyContact => 'ผู้ติดต่อของฉัน';

  @override
  String projectMemberContactBound(String name) {
    return 'ผูกกับ $name แล้ว';
  }

  @override
  String projectMemberContactAdded(String name) {
    return 'เพิ่ม $name เข้าผู้ติดต่อแล้ว';
  }

  @override
  String get projectMemberContactUnbound => 'เลิกผูกแล้ว';

  @override
  String projectMemberRemoveTitle(String name) {
    return 'นำ $name ออก?';
  }

  @override
  String get projectMemberRemoved => 'นำออกแล้ว';

  @override
  String get projectMemberTransfer => 'โอนความเป็นเจ้าของ';

  @override
  String projectMemberTransferTitle(String name) {
    return 'โอนให้ $name?';
  }

  @override
  String projectMemberTransferBody(String name) {
    return '$name จะเป็นเจ้าของ คุณจะเป็นสมาชิกธรรมดา';
  }

  @override
  String get projectMemberTransferred => 'โอนความเป็นเจ้าของแล้ว';

  @override
  String get projectMemberTransferNeedsAccount =>
      'โอนได้เฉพาะสมาชิกที่มีบัญชีในแอป';

  @override
  String get projectAddMemberName => 'ชื่อ';

  @override
  String get projectAddMemberNameRequired => 'ต้องใส่ชื่อ';

  @override
  String get projectAddMemberEmail => 'อีเมล (ไม่บังคับ)';

  @override
  String get projectAddMemberEmailHint =>
      'ใส่อีเมลเพื่อเชิญผู้ใช้ในแอป | เว้นว่าง = สมาชิกที่ไม่มีบัญชี';

  @override
  String get projectAddMemberFromContacts => 'เลือกจากผู้ติดต่อ';

  @override
  String get projectAddMemberSubmit => 'เพิ่ม';

  @override
  String projectAddMemberAdded(String name) {
    return 'เพิ่ม $name แล้ว';
  }

  @override
  String get projectTxPaidBy => 'ใครจ่าย';

  @override
  String get projectTxAddTag => 'แท็กใหม่';

  @override
  String get projectTxTagHint => 'ชื่อแท็ก';

  @override
  String get projectTxSplitMember => 'ใคร';

  @override
  String get settingsThemeMint => 'มิ้นต์';

  @override
  String get settingsThemeSweet => 'สวีท';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsFontSample => 'ตัวอย่าง ภาษาไทย ABC 123';

  @override
  String get notificationsTitle => 'การแจ้งเตือน';

  @override
  String get notificationsEmptyTitle => 'ไม่มีการแจ้งเตือน';

  @override
  String get notificationsEmptyMessage =>
      'ความเคลื่อนไหวจากคนที่ใช้ร่วมกันจะแสดงที่นี่';

  @override
  String get notificationsEmptyUnread => 'ไม่มีที่ยังไม่อ่าน';

  @override
  String get notificationsSomeone => 'มีคน';

  @override
  String notifSplitCreated(String actor) {
    return '$actor หารบิลกับคุณ';
  }

  @override
  String notifProjectTxForYou(String actor) {
    return '$actor บันทึกรายการอีเวนต์ให้คุณ';
  }

  @override
  String notifProjectTxChanged(String actor) {
    return '$actor แก้ไขรายการในอีเวนต์';
  }

  @override
  String notifProjectInvite(String actor, String project) {
    return '$actor ชวนคุณเข้าอีเวนต์ $project';
  }

  @override
  String notifContactLink(String actor) {
    return '$actor ขอเชื่อมเป็นผู้ติดต่อ';
  }

  @override
  String get notifUnknown => 'การแจ้งเตือน';

  @override
  String get notifAccepted => 'ตอบรับแล้ว | แตะเพื่อเปิด';

  @override
  String get notifRejectTitle => 'ปฏิเสธคำขอนี้?';

  @override
  String get notifRejectBody => 'อีกฝ่ายจะไม่ได้รับแจ้งว่าคุณปฏิเสธ';

  @override
  String get notifHidden => 'ซ่อนแล้ว';

  @override
  String get notifGroupProjects => 'อีเวนต์';

  @override
  String get notifGroupRequests => 'คำเชิญและคำขอ';

  @override
  String get notifTypeSplitCreated => 'มีคนแชร์บิลกับฉัน';

  @override
  String get notifTypeProjectTxForYou => 'มีคนบันทึกรายการอีเวนต์ให้ฉัน';

  @override
  String get notifTypeProjectTxChanged => 'มีการแก้ไขรายการในอีเวนต์';

  @override
  String get notifTypeProjectAdded => 'ถูกเพิ่มเข้าอีเวนต์';

  @override
  String get notifActionCopyToBook => 'บันทึกเข้าบัญชีส่วนตัว';

  @override
  String get notifActionUpdateCopy => 'อัปเดตตาม';

  @override
  String get notifActionSkip => 'ข้าม';

  @override
  String get notifActionDone => 'ทำแล้ว | แตะเพื่อเปิด';

  @override
  String notifProjectAdded(String actor, String project) {
    return '$actor เพิ่มคุณเข้าอีเวนต์ $project';
  }

  @override
  String get notifSettingsSaveFailed => 'บันทึกไม่ได้ — เปลี่ยนกลับแล้ว';

  @override
  String get profileUsernameLocked => 'เปลี่ยนชื่อผู้ใช้ไม่ได้';

  @override
  String homeUpcomingInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'อีก $days วัน',
      one: 'พรุ่งนี้',
      zero: 'วันนี้',
    );
    return '$_temp0';
  }

  @override
  String get homeNoTxYet => 'ยังไม่มีรายการ';

  @override
  String get homeAddFirstTx => 'เพิ่มรายการแรก';

  @override
  String get homeAssets => 'ทรัพย์สิน';

  @override
  String get homeLiabilities => 'หนี้สิน';

  @override
  String get homeIncome => 'รายรับ';

  @override
  String get homeExpense => 'รายจ่าย';

  @override
  String get homeLeftOver => 'คงเหลือ';

  @override
  String get homeVsPrevMonth => 'รายจ่ายเทียบเดือนก่อน';

  @override
  String homeComingUpWindow(int days) {
    return '$days วัน';
  }

  @override
  String homeOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'เลย $days วัน',
      one: 'เลย 1 วัน',
    );
    return '$_temp0';
  }

  @override
  String get homeCardDue => 'ชำระบัตร';

  @override
  String get homeWhereMoneyWent => 'เงินไปไหน';

  @override
  String get homeOther => 'อื่นๆ';

  @override
  String get homeUncategorized => 'ไม่ระบุหมวด';

  @override
  String get homeNoExpense => 'เดือนนี้ยังไม่มีรายจ่าย';

  @override
  String get homeTrend => 'รับ vs จ่าย 6 เดือน';

  @override
  String homeBudgetsUsed(String pct) {
    return 'ใช้ไป $pct%';
  }

  @override
  String homeBudgetsOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เกินงบ $count หมวด',
    );
    return '$_temp0';
  }

  @override
  String get homeBudgetsNone => 'ยังไม่ตั้งงบ';

  @override
  String get homeDebtsNone => 'ไม่มีหนี้ค้าง';

  @override
  String homeGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เป้าหมาย',
    );
    return '$_temp0';
  }

  @override
  String get homeGoalsNone => 'ยังไม่มีเป้า';

  @override
  String get homeLoadError => 'โหลดแดชบอร์ดไม่สำเร็จ';

  @override
  String get transactionsFilterType => 'ประเภท';

  @override
  String get transactionsFilterRange => 'ช่วงเวลา';

  @override
  String get transactionsFilterAccount => 'กระเป๋า';

  @override
  String get transactionsFilterCategory => 'หมวด';

  @override
  String get transactionsFilterTag => 'แท็ก';

  @override
  String get transactionsSortNewest => 'ล่าสุด';

  @override
  String get transactionsSortOldest => 'เก่าสุด';

  @override
  String get transactionsSortAmountHigh => 'ยอดมากสุด';

  @override
  String get transactionsSortAmountLow => 'ยอดน้อยสุด';

  @override
  String get transactionsNoMatch => 'ไม่มีรายการตามตัวกรองนี้';

  @override
  String get transactionsClearFilters => 'ล้างตัวกรอง';

  @override
  String get txDetailSourceProject => 'อีเวนต์';

  @override
  String get txDeleted => 'ลบรายการแล้ว';

  @override
  String get txSplitEqually => 'หารเท่ากัน';

  @override
  String get txSplitAddPerson => 'เพิ่มคน';

  @override
  String get txSplitRemove => 'นำออก';

  @override
  String get txSplitExceeds => 'ยอดหารรวมเกินยอดรายการ';

  @override
  String get txTransferNeedsTo => 'เลือกกระเป๋าปลายทาง';

  @override
  String get txTransferSameWallet =>
      'กระเป๋าต้นทางกับปลายทางต้องไม่ใช่อันเดียวกัน';

  @override
  String get authTagline => 'จดรายรับรายจ่าย หารบิลกับเพื่อน';

  @override
  String get authOr => 'หรือ';

  @override
  String get authContinueWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get authComingSoon => 'เร็ว ๆ นี้';

  @override
  String get authRegisterSectionAccount => 'บัญชีสำหรับเข้าสู่ระบบ';

  @override
  String get authRegisterSectionProfile => 'เกี่ยวกับคุณ';

  @override
  String get authRegisterUsernameHint => 'a-z 0-9 _ - | 3–50 ตัว';

  @override
  String get authRegisterPasswordHint => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get authRegisterEmailHint => 'ใช้ให้เพื่อนเชื่อมบัญชีกับคุณได้';

  @override
  String get accountsSummaryNet => 'ยอดสุทธิของฉัน';

  @override
  String accountsSummaryWalletCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count กระเป๋า',
    );
    return '$_temp0';
  }

  @override
  String accountsArchivedLink(int count) {
    return 'กระเป๋าที่เก็บถาวร ($count)';
  }

  @override
  String get accountsArchivedTitle => 'กระเป๋าที่เก็บถาวร';

  @override
  String get accountsArchivedEmpty => 'ไม่มีกระเป๋าที่เก็บถาวร';

  @override
  String get accountRestore => 'กู้คืน';

  @override
  String accountRestored(String name) {
    return 'กู้คืน $name แล้ว';
  }

  @override
  String get accountArchiveHasMembers =>
      'กระเป๋าที่ยังมีสมาชิกอื่นเก็บถาวรไม่ได้ — นำสมาชิกออกก่อน';

  @override
  String get accountArchived => 'เก็บกระเป๋าแล้ว';

  @override
  String get txSplitOver => 'ยอดหารรวมเกินยอดรายการ';

  @override
  String get moreDebts => 'หนี้สิน';

  @override
  String get moreNotifications => 'การแจ้งเตือน';

  @override
  String get moreBudgets => 'งบประมาณ';

  @override
  String get moreSavingGoals => 'เป้าหมายการออม';

  @override
  String get moreCategoriesDesc => 'จัดกลุ่มรายการ';

  @override
  String get moreTagsDesc => 'ติดป้ายให้ค้นง่าย';

  @override
  String get moreContactsDesc => 'คนที่ใช้ในบิลและหนี้';

  @override
  String get moreProjectsDesc => 'ทริปและกิจกรรมที่หารเงิน';

  @override
  String get moreDebtsDesc => 'เงินยืมและเงินที่ติดค้าง';

  @override
  String get moreBudgetsDesc => 'คุมรายจ่ายรายเดือน';

  @override
  String get moreSavingGoalsDesc => 'ออมเพื่อสิ่งที่อยากได้';

  @override
  String get moreChipOverBudget => 'เกินงบ';

  @override
  String get moreChipNearBudget => 'ใกล้เต็มงบ';

  @override
  String get moreChipGoalReached => 'ถึงเป้าแล้ว';

  @override
  String get moreChipNearGoal => 'ใกล้ถึงเป้า';

  @override
  String moreChipDueSoon(int count) {
    return 'ใกล้ถึงกำหนด $count';
  }

  @override
  String moreChipReceivable(String amount) {
    return 'รอรับ $amount';
  }

  @override
  String moreChipPayable(String amount) {
    return 'ต้องจ่าย $amount';
  }

  @override
  String moreChipOpenEvents(int count) {
    return 'เปิดอยู่ $count';
  }

  @override
  String moreChipPending(int count) {
    return 'รอยืนยัน $count';
  }

  @override
  String moreChipUnread(int count) {
    return 'ยังไม่อ่าน $count';
  }

  @override
  String get categoriesTitle => 'หมวดหมู่';

  @override
  String get categoriesEmptyTitle => 'ยังไม่มีหมวดหมู่';

  @override
  String get categoriesEmptyMessage => 'เพิ่มหมวดหมู่แรกเพื่อจัดระเบียบรายการ';

  @override
  String get categoryDetailNotFound => 'ไม่พบหมวดหมู่';

  @override
  String get categoryDetailNotFoundMessage => 'หมวดหมู่นี้อาจถูกลบไปแล้ว';

  @override
  String get categoriesLimitReached =>
      'ถึงขีดจำกัด 100 หมวดหมู่แล้ว ลบหนึ่งรายการก่อนเพิ่มใหม่';

  @override
  String get categoryTypeExpense => 'รายจ่าย';

  @override
  String get categoryTypeIncome => 'รายรับ';

  @override
  String get categoryHiddenFromReport => 'ซ่อนจากรายงาน';

  @override
  String get categoryFormTitleNew => 'หมวดหมู่ใหม่';

  @override
  String get categoryFormNameRequired => 'จำเป็น';

  @override
  String get categoryFormNameTooLong => 'สูงสุด 100 ตัวอักษร';

  @override
  String get categoryFormNameDuplicate =>
      'มีหมวดหมู่ในระดับนี้ที่ใช้ชื่อนี้แล้ว';

  @override
  String get categoryFormParentLabel => 'หมวดหลัก';

  @override
  String get categoryFormParentNone => 'ไม่มี';

  @override
  String get categoryFormIconLabel => 'ไอคอน';

  @override
  String get categoryFormColorLabel => 'สี';

  @override
  String get categoryFormIncludeInReportLabel => 'รวมในรายงาน';

  @override
  String get categoryFormIncludeInReportHelper =>
      'ปิด = รายการในหมวดนี้จะไม่ถูกนับในยอดรวมและกราฟ';

  @override
  String get categoriesAddNew => 'เพิ่มหมวดหมู่';

  @override
  String get categoriesSearchHint => 'ค้นหาหมวดหมู่';

  @override
  String get categoriesSearchNoMatch => 'ไม่พบหมวดที่ค้นหา';

  @override
  String get categoryDelete => 'ลบหมวดหมู่';

  @override
  String categoryDeleteTitle(String name) {
    return 'ลบ \"$name\"?';
  }

  @override
  String get categoryDeleteBody => 'หมวดย่อยจะย้ายขึ้นไปอยู่ใต้หมวดแม่';

  @override
  String categoryDeleteTxImpact(int count) {
    return 'รายการ $count รายการจะกลายเป็น ไม่ระบุหมวด';
  }

  @override
  String categoryDeleteBudgetImpact(int count) {
    return 'งบประมาณของหมวดนี้ $count รายการจะถูกลบด้วย';
  }

  @override
  String categoryDeletedResult(String name) {
    return 'ลบ \"$name\" แล้ว';
  }

  @override
  String get commonDelete => 'ลบ';

  @override
  String get budgetDeleteThis => 'ลบงบประมาณนี้';

  @override
  String get savingGoalDeleteThis => 'ลบเป้าหมายนี้';

  @override
  String get contactDeleteThis => 'ลบผู้ติดต่อนี้';

  @override
  String get projectDeleteThis => 'ลบอีเวนต์นี้';

  @override
  String get transactionDeleteThis => 'ลบรายการนี้';

  @override
  String get transactionDeleteConsequence =>
      'ลบถาวร | ยอดในกระเป๋ากลับเป็นเหมือนก่อนบันทึก';

  @override
  String get categoriesReorderEnter => 'จัดลำดับ';

  @override
  String get categoriesReorderSave => 'บันทึก';

  @override
  String get categoriesUndo => 'ย้อนกลับ';

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
  String get tagsSearchHint => 'ค้นหาแท็ก';

  @override
  String get tagsNoMatch => 'ไม่พบแท็กที่ค้นหา';

  @override
  String get tagsSortUsage => 'ใช้บ่อย';

  @override
  String get tagsSelectAll => 'เลือกทั้งหมดที่แสดง';

  @override
  String get tagsBulkColor => 'เปลี่ยนสี';

  @override
  String get tagsBulkIcon => 'เปลี่ยนไอคอน';

  @override
  String get tagsFiltersClearedForError => 'ล้างตัวกรองเพื่อแสดงแท็กที่ต้องแก้';

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
  String get tagDeleteConfirmAction => 'ลบ';

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
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsChangePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get settingsTheme => 'ธีม';

  @override
  String get settingsAppearance => 'การแสดงผล';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsAppVersion => 'เวอร์ชันแอป';

  @override
  String get settingsLogout => 'ออกจากระบบ';

  @override
  String get settingsLogoutDialogTitle => 'ออกจากระบบ ChubiPocket?';

  @override
  String get settingsLogoutDialogBody => 'ฉันจะกลับไปที่หน้าเข้าสู่ระบบ';

  @override
  String get editProfileTitle => 'แก้ไขโปรไฟล์';

  @override
  String get editProfileDisplayNameLabel => 'ชื่อที่แสดง';

  @override
  String get editProfileUsernameLabel => 'ชื่อผู้ใช้';

  @override
  String get editProfileEmailLabel => 'อีเมล';

  @override
  String get editProfileEmailInvalid => 'กรุณากรอกอีเมลให้ถูกต้อง';

  @override
  String get editProfileEmailTaken => 'อีเมลนี้ถูกใช้กับบัญชีอื่นแล้ว';

  @override
  String get editProfileSnackSuccess => 'อัปเดตโปรไฟล์แล้ว';

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
  String get changePasswordSnackSuccess => 'อัปเดตรหัสผ่านแล้ว';

  @override
  String get modeLight => 'สว่าง';

  @override
  String get modeDark => 'มืด';

  @override
  String get modeSystem => 'ระบบ';

  @override
  String get amountLabel => 'จำนวนเงิน';

  @override
  String get transactionFormTitleNew => 'รายการใหม่';

  @override
  String get quickSave => 'บันทึก';

  @override
  String get quickSaved => 'บันทึกแล้ว';

  @override
  String get txHeroTitleHint => 'ค่าอะไร?';

  @override
  String get txDetailRepaymentBanner =>
      'รายการนี้บันทึกจากการจ่ายหนี้ แก้ไขไม่ได้ แต่ลบได้ (ยอดที่จ่ายคืนของหนี้จะลดลงตาม)';

  @override
  String txDetailDeleteRepaymentBody(String amount) {
    return 'ยอดที่จ่ายคืนของหนี้นี้จะลดลง $amount';
  }

  @override
  String notifSplitAmountChanged(
    String who,
    String what,
    String from,
    String to,
  ) {
    return '$who แก้ยอดหาร $what: $from → $to';
  }

  @override
  String notifSplitRemovedYou(String who, String what) {
    return '$who เอาคุณออกจากการหาร $what';
  }

  @override
  String txSplitStatusOverpaidToThem(String amount) {
    return 'จ่ายเกิน $amount | ต้องคืนให้เขา';
  }

  @override
  String txSplitStatusOverpaidByMe(String amount) {
    return 'จ่ายเกิน $amount | เขาต้องคืน';
  }

  @override
  String txSplitRepaidSoFar(String amount) {
    return 'คืนแล้ว $amount';
  }

  @override
  String get txSplitErrorContact => 'ผู้ติดต่อนี้ใช้ไม่ได้แล้ว';

  @override
  String get txSplitStatusPaid => '✓ จ่ายแล้ว';

  @override
  String get txSplitStatusRepaid => '✓ คืนแล้ว';

  @override
  String txSplitStatusAwaiting(String amount) {
    return 'รอคืน $amount';
  }

  @override
  String txSplitStatusToPay(String amount) {
    return 'ต้องคืน $amount';
  }

  @override
  String txSplitStatusPartPaid(String paid, String total) {
    return 'จ่ายแล้ว $paid จาก $total';
  }

  @override
  String txSplitStatusPartRepaid(String paid, String total) {
    return 'คืนแล้ว $paid จาก $total';
  }

  @override
  String get txSplitStatusCancelled => 'ยกเลิก';

  @override
  String txDetailMetaRecordedBy(String name) {
    return 'ผู้บันทึก $name';
  }

  @override
  String get txDetailCreatedAt => 'บันทึกเมื่อ';

  @override
  String get txDetailUpdatedAt => 'แก้ไขล่าสุด';

  @override
  String tagPickerCreateNamed(String name) {
    return 'สร้าง “$name”';
  }

  @override
  String get txNoteAddHint => 'เช่น ซื้อที่ไหน กับใคร';

  @override
  String get bgNoteHint => 'เช่น ทำไมตั้งเพดานนี้ หรืออยากลดรายจ่ายอะไร';

  @override
  String get projectNoteHint => 'เช่น ที่พัก ข้อตกลงในกลุ่ม หรือบัญชีสำหรับโอน';

  @override
  String get recurringNoteHint => 'เช่น เลขที่สัญญา รอบตัดบัตร หรือวิธีจ่าย';

  @override
  String get fpGoalsNoteHint => 'เช่น ออมไว้ทำอะไร หรือแผนที่จะออม';

  @override
  String get categoryNoteHint => 'เช่น รายการแบบไหนควรอยู่หมวดนี้';

  @override
  String get debtNoteHint => 'เช่น ยืมไปทำอะไร';

  @override
  String get quickEventNone => 'ไม่ได้เลือก';

  @override
  String get quickUnsavedTitle => 'ยังไม่ได้บันทึก';

  @override
  String get quickUnsavedMessage => 'ถ้าปิดตอนนี้ รายการนี้จะหายไป';

  @override
  String get quickDiscardEntry => 'ยกเลิกรายการนี้';

  @override
  String get txSplitIncompleteTitle => 'มีแถวหารที่ยังไม่ครบ';

  @override
  String txSplitIncompleteNoName(String amount) {
    return '$amount — ยังไม่ใส่ชื่อ';
  }

  @override
  String txSplitIncompleteNoAmount(String name) {
    return '$name — ยังไม่ใส่จำนวน';
  }

  @override
  String get txSplitSkipIncomplete => 'บันทึกโดยไม่รวมแถวนี้';

  @override
  String get txTagCreateFailed => 'สร้างแท็กไม่สำเร็จ';

  @override
  String get quickFrom => 'จาก';

  @override
  String get quickTo => 'ไป';

  @override
  String get quickSwap => 'สลับต้นทางกับปลายทาง';

  @override
  String get quickPickWallet => 'เลือกกระเป๋า';

  @override
  String get quickAmountRequired => 'ใส่ยอดเงินก่อน';

  @override
  String get quickDiscardConfirm => 'ทิ้ง';

  @override
  String get quickAddToEvent => 'เพิ่มเข้าอีเวนต์';

  @override
  String get quickEventLabel => 'อีเวนต์';

  @override
  String quickEventNewNamed(String name) {
    return 'ใหม่: $name';
  }

  @override
  String get quickEventRemove => 'ไม่เพิ่มเข้าอีเวนต์';

  @override
  String get quickEventNameLabel => 'ชื่ออีเวนต์';

  @override
  String get quickEventNoneYet => 'ยังไม่มีอีเวนต์ที่เปิดอยู่';

  @override
  String get quickEventDefaultName => 'อีเวนต์';

  @override
  String get quickEventNeedsWallet => 'เพิ่มเข้าอีเวนต์ต้องเลือกกระเป๋า';

  @override
  String get pendingTitle => 'รอยืนยัน';

  @override
  String get pendingTooltip => 'รอยืนยัน';

  @override
  String get pendingImportSlip => 'นำเข้าสลิป';

  @override
  String get pendingTypeIt => 'พิมพ์เอง';

  @override
  String get pendingChatHint => 'เช่น กาแฟ 65';

  @override
  String get pendingChatSend => 'ส่ง';

  @override
  String get pendingChatClose => 'ปิด';

  @override
  String get pendingSelectAll => 'เลือกทั้งหมด';

  @override
  String get pendingSelectOne => 'เลือกรายการนี้';

  @override
  String pendingFilterAll(int count) {
    return 'ทั้งหมด $count';
  }

  @override
  String pendingFilterManual(int count) {
    return 'ใส่เอง $count';
  }

  @override
  String pendingFilterOthers(int count) {
    return 'จากคนอื่น $count';
  }

  @override
  String pendingResult(int done, int failed) {
    return 'บันทึกแล้ว $done | ค้าง $failed';
  }

  @override
  String get pendingEmptyTitle => 'ไม่มีรายการรอยืนยัน';

  @override
  String get pendingEmptyMessage => 'จดไว้ก่อนแล้วค่อยมายืนยันได้ที่นี่';

  @override
  String get pendingAdd => 'เพิ่มร่าง';

  @override
  String pendingSubmitSelected(int count) {
    return 'ยืนยันที่เลือก ($count)';
  }

  @override
  String pendingSubmittedCount(int count) {
    return 'บันทึก $count รายการแล้ว';
  }

  @override
  String get pendingSeeTransactions => 'ดูในรายการ';

  @override
  String get pendingUntitled => 'ไม่มีคำอธิบาย';

  @override
  String get pendingSourceManual => 'ใส่เอง';

  @override
  String get pendingSourceSplitPaid => 'จ่ายแล้ว';

  @override
  String get pendingSourceProject => 'อีเวนต์';

  @override
  String get pendingSourceOcr => 'สแกน';

  @override
  String get pendingSourceChat => 'แชท';

  @override
  String get pendingSourceOther => 'อื่นๆ';

  @override
  String pendingSavedCount(int count) {
    return 'เก็บเป็นร่าง $count รายการแล้ว';
  }

  @override
  String get pendingBatchHint =>
      'กรอกแค่ยอดก็พอ ที่เหลือค่อยเติมในหน้ารอยืนยัน';

  @override
  String get pendingAddRow => 'เพิ่มแถว';

  @override
  String pendingSaveAsDrafts(int count) {
    return 'เก็บเป็นร่าง $count รายการ';
  }

  @override
  String pendingSubmitAllNow(int count) {
    return 'ยืนยันเลยทั้ง $count รายการ';
  }

  @override
  String get pendingRemoveRow => 'ลบแถวนี้';

  @override
  String get pendingSavedAsDraft => 'เก็บเป็นร่างแล้ว | อยู่ในรอยืนยัน';

  @override
  String get pendingSaveDraft => 'บันทึกร่าง';

  @override
  String get pendingSubmitThis => 'ยืนยันรายการนี้';

  @override
  String get pendingEditTitle => 'แก้ร่าง';

  @override
  String get pendingDiscardTitle => 'ทิ้งร่างนี้?';

  @override
  String pendingDiscardSelectedTitle(int count) {
    return 'ทิ้ง $count ร่าง?';
  }

  @override
  String get pendingKeepAsDraft => 'เก็บเป็นร่าง';

  @override
  String pendingBlockMore(int count) {
    return '+ อีก $count รายการ';
  }

  @override
  String get pendingNotCounted => 'ยังไม่นับในยอดด้านล่าง';

  @override
  String get pendingErrMissingType => 'ต้องเลือกประเภทก่อนยืนยัน';

  @override
  String get pendingErrMissingAmount => 'ต้องใส่ยอดเงินก่อนยืนยัน';

  @override
  String get pendingErrMissingDate => 'ต้องเลือกวันที่ก่อนยืนยัน';

  @override
  String get pendingErrAccount =>
      'กระเป๋านี้ใช้ไม่ได้แล้ว เลือกใหม่หรือไม่ผูกกระเป๋า';

  @override
  String get pendingErrCategory => 'หมวดนี้ใช้ไม่ได้ เลือกหมวดใหม่';

  @override
  String get pendingErrCurrency => 'โอนข้ามสกุลเงินไม่ได้';

  @override
  String get pendingErrTag => 'มีแท็กที่ถูกลบไปแล้ว';

  @override
  String get pendingErrContact => 'ผู้ติดต่อในการหารถูกลบไปแล้ว';

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
  String get transactionFormCategoryLabel => 'หมวดหมู่';

  @override
  String get transactionFormCategoryNone => 'ไม่ระบุหมวด';

  @override
  String get transactionFormAmountLabel => 'จำนวนเงิน';

  @override
  String get transactionFormTagsLabel => 'แท็ก';

  @override
  String get transactionFormSave => 'บันทึก';

  @override
  String get transactionFormAccountNone => 'ไม่ระบุกระเป๋า';

  @override
  String get transactionFormAccountPickerTitle => 'เลือกกระเป๋า';

  @override
  String get transactionFormAccountPickerEmpty =>
      'ยังไม่มีกระเป๋าที่ใช้งาน เพิ่มกระเป๋าก่อน';

  @override
  String get transactionFormCategoryPickerNoneOption => 'ไม่ระบุหมวด';

  @override
  String get transactionFormCategoryPickerEmpty => 'ยังไม่มีหมวดประเภทนี้';

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
  String get transactionsListFilterAll => 'ทั้งหมด';

  @override
  String get transactionsListEmptyMessage =>
      'บันทึกรายรับรายจ่ายแรกของเดือนได้เลย';

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
  String get savingGoalCompletedLabel => 'ถึงเป้าแล้ว';

  @override
  String get savingGoalFormTitle => 'เป้าหมายใหม่';

  @override
  String get savingGoalFormIconLabel => 'ไอคอน';

  @override
  String get savingGoalFormNameRequired => 'จำเป็น';

  @override
  String get savingGoalFormTargetLabel => 'ยอดเป้าหมาย';

  @override
  String get savingGoalFormTargetInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get savingGoalFormDeadlineLabel => 'วันที่ครบกำหนด';

  @override
  String get savingGoalFormDeadlinePlaceholder => 'ไม่ระบุ';

  @override
  String get savingGoalDetailNotFound => 'ไม่พบเป้าหมาย';

  @override
  String get savingGoalDetailNotFoundMessage =>
      'เป้าหมายนี้อาจถูกลบหรือเก็บถาวรแล้ว';

  @override
  String get savingGoalDetailArchive => 'เก็บถาวร';

  @override
  String get savingGoalArchiveConfirmTitle => 'เก็บถาวรเป้าหมายนี้?';

  @override
  String get savingGoalArchiveConfirmAction => 'เก็บถาวร';

  @override
  String get savingGoalDeleteConfirmTitle => 'ลบเป้าหมายนี้?';

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
  String get budgetFormTitle => 'งบประมาณใหม่';

  @override
  String get budgetFormAmountInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get budgetDetailNotFound => 'ไม่พบงบประมาณ';

  @override
  String get budgetDetailNotFoundMessage =>
      'งบประมาณนี้อาจถูกลบหรือเก็บถาวรแล้ว';

  @override
  String get budgetDetailFallbackTitle => 'งบประมาณ';

  @override
  String get budgetDetailArchive => 'เก็บถาวร';

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
  String get projectFormPlannedInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

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
  String get walletReportScopeTitle => 'ในรายงานของฉัน';

  @override
  String get walletReportScopeNone => 'ไม่รวมในรายงาน';

  @override
  String get walletReportScopeOwn => 'เฉพาะที่ฉันจด';

  @override
  String get walletReportScopeAll => 'รวมในรายงาน';

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
      'กระเป๋านี้ยังมีสมาชิกคนอื่นอยู่ จึงเก็บถาวรหรือลบไม่ได้';

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
  String get quickCreateErrorTxNotFound =>
      'บางบิลที่เลือกไม่มีอยู่แล้ว ลองรีเฟรชแล้วเลือกใหม่';

  @override
  String get quickCreateErrorTxAlreadyInProject =>
      'บางบิลที่เลือกอยู่ในอีเวนต์อื่นแล้ว ลองรีเฟรชแล้วเลือกใหม่';

  @override
  String get quickCreateErrorValidation =>
      'ข้อมูลบางอย่างยังไม่ถูกต้อง ลองตรวจดูอีกครั้ง';

  @override
  String get transactionsSearchHint => 'ค้นหาคำอธิบาย | โน้ต | หมวด | กระเป๋า';

  @override
  String get accountAdjustBalanceNewDebtLabel => 'ยอดค้างชำระใหม่';

  @override
  String get accountAdjustBalanceDiffLabel => 'ส่วนต่าง';

  @override
  String accountAdjustBalanceWillCreate(String amount) {
    return 'ระบบจะสร้างรายการ \"ปรับยอด\" $amount ลงวันนี้';
  }

  @override
  String get accountIdentifiersTitle => 'เลขอ้างอิง';

  @override
  String get accountIdentifiersAdd => 'เพิ่มเลข';

  @override
  String get identifierKindBankAccount => 'เลขบัญชี';

  @override
  String get identifierKindPromptPay => 'พร้อมเพย์';

  @override
  String get identifierKindCard => 'บัตร';

  @override
  String get identifierKindOther => 'อื่น ๆ';

  @override
  String get identifierKindLabel => 'ชนิด';

  @override
  String get identifierBankLabel => 'ธนาคาร';

  @override
  String get identifierBankNone => 'ไม่ระบุ';

  @override
  String get identifierValueLabel => 'เลข';

  @override
  String get identifierValueTooShort => 'ต้องมีตัวเลขอย่างน้อย 4 ตัว';

  @override
  String get identifierValueTooLong => 'ยาวเกินไป';

  @override
  String get identifierDelete => 'ลบเลขนี้';

  @override
  String get walletErrorInvalidIdentifier => 'เลขบัญชีไม่ถูกต้อง';

  @override
  String get monthPickerTitle => 'เลือกเดือน';

  @override
  String get monthPickerThisMonth => 'เดือนนี้';

  @override
  String get monthPickerPrevYear => 'ปีก่อน';

  @override
  String get monthPickerNextYear => 'ปีถัดไป';

  @override
  String get monthPickerPrevMonth => 'เดือนก่อน';

  @override
  String get monthPickerNextMonth => 'เดือนถัดไป';

  @override
  String get appUpdateRequiredTitle => 'ต้องอัปเดตก่อนใช้งาน';

  @override
  String get appUpdateRequiredBody =>
      'แอปเวอร์ชันนี้เก่าเกินไปแล้ว ดาวน์โหลดเวอร์ชันใหม่เพื่อใช้งานต่อ';

  @override
  String get appUpdateDownload => 'ดาวน์โหลดเวอร์ชันใหม่';

  @override
  String get appUpdateNoLink => 'ยังไม่มีลิงก์ดาวน์โหลด — ติดต่อผู้ดูแล';

  @override
  String get appUpdateOpenFailed => 'เปิดลิงก์ดาวน์โหลดไม่ได้';

  @override
  String appUpdateBuildLine(int current, int required) {
    return 'เวอร์ชันนี้ build $current | ต้องการ $required ขึ้นไป';
  }

  @override
  String get appUpdateAvailable => 'มีเวอร์ชันใหม่';

  @override
  String get appUpdateAvailableAction => 'อัปเดต';

  @override
  String get transactionsEmptyMonthTitle => 'เดือนนี้ยังไม่มีรายการ';

  @override
  String get transactionsNoMatchMessage =>
      'ลองเปลี่ยนตัวกรอง หรือล้างตัวกรองเพื่อดูทั้งหมด';

  @override
  String get notifCopyUpdated => 'อัปเดตรายการของคุณแล้ว';

  @override
  String get homeTodoTitle => 'ต้องจัดการ';

  @override
  String get homeTodoPending => 'รอยืนยัน';

  @override
  String get homeTodoComingUp => 'กำลังจะถึง';

  @override
  String get transactionsFiltersTitle => 'ตัวกรอง';

  @override
  String get transactionsFiltersApply => 'ใช้ตัวกรอง';

  @override
  String get txPeriodMonth => 'เดือน';

  @override
  String get txPeriodWeek => 'สัปดาห์';

  @override
  String get txPeriodYear => 'ปี';

  @override
  String get txPeriodCustom => 'กำหนดเอง';

  @override
  String get txPeriodPrev => 'ช่วงก่อนหน้า';

  @override
  String get txPeriodNext => 'ช่วงถัดไป';

  @override
  String get transactionsEmptyPeriodTitle => 'ไม่มีรายการในช่วงนี้';

  @override
  String get commonMore => 'เพิ่มเติม';

  @override
  String get txShareMine => 'ส่วนของฉัน';

  @override
  String get txSplitAuthorOnly => 'เฉพาะคนที่บันทึกรายการนี้แก้การหารได้';

  @override
  String get quickCreateErrorNotBillable =>
      'รายการยอดยกมา / ปรับยอด เพิ่มเข้าอีเวนต์ไม่ได้';

  @override
  String get txEventRemove => 'เอาออกจากอีเวนต์';

  @override
  String get txEventSplitRepaid => 'มีคนจ่ายคืนแล้ว เอาเข้าอีเวนต์ไม่ได้';

  @override
  String txEventFailedAfterSave(String reason) {
    return 'บันทึกรายการแล้ว แต่เปลี่ยนอีเวนต์ไม่สำเร็จ: $reason';
  }

  @override
  String get txEventSplitCancelled =>
      'มีรายการหารที่ยกหนี้แล้ว เอาเข้าอีเวนต์ไม่ได้';

  @override
  String get txSplitExceedsShare => 'เกินส่วนของฉัน';

  @override
  String get accountsReorderSave => 'บันทึกลำดับ';

  @override
  String get accountsReorderDiscard => 'ยกเลิก';

  @override
  String get accountsEmptyTitle => 'ยังไม่มีกระเป๋า';

  @override
  String get accountsEmptyMessage =>
      'เพิ่มกระเป๋าแรก — เงินสด บัญชีธนาคาร หรือบัตร';

  @override
  String get accountsArchivedEmptyMessage =>
      'กระเป๋าที่เก็บถาวรจะอยู่ที่นี่ กู้คืนได้ทุกเมื่อ';

  @override
  String get txPeriodDay => 'วัน';

  @override
  String get txPeriodWeekHint =>
      'แตะวันไหนก็ได้ — ได้ทั้งสัปดาห์ (จันทร์ถึงอาทิตย์)';

  @override
  String quickEventCreateNamed(String name) {
    return 'สร้าง \"$name\"';
  }

  @override
  String get quickEventMembersInfo => 'คนที่หารด้วยจะถูกเพิ่มเป็นสมาชิกอีเวนต์';

  @override
  String get eventPickerTabOpen => 'เปิดอยู่';

  @override
  String get eventPickerTabClosed => 'ปิดแล้ว';

  @override
  String get txSplitInEventHelper =>
      'การหารนี้จะอยู่ในอีเวนต์ แก้ได้ที่หน้าอีเวนต์';

  @override
  String get txSplitFromMyShare => 'หารจากส่วนของฉัน';

  @override
  String get categoryPickerTitle => 'เลือกหมวดหมู่';

  @override
  String get categoryPickerSearchHint => 'ค้นหาหมวดหมู่';

  @override
  String get categoryPickerNoMatch => 'ไม่พบหมวดหมู่ที่ตรงกัน';

  @override
  String get tagPickerSearchHint => 'ค้นหา หรือพิมพ์ชื่อแท็กใหม่';

  @override
  String get tagPickerEmpty => 'ยังไม่มีแท็ก — สร้างได้ที่หน้าแท็ก';

  @override
  String get tagPickerNoMatch => 'ไม่พบแท็กที่ตรงกัน';

  @override
  String get contactsSortRecent => 'ใช้ล่าสุด';

  @override
  String get contactsSortNameAsc => 'ชื่อ ก→ฮ';

  @override
  String get contactsSortNameDesc => 'ชื่อ ฮ→ก';

  @override
  String get contactArchiveConfirmTitle => 'เก็บถาวรผู้ติดต่อนี้?';

  @override
  String get tagsBulkDeleteConfirmBody =>
      'แท็กที่เลือกจะถูกลบเมื่อกดบันทึก และจะเอาออกจากรายการที่ใช้แท็กนั้น';

  @override
  String get contactLinked => 'ผูกแล้ว';

  @override
  String get contactsLinkLabel => 'การผูก';

  @override
  String get contactsLinkUnlinked => 'ยังไม่ผูก';

  @override
  String get contactsNoFilterMatch => 'ไม่มีผู้ติดต่อตามตัวกรองนี้';

  @override
  String get contactsNoFilterMatchMessage => 'ลองเปลี่ยนตัวกรอง';

  @override
  String get contactsNoMatchFilterMessage => 'ลองคำค้นอื่น หรือเปลี่ยนตัวกรอง';

  @override
  String get walletInviteFromContacts => 'เชิญจากผู้ติดต่อ';

  @override
  String get walletInvitePickTitle => 'เชิญเข้ากระเป๋านี้';

  @override
  String get walletInvitePickHint =>
      'เชิญได้เฉพาะผู้ติดต่อที่ลิงก์บัญชีแอปแล้ว';

  @override
  String get walletInvitePickEmpty =>
      'ไม่มีผู้ติดต่อที่ลิงก์บัญชีให้เชิญแล้ว — ลิงก์ผู้ติดต่อกับบัญชีแอปของเขาก่อน (ที่หน้าผู้ติดต่อ)';

  @override
  String get walletErrorContactNotFound => 'ไม่พบผู้ติดต่อนี้แล้ว';

  @override
  String get walletErrorContactArchived =>
      'ผู้ติดต่อนี้ถูกเก็บถาวรอยู่ กู้คืนก่อนจึงจะเชิญได้';

  @override
  String get walletErrorContactNotLinked =>
      'ผู้ติดต่อนี้ยังไม่ได้ลิงก์บัญชีแอป';

  @override
  String get walletErrorInviteInvalid => 'ส่งคำเชิญไม่สำเร็จ ลองใหม่อีกครั้ง';

  @override
  String get reorderMoveUp => 'เลื่อนขึ้น';

  @override
  String get reorderMoveDown => 'เลื่อนลง';

  @override
  String get reorderOutdent => 'ออกหนึ่งระดับ';

  @override
  String get reorderIndent => 'เข้าหนึ่งระดับ';

  @override
  String categoriesReorderUnder(String name) {
    return 'ใต้ $name';
  }

  @override
  String get categoriesReorderTopLevel => 'หมวดหลัก';

  @override
  String get categoriesReorderTapHint =>
      'แตะแถวเพื่อเลือกแล้วใช้ลูกศร หรือลากที่ ⠿';

  @override
  String get categoryErrorMaxDepth =>
      'หมวดหมู่ซ้อนกันได้ไม่เกิน 3 ระดับ (นับหมวดย่อยของหมวดนี้ด้วย)';

  @override
  String get accountsReorderTapHint =>
      'แตะเพื่อเลือกแล้วใช้ลูกศร หรือลากที่ ⠿ ลำดับนี้เป็นของคุณคนเดียว ไม่กระทบสมาชิกกระเป๋าแชร์';

  @override
  String get categorySectionSettings => 'การตั้งค่า';

  @override
  String get dayPickerLastDay => 'วันสุดท้ายของเดือน';

  @override
  String get dayPickerNone => 'ไม่ระบุ';

  @override
  String dayPickerEveryMonth(int day) {
    return 'วันที่ $day ของทุกเดือน';
  }

  @override
  String get txSplitMe => 'ส่วนของฉัน';

  @override
  String txSplitLeft(String amount) {
    return 'ยังไม่ได้แบ่ง $amount';
  }

  @override
  String get txSplitBalanced => 'แบ่งครบแล้ว';

  @override
  String txSplitOverBy(String amount) {
    return 'แบ่งเกิน $amount';
  }

  @override
  String get txSplitUnbalanced =>
      'ยอดที่แบ่งยังไม่ลงตัว — ส่วนของฉันรวมกับของคนอื่นต้องเท่ากับยอดรายการก่อนบันทึก';

  @override
  String txShareOthersOweYou(String amount) {
    return 'ลูกหนี้จากบิลนี้ $amount';
  }

  @override
  String txShareYouOweOthers(String amount) {
    return 'เจ้าหนี้จากบิลนี้ $amount';
  }

  @override
  String get accountsSortCustom => 'ลำดับที่จัดเอง';

  @override
  String get accountsSortBalance => 'ยอดมาก→น้อย';

  @override
  String get accountsSortName => 'ชื่อ';

  @override
  String get accountsSummaryCardDebt => 'หนี้บัตร';

  @override
  String get accountCreditSectionTitle => 'บัตร / วงเงิน';

  @override
  String get accountMinPaymentOverLimit =>
      'ขั้นต่ำมากกว่าวงเงิน ตรวจดูอีกครั้ง';

  @override
  String get identifierHintBankAccount => 'เช่น 123-4-56789-0';

  @override
  String get identifierHintPromptPay => 'เบอร์ 10 หลัก หรือเลขบัตร 13 หลัก';

  @override
  String get identifierHintCard => '4 ตัวท้ายของบัตร';

  @override
  String get identifierPromptPayLength =>
      'พร้อมเพย์ต้องเป็นเบอร์ 10 หลัก หรือเลขบัตร 13 หลัก';

  @override
  String get identifierCardLength => 'ใส่ 4 ตัวท้ายของบัตร';

  @override
  String get txSplitAuto => 'อัตโนมัติ';

  @override
  String get contactPickerCreateNew => 'สร้างผู้ติดต่อใหม่';

  @override
  String get contactPickerEmptyPlain => 'ยังไม่มีผู้ติดต่อ';

  @override
  String get contactPickerFilterAll => 'ทั้งหมด';

  @override
  String get contactPickerFilterContacts => 'ผู้ติดต่อ';

  @override
  String get contactPickerFilterNotInContacts => 'ไม่อยู่ในผู้ติดต่อ';

  @override
  String get contactPickerFilterOwing => 'มีหนี้';

  @override
  String get contactPickerFilterNoDebt => 'ไม่มีหนี้';

  @override
  String get contactPickerNoMatch => 'ไม่พบชื่อที่ตรงกัน';

  @override
  String get contactPickerTypeName => 'ชื่อใหม่';

  @override
  String contactPickerUseName(Object name) {
    return 'ใช้ชื่อ \"$name\"';
  }

  @override
  String get txSplitNameHint => 'ชื่อ';

  @override
  String get accountIdentifiersHint =>
      'ส่วนนี้ใช้จับคู่บัญชีตอนสแกนสลิปเท่านั้น';

  @override
  String get detailManageTitle => 'การจัดการ';

  @override
  String get draftExtrasNone => 'ไม่ได้ตั้ง';

  @override
  String get accountMembersSectionDescription => 'คนที่ใช้กระเป๋านี้ร่วมกับคุณ';

  @override
  String get accountCreditSectionDescription =>
      'วันตัดรอบ วันครบกำหนด และยอดชำระขั้นต่ำของบัตรนี้';

  @override
  String get walletMembersHistoryDescription =>
      'คนที่เคยอยู่ในกระเป๋านี้แต่ออกไปแล้ว';

  @override
  String get categorySettingsSectionDescription =>
      'ตั้งว่าหมวดนี้นับในรายงานและใช้กับค่าธรรมเนียมหรือไม่';

  @override
  String get projectMembersDescription => 'คนที่ร่วมอีเวนต์นี้อยู่ตอนนี้';

  @override
  String get projectMembersPendingDescription => 'เชิญแล้ว กำลังรอให้ตอบรับ';

  @override
  String get projectMembersLeftDescription => 'คนที่ออกจากอีเวนต์นี้ไปแล้ว';

  @override
  String get contactFieldNotSet => 'ไม่ระบุ';

  @override
  String get txSplitSectionTitle => 'ผูกกับ';

  @override
  String get txSplitSectionHint => 'แบ่งยอด ใส่ในอีเวนต์ หรือผูกกับรายการประจำ';

  @override
  String get txSplitRowLabel => 'แบ่งยอด';

  @override
  String get txSplitPeopleLabel => 'แบ่งกับคน';

  @override
  String get quickEventAdd => 'เพิ่มอีเวนต์';

  @override
  String get dayPickerLastShort => 'สิ้นเดือน';

  @override
  String get profileCurrencyLabel => 'สกุลเงิน';

  @override
  String get contactNicknameLabel => 'ชื่อเล่น';

  @override
  String get contactNicknameHint => 'ไม่บังคับ | เช่น แม่';

  @override
  String get contactShowNicknameLabel => 'แสดงชื่อเล่น';

  @override
  String get notOwnerError => 'เฉพาะเจ้าของกระเป๋าเท่านั้น';

  @override
  String get profileTitle => 'โปรไฟล์';

  @override
  String get profileEmailCannotClear => 'อีเมลที่ตั้งแล้วลบออกไม่ได้';

  @override
  String get connectionOffline => 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ | กำลังลองใหม่…';

  @override
  String get connectionReconnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get connectionBack => 'เชื่อมต่อได้แล้ว';

  @override
  String get connectionRetry => 'ลองใหม่';

  @override
  String get uiLoadMoreFailed => 'โหลดเพิ่มไม่สำเร็จ';

  @override
  String get debtsSortLabel => 'เรียง';

  @override
  String get debtsSortNewest => 'ใหม่สุด';

  @override
  String get debtsSortOldest => 'เก่าสุด';

  @override
  String get debtsSortAmountDesc => 'จำนวนมากสุด';

  @override
  String get debtsSortAmountAsc => 'จำนวนน้อยสุด';

  @override
  String get debtsDirLabel => 'ประเภท';

  @override
  String get debtsDirPaid => 'จ่าย';

  @override
  String get debtsDirReceived => 'รับ';

  @override
  String get debtsPaidChip => 'จ่ายแล้ว';

  @override
  String get debtsTimelineEmpty => 'ยังไม่มีรายการ';

  @override
  String get debtsEntriesNoMatch => 'ไม่พบรายการที่ค้นหา';

  @override
  String get debtsEntrySearchHint => 'ค้นหารายการ';

  @override
  String debtEntryPaidTo(String name) {
    return 'จ่ายให้ $name';
  }

  @override
  String debtEntryReceivedFrom(String name) {
    return 'รับจาก $name';
  }

  @override
  String get eventStartDateLabel => 'วันเริ่ม';

  @override
  String get eventDatesInvalid => 'วันสิ้นสุดต้องไม่ก่อนวันเริ่ม';

  @override
  String get eventTagShowBills => 'ดูบิลที่ติดแท็กนี้';

  @override
  String get eventTagAddToMine => 'เพิ่มเข้าแท็กของฉัน';

  @override
  String get quickModeTx => 'รายการ';

  @override
  String get quickModeDebt => 'หนี้';

  @override
  String get debtNoWallet => 'ไม่ระบุกระเป๋า';

  @override
  String get debtPickPerson => 'เลือกคน';

  @override
  String get debtPersonPickerTitle => 'กับใคร';

  @override
  String get debtSettledLabel => 'เคลียร์แล้ว';

  @override
  String get debtMarkPaidTitle => 'ทำเครื่องหมายรายการที่จ่ายแล้ว';

  @override
  String get debtMarkPaidNone => 'ไม่มีรายการค้าง';

  @override
  String get debtCloseLabel => 'ปิดหนี้';

  @override
  String debtCloseConfirm(int n) {
    return 'เลือก $n หนี้';
  }

  @override
  String get txFilterNoWallet => 'ไม่ระบุกระเป๋า';

  @override
  String get txFilterNoCategory => 'ไม่ระบุหมวด';

  @override
  String get txFilterNoTag => 'ไม่ระบุแท็ก';

  @override
  String get txSummaryNet => 'สุทธิ';

  @override
  String get txFilterAmount => 'จำนวนเงิน';

  @override
  String get txFilterAmountMin => 'ต่ำสุด';

  @override
  String get txFilterAmountMax => 'สูงสุด';

  @override
  String get txTitleHintExpense => 'จ่ายค่าอะไร?';

  @override
  String get txTitleHintIncome => 'รับเงินค่าอะไร?';

  @override
  String get savingTitleHint => 'ออมอะไร?';

  @override
  String get savingEntryGoalLabel => 'เป้าหมายการออม';

  @override
  String get debtEntrySaved => 'บันทึกหนี้แล้ว';

  @override
  String eventTagsImported(int count) {
    return 'เพิ่ม $count แท็กเข้าแท็กของฉันแล้ว';
  }

  @override
  String get debtEntryTitle => 'รายการหนี้';

  @override
  String get debtEntryNotFound => 'ไม่พบรายการหนี้นี้';

  @override
  String get debtEntryDelete => 'ลบรายการหนี้';

  @override
  String get debtEntryDeleteTitle => 'ลบรายการหนี้นี้?';

  @override
  String debtDeleteBothMessage(Object wallet) {
    return 'รายการใน “$wallet” จะถูกลบด้วย — ยอดเงินคืนเข้ากระเป๋า';
  }

  @override
  String debtDeleteLedgerMessage(Object name) {
    return 'ยอดกับ $name จะเปลี่ยนตาม';
  }

  @override
  String debtSourceHint(Object source) {
    return 'มาจาก $source — แก้ได้เฉพาะคำอธิบาย โน้ต และจ่ายแล้ว';
  }

  @override
  String get debtSourceRowLabel => 'มาจาก';

  @override
  String get eventErrLocked => 'อีเวนต์นี้ล็อกอยู่ แก้ไขไม่ได้';

  @override
  String get eventErrNotOwner => 'เฉพาะเจ้าของอีเวนต์ทำได้';

  @override
  String get eventErrTagTaken => 'มีแท็กชื่อนี้ในอีเวนต์แล้ว';

  @override
  String get eventErrTagNotFound => 'ไม่พบแท็กนี้ในอีเวนต์';

  @override
  String get eventErrNoShare => 'บิลนี้ไม่มีส่วนของฉัน';

  @override
  String get eventErrOwnerCannotLeave =>
      'เจ้าของต้องโอนความเป็นเจ้าของก่อนออกจากอีเวนต์';

  @override
  String get eventDeleteConfirm => 'ยืนยันลบ';

  @override
  String get occurrenceStateUpcoming => 'ล่วงหน้า';

  @override
  String get occurrenceStateNotCreated => 'รอยืนยัน';

  @override
  String get occurrenceStatePending => 'รอยืนยัน';

  @override
  String get occurrenceStateDone => 'บันทึกแล้ว';

  @override
  String get occurrenceStatePaid => 'จ่ายแล้ว';

  @override
  String get occurrenceStateArchived => 'ข้าม';

  @override
  String get occurrenceEditOnly => 'แก้เฉพาะงวดนี้';

  @override
  String get occurrenceConfirm => 'ยืนยัน';

  @override
  String get occurrenceEnterAmount => 'ใส่ยอด';

  @override
  String get occurrenceMarkPaid => 'จ่ายแล้ว';

  @override
  String get occurrenceSkip => 'ข้าม';

  @override
  String get occurrenceRestore => 'ยกเลิกการข้าม';

  @override
  String get occurrenceRecordInTx => 'บันทึกในรายการ';

  @override
  String get occurrenceLinkPick => 'ผูกรายการ';

  @override
  String get occurrenceCreateNow => 'สร้างรายการใหม่';

  @override
  String get occurrenceConfirmAll => 'ยืนยันทั้งหมด';

  @override
  String get occurrencePaidAll => 'จ่ายแล้วทั้งหมด';

  @override
  String get occurrenceSkipAll => 'ข้ามทั้งหมด';

  @override
  String occurrenceLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เหลือ $count งวดที่ยังไม่มียอด',
    );
    return '$_temp0';
  }

  @override
  String occurrenceLeftOutRefused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'บันทึกไม่ได้ $count งวด',
    );
    return '$_temp0';
  }

  @override
  String get occurrenceDueTitle => 'ต้องจัดการ';

  @override
  String occurrenceDueMore(int n) {
    return 'ดูทั้ง $n งวด';
  }

  @override
  String get occurrenceSelectAll => 'เลือกทั้งหมด';

  @override
  String occurrenceSelectedCount(int n) {
    return 'เลือกแล้ว $n';
  }

  @override
  String get occurrenceSkipSelected => 'ข้ามที่เลือก';

  @override
  String occurrenceConfirmSelected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ยืนยันที่เลือก ($n)',
      zero: 'ยืนยันที่เลือก',
    );
    return '$_temp0';
  }

  @override
  String occurrenceSkipSelectedTitle(int n) {
    return 'ข้าม $n งวดที่เลือก?';
  }

  @override
  String occurrenceSkippedCount(int n) {
    return 'ข้ามแล้ว $n งวด';
  }

  @override
  String occurrenceSavedCount(int n) {
    return 'บันทึกแล้ว $n งวด';
  }

  @override
  String occurrencePaidCount(int n) {
    return 'จ่ายแล้ว $n งวด';
  }

  @override
  String get occurrencePaidSelected => 'จ่ายแล้วที่เลือก';

  @override
  String get occurrenceNeedsAmount => 'ใส่ยอดก่อนยืนยัน';

  @override
  String get recurringSortDate => 'วันที่';

  @override
  String get recurringSortAmount => 'ยอดมากสุด';

  @override
  String get recurringSortTooltip => 'เรียงลำดับ';

  @override
  String get recurringFilterAllStatus => 'ทุกสถานะ';

  @override
  String get recurringFilterAllKinds => 'ทุกประเภท';

  @override
  String get recurringMonthNoMatch => 'ไม่มีรายการตามตัวกรองนี้';

  @override
  String get occurrenceShowLess => 'ย่อ';

  @override
  String get recurringAheadCustomize => 'ปรับแต่งล่วงหน้า';

  @override
  String get recurringAheadCustomizeHint =>
      'แก้ยอด เลื่อนวัน หรือข้ามงวดข้างหน้า';

  @override
  String get recurringAheadNext => 'ถัดไป';

  @override
  String get recurringTileMoved => 'เลื่อน';

  @override
  String get recurringTileEdited => 'แก้';

  @override
  String get recurringFieldKind => 'ประเภท';

  @override
  String get recurringFieldDates => 'เลือกวันเอง';

  @override
  String get recurringSectionPeriod => 'ช่วงเวลา';

  @override
  String get recurringHomeTabOverview => 'ภาพรวม';

  @override
  String get recurringHomeMonthPay => 'จ่ายรวมทั้งเดือน';

  @override
  String get recurringHomeMonthCount => 'รายการเดือนนี้';

  @override
  String recurringHomeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0';
  }

  @override
  String recurringHomeToday(String date) {
    return 'วันนี้ $date';
  }

  @override
  String recurringDayEmpty(String date) {
    return 'ไม่มีรายการวันที่ $date';
  }

  @override
  String get recurringHomeAllTitle => 'รายการประจำทั้งหมด';

  @override
  String recurringHomePerMonthYear(String month, String year) {
    return '$month/เดือน | $year/ปี';
  }

  @override
  String recurringHomePerMonth(String amount) {
    return '$amount/เดือน';
  }

  @override
  String recurringHomeAvgPerMonth(String amount) {
    return 'เฉลี่ย $amount/เดือน';
  }

  @override
  String recurringHomeLeft(String amount) {
    return 'เหลือ $amount';
  }

  @override
  String get txPickerTitle => 'เลือกรายการ';

  @override
  String get txPickerGroupNear => 'ใกล้วันที่';

  @override
  String get quickUpcomingHintTitle => 'รายการล่วงหน้า';

  @override
  String get linkedSaveTitle => 'แก้อีกฝั่งด้วยไหม?';

  @override
  String get linkedCancel => 'ยังก่อน';

  @override
  String get linkedSaveThisOnly => 'บันทึกเฉพาะฝั่งนี้';

  @override
  String get linkedSaveBoth => 'บันทึกและแก้อีกฝั่ง';

  @override
  String get dueToday => 'วันนี้';

  @override
  String get dueTomorrow => 'พรุ่งนี้';

  @override
  String get dueYesterday => 'เมื่อวาน';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อีก $count วัน',
    );
    return '$_temp0';
  }

  @override
  String dueOverdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เลยกำหนด $count วัน',
    );
    return '$_temp0';
  }

  @override
  String recurEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทุก $count วัน',
      one: 'ทุกวัน',
    );
    return '$_temp0';
  }

  @override
  String recurEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทุก $count สัปดาห์',
      one: 'ทุกสัปดาห์',
    );
    return '$_temp0';
  }

  @override
  String get recurWeekday1 => 'จันทร์';

  @override
  String get recurWeekday2 => 'อังคาร';

  @override
  String get recurWeekday3 => 'พุธ';

  @override
  String get recurWeekday4 => 'พฤหัสบดี';

  @override
  String get recurWeekday5 => 'ศุกร์';

  @override
  String get recurWeekday6 => 'เสาร์';

  @override
  String get recurWeekday7 => 'อาทิตย์';

  @override
  String recurWeekdayPair(String a, String b) {
    return '$aและ$b';
  }

  @override
  String recurWeekdayList(String list, String last) {
    return '$list และ$last';
  }

  @override
  String get recurWeekdayListSep => ' ';

  @override
  String recurEveryWeekdays(String weekdays) {
    return 'ทุกวัน$weekdays';
  }

  @override
  String recurOnWeekdays(String weekdays) {
    return 'วัน$weekdays';
  }

  @override
  String recurEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทุก $count เดือน',
      one: 'ทุกเดือน',
    );
    return '$_temp0';
  }

  @override
  String recurMonthlyOnDay(int day) {
    return 'ทุกวันที่ $day';
  }

  @override
  String get recurMonthlyLastDay => 'ทุกวันสุดท้ายของเดือน';

  @override
  String recurOnDay(int day) {
    return 'วันที่ $day';
  }

  @override
  String get recurLastDay => 'วันสุดท้าย';

  @override
  String recurMonthlyNthWeekday(String ord, int nth, String weekday) {
    return 'ทุกวัน$weekdayที่ $nth ของเดือน';
  }

  @override
  String recurMonthlyLastWeekday(String weekday) {
    return 'ทุกวัน$weekdayสุดท้ายของเดือน';
  }

  @override
  String recurOnNthWeekday(String ord, int nth, String weekday) {
    return 'วัน$weekdayที่ $nth';
  }

  @override
  String recurOnLastWeekday(String weekday) {
    return 'วัน$weekdayสุดท้าย';
  }

  @override
  String recurEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทุก $count ปี',
      one: 'ทุกปี',
    );
    return '$_temp0';
  }

  @override
  String recurYearlyOn(String date) {
    return 'ทุกปี $date';
  }

  @override
  String recurCustomDates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'กำหนดเอง $count วัน',
      zero: 'กำหนดเอง',
    );
    return '$_temp0';
  }

  @override
  String recurEndCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String recurEndUntil(String date) {
    return 'ถึง $date';
  }

  @override
  String get uiPickDatesHint => 'แตะวันที่เพื่อเลือก';

  @override
  String get txRecurringRowLabel => 'รายการประจำ';

  @override
  String get recurringTitle => 'รายการประจำ';

  @override
  String get recurringAdd => 'เพิ่มรายการประจำ';

  @override
  String get recurringEmptyTitle => 'ยังไม่มีรายการประจำ';

  @override
  String get recurringEmptyMessage =>
      'ตั้งรายการที่เกิดซ้ำ เช่น ค่าเน็ต ค่าห้อง พอถึงวันจะมีรายการรอยืนยันให้';

  @override
  String get recurringNewTitle => 'รายการประจำใหม่';

  @override
  String get recurringNotFound => 'ไม่พบรายการประจำ';

  @override
  String get recurringNotFoundMessage => 'อาจถูกลบไปแล้ว';

  @override
  String get recurringFieldIcon => 'ไอคอน';

  @override
  String get recurringFieldToWallet => 'โอนไปกระเป๋า';

  @override
  String get recurringFieldCategory => 'หมวดหมู่';

  @override
  String get recurringFieldRepeat => 'ทำซ้ำ';

  @override
  String get recurringFieldStart => 'เริ่ม';

  @override
  String get recurringNameRequired => 'ใส่ชื่อรายการ';

  @override
  String get recurringAmountInvalid => 'ใส่จำนวนเงินมากกว่า 0';

  @override
  String get recurringWalletRequired => 'เลือกกระเป๋า';

  @override
  String get recurringRepeatDatesTitle => 'เลือกวัน';

  @override
  String recurringRepeatDatesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เลือก $count วัน',
    );
    return '$_temp0';
  }

  @override
  String get recurringEndNever => 'ไม่สิ้นสุด';

  @override
  String get recurringStatusActive => 'ใช้งาน';

  @override
  String get recurringStatusPaused => 'พักไว้';

  @override
  String get recurringStatusArchived => 'เก็บถาวร';

  @override
  String get recurringStatusEndingSoon => 'ใกล้ครบ';

  @override
  String get recurringPause => 'พัก';

  @override
  String get recurringResume => 'ทำต่อ';

  @override
  String get recurringArchive => 'เก็บถาวร';

  @override
  String get recurringRestore => 'กู้คืน';

  @override
  String get recurringDelete => 'ลบรายการประจำ';

  @override
  String get recurringArchiveTitle => 'เก็บรายการประจำนี้ถาวร?';

  @override
  String get recurringArchiveBody =>
      'จะหยุดสร้างรายการและซ่อนไว้ กู้คืนได้ภายหลัง';

  @override
  String get recurringDeleteTitle => 'ลบรายการประจำนี้?';

  @override
  String get recurringDeleteBody => 'ลบการตั้งค่าและรายการที่ยังไม่ได้สร้าง';

  @override
  String get recurringDeleteKeepTxs => 'ลบ แต่เก็บรายการที่บันทึกแล้วไว้';

  @override
  String recurringDeleteWithTxs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ลบพร้อมรายการที่บันทึกแล้ว $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String recurringEndingSoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ใกล้ครบแล้ว เหลืออีก $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get recurringExtend => 'ต่ออีก';

  @override
  String get recurringPausedNotice =>
      'พักไว้อยู่ วันที่ผ่านไประหว่างพักจะไม่สร้างรายการ';

  @override
  String get recurringItemsEmpty => 'ยังไม่มีรายการที่ถึงกำหนด';

  @override
  String get recurringUpcomingEmpty => 'ไม่มีรายการที่จะถึง';

  @override
  String get recurringUpcomingEmptyMessage =>
      'กด \"ต่ออีก\" หรือแก้การตั้งค่าเพื่อสร้างรายการต่อ';

  @override
  String get moreRecurring => 'รายการประจำ';

  @override
  String get moreRecurringDesc => 'บิลและรายการที่เกิดซ้ำ';

  @override
  String notifRecurringDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รายการประจำถึงกำหนด $count งวด รอจัดการ',
    );
    return '$_temp0';
  }

  @override
  String notifRecurringAutoCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'บันทึกอัตโนมัติ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String notifRecurringEnding(String name, int left) {
    return '$name เหลืออีก $left รายการ — ต่ออีกไหม';
  }

  @override
  String get recurSheetTitle => 'ทำซ้ำแบบกำหนดเอง';

  @override
  String get recurSheetEvery => 'ทุก';

  @override
  String recurSheetUnitDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วัน',
    );
    return '$_temp0';
  }

  @override
  String recurSheetUnitWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'สัปดาห์',
    );
    return '$_temp0';
  }

  @override
  String recurSheetUnitMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เดือน',
    );
    return '$_temp0';
  }

  @override
  String recurSheetUnitYear(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ปี',
    );
    return '$_temp0';
  }

  @override
  String get recurSheetRepeatOn => 'ทำซ้ำในวัน';

  @override
  String get recurSheetMonthlyOn => 'วันในเดือน';

  @override
  String get recurSheetEnds => 'สิ้นสุด';

  @override
  String get recurSheetEndNever => 'ไม่สิ้นสุด';

  @override
  String get recurSheetEndOnDate => 'ถึงวันที่';

  @override
  String get recurSheetEndAfter => 'ครบจำนวนครั้ง';

  @override
  String recurSheetOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get recurSheetPeriodStart => 'รอบใหม่เริ่มวัน';

  @override
  String get recurSheetYearlyOn => 'ทุกปีในวันที่';

  @override
  String get recurSheetByDay => 'ตามวันที่';

  @override
  String get recurSheetByWeekday => 'ตามวันในสัปดาห์';

  @override
  String recurSheetNth(String ord, int nth) {
    return 'ที่ $nth';
  }

  @override
  String recurSheetStartMoves(String date) {
    return 'วันเริ่มจะเลื่อนเป็น $date';
  }

  @override
  String get moreGroupPlan => 'แผนการเงิน';

  @override
  String get moreGroupOthers => 'เงินกับคนอื่น';

  @override
  String get moreGroupSetup => 'ข้อมูลตั้งต้น';

  @override
  String get moreGroupMain => 'เมนูหลัก';

  @override
  String get moreSettings => 'โปรไฟล์และตั้งค่า';

  @override
  String get moreDashboardDesc => 'ภาพรวมการเงินของเดือนนี้';

  @override
  String get moreTransactionsDesc => 'รายรับ-รายจ่ายทั้งหมด';

  @override
  String get moreWalletsDesc => 'เงินสด บัญชี และบัตร';

  @override
  String get morePendingDesc => 'รายการที่รอให้คุณยืนยัน';

  @override
  String get moreNotificationsDesc => 'ข่าวและเตือนความจำ';

  @override
  String get moreSettingsDesc => 'บัญชี ธีม และการแจ้งเตือน';

  @override
  String get sgv2Spare => 'ยังไม่จัดสรร';

  @override
  String get sgv2SpareHint => 'เงินออมที่ยังไม่มีเป้าหมาย';

  @override
  String get sgv2FilterActive => 'กำลังออม';

  @override
  String get sgv2FilterCompleted => 'สำเร็จ';

  @override
  String get sgv2FilterArchived => 'เก็บถาวร';

  @override
  String get sgv2EmptyFilteredTitle => 'ไม่มีเป้าหมายในหมวดนี้';

  @override
  String sgv2PaceLate(int n) {
    return 'ช้า $n เดือน';
  }

  @override
  String get sgv2PaceOnTrack => 'ตามแผน';

  @override
  String sgv2DueOn(String date) {
    return 'ครบ $date';
  }

  @override
  String get sgv2ActionWithdraw => 'ถอน';

  @override
  String get sgv2ActionMove => 'ย้าย';

  @override
  String get sgv2Overview => 'ภาพรวม';

  @override
  String get sgv2Entries => 'รายการออม';

  @override
  String get sgv2EntriesEmpty => 'ยังไม่มีรายการออม';

  @override
  String get sgv2CloseGoal => 'ปิดเป้าหมาย';

  @override
  String sgv2CloseTitle(String name) {
    return 'ปิดเป้าหมาย “$name”';
  }

  @override
  String sgv2CloseBody(String amount) {
    return 'เงินออม $amount จะไปที่ไหน?';
  }

  @override
  String get sgv2CloseToSpare => 'เข้ายังไม่จัดสรร';

  @override
  String get sgv2CloseToWallets => 'กลับกระเป๋า';

  @override
  String get sgv2KindSave => 'ออม';

  @override
  String get sgv2KindWithdraw => 'ถอนออม';

  @override
  String get sgv2KindMove => 'จัดสรร';

  @override
  String sgEntryFrom(String name) {
    return 'จาก $name';
  }

  @override
  String sgEntryTo(String name) {
    return 'ไป $name';
  }

  @override
  String get sgv2SpareTitle => 'ยังไม่จัดสรร';

  @override
  String get walletTrackLabel => 'ติดตามยอดเงิน';

  @override
  String get walletTrackHelper =>
      'ปิดไว้ถ้าไม่ต้องการดูยอดคงเหลือของกระเป๋านี้ (ยังบันทึกรายการและโอนได้)';

  @override
  String get walletTrackSetBalanceTitle => 'ยอดเงินตอนนี้';

  @override
  String get walletTrackSetBalanceAction => 'ตั้งยอด';

  @override
  String get walletErrorBalanceNotTracked =>
      'กระเป๋านี้ไม่ได้ติดตามยอดเงิน เปิดสวิตช์ก่อนจึงจะปรับยอดได้';

  @override
  String get multiPickCategoriesTitle => 'เลือกหมวดหมู่';

  @override
  String get multiPickWalletsTitle => 'เลือกกระเป๋า';

  @override
  String get multiPickSearch => 'ค้นหา';

  @override
  String get multiPickIncludeChildren => 'รวมหมวดย่อย';

  @override
  String get multiPickEmpty => 'ยังไม่มีรายการ';

  @override
  String get multiPickNoMatch => 'ไม่พบรายการ';

  @override
  String multiPickConfirm(int count) {
    return 'ตกลง ($count)';
  }

  @override
  String get bgFilterActive => 'กำลังใช้งาน';

  @override
  String get bgFilterEnded => 'จบแล้ว';

  @override
  String get bgFilterArchived => 'เก็บถาวร';

  @override
  String get bgSortRisk => 'ใกล้เกินก่อน';

  @override
  String get bgSortName => 'ชื่อ';

  @override
  String get bgSortNewest => 'ใหม่สุด';

  @override
  String bgSortChip(String sort) {
    return 'เรียง: $sort';
  }

  @override
  String get bgStatOver => 'เกินงบ';

  @override
  String get bgStatWarn => 'ใกล้เต็ม';

  @override
  String get bgStatusOver => 'เกินงบ';

  @override
  String get bgStatusWarn => 'ใกล้เต็ม';

  @override
  String get bgStatusEnded => 'จบแล้ว';

  @override
  String get bgStatusArchived => 'เก็บถาวร';

  @override
  String get bgStatusUpcoming => 'ยังไม่เริ่ม';

  @override
  String get bgListEmptyEnded => 'ยังไม่มีงบที่จบแล้ว';

  @override
  String get bgListEmptyArchived => 'ไม่มีงบที่เก็บถาวร';

  @override
  String get bgRuleDaily => 'รายวัน';

  @override
  String get bgRuleWeekly => 'รายสัปดาห์';

  @override
  String get bgRuleMonthly => 'รายเดือน';

  @override
  String get bgRuleYearly => 'รายปี';

  @override
  String bgRowRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get bgRowOpenEnded => 'ไม่มีกำหนดจบ';

  @override
  String bgRowSince(String date) {
    return 'ตั้งแต่ $date';
  }

  @override
  String bgRowDaysLeft(int count) {
    return 'เหลือ $count วัน';
  }

  @override
  String bgRowUsed(String used, String amount) {
    return 'ใช้ $used จาก $amount';
  }

  @override
  String get bgPeriodNow => 'รอบนี้';

  @override
  String get bgPeriodOverridden => 'เฉพาะรอบนี้';

  @override
  String get bgSourceNormal => 'ปกติ';

  @override
  String get bgSourceRecurring => 'รายการประจำ';

  @override
  String get bgSourceEvent => 'อีเวนต์';

  @override
  String get bgSourceUpcoming => 'รายการประจำ | ล่วงหน้า';

  @override
  String get bgSourcePending => 'รอยืนยัน';

  @override
  String get bgSourceFutureTx => 'ล่วงหน้า';

  @override
  String get bgPeriodsAll => 'ดูรอบก่อนหน้าทั้งหมด';

  @override
  String get bgItemsMore => 'ดูเพิ่ม';

  @override
  String get bgItemsEmpty => 'ยังไม่มีรายการในรอบนี้';

  @override
  String get bgPeriodAmountField => 'งบรอบนี้';

  @override
  String bgPeriodEditSubtitle(String period) {
    return 'แก้เฉพาะรอบ $period | รอบอื่นไม่เปลี่ยน';
  }

  @override
  String get bgPeriodBase => 'งบปกติ';

  @override
  String get bgPeriodNoteHint => 'เช่น เดือนนี้มีงานแต่ง';

  @override
  String get bgSectionScope => 'นับรายจ่ายไหนบ้าง';

  @override
  String get bgScopeAll => 'ทุกรายจ่าย';

  @override
  String get bgScopeCategories => 'หมวดหมู่';

  @override
  String get bgScopeTags => 'แท็ก';

  @override
  String get bgScopeWallets => 'กระเป๋า';

  @override
  String bgScopeChildren(String name) {
    return '$name ทั้งหมด';
  }

  @override
  String get bgScopeRequired => 'เลือกสิ่งที่จะนับ หรือเปิด \"ทุกรายจ่าย\"';

  @override
  String get bgSectionPeriod => 'ช่วงเวลา';

  @override
  String get bgFieldRepeat => 'นับรอบ';

  @override
  String get bgFieldRepeatToggle => 'ทำซ้ำ';

  @override
  String get bgFieldStart => 'เริ่ม';

  @override
  String get bgFieldEnd => 'สิ้นสุด';

  @override
  String get bgSectionPeriodDesc => 'เริ่มเมื่อไร และวนรอบยังไง';

  @override
  String get bgScopeChoose => 'เลือกเอง';

  @override
  String get bgScopeAndHint =>
      'นับรายการที่ตรงกับทุกแถวที่เลือก (ในแถวเดียวกัน อันไหนก็ได้)';

  @override
  String get bgScopePickTags => 'เลือกแท็ก';

  @override
  String get bgStatusOnPlan => 'ตามแผน';

  @override
  String bgStatusAhead(String amount) {
    return 'ใช้เร็วกว่าแผน $amount';
  }

  @override
  String bgStatusOverBy(String amount) {
    return 'เกินงบ $amount';
  }

  @override
  String bgRingOf(String amount) {
    return 'จาก $amount';
  }

  @override
  String get bgFactUsed => 'ใช้ไป';

  @override
  String get bgFactPending => 'รอจ่าย';

  @override
  String get bgFactPlanToday => 'แผนถึงวันนี้';

  @override
  String bgPaceBubble(String amount) {
    return 'แผน $amount';
  }

  @override
  String get bgRingTotalLeft => 'เหลือทั้งหมด';

  @override
  String get bgFactUsedTotal => 'ใช้ไปทั้งหมด';

  @override
  String get bgFactUsedPct => 'ใช้แล้ว';

  @override
  String get bgFactBudgetCount => 'งบในรอบนี้';

  @override
  String bgCountBudgets(int count) {
    return '$count งบ';
  }

  @override
  String get bgFactNextRound => 'รอบใหม่เริ่ม';

  @override
  String get bgFieldStartHelp => 'เริ่มนับรายจ่ายตั้งแต่วันนี้';

  @override
  String get bgEndNone => 'ไม่สิ้นสุด';

  @override
  String bgEndOnDate(Object date) {
    return 'สิ้นสุด $date';
  }

  @override
  String get bgEndPickDate => 'เลือกวันที่…';

  @override
  String bgEndPeriods(int count) {
    return '$count รอบ';
  }

  @override
  String get bgWarnOff => 'ไม่เตือน';

  @override
  String bgWarnPct(int pct) {
    return '$pct%';
  }

  @override
  String get bgScopeChoiceTitle => 'ใช้การตั้งค่าใหม่กับรอบไหน';

  @override
  String get bgScopeFollowing => 'รอบนี้และถัดไป';

  @override
  String get bgScopeAllPeriods => 'ทุกรอบ (รวมรอบที่ผ่านมา)';

  @override
  String get bgClose => 'ปิดงบ';

  @override
  String get bgCloseConfirmTitle => 'ปิดงบนี้?';

  @override
  String get bgCloseConfirmBody =>
      'งบจะหยุดนับตั้งแต่วันนี้ และย้ายไปอยู่ใน \"จบแล้ว\"';

  @override
  String get bgRestore => 'กู้คืน';

  @override
  String get bgNameRequired => 'ใส่ชื่องบ';

  @override
  String get pendingSavingNoWallet => 'ต้องเลือกกระเป๋าก่อนยืนยัน';

  @override
  String get walletSavingsSaved => 'ออมไว้';

  @override
  String get quickModeSaving => 'ออม';

  @override
  String get savingEntrySpare => 'ยังไม่จัดสรร';

  @override
  String get savingEntryPickGoal => 'เลือกเป้าหมายการออม';

  @override
  String savingEntryAvailable(String amount) {
    return 'ว่างออมได้ $amount';
  }

  @override
  String savingEntryOverAvailable(String amount) {
    return 'เกินเงินที่ว่าง $amount (ยังบันทึกได้)';
  }

  @override
  String get savingEntrySaved => 'บันทึกเงินออมแล้ว';

  @override
  String get sgv2MoveTitle => 'ย้ายเงินออม';

  @override
  String get sgv2WithdrawTitle => 'ถอนเงินออม';

  @override
  String get sgv2MoveFrom => 'จาก';

  @override
  String get sgv2MoveTo => 'ไป';

  @override
  String get sgv2WalletsCard => 'กระเป๋า';

  @override
  String get sgv2AmountLabel => 'จำนวนเงิน';

  @override
  String get sgv2SplitTitle => 'แบ่งตามกระเป๋า (อัตโนมัติ)';

  @override
  String get sgv2SplitEdit => 'แก้ไข';

  @override
  String sgv2SplitHas(String amount) {
    return 'มี $amount';
  }

  @override
  String sgv2SumOk(String sum) {
    return 'รวม $sum ✓';
  }

  @override
  String sgv2SumOff(String sum, String amount) {
    return 'รวม $sum ไม่ตรงกับ $amount';
  }

  @override
  String get sgv2ReturnsTitle => 'ถ้ากลับกระเป๋า';

  @override
  String get sgv2Cancel => 'ยกเลิก';

  @override
  String get sgv2MovePick => 'ย้ายไปที่ไหน?';

  @override
  String get sgv2MoveSave => 'ย้าย';

  @override
  String get sgv2WithdrawSave => 'ถอน';

  @override
  String get sgv2ChartCaption => 'ยอดสะสม';

  @override
  String sgv2ChartTarget(String amount) {
    return 'เป้า $amount';
  }

  @override
  String get sgv2SpareName => 'ยังไม่จัดสรร';

  @override
  String get profileCurrencyChangeTitle => 'เปลี่ยนสกุลเงิน?';

  @override
  String get profileCurrencyChangeMessage => '100 ก็ยังเป็น 100';

  @override
  String get profileCurrencyChangeConfirm => 'เปลี่ยนสกุลเงิน';

  @override
  String get bgSearchHint => 'ค้นหางบประมาณ';

  @override
  String get bgNoMatch => 'ไม่พบงบประมาณที่ตรงกัน';

  @override
  String get sgv2SearchHint => 'ค้นหาเป้าหมาย';

  @override
  String get recurringSearchHint => 'ค้นหารายการประจำ';

  @override
  String get recurringNoMatch => 'ไม่พบรายการประจำที่ค้นหา';

  @override
  String get accountsSearchHint => 'ค้นหากระเป๋า';

  @override
  String get accountsNoMatch => 'ไม่พบกระเป๋าที่ค้นหา';

  @override
  String get bgTileAll => 'ทั้งหมด';

  @override
  String get bgTileOk => 'ปกติ';

  @override
  String get bgStatusFieldLabel => 'สถานะ';

  @override
  String get bgRowLeft => 'เหลือ';

  @override
  String get bgRowOverAmount => 'เกิน';

  @override
  String get bgRowOneOff => 'ครั้งเดียว';

  @override
  String get fpWalletsTileAvailable => 'ใช้ได้จริง';

  @override
  String fpWalletsCreditUsedPct(int pct) {
    return 'ใช้วงเงิน $pct%';
  }

  @override
  String get fpWalletsFilterAll => 'ทั้งหมด';

  @override
  String get fpWalletsFilterCash => 'เงินสด/บัญชี';

  @override
  String get fpWalletsFilterCard => 'บัตรเครดิต';

  @override
  String fpWalletsSharedTooltip(int count) {
    return 'กระเป๋าร่วม $count';
  }

  @override
  String get fpWalletsSortByType => 'ตามประเภท';

  @override
  String get fpWalletsReorderChip => 'จัดลำดับ';

  @override
  String get fpWalletBalanceLabel => 'ยอดในกระเป๋า';

  @override
  String fpWalletSavedLegend(String amount) {
    return 'ออมไว้ $amount';
  }

  @override
  String get fpWalletSavedInTitle => 'ออมไว้ใน';

  @override
  String get fpWalletSavedInDesc => 'เงินในกระเป๋านี้ที่กันไว้ให้เป้าหมาย';

  @override
  String get fpWalletAvailableLabel => 'ใช้ได้';

  @override
  String get fpWalletSavedLabel => 'ออมไว้';

  @override
  String fpWalletSavedOverAlert(String amount) {
    return 'ออมไว้เกินยอดในกระเป๋า $amount';
  }

  @override
  String get fpWalletCreditUsedLabel => 'ยอดใช้ไป';

  @override
  String fpWalletCardAvailableLabel(String limit) {
    return 'เหลือใช้ จากวงเงิน $limit';
  }

  @override
  String get fpWalletScopeOwnChip => 'เฉพาะฉัน';

  @override
  String fpWalletFlowIn(String month) {
    return 'เงินเข้า $month';
  }

  @override
  String fpWalletFlowOut(String month) {
    return 'เงินออก $month';
  }

  @override
  String fpWalletCardLeft(String amount) {
    return 'เหลือ $amount';
  }

  @override
  String fpWalletDueAlert(String date, int days) {
    return 'ครบกำหนดชำระ $date | อีก $days วัน';
  }

  @override
  String accountCardDueIn(int days) {
    return 'ครบกำหนดอีก $days วัน';
  }

  @override
  String get accountCardDueToday => 'ครบกำหนดวันนี้';

  @override
  String get fpWalletPayCard => 'ชำระบัตร';

  @override
  String get fpWalletSave => 'ออม';

  @override
  String get fpWalletSettingsDesc => 'กระเป๋านี้นับในยอดและรายงานอย่างไร';

  @override
  String get fpWalletCardSettingsDesc => 'บัตรนี้นับในรายงานอย่างไร';

  @override
  String get fpWalletArchiveConsequence =>
      'ไม่นับในยอดใดเลย แก้ไม่ได้ กู้คืนได้';

  @override
  String get fpWalletInviteLabel => 'เชิญ';

  @override
  String get fpWalletOwnerCaption => 'เจ้าของ';

  @override
  String get fpWalletMemberCaption => 'สมาชิก';

  @override
  String fpTxAvgDaily(String amount) {
    return 'จ่ายเฉลี่ย $amount/วัน';
  }

  @override
  String get fpWalletDeleteLabel => 'ลบกระเป๋านี้';

  @override
  String get fpWalletDeleteConsequence =>
      'ดูก่อนว่ามีอะไรผูกอยู่ | เงินออมยังอยู่ แค่หลุดจากกระเป๋า';

  @override
  String get fpWalletDeleteTitle => 'ลบกระเป๋านี้?';

  @override
  String fpWalletDeleteBody(
    int transactions,
    int transfers,
    int system,
    int recurring,
    int savings,
    String amount,
  ) {
    return 'รายการ $transactions รายการยังอยู่แต่ไม่มีกระเป๋า (โอน $transfers) | รายการเปิดยอด/ปรับยอด $system รายการถูกลบ | รายการประจำ $recurring ยังทำงานต่อ | เงินออม $savings รายการ ($amount) ยังอยู่แต่หลุดจากกระเป๋า';
  }

  @override
  String get fpWalletDeleted => 'ลบกระเป๋าแล้ว';

  @override
  String get fpContactsLinkSection => 'บัญชีในแอป';

  @override
  String get fpContactsLinkSectionDesc =>
      'ผูกคนนี้กับบัญชีที่เขาใช้ในแอป ให้ชื่อ อีเมล และไอคอนตามบัญชีของเขา และรวมชื่อที่เคยพิมพ์ไว้ในรายการหาร';

  @override
  String contactLinkedAccount(String name) {
    return 'เชื่อมกับบัญชี $name';
  }

  @override
  String get fpContactsArchiveConsequence =>
      'ซ่อนจากลิสต์และตัวเลือกคน หนี้ไม่เปลี่ยน';

  @override
  String get fpContactsDeleteConsequence =>
      'รายการเก่าเหลือแค่ชื่อ ยอดไม่เปลี่ยน';

  @override
  String fpDebtsOwedToMeTile(int count) {
    return 'ลูกหนี้ | $count คน';
  }

  @override
  String fpDebtsIOweTile(int count) {
    return 'เจ้าหนี้ | $count คน';
  }

  @override
  String fpDebtsDaysOutstanding(int count) {
    return 'ค้าง $count วัน';
  }

  @override
  String get fpDebtsCopy => 'คัดลอก';

  @override
  String get fpDebtsCopied => 'คัดลอกข้อความแล้ว';

  @override
  String get fpBudgetsLeftLabel => 'ยังใช้ได้';

  @override
  String get fpBudgetsOverLabel => 'เกิน';

  @override
  String get fpBudgetsTileDaily => 'ใช้ได้วันละ';

  @override
  String get fpBudgetsWarnAt => 'เตือนเมื่อใช้ถึง';

  @override
  String get fpBudgetsTabItems => 'รายการในรอบนี้';

  @override
  String get fpBudgetsTabPeriods => 'ทุกรอบ';

  @override
  String get fpBudgetsLimitLabel => 'เพดานงบ';

  @override
  String fpBudgetsPeriodReset(String amount) {
    return '↺ ใช้งบปกติ ($amount)';
  }

  @override
  String get fpBudgetsCloseConsequence =>
      'จบงบนี้ ไม่สร้างรอบใหม่ รอบเก่ายังดูได้';

  @override
  String get fpBudgetsArchiveConsequence => 'ซ่อนไว้ ไม่นับในยอด กู้คืนได้';

  @override
  String get fpBudgetsRestoreConsequence =>
      'กลับมาอยู่ในรายการและนับในยอดอีกครั้ง';

  @override
  String get fpBudgetsDeleteConsequence => 'ลบถาวร ทุกรอบ';

  @override
  String fpGoalsStatusChip(String status) {
    return 'สถานะ: $status';
  }

  @override
  String fpGoalsDueBy(String date) {
    return 'ภายใน $date';
  }

  @override
  String get fpGoalsBehind => 'ช้ากว่าแผน';

  @override
  String get fpGoalsReached => 'ครบแล้ว';

  @override
  String get fpGoalsClosed => 'ปิดแล้ว';

  @override
  String get fpGoalsSavedLabel => 'ออมแล้ว';

  @override
  String fpGoalsDaysLeft(int count) {
    return 'อีก $count วัน';
  }

  @override
  String get fpGoalsTileSaved => 'เดือนนี้ออมแล้ว';

  @override
  String get fpGoalsActionSave => 'ออม';

  @override
  String get fpGoalsActionRestore => 'กู้คืน';

  @override
  String get fpGoalsAutoFrom => 'กันเงินจาก';

  @override
  String get fpGoalsNoWallet => 'ไม่ระบุกระเป๋า';

  @override
  String get fpGoalsChartActual => 'ออมจริง';

  @override
  String get fpGoalsCloseConsequence =>
      'ย้ายเงินไป “ยังไม่จัดสรร” หรือคืนกระเป๋าเดิม';

  @override
  String get fpGoalsArchiveConsequence => 'ซ่อนไว้ ไม่นับในยอด กู้คืนได้';

  @override
  String get fpGoalsArchiveNeedsClose => 'ปิดเป้าหมายก่อน';

  @override
  String get fpGoalsDeleteConsequence => 'ลบถาวร พร้อมประวัติการออม';

  @override
  String get fpGoalsArchiveConfirmBody =>
      'ซ่อนเป้าหมายนี้ ไม่นับในยอด กู้คืนได้ภายหลัง';

  @override
  String get fpGoalsDeleteConfirmBody =>
      'ลบเป้าหมายนี้ถาวร พร้อมประวัติการออมของเป้าหมาย';

  @override
  String get fpGoalsGroupOngoing => 'ออมต่อเนื่อง';

  @override
  String fpGoalsRingOfPlan(String amount) {
    return 'เป้าหมาย $amount';
  }

  @override
  String fpGoalsRingOf(String target, int pct) {
    return 'จาก $target | $pct%';
  }

  @override
  String get fpGoalsFactTotal => 'เงินออมทั้งหมด';

  @override
  String get fpGoalsFactGoals => 'เป้าหมาย';

  @override
  String get fpGoalsFactTarget => 'เป้าหมาย';

  @override
  String get fpGoalsFactStillShort => 'เดือนนี้ยังขาด';

  @override
  String get fpGoalsFactShouldHave => 'ควรมีตอนนี้';

  @override
  String get fpGoalsFactLeft => 'เหลืออีก';

  @override
  String get fpGoalsFactReachedOn => 'ถึงเป้าเมื่อ';

  @override
  String get fpGoalsFilterAll => 'ทั้งหมด';

  @override
  String get fpGoalsFilterShort => 'กำลังออม';

  @override
  String get fpGoalsFilterFree => 'ไม่มีกำหนด';

  @override
  String get fpGoalsSortNeed => 'ต้องออมก่อน';

  @override
  String get fpGoalsRowDone => 'ครบแล้ว ✓';

  @override
  String fpGoalsRowMonthOnly(String month, String amount) {
    return '$month $amount';
  }

  @override
  String get fpGoalsThisMonth => 'เดือนนี้';

  @override
  String fpGoalsChipShort(String amount) {
    return 'เดือนนี้ขาด $amount';
  }

  @override
  String fpGoalsChipLate(int n) {
    return 'ช้ากว่ากำหนด $n เดือน';
  }

  @override
  String get fpGoalsFactPeriodSaved => 'ออมรอบนี้';

  @override
  String get fpGoalsFactPeriodTarget => 'เป้ารอบนี้';

  @override
  String get fpGoalsFactPeriodEta => 'ครบตามเป้า';

  @override
  String fpGoalsChipPeriodShort(String amount, int days) {
    return 'รอบนี้ขาด $amount | อีก $days วัน';
  }

  @override
  String get fpGoalsChipPeriodDone => 'รอบนี้ครบแล้ว';

  @override
  String fpGoalsArchiveConsequenceMoney(String amount) {
    return 'ซ่อนไว้ | เงิน $amount ไม่นับในยอดออม | กู้คืนได้';
  }

  @override
  String fpGoalsArchiveConfirmBodyMoney(String amount) {
    return 'ซ่อนเป้าหมายนี้ เงิน $amount ที่ออมไว้จะไม่นับในยอดออม กู้คืนได้ภายหลัง';
  }

  @override
  String get savingGoalFormTargetOptionalHint =>
      'เว้นว่าง = ออมต่อเนื่อง ไม่มียอดเป้า';

  @override
  String get sgPlanSection => 'แผนการออม';

  @override
  String get sgPlanSectionDesc => 'ครบเมื่อไร และเริ่มจากเท่าไร';

  @override
  String get sgOpeningLabel => 'เงินออมเริ่มต้น';

  @override
  String get sgOpeningHelp => 'เงินที่มีอยู่แล้ว ลงเป็นรายการออมแรก';

  @override
  String get sgAutoAdd => 'เพิ่มรายการออม';

  @override
  String sgCreatedPartly(String error) {
    return 'สร้างเป้าหมายแล้ว แต่บันทึกบางส่วนไม่สำเร็จ: $error';
  }

  @override
  String get fpGoalsRefreshFailed => 'รีเฟรชไม่สำเร็จ แสดงข้อมูลล่าสุดที่มี';

  @override
  String fpEventsHeroNet(int count) {
    return 'ค้างสุทธิ | $count อีเวนต์';
  }

  @override
  String fpEventsOwedFact(int count) {
    return 'ได้คืน | $count อีเวนต์';
  }

  @override
  String fpEventsOweFact(int count) {
    return 'ต้องจ่าย | $count อีเวนต์';
  }

  @override
  String fpEventsShareFact(int count) {
    return 'ส่วนของฉัน | กำลังทำ $count';
  }

  @override
  String get fpEventsFilterAll => 'ทั้งหมด';

  @override
  String get fpEventsOverBudget => 'เกินงบ';

  @override
  String get fpEventsTileActive => 'กำลังทำ';

  @override
  String get fpEventsTileUnsettled => 'ยังเคลียร์ไม่หมด';

  @override
  String get fpEventsTileEnded => 'จบแล้ว';

  @override
  String get fpEventsSortRecent => 'ล่าสุดก่อน';

  @override
  String get fpEventsSortOldest => 'เก่าสุดก่อน';

  @override
  String get fpEventsSortAmount => 'ยอดมากสุดก่อน';

  @override
  String get fpEventsCreate => 'สร้างอีเวนต์';

  @override
  String fpEventsRowShare(String amount) {
    return 'ส่วนฉัน $amount';
  }

  @override
  String get fpEventsOwed => 'ได้คืน';

  @override
  String get fpEventsOwe => 'ต้องจ่าย';

  @override
  String get fpEventsSpentTotal => 'ใช้ไปรวม';

  @override
  String get fpEventsMyShare => 'ส่วนของฉัน';

  @override
  String get fpEventsIncomeTotal => 'รายรับรวม';

  @override
  String get fpEventsMyTags => 'แท็กของฉัน';

  @override
  String get fpEventsTagPick => 'เลือก';

  @override
  String fpEventsMemberPaid(String amount) {
    return 'จ่าย $amount';
  }

  @override
  String fpEventsMemberOwed(String amount) {
    return 'ได้คืน $amount';
  }

  @override
  String fpEventsMemberOwe(String amount) {
    return 'ต้องจ่าย $amount';
  }

  @override
  String get fpEventsInvite => 'เชิญ';

  @override
  String get fpEventsBillsSearchHint => 'ค้นหารายการในอีเวนต์';

  @override
  String get fpEventsPayerFilter => 'คนจ่าย';

  @override
  String get fpEventsPayerAll => 'ทุกคน';

  @override
  String get fpEventsTagAll => 'ทั้งหมด';

  @override
  String get fpEventsBudgetLabel => 'ตั้งงบไว้ (ไม่บังคับ)';

  @override
  String get fpEventsBudgetHelper =>
      'ยอดที่ตั้งใจจะใช้ | ล้างค่าเพื่อไม่แสดงแผน';

  @override
  String get fpEventsDatesLabel => 'วันเริ่ม – สิ้นสุด';

  @override
  String get fpEventsManageTags => 'จัดการแท็กอีเวนต์';

  @override
  String fpEventsTagsCount(int count) {
    return '$count แท็ก';
  }

  @override
  String get fpEventsArchiveConsequence => 'ซ่อนไว้ ไม่นับในยอด กู้คืนได้';

  @override
  String get fpEventsRestore => 'กู้คืนอีเวนต์';

  @override
  String get fpEventsRestoreConsequence => 'กลับมาเป็นกำลังดำเนินการ';

  @override
  String get fpEventsArchived => 'เก็บถาวรแล้ว';

  @override
  String get fpEventsRestored => 'กู้คืนแล้ว';

  @override
  String get fpEventsArchiveConfirmTitle => 'เก็บถาวรอีเวนต์นี้?';

  @override
  String get fpEventsArchiveConfirmBody =>
      'ซ่อนไว้ ไม่นับในยอด และแก้ไขไม่ได้ กู้คืนได้ทุกเมื่อ';

  @override
  String get fpEventsTagsTitle => 'แท็กอีเวนต์ | ใช้ร่วมกับสมาชิก';

  @override
  String get fpEventsTagAdd => 'เพิ่มแท็กอีเวนต์';

  @override
  String get fpEventsTagsImportAll => 'นำเข้าทั้งหมดไปแท็กของฉัน';

  @override
  String get fpEventsTagRename => 'เปลี่ยนชื่อ';

  @override
  String get fpEventsTagRestyle => 'เปลี่ยนไอคอน/สี';

  @override
  String get fpEventsTagImportOne => 'นำเข้าแท็กของฉัน';

  @override
  String get fpEventsTagNameLabel => 'ชื่อแท็ก';

  @override
  String get fpEventsTagNewTitle => 'แท็กอีเวนต์ใหม่';

  @override
  String get fpEventsTagRenameTitle => 'เปลี่ยนชื่อแท็ก';

  @override
  String get fpEventsTagIconTitle => 'ไอคอนแท็ก';

  @override
  String fpEventsTagDeleteTitle(String name) {
    return 'ลบแท็ก $name?';
  }

  @override
  String get fpEventsTagDeleteBody => 'บิลที่ใช้แท็กนี้จะหลุดแท็ก';

  @override
  String get fpEventsTagsEmpty => 'ยังไม่มีแท็กอีเวนต์';

  @override
  String fpEventsTagBills(int count) {
    return '$count บิล';
  }

  @override
  String get fpEventsTagInMine => 'มีในแท็กของฉันแล้ว';

  @override
  String get fpEventsLoadFailed => 'โหลดใหม่ไม่ได้ | แสดงข้อมูลล่าสุด';

  @override
  String get evbNewBill => 'เพิ่มบิล';

  @override
  String get evbEditBill => 'แก้ไขบิล';

  @override
  String get evbNewPayback => 'จ่ายคืน';

  @override
  String get evbEditPayback => 'แก้ไขการจ่ายคืน';

  @override
  String get evbTypePayback => 'จ่ายคืน';

  @override
  String evbPeople(int count) {
    return 'คนในบิล | $count';
  }

  @override
  String get evbPays => 'จ่าย';

  @override
  String get evbPaidBack => 'คืนแล้ว';

  @override
  String get evbMembersSection => 'คนในอีเวนต์';

  @override
  String evbAddPeopleConfirm(int count) {
    return 'เพิ่ม $count คน';
  }

  @override
  String get evbMyBooks => 'ลงบัญชีของฉันด้วย';

  @override
  String get evbBooked => 'ลงบัญชีแล้ว';

  @override
  String evbBookDebtLine(String name) {
    return 'ฉันค้าง $name';
  }

  @override
  String evbPaybackBy(String name) {
    return 'จ่ายคืน | จดโดย $name';
  }

  @override
  String get evbNoWallet => 'ไม่ตัดกระเป๋า';

  @override
  String get evbTabBills => 'บิล';

  @override
  String get evbTabSummary => 'สรุป';

  @override
  String get evbNets => 'ยอดแต่ละคน';

  @override
  String get evbMembersTitle => 'สมาชิก';

  @override
  String get evbManageMembers => 'จัดการสมาชิก ›';

  @override
  String get evbSettleSection => 'จัดการ';

  @override
  String get evbSettleRecord => 'จดเป็นหนี้';

  @override
  String get evbSettleRecorded => 'จดแล้ว';

  @override
  String get evbBookedDebt => 'ลงหนี้';

  @override
  String get evbBookedTx => 'ลงรายการ';

  @override
  String get evbBookMine => 'ลงบัญชี';

  @override
  String get evbSettleHint =>
      'แตะแถว = จดจ่ายคืนลงอีเวนต์ ใครจดก็ได้ | ปุ่มลงกล่อง = จดเป็นหนี้ของคุณ';

  @override
  String get evbAllSettled => 'เคลียร์กันครบแล้ว';

  @override
  String get evbOnlyMine => 'เฉพาะของฉัน';

  @override
  String get evbNoDebt => 'ไม่เป็นหนี้';

  @override
  String get evbRecordDebt => 'จดหนี้';

  @override
  String get evbIPaid => 'ฉันจ่ายไป';

  @override
  String get evbBackReceived => 'รับคืนแล้ว';

  @override
  String get evbBackSent => 'จ่ายคืนแล้ว';

  @override
  String evbTheyOweMe(String name) {
    return '$name ค้างฉัน';
  }

  @override
  String get evbDebtUp => 'เพิ่มหนี้';

  @override
  String get evbDebtDown => 'ลดหนี้';

  @override
  String get categoryDeleteConsequence => 'ลบถาวร | รายการในหมวดนี้จะไม่มีหมวด';

  @override
  String categoryMonthSpentLabel(String month, int count) {
    return '$month ใช้ไป | $count รายการ ›';
  }

  @override
  String categoryMonthEarnedLabel(String month, int count) {
    return '$month ได้รับ | $count รายการ ›';
  }

  @override
  String get notifGroupRecurring => 'รายการประจำ';

  @override
  String get notifTypeRecurringDue => 'รายการประจำถึงกำหนด';

  @override
  String get notifTypeRecurringEnding => 'รายการประจำใกล้จบ';

  @override
  String get notifTypeRecurringAutoCreated => 'บันทึกอัตโนมัติ';

  @override
  String get settingsSectionApp => 'แอป';

  @override
  String get settingsSectionMoney => 'เงิน';

  @override
  String get settingsCurrencyHint => 'เปลี่ยนแค่ป้าย ไม่แปลงยอด';

  @override
  String get settingsMainWallet => 'กระเป๋าหลัก';

  @override
  String get settingsMoneyStyle => 'รูปแบบตัวเลขเงิน';

  @override
  String get settingsMoneySignPlusMinus => '+ / −';

  @override
  String get settingsMoneySignParentheses => 'วงเล็บ ( )';

  @override
  String get settingsMoneySignNone => 'ไม่มีเครื่องหมาย';

  @override
  String get settingsMoneyColor => 'ใช้สีแดง / เขียว';

  @override
  String get settingsMoneyColorHint => 'รายรับสีเขียว รายจ่ายสีแดง';

  @override
  String get settingsMoneyDecimals => 'ทศนิยม (สตางค์)';

  @override
  String get settingsMoneyDecimalsAlways => 'แสดงปกติ';

  @override
  String get settingsMoneyDecimalsNever => 'ไม่แสดงเลย (ปัดเศษ)';

  @override
  String get settingsMoneyDecimalsAuto => 'ซ่อนเฉพาะ .00';

  @override
  String get settingsMainWalletHint => 'ไม่ตั้ง = ใช้กระเป๋าล่าสุด';

  @override
  String get settingsMainWalletNone => 'ยังไม่ตั้ง';

  @override
  String get settingsArchived => 'ที่เก็บถาวร';

  @override
  String get settingsArchivedHint =>
      'กระเป๋า งบประมาณ เป้าออม รายการประจำ อีเวนต์ ผู้ติดต่อ';

  @override
  String get settingsExportCsv => 'ส่งออก CSV';

  @override
  String get profileSectionSecurity => 'ความปลอดภัย';

  @override
  String get notifTileAll => 'ทั้งหมด';

  @override
  String get notifTileNeedsAnswer => 'ต้องตอบ';

  @override
  String get notifTileUnread => 'ยังไม่อ่าน';

  @override
  String get notifTileHidden => 'ซ่อนไว้';

  @override
  String get notifReadAllTooltip => 'อ่านทั้งหมดแล้ว';

  @override
  String get notifSettingsTooltip => 'ตั้งค่าการแจ้งเตือน';

  @override
  String get notifRestore => 'กู้คืน';

  @override
  String get notifUndo => 'เลิกทำ';

  @override
  String get notifEmptyNeedsAnswer => 'ไม่มีเรื่องที่ต้องตอบ';

  @override
  String get notifEmptyHidden => 'ไม่มีการแจ้งเตือนที่ซ่อนไว้';

  @override
  String get notifActionExtend => 'ต่ออีก';

  @override
  String get notifActionLetEnd => 'ปล่อยให้จบ';

  @override
  String get notifActionOpenDue => 'ไปจัดการ ›';

  @override
  String get archivedGroupWallets => 'กระเป๋า';

  @override
  String get archivedGroupBudgets => 'งบประมาณ';

  @override
  String get archivedGroupGoals => 'เป้าหมาย';

  @override
  String get archivedGroupEvents => 'อีเวนต์';

  @override
  String get archivedGroupContacts => 'ผู้ติดต่อ';

  @override
  String get archivedGroupRecurring => 'รายการประจำ';

  @override
  String archivedOn(String date) {
    return 'เก็บถาวรเมื่อ $date';
  }

  @override
  String get archivedRestore => 'กู้คืน';

  @override
  String archivedSecondaryBalance(String amount) {
    return 'คงเหลือ $amount';
  }

  @override
  String archivedSecondaryLimit(String amount) {
    return 'วงเงิน $amount';
  }

  @override
  String archivedSecondaryTarget(String amount) {
    return 'เป้าหมาย $amount';
  }

  @override
  String archivedSecondaryPlanned(String amount) {
    return 'งบ $amount';
  }

  @override
  String archivedSecondaryAmount(String amount) {
    return 'ยอด $amount';
  }

  @override
  String archivedRestored(String name) {
    return 'กู้คืน $name แล้ว';
  }

  @override
  String get archivedEmpty => 'ไม่มีที่เก็บถาวร';

  @override
  String get archivedEmptyMessage =>
      'สิ่งที่เก็บถาวรไว้จะแสดงที่นี่ กู้คืนได้ทุกเมื่อ';

  @override
  String get txRecurringPick => 'เลือกรายการประจำ';

  @override
  String get txRecurringUnlink => 'เลิกผูก';

  @override
  String get recurringPickerTitle => 'ผูกกับรายการประจำ';

  @override
  String get recurringPickerGroupLikely => 'น่าจะใช่';

  @override
  String get recurringPickerGroupRecurring => 'รายการประจำ';

  @override
  String get recurringPickerGroupReminders => 'เตือนจ่าย';

  @override
  String get recurringPickerAwaitingAmount => 'รอยอด';

  @override
  String get recurringPickerCreate => 'สร้างรายการประจำใหม่จากรายการนี้';

  @override
  String get recurringPickerEmpty => 'ยังไม่มีรายการประจำให้ผูก';

  @override
  String recurringPickerPeriod(String date) {
    return 'งวด $date';
  }

  @override
  String get recurringPickerStatusUpcoming => 'ยังไม่ถึง';

  @override
  String get recurringPickerStatusPending => 'รอยืนยัน';

  @override
  String get recurringPickerStatusNotCreated => 'ยังไม่จ่าย';

  @override
  String get recurringPickerStatusReminder => 'รอใส่ยอด';

  @override
  String recurringLinkAskAmount(String rule, String tx) {
    return 'ยอดไม่ตรงกับที่ตั้งไว้ ($rule → $tx) อัปเดตยอดรายการประจำด้วยไหม?';
  }

  @override
  String get recurringLinkAskNo => 'ไม่ต้อง';

  @override
  String get recurringLinkAskYes => 'อัปเดต';

  @override
  String get recurringLinked => 'ผูกกับรายการประจำแล้ว';

  @override
  String get recurringLinkedAmountUpdated => 'อัปเดตยอดรายการประจำแล้ว';

  @override
  String get recurringLinkAlreadyLinked =>
      'งวดนี้ผูกไปแล้ว (หรือรายการนี้ผูกอยู่แล้ว)';

  @override
  String get recurringPickerGroupNearest => 'งวดใกล้เคียง';

  @override
  String get recurringPickerGroupNext => 'งวดถัดไป';

  @override
  String get recurringPickerGroupPast => 'งวดที่ผ่านมา';

  @override
  String get recurringPickerOtherRule => 'เลือกรายการประจำอื่น';

  @override
  String get recurringLinkSwapTitle => 'สลับรายการที่ผูก?';

  @override
  String recurringLinkSwapBody(String name) {
    return 'งวดนี้ผูกกับ $name อยู่ จะเปลี่ยนมาผูกกับรายการนี้แทน ส่วน $name ยังอยู่ แค่เลิกผูก';
  }

  @override
  String get recurringLinkMoveBody =>
      'รายการนี้ผูกกับงวดอื่นอยู่ จะย้ายมาผูกกับงวดนี้แทน งวดเดิมกลับไปรอจ่าย';

  @override
  String get recurringLinkSwapYes => 'สลับ';

  @override
  String get fpRecurringTabCalendar => 'ปฏิทิน';

  @override
  String get fpRecurringPausedGroup => 'หยุดไว้';

  @override
  String get fpRecurringAwaitingAmount => 'รอยอด';

  @override
  String get fpRecurringKindSubscription => 'ค่าสมาชิก';

  @override
  String get fpRecurringKindInstallment => 'ผ่อนชำระ';

  @override
  String get fpRecurringKindIncome => 'รายรับ';

  @override
  String get fpRecurringKindReminder => 'เตือนจ่าย';

  @override
  String get fpRecurringKindSaving => 'ออมเงิน';

  @override
  String get recurringHomeMonthPayNoSaving => 'จ่ายรวมทั้งเดือน ไม่รวมออมเงิน';

  @override
  String get recurringHomeMonthSave => 'ออมเดือนนี้';

  @override
  String get sgRecurringTitle => 'ทำเป็นรายการประจำ';

  @override
  String get sgPlanTitle => 'วางแผนการออม';

  @override
  String get sgRecurringLabel => 'รายการประจำการออม';

  @override
  String get sgPeriodTarget => 'เป้าต่อรอบ';

  @override
  String get sgPeriodTargetField => 'ยอดต่อรอบ';

  @override
  String get sgPeriodNone => 'ไม่ได้ตั้ง';

  @override
  String get sgPeriodClear => 'ไม่ตั้งเป้าต่อรอบ';

  @override
  String get sgPeriodHelper => 'รอบสุดท้ายใช้เท่าที่เหลือ ไม่เกินยอดเต็ม';

  @override
  String get sgPeriodRule => 'รอบ';

  @override
  String sgPeriodPlanShort(String plan, String target) {
    return 'รายการประจำออมได้ $plan ต่อรอบ ไม่ถึงเป้าต่อรอบ $target';
  }

  @override
  String get sgRecurringSpareCaption => 'ออมเข้ายังไม่จัดสรรตามรอบที่ตั้งไว้';

  @override
  String get fpRecurringRefreshFailed =>
      'รีเฟรชไม่สำเร็จ แสดงข้อมูลล่าสุดที่มี';

  @override
  String get fpRecurringAwaitingValue => 'รอใส่ยอด';

  @override
  String get fpRecurringTileYearly => 'ปีละ';

  @override
  String get fpRecurringTileSaved => 'บันทึกแล้ว';

  @override
  String fpRecurringCountUnit(int n) {
    return '$n งวด';
  }

  @override
  String get fpRecurringTrialUntil => 'ทดลองฟรีถึง';

  @override
  String get fpRecurringTabPast => 'งวดที่ผ่านมา';

  @override
  String get fpRecurringTabUpcoming => 'ล่วงหน้า';

  @override
  String get fpRecurringEditedChip => 'แก้แล้ว';

  @override
  String get fpRecurringActEditAmount => 'แก้ยอด';

  @override
  String get fpRecurringActMove => 'เลื่อนวัน';

  @override
  String get fpRecurringActSkip => 'ข้าม';

  @override
  String get fpRecurringActEnterAmount => 'ใส่ยอด';

  @override
  String get fpRecurringOccEditTitle => 'แก้ไขงวดนี้';

  @override
  String get fpRecurringOccMoveTitle => 'เลื่อนงวดนี้';

  @override
  String get fpRecurringOccEnterTitle => 'ใส่ยอด';

  @override
  String get fpRecurringOccDate => 'วันที่';

  @override
  String get fpRecurringOccAmount => 'ยอดเงิน';

  @override
  String get fpRecurringSkipTitle => 'ข้ามงวดนี้?';

  @override
  String get fpRecurringSkipBody =>
      'งวดนี้จะไม่ขึ้นร่างใน pending กู้คืนได้ภายหลัง';

  @override
  String get fpRecurringAmountLabel => 'จำนวนเงิน / งวด';

  @override
  String get fpRecurringAmountOptional => 'จำนวนเงิน / งวด (ไม่บังคับ)';

  @override
  String get fpRecurringReminderHint =>
      'ไม่ต้องใส่ยอดก็ได้ ถึงวันให้ใส่ยอดจริงในร่าง';

  @override
  String fpRecurringCountValue(int n) {
    return '$n งวด';
  }

  @override
  String get fpRecurringCountRequired => 'ผ่อนชำระต้องระบุจำนวนงวด';

  @override
  String get fpRecurringFieldMode => 'แบบ';

  @override
  String get fpRecurringFieldFromWallet => 'จากกระเป๋า';

  @override
  String get fpRecurringArchiveConsequence =>
      'หยุดสร้างงวดใหม่ ซ่อนไว้ กู้คืนได้';

  @override
  String get fpRecurringRestoreConsequence => 'กลับมาใช้งานและสร้างงวดใหม่ต่อ';

  @override
  String get fpRecurringDeleteConsequence =>
      'ลบรายการประจำนี้ พร้อมงวดที่ยังไม่บันทึก';

  @override
  String get fpRecurringDuplicate => 'ทำสำเนา';

  @override
  String get fpRecurringDuplicateConsequence =>
      'สร้างรายการประจำใหม่ที่เหมือนกัน เริ่มวันนี้';

  @override
  String fpM5ContactDeleteDebts(int n) {
    return 'รายการหนี้ $n รายการ จะเหลือแค่ชื่อ';
  }

  @override
  String fpM5ContactDeleteMembers(int n) {
    return 'เป็นสมาชิกอีเวนต์ $n งาน';
  }

  @override
  String get fpM5ContactDeleteLinked => 'เชื่อมบัญชีอยู่ จะถูกตัดการเชื่อมต่อ';

  @override
  String fpM5BudgetDeleteBody(
    int periods,
    int overridden,
    int categories,
    int wallets,
  ) {
    return 'ลบถาวร $periods รอบ (ปรับเอง $overridden รอบ) | $categories หมวด | $wallets กระเป๋า | รายการธุรกรรมไม่ได้รับผลกระทบ';
  }

  @override
  String fpM5GoalDeleteBody(int n) {
    return 'ลบเป้าหมายนี้ถาวร รายการออม $n รายการจะไม่ผูกกับเป้าหมายอีก';
  }

  @override
  String get fpM5GoalsSortTooltip => 'เรียงลำดับ';

  @override
  String get fpM5GoalsSortCreated => 'เรียงตามสร้าง';

  @override
  String get fpM5GoalsSortDeadline => 'ใกล้ถึงก่อน';

  @override
  String get fpM5GoalsSortProgress => 'ความคืบหน้า';

  @override
  String get fpM5GoalsSortRemaining => 'ที่เหลือ';

  @override
  String get fpM5GoalsSortName => 'ชื่อ';

  @override
  String get fpM5GoalsChartPlan => 'ตามแผน';

  @override
  String fpRecurringSince(String date) {
    return 'ตั้งแต่ $date';
  }

  @override
  String fpRecurringNextOnce(String due) {
    return 'ครั้งถัดไป | $due';
  }

  @override
  String fpRecurringNextInstallment(int n, int total, String due) {
    return 'งวดถัดไป ($n/$total) | $due';
  }

  @override
  String get fpRecurringStatPaid => 'จ่ายแล้ว';

  @override
  String get fpRecurringStatRemaining => 'เหลือ';

  @override
  String get fpRecurringStatLast => 'งวดสุดท้าย';

  @override
  String get fpRecurringStatAvg => 'เฉลี่ย';

  @override
  String get fpRecurringStatPrev => 'ครั้งก่อน';

  @override
  String get fpRecurringStatMax => 'สูงสุด';

  @override
  String fpRecurringAvgLine(String amount) {
    return 'เฉลี่ย $amount';
  }

  @override
  String fpRecurringChainLabel(int done, int total) {
    return 'จ่ายแล้ว $done จาก $total งวด';
  }

  @override
  String get fpRecurringChartLabel => 'ยอดแต่ละครั้ง';

  @override
  String get fpRecurringAutoChip => 'บันทึกอัตโนมัติ';

  @override
  String get fpRecurringTagNext => 'ครั้งถัดไป';

  @override
  String get fpRecurringTagMoved => 'เลื่อนแล้ว';

  @override
  String get fpRecurringTagLast => 'สุดท้าย';

  @override
  String fpRecurringUsualAmount(String amount) {
    return 'ปกติ $amount';
  }

  @override
  String fpRecurringMovedFrom(String date) {
    return 'จาก $date';
  }

  @override
  String get fpRecurringTapToEnter => 'แตะเพื่อใส่ยอด';

  @override
  String get fpRecurringTapToRestore => 'แตะเพื่อยกเลิกการข้าม';

  @override
  String get fpRecurringAutoCreate => 'บันทึกอัตโนมัติเมื่อถึงวัน';

  @override
  String get fpRecurringAutoCreateHint =>
      'ถึงวันแล้วบันทึกเป็นรายการให้เลย ไม่ต้องกดยืนยัน';

  @override
  String get fpM5bRecurringPerMonth => 'ต่อเดือน';

  @override
  String fpM5bRecurringDeleteNumbers(int items, int drafts, int linked) {
    return 'จะลบ $items งวด ร่างที่รออยู่ $drafts รายการ และเกี่ยวข้องกับรายการที่บันทึกแล้ว $linked รายการ';
  }

  @override
  String get fpGoalsFactTargetShort => 'ยังขาดถึงเป้า';

  @override
  String get fpGoalsFactMonthToSave => 'เดือนนี้ต้องออม';

  @override
  String get debtRepayReceive => 'รับคืน';

  @override
  String get debtRecordChip => 'จดหนี้';

  @override
  String get debtSettleChip => 'จ่ายหนี้';

  @override
  String get debtRoleDebtor => 'ลูกหนี้';

  @override
  String get debtRoleCreditor => 'เจ้าหนี้';

  @override
  String debtSummaryDebtor(String name) {
    return '$name เป็นลูกหนี้';
  }

  @override
  String debtSummaryCreditor(String name) {
    return '$name เป็นเจ้าหนี้';
  }

  @override
  String debtSummaryBecomesDebtor(String name) {
    return '$name กลายเป็นลูกหนี้';
  }

  @override
  String debtSummaryBecomesCreditor(String name) {
    return '$name กลายเป็นเจ้าหนี้';
  }

  @override
  String debtSummaryCleared(String name) {
    return 'เคลียร์แล้วกับ $name';
  }

  @override
  String get debtRepayTo => 'จ่ายคืนให้';

  @override
  String get debtRepayFrom => 'รับคืนจาก';

  @override
  String get debtMarkPaidLabel => 'ปิดหนี้';

  @override
  String get debtRepayCleared => 'เคลียร์แล้ว';

  @override
  String get debtRepayPickTitle => 'คนที่ยังค้างกันอยู่';

  @override
  String get debtRepayNoOpen => 'ไม่มีใครค้างกันอยู่';

  @override
  String get txRepaymentCategoryLocked =>
      'รายการจ่ายคืนใช้หมวดของระบบ เปลี่ยนไม่ได้';

  @override
  String get txLinkModeNeedsPayer => 'เลือกคนที่จ่ายแทนก่อน';

  @override
  String get txLinkModeNeedsEvent => 'เลือกอีเวนต์ก่อน';

  @override
  String get txLinkModeUnbalanced =>
      'ยอดยังไม่ลงตัวกับยอดบิล — ดูบรรทัดสถานะในการ์ด';

  @override
  String get txLinkTabSplit => 'แบ่ง';

  @override
  String get txLinkBillLabel => 'ยอดบิล';

  @override
  String get txLinkCardPaidTitle => 'ใครจ่าย และจ่ายเท่าไหร่';

  @override
  String get txLinkCardMyPaid => 'ฉันจ่ายเอง (จากกระเป๋า)';

  @override
  String get txLinkCardWhoPaid => 'ใครจ่าย';

  @override
  String get txLinkCardWhoInBill => 'ใครอยู่ในบิล';

  @override
  String get txLinkCardMe => 'ฉัน';

  @override
  String get txLinkCardSplitOk => '✓ แบ่งครบแล้ว';

  @override
  String get txLinkCardPaidOk => '✓ จ่ายครบแล้ว';

  @override
  String txLinkCardShort(String amount) {
    return 'ยังขาด $amount';
  }

  @override
  String txLinkCardOver(String amount) {
    return 'เกินยอด $amount';
  }

  @override
  String get txLinkCardNewToEvent => 'ใหม่ · เพิ่มเข้าอีเวนต์';

  @override
  String get txLinkAddToEvent => 'เพิ่มในอีเวนต์';

  @override
  String get txPaidBackNeedsWallet => 'คืนแล้วต้องเลือกกระเป๋าที่รับเงิน';

  @override
  String get txLinkBookDebt => 'จดหนี้ด้วย';

  @override
  String get txLinkWalletNotOut => 'ไม่ออกจากกระเป๋า';

  @override
  String txLinkWalletPart(String amount) {
    return 'จ่ายจากกระเป๋า $amount';
  }

  @override
  String txLinkShareIOwe(String name, String amount) {
    return '$name เป็นเจ้าหนี้ $amount';
  }

  @override
  String get txLinkViewPaidLabel => 'จ่ายโดย';

  @override
  String txLinkViewMyPaid(String amount) {
    return 'ฉันจ่ายเอง $amount';
  }

  @override
  String get txLinkViewEventLabel => 'บิลอีเวนต์';

  @override
  String get txLinkViewIPaid => 'ฉันจ่าย';

  @override
  String txLinkViewTheyPaid(String name) {
    return '$nameจ่าย';
  }

  @override
  String txLinkViewPeople(int count) {
    return '$count คน';
  }

  @override
  String get txLinkPreviewTitle => 'ยอดที่จะเปลี่ยน';

  @override
  String txLinkPreviewLine(String name, String before, String after) {
    return '$name: $before → $after';
  }

  @override
  String get txLinkPreviewNone => 'ไม่มียอดคงเหลือของใครเปลี่ยน';

  @override
  String get txLinkOutOfSyncLabel => 'บิลในอีเวนต์ถูกแก้';

  @override
  String get txLinkApplyEvent => 'อัปเดตตามอีเวนต์';

  @override
  String get txLinkApplied => 'อัปเดตตามอีเวนต์แล้ว';

  @override
  String get linkedEventAskTitle => 'แก้ในอีเวนต์ด้วยไหม?';

  @override
  String get linkedMineOnly => 'แก้แค่ของฉัน';

  @override
  String get linkedBoth => 'แก้ทั้งคู่';

  @override
  String get txLinkDraftNeedsExistingEvent =>
      'ร่างผูกได้กับอีเวนต์ที่มีอยู่แล้วเท่านั้น';

  @override
  String debtResultNow(String name) {
    return '$name ตอนนี้';
  }

  @override
  String get debtResultAfterSave => 'หลังบันทึก';

  @override
  String debtResultWallet(String wallet) {
    return 'กระเป๋า $wallet';
  }

  @override
  String get debtWalletNotUsed => 'ไม่เปลี่ยน';

  @override
  String debtOverpayWarn(String after) {
    return 'เกินยอดค้าง — หลังบันทึก $after';
  }

  @override
  String get debtOverpayTitle => 'จ่ายเกินยอดค้าง';

  @override
  String get debtOverpayConfirm => 'บันทึกเลย';

  @override
  String get debtOverpayEdit => 'แก้ยอด';

  @override
  String get debtSomeone => 'เขา';

  @override
  String get debtTxHintLend => 'สร้างรายการจ่ายในกระเป๋า';

  @override
  String get debtTxHintBorrow => 'สร้างรายการรับในกระเป๋า';

  @override
  String get debtTxHintOff => 'ไม่กระทบยอดกระเป๋า';

  @override
  String debtsHeroNet(int count) {
    return 'หนี้สุทธิ | $count คน';
  }

  @override
  String get debtsFilterAll => 'ทั้งหมด';

  @override
  String get debtsOver30Label => 'ค้างเกิน 30 วัน';

  @override
  String debtsPeopleCount(int count) {
    return '$count คน';
  }

  @override
  String debtPersonSince(String month) {
    return 'ติดต่อกันตั้งแต่ $month';
  }

  @override
  String debtPersonSettlePay(String amount) {
    return 'จ่ายคืน $amount';
  }

  @override
  String debtPersonSettleReceive(String amount) {
    return 'รับคืน $amount';
  }

  @override
  String get debtPersonSummary => 'สรุปยอด';

  @override
  String get debtPersonChase => 'ทวง';

  @override
  String debtPersonSummaryTitle(String name) {
    return 'สรุปยอดกับ$name';
  }

  @override
  String debtPersonChaseTitle(String name) {
    return 'ทวงยอดกับ$name';
  }

  @override
  String get debtShareThisCycle => 'รอบนี้';

  @override
  String get debtShareBalanceOnly => 'ยอดคงเหลืออย่างเดียว';

  @override
  String get debtShareFieldLabel => 'ข้อความ (แก้ได้ก่อนส่ง)';

  @override
  String get debtShareSend => 'แชร์ไป LINE / แอปอื่น';

  @override
  String debtDayUp(String amount) {
    return 'เพิ่ม $amount';
  }

  @override
  String debtDayDown(String amount) {
    return 'ลดลง $amount';
  }

  @override
  String debtEarlierShow(String date) {
    return 'เคลียร์แล้ว $date | ดูรอบก่อน ▾';
  }

  @override
  String get debtEarlierShowPlain => 'ดูรอบก่อน ▾';

  @override
  String get debtEarlierHide => 'ซ่อนรอบก่อน ▴';

  @override
  String debtRowTheyPaid(String name) {
    return '$nameจ่ายแทน';
  }

  @override
  String get debtRowIPaid => 'คุณจ่ายแทน';

  @override
  String debtRowSplitBill(String amount) {
    return 'แบ่งบิล $amount';
  }

  @override
  String debtRowEvent(String name) {
    return 'อีเวนต์ $name';
  }

  @override
  String debtRowIPaidBack(String name) {
    return 'คุณจ่ายคืน $name';
  }

  @override
  String debtRowTheyPaidBack(String name) {
    return '$name คืนเงิน';
  }

  @override
  String get debtUnpaidLabel => 'ยังไม่จ่าย';

  @override
  String get debtDueLabel => 'กำหนดจ่าย';

  @override
  String get debtsSectionTotal => 'รวม';

  @override
  String get debtDuePick => 'เลือกวันกำหนดจ่าย';

  @override
  String debtDueOn(String date) {
    return 'ครบกำหนด $date';
  }

  @override
  String debtOverdueDays(int days) {
    return 'เลยกำหนด $days วัน';
  }

  @override
  String debtsOwingDays(int days) {
    return 'ค้างมา $days วันแล้ว';
  }

  @override
  String get debtLinkTx => 'สร้างรายการจากหนี้';

  @override
  String get debtTxNone => 'ยังไม่ผูกรายการ';

  @override
  String debtLinkedAmountDiffers(String amount) {
    return 'ยอดรายการ $amount ไม่ตรงกับหนี้';
  }

  @override
  String debtOriginLabel(String kind) {
    return 'มาจาก ($kind)';
  }

  @override
  String get debtOriginSplit => 'แบ่งบิล';

  @override
  String get debtOriginPaidBy => 'จ่ายแทน';

  @override
  String get debtOriginPartner => 'แบ่งบิลมา';

  @override
  String get debtOriginEvent => 'อีเวนต์';

  @override
  String get debtOriginCash => 'ยืม / ให้ยืม';

  @override
  String get debtOriginLocked => 'แก้ไม่ได้ที่นี่';

  @override
  String get quickCreateBtnTx => 'บันทึก';

  @override
  String get quickCreateBtnDebt => 'จดหนี้';

  @override
  String get quickCreateBtnSaving => 'ออมเงิน';

  @override
  String get debtsEmptyOpenTitle => 'ยังไม่มีหนี้ค้าง';

  @override
  String get debtsEmptyOpenMessage =>
      'จดไว้ว่าใครยืม ใครจ่ายแทน จะได้ไม่ลืมทวง';

  @override
  String get evbReceives => 'รับ';

  @override
  String get txLinkWalletNotIn => 'ไม่เข้ากระเป๋า';

  @override
  String txLinkWalletPartIn(String amount) {
    return 'เข้ากระเป๋า $amount';
  }

  @override
  String get txLinkViewGotLabel => 'รับโดย';

  @override
  String txLinkViewMyGot(String amount) {
    return 'ฉันรับเอง $amount';
  }

  @override
  String get txLinkViewIGot => 'ฉันรับ';

  @override
  String get txLinkCardGotTitle => 'ใครรับ และรับเท่าไหร่';

  @override
  String get txLinkCardMyGot => 'ฉันรับเอง (เข้ากระเป๋า)';

  @override
  String get txLinkCardWhoGot => 'ใครรับ';

  @override
  String get txLinkCardGotOk => '✓ รับครบแล้ว';

  @override
  String txFutureHint(String when) {
    return '$when | นับเข้ายอดเมื่อถึงวันนั้น';
  }

  @override
  String get categorySystemLoanGiven => 'ให้กู้ยืม';

  @override
  String get categorySystemLoanTaken => 'กู้ยืม';

  @override
  String get categorySystemLockedHelper =>
      'หมวดระบบ: เปลี่ยนชื่อและการนับในรายงานไม่ได้';

  @override
  String get debtLinkExistingLabel => 'ผูกกับรายการที่มีอยู่';

  @override
  String get debtLinkedAmountNote => 'ยอดและวันที่ตามรายการที่ผูก';

  @override
  String get debtCloseAllHint => 'ติดป้ายจ่ายแล้วให้หนี้ที่ค้างกับคนนี้ทั้งหมด';

  @override
  String get fpRecurringAutoCreateNeedsWallet => 'ต้องเลือกกระเป๋าก่อน';

  @override
  String get fpRecurringAutoCreateZeroWarn =>
      'ไม่มียอดคงที่: ถึงวันจะบันทึกยอด 0 ให้ไปแก้เอง ไม่เหมาะกับรายการที่ยอดเปลี่ยนทุกงวด (เช่น ค่าไฟ)';

  @override
  String get txLinkDisconnect => 'ตัดการเชื่อม';

  @override
  String get txLinkDisconnectTitle => 'ตัดการเชื่อมกับอีเวนต์?';

  @override
  String get txLinkDisconnected => 'ตัดการเชื่อมแล้ว';

  @override
  String get occurrenceSkipFilled =>
      'งวดนี้มีรายการแล้ว ตัดการเชื่อมรายการก่อนจึงข้ามได้';

  @override
  String get recurringPausedOverdue =>
      'ค้าง 3 งวด: พักไว้แล้ว เคลียร์งวดที่ค้างแล้วกดเริ่มใหม่ จะเริ่มที่งวดปัจจุบัน';

  @override
  String get recurringPausedGoal => 'เป้าหมายออมปิดแล้ว: พักไว้อยู่';

  @override
  String get recurringOverdueLimitChip => 'ค้าง 3 งวด';

  @override
  String get notifTypeDebtDisconnected => 'มีคนตัดการเชื่อมหนี้กับฉัน';

  @override
  String notifDebtDisconnected(String who, String amount) {
    return '$who ตัดการเชื่อมหนี้ $amount แล้ว';
  }

  @override
  String debtDisconnectTitle(String name) {
    return 'ตัดการเชื่อมหนี้กับ $name?';
  }

  @override
  String get debtDisconnectBody =>
      'หนี้นี้จะเป็นหนี้ธรรมดาในสมุดของคุณ แก้ได้เอง การแก้บิลของอีกฝ่ายจะไม่ตามมาอีก อีกฝ่ายจะได้รับแจ้ง';

  @override
  String debtPartnerLinked(String name) {
    return 'เชื่อมกับสมุดของ $name';
  }

  @override
  String get eventCompleteTitle => 'ปิดอีเวนต์ถาวร?';

  @override
  String get eventCompleteBody =>
      'ย้อนกลับไม่ได้ เพิ่มหรือแก้บิลไม่ได้อีก และรายการในสมุดของทุกคนจะเลิกอัปเดตตามอีเวนต์นี้ทันที (ยังเชื่อมกันไว้)';

  @override
  String get eventCompleteConfirm => 'ปิดอีเวนต์';

  @override
  String get eventCompleted => 'ปิดอีเวนต์แล้ว';

  @override
  String get eventCompletedNotice =>
      'อีเวนต์นี้ปิดแล้ว แก้ไขหรือเพิ่มบิลไม่ได้ และสมุดของทุกคนเลิกอัปเดตตามอีเวนต์นี้แล้ว';

  @override
  String get eventErrCompleted => 'อีเวนต์นี้ปิดแล้ว แก้ไขไม่ได้';

  @override
  String get eventErrNotActive => 'ปิดได้เฉพาะอีเวนต์ที่กำลังดำเนินการ';

  @override
  String get eventErrEmptyPerson =>
      'ยังมีบิลที่มีช่องคนว่าง ใส่คนให้ครบก่อนปิดอีเวนต์';

  @override
  String get settingsGroupSync => 'อัปเดตอัตโนมัติ';

  @override
  String get settingsGroupPagePrefs => 'ตัวกรองและการเรียง';

  @override
  String get settingsComingSoon => 'เร็วๆ นี้';

  @override
  String get settingsFontThai => 'ฟอนต์ภาษาไทย';

  @override
  String get settingsFontEnglish => 'ฟอนต์ภาษาอังกฤษ';

  @override
  String get settingsPreview => 'ตัวอย่าง';

  @override
  String get settingsSectionNumbers => 'การแสดงตัวเลข';

  @override
  String get settingsSectionEntryDefaults => 'ค่าเริ่มต้นตอนจดรายการ';

  @override
  String get settingsFeeCategory => 'หมวดค่าธรรมเนียม';

  @override
  String get settingsFeeCategoryHint => 'ใช้ตอนโอนเงินที่มีค่าธรรมเนียม';

  @override
  String get settingsSyncFootnote =>
      'สวิตช์อัตโนมัติชุดเดียวกับในหน้าอีเวนต์และหน้าคน เปลี่ยนที่ไหนก็เป็นค่าเดียวกัน';

  @override
  String get notifSettingsOnOffLegend =>
      'แจ้ง = ส่งแจ้งเตือนเรื่องนี้\nอัตโนมัติ (อีเวนต์ / แบ่งจ่าย) = ไม่ต้องถาม ทำให้เลย\nปิดทั้งสองอย่าง = ไม่แจ้ง และไม่ทำอะไรเลย';

  @override
  String get notifGroupSharedBills => 'บิลที่แชร์';

  @override
  String get notifSetSplitChanged => 'มีคนแก้บิลที่แชร์กับฉัน';

  @override
  String get notifSetSharedBillDeleted => 'มีคนลบบิลที่แชร์กับฉัน';

  @override
  String get notifSetSharedBillDisconnected =>
      'มีคนตัดการเชื่อมบิลที่แชร์กับฉัน';

  @override
  String get notifSetSharedBillDisconnectedHint =>
      'บิลของฉันยังอยู่ แค่ไม่เชื่อมกันแล้ว';

  @override
  String get notifSetDebtDisconnectedHint =>
      'หนี้ของฉันยังอยู่ แค่ไม่เชื่อมกันแล้ว';

  @override
  String get notifSetEventCompleted => 'อีเวนต์ปิดแล้ว';

  @override
  String get notifSetEventInvite => 'เชิญเข้าอีเวนต์';

  @override
  String get notifSetEventInviteHint => 'อัตโนมัติ = เข้าร่วมอีเวนต์เลย';

  @override
  String get notifSetContactLink => 'ขอเชื่อมผู้ติดต่อ';

  @override
  String get notifSetContactLinkHint =>
      'อัตโนมัติ = เชื่อมกับผู้ติดต่อของเขาเลย';

  @override
  String get notifSetWalletInvite => 'ชวนใช้กระเป๋า';

  @override
  String get notifSetWalletInviteHint => 'อัตโนมัติ = เข้าร่วมกระเป๋าเลย';

  @override
  String get notifSetEventCompletedHint =>
      'ล็อกถาวร เลิกอัปเดต เคลมได้ครั้งเดียว';

  @override
  String get notifSetEventMemberRemoved => 'ถูกเอาออกจากอีเวนต์';

  @override
  String get notifSetEventMemberRemovedHint =>
      'รายการที่ลงไว้ยังอยู่ แค่ไม่เชื่อมกันแล้ว';

  @override
  String get notifSetRecurringAutoCreatedHint => 'ระบบลงรายการให้ตามรอบ';

  @override
  String get notifActionAddToBook => 'เพิ่มในสมุด';

  @override
  String get notifActionRemoveMine => 'ลบตาม';

  @override
  String get notifActionKeepMine => 'เก็บไว้';

  @override
  String notifSharedBillCreated(String who, String what) {
    return '$who บันทึกบิล $what ที่คุณมีส่วน';
  }

  @override
  String notifSharedBillDeleted(String who, String what) {
    return '$who ลบบิล $what';
  }

  @override
  String notifSharedBillDisconnected(String who, String what) {
    return '$who ตัดการเชื่อมบิล $what';
  }

  @override
  String notifEventCompleted(String who, String name) {
    return '$who ปิดอีเวนต์ $name แล้ว';
  }

  @override
  String notifEventMemberRemoved(String who, String name) {
    return '$who นำคุณออกจากอีเวนต์ $name';
  }

  @override
  String get notifBillRemovedMine => 'ลบรายการของบิลนี้ออกจากสมุดแล้ว';

  @override
  String get notifBillGone => 'บิลนี้ถูกลบไปแล้ว';

  @override
  String get notifBillDisconnectedMine =>
      'คุณตัดการเชื่อมบิลนี้ไว้ เชื่อมใหม่ได้จากหน้าบิล';

  @override
  String get txLinkDisconnectBodyCopy =>
      'รายการนี้และหนี้จากบิลนี้จะเป็นรายการธรรมดา แก้เองได้ บิลไม่เปลี่ยน และการแก้บิลจะไม่ตามมาอีก';

  @override
  String get evbEmptyPerson => 'ยังไม่ระบุคน';

  @override
  String get evbAssignMe => 'ฉัน';

  @override
  String get evbAssignTitle => 'ใครแทนช่องนี้';

  @override
  String get evbAssignWhose => 'ช่องของใคร';

  @override
  String get evbAssignAction => 'ใส่คน';

  @override
  String get evbAssigned => 'ใส่คนแล้ว';

  @override
  String evbEmptyPersonsNotice(int count) {
    return '$count บิลมีช่องคนว่าง จากคนที่ถูกนำออก ใส่คนให้ครบก่อนปิดอีเวนต์';
  }

  @override
  String get evbBillChanged => 'บิลถูกแก้แล้ว โหลดใหม่ให้แล้ว';

  @override
  String get evbSplitBill => 'บิลแบ่งจ่าย';

  @override
  String get fpRecurringKindDebt => 'หนี้';

  @override
  String get pagePrefSort => 'เรียง';

  @override
  String get pagePrefFilter => 'กรอง';

  @override
  String get pagePrefStatus => 'สถานะ';

  @override
  String get pagePrefKind => 'ประเภท';

  @override
  String get pagePrefLink => 'การผูก';

  @override
  String get pagePrefCollapsed => 'ยุบหมวดแม่';

  @override
  String get pagePrefAll => 'ทั้งหมด';

  @override
  String get pagePrefPendingManual => 'ใส่เอง';

  @override
  String get pagePrefPendingOthers => 'จากคนอื่น';

  @override
  String get pagePrefNone => 'ไม่มี';

  @override
  String get pagePrefsChanged => 'เปลี่ยนแล้ว';

  @override
  String get pagePrefsCaption =>
      'เลือกในหน้าไหน ค่าตรงนี้ก็เปลี่ยนตาม\nแตะเพื่อตั้งเอง';

  @override
  String get pagePrefsFootnote =>
      'แท็บ ช่วงวันที่ และแถบค้นหา เริ่มใหม่ทุกครั้งที่เปิดหน้า';

  @override
  String get pagePrefsResetAll => 'คืนค่าเริ่มต้นทั้งหมด';

  @override
  String get pagePrefsResetAllBody =>
      'ทุกหน้ากลับไปใช้ตัวกรองและการเรียงเริ่มต้น';

  @override
  String get pagePrefsResetPage => 'คืนค่าเริ่มต้นของหน้านี้';

  @override
  String get pagePrefsSetOnPage => 'ตั้งในหน้านั้นเอง';

  @override
  String evbClaimTitle(String name) {
    return 'ลงสมุดของฉัน: $name';
  }

  @override
  String evbClaimTheyOwe(String name) {
    return '$name ติดฉัน';
  }

  @override
  String evbClaimIOwe(String name) {
    return 'ฉันติด $name';
  }

  @override
  String get evbClaimPaybacks => 'คืนเงิน / ให้ยืม';

  @override
  String get evbClaimUntitled => 'บิล';

  @override
  String get evbClaimDone => 'ลงสมุดแล้ว';

  @override
  String get evbClaimNote =>
      'บิลที่เลือกรวมเป็นหนี้ก้อนเดียวกับคนนี้ บิลที่คนอื่นจ่ายจะได้รายการ \"จ่ายโดย\" ของส่วนฉัน';

  @override
  String evbClaimConfirm(int count) {
    return 'ลงสมุด $count บิล';
  }

  @override
  String evbClaimed(String name) {
    return 'ลงสมุดกับ $name แล้ว';
  }

  @override
  String get evbClaimNothing => 'ไม่มีบิลที่ยังไม่ลงสมุด';

  @override
  String get evbClaimMixed => 'เลือกได้ทีละฝั่ง: ติดฉัน หรือ ฉันติด';

  @override
  String get evbClaimAlready => 'บางบิลลงสมุดไปแล้ว';

  @override
  String get evbMyCopy => 'สมุดของฉัน';

  @override
  String evbPaidByName(String name) {
    return 'จ่ายโดย $name';
  }

  @override
  String evbPaidBackName(String name) {
    return 'คืน $name แล้ว';
  }

  @override
  String get evbPrivateNote => 'โน้ตส่วนตัว';

  @override
  String get evbPrivateNoteHint => 'เห็นแค่คุณ';

  @override
  String get evbCopyDisconnected => 'ตัดการเชื่อมไว้ บิลนี้ไม่เข้าสมุดของฉัน';

  @override
  String get evbReconnect => 'เชื่อมใหม่';

  @override
  String get evbCopyOutOfSync => 'สมุดของฉันไม่ตรงกับบิล';

  @override
  String get evbApplyBill => 'อัปเดตตาม';

  @override
  String get debtBillsTitle => 'บิลในหนี้ก้อนนี้';

  @override
  String get debtBillSplit => 'แบ่งจ่าย';

  @override
  String get debtBillOutOfSync => 'ไม่ตรง';

  @override
  String get evbJoinTitle => 'ผูกกับบิลไหน';

  @override
  String evbJoinPaidBy(String name) {
    return '$name จ่าย';
  }

  @override
  String get evbJoined => 'ผูกกับบิลแล้ว';

  @override
  String get evbSettlePairs => 'ตามคู่จริง';

  @override
  String get evbSettleSimplified => 'จ่ายน้อยครั้งสุด';

  @override
  String get evbSettleBook => 'ลงในสมุดฉัน';

  @override
  String get evbSettleBookTitle => 'ลงในสมุดฉันครั้งเดียว?';

  @override
  String get evbSettleBookBody =>
      'เงินที่โอนจริงจะเป็นรายการ หนี้จากบิลที่ลงไว้แล้วจะถูกปิดให้เป็นศูนย์ และลงคู่จริงเพิ่มไม่ได้อีก';

  @override
  String get evbSettleBooked => 'ลงในสมุดฉันแล้ว';

  @override
  String evbSettleBookedOn(String date) {
    return 'ลงในสมุดฉันแล้วเมื่อ $date';
  }

  @override
  String get evbSettleAlreadyBooked => 'ลงในสมุดไปแล้ว';

  @override
  String evbBookLinePay(String name, String amount) {
    return 'จ่าย $name $amount';
  }

  @override
  String evbBookLineGet(String name, String amount) {
    return 'รับจาก $name $amount';
  }

  @override
  String get occurrenceNothingOwed => 'ไม่มียอดค้างกับคนนี้แล้ว';

  @override
  String get recurringPausedNoBalance =>
      'หยุดชั่วคราว: ไม่มียอดค้าง 3 งวด | มีหนี้ใหม่กับคนนี้เมื่อไหร่ เริ่มเองอีกครั้ง';

  @override
  String get recurringNoBalanceChip => 'ไม่มียอดค้าง';

  @override
  String get debtsPersonAddRecurring => 'ตั้งเป็นรายการประจำ';

  @override
  String get occurrenceDebtPickEmpty => 'ไม่มีรายการของคนนี้ที่ผูกได้';

  @override
  String get debtFromEventLabel => 'จากบิลอีเวนต์';

  @override
  String get debtFromEventPick => 'เลือกบิล';

  @override
  String get txJoinBill => 'ผูกกับบิลในอีเวนต์';

  @override
  String get settingsAcceptTitle => 'รับบิลใหม่อัตโนมัติ';

  @override
  String get settingsAutoEventInvites => 'รับคำเชิญเข้าอีเวนต์อัตโนมัติ';

  @override
  String get settingsAutoContactLinks => 'รับคำขอเชื่อมผู้ติดต่ออัตโนมัติ';

  @override
  String get settingsAutoWalletInvites => 'รับคำชวนใช้กระเป๋าอัตโนมัติ';

  @override
  String get settingsAutoRequestCaption =>
      'ใช้กับทุกคำขอ ตั้งที่ การตั้งค่า › การแจ้งเตือน ก็ได้';

  @override
  String get eventDeleteKeepsBills =>
      'ลบแค่อีเวนต์ บิลข้างในยังอยู่ เป็นบิลแบ่งจ่าย ทุกคนยังเชื่อมกันเหมือนเดิม ไม่มีรายการในสมุดของใครถูกลบ';

  @override
  String get eventDeleteKeepsBillsShort => 'บิลข้างในยังอยู่ เป็นบิลแบ่งจ่าย';

  @override
  String get evbPayersLabel => 'คนจ่าย';

  @override
  String evbPayers(int count) {
    return 'คนจ่าย | $count';
  }

  @override
  String get evbAddPayer => 'เพิ่มคนจ่าย';

  @override
  String evbPayersLine(String payers) {
    return 'จ่าย $payers';
  }

  @override
  String get settingsSectionSettings => 'ตั้งค่า';

  @override
  String get settingsSectionData => 'ข้อมูล';

  @override
  String settingsNotificationsSummary(int on, int total, int auto) {
    return 'แจ้ง $on จาก $total เรื่อง | อัตโนมัติ $auto เรื่อง';
  }

  @override
  String settingsPagePrefsChangedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เปลี่ยน $count หน้า',
      zero: 'ยังไม่เปลี่ยน',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionAppearance => 'หน้าตา';

  @override
  String get settingsSectionLanguageFont => 'ภาษาและฟอนต์';

  @override
  String get settingsMoneyStyleHint =>
      'รายรับ / รายจ่ายแสดงด้วยเครื่องหมายแบบไหน';

  @override
  String get settingsMoneyDecimalsHint => 'แสดงสตางค์ไหม';

  @override
  String get notifColumnNotify => 'แจ้ง';

  @override
  String get notifColumnAuto => 'อัตโนมัติ';

  @override
  String get notifAutoAcceptHint => 'อัตโนมัติ = รับเข้าสมุดเลย';

  @override
  String get notifAutoUpdateHint => 'อัตโนมัติ = อัปเดตตามเลย';

  @override
  String get notifAutoDeleteHint =>
      'อีเวนต์: ตามช่องอีเวนต์ของแถว \"มีคนแก้บิลที่แชร์กับฉัน\"\nแบ่งจ่าย: สำเนาของฉันเป็นรายการธรรมดาเสมอ';

  @override
  String get notifSetRecurringDueHint => 'งวดที่ต้องจ่าย / ต้องรับวันนี้';

  @override
  String get notifSetRecurringEndingHint => 'เหลืองวดสุดท้ายแล้ว';

  @override
  String get settingsAutoTitle => 'อัตโนมัติ';

  @override
  String get settingsAutoEventsDescription =>
      'ใช้กับทุกอีเวนต์ ตั้งได้ที่ การตั้งค่า › การแจ้งเตือน';

  @override
  String get settingsAutoDebtsDescription =>
      'ใช้กับทุกคน ตั้งได้ที่ การตั้งค่า › การแจ้งเตือน';

  @override
  String get profileSectionAccount => 'บัญชี';

  @override
  String get pagePrefsResetTitle => 'คืนค่า';

  @override
  String get pagePrefsResetAllHint => 'ทุกหน้ากลับเป็นค่าเริ่มต้น';

  @override
  String get pagePrefsResetPageBody =>
      'หน้านี้กลับไปใช้ตัวกรองและการเรียงเริ่มต้น';

  @override
  String pagePrefSetCount(String title, int count) {
    return '$title $count';
  }

  @override
  String get settingsMainWalletUnsetSummary => 'ยังไม่ตั้งกระเป๋าหลัก';

  @override
  String get pagePrefsSectionPages => 'หน้าในแอป';

  @override
  String connectionConnectingAttempt(int attempt, int attempts) {
    return 'กำลังเชื่อมต่อ… $attempt/$attempts';
  }

  @override
  String get connectionCantConnect => 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';

  @override
  String get connectionsNotLinked => 'ยังไม่เชื่อม';

  @override
  String get connectionsPermissionChat => 'จดรายการผ่านแชต';

  @override
  String get connectionsPermissionAsk => 'ถามยอดเงิน';

  @override
  String get connectionsPermissionSlip => 'ส่งสลิป';

  @override
  String get connectionsPermissionNotify => 'แจ้งเตือน';

  @override
  String get connectionsPermissionLogin => 'เข้าสู่ระบบด้วย Google';

  @override
  String get connectionsPermissionSheets => 'ส่งรายการไป Sheets';

  @override
  String get connectionsPermissionCalendar => 'ลงวันครบกำหนดใน Calendar';

  @override
  String connectionsErrorNoPhoto(String name) {
    return '$name ไม่ส่งรูปให้';
  }

  @override
  String get connectionsErrorLastLoginMethod =>
      'ตั้งรหัสผ่านก่อน ไม่งั้นจะเข้าบัญชีไม่ได้';

  @override
  String get avatarColorsTitle => 'สีและขอบรูป';

  @override
  String avatarColorsSlot(int n) {
    return 'สี $n';
  }

  @override
  String get avatarColorsRingColor => 'สีขอบ';

  @override
  String get avatarColorsClear => 'ล้างสีนี้';

  @override
  String get avatarBorderNone => 'ไม่มี';

  @override
  String get avatarBorderThin => 'บาง';

  @override
  String get avatarBorderThick => 'หนา';

  @override
  String get avatarBorderDashed => 'เส้นประ';

  @override
  String get profileSectionConnections => 'การเชื่อมต่อ';

  @override
  String get profileSectionPicture => 'รูปโปรไฟล์';

  @override
  String get profileSetPassword => 'ตั้งรหัสผ่าน';

  @override
  String get profileSetPasswordSnackSuccess => 'ตั้งรหัสผ่านแล้ว';

  @override
  String profileUsernameReadOnly(String username) {
    return '@$username (แก้ไม่ได้)';
  }

  @override
  String get profilePictureIcon => 'ไอคอน';

  @override
  String get profilePictureUpload => 'อัปโหลดเอง';

  @override
  String get profilePictureEdit => 'แก้';

  @override
  String profilePictureImportedAt(String date) {
    return 'นำเข้าเมื่อ $date';
  }

  @override
  String get profileColorsLabel => 'สีโปรไฟล์ 1–3';

  @override
  String get connectionsTapToLink => 'แตะเพื่อเชื่อม';

  @override
  String get connectionsSectionPermissions => 'สิทธิ์การใช้งาน';

  @override
  String connectionsPhotoFrom(String name) {
    return 'รูปจาก $name';
  }

  @override
  String get connectionsPhotoNotImported => 'ยังไม่ได้นำเข้า';

  @override
  String get connectionsPhotoUpdate => 'อัปเดต';

  @override
  String get connectionsPhotoImport => 'นำเข้า';

  @override
  String connectionsPhotoDeleteTitle(String name) {
    return 'ลบรูปจาก $name?';
  }

  @override
  String get connectionsPhotoDeleteInUse =>
      'ใช้เป็นรูปโปรไฟล์อยู่ ลบแล้วจะใช้ไอคอนแทน';

  @override
  String connectionsChangeAccount(String name) {
    return 'เปลี่ยนบัญชี $name';
  }

  @override
  String get connectionsUnlink => 'ยกเลิกการเชื่อม';

  @override
  String connectionsUnlinkTitle(String name) {
    return 'ยกเลิกการเชื่อม $name?';
  }

  @override
  String connectionsLink(String name) {
    return 'เชื่อม $name';
  }

  @override
  String connectionsLinkedAt(String date) {
    return 'เชื่อมเมื่อ $date';
  }

  @override
  String connectionsOpenFailed(String name) {
    return 'เปิด $name ไม่ได้';
  }

  @override
  String get notifSetBillCreated => 'มีบิลใหม่ที่แชร์กับฉัน';

  @override
  String get notifColumnAutoEvents => 'อีเวนต์';

  @override
  String get notifColumnAutoSplit => 'แบ่งจ่าย';
}
