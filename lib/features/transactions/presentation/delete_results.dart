import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../personal_debts/domain/debt_ledger.dart';
import '../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../domain/transaction.dart';
import 'cubit/transactions_cubit.dart';

/// A tx delete moves the wallets, and a repayment's delete moves the
/// person's balance back (0.4.0-3).
void applyTxDeleteResult(
  DeleteTransactionResult result, {
  required AccountsCubit accounts,
  DebtDirectoryCubit? debts,
}) {
  accounts.patchBalances(result.accountBalances);
  final balance = result.personBalance;
  if (balance != null) debts?.applyBalance(balance);
}

/// A debt entry delete moves the wallets and drops the entry's tx row.
void applyDebtEntryDeleteResult(
  DebtEntryDeleteResult result, {
  required AccountsCubit accounts,
  required TransactionsCubit txs,
}) {
  accounts.patchBalances(result.accountBalances);
  final txId = result.transactionId;
  if (txId != null) txs.dropRow(txId);
}
