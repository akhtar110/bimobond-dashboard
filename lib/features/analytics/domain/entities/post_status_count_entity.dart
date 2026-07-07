import 'package:equatable/equatable.dart';

class PostStatusCountEntity extends Equatable {
  const PostStatusCountEntity({required this.status, required this.count});

  final String status;
  final int count;

  static const published = 'PUBLISHED';
  static const hidden = 'HIDDEN';
  static const banned = 'BANNED';
  static const expired = 'EXPIRED';

  static const knownStatuses = [published, hidden, banned, expired];

  @override
  List<Object?> get props => [status, count];
}
