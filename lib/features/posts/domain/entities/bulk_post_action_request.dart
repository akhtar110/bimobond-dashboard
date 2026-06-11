import '../enums/bulk_post_action_type.dart';

class BulkPostActionRequest {
  const BulkPostActionRequest({
    required this.postIds,
    required this.action,
  });

  final List<String> postIds;
  final BulkPostActionType action;
}
