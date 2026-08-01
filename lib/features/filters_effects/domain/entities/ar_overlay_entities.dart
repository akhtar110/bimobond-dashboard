import 'package:equatable/equatable.dart';

/// Single AR Overlay Entity representing a camera studio screen overlay.
class ArOverlayEntity extends Equatable {
  const ArOverlayEntity({
    required this.id,
    required this.label,
    this.sortOrder = 0,
    required this.lottieUrl,
    this.emoji,
    this.thumbnailUrl,
    this.previewColorHex,
    this.isActive = true,
  });

  final String id;
  final String label;
  final int sortOrder;
  final String lottieUrl;
  final String? emoji;
  final String? thumbnailUrl;
  final String? previewColorHex;
  final bool isActive;

  ArOverlayEntity copyWith({
    String? id,
    String? label,
    int? sortOrder,
    String? lottieUrl,
    String? emoji,
    String? thumbnailUrl,
    String? previewColorHex,
    bool? isActive,
  }) {
    return ArOverlayEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      lottieUrl: lottieUrl ?? this.lottieUrl,
      emoji: emoji ?? this.emoji,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewColorHex: previewColorHex ?? this.previewColorHex,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        sortOrder,
        lottieUrl,
        emoji,
        thumbnailUrl,
        previewColorHex,
        isActive,
      ];
}

/// Metadata object for paginated AR Overlays admin responses.
class ArOverlayMetaEntity extends Equatable {
  const ArOverlayMetaEntity({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

/// Category entity for the public AR Overlays catalog response.
class ArOverlayCategoryEntity extends Equatable {
  const ArOverlayCategoryEntity({
    required this.id,
    required this.label,
    this.sortOrder = 0,
    this.overlays = const [],
  });

  final String id;
  final String label;
  final int sortOrder;
  final List<ArOverlayEntity> overlays;

  @override
  List<Object?> get props => [id, label, sortOrder, overlays];
}

/// Public catalog response wrapper payload (`GET /camera-studio/ar-overlays`).
class ArOverlayCatalogResponseEntity extends Equatable {
  const ArOverlayCatalogResponseEntity({
    required this.version,
    this.overlayCategories = const [],
  });

  final String version;
  final List<ArOverlayCategoryEntity> overlayCategories;

  @override
  List<Object?> get props => [version, overlayCategories];
}

/// Paginated admin list response wrapper payload (`GET /camera-studio/ar-overlays/admin`).
class ArOverlayListResponseEntity extends Equatable {
  const ArOverlayListResponseEntity({
    required this.version,
    this.data = const [],
    required this.meta,
  });

  final String version;
  final List<ArOverlayEntity> data;
  final ArOverlayMetaEntity meta;

  @override
  List<Object?> get props => [version, data, meta];
}

/// Status filter for AR Overlays admin list (All / Active / Inactive).
enum ArOverlayStatusFilter { all, active, inactive }

