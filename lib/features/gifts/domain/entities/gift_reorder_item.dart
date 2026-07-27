class GiftReorderItem {
  const GiftReorderItem({
    required this.id,
    required this.sortOrder,
  });

  final String id;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sortOrder': sortOrder,
      };
}
