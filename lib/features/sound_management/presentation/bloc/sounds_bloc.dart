import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/sound_entities.dart';
import '../../domain/usecases/sound_usecases.dart';

abstract class SoundsEvent extends Equatable {
  const SoundsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSoundsEvent extends SoundsEvent {
  const LoadSoundsEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
  @override
  List<Object?> get props => [refresh, page];
}

class SearchSoundsEvent extends SoundsEvent {
  const SearchSoundsEvent(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class SortSoundsEvent extends SoundsEvent {
  const SortSoundsEvent(this.sort);
  final SoundSortMode sort;
  @override
  List<Object?> get props => [sort];
}

class FilterSoundsActiveEvent extends SoundsEvent {
  const FilterSoundsActiveEvent(this.isActive);
  final bool? isActive;
  @override
  List<Object?> get props => [isActive];
}

class FilterSoundsCreatorEvent extends SoundsEvent {
  const FilterSoundsCreatorEvent(this.creatorId);
  final String? creatorId;
  @override
  List<Object?> get props => [creatorId];
}

class ClearSoundsFiltersEvent extends SoundsEvent {
  const ClearSoundsFiltersEvent();
}

class ToggleSoundSelectionEvent extends SoundsEvent {
  const ToggleSoundSelectionEvent(this.soundId);
  final String soundId;
  @override
  List<Object?> get props => [soundId];
}

class SelectAllSoundsEvent extends SoundsEvent {
  const SelectAllSoundsEvent();
}

class ClearSoundSelectionEvent extends SoundsEvent {
  const ClearSoundSelectionEvent();
}

enum SoundLibraryMutation {
  created,
  updated,
  deleted,
  activated,
  deactivated,
  bulkDeleted,
  bulkActivated,
  bulkDeactivated,
}

class ApplySoundLibraryMutationEvent extends SoundsEvent {
  const ApplySoundLibraryMutationEvent({
    required this.mutation,
    this.sound,
    this.soundIds = const [],
  });

  final SoundLibraryMutation mutation;
  final SoundEntity? sound;
  final List<String> soundIds;

  @override
  List<Object?> get props => [mutation, sound, soundIds];
}

abstract class SoundsState extends Equatable {
  const SoundsState();
  @override
  List<Object?> get props => [];
}

class SoundsInitial extends SoundsState {}

class SoundsLoading extends SoundsState {}

class SoundsLoaded extends SoundsState {
  const SoundsLoaded({
    required this.sounds,
    required this.meta,
    required this.query,
    this.selectedIds = const {},
    this.isRefreshing = false,
  });

  final List<SoundEntity> sounds;
  final PaginationMeta meta;
  final SoundsQuery query;
  final Set<String> selectedIds;
  final bool isRefreshing;

  SoundsLoaded copyWith({
    List<SoundEntity>? sounds,
    PaginationMeta? meta,
    SoundsQuery? query,
    Set<String>? selectedIds,
    bool? isRefreshing,
    bool clearSelection = false,
  }) {
    return SoundsLoaded(
      sounds: sounds ?? this.sounds,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      selectedIds: clearSelection ? const {} : (selectedIds ?? this.selectedIds),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  int get selectedCount => selectedIds.length;

  bool get allVisibleSelected {
    if (sounds.isEmpty) return false;
    return sounds.every((s) => selectedIds.contains(s.id));
  }

  bool get someVisibleSelected =>
      selectedIds.isNotEmpty && !allVisibleSelected;

  @override
  List<Object?> get props =>
      [sounds, meta, query, selectedIds, isRefreshing];
}

class SoundsEmpty extends SoundsState {
  const SoundsEmpty({required this.query, this.isLoading = false});
  final SoundsQuery query;
  final bool isLoading;
  @override
  List<Object?> get props => [query, isLoading];
}

class SoundsError extends SoundsState {
  const SoundsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class SoundsBloc extends Bloc<SoundsEvent, SoundsState> {
  SoundsBloc({required GetSoundsUseCase getSounds})
      : _getSounds = getSounds,
        super(SoundsInitial()) {
    on<LoadSoundsEvent>(_onLoad);
    on<SearchSoundsEvent>(_onSearch);
    on<SortSoundsEvent>(_onSort);
    on<FilterSoundsActiveEvent>(_onFilterActive);
    on<FilterSoundsCreatorEvent>(_onFilterCreator);
    on<ClearSoundsFiltersEvent>(_onClearFilters);
    on<ToggleSoundSelectionEvent>(_onToggleSelection);
    on<SelectAllSoundsEvent>(_onSelectAll);
    on<ClearSoundSelectionEvent>(_onClearSelection);
    on<ApplySoundLibraryMutationEvent>(_onApplyMutation);
  }

  final GetSoundsUseCase _getSounds;
  Timer? _searchDebounce;
  SoundsQuery _query = const SoundsQuery();

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadSoundsEvent event,
    Emitter<SoundsState> emit,
  ) async {
    final current = state;
    if (current is SoundsLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else if (current is SoundsEmpty) {
      emit(SoundsEmpty(query: _query, isLoading: true));
    } else {
      emit(SoundsLoading());
    }

    _query = _query.copyWith(page: event.page ?? _query.page);

    try {
      final result = await _getSounds(_query);
      if (result.data.isEmpty) {
        emit(SoundsEmpty(query: _query));
      } else {
        final previousSelection =
            current is SoundsLoaded ? current.selectedIds : const <String>{};
        emit(
          SoundsLoaded(
            sounds: result.data,
            meta: result.meta,
            query: _query,
            selectedIds: previousSelection,
          ),
        );
      }
    } catch (e) {
      if (current is SoundsLoaded) {
        emit(current.copyWith(isRefreshing: false));
      } else if (current is SoundsEmpty) {
        emit(SoundsEmpty(query: _query));
      } else {
        emit(SoundsError(e.toString()));
      }
    }
  }

  void _onSearch(SearchSoundsEvent event, Emitter<SoundsState> emit) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _query = _query.copyWith(
        page: 1,
        search: event.query.trim(),
        clearSearch: event.query.trim().isEmpty,
      );
      add(const LoadSoundsEvent(refresh: true));
    });
  }

  void _onSort(SortSoundsEvent event, Emitter<SoundsState> emit) {
    _query = _query.copyWith(page: 1, sort: event.sort);
    add(const LoadSoundsEvent(refresh: true));
  }

  void _onFilterActive(
    FilterSoundsActiveEvent event,
    Emitter<SoundsState> emit,
  ) {
    _query = _query.copyWith(
      page: 1,
      isActive: event.isActive,
      clearIsActive: event.isActive == null,
    );
    add(const LoadSoundsEvent(refresh: true));
  }

  void _onFilterCreator(
    FilterSoundsCreatorEvent event,
    Emitter<SoundsState> emit,
  ) {
    _query = _query.copyWith(
      page: 1,
      creatorId: event.creatorId,
      clearCreatorId: event.creatorId == null || event.creatorId!.isEmpty,
    );
    add(const LoadSoundsEvent(refresh: true));
  }

  void _onClearFilters(ClearSoundsFiltersEvent event, Emitter<SoundsState> emit) {
    _searchDebounce?.cancel();
    _query = const SoundsQuery();
    add(const LoadSoundsEvent(refresh: true));
  }

  void _onToggleSelection(
    ToggleSoundSelectionEvent event,
    Emitter<SoundsState> emit,
  ) {
    final current = state;
    if (current is! SoundsLoaded) return;
    final next = Set<String>.from(current.selectedIds);
    if (next.contains(event.soundId)) {
      next.remove(event.soundId);
    } else {
      next.add(event.soundId);
    }
    emit(current.copyWith(selectedIds: next));
  }

  void _onSelectAll(SelectAllSoundsEvent event, Emitter<SoundsState> emit) {
    final current = state;
    if (current is! SoundsLoaded || current.sounds.isEmpty) return;
    if (current.allVisibleSelected) {
      emit(current.copyWith(clearSelection: true));
    } else {
      emit(
        current.copyWith(
          selectedIds: current.sounds.map((s) => s.id).toSet(),
        ),
      );
    }
  }

  void _onClearSelection(
    ClearSoundSelectionEvent event,
    Emitter<SoundsState> emit,
  ) {
    final current = state;
    if (current is! SoundsLoaded) return;
    emit(current.copyWith(clearSelection: true));
  }

  void _onApplyMutation(
    ApplySoundLibraryMutationEvent event,
    Emitter<SoundsState> emit,
  ) {
    final current = state;
    if (current is! SoundsLoaded) {
      if (event.mutation == SoundLibraryMutation.created) {
        add(const LoadSoundsEvent(refresh: true));
      }
      return;
    }

    switch (event.mutation) {
      case SoundLibraryMutation.created:
        final sound = event.sound;
        if (sound == null || !_matchesQuery(sound, current.query)) return;
        if (current.query.page != 1) {
          emit(
            current.copyWith(
              meta: _metaWithTotal(current.meta, current.meta.total + 1),
              clearSelection: true,
            ),
          );
          return;
        }
        final sounds = [sound, ...current.sounds];
        final limit = current.query.limit;
        emit(
          current.copyWith(
            sounds: sounds.length > limit ? sounds.sublist(0, limit) : sounds,
            meta: _metaWithTotal(current.meta, current.meta.total + 1),
            clearSelection: true,
          ),
        );
      case SoundLibraryMutation.updated:
      case SoundLibraryMutation.activated:
      case SoundLibraryMutation.deactivated:
        final sound = event.sound;
        if (sound == null) return;
        _upsertOrRemoveSound(emit, current, sound);
      case SoundLibraryMutation.deleted:
        final id = event.soundIds.isNotEmpty ? event.soundIds.first : null;
        if (id == null || id.isEmpty) return;
        _removeSounds(emit, current, {id});
      case SoundLibraryMutation.bulkDeleted:
        if (event.soundIds.isEmpty) return;
        _removeSounds(emit, current, event.soundIds.toSet());
      case SoundLibraryMutation.bulkActivated:
      case SoundLibraryMutation.bulkDeactivated:
        final active =
            event.mutation == SoundLibraryMutation.bulkActivated;
        if (event.soundIds.isEmpty) return;
        _bulkSetActive(emit, current, event.soundIds.toSet(), active);
    }
  }

  bool _matchesQuery(SoundEntity sound, SoundsQuery query) {
    if (query.isActive != null && sound.isActive != query.isActive) {
      return false;
    }
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      final haystack =
          '${sound.name} ${sound.author}'.toLowerCase();
      if (!haystack.contains(search)) return false;
    }
    return true;
  }

  PaginationMeta _metaWithTotal(PaginationMeta meta, int total) {
    final safeTotal = total < 0 ? 0 : total;
    final totalPages = meta.limit <= 0
        ? 1
        : (safeTotal / meta.limit).ceil().clamp(1, 999999);
    return PaginationMeta(
      total: safeTotal,
      page: meta.page,
      limit: meta.limit,
      totalPages: totalPages,
    );
  }

  void _upsertOrRemoveSound(
    Emitter<SoundsState> emit,
    SoundsLoaded current,
    SoundEntity sound,
  ) {
    final index = current.sounds.indexWhere((s) => s.id == sound.id);
    if (!_matchesQuery(sound, current.query)) {
      if (index >= 0) {
        _removeSounds(emit, current, {sound.id});
      }
      return;
    }
    if (index < 0) return;
    final next = List<SoundEntity>.from(current.sounds)..[index] = sound;
    emit(current.copyWith(sounds: next, clearSelection: true));
  }

  void _removeSounds(
    Emitter<SoundsState> emit,
    SoundsLoaded current,
    Set<String> ids,
  ) {
    if (ids.isEmpty) return;
    final nextSounds =
        current.sounds.where((s) => !ids.contains(s.id)).toList();
    final removedCount =
        current.sounds.length - nextSounds.length;
    if (removedCount <= 0) return;

    final nextTotal = (current.meta.total - removedCount).clamp(0, 999999999);
    final nextMeta = _metaWithTotal(current.meta, nextTotal);

    if (nextSounds.isEmpty && nextTotal == 0) {
      emit(SoundsEmpty(query: current.query));
      return;
    }

    emit(
      current.copyWith(
        sounds: nextSounds,
        meta: nextMeta,
        clearSelection: true,
      ),
    );
  }

  void _bulkSetActive(
    Emitter<SoundsState> emit,
    SoundsLoaded current,
    Set<String> ids,
    bool isActive,
  ) {
    if (ids.isEmpty) return;

    if (current.query.isActive != null && current.query.isActive != isActive) {
      _removeSounds(emit, current, ids);
      return;
    }

    final next = current.sounds
        .map(
          (sound) => ids.contains(sound.id)
              ? SoundEntity(
                  id: sound.id,
                  name: sound.name,
                  author: sound.author,
                  audioUrl: sound.audioUrl,
                  coverUrl: sound.coverUrl,
                  duration: sound.duration,
                  useCount: sound.useCount,
                  isOriginal: sound.isOriginal,
                  isActive: isActive,
                  originalSoundId: sound.originalSoundId,
                  creatorId: sound.creatorId,
                  createdAt: sound.createdAt,
                  creator: sound.creator,
                )
              : sound,
        )
        .toList();

    emit(current.copyWith(sounds: next, clearSelection: true));
  }
}
