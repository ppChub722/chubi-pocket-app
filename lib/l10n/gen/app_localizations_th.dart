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
  String get commonDiscard => 'ทิ้ง';

  @override
  String get commonDiscardTitle => 'ทิ้งการแก้ไข?';

  @override
  String get commonDiscardBody => 'การแก้ไขที่ยังไม่บันทึกจะหายไป';

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
  String get contactPickerSearchHint => 'ค้นหาผู้ติดต่อ หรือพิมพ์ชื่อ';

  @override
  String contactPickerUseName(String name) {
    return 'ใช้ชื่อ \"$name\"';
  }

  @override
  String get contactPickerUseNameHint => 'ไม่บันทึกเป็นผู้ติดต่อ';

  @override
  String get contactPickerEmpty => 'ยังไม่มีผู้ติดต่อ — พิมพ์ชื่อด้านบนได้เลย';

  @override
  String get commonShowAmounts => 'แสดงยอดเงิน';

  @override
  String get commonHideAmounts => 'ซ่อนยอดเงิน';

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
  String get accountsAddNew => 'เพิ่มกระเป๋า';

  @override
  String get accountsReorderHint =>
      'ลากที่ ≡ เพื่อจัดลำดับ ลำดับนี้เป็นของคุณคนเดียว ไม่กระทบสมาชิกกระเป๋าแชร์';

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
  String get accountDetailAdjustBalance => 'ปรับยอด';

  @override
  String get accountDetailArchive => 'เก็บเข้าคลัง';

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
  String get accountDetailTabOverview => 'ภาพรวม';

  @override
  String get accountFormTitle => 'กระเป๋าใหม่';

  @override
  String get accountFormTitleEdit => 'แก้ไขกระเป๋า';

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
  String get accountFormBalanceLabel => 'ยอดเริ่มต้น';

  @override
  String get accountFormBalanceHelper =>
      'เงินที่มีอยู่ในกระเป๋านี้ ณ วันที่เริ่มติดตาม';

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
  String get accountAdjustBalanceTitle => 'ปรับยอดเงิน';

  @override
  String get accountAdjustBalanceCurrentLabel => 'ยอดปัจจุบัน';

  @override
  String get accountAdjustBalanceNewLabel => 'ยอดใหม่';

  @override
  String get accountAdjustBalanceNoteLabel => 'บันทึก (ไม่บังคับ)';

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
  String get accountFormDescriptionHelper =>
      'ใช้สำหรับอะไร เห็นเฉพาะคุณคนเดียว';

  @override
  String get accountFormNoteHelper =>
      'บันทึกส่วนตัว (เช่น \"เงินไปเที่ยวญี่ปุ่น\")';

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
  String get projectsPlaceholderTitle => 'ยังไม่มีโปรเจกต์';

  @override
  String get projectsPlaceholderMessage => 'โปรเจกต์ร่วมจะมาในเฟส 1b';

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
  String get contactTitleEdit => 'แก้ไขผู้ติดต่อ';

  @override
  String get contactNotFound => 'ไม่พบผู้ติดต่อ';

  @override
  String get contactNameLabel => 'ชื่อ';

  @override
  String get contactNameHint => 'ชื่อ (จำเป็น)';

  @override
  String get contactEmailHint => 'ไม่บังคับ · name@example.com';

  @override
  String get contactPhoneHint => 'ไม่บังคับ · 081-234-5678';

  @override
  String get contactNotesHint => 'ไม่บังคับ · เช่น เพื่อนที่ทำงาน';

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
  String get contactNotesLabel => 'บันทึก';

  @override
  String get contactLinkedBadge => 'เชื่อมกับบัญชีผู้ใช้';

  @override
  String get contactLinkedLockedHint => 'ชื่อและอีเมลมาจากบัญชีของเขา';

  @override
  String get contactArchivedBadge => 'เก็บถาวร';

  @override
  String get contactSectionActions => 'การจัดการ';

  @override
  String get contactLinkTitle => 'เชื่อมบัญชี';

  @override
  String get contactLinkLinked =>
      'เชื่อมแล้ว — ชื่อ อีเมล และไอคอนตามบัญชีของเขา';

  @override
  String get contactLinkRequest => 'ส่งคำขอเชื่อม';

  @override
  String get contactLinkRequestHint =>
      'ถ้าอีเมลนี้เป็นของผู้ใช้ในแอป เขาจะได้รับคำขอ';

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
  String get contactWireTitle => 'จับคู่ชื่อในรายการหาร';

  @override
  String contactWireHint(int names, int splits) {
    return '$names ชื่อ · $splits รายการ ที่ยังไม่ผูกผู้ติดต่อ';
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
  String get debtsNet => 'สุทธิ';

  @override
  String get debtsOwedToMe => 'ติดคุณ';

  @override
  String get debtsIOwe => 'คุณติด';

  @override
  String get debtsEven => 'เคลียร์แล้ว';

  @override
  String get debtsSearchHint => 'ค้นหาชื่อ';

  @override
  String get debtsStatusLabel => 'สถานะ';

  @override
  String get debtsStatusOpen => 'ค้างอยู่';

  @override
  String get debtsStatusAll => 'ทั้งหมด';

  @override
  String debtsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ค้าง $count รายการ',
      zero: 'ไม่มีค้าง',
    );
    return '$_temp0';
  }

  @override
  String get debtsEmptyTitle => 'ยังไม่มีหนี้';

  @override
  String get debtsEmptyMessage =>
      'บันทึกว่าใครติดเงินคุณ หรือคุณติดเงินใคร — หรือหารบิลจากรายการ';

  @override
  String get debtsNoMatch => 'ไม่พบคนที่ค้นหา';

  @override
  String get debtsAddNew => 'บันทึกหนี้';

  @override
  String debtsPersonHistory(int count) {
    return 'ประวัติ ($count)';
  }

  @override
  String get debtsPersonAdd => 'บันทึกหนี้กับคนนี้';

  @override
  String get debtsPersonLinkContact => 'ผูกกับผู้ติดต่อ';

  @override
  String get debtsPersonLinkContactHint => 'รวมหนี้ของชื่อนี้เข้ากับผู้ติดต่อ';

  @override
  String debtsPersonLinked(int count, String name) {
    return 'ผูก $count รายการกับ $name แล้ว';
  }

  @override
  String get debtsPersonOpenContact => 'ดูผู้ติดต่อ';

  @override
  String debtTheyOweYou(String name) {
    return '$name ติดคุณ';
  }

  @override
  String debtYouOwe(String name) {
    return 'คุณติด $name';
  }

  @override
  String get debtStatusSettled => 'คืนครบแล้ว';

  @override
  String get debtStatusCancelled => 'ยกเลิก';

  @override
  String get debtOutstanding => 'คงค้าง';

  @override
  String debtProgress(String paid, String total) {
    return 'คืนแล้ว $paid จาก $total';
  }

  @override
  String get debtReceive => 'รับเงินคืน';

  @override
  String get debtPay => 'จ่ายคืน';

  @override
  String get debtAmount => 'ยอดเต็ม';

  @override
  String get debtSettled => 'คืนแล้ว';

  @override
  String get debtSource => 'ที่มา';

  @override
  String get debtSourceManual => 'บันทึกเอง';

  @override
  String get debtSourceTransaction => 'หารบิลจากรายการ';

  @override
  String get debtSourceProject => 'โปรเจกต์';

  @override
  String get debtNote => 'บันทึก';

  @override
  String get debtCreatedAt => 'วันที่สร้าง';

  @override
  String get debtCounterparty => 'กับใคร';

  @override
  String get debtCounterpartyPlaceholder => 'เลือกผู้ติดต่อ หรือพิมพ์ชื่อ';

  @override
  String get debtCounterpartyRequired => 'เลือกหรือพิมพ์ชื่อ';

  @override
  String get debtCancel => 'ยกเลิกหนี้นี้';

  @override
  String get debtCancelTitle => 'ยกเลิกหนี้นี้?';

  @override
  String get debtCancelBody =>
      'ไม่มีเงินเคลื่อนไหว ใช้ตอนยกหนี้ให้ หรือบันทึกผิด';

  @override
  String get debtCancelled => 'ยกเลิกหนี้แล้ว';

  @override
  String get debtDeleteTitle => 'ลบหนี้นี้?';

  @override
  String get debtDeleteBody => 'ลบถาวร ย้อนกลับไม่ได้';

  @override
  String get debtDeleted => 'ลบหนี้แล้ว';

  @override
  String get debtNewTitle => 'บันทึกหนี้';

  @override
  String get debtEditTitle => 'แก้ไขหนี้';

  @override
  String get debtDirectionOwedToMe => 'เขาติดฉัน';

  @override
  String get debtDirectionOwedToMeDesc => 'ฉันให้ยืม หรือออกเงินแทนเขา';

  @override
  String get debtDirectionIOwe => 'ฉันติดเขา';

  @override
  String get debtDirectionIOweDesc => 'ฉันยืมมา หรือเขาออกให้ก่อน';

  @override
  String get debtAmountRequired => 'ใส่ยอดมากกว่า 0';

  @override
  String debtAmountBelowSettled(String amount) {
    return 'ต้องไม่น้อยกว่ายอดที่คืนแล้ว ($amount)';
  }

  @override
  String debtSettleTitleReceive(String name) {
    return 'รับเงินคืนจาก $name';
  }

  @override
  String debtSettleTitlePay(String name) {
    return 'จ่ายคืน $name';
  }

  @override
  String get debtSettleAll => 'ทั้งหมด';

  @override
  String get debtSettleHalf => 'ครึ่งหนึ่ง';

  @override
  String debtSettleOver(String amount) {
    return 'เกินยอดคงค้าง ($amount)';
  }

  @override
  String get debtSettleAccount => 'กระเป๋า';

  @override
  String get debtSettleAccountRequired => 'เลือกกระเป๋า';

  @override
  String get debtSettleDate => 'วันที่';

  @override
  String get debtSettleConfirm => 'ยืนยัน';

  @override
  String get debtSettleDone => 'บันทึกการคืนเงินแล้ว';

  @override
  String get projectStatusActive => 'กำลังดำเนินการ';

  @override
  String get projectStatusCompleted => 'เสร็จสิ้น';

  @override
  String get projectStatusCancelled => 'ยกเลิก';

  @override
  String get projectStatusArchived => 'เก็บถาวร';

  @override
  String get projectsStatusAll => 'ทั้งหมด';

  @override
  String get projectsStatusLabel => 'สถานะ';

  @override
  String get projectsSearchHint => 'ค้นหาโปรเจกต์';

  @override
  String get projectsSortRecent => 'ล่าสุด';

  @override
  String get projectsSortName => 'ชื่อ';

  @override
  String get projectsEmptyTitle => 'ยังไม่มีโปรเจกต์';

  @override
  String get projectsEmptyMessage =>
      'รวมรายจ่ายของทริปหรืองานไว้ที่เดียว แล้วเคลียร์ยอดกับเพื่อนตอนจบ';

  @override
  String get projectsNoMatch => 'ไม่พบโปรเจกต์ที่ค้นหา';

  @override
  String projectsMembersCount(int count) {
    return '$count สมาชิก';
  }

  @override
  String get projectTabDashboard => 'แดชบอร์ด';

  @override
  String get projectTabTransactions => 'รายการ';

  @override
  String get projectTabResolve => 'เคลียร์ยอด';

  @override
  String get projectAddTransaction => 'เพิ่มรายการ';

  @override
  String get projectNewTitle => 'โปรเจกต์ใหม่';

  @override
  String get projectEditTitle => 'แก้ไขโปรเจกต์';

  @override
  String get projectNameLabel => 'ชื่อโปรเจกต์';

  @override
  String get projectNameRequired => 'ต้องใส่ชื่อ';

  @override
  String get projectTypeLabel => 'ประเภท';

  @override
  String get projectTypeHint => 'เช่น ทริป งานฟรีแลนซ์';

  @override
  String get projectDescriptionLabel => 'รายละเอียด';

  @override
  String get projectIconLabel => 'ไอคอนโปรเจกต์';

  @override
  String get projectStatusChangeTitle => 'เปลี่ยนสถานะ';

  @override
  String projectStatusLockTitle(String status) {
    return 'เปลี่ยนเป็น $status?';
  }

  @override
  String get projectStatusLockBody =>
      'โปรเจกต์จะถูกล็อก — เพิ่มหรือแก้รายการไม่ได้จนกว่าจะเปิดอีกครั้ง';

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
  String get projectDeleteBody =>
      'ลบได้เฉพาะโปรเจกต์ที่ยังไม่มีรายการ · ถ้ามีรายการแล้ว ให้เปลี่ยนสถานะเป็นเก็บถาวรแทน';

  @override
  String get projectDeleted => 'ลบโปรเจกต์แล้ว';

  @override
  String get projectDashTotalExpense => 'รายจ่ายรวม';

  @override
  String get projectDashTotalIncome => 'รายรับรวม';

  @override
  String get projectDashMembers => 'สมาชิก';

  @override
  String get projectDashWhoPaid => 'ใครจ่ายเท่าไร';

  @override
  String get projectDashTopTags => 'แท็กที่ใช้มากสุด';

  @override
  String get projectDashRecent => 'ล่าสุด';

  @override
  String get projectDashSeeAll => 'ดูทั้งหมด';

  @override
  String projectDashTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
      zero: 'ยังไม่มีรายการ',
    );
    return '$_temp0';
  }

  @override
  String get projectTxSearchHint => 'ค้นหารายการ';

  @override
  String get projectTxTypeLabel => 'ประเภท';

  @override
  String get projectTxTypeAll => 'ทั้งหมด';

  @override
  String get projectTxTypeExpense => 'รายจ่าย';

  @override
  String get projectTxTypeIncome => 'รายรับ';

  @override
  String get projectTxOnlyMine => 'เฉพาะฉัน';

  @override
  String get projectTxSortTime => 'วันที่';

  @override
  String get projectTxSortAmount => 'ยอด';

  @override
  String get projectTxSortMember => 'คนจ่าย';

  @override
  String get projectTxSortTag => 'แท็ก';

  @override
  String get projectTxEmpty => 'ยังไม่มีรายการในโปรเจกต์';

  @override
  String get projectTxNoMatch => 'ไม่พบรายการที่ค้นหา';

  @override
  String projectTxOwes(String name) {
    return 'ติด $name';
  }

  @override
  String get projectTxUnmark => 'ยกเลิกการติ๊ก';

  @override
  String get projectTxResolve => 'ลงบัญชีส่วนตัว';

  @override
  String get projectTxResolveHint => 'สร้างรายการหรือหนี้ในบัญชีของคุณ';

  @override
  String get projectTxEdit => 'แก้ไขรายการ';

  @override
  String get projectTxDelete => 'ลบรายการ';

  @override
  String get projectTxDeleteTitle => 'ลบรายการนี้?';

  @override
  String get projectTxDeleteBody => 'ยอดหารที่ผูกกับรายการนี้จะถูกลบด้วย';

  @override
  String get projectTxDeleted => 'ลบรายการแล้ว';

  @override
  String get projectResolveAsTx => 'เป็นรายการ';

  @override
  String get projectResolveAsDebt => 'เป็นหนี้';

  @override
  String get projectResolveShareOnly => 'ใช้เฉพาะส่วนของฉัน';

  @override
  String projectResolveShareHint(String full, String share) {
    return 'เต็ม $full · ส่วนของฉัน $share';
  }

  @override
  String get projectResolveAmount => 'ยอด';

  @override
  String get projectResolveCategory => 'หมวดหมู่ (ไม่บังคับ)';

  @override
  String get projectResolveCategoryNone => 'ไม่ระบุหมวด';

  @override
  String get projectResolveDebtHint => 'ชื่อคนมาจากสมาชิกในโปรเจกต์';

  @override
  String get projectResolveConfirm => 'ลงบัญชี';

  @override
  String get projectResolveDone => 'ลงบัญชีแล้ว';

  @override
  String get projectResolveComingSoon =>
      'หน้าสรุปการเคลียร์ยอดกำลังมา — ตอนนี้ติ๊กเคลียร์ได้จากแท็บรายการ';

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
  String projectMyPosition(String paid, String share) {
    return 'ของฉัน: จ่ายไป $paid · ส่วนของฉัน $share';
  }

  @override
  String get projectMyNet => 'สุทธิ';

  @override
  String get projectMemberLinked => 'มีบัญชีในแอป';

  @override
  String get projectMemberAdHoc => 'ไม่มีบัญชีในแอป';

  @override
  String get projectMembersInvite => 'เชิญสมาชิก';

  @override
  String get projectLeave => 'ออกจากโปรเจกต์';

  @override
  String projectLeaveTitle(String name) {
    return 'ออกจาก $name?';
  }

  @override
  String get projectLeaveBody =>
      'คุณจะไม่เห็นโปรเจกต์นี้อีก จนกว่าจะได้รับเชิญใหม่';

  @override
  String get projectLeft => 'ออกจากโปรเจกต์แล้ว';

  @override
  String get projectMemberRemove => 'นำออกจากโปรเจกต์';

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
      'ใส่อีเมลเพื่อเชิญผู้ใช้ในแอป · เว้นว่าง = สมาชิกที่ไม่มีบัญชี';

  @override
  String get projectAddMemberFromContacts => 'เลือกจากผู้ติดต่อ';

  @override
  String get projectAddMemberSubmit => 'เพิ่ม';

  @override
  String projectAddMemberAdded(String name) {
    return 'เพิ่ม $name แล้ว';
  }

  @override
  String get projectTxNewTitle => 'เพิ่มรายการโปรเจกต์';

  @override
  String get projectTxEditTitle => 'แก้ไขรายการ';

  @override
  String get projectTxPaidBy => 'ใครจ่าย';

  @override
  String get projectTxReceivedBy => 'ใครรับ';

  @override
  String get projectTxNote => 'บันทึก';

  @override
  String get projectTxTags => 'แท็ก';

  @override
  String get projectTxAddTag => 'แท็กใหม่';

  @override
  String get projectTxTagHint => 'ชื่อแท็ก';

  @override
  String get projectTxDescriptionHint => 'คำอธิบาย';

  @override
  String projectTxDescriptionUse(String text) {
    return 'ใช้ \"$text\"';
  }

  @override
  String get projectTxDescriptionPast => 'เคยใช้ในโปรเจกต์นี้';

  @override
  String get projectTxSplitMember => 'ใคร';

  @override
  String get projectTxSplits => 'หารกับ';

  @override
  String get projectTxSplitsHint =>
      'แต่ละคนติดคนจ่ายเท่าไร · คนจ่ายรับส่วนที่เหลือ';

  @override
  String get projectTxAddSplit => 'เพิ่มการหาร';

  @override
  String get projectTxSplitEqual => 'หารเท่ากัน';

  @override
  String projectTxSplitsOver(String sum) {
    return 'ยอดหารรวม ($sum) เกินยอดรวม';
  }

  @override
  String projectTxPayerKeeps(String amount) {
    return 'ส่วนของคนจ่าย $amount';
  }

  @override
  String get projectTxAmountRequired => 'ใส่ยอดมากกว่า 0';

  @override
  String get settingsThemeMint => 'มิ้นต์';

  @override
  String get settingsThemeSweet => 'สวีท';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsNotificationsHint =>
      'เรื่องที่อยากรับ และสิ่งที่ทำให้อัตโนมัติ';

  @override
  String get settingsDefaultCurrencyHint =>
      'ใช้เป็นค่าเริ่มต้นตอนสร้างกระเป๋าและหนี้';

  @override
  String get settingsCurrencySaved => 'เปลี่ยนสกุลเงินเริ่มต้นแล้ว';

  @override
  String get settingsFontSample => 'ตัวอย่าง ภาษาไทย ABC 123';

  @override
  String get notificationsTitle => 'การแจ้งเตือน';

  @override
  String get notificationsTabAll => 'ทั้งหมด';

  @override
  String get notificationsTabUnread => 'ยังไม่อ่าน';

  @override
  String get notificationsMarkAllRead => 'อ่านทั้งหมดแล้ว';

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
  String notifSplitPaid(String actor) {
    return '$actor จ่ายส่วนของเขาแล้ว';
  }

  @override
  String notifSplitReceived(String actor) {
    return '$actor ยืนยันว่าได้รับเงินแล้ว';
  }

  @override
  String notifProjectTxForYou(String actor) {
    return '$actor บันทึกรายการโปรเจกต์ให้คุณ';
  }

  @override
  String notifProjectTxChanged(String actor) {
    return '$actor แก้ไขรายการในโปรเจกต์';
  }

  @override
  String notifProjectInvite(String actor, String project) {
    return '$actor ชวนคุณเข้าโปรเจกต์ $project';
  }

  @override
  String notifContactLink(String actor) {
    return '$actor ขอเชื่อมเป็นผู้ติดต่อ';
  }

  @override
  String get notifUnknown => 'การแจ้งเตือน';

  @override
  String get notifAccepted => 'ตอบรับแล้ว · แตะเพื่อเปิด';

  @override
  String get notifRejectTitle => 'ปฏิเสธคำขอนี้?';

  @override
  String get notifRejectBody => 'อีกฝ่ายจะไม่ได้รับแจ้งว่าคุณปฏิเสธ';

  @override
  String get notifHidden => 'ซ่อนแล้ว';

  @override
  String get notifSettingsTitle => 'ตั้งค่าการแจ้งเตือน';

  @override
  String get notifSettingsReceive => 'การแจ้งเตือนที่ได้รับ';

  @override
  String get notifGroupSplits => 'การหารบิล';

  @override
  String get notifGroupProjects => 'โปรเจกต์';

  @override
  String get notifGroupRequests => 'คำเชิญและคำขอ';

  @override
  String get notifTypeSplitCreated => 'มีคนหารบิลกับฉัน';

  @override
  String get notifTypeSplitPaid => 'มีคนจ่ายส่วนของเขาคืน';

  @override
  String get notifTypeProjectTxForYou => 'มีคนบันทึกรายการโปรเจกต์ให้ฉัน';

  @override
  String get notifTypeProjectTxChanged => 'มีการแก้ไขรายการในโปรเจกต์';

  @override
  String get notifTypeAlwaysOn => 'เปิดตลอด';

  @override
  String get notifTypeProjectAdded => 'ถูกเพิ่มเข้าโปรเจกต์';

  @override
  String get notifSettingsAutoHint =>
      '\"อัตโนมัติ\" = พอแจ้งเตือนมาถึง ระบบกดปุ่มให้เลย · ปิดรับแจ้งเตือนประเภทไหน ประเภทนั้นจะไม่ทำอะไรเลย · คำเชิญและคำขอปิดไม่ได้ เพราะต้องตอบ';

  @override
  String get notifAutoAddDebt => 'อัตโนมัติ: เพิ่มเข้าหนี้ของฉัน';

  @override
  String get notifAutoRecordPayment => 'อัตโนมัติ: บันทึกรับเงิน';

  @override
  String get notifAutoCopyToBook => 'อัตโนมัติ: บันทึกเข้าบัญชีส่วนตัว';

  @override
  String get notifAutoUpdateCopy => 'อัตโนมัติ: อัปเดตรายการส่วนตัวตาม';

  @override
  String get notifAutoResolveProject =>
      'บันทึกรายการที่ฉันจ่ายเองลงบัญชีส่วนตัวด้วย';

  @override
  String get notifActionAddDebt => 'เพิ่มเข้าหนี้ของฉัน';

  @override
  String get notifActionRecordReceipt => 'บันทึกรับเงิน';

  @override
  String get notifActionCopyToBook => 'บันทึกเข้าบัญชีส่วนตัว';

  @override
  String get notifActionUpdateCopy => 'อัปเดตตาม';

  @override
  String get notifActionSkip => 'ข้าม';

  @override
  String get notifActionDone => 'ทำแล้ว · แตะเพื่อเปิด';

  @override
  String notifProjectAdded(String actor, String project) {
    return '$actor เพิ่มคุณเข้าโปรเจกต์ $project';
  }

  @override
  String get notifDefaultAccount => 'กระเป๋าที่รับเงิน';

  @override
  String get notifDefaultAccountNone => 'ยังไม่ได้เลือก';

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
  String get homeComingUp => 'เร็วๆ นี้';

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
  String get homeUncategorized => 'ไม่มีหมวด';

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
  String homeDebtsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ค้าง $count รายการ',
    );
    return '$_temp0';
  }

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
  String get homePrevMonth => 'เดือนก่อน';

  @override
  String get homeNextMonth => 'เดือนถัดไป';

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
  String get txDetailAccount => 'กระเป๋า';

  @override
  String get txDetailCategory => 'หมวด';

  @override
  String get txDetailTags => 'แท็ก';

  @override
  String get txDetailNote => 'บันทึก';

  @override
  String get txDetailSplits => 'การหาร';

  @override
  String get txDetailHasSplits => 'มีการหารกับคนอื่น';

  @override
  String get txDetailRecordedBy => 'ผู้บันทึก';

  @override
  String get txDetailSource => 'ที่มา';

  @override
  String get txDetailSourceProject => 'โปรเจกต์';

  @override
  String get txDetailTransferTo => 'ไปที่';

  @override
  String get txDetailBalanceAfter => 'ยอดคงเหลือหลังรายการ';

  @override
  String get txDeleted => 'ลบรายการแล้ว';

  @override
  String get txSplitAdd => 'เพิ่มการหาร';

  @override
  String get txSplitWith => 'หารกับ';

  @override
  String get txSplitEqually => 'หารเท่ากัน';

  @override
  String get txSplitCollapse => 'ยกเลิกการหาร';

  @override
  String get txSplitAddPerson => 'เพิ่มคน';

  @override
  String txSplitRemaining(String amount) {
    return 'ส่วนของคุณ $amount';
  }

  @override
  String get txSplitWiredContact => 'ผูกกับผู้ติดต่อแล้ว';

  @override
  String get txSplitName => 'ชื่อ';

  @override
  String get txSplitOwes => 'ติด';

  @override
  String get txSplitRemove => 'นำออก';

  @override
  String get txSplitExceeds => 'ยอดหารรวมเกินยอดรายการ';

  @override
  String get txSavedTagsFailed =>
      'บันทึกรายการแล้ว แต่ใส่แท็กไม่สำเร็จ แก้แท็กในรายการได้';

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
  String get authRegisterUsernameHint => 'a-z 0-9 _ - · 3–50 ตัว';

  @override
  String get authRegisterPasswordHint => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get authRegisterEmailHint => 'ใช้ให้เพื่อนเชื่อมบัญชีกับคุณได้';

  @override
  String get authLanguage => 'ภาษา';

  @override
  String get accountsTotalShared => 'กองกลาง';

  @override
  String get accountsSummaryNet => 'ยอดสุทธิของฉัน';

  @override
  String get accountsSummaryAssets => 'เงินที่มี';

  @override
  String get accountsSummaryDebt => 'หนี้บัตร / จ่ายทีหลัง';

  @override
  String accountsSummaryCreditUsed(int pct, String left) {
    return 'ใช้วงเงิน $pct% · เหลือ $left';
  }

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
  String get accountDetailNote => 'บันทึก';

  @override
  String get accountArchiveHasMembers =>
      'กระเป๋าที่ยังมีสมาชิกอื่นเก็บถาวรไม่ได้ — นำสมาชิกออกก่อน';

  @override
  String get accountArchived => 'เก็บกระเป๋าแล้ว';

  @override
  String get txSplitOver => 'ยอดหารรวมเกินยอดรายการ';

  @override
  String get txSplitFreeText =>
      'พิมพ์ชื่อเอง — เลือกจากรายชื่อที่แนะนำเพื่อผูกผู้ติดต่อ';

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
  String get moreGroupLibrary => 'คลังข้อมูล';

  @override
  String get moreGroupPeople => 'คนและเงินร่วม';

  @override
  String get moreGroupPlanning => 'วางแผน';

  @override
  String get moreCategoriesDesc => 'จัดกลุ่มรายรับ-รายจ่าย';

  @override
  String get moreTagsDesc => 'ติดป้ายให้ค้นง่าย';

  @override
  String get moreContactsDesc => 'คนที่หารบิลด้วย';

  @override
  String get moreProjectsDesc => 'ทริปและงบร่วมกัน';

  @override
  String get moreDebtsDesc => 'ใครติดใครเท่าไร';

  @override
  String get moreBudgetsDesc => 'ตั้งเพดานการใช้จ่าย';

  @override
  String get moreSavingGoalsDesc => 'เก็บเงินให้ถึงเป้า';

  @override
  String get moreScheduledDesc => 'บิลประจำและที่จะถึง';

  @override
  String moreLiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0';
  }

  @override
  String moreLiveDebts(String owed, String owe) {
    return 'เขาติด $owed · คุณติด $owe';
  }

  @override
  String moreLiveDueSoon(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ถึงกำหนด $count รายการใน $days วัน',
    );
    return '$_temp0';
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
  String get categoryFormIconLabel => 'ไอคอน';

  @override
  String get categoryFormColorLabel => 'สี';

  @override
  String get categoryFormDescriptionLabel => 'คำอธิบาย';

  @override
  String get categoryFormDescriptionTooLong => 'สูงสุด 200 ตัวอักษร';

  @override
  String get categoryFormNoteLabel => 'บันทึกย่อ';

  @override
  String get categoryFormNoteTooLong => 'สูงสุด 200 ตัวอักษร';

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
    return 'รายการ $count รายการจะกลายเป็น ไม่มีหมวด';
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
  String get debtDeleteThis => 'ลบหนี้นี้';

  @override
  String get projectDeleteThis => 'ลบโปรเจกต์นี้';

  @override
  String get scheduledDeleteThis => 'ลบรายการตามกำหนดนี้';

  @override
  String get transactionDeleteThis => 'ลบรายการนี้';

  @override
  String get categoriesReorderEnter => 'จัดลำดับ';

  @override
  String get categoriesReorderSave => 'บันทึก';

  @override
  String get categoriesReorderDiscard => 'ยกเลิก';

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
  String get tagDeleteConfirmBody =>
      'จะลบแท็กออกจากรายการที่ใช้แท็กนี้ ไม่สามารถย้อนกลับได้';

  @override
  String get tagDeleteConfirmAction => 'ลบ';

  @override
  String get tagFormTitleEdit => 'แก้ไขแท็ก';

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
  String get changePasswordSubmit => 'อัปเดตรหัสผ่าน';

  @override
  String get changePasswordSnackSuccess => 'อัปเดตรหัสผ่านแล้ว';

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
  String get quickSave => 'บันทึก';

  @override
  String get quickSaved => 'บันทึกแล้ว';

  @override
  String get quickNoteHint => 'โน้ต (ไม่บังคับ)';

  @override
  String get quickMore => 'รายละเอียดเพิ่ม';

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
  String get quickDiscardTitle => 'ปิดโดยไม่บันทึก?';

  @override
  String get quickDiscardMessage => 'สิ่งที่กรอกไว้จะหายไป';

  @override
  String get quickDiscardConfirm => 'ทิ้ง';

  @override
  String get quickDiscardKeep => 'กลับไปแก้ต่อ';

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
  String get quickEventNew => 'สร้างอีเวนต์ใหม่';

  @override
  String get quickEventNameLabel => 'ชื่ออีเวนต์';

  @override
  String get quickEventCreate => 'สร้าง';

  @override
  String get quickEventExisting => 'หรือเพิ่มเข้าอีเวนต์ที่มีอยู่';

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
  String get pendingScanning => 'กำลังอ่านสลิป…';

  @override
  String get pendingScanDone => 'นำเข้าสลิปแล้ว';

  @override
  String get pendingSelectAll => 'เลือกทั้งหมด';

  @override
  String get pendingSelectNone => 'ไม่เลือก';

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
    return 'บันทึกแล้ว $done · ค้าง $failed';
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
  String get pendingUntitled => 'ไม่มีโน้ต';

  @override
  String get pendingSourceManual => 'ใส่เอง';

  @override
  String get pendingSourceSplitPaid => 'จ่ายแล้ว';

  @override
  String get pendingSourceProject => 'โปรเจกต์';

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
  String get pendingSavedAsDraft => 'เก็บเป็นร่างแล้ว · อยู่ในรอยืนยัน';

  @override
  String get pendingSaveDraft => 'บันทึกร่าง';

  @override
  String get pendingSubmitThis => 'ยืนยันรายการนี้';

  @override
  String get pendingEditTitle => 'แก้ร่าง';

  @override
  String get pendingDiscardTitle => 'ทิ้งร่างนี้?';

  @override
  String get pendingKeepAsDraft => 'เก็บเป็นร่าง';

  @override
  String get pendingDropEditsTitle => 'ทิ้งการแก้ไข?';

  @override
  String get pendingDropEditsMessage => 'ร่างจะกลับไปเป็นแบบเดิม';

  @override
  String pendingBlockTitle(int count) {
    return 'รอยืนยัน $count รายการ';
  }

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
  String get transactionFormTagsEmpty => 'ยังไม่มีแท็ก สร้างได้จากหน้าแท็ก';

  @override
  String get transactionFormSave => 'บันทึก';

  @override
  String get transactionFormAccountNone => 'ไม่มีกระเป๋า';

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
  String get transactionsListEmptyMessage => 'ไม่มีรายการตรงตัวกรอง';

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
  String get savingGoalFormIconLabel => 'ไอคอน';

  @override
  String get savingGoalFormNameLabel => 'ชื่อเป้าหมาย';

  @override
  String get savingGoalFormNameRequired => 'จำเป็น';

  @override
  String get savingGoalFormLinkedAccountLabel => 'กระเป๋าที่เชื่อม';

  @override
  String get savingGoalFormAccountRequired => 'เลือกกระเป๋าที่เชื่อม';

  @override
  String get savingGoalFormTargetLabel => 'ยอดเป้าหมาย';

  @override
  String get savingGoalFormTargetInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get savingGoalFormAllocationLabel => 'การจัดสรร';

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
  String get savingGoalDetailArchive => 'เก็บถาวร';

  @override
  String savingGoalDetailOfTarget(String target) {
    return 'จาก $target';
  }

  @override
  String get savingGoalDetailRemaining => 'คงเหลือ';

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
  String get budgetFormCategoryLabel => 'หมวดหมู่';

  @override
  String get budgetFormCategoryPlaceholder => 'เลือกหมวดหมู่';

  @override
  String get budgetFormCategoryRequired => 'เลือกหมวดหมู่';

  @override
  String get budgetFormAmountLabel => 'เพดานต่อรอบ';

  @override
  String get budgetFormAmountInvalid => 'ใส่จำนวนที่มากกว่าศูนย์';

  @override
  String get budgetFormPeriodLabel => 'รอบ';

  @override
  String get budgetFormNoteLabel => 'หมายเหตุ';

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
  String get scheduledFormSave => 'สร้าง';

  @override
  String get scheduledFormIconLabel => 'ไอคอน';

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
  String get scheduledDetailPause => 'พักไว้';

  @override
  String get scheduledDetailResume => 'ใช้งานต่อ';

  @override
  String get scheduledDetailCancel => 'ยกเลิก';

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
  String get scheduledStatusChangeTitle => 'เปลี่ยนสถานะ';

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
  String projectMetaPlanned(String amount) {
    return 'งบ $amount';
  }

  @override
  String projectPlannedLine(String planned, String remaining) {
    return 'ตั้งงบไว้ $planned · เหลือ $remaining';
  }

  @override
  String projectPlannedOverLine(String over) {
    return '🔴 เกินงบ $over';
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
  String get transactionSplitWithTitle => 'หารกับ...';

  @override
  String get transactionSplitShareTitle => 'แบ่งให้... (เราติดเงินเขา)';

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
  String get budgetNameLabel => 'ชื่องบ';

  @override
  String budgetsOverviewSpent(String spent, String total) {
    return 'ใช้ไป $spent จาก $total';
  }

  @override
  String budgetsOverviewOverCount(int count) {
    return 'เกิน $count งบ';
  }

  @override
  String get transactionsSearchHint => 'ค้นหาโน้ต · หมวด · กระเป๋า';

  @override
  String get savingGoalAllocationAuto => 'อัตโนมัติ';

  @override
  String get accountSharingSectionTitle => 'การแชร์และรายงาน';

  @override
  String get accountFormOpeningDebtLabel => 'ยอดค้างชำระตอนเริ่ม';

  @override
  String get accountFormOpeningDebtHelper =>
      'ยอดที่ยังค้างจ่าย ณ วันที่เริ่มติดตาม (ไม่มีให้ใส่ 0)';

  @override
  String get accountAdjustBalanceNewDebtLabel => 'ยอดค้างชำระใหม่';

  @override
  String get accountAdjustBalanceDiffLabel => 'ส่วนต่าง';

  @override
  String accountAdjustBalanceWillCreate(String amount) {
    return 'ระบบจะสร้างรายการ \"ปรับยอด\" $amount ลงวันนี้';
  }

  @override
  String get scheduledSheetTitleNew => 'ตั้งรายการประจำ';

  @override
  String get scheduledSheetTitleEdit => 'แก้รายการประจำ';
}
