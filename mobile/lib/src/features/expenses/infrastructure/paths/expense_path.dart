/// Danh sách API paths cho Feature Expenses theo Mục 5 contract.md.
abstract class ExpensePath {
  static const String scanReceipt = '/receipts/scan';
  static String createExpense(String groupId) => '/groups/$groupId/expenses';
}
