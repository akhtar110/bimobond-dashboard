import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/video_entity.dart';
import '../../domain/usecases/delete_video.dart';
import '../../domain/usecases/get_videos.dart';

sealed class VideosEvent {}

class LoadVideosEvent extends VideosEvent {
  LoadVideosEvent({this.refresh = false});
  final bool refresh;
}

class FilterVideosEvent extends VideosEvent {
  FilterVideosEvent(this.filter);
  final VideoFilter filter;
}

class DeleteVideoEvent extends VideosEvent {
  DeleteVideoEvent(this.videoId);
  final String videoId;
}

sealed class VideosState {}

class VideosLoading extends VideosState {}

class VideosError extends VideosState {}

class VideosEmpty extends VideosState {}

class VideosLoaded extends VideosState {
  VideosLoaded({
    required this.videos,
    required this.filter,
    required this.isLoadingMore,
  });

  final List<VideoEntity> videos;
  final VideoFilter filter;
  final bool isLoadingMore;
}

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  VideosBloc({required this.getVideos, required this.deleteVideo})
    : super(VideosLoading()) {
    on<LoadVideosEvent>(_onLoad);
    on<FilterVideosEvent>(_onFilter);
    on<DeleteVideoEvent>(_onDelete);
  }

  final GetVideos getVideos;
  final DeleteVideo deleteVideo;

  static const _limit = 18;
  int _page = 1;
  bool _hasMore = true;
  bool _busy = false;
  VideoFilter _filter = VideoFilter.all;
  final List<VideoEntity> _videos = [];

  Future<void> _onLoad(LoadVideosEvent event, Emitter<VideosState> emit) async {
    if (_busy) return;
    if (event.refresh) {
      _page = 1;
      _hasMore = true;
      _videos.clear();
    }
    if (!_hasMore) return;
    _busy = true;
    if (_videos.isEmpty) {
      emit(VideosLoading());
    } else {
      emit(VideosLoaded(videos: List.of(_videos), filter: _filter, isLoadingMore: true));
    }
    try {
      final batch = await getVideos(page: _page, limit: _limit, filter: _filter);
      _videos.addAll(batch);
      _hasMore = batch.length == _limit;
      if (_videos.isEmpty) {
        emit(VideosEmpty());
      } else {
        _page++;
        emit(
          VideosLoaded(
            videos: List.of(_videos),
            filter: _filter,
            isLoadingMore: false,
          ),
        );
      }
    } catch (_) {
      emit(VideosError());
    } finally {
      _busy = false;
    }
  }

  Future<void> _onFilter(FilterVideosEvent event, Emitter<VideosState> emit) async {
    _filter = event.filter;
    add(LoadVideosEvent(refresh: true));
  }

  Future<void> _onDelete(DeleteVideoEvent event, Emitter<VideosState> emit) async {
    await deleteVideo(event.videoId);
    add(LoadVideosEvent(refresh: true));
  }
}
