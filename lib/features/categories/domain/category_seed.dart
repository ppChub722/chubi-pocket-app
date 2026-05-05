import '../../../shared/icon_maker/brand_palette.dart';
import '../../../shared/icon_maker/icon_code.dart';
import 'category.dart';
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
      iconCode: _bg('system_opening', BrandPalette.green),
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_opening_balance_out',
      name: 'Opening Balance',
      type: CategoryType.expense,
      iconCode: _bg('system_opening', BrandPalette.red),
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_adjustment_in',
      name: 'Adjustment',
      type: CategoryType.income,
      iconCode: _bg('system_adjustment', BrandPalette.brown),
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_adjustment_out',
      name: 'Adjustment',
      type: CategoryType.expense,
      iconCode: _bg('system_adjustment', BrandPalette.brown),
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_transfer_in',
      name: 'Transfer In',
      type: CategoryType.income,
      iconCode: _bg('system_transfer', BrandPalette.cyan),
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),
    Category(
      id: 'sys_transfer_out',
      name: 'Transfer Out',
      type: CategoryType.expense,
      iconCode: _bg('system_transfer', BrandPalette.cyan),
      includeInReport: false,
      isSystem: true,
      sortOrder: next(),
    ),

    // ── Expense — Food & Drinks
    ..._parentWithChildren(
      parentId: 'food_drinks',
      parentName: 'Food & Drinks',
      parentIconId: 'restaurant',
      color: BrandPalette.orange,
      next: next,
      children: const [
        _Sub(
          'groceries',
          'Groceries',
          'shopping_basket',
          'สำหรับของสด, วัตถุดิบ, และน้ำดื่มที่ซื้อมาตุนทำเองที่บ้าน',
          'Examples: เนื้อสัตว์, ผัก, เครื่องปรุง, ข้าวสาร, น้ำแพ็ค',
        ),
        _Sub(
          'food_delivery',
          'Food Delivery',
          'delivery_dining',
          'สำหรับยอดรวมบิลจากแอปฯ สั่งอาหารและสินค้าต่างๆ',
          'Examples: GrabFood, LINE MAN, ShopeeFood, 7-Delivery',
        ),
        _Sub(
          'convenience_store',
          'Convenience Store',
          'convenience_store',
          'สำหรับของกินและของใช้เล็กน้อยจากร้านสะดวกซื้อ',
          'Examples: ขนม, น้ำอัดลม, ไส้กรอก, ของเวฟใน 7-Eleven',
        ),
        _Sub(
          'buffet',
          'Buffet',
          'restaurant_menu',
          'สำหรับร้านอาหารแบบบุฟเฟต์ทุกประเภท',
          'Examples: ปิ้งย่าง, ชาบู, บุฟเฟต์โรงแรม, ซูชิสายพาน',
        ),
        _Sub(
          'dining_take_away',
          'Dining / Take-away',
          'restaurant',
          'สำหรับมื้ออาหารที่ไปนั่งทานที่ร้าน หรือซื้อกลับบ้าน',
          'Examples: กินข้าวแกง, ก๋วยเตี๋ยว, อาหารตามสั่ง',
        ),
      ],
    ),

    // ── Expense — Transportation
    ..._parentWithChildren(
      parentId: 'transportation',
      parentName: 'Transportation',
      parentIconId: 'directions_car',
      color: BrandPalette.blue,
      next: next,
      children: const [
        _Sub(
          'fuel',
          'Fuel',
          'local_gas_station',
          'ค่าน้ำมันเชื้อเพลิงที่เติมเมื่อมีการเดินทาง',
          'Examples: เติมน้ำมันแก๊สโซฮอล์ 95, ดีเซล B7',
        ),
        _Sub(
          'tolls_parking',
          'Tolls / Parking',
          'local_parking',
          'ค่าใช้จ่ายที่เกิดขึ้นระหว่างการเดินทางเพื่อความสะดวก/รวดเร็ว',
          'Examples: ค่าทางด่วน, ค่าที่จอดรถตามห้าง',
        ),
        _Sub(
          'public_transit',
          'Public Transit',
          'directions_bus',
          'ค่าเดินทางด้วยระบบขนส่งสาธารณะทุกประเภท',
          'Examples: BTS, MRT, รถเมล์, เรือด่วน, วินมอเตอร์ไซค์',
        ),
        _Sub(
          'taxi_rideshare',
          'Taxi / Rideshare',
          'local_taxi',
          'ค่าเดินทางด้วยบริการรถรับจ้างส่วนบุคคลผ่านแอปฯ หรือโบกเรียก',
          'Examples: Grab Car, Bolt, แท็กซี่มิเตอร์',
        ),
      ],
    ),

    // ── Expense — Vehicle
    ..._parentWithChildren(
      parentId: 'vehicle',
      parentName: 'Vehicle',
      parentIconId: 'car_repair',
      color: BrandPalette.indigo,
      next: next,
      children: const [
        _Sub(
          'insurance_tax',
          'Insurance / Tax',
          'policy',
          'ค่าใช้จ่ายรายปีที่จำเป็นเพื่อให้รถใช้งานได้ตามกฎหมาย',
          'Examples: ประกันภัยชั้น 1, พ.ร.บ., ภาษีรถยนต์ประจำปี',
        ),
        _Sub(
          'maintenance',
          'Maintenance',
          'car_repair',
          'ค่าใช้จ่ายในการดูแลรักษารถทั้งเชิงป้องกัน, แก้ไข, และความสะอาด',
          'Examples: เข้าศูนย์เช็คระยะ, เปลี่ยนยาง, ซ่อมแอร์, ล้างรถ',
        ),
      ],
    ),

    // ── Expense — Shopping
    ..._parentWithChildren(
      parentId: 'shopping',
      parentName: 'Shopping',
      parentIconId: 'shopping_bag',
      color: BrandPalette.pink,
      next: next,
      children: const [
        _Sub('apparel', 'Apparel', 'checkroom',
            'ของใช้ส่วนตัวเพื่อการแต่งกาย เพิ่มบุคลิกภาพ',
            'Examples: เสื้อผ้า, กางเกง, รองเท้า, นาฬิกา, กระเป๋า'),
        _Sub('gadgets_it', 'Gadgets / IT', 'headphones',
            'อุปกรณ์อิเล็กทรอนิกส์พกพา, อุปกรณ์เสริมคอม/มือถือ',
            'Examples: หูฟัง, Power Bank, เมาส์, คีย์บอร์ด, สายชาร์จ'),
        _Sub('home_electronics', 'Home & Electronics', 'tv',
            'ของใช้และเครื่องใช้ไฟฟ้าชิ้นใหญ่ในบ้าน (คงทน)',
            'Examples: ทีวี, ตู้เย็น, ของแต่งบ้าน, เครื่องครัว'),
        _Sub('personal_care', 'Personal Care', 'face_retouching',
            'ของใช้ส่วนตัวที่ใช้แล้วหมดไป (สิ้นเปลือง)',
            'Examples: สบู่, ยาสีฟัน, แชมพู, โฟมล้างหน้า, เครื่องสำอาง'),
        _Sub('household_supplies', 'Household Supplies', 'cleaning_services',
            'ของใช้ในบ้านที่ใช้แล้วหมดไป (สิ้นเปลือง)',
            'Examples: น้ำยาล้างจาน, ผงซักฟอก, ทิชชู่, ถ่านไฟฉาย'),
        _Sub('hobby_art', 'Hobby / Art', 'palette',
            'ของที่ใช้สำหรับทำงานอดิเรกหรืองานศิลปะโดยเฉพาะ',
            'Examples: สีน้ำ, สมุดสเก็ตช์, ซื้อ Brush/Asset ในแอปวาดรูป'),
      ],
    ),

    // ── Expense — Bills
    ..._parentWithChildren(
      parentId: 'bills',
      parentName: 'Bills',
      parentIconId: 'receipt_long',
      color: BrandPalette.red,
      next: next,
      children: const [
        _Sub('housing', 'Housing', 'home',
            'ค่าใช้จ่ายคงที่และจำเป็นเพื่อให้มีที่อยู่อาศัย',
            'Examples: ค่าเช่าห้อง/คอนโด, ค่าน้ำ, ค่าไฟ, ค่าส่วนกลาง'),
        _Sub('communication', 'Communication', 'wifi',
            'ค่าใช้จ่ายเพื่อให้สามารถติดต่อสื่อสารและเข้าถึงอินเทอร์เน็ตได้',
            'Examples: ค่าเน็ตบ้าน, ค่าโทรศัพท์มือถือรายเดือน'),
      ],
    ),

    // ── Expense — Services
    ..._parentWithChildren(
      parentId: 'services',
      parentName: 'Services',
      parentIconId: 'handshake',
      color: BrandPalette.cyan,
      next: next,
      children: const [
        _Sub('subscriptions', 'Subscriptions', 'subscriptions',
            'ค่าบริการรายเดือน/ปี เพื่อเข้าถึงเนื้อหาหรือแอปพลิเคชันต่างๆ',
            'Examples: Netflix, YouTube Premium, Spotify, iCloud'),
        _Sub('personal_services', 'Personal', 'spa',
            'ค่าบริการที่ทำเพื่อดูแลตัวเองเป็นครั้งคราว',
            'Examples: ค่าตัดผม, ทำสปา, นวด, ซักรีด'),
        _Sub('fitness', 'Fitness', 'fitness_center',
            'ค่าบริการที่เกี่ยวกับการออกกำลังกายและสุขภาพ',
            'Examples: ค่าสมาชิกฟิตเนส, คลาสโยคะ'),
      ],
    ),

    // ── Expense — Health & Medical
    ..._parentWithChildren(
      parentId: 'health_medical',
      parentName: 'Health & Medical',
      parentIconId: 'local_hospital',
      color: BrandPalette.green,
      next: next,
      children: const [
        _Sub('doctor_meds', 'Doctor / Meds', 'medical_services',
            'ค่าใช้จ่ายเมื่อเจ็บป่วย หรือซื้อยาเพื่อรักษา/บำรุง',
            'Examples: ค่าหาหมอ, ค่ายาตามใบสั่งแพทย์, วิตามิน'),
        _Sub('vision_dental', 'Vision / Dental', 'visibility',
            'ค่าใช้จ่ายเกี่ยวกับสายตาและทันตกรรมโดยเฉพาะ',
            'Examples: ตัดแว่น, ซื้อคอนแทคเลนส์, ขูดหินปูน, อุดฟัน'),
      ],
    ),

    // ── Expense — Entertainment
    ..._parentWithChildren(
      parentId: 'entertainment',
      parentName: 'Entertainment',
      parentIconId: 'movie',
      color: BrandPalette.purple,
      next: next,
      children: const [
        _Sub('gaming', 'Gaming', 'sports_esports',
            'ค่าใช้จ่ายที่เกี่ยวกับการเล่นเกมทั้งหมด',
            'Examples: ซื้อเกม (Steam), เติมเงินในเกม, ซื้อเครื่องเกม'),
        _Sub('media_books', 'Media / Books', 'theaters',
            'ค่าใช้จ่ายเพื่อความบันเทิงผ่านสื่อต่างๆ',
            'Examples: ตั๋วหนัง, คอนเสิร์ต, งานอีเวนต์, ซื้อหนังสือ'),
        _Sub('hangouts', 'Hangouts', 'nightlife',
            'ค่าใช้จ่ายเพื่อเข้าสังคมหรือทำกิจกรรมนอกบ้าน',
            'Examples: ไปร้านเหล้า, คาเฟ่บอร์ดเกม, คาราโอเกะ'),
        _Sub('travel', 'Travel', 'flight',
            'ค่าใช้จ่ายที่เกิดขึ้น "เพราะ" การท่องเที่ยวโดยตรง',
            'Examples: ค่าตั๋วเครื่องบิน, ค่าโรงแรม, ค่าเช่ารถ'),
      ],
    ),

    // ── Expense — Investments
    ..._parentWithChildren(
      parentId: 'investments',
      parentName: 'Investments',
      parentIconId: 'trending_up',
      color: BrandPalette.green,
      next: next,
      children: const [
        _Sub('savings', 'Savings', 'savings',
            'การโอนเงินไปเก็บในบัญชีเงินออมโดยเฉพาะ',
            'Examples: ฝากเงินเข้าบัญชีเงินฝากประจำ, ออมทอง'),
        _Sub('financial_assets', 'Financial Assets', 'trending_up',
            'เงินที่ใช้ซื้อสินทรัพย์ทางการเงินทุกประเภทเพื่อหวังผลตอบแทน',
            'Examples: ซื้อกองทุนรวม, หุ้น, หุ้นกู้, Cryptocurrency'),
        _Sub('speculative', 'Speculative', 'casino',
            'การลงทุนในรูปแบบอื่นๆ ที่มีความเสี่ยงเฉพาะตัวหรือไม่เป็นทางการ',
            'Examples: ให้เพื่อนยืมเงิน (กินดอกเบี้ย), เล่นแชร์'),
      ],
    ),

    // ── Expense — Debt Repayments
    ..._parentWithChildren(
      parentId: 'debt_repayments',
      parentName: 'Debt Repayments',
      parentIconId: 'credit_card',
      color: BrandPalette.red,
      next: next,
      children: const [
        _Sub('credit_card', 'Credit Card', 'credit_card',
            'การจ่ายเพื่อชำระยอดบัตรเครดิต "ของตัวเราเอง"',
            'Examples: จ่ายบัตรเครดิต KTC, จ่ายบัตร Citi'),
        _Sub('bnpl', 'BNPL', 'schedule',
            'การชำระยอดบริการ "ซื้อก่อนจ่ายทีหลัง"',
            'Examples: จ่าย SPayLater, จ่าย LazPay, จ่าย Atome'),
        _Sub('personal_loan', 'Personal Loan', 'handshake',
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
      parentIconId: 'more_horiz',
      color: BrandPalette.brown,
      next: next,
      children: const [
        _Sub('miscellaneous', 'Miscellaneous', 'more_horiz',
            'รายจ่ายเบ็ดเตล็ดทั่วไปที่จำเป็น แต่ไม่เข้าพวกหมวดหมู่อื่น',
            'Examples: ค่าธรรมเนียมธนาคาร, ค่าซองจดหมาย, ค่าถ่ายเอกสาร'),
        _Sub(
          'lending_pay_for_others',
          'Lending / Pay for Others',
          'volunteer_activism',
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
      iconCode: _bg('payments', BrandPalette.green),
      description: 'เงินเดือนจากงานประจำ หรือรายรับหลัก',
      sortOrder: next(),
    ),
    Category(
      id: 'side_hustle_freelance',
      name: 'Side Hustle / Freelance',
      type: CategoryType.income,
      iconCode: _bg('work', BrandPalette.cyan),
      description: 'รายได้จากงานเสริม, งานฟรีแลนซ์, หรือโปรเจกต์พิเศษ',
      sortOrder: next(),
    ),
    Category(
      id: 'online_sales',
      name: 'Online Sales',
      type: CategoryType.income,
      iconCode: _bg('storefront', BrandPalette.orange),
      description: 'รายได้จากการขายของออนไลน์ทุกประเภท',
      sortOrder: next(),
    ),
    Category(
      id: 'reimbursements_payback',
      name: 'Reimbursements / Payback',
      type: CategoryType.income,
      iconCode: _bg('swap_horiz', BrandPalette.brown),
      description: 'เงินที่คนอื่นคืนให้ ซึ่งไม่ใช่รายได้ที่แท้จริงของเรา',
      includeInReport: false,
      sortOrder: next(),
    ),
    Category(
      id: 'other_income',
      name: 'Other Income',
      type: CategoryType.income,
      iconCode: _bg('redeem', BrandPalette.yellow),
      description: 'รายรับอื่นๆ ที่ไม่เข้าพวก เช่น เงินปันผล, ดอกเบี้ย',
      sortOrder: next(),
    ),
    // (income-side "Adjustment" intentionally omitted — same reason as
    // the expense-side: the system category sys_adjustment_in covers it.)
  ];
}

IconCode _bg(String iconId, BrandSwatch swatch) => IconCode(
      icon: iconId,
      iconColors: const ['#FFFFFF'],
      background: 'solid',
      bgColors: [swatch.hex],
    );

class _Sub {
  const _Sub(
    this.id,
    this.name,
    this.iconId,
    this.description,
    this.example, {
    this.includeInReport = true,
  });
  final String id;
  final String name;
  final String iconId;
  final String description;
  final String example;
  final bool includeInReport;
}

List<Category> _parentWithChildren({
  required String parentId,
  required String parentName,
  required String parentIconId,
  required BrandSwatch color,
  required int Function() next,
  required List<_Sub> children,
}) {
  return [
    Category(
      id: parentId,
      name: parentName,
      type: CategoryType.expense,
      iconCode: _bg(parentIconId, color),
      sortOrder: next(),
    ),
    for (final child in children)
      Category(
        id: child.id,
        name: child.name,
        parentId: parentId,
        type: CategoryType.expense,
        iconCode: _bg(child.iconId, color),
        description: '${child.description} ${child.example}',
        includeInReport: child.includeInReport,
        sortOrder: next(),
      ),
  ];
}
