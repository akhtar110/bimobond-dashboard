import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/usecases/promotion_usecases.dart';

abstract class PromotedPostDetailEvent extends Equatable {
  const PromotedPostDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadPromotedPostDetailEvent extends PromotedPostDetailEvent {
  const LoadPromotedPostDetailEvent(this.postId);
  final String postId;
  @override
  List<Object?> get props => [postId];
}

abstract class PromotedPostDetailState extends Equatable {
  const PromotedPostDetailState();
  @override
  List<Object?> get props => [];
}

class PromotedPostDetailInitial extends PromotedPostDetailState {}

class PromotedPostDetailLoading extends PromotedPostDetailState {}

class PromotedPostDetailLoaded extends PromotedPostDetailState {
  const PromotedPostDetailLoaded({required this.detail});
  final PromotedPostDetailEntity detail;
  @override
  List<Object?> get props => [detail];
}

class PromotedPostDetailEmpty extends PromotedPostDetailState {}

class PromotedPostDetailError extends PromotedPostDetailState {
  const PromotedPostDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class PromotedPostDetailBloc
    extends Bloc<PromotedPostDetailEvent, PromotedPostDetailState> {
  PromotedPostDetailBloc({
    required GetPromotedPostDetailUseCase getDetail,
  })  : _getDetail = getDetail,
        super(PromotedPostDetailInitial()) {
    on<LoadPromotedPostDetailEvent>(_onLoad);
  }

  final GetPromotedPostDetailUseCase _getDetail;

  Future<void> _onLoad(
    LoadPromotedPostDetailEvent event,
    Emitter<PromotedPostDetailState> emit,
  ) async {
    emit(PromotedPostDetailLoading());
    try {
      final detail = await _getDetail(event.postId);
      emit(PromotedPostDetailLoaded(detail: detail));
    } catch (e) {
      emit(PromotedPostDetailError(e.toString()));
    }
  }
}
