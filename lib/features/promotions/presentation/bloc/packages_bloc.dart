import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/promotion_entities.dart';
import '../../domain/enums/promotion_enums.dart';
import '../../domain/usecases/promotion_usecases.dart';

enum PackageStatusFilter { all, active, inactive }

abstract class PackagesEvent {}

class LoadPackagesEvent extends PackagesEvent {}

class CreatePackageEvent extends PackagesEvent {
  CreatePackageEvent(this.data);
  final CreatePackageData data;
}

class UpdatePackageEvent extends PackagesEvent {
  UpdatePackageEvent(this.packageId, this.data);
  final String packageId;
  final UpdatePackageData data;
}

class TogglePackageActiveEvent extends PackagesEvent {
  TogglePackageActiveEvent(this.packageId, {required this.activate});
  final String packageId;
  final bool activate;
}

class DeletePackageEvent extends PackagesEvent {
  DeletePackageEvent(this.packageId);
  final String packageId;
}

class SearchPackagesEvent extends PackagesEvent {
  SearchPackagesEvent(this.query);
  final String query;
}

class FilterPackageStatusEvent extends PackagesEvent {
  FilterPackageStatusEvent(this.filter);
  final PackageStatusFilter filter;
}

class ClearPackageFiltersEvent extends PackagesEvent {}

class TogglePackageSelectionEvent extends PackagesEvent {
  TogglePackageSelectionEvent(this.packageId);
  final String packageId;
}

class SelectAllVisiblePackagesEvent extends PackagesEvent {}

class ClearPackageSelectionEvent extends PackagesEvent {}

class BulkActivatePackagesEvent extends PackagesEvent {}

class BulkDeactivatePackagesEvent extends PackagesEvent {}

abstract class PackagesState {}

class PackagesInitial extends PackagesState {}

class PackagesLoading extends PackagesState {}

class PackagesLoaded extends PackagesState {
  PackagesLoaded({
    required this.packages,
    this.search = '',
    this.statusFilter = PackageStatusFilter.all,
    this.selectedIds = const {},
    this.isSaving = false,
    this.isRefreshing = false,
    this.message,
    this.isError = false,
  });

  final List<PromotionPackageEntity> packages;
  final String search;
  final PackageStatusFilter statusFilter;
  final Set<String> selectedIds;
  final bool isSaving;
  final bool isRefreshing;
  final String? message;
  final bool isError;

  List<PromotionPackageEntity> get visiblePackages {
    switch (statusFilter) {
      case PackageStatusFilter.active:
        return packages.where((p) => p.isActive).toList();
      case PackageStatusFilter.inactive:
        return packages.where((p) => !p.isActive).toList();
      case PackageStatusFilter.all:
        return packages;
    }
  }

  int get totalCount => packages.length;
  int get activeCount => packages.where((p) => p.isActive).length;
  int get inactiveCount => packages.length - activeCount;

  int get selectedCount => selectedIds.length;

  bool get allVisibleSelected {
    final visible = visiblePackages;
    if (visible.isEmpty) return false;
    return visible.every((p) => selectedIds.contains(p.id));
  }

  bool get someVisibleSelected {
    if (selectedIds.isEmpty) return false;
    final visibleIds = visiblePackages.map((p) => p.id).toSet();
    return selectedIds.any(visibleIds.contains) && !allVisibleSelected;
  }

  bool get hasActiveFilters =>
      search.trim().isNotEmpty || statusFilter != PackageStatusFilter.all;

