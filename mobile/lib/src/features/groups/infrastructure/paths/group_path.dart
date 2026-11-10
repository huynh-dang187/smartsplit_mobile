/// Danh sách API paths cho Feature Groups theo Mục 5 contract.md.
abstract class GroupPath {
  static const String groups = '/groups';
  static String groupDetail(String groupId) => '/groups/$groupId';
  static String addMember(String groupId) => '/groups/$groupId/members';
  static String settleUp(String groupId) => '/groups/$groupId/settle';
}
