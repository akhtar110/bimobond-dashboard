import 'package:equatable/equatable.dart';

class PeriodEngagementEntity extends Equatable {
  const PeriodEngagementEntity({
    required this.views,
    required this.likes,
    required this.comments,
    required this.reposts,
  });

  final int views;
  final int likes;
  final int comments;
  final int reposts;

  int get total => views + likes + comments + reposts;

  @override
  List<Object?> get props => [views, likes, comments, reposts];
}
