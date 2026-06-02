import '../../domain/entities/create_post_entity.dart';
import '../../domain/repositories/create_post_repository.dart';
import '../datasources/create_post_remote_data_source.dart';
import '../models/create_post_dto.dart';

class CreatePostRepositoryImpl implements CreatePostRepository {
  CreatePostRepositoryImpl(this._dataSource);

  final CreatePostRemoteDataSource _dataSource;

  @override
  Future<List<String>> uploadMediaFiles(List<LocalMediaFile> files) {
    return _dataSource.uploadMediaFiles(files);
  }

  @override
  Future<Map<String, dynamic>> createPost(CreatePostEntity entity) async {
    final dto = CreatePostDto.fromEntity(entity);
    return _dataSource.createPost(dto);
  }
}