  PackagesLoaded copyWith({
    List<PromotionPackageEntity>? packages,
    String? search,
    PackageStatusFilter? statusFilter,
    Set<String>? selectedIds,
    bool? isSaving,
    bool? isRefreshing,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return PackagesLoaded(
      packages: packages ?? this.packages,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedIds: selectedIds ?? this.selectedIds,
      isSaving: isSaving ?? this.isSaving,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }
}

class PackagesError extends PackagesState {
  PackagesError(this.message);
  final String message;
}

class PackagesBloc extends Bloc<PackagesEvent, PackagesState> {
  PackagesBloc({
    required GetPackagesUseCase getPackages,
    required CreatePackageUseCase createPackage,
    required UpdatePackageUseCase updatePackage,
    required TogglePackageStatusUseCase toggleStatus,
    required DeletePackageUseCase deletePackage,
    required BulkCampaignActionUseCase bulkAction,
  })  : _getPackages = getPackages,
        _createPackage = createPackage,
        _updatePackage = updatePackage,
        _toggleStatus = toggleStatus,
        _deletePackage = deletePackage,
        _bulkAction = bulkAction,
        super(PackagesInitial()) {
    on<LoadPackagesEvent>(_onLoad);
    on<CreatePackageEvent>(_onCreate);
    on<UpdatePackageEvent>(_onUpdate);
    on<TogglePackageActiveEvent>(_onToggle);
    on<DeletePackageEvent>(_onDelete);
    on<SearchPackagesEvent>(_onSearch);
    on<FilterPackageStatusEvent>(_onFilterStatus);
    on<ClearPackageFiltersEvent>(_onClearFilters);
    on<TogglePackageSelectionEvent>(_onToggleSelection);
    on<SelectAllVisiblePackagesEvent>(_onSelectAllVisible);
    on<ClearPackageSelectionEvent>(_onClearSelection);
    on<BulkActivatePackagesEvent>(_onBulkActivate);
    on<BulkDeactivatePackagesEvent>(_onBulkDeactivate);
  }

  final GetPackagesUseCase _getPackages;
  final CreatePackageUseCase _createPackage;
  final UpdatePackageUseCase _updatePackage;
  final TogglePackageStatusUseCase _toggleStatus;
  final DeletePackageUseCase _deletePackage;
  final BulkCampaignActionUseCase _bulkAction;
  Timer? _searchDebounce;
  PackagesQuery _query = const PackagesQuery();
  PackageStatusFilter _statusFilter = PackageStatusFilter.all;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadPackagesEvent event,
    Emitter<PackagesState> emit,
  ) async {
    await _reload(
      emit,
      showFullLoading: state is! PackagesLoaded,
    );
  }

  Future<void> _reload(
    Emitter<PackagesState> emit, {
    required bool showFullLoading,
    String? successMessage,
    Set<String>? keepSelectedIds,
  }) async {
    final current = state;
    if (current is PackagesLoaded) {
      emit(current.copyWith(isRefreshing: true, clearMessage: true));
    } else if (showFullLoading) {
      emit(PackagesLoading());
    }

    try {
      final packages = await _getPackages(query: _query);
      final previous = current is PackagesLoaded ? current : null;
      final selected = keepSelectedIds ??
          (previous?.selectedIds
                  .where((id) => packages.any((p) => p.id == id))
                  .toSet() ??
              {});
      emit(
        PackagesLoaded(
          packages: packages,
          search: _query.search ?? '',
          statusFilter: _statusFilter,
          selectedIds: selected,
          message: successMessage,
          isError: false,
        ),
      );
    } catch (e) {
      if (current is PackagesLoaded) {
        emit(current.copyWith(
          isRefreshing: false,
          isSaving: false,
          message: e.toString(),
          isError: true,
        ));
      } else {
        emit(PackagesError(e.toString()));
      }
    }
  }

  void _onSearch(SearchPackagesEvent event, Emitter<PackagesState> emit) {
    _searchDebounce?.cancel();
    final current = state;
    if (current is PackagesLoaded) {
      emit(current.copyWith(search: event.query, clearMessage: true));
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final term = event.query.trim();
      _query = _query.copyWith(
        search: term,
        clearSearch: term.isEmpty,
      );
      add(LoadPackagesEvent());
    });
  }

  void _onFilterStatus(
    FilterPackageStatusEvent event,
    Emitter<PackagesState> emit,
  ) {
    _statusFilter = event.filter;
    final current = state;
    if (current is PackagesLoaded) {
      emit(current.copyWith(
        statusFilter: event.filter,
        clearMessage: true,
      ));
    }
  }

  void _onClearFilters(
    ClearPackageFiltersEvent event,
    Emitter<PackagesState> emit,
  ) {
    _searchDebounce?.cancel();
    _query = const PackagesQuery();
    _statusFilter = PackageStatusFilter.all;
    add(LoadPackagesEvent());
  }

