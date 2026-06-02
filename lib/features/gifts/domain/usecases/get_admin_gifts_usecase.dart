import '../entities/gift_entity.dart';
import '../repositories/gifts_repository.dart';

class GetAdminGifts {
  const GetAdminGifts(this.repository);
  final GiftsRepository repository;
  Future<List<GiftEntity>> call() => repository.getAdminGifts();
}
