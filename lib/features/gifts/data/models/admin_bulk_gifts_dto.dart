import 'admin_bulk_gift_action.dart';

/// Mirrors backend `AdminBulkGiftsDto`.
class AdminBulkGiftsDto {
  const AdminBulkGiftsDto({
    required this.giftIds,
    required this.action,
  });

  final List<String> giftIds;
  final AdminBulkGiftAction action;

  Map<String, dynamic> toJson() => {
        'giftIds': giftIds,
        'action': action.apiValue,
      };
}
