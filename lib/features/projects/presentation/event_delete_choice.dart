enum DeleteChoice { notYet, keepTxs, withTxs }

bool? deleteLinkedTxsOf(DeleteChoice? choice) =>
    choice == null || choice == DeleteChoice.notYet
    ? null
    : choice == DeleteChoice.withTxs;
