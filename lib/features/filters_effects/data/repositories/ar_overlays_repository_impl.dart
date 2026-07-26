import '../../domain/entities/ar_overlay_entities.dart';
import '../../domain/repositories/ar_overlays_repository.dart';
import '../datasources/ar_overlays_remote_datasource.dart';
import '../models/ar_overlay_models.dart';

class ArOverlaysRepositoryImpl implements ArOverlaysRepository {
  const ArOverlaysRepositoryImpl({
    required ArOverlaysRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ArOverlaysRemoteDataSource _remoteDataSource;

  @override
  Future<ArOverlayCatalogResponseEntity> getPublicCatalog() {
    return _remoteDataSource.getPublicCatalog();
  }

  @override
  Future<ArOverlayListResponseEntity> getAdminOverlays({
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.getAdminOverlays(page: page, limit: limit);
  }

  @override
  Future<ArOverlayEntity> getAdminOverlayById(String id) {
    return _remoteDataSource.getAdminOverlayById(id);
  }

  @override
  Future<ArOverlayEntity> createAdminOverlay(CreateArOverlayData data) {
    return _remoteDataSource.createAdminOverlay(data);
  }

  @override
  Future<ArOverlayEntity> updateAdminOverlay(
    String id,
    UpdateArOverlayData data,
  ) {
    return _remoteDataSource.updateAdminOverlay(id, data);
  }

  @override
  Future<void> deleteAdminOverlay(String id) {
    return _remoteDataSource.deleteAdminOverlay(id);
  }
}
