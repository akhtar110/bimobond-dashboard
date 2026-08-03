import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../../domain/usecases/promotion_usecases.dart';

abstract class CampaignsEvent {}

class LoadCampaignsEvent extends CampaignsEvent {
  LoadCampaignsEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class LoadMoreCampaignsEvent extends CampaignsEvent {}

class SearchCampaignsEvent extends CampaignsEvent {
  SearchCampaignsEvent(this.query);
  final String query;
}

class FilterCampaignStatusEvent extends CampaignsEvent {
  FilterCampaignStatusEvent(this.status);
  final String? status;
}

class FilterCampaignObjectiveEvent extends CampaignsEvent {
  FilterCampaignObjectiveEvent(this.objective);
  final String? objective;
}

class FilterCampaignDateRangeEvent extends CampaignsEvent {
  FilterCampaignDateRangeEvent(this.range);
  final DateTimeRange? range;
}

class ToggleCampaignSelectionEvent extends CampaignsEvent {
  ToggleCampaignSelectionEvent(this.campaignId);
  final String campaignId;
}

class SelectAllCampaignsEvent extends CampaignsEvent {}

class ClearCampaignSelectionEvent extends CampaignsEvent {}

class ClearCampaignFiltersEvent extends CampaignsEvent {}

class UpdateCampaignStatusFromListEvent extends CampaignsEvent {
  UpdateCampaignStatusFromListEvent(this.campaignId, this.status);
  final String campaignId;
  final String status;
}

class DeleteCampaignFromListEvent extends CampaignsEvent {
  DeleteCampaignFromListEvent(this.campaignId);
  final String campaignId;
}

abstract class CampaignsState {}

class CampaignsInitial extends CampaignsState {}

class CampaignsLoading extends CampaignsState {
  CampaignsLoading({this.query = const AdminCampaignsQuery()});

  final AdminCampaignsQuery query;
}

class CampaignsLoaded extends CampaignsState {
  CampaignsLoaded({
    required this.campaigns,
    required this.meta,
    required this.query,
    this.selectedIds = const {},
    this.isActioning = false,
    this.isLoadingMore = false,
    this.message,
    this.isError = false,
  });

  final List<CampaignEntity> campaigns;
  final PaginationMeta meta;
  final AdminCampaignsQuery query;
  final Set<String> selectedIds;
  final bool isActioning;
  final bool isLoadingMore;
  final String? message;
  final bool isError;

