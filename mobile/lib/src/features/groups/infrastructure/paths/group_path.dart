/// Danh sách API paths cho Feature Groups theo Mục 5 contract.md.
abstract class GroupPath {
  static const String groups = '/groups';
  static String groupDetail(String id) => '/groups/$id';
  static String addMember(String id) => '/groups/$id/members';
  static String settleUp(String id) => '/groups/$id/settle';
}