  void _onToggleSelection(
    TogglePackageSelectionEvent event,
    Emitter<PackagesState> emit,
  ) {
    final current = state;
    if (current is! PackagesLoaded) return;
    final next = Set<String>.from(current.selectedIds);
    if (next.contains(event.packageId)) {
      next.remove(event.packageId);
    } else {
      next.add(event.packageId);
    }
    emit(current.copyWith(selectedIds: next, clearMessage: true));
  }

  void _onSelectAllVisible(
    SelectAllVisiblePackagesEvent event,
    Emitter<PackagesState> emit,
  ) {
    final current = state;
    if (current is! PackagesLoaded) return;
    final visibleIds = current.visiblePackages.map((p) => p.id).toSet();
    if (current.allVisibleSelected) {
      emit(current.copyWith(
        selectedIds: current.selectedIds.difference(visibleIds),
        clearMessage: true,
      ));
    } else {
      emit(current.copyWith(
        selectedIds: {...current.selectedIds, ...visibleIds},
        clearMessage: true,
      ));
    }
  }

  void _onClearSelection(
    ClearPackageSelectionEvent event,
    Emitter<PackagesState> emit,
  ) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(selectedIds: {}, clearMessage: true));
  }

  Future<void> _onCreate(
    CreatePackageEvent event,
    Emitter<PackagesState> emit,
  ) async {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(isSaving: true, clearMessage: true));
    try {
      await _createPackage(event.data);
      await _reload(
        emit,
        showFullLoading: false,
        successMessage: 'promoPackageCreated',
        keepSelectedIds: {},
      );
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onUpdate(
    UpdatePackageEvent event,
    Emitter<PackagesState> emit,
  ) async {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(isSaving: true, clearMessage: true));
    try {
      await _updatePackage(event.packageId, event.data);
      await _reload(
        emit,
        showFullLoading: false,
        successMessage: 'promoPackageUpdated',
      );
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onToggle(
    TogglePackageActiveEvent event,
    Emitter<PackagesState> emit,
  ) async {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(isSaving: true, clearMessage: true));
    try {
      if (event.activate) {
        await _toggleStatus.activate(event.packageId);
      } else {
        await _toggleStatus.deactivate(event.packageId);
      }
      await _reload(
        emit,
        showFullLoading: false,
        successMessage: event.activate
            ? 'promoPackageActivated'
            : 'promoPackageDeactivated',
      );
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onDelete(
    DeletePackageEvent event,
    Emitter<PackagesState> emit,
  ) async {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(isSaving: true, clearMessage: true));
    try {
      await _deletePackage(event.packageId);
      final nextSelected = Set<String>.from(current.selectedIds)
        ..remove(event.packageId);
      await _reload(
        emit,
        showFullLoading: false,
        successMessage: 'promoPackageDeleted',
        keepSelectedIds: nextSelected,
      );
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onBulkActivate(
    BulkActivatePackagesEvent event,
    Emitter<PackagesState> emit,
  ) async {
    await _runBulk(
      emit,
      action: BulkCampaignAction.activatePackages,
      successKey: 'promoPackagesBulkActivated',
    );
  }

  Future<void> _onBulkDeactivate(
    BulkDeactivatePackagesEvent event,
    Emitter<PackagesState> emit,
  ) async {
    await _runBulk(
      emit,
      action: BulkCampaignAction.deactivatePackages,
      successKey: 'promoPackagesBulkDeactivated',
    );
  }

  Future<void> _runBulk(
    Emitter<PackagesState> emit, {
    required BulkCampaignAction action,
    required String successKey,
  }) async {
    final current = state;
    if (current is! PackagesLoaded || current.selectedIds.isEmpty) return;
    emit(current.copyWith(isSaving: true, clearMessage: true));
    try {
      await _bulkAction(
        BulkCampaignActionRequest(
          packageIds: current.selectedIds.toList(),
          action: action.apiValue,
        ),
      );
      await _reload(
        emit,
        showFullLoading: false,
        successMessage: successKey,
        keepSelectedIds: {},
      );
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }
}
