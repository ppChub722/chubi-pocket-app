import 'package:flutter/material.dart';

import '../hub_kit.dart';
import 'sheet_demos/description_picker_sheet_demo.dart';
import 'sheet_demos/quick_create_demo.dart';
import 'sheet_demos/settle_sheet_demo.dart';
import 'sheet_demos/tx_filter_sheet_demo.dart';

/// `/dev/domain/sheets-transactions` — the transaction sheets, each split in
/// two: a PRESENTATIONAL organism in `lib/ui` (data + words + callbacks in,
/// result out; no cubits / repos) and a thin wrapper in `features/` that
/// reads the cubits, maps models + strings and handles the result. Every
/// button opens the organism live with sample data.
Widget buildSheetsTransactionsPage(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    HubDemo(
      title: 'QuickCreateSheetShell — the + sheet\'s frame',
      note:
          'Drag handle + drag-to-dismiss, the title row that swaps to the '
          'amount | category summary once the hero scrolls away, the discard '
          'guard, the scrolling body slot, the pinned save / draft / submit '
          'bar and the saving overlay. The wrapper puts the DraftForm in the '
          'body and keeps every save path.',
      child: buildQuickCreateDemo(context),
    ),
    HubDemo(
      title: 'TxFilterSheet — the list filter (side sheet)',
      note:
          'Wallet / category / tag / type chips. Takes plain option lists + '
          'the current selection and returns the new selection; the wrapper '
          'loads the form options, maps them and passes the "more" pickers.',
      child: buildTxFilterSheetDemo(context),
    ),
    HubDemo(
      title: 'DescriptionPickerSheet — suggestions + free text',
      note:
          'Generic: past descriptions as suggestions and a typed one; all '
          'strings are parameters.',
      child: buildDescriptionPickerSheetDemo(context),
    ),
    HubDemo(
      title: 'SettleSheet — receive / pay back',
      note:
          'The hero amount with quick fills, the wallet and a note. The '
          'wrapper runs the settle call inside the sheet through onConfirm, '
          'so a failure keeps it open.',
      child: buildSettleSheetDemo(context),
    ),
  ],
);
