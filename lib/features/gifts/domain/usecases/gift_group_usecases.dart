import '../entities/gift_group_entities.dart';
import '../repositories/gifts_repository.dart';

class GetGiftGroupsUseCase {
  const GetGiftGroupsUseCase(this._repository);
  final GiftsRepository _repository;

  Future<List<GiftGroupEntity>> call() => _repository.getGiftGroups();
}

class CreateGiftGroupUseCase {
  const CreateGiftGroupUseCase(this._repository);
  final GiftsRepository _repository;

  Future<GiftGroupEntity> call(CreateGiftGroupData data) =>
      _repository.createGiftGroup(data);
}

class UpdateGiftGroupUseCase {
  const UpdateGiftGroupUseCase(this._repository);
  final GiftsRepository _repository;

  Future<GiftGroupEntity> call(String groupId, UpdateGiftGroupData data) =>
      _repository.updateGiftGroup(groupId, data);
}

class DeleteGiftGroupUseCase {
  const DeleteGiftGroupUseCase(this._repository);
  final GiftsRepository _repository;

  Future<void> call(String groupId) => _repository.deleteGiftGroup(groupId);
}

class ReorderGiftGroupsUseCase {
  const ReorderGiftGroupsUseCase(this._repository);
  final GiftsRepository _repository;

  Future<List<GiftGroupEntity>> call(List<GiftGroupReorderItem> items) =>
      _repository.reorderGiftGroups(items);
}

class ReplaceGroupGiftsUseCase {
  const ReplaceGroupGiftsUseCase(this._repository);
  final GiftsRepository _repository;

  Future<GiftGroupEntity> call(
    String groupId,
    List<GiftGroupMembershipItem> gifts,
  ) =>
      _repository.replaceGroupGifts(groupId, gifts);
}
