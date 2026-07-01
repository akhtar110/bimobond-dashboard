import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sound_entities.dart';
import '../../domain/usecases/sound_usecases.dart';

abstract class SoundOverviewEvent extends Equatable {
  const SoundOverviewEvent();
  @override
  List<Object?> get props => [];
}

class LoadSoundOverviewEvent extends SoundOverviewEvent {
  const LoadSoundOverviewEvent({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

abstract class SoundOverviewState extends Equatable {
  const SoundOverviewState();
  @override
  List<Object?> get props => [];
}

class SoundOverviewInitial extends SoundOverviewState {}

class SoundOverviewLoading extends SoundOverviewState {}

class SoundOverviewLoaded extends SoundOverviewState {
  const SoundOverviewLoaded({
    required this.overview,
    this.isRefreshing = false,
  });

  final SoundOverviewEntity overview;
  final bool isRefreshing;

  SoundOverviewLoaded copyWith({
    SoundOverviewEntity? overview,
    bool? isRefreshing,
  }) {
    return SoundOverviewLoaded(
      overview: overview ?? this.overview,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [overview, isRefreshing];
}

class SoundOverviewError extends SoundOverviewState {
  const SoundOverviewError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class SoundOverviewBloc extends Bloc<SoundOverviewEvent, SoundOverviewState> {
  SoundOverviewBloc({required GetSoundOverviewUseCase getOverview})
      : _getOverview = getOverview,
        super(SoundOverviewInitial()) {
    on<LoadSoundOverviewEvent>(_onLoad);
  }

  final GetSoundOverviewUseCase _getOverview;

  Future<void> _onLoad(
    LoadSoundOverviewEvent event,
    Emitter<SoundOverviewState> emit,
  ) async {
    final current = state;
    if (current is SoundOverviewLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(SoundOverviewLoading());
    }

    try {
      final overview = await _getOverview();
      emit(SoundOverviewLoaded(overview: overview));
    } catch (e) {
      if (current is SoundOverviewLoaded) {
        emit(current.copyWith(isRefreshing: false));
      } else {
        emit(SoundOverviewError(e.toString()));
      }
    }
  }
}
