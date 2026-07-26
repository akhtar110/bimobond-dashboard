import 'package:equatable/equatable.dart';

import '../../domain/entities/ar_overlay_entities.dart';
import '../../../gifts/domain/enums/gifts_view_type.dart';

abstract class ArOverlaysState extends Equatable {
  const ArOverlaysState();

  @override
  List<Object?> get props => [];
}

class ArOverlaysInitial extends ArOverlaysState {
  const ArOverlaysInitial();
}

class ArOverlaysLoading extends ArOverlaysState {
  const ArOverlaysLoading();
}

class ArOverlaysLoaded extends ArOverlaysState {
  const ArOverlaysLoaded({
    required this.overlays,
    required this.meta,
    this.searchQuery = '',
    this.viewType = GiftsViewType.grid,
    this.isActioning = false,
    this.successMessage,
    this.errorMessage,
    this.selectedOverlay,
  });

  final List<ArOverlayEntity> overlays;
  final ArOverlayMetaEntity meta;
  final String searchQuery;
  final GiftsViewType viewType;
  final bool isActioning;
  final String? successMessage;
  final String? errorMessage;
  final ArOverlayEntity? selectedOverlay;

  /// Returns locally filtered list of overlays based on search query.
  List<ArOverlayEntity> get filteredOverlays {
    if (searchQuery.trim().isEmpty) return overlays;
    final q = searchQuery.trim().toLowerCase();
    return overlays.where((item) {
      final idMatch = item.id.toLowerCase().contains(q);
      final labelMatch = item.label.toLowerCase().contains(q);
      final emojiMatch = (item.emoji ?? '').toLowerCase().contains(q);
      return idMatch || labelMatch || emojiMatch;
    }).toList();
  }

  ArOverlaysLoaded copyWith({
    List<ArOverlayEntity>? overlays,
    ArOverlayMetaEntity? meta,
    String? searchQuery,
    GiftsViewType? viewType,
    bool? isActioning,
    String? successMessage,
    String? errorMessage,
    ArOverlayEntity? selectedOverlay,
    bool clearMessages = false,
    bool clearSelectedOverlay = false,
  }) {
    return ArOverlaysLoaded(
      overlays: overlays ?? this.overlays,
      meta: meta ?? this.meta,
      searchQuery: searchQuery ?? this.searchQuery,
      viewType: viewType ?? this.viewType,
      isActioning: isActioning ?? this.isActioning,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      selectedOverlay: clearSelectedOverlay ? null : (selectedOverlay ?? this.selectedOverlay),
    );
  }

  @override
  List<Object?> get props => [
        overlays,
        meta,
        searchQuery,
        viewType,
        isActioning,
        successMessage,
        errorMessage,
        selectedOverlay,
      ];
}

class ArOverlaysError extends ArOverlaysState {
  const ArOverlaysError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
