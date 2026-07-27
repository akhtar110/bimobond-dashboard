import '../entities/gift_entity.dart';
import '../entities/gift_reorder_item.dart';
import '../repositories/gifts_repository.dart';

class ReorderGiftsUseCase {
  const ReorderGiftsUseCase(this._repository);
  final GiftsRepository _repository;

  Future<List<GiftEntity>> call(List<GiftReorderItem> items) =>
      _repository.reorderGifts(items);
}
