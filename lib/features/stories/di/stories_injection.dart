import 'package:get_it/get_it.dart';

import '../data/datasources/stories_remote_data_source.dart';
import '../data/repositories/stories_repository_impl.dart';
import '../domain/repositories/stories_repository.dart';
import '../domain/usecases/delete_story.dart';
import '../domain/usecases/get_stories.dart';
import '../domain/usecases/update_story.dart';
import '../presentation/bloc/stories_bloc.dart';

void registerStoriesDependencies(GetIt sl) {
  sl.registerLazySingleton<StoriesRemoteDataSource>(
    () => StoriesRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<StoriesRepository>(
    () => StoriesRepositoryImpl(sl<StoriesRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetStoriesUseCase(sl<StoriesRepository>()));
  sl.registerLazySingleton(() => UpdateStoryUseCase(sl<StoriesRepository>()));
  sl.registerLazySingleton(() => DeleteStoryUseCase(sl<StoriesRepository>()));

  sl.registerFactory(
    () => StoriesBloc(
      getStoriesUseCase: sl<GetStoriesUseCase>(),
      updateStoryUseCase: sl<UpdateStoryUseCase>(),
      deleteStoryUseCase: sl<DeleteStoryUseCase>(),
    ),
  );
}
