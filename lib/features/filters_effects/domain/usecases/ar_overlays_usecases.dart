import '../../data/models/ar_overlay_models.dart';
import '../entities/ar_overlay_entities.dart';
import '../repositories/ar_overlays_repository.dart';

class GetAdminOverlaysUseCase {
  const GetAdminOverlaysUseCase(this._repository);
  final ArOverlaysRepository _repository;

  Future<ArOverlayListResponseEntity> call({
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getAdminOverlays(page: page, limit: limit);
  }
}

class GetAdminOverlayByIdUseCase {
  const GetAdminOverlayByIdUseCase(this._repository);
  final ArOverlaysRepository _repository;

  Future<ArOverlayEntity> call(String id) {
    return _repository.getAdminOverlayById(id);
  }
}

class CreateAdminOverlayUseCase {
  const CreateAdminOverlayUseCase(this._repository);
  final ArOverlaysRepository _repository;

  Future<ArOverlayEntity> call(CreateArOverlayData data) {
    return _repository.createAdminOverlay(data);
  }
}

class UpdateAdminOverlayUseCase {
  const UpdateAdminOverlayUseCase(this._repository);
  final ArOverlaysRepository _repository;

  Future<ArOverlayEntity> call(String id, UpdateArOverlayData data) {
    return _repository.updateAdminOverlay(id, data);
  }
}

class DeleteAdminOverlayUseCase {
  const DeleteAdminOverlayUseCase(this._repository);
  final ArOverlaysRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteAdminOverlay(id);
  }
}

class GetPublicArOverlaysCatalogUseCase {
  const GetPublicArOverlaysCatalogUseCase(this._repository);
  final ArOverlaysRepository _repository;

  Future<ArOverlayCatalogResponseEntity> call() {
    return _repository.getPublicCatalog();
  }
}
