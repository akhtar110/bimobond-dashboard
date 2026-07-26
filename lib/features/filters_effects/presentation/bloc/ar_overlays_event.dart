import 'package:equatable/equatable.dart';

import '../../data/models/ar_overlay_models.dart';
import '../../../gifts/domain/enums/gifts_view_type.dart';

abstract class ArOverlaysEvent extends Equatable {
  const ArOverlaysEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch paginated list of overlays from admin API (`GET /camera-studio/ar-overlays/admin`).
class LoadArOverlaysEvent extends ArOverlaysEvent {
  const LoadArOverlaysEvent({
    this.page = 1,
    this.limit = 20,
  });

  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

/// Force refresh the current page of overlays.
class RefreshArOverlaysEvent extends ArOverlaysEvent {
  const RefreshArOverlaysEvent();
}

/// Fetch a single overlay by ID.
class LoadArOverlayByIdEvent extends ArOverlaysEvent {
  const LoadArOverlayByIdEvent(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// Create a new AR Overlay.
class CreateArOverlayEvent extends ArOverlaysEvent {
  const CreateArOverlayEvent(this.data);
  final CreateArOverlayData data;

  @override
  List<Object?> get props => [data];
}

/// Update an existing AR Overlay.
class UpdateArOverlayEvent extends ArOverlaysEvent {
  const UpdateArOverlayEvent(this.id, this.data);
  final String id;
  final UpdateArOverlayData data;

  @override
  List<Object?> get props => [id, data];
}

/// Delete an AR Overlay by ID.
class DeleteArOverlayEvent extends ArOverlaysEvent {
  const DeleteArOverlayEvent(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// Search overlays locally by query string.
class SearchArOverlaysEvent extends ArOverlaysEvent {
  const SearchArOverlaysEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Change current page in pagination.
class ChangeArOverlaysPageEvent extends ArOverlaysEvent {
  const ChangeArOverlaysPageEvent(this.page);
  final int page;

  @override
  List<Object?> get props => [page];
}

/// Toggle Grid / List view mode.
class ChangeArOverlaysViewTypeEvent extends ArOverlaysEvent {
  const ChangeArOverlaysViewTypeEvent(this.viewType);
  final GiftsViewType viewType;

  @override
  List<Object?> get props => [viewType];
}

/// Clear snackbar messages.
class ClearArOverlaysMessageEvent extends ArOverlaysEvent {
  const ClearArOverlaysMessageEvent();
}
