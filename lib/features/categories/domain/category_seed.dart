import 'category.dart';
import 'category_icon_preset.dart';
import 'category_type.dart';

/// Default seed list every new user receives.
///
/// 60 entries:
/// - **6 system** (auto-managed, hidden from picker, never editable beyond
///   the display name). Spec §2.1.
/// - **11 expense parent + 37 expense subcategories** (user-editable Thai
///   personal-finance taxonomy). Replaces / extends spec §2.2's 28-entry
///   English seed; spec bump pending.
/// - **6 income** (flat — income categories don't carry subcategories in
///   the current taxonomy).
///
/// `description` is filled from the source taxonomy with example text
/// appended. `note` is always null at seed time — that field is for the
/// user's personal context.
List<Category> seedCategories() {
  var order = 0;
  int next() => order++;

  return [
    // ── 6 system categories — hidden from the management page; auto-
    //    assigned by the backend on transfers / opening balances /
    //    adjustments. Spec §2.1.
    Category(
      id: 'sys_opening_balance_in',
      name: 'Opening Balance',
      type: CategoryType.income,
      icon: CategoryIconPreset.systemOpening,
      color: CategoryColor.green,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_opening_balance_out',
      name: 'Opening Balance',
      type: CategoryType.expense,
      icon: CategoryIconPreset.systemOpening,
      color: CategoryColor.red,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_adjustment_in',
      name: 'Adjustment',
      type: CategoryType.income,
      icon: CategoryIconPreset.systemAdjustment,
      color: CategoryColor.brown,
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_adjustment_out',
      name: 'Adjustment',
      type: CategoryType.expense,
      icon: CategoryIconPreset.systemAdjustment,
      color: CategoryColor.brown,
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_transfer_in',
      name: 'Transfer In',
      type: CategoryType.income,
      icon: CategoryIconPreset.systemTransfer,
      color: CategoryColor.cyan,
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_transfer_out',
      name: 'Transfer Out',
      type: CategoryType.expense,
      icon: CategoryIconPreset.systemTransfer,
      color: CategoryColor.cyan,
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),

    // ── Expense — Food & Drinks
    ..._parentWithChildren(
      parentId: 'food_drinks',
      parentName: 'Food & Drinks',
      parentIcon: CategoryIconPreset.restaurant,
      color: CategoryColor.orange,
      next: next,
      children: const [
        _Sub(
          'groceries',
          'Groceries',
          CategoryIconPreset.shoppingBasket,
          'สำหรับของสด, วัตถุดิบ, และน้ำดื่มที่ซื้อมาตุนทำเองที่บ้าน',
          'Examples: เนื้อสัตว์, ผัก, เครื่องปรุง, ข้าวสาร, น้ำแพ็ค',
        ),
        _Sub(
          'food_delivery',
          'Food Delivery',
          CategoryIconPreset.deliveryDining,
          'สำหรับยอดรวมบิลจากแอปฯ สั่งอาหารและสินค้าต่างๆ',
          'Examples: GrabFood, LINE MAN, ShopeeFood, 7-Delivery',
        ),
        _Sub(
          'convenience_store',
          'Convenience Store',
          CategoryIconPreset.convenienceStore,
          'สำหรับของกินและของใช้เล็กน้อยจากร้านสะดวกซื้อ',
          'Examples: ขนม, น้ำอัดลม, ไส้กรอก, ของเวฟใน 7-Eleven',
        ),
        _Sub(
          'buffet',
          'Buffet',
          CategoryIconPreset.restaurantMenu,
          'สำหรับร้านอาหารแบบบุฟเฟต์ทุกประเภท',
          'Examples: ปิ้งย่าง, ชาบู, บุฟเฟต์โรงแรม, ซูชิสายพาน',
        ),
        _Sub(
          'dining_take_away',
          'Dining / Take-away',
          CategoryIconPreset.restaurant,
          'สำหรับมื้ออาหารที่ไปนั่งทานที่ร้าน หรือซื้อกลับบ้าน',
          'Examples: กินข้าวแกง, ก๋วยเตี๋ยว, อาหารตามสั่ง',
        ),
      ],
    ),

    // ── Expense — Transportation
    ..._parentWithChildren(
      parentId: 'transportation',
      parentName: 'Transportation',
      parentIcon: CategoryIconPreset.directionsCar,
      color: CategoryColor.blue,
      next: next,
      children: const [
        _Sub(
          'fuel',
          'Fuel',
          CategoryIconPreset.localGasStation,
          'ค่าน้ำมันเชื้อเพลิงที่เติมเมื่อมีการเดินทาง',
          'Examples: เติมน้ำมันแก๊สโซฮอล์ 95, ดีเซล B7',
        ),
        _Sub(
          'tolls_parking',
          'Tolls / Parking',
          CategoryIconPreset.localParking,
          'ค่าใช้จ่ายที่เกิดขึ้นระหว่างการเดินทางเพื่อความสะดวก/รวดเร็ว',
          'Examples: ค่าทางด่วน, ค่าที่จอดรถตามห้าง',
        ),
        _Sub(
          'public_transit',
          'Public Transit',
          CategoryIconPreset.directionsBus,
          'ค่าเดินทางด้วยระบบขนส่งสาธารณะทุกประเภท',
          'Examples: BTS, MRT, รถเมล์, เรือด่วน, วินมอเตอร์ไซค์',
        ),
        _Sub(
          'taxi_rideshare',
          'Taxi / Rideshare',
          CategoryIconPreset.localTaxi,
          'ค่าเดินทางด้วยบริการรถรับจ้างส่วนบุคคลผ่านแอปฯ หรือโบกเรียก',
          'Examples: Grab Car, Bolt, แท็กซี่มิเตอร์',
        ),
      ],
    ),

    // ── Expense — Vehicle
    ..._parentWithChildren(
      parentId: 'vehicle',
      parentName: 'Vehicle',
      parentIcon: CategoryIconPreset.carRepair,
      color: CategoryColor.indigo,
      next: next,
      children: const [
        _Sub(
          'insurance_tax',
          'Insurance / Tax',
          CategoryIconPreset.policy,
          'ค่าใช้จ่ายรายปีที่จำเป็นเพื่อให้รถใช้งานได้ตามกฎหมาย',
          'Examples: ประกันภัยชั้น 1, พ.ร.บ., ภาษีรถยนต์ประจำปี',
        ),
        _Sub(
          'maintenance',
          'Maintenance',
          CategoryIconPreset.carRepair,
          'ค่าใช้จ่ายในการดูแลรักษารถทั้งเชิงป้องกัน, แก้ไข, และความสะอาด',
          'Examples: เข้าศูนย์เช็คระยะ, เปลี่ยนยาง, ซ่อมแอร์, ล้างรถ',
        ),
      ],
    ),

    // ── Expense — Shopping
    ..._parentWithChildren(
      parentId: 'shopping',
      parentName: 'Shopping',
      parentIcon: CategoryIconPreset.shoppingBag,
      color: CategoryColor.pink,
      next: next,
      children: const [
        _Sub('apparel', 'Apparel', CategoryIconPreset.checkroom,
            'ของใช้ส่วนตัวเพื่อการแต่งกาย เพิ่มบุคลิกภาพ',
            'Examples: เสื้อผ้า, กางเกง, รองเท้า, นาฬิกา, กระเป๋า'),
        _Sub('gadgets_it', 'Gadgets / IT', CategoryIconPreset.headphones,
            'อุปกรณ์อิเล็กทรอนิกส์พกพา, อุปกรณ์เสริมคอม/มือถือ',
            'Examples: หูฟัง, Power Bank, เมาส์, คีย์บอร์ด, สายชาร์จ'),
        _Sub('home_electronics', 'Home & Electronics', CategoryIconPreset.tv,
            'ของใช้และเครื่องใช้ไฟฟ้าชิ้นใหญ่ในบ้าน (คงทน)',
            'Examples: ทีวี, ตู้เย็น, ของแต่งบ้าน, เครื่องครัว'),
        _Sub('personal_care', 'Personal Care',
            CategoryIconPreset.faceRetouching,
            'ของใช้ส่วนตัวที่ใช้แล้วหมดไป (สิ้นเปลือง)',
            'Examples: สบู่, ยาสีฟัน, แชมพู, โฟมล้างหน้า, เครื่องสำอาง'),
        _Sub('household_supplies', 'Household Supplies',
            CategoryIconPreset.cleaningServices,
            'ของใช้ในบ้านที่ใช้แล้วหมดไป (สิ้นเปลือง)',
            'Examples: น้ำยาล้างจาน, ผงซักฟอก, ทิชชู่, ถ่านไฟฉาย'),
        _Sub('hobby_art', 'Hobby / Art', CategoryIconPreset.palette,
            'ของที่ใช้สำหรับทำงานอดิเรกหรืองานศิลปะโดยเฉพาะ',
            'Examples: สีน้ำ, สมุดสเก็ตช์, ซื้อ Brush/Asset ในแอปวาดรูป'),
      ],
    ),

    // ── Expense — Bills
    ..._parentWithChildren(
      parentId: 'bills',
      parentName: 'Bills',
      parentIcon: CategoryIconPreset.receiptLong,
      color: CategoryColor.red,
      next: next,
      children: const [
        _Sub('housing', 'Housing', CategoryIconPreset.home,
            'ค่าใช้จ่ายคงที่และจำเป็นเพื่อให้มีที่อยู่อาศัย',
            'Examples: ค่าเช่าห้อง/คอนโด, ค่าน้ำ, ค่าไฟ, ค่าส่วนกลาง'),
        _Sub('communication', 'Communication', CategoryIconPreset.wifi,
            'ค่าใช้จ่ายเพื่อให้สามารถติดต่อสื่อสารและเข้าถึงอินเทอร์เน็ตได้',
            'Examples: ค่าเน็ตบ้าน, ค่าโทรศัพท์มือถือรายเดือน'),
      ],
    ),

    // ── Expense — Services
    ..._parentWithChildren(
      parentId: 'services',
      parentName: 'Services',
      parentIcon: CategoryIconPreset.handshake,
      color: CategoryColor.cyan,
      next: next,
      children: const [
        _Sub('subscriptions', 'Subscriptions',
            CategoryIconPreset.subscriptions,
            'ค่าบริการรายเดือน/ปี เพื่อเข้าถึงเนื้อหาหรือแอปพลิเคชันต่างๆ',
            'Examples: Netflix, YouTube Premium, Spotify, iCloud'),
        _Sub('personal_services', 'Personal', CategoryIconPreset.spa,
            'ค่าบริการที่ทำเพื่อดูแลตัวเองเป็นครั้งคราว',
            'Examples: ค่าตัดผม, ทำสปา, นวด, ซักรีด'),
        _Sub('fitness', 'Fitness', CategoryIconPreset.fitnessCenter,
            'ค่าบริการที่เกี่ยวกับการออกกำลังกายและสุขภาพ',
            'Examples: ค่าสมาชิกฟิตเนส, คลาสโยคะ'),
      ],
    ),

    // ── Expense — Health & Medical
    ..._parentWithChildren(
      parentId: 'health_medical',
      parentName: 'Health & Medical',
      parentIcon: CategoryIconPreset.localHospital,
      color: CategoryColor.green,
      next: next,
      children: const [
        _Sub('doctor_meds', 'Doctor / Meds',
            CategoryIconPreset.medicalServices,
            'ค่าใช้จ่ายเมื่อเจ็บป่วย หรือซื้อยาเพื่อรักษา/บำรุง',
            'Examples: ค่าหาหมอ, ค่ายาตามใบสั่งแพทย์, วิตามิน'),
        _Sub('vision_dental', 'Vision / Dental', CategoryIconPreset.visibility,
            'ค่าใช้จ่ายเกี่ยวกับสายตาและทันตกรรมโดยเฉพาะ',
            'Examples: ตัดแว่น, ซื้อคอนแทคเลนส์, ขูดหินปูน, อุดฟัน'),
      ],
    ),

    // ── Expense — Entertainment
    ..._parentWithChildren(
      parentId: 'entertainment',
      parentName: 'Entertainment',
      parentIcon: CategoryIconPreset.movie,
      color: CategoryColor.purple,
      next: next,
      children: const [
        _Sub('gaming', 'Gaming', CategoryIconPreset.sportsEsports,
            'ค่าใช้จ่ายที่เกี่ยวกับการเล่นเกมทั้งหมด',
            'Examples: ซื้อเกม (Steam), เติมเงินในเกม, ซื้อเครื่องเกม'),
        _Sub('media_books', 'Media / Books', CategoryIconPreset.theaters,
            'ค่าใช้จ่ายเพื่อความบันเทิงผ่านสื่อต่างๆ',
            'Examples: ตั๋วหนัง, คอนเสิร์ต, งานอีเวนต์, ซื้อหนังสือ'),
        _Sub('hangouts', 'Hangouts', CategoryIconPreset.nightlife,
            'ค่าใช้จ่ายเพื่อเข้าสังคมหรือทำกิจกรรมนอกบ้าน',
            'Examples: ไปร้านเหล้า, คาเฟ่บอร์ดเกม, คาราโอเกะ'),
        _Sub('travel', 'Travel', CategoryIconPreset.flight,
            'ค่าใช้จ่ายที่เกิดขึ้น "เพราะ" การท่องเที่ยวโดยตรง',
            'Examples: ค่าตั๋วเครื่องบิน, ค่าโรงแรม, ค่าเช่ารถ'),
      ],
    ),

    // ── Expense — Investments
    ..._parentWithChildren(
      parentId: 'investments',
      parentName: 'Investments',
      parentIcon: CategoryIconPreset.trendingUp,
      color: CategoryColor.green,
      next: next,
      children: const [
        _Sub('savings', 'Savings', CategoryIconPreset.savings,
            'การโอนเงินไปเก็บในบัญชีเงินออมโดยเฉพาะ',
            'Examples: ฝากเงินเข้าบัญชีเงินฝากประจำ, ออมทอง'),
        _Sub('financial_assets', 'Financial Assets',
            CategoryIconPreset.trendingUp,
            'เงินที่ใช้ซื้อสินทรัพย์ทางการเงินทุกประเภทเพื่อหวังผลตอบแทน',
            'Examples: ซื้อกองทุนรวม, หุ้น, หุ้นกู้, Cryptocurrency'),
        _Sub('speculative', 'Speculative', CategoryIconPreset.casino,
            'การลงทุนในรูปแบบอื่นๆ ที่มีความเสี่ยงเฉพาะตัวหรือไม่เป็นทางการ',
            'Examples: ให้เพื่อนยืมเงิน (กินดอกเบี้ย), เล่นแชร์'),
      ],
    ),

    // ── Expense — Debt Repayments
    ..._parentWithChildren(
      parentId: 'debt_repayments',
      parentName: 'Debt Repayments',
      parentIcon: CategoryIconPreset.creditCard,
      color: CategoryColor.red,
      next: next,
      children: const [
        _Sub('credit_card', 'Credit Card', CategoryIconPreset.creditCard,
            'การจ่ายเพื่อชำระยอดบัตรเครดิต "ของตัวเราเอง"',
            'Examples: จ่ายบัตรเครดิต KTC, จ่ายบัตร Citi'),
        _Sub('bnpl', 'BNPL', CategoryIconPreset.schedule,
            'การชำระยอดบริการ "ซื้อก่อนจ่ายทีหลัง"',
            'Examples: จ่าย SPayLater, จ่าย LazPay, จ่าย Atome'),
        _Sub('personal_loan', 'Personal Loan', CategoryIconPreset.handshake,
            'การชำระหนี้ส่วนตัวคืนให้กับบุคคล',
            'Examples: คืนเงินที่ยืมแฟน, คืนเงินที่ยืมคุณแม่'),
      ],
    ),

    // ── Expense — Other
    // Note: the "Adjustments" sub-category from the original taxonomy is
    // intentionally omitted — Adjustment is a system category (see
    // sys_adjustment_in / sys_adjustment_out above) auto-assigned by the
    // backend on `POST /v1/accounts/:id/adjust-balance`. Surfacing it as a
    // user-editable sibling would be a confusing duplicate.
    ..._parentWithChildren(
      parentId: 'other_expense',
      parentName: 'Other',
      parentIcon: CategoryIconPreset.moreHoriz,
      color: CategoryColor.brown,
      next: next,
      children: const [
        _Sub('miscellaneous', 'Miscellaneous', CategoryIconPreset.moreHoriz,
            'รายจ่ายเบ็ดเตล็ดทั่วไปที่จำเป็น แต่ไม่เข้าพวกหมวดหมู่อื่น',
            'Examples: ค่าธรรมเนียมธนาคาร, ค่าซองจดหมาย, ค่าถ่ายเอกสาร'),
        _Sub(
          'lending_pay_for_others',
          'Lending / Pay for Others',
          CategoryIconPreset.volunteerActivism,
          'เงินที่จ่ายแทนคนอื่นไปก่อน หรือให้ยืม',
          'Examples: จ่ายค่าข้าวให้เพื่อน, ให้แฟนยืมเงิน',
          includeInReport: false,
        ),
      ],
    ),

    // ── Income (flat — no subcategories)
    Category(
      id: 'salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: CategoryIconPreset.payments,
      color: CategoryColor.green,
      description: 'เงินเดือนจากงานประจำ หรือรายรับหลัก',
      sortOrder: next(),
    ),
    Category(
      id: 'side_hustle_freelance',
      name: 'Side Hustle / Freelance',
      type: CategoryType.income,
      icon: CategoryIconPreset.work,
      color: CategoryColor.cyan,
      description: 'รายได้จากงานเสริม, งานฟรีแลนซ์, หรือโปรเจกต์พิเศษ',
      sortOrder: next(),
    ),
    Category(
      id: 'online_sales',
      name: 'Online Sales',
      type: CategoryType.income,
      icon: CategoryIconPreset.storefront,
      color: CategoryColor.orange,
      description: 'รายได้จากการขายของออนไลน์ทุกประเภท',
      sortOrder: next(),
    ),
    Category(
      id: 'reimbursements_payback',
      name: 'Reimbursements / Payback',
      type: CategoryType.income,
      icon: CategoryIconPreset.swapHoriz,
      color: CategoryColor.brown,
      description: 'เงินที่คนอื่นคืนให้ ซึ่งไม่ใช่รายได้ที่แท้จริงของเรา',
      includeInReport: false,
      sortOrder: next(),
    ),
    Category(
      id: 'other_income',
      name: 'Other Income',
      type: CategoryType.income,
      icon: CategoryIconPreset.redeem,
      color: CategoryColor.yellow,
      description: 'รายรับอื่นๆ ที่ไม่เข้าพวก เช่น เงินปันผล, ดอกเบี้ย',
      sortOrder: next(),
    ),
    // (income-side "Adjustment" intentionally omitted — same reason as
    // the expense-side: the system category sys_adjustment_in covers it.)
  ];
}

class _Sub {
  const _Sub(
    this.id,
    this.name,
    this.icon,
    this.description,
    this.example, {
    this.includeInReport = true,
  });
  final String id;
  final String name;
  final CategoryIconPreset icon;
  final String description;
  final String example;
  final bool includeInReport;
}

List<Category> _parentWithChildren({
  required String parentId,
  required String parentName,
  required CategoryIconPreset parentIcon,
  required CategoryColor color,
  required int Function() next,
  required List<_Sub> children,
}) {
  return [
    Category(
      id: parentId,
      name: parentName,
      type: CategoryType.expense,
      icon: parentIcon,
      color: color,
      sortOrder: next(),
    ),
    for (final child in children)
      Category(
        id: child.id,
        name: child.name,
        parentId: parentId,
        type: CategoryType.expense,
        icon: child.icon,
        color: color,
        description: '${child.description} ${child.example}',
        includeInReport: child.includeInReport,
        sortOrder: next(),
      ),
  ];
}
