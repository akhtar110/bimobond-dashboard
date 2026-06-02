class VideoEntity {
  const VideoEntity({
    required this.id,
    required this.thumbnailUrl,
    required this.ownerName,
    required this.reportCount,
    required this.isReported,
    required this.isTrending,
    required this.isNew,
  });

  final String id;
  final String thumbnailUrl;
  final String ownerName;
  final int reportCount;
  final bool isReported;
  final bool isTrending;
  final bool isNew;
}

enum VideoFilter { all, reported, trending, newest }
