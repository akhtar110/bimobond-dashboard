import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/api_error_messages.dart';
import '../../domain/entities/user_interest_entities.dart';
import '../../domain/usecases/get_user_interests.dart';
import 'user_interests_event.dart';
import 'user_interests_state.dart';

class UserInterestsBloc extends Bloc<UserInterestsEvent, UserInterestsState> {
  UserInterestsBloc({
    required GetUserInterestsUseCase getUserInterests,
  })  : _getUserInterests = getUserInterests,
        super(const UserInterestsInitial()) {
    on<LoadUserInterestsEvent>(_onLoad);
    on<RefreshUserInterestsEvent>(_onRefresh);
    on<SearchInterestsEvent>(_onSearch);
    on<FilterByPreferenceEvent>(_onFilterPreference);
    on<FilterBySourceEvent>(_onFilterSource);
    on<FilterByDateRangeEvent>(_onFilterDateRange);
    on<ClearUserInterestsFiltersEvent>(_onClearFilters);
  }

  final GetUserInterestsUseCase _getUserInterests;

  String? _userId;
  UserInterestsResponseEntity? _response;
  UserInterestsFilterQuery _filter = const UserInterestsFilterQuery();

  Future<void> _onLoad(
    LoadUserInterestsEvent event,
    Emitter<UserInterestsState> emit,
  ) async {
    _userId = event.userId;
    _filter = const UserInterestsFilterQuery();
    emit(const UserInterestsLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshUserInterestsEvent event,
    Emitter<UserInterestsState> emit,
  ) async {
    _userId = event.userId;
    final current = state;
    if (current is UserInterestsLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const UserInterestsLoading());
    }
    await _fetch(emit);
  }

  void _onSearch(
    SearchInterestsEvent event,
    Emitter<UserInterestsState> emit,
  ) {
    final trimmed = event.query.trim();
    _filter = _filter.copyWith(
      search: trimmed,
      clearSearch: trimmed.isEmpty,
    );
    _emitFiltered(emit);
  }

  void _onFilterPreference(
    FilterByPreferenceEvent event,
    Emitter<UserInterestsState> emit,
  ) {
    _filter = _filter.copyWith(
      preference: event.preference,
      clearPreference: event.preference == null,
    );
    _emitFiltered(emit);
  }

  void _onFilterSource(
    FilterBySourceEvent event,
    Emitter<UserInterestsState> emit,
  ) {
    _filter = _filter.copyWith(
      source: event.source,
      clearSource: event.source == null,
    );
    _emitFiltered(emit);
  }

  void _onFilterDateRange(
    FilterByDateRangeEvent event,
    Emitter<UserInterestsState> emit,
  ) {
    if (event.from == null && event.to == null) {
      _filter = _filter.copyWith(clearDateRange: true);
    } else {
      _filter = _filter.copyWith(
        createdFrom: event.from,
        createdTo: event.to,
      );
    }
    _emitFiltered(emit);
  }

  void _onClearFilters(
    ClearUserInterestsFiltersEvent event,
    Emitter<UserInterestsState> emit,
  ) {
    _filter = const UserInterestsFilterQuery();
    _emitFiltered(emit);
  }

  Future<void> _fetch(Emitter<UserInterestsState> emit) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      emit(const UserInterestsError(message: 'User not found.'));
      return;
    }

    try {
      final response = await _getUserInterests(userId);
      _response = response;
      _emitFiltered(emit);
    } catch (error) {
      emit(_mapError(error, userId));
    }
  }

  void _emitFiltered(Emitter<UserInterestsState> emit) {
    final userId = _userId;
    final response = _response;
    if (userId == null || response == null) return;

    final interests = _applyFilter(response.interests);
    final notInterests = _applyFilter(response.notInterests);

    if (response.isEmpty && !_filter.hasActiveFilters) {
      emit(UserInterestsEmpty(
        userId: userId,
        meta: response.meta,
        filter: _filter,
      ));
      return;
    }

    emit(UserInterestsLoaded(
      userId: userId,
      response: response,
      filteredInterests: interests,
      filteredNotInterests: notInterests,
      filter: _filter,
    ));
  }

  List<UserInterestEntity> _applyFilter(List<UserInterestEntity> items) {
    final search = _filter.search?.trim().toLowerCase();
    final preference = _filter.preference;
    final source = _filter.source;
    final from = _filter.createdFrom;
    final to = _filter.createdTo;

    return items.where((item) {
      if (preference != null && item.preference != preference) return false;
      if (source != null && item.source != source) return false;

      if (search != null && search.isNotEmpty) {
        final name = item.category.name.toLowerCase();
        final slug = item.category.slug.toLowerCase();
        if (!name.contains(search) && !slug.contains(search)) return false;
      }

      if (from != null) {
        final start = DateTime(from.year, from.month, from.day);
        if (item.createdAt.isBefore(start)) return false;
      }
      if (to != null) {
        final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
        if (item.createdAt.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  UserInterestsError _mapError(Object error, String userId) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 403 || status == 401) {
        return UserInterestsError(
          message: 'You are not allowed to view user interests.',
          userId: userId,
          isForbidden: true,
        );
      }
      if (status == 404) {
        return UserInterestsError(
          message: 'User not found.',
          userId: userId,
          isNotFound: true,
        );
      }
    }
    final message = ApiErrorMessages.from(error);
    return UserInterestsError(
      message: message.isNotEmpty ? message : 'Failed to load topics.',
      userId: userId,
    );
  }
}
