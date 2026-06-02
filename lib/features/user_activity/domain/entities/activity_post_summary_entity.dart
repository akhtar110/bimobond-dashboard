import 'activity_user_entity.dart';

class ActivityPostSummaryEntity {
  const ActivityPostSummaryEntity({
    required this.id,
    this.description,
    this.user,
  });

  final String id;
  final String? description;
  final ActivityUserEntity? user;
}
