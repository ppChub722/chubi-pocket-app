// Events API payloads shaped like the BE's OpenAPI spec (tag "Events").

Map<String, dynamic> memberRef(String id, String name, {bool me = false}) => {
  'id': id,
  'user_id': me ? 'u-me' : null,
  'name': name,
  'icon_code': null,
  'is_me': me,
};

Map<String, dynamic> eventJson({
  String id = 'e1',
  String name = 'Chiang Mai trip',
  String status = 'active',
  double? planned = 10000,
  double myNet = 250,
  double totalIncome = 0,
  List<Map<String, dynamic>> tags = const [],
}) => {
  'id': id,
  'owner_user_id': 'u-me',
  'name': name,
  'icon_code': null,
  'description': 'Long weekend',
  'note': null,
  'status': status,
  'start_date': '2026-10-01',
  'end_date': '2026-10-04',
  'planned_amount': planned,
  'members_count': 2,
  'total_expense': 1750,
  'total_income': totalIncome,
  'my_net': myNet,
  // 0.4.0: the BE splits my net by sign and says what is left of the plan.
  'my_paid': 1000,
  'my_share': 750,
  'my_receivable': myNet > 0 ? myNet : 0,
  'my_payable': myNet < 0 ? -myNet : 0,
  'remaining': planned == null ? null : planned - 1750 + totalIncome,
  'tags': tags,
  'my_member_id': 'm-me',
  'my_role': 'owner',
  'is_owner': true,
  'is_locked': false,
  'can_add_bill': true,
  'can_edit': true,
  'can_manage_members': true,
  'created_at': '2026-10-01T08:00:00Z',
  'updated_at': '2026-10-05T08:00:00Z',
};

Map<String, dynamic> eventTagJson(
  String id,
  String name, {
  bool mine = false,
  int count = 1,
}) => {'id': id, 'name': name, 'icon_code': null, 'mine': mine, 'count': count};

Map<String, dynamic> boardRowJson({
  String id = 'b1',
  String description = 'Gas',
  double amount = 1000,
  String date = '2026-10-02',
  List<String> marks = const [],
  bool linked = false,
  Map<String, dynamic>? sourceTx,
  List<Map<String, dynamic>> tags = const [],
  List<Map<String, dynamic>> children = const [],
  Map<String, dynamic>? payer,
}) => {
  'id': id,
  'project_id': 'e1',
  'type': 'expense',
  'amount': amount,
  'date': date,
  'description': description,
  'note': null,
  'transaction_member': payer ?? memberRef('m-me', 'Pond', me: true),
  'record_user_id': 'u-me',
  'tags': tags,
  'marks': marks,
  'my_mark': marks.contains('m-me'),
  'my_share': 500,
  'locked': false,
  'linked': linked,
  'source_tx': sourceTx,
  'children': children,
  'created_at': '2026-10-02T08:00:00Z',
  'updated_at': '2026-10-02T08:00:00Z',
};

Map<String, dynamic> splitJson(String id, double amount) => {
  'id': id,
  'transaction_member': memberRef('m-lee', 'Lee'),
  'amount': amount,
  'marks': <String>[],
  'my_mark': false,
};

Map<String, dynamic> summaryJson({double totalExpense = 1750}) => {
  'total_expense': totalExpense,
  'total_income': 0,
  'transaction_count': 2,
  'member_count': 2,
  'planned_amount': 10000,
  'spent_net': totalExpense,
  'remaining': 10000 - totalExpense,
  'my_position': {
    'member': memberRef('m-me', 'Pond', me: true),
    'paid': 1000,
    'share': 750,
    'net': 250,
    'receivable': 250,
    'payable': 0,
  },
  'members': [
    {
      'member': memberRef('m-me', 'Pond', me: true),
      'paid': 1000,
      'share': 750,
      'net': 250,
      'receivable': 250,
      'payable': 0,
    },
    {
      'member': memberRef('m-lee', 'Lee'),
      'paid': 750,
      'share': 1000,
      'net': -250,
      'receivable': 0,
      'payable': 250,
    },
  ],
  'by_tag': [
    {'tag': eventTagJson('t1', 'Food'), 'total': 750, 'share': 375, 'count': 1},
    {'tag': null, 'total': 1000, 'share': 500, 'count': 1},
  ],
};

List<Map<String, dynamic>> membersJson() => [
  {
    ...memberRef('m-me', 'Pond', me: true),
    'linked': true,
    'role': 'owner',
    'status': 'active',
    'invited_at': null,
    'joined_at': '2026-10-01T08:00:00Z',
    'left_at': null,
  },
  {
    ...memberRef('m-lee', 'Lee'),
    'linked': false,
    'role': 'contributor',
    'status': 'active',
    'invited_at': null,
    'joined_at': '2026-10-01T08:00:00Z',
    'left_at': null,
  },
];

Map<String, dynamic> detailJson({
  List<Map<String, dynamic>>? rows,
  int totalPages = 1,
}) => {
  'event': eventJson(
    tags: [
      {'id': 'pt1', 'name': 'Trips', 'icon_code': null},
    ],
  ),
  'summary': summaryJson(),
  'members': membersJson(),
  'tags': [eventTagJson('t1', 'Food')],
  'board': {
    'data':
        rows ??
        [
          boardRowJson(
            children: [splitJson('s1', 500)],
            linked: true,
            sourceTx: {'id': 'tx9', 'description': 'Gas', 'account': null},
          ),
          boardRowJson(
            id: 'b2',
            description: 'Dinner',
            amount: 750,
            date: '2026-10-03',
            payer: memberRef('m-lee', 'Lee'),
            tags: [eventTagJson('t1', 'Food')],
          ),
        ],
    'pagination': {
      'page': 1,
      'per_page': 50,
      'total': 2,
      'total_pages': totalPages,
    },
  },
};

/// `GET /projects` `summary` (BE EventList.summary).
Map<String, dynamic> listSummaryJson() => {
  'my_share_total': 14289,
  'paid_total': 22539,
  'receivable_total': 8250,
  'payable_total': 100,
  'counts': {
    'all': 7,
    'active': 2,
    'unsettled': 3,
    'receivable': 2,
    'payable': 1,
    'ended': 5,
  },
};

Map<String, dynamic> patchJson({
  Map<String, dynamic>? row,
  String? removedRowId,
  double totalExpense = 1750,
}) => {
  'event': eventJson(),
  'summary': summaryJson(totalExpense: totalExpense),
  'members': membersJson(),
  'tags': [eventTagJson('t1', 'Food')],
  'row': row,
  'removed_row_id': removedRowId,
  'account_balances': <Map<String, dynamic>>[],
};