  CampaignsLoaded copyWith({
    List<CampaignEntity>? campaigns,
    PaginationMeta? meta,
    AdminCampaignsQuery? query,
    Set<String>? selectedIds,
    bool? isActioning,
    bool? isLoadingMore,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return CampaignsLoaded(
      campaigns: campaigns ?? this.campaigns,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      selectedIds: selectedIds ?? this.selectedIds,
      isActioning: isActioning ?? this.isActioning,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  int get selectedCount => selectedIds.length;

  bool get allVisibleSelected {
    if (campaigns.isEmpty) return false;
    final visibleIds = campaigns.map((c) => c.id);
    return visibleIds.every(selectedIds.contains);
  }

  bool get someVisibleSelected =>
      selectedIds.isNotEmpty && !allVisibleSelected;
}

class CampaignsError extends CampaignsState {
  CampaignsError(this.message, {this.query = const AdminCampaignsQuery()});

  final String message;
  final AdminCampaignsQuery query;
}

class CampaignsBloc extends Bloc<CampaignsEvent, CampaignsState> {
  CampaignsBloc({
    required GetCampaignsUseCase getCampaigns,
    required UpdateCampaignStatusUseCase updateStatus,
    required DeleteCampaignUseCase deleteCampaign,
  })  : _getCampaigns = getCampaigns,
        _updateStatus = updateStatus,
        _deleteCampaign = deleteCampaign,
        super(CampaignsInitial()) {
    on<LoadCampaignsEvent>(_onLoad);
    on<LoadMoreCampaignsEvent>(_onLoadMore);
    on<SearchCampaignsEvent>(_onSearch);
    on<FilterCampaignStatusEvent>(_onFilterStatus);
    on<FilterCampaignObjectiveEvent>(_onFilterObjective);
    on<FilterCampaignDateRangeEvent>(_onFilterDate);
    on<ToggleCampaignSelectionEvent>(_onToggleSelection);
    on<SelectAllCampaignsEvent>(_onSelectAll);
    on<ClearCampaignSelectionEvent>(_onClearSelection);
    on<ClearCampaignFiltersEvent>(_onClearFilters);
    on<UpdateCampaignStatusFromListEvent>(_onUpdateStatus);
    on<DeleteCampaignFromListEvent>(_onDelete);
  }

  final GetCampaignsUseCase _getCampaigns;
  final UpdateCampaignStatusUseCase _updateStatus;
  final DeleteCampaignUseCase _deleteCampaign;
  Timer? _searchDebounce;
  AdminCampaignsQuery _query = const AdminCampaignsQuery();
  int _loadGeneration = 0;
  bool _loadMoreBusy = false;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadCampaignsEvent event,
    Emitter<CampaignsState> emit,
  ) async {
    final loadId = ++_loadGeneration;
    final previous = state;

    final page = event.page ?? _query.page;
    _query = _query.copyWith(page: page);

    if (previous is CampaignsLoaded) {
      emit(previous.copyWith(
        isActioning: true,
        isLoadingMore: false,
        query: _query,
        clearMessage: true,
      ));
    } else {
      emit(CampaignsLoading(query: _query));
    }

    try {
      final result = await _getCampaigns(_query);
      if (loadId != _loadGeneration) return;
      emit(
        CampaignsLoaded(
          campaigns: result.data,
          meta: result.meta,
          query: _query,
          selectedIds:
              previous is CampaignsLoaded ? previous.selectedIds : {},
        ),
      );
    } catch (e) {
      if (loadId != _loadGeneration) return;
      final current = state;
      if (current is CampaignsLoaded) {
        emit(current.copyWith(
          isActioning: false,
          message: e.toString(),
          isError: true,
        ));
      } else {
        emit(CampaignsError(e.toString(), query: _query));
      }
    }
  }

  Future<void> _onLoadMore(
    LoadMoreCampaignsEvent event,
    Emitter<CampaignsState> emit,
  ) async {
    final current = state;
    if (current is! CampaignsLoaded) return;
    if (current.meta.hasReachedMax ||
        current.isLoadingMore ||
        current.isActioning ||
        _loadMoreBusy) {
      return;
    }

    _loadMoreBusy = true;
    final nextPage = current.meta.page + 1;
    _query = _query.copyWith(page: nextPage);
    emit(current.copyWith(isLoadingMore: true, clearMessage: true));

    try {
      final result = await _getCampaigns(_query);
      emit(
        CampaignsLoaded(
          campaigns: [...current.campaigns, ...result.data],
          meta: result.meta,
          query: _query,
          selectedIds: current.selectedIds,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isLoadingMore: false,
          message: e.toString(),
          isError: true,
        ),
      );
    } finally {
      _loadMoreBusy = false;
    }
  }

  void _onSearch(SearchCampaignsEvent event, Emitter<CampaignsState> emit) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _query = _query.copyWith(
        page: 1,
        search: event.query.trim(),
        clearSearch: event.query.trim().isEmpty,
      );
      add(LoadCampaignsEvent(refresh: true));
    });
  }

  void _onFilterStatus(
    FilterCampaignStatusEvent event,
    Emitter<CampaignsState> emit,
  ) {
    _query = _query.copyWith(
      page: 1,
      status: event.status,
      clearStatus: event.status == null,
    );
    add(LoadCampaignsEvent(refresh: true));
  }

  void _onFilterObjective(
    FilterCampaignObjectiveEvent event,
    Emitter<CampaignsState> emit,
  ) {
    _query = _query.copyWith(
      page: 1,
      objective: event.objective,
      clearObjective: event.objective == null,
    );
    add(LoadCampaignsEvent(refresh: true));
  }

  void _onFilterDate(
    FilterCampaignDateRangeEvent event,
    Emitter<CampaignsState> emit,
  ) {
    add(LoadCampaignsEvent(refresh: true));
  }

