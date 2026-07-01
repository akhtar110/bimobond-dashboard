import 'package:equatable/equatable.dart';

class PostTypeCountEntity extends Equatable {
  const PostTypeCountEntity({required this.type, required this.count});

  final String type;
  final int count;

  static const video = 'VIDEO';
  static const image = 'IMAGE';
  static const carousel = 'CAROUSEL';

  static const knownTypes = [video, image, carousel];

  @override
  List<Object?> get props => [type, count];
}
