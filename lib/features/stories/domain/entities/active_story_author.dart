import 'package:equatable/equatable.dart';

class ActiveStoryAuthor extends Equatable {
  const ActiveStoryAuthor({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, name, username, avatarUrl];
}
