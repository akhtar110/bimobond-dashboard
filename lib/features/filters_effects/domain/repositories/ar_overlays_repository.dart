import '../../data/models/ar_overlay_models.dart';
import '../entities/ar_overlay_entities.dart';

abstract class ArOverlaysRepository {
  Future<ArOverlayCatalogResponseEntity> getPublicCatalog();
  Future<ArOverlayListResponseEntity> getAdminOverlays({
    int page = 1,
    int limit = 20,
  });
  Future<ArOverlayEntity> getAdminOverlayById(String id);
  Future<ArOverlayEntity> createAdminOverlay(CreateArOverlayData data);
  Future<ArOverlayEntity> updateAdminOverlay(
    String id,
    UpdateArOverlayData data,
  );
  Future<void> deleteAdminOverlay(String id);
}
