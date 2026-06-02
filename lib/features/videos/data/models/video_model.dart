import '../../domain/entities/video_entity.dart';

class VideoModel extends VideoEntity {
  const VideoModel({
    required super.id,
    required super.thumbnailUrl,
    required super.ownerName,
    required super.reportCount,
    required super.isReported,
    required super.isTrending,
    required super.isNew,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      ownerName: json['ownerName'] ?? (json['user'] != null ? json['user']['username'] : 'Unknown'),
      reportCount: json['reportCount'] ?? 0,
      isReported: json['isReported'] ?? false,
      isTrending: json['isTrending'] ?? false,
      isNew: json['isNew'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thumbnailUrl': thumbnailUrl,
      'ownerName': ownerName,
      'reportCount': reportCount,
      'isReported': isReported,
      'isTrending': isTrending,
      'isNew': isNew,
    };
  }
}
