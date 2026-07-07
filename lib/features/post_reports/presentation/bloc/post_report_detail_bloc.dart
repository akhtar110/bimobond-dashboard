import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post_report_entities.dart';
import '../../domain/usecases/get_post_report_detail.dart';

part 'post_report_detail_event.dart';
part 'post_report_detail_state.dart';

class PostReportDetailBloc
    extends Bloc<PostReportDetailEvent, PostReportDetailState> {
  PostReportDetailBloc({required GetPostReportDetail getPostReportDetail})
      : _getPostReportDetail = getPostReportDetail,
        super(PostReportDetailInitial()) {
    on<LoadPostReportDetailEvent>(_onLoad);
    on<ChangePostReportDetailDaysEvent>(_onChangeDays);
    on<RefreshPostReportDetailEvent>(_onRefresh);
  }

  final GetPostReportDetail _getPostReportDetail;

  String? _postId;
  int _days = 30;

  Future<void> _onLoad(
    LoadPostReportDetailEvent event,
    Emitter<PostReportDetailState> emit,
  ) async {
    _postId = event.postId;
    _days = event.days;
    emit(PostReportDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onChangeDays(
    ChangePostReportDetailDaysEvent event,
    Emitter<PostReportDetailState> emit,
  ) async {
    _days = event.days;
    final current = state;
    if (current is PostReportDetailLoaded) {
      emit(current.copyWith(days: event.days, isRefreshing: true));
    } else {
      emit(PostReportDetailLoading());
    }
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshPostReportDetailEvent event,
    Emitter<PostReportDetailState> emit,
  ) async {
    final current = state;
    if (current is PostReportDetailLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<PostReportDetailState> emit) async {
    final postId = _postId;
    if (postId == null || postId.isEmpty) {
      emit(PostReportDetailError('Missing post id'));
      return;
    }

    try {
      final detail = await _getPostReportDetail(
        postId: postId,
        query: ReportPeriodQuery(days: _days),
      );
      emit(PostReportDetailLoaded(detail: detail, days: _days));
    } catch (e) {
      emit(PostReportDetailError(e.toString()));
    }
  }
}
