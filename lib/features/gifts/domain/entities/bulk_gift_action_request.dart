import '../enums/bulk_gift_action_type.dart';

class BulkGiftActionRequest {
  const BulkGiftActionRequest({
    required this.giftIds,
    required this.action,
  });

  final List<String> giftIds;
  final BulkGiftActionType action;
}