  void _onToggleSelection(
    ToggleCampaignSelectionEvent event,
    Emitter<CampaignsState> emit,
  ) {
    final current = state;
    if (current is! CampaignsLoaded) return;
    final next = Set<String>.from(current.selectedIds);
    if (next.contains(event.campaignId)) {
      next.remove(event.campaignId);
    } else {
      next.add(event.campaignId);
    }
    emit(current.copyWith(selectedIds: next));
  }

  void _onSelectAll(SelectAllCampaignsEvent event, Emitter<CampaignsState> emit) {
    final current = state;
    if (current is! CampaignsLoaded) return;
    final visibleIds = current.campaigns.map((c) => c.id).toSet();
    if (current.allVisibleSelected) {
      emit(
        current.copyWith(
          selectedIds: current.selectedIds.difference(visibleIds),
        ),
      );
    } else {
      emit(
        current.copyWith(
          selectedIds: {...current.selectedIds, ...visibleIds},
        ),
      );
    }
  }

  void _onClearSelection(
    ClearCampaignSelectionEvent event,
    Emitter<CampaignsState> emit,
  ) {
    final current = state;
    if (current is! CampaignsLoaded) return;
    emit(current.copyWith(selectedIds: {}));
  }

  void _onClearFilters(
    ClearCampaignFiltersEvent event,
    Emitter<CampaignsState> emit,
  ) {
    _searchDebounce?.cancel();
    _query = const AdminCampaignsQuery();
    final current = state;
    if (current is CampaignsLoaded) {
      emit(current.copyWith(
        query: _query,
        isActioning: true,
        clearMessage: true,
        selectedIds: {},
      ));
    }
    add(LoadCampaignsEvent(refresh: true));
  }

  Future<void> _onUpdateStatus(
    UpdateCampaignStatusFromListEvent event,
    Emitter<CampaignsState> emit,
  ) async {
    final current = state;
    if (current is! CampaignsLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _updateStatus(event.campaignId, event.status);
      add(LoadCampaignsEvent(refresh: true));
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onDelete(
    DeleteCampaignFromListEvent event,
    Emitter<CampaignsState> emit,
  ) async {
    final current = state;
    if (current is! CampaignsLoaded) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await _deleteCampaign(event.campaignId);
      add(LoadCampaignsEvent(refresh: true));
    } catch (e) {
      emit(current.copyWith(
        isActioning: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

}

abstract class BulkActionsEvent {}

class ExecuteBulkCampaignActionEvent extends BulkActionsEvent {
  ExecuteBulkCampaignActionEvent({
    required this.campaignIds,
    required this.action,
    this.status,
  });

  final List<String> campaignIds;
  final BulkCampaignAction action;
  final String? status;
}

class BulkActionsState {}

class BulkActionsInitial extends BulkActionsState {}

class BulkActionsRunning extends BulkActionsState {}

class BulkActionsSuccess extends BulkActionsState {
  BulkActionsSuccess(this.result);
  final BulkActionResultEntity result;
}

class BulkActionsError extends BulkActionsState {
  BulkActionsError(this.message);
  final String message;
}

class BulkActionsBloc extends Bloc<BulkActionsEvent, BulkActionsState> {
  BulkActionsBloc({required BulkCampaignActionUseCase bulkAction})
      : _bulkAction = bulkAction,
        super(BulkActionsInitial()) {
    on<ExecuteBulkCampaignActionEvent>(_onExecute);
  }

  final BulkCampaignActionUseCase _bulkAction;

  Future<void> _onExecute(
    ExecuteBulkCampaignActionEvent event,
    Emitter<BulkActionsState> emit,
  ) async {
    emit(BulkActionsRunning());
    try {
      final result = await _bulkAction(
        BulkCampaignActionRequest(
          campaignIds: event.campaignIds,
          action: event.action.apiValue,
          status: event.status,
        ),
      );
      emit(BulkActionsSuccess(result));
    } catch (e) {
      emit(BulkActionsError(e.toString()));
    }
  }
}
