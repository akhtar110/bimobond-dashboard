import 'admin_bulk_post_action.dart';

/// Mirrors backend `AdminBulkPostsDto`.
class AdminBulkPostsDto {
  const AdminBulkPostsDto({
    required this.postIds,
    required this.action,
    this.status,
  });

  final List<String> postIds;
  final AdminBulkPostAction action;
  final String? status;

  Map<String, dynamic> toJson() => {
        'postIds': postIds,
        'action': action.apiValue,
        if (status != null) 'status': status,
      };
}
