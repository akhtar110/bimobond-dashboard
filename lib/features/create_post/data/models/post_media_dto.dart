class PostMediaDto {
  const PostMediaDto({
    required this.url,
    required this.mediaType,
    this.order = 0,
  });

  final String url;
  final String mediaType;
  final int order;

  Map<String, dynamic> toJson() => {
        'url': url,
        'mediaType': mediaType,
        'order': order,
      };
}
