import 'package:equatable/equatable.dart';

import '../../domain/entities/filters_effects_entities.dart';

abstract class FiltersEffectsState extends Equatable {
  const FiltersEffectsState();

  @override
  List<Object?> get props => [];
}

class FiltersEffectsInitial extends FiltersEffectsState {}

class FiltersEffectsLoading extends FiltersEffectsState {}

class FiltersEffectsLoaded extends FiltersEffectsState {
  const FiltersEffectsLoaded({
    required this.overview,
    required this.catalog,
    required this.filters,
    required this.filterCategories,
    required this.effects,
    required this.effectCategories,
    required this.query,
    required this.activeTab,
    this.filtersMeta,
    this.effectsMeta,
    this.allFiltersForPicker = const [],
    this.allEffectsForPicker = const [],
    this.isActioning = false,
    this.message,
    this.messageParams,
    this.isErrorMessage = false,
    this.operationSuccess = false,
    this.selectedFilterIds = const {},
    this.selectedEffectIds = const {},
    this.isBulkDeleting = false,
  });

  final FiltersEffectsOverviewEntity? overview;
  final CameraStudioCatalogEntity? catalog;
  final List<CameraFilterEntity> filters;
  final List<CameraFilterCategoryEntity> filterCategories;
  final List<CameraEffectEntity> effects;
  final List<CameraEffectCategoryEntity> effectCategories;
  final FiltersEffectsListQuery query;
  final FiltersEffectsTab activeTab;
  final FiltersEffectsPaginationMeta? filtersMeta;
  final FiltersEffectsPaginationMeta? effectsMeta;
  final List<CameraFilterEntity> allFiltersForPicker;
  final List<CameraEffectEntity> allEffectsForPicker;
  final bool isActioning;
  final String? message;
  final Map<String, String>? messageParams;
  final bool isErrorMessage;
  final bool operationSuccess;
  final Set<String> selectedFilterIds;
  final Set<String> selectedEffectIds;
  final bool isBulkDeleting;

  bool get hasFilterSelection => selectedFilterIds.isNotEmpty;

  bool get hasEffectSelection => selectedEffectIds.isNotEmpty;

  int get selectedFilterCount => selectedFilterIds.length;

  int get selectedEffectCount => selectedEffectIds.length;

  bool get allVisibleFiltersSelected =>
      filteredFilters.isNotEmpty &&
      filteredFilters.every((f) => selectedFilterIds.contains(f.id));

  bool get someVisibleFiltersSelected =>
      filteredFilters.any((f) => selectedFilterIds.contains(f.id)) &&
      !allVisibleFiltersSelected;

  bool get allVisibleEffectsSelected =>
      filteredEffects.isNotEmpty &&
      filteredEffects.every((e) => selectedEffectIds.contains(e.id));

  bool get someVisibleEffectsSelected =>
      filteredEffects.any((e) => selectedEffectIds.contains(e.id)) &&
      !allVisibleEffectsSelected;

  List<CameraFilterEntity> get filteredFilters => filters;

  List<CameraEffectEntity> get filteredEffects => effects;

  int get filtersTotalPages => filtersMeta?.totalPages ?? 1;

  int get effectsTotalPages => effectsMeta?.totalPages ?? 1;

  int get filtersTotalCount => filtersMeta?.total ?? filters.length;

  int get effectsTotalCount => effectsMeta?.total ?? effects.length;

  List<CameraFilterEntity> get pagedFilters => filters;

  List<CameraEffectEntity> get pagedEffects => effects;

  FiltersEffectsLoaded copyWith({
    FiltersEffectsOverviewEntity? overview,
    CameraStudioCatalogEntity? catalog,
    List<CameraFilterEntity>? filters,
    List<CameraFilterCategoryEntity>? filterCategories,
    List<CameraEffectEntity>? effects,
    List<CameraEffectCategoryEntity>? effectCategories,
    FiltersEffectsListQuery? query,
    FiltersEffectsTab? activeTab,
    FiltersEffectsPaginationMeta? filtersMeta,
    FiltersEffectsPaginationMeta? effectsMeta,
    List<CameraFilterEntity>? allFiltersForPicker,
    List<CameraEffectEntity>? allEffectsForPicker,
    bool? isActioning,
    String? message,
    Map<String, String>? messageParams,
    bool clearMessage = false,
    bool? isErrorMessage,
    bool? operationSuccess,
    Set<String>? selectedFilterIds,
    Set<String>? selectedEffectIds,
    bool clearFilterSelection = false,
    bool clearEffectSelection = false,
    bool? isBulkDeleting,
  }) {
    return FiltersEffectsLoaded(
      overview: overview ?? this.overview,
      catalog: catalog ?? this.catalog,
      filters: filters ?? this.filters,
      filterCategories: filterCategories ?? this.filterCategories,
      effects: effects ?? this.effects,
      effectCategories: effectCategories ?? this.effectCategories,
      query: query ?? this.query,
      activeTab: activeTab ?? this.activeTab,
      filtersMeta: filtersMeta ?? this.filtersMeta,
      effectsMeta: effectsMeta ?? this.effectsMeta,
      allFiltersForPicker: allFiltersForPicker ?? this.allFiltersForPicker,
      allEffectsForPicker: allEffectsForPicker ?? this.allEffectsForPicker,
      isActioning: isActioning ?? this.isActioning,
      message: clearMessage ? null : (message ?? this.message),
      messageParams: clearMessage ? null : (messageParams ?? this.messageParams),
      isErrorMessage: isErrorMessage ?? this.isErrorMessage,
      operationSuccess: operationSuccess ?? this.operationSuccess,
      selectedFilterIds: clearFilterSelection
          ? const {}
          : (selectedFilterIds ?? this.selectedFilterIds),
      selectedEffectIds: clearEffectSelection
          ? const {}
          : (selectedEffectIds ?? this.selectedEffectIds),
      isBulkDeleting: isBulkDeleting ?? this.isBulkDeleting,
    );
  }

  @override
  List<Object?> get props => [
    overview,
    catalog,
    filters,
    filterCategories,
    effects,
    effectCategories,
    query,
    activeTab,
    filtersMeta,
    effectsMeta,
    allFiltersForPicker,
    allEffectsForPicker,
    isActioning,
    message,
    messageParams,
    isErrorMessage,
    operationSuccess,
    selectedFilterIds,
    selectedEffectIds,
    isBulkDeleting,
  ];
}

class FiltersEffectsError extends FiltersEffectsState {
  const FiltersEffectsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FiltersEffectsOperationSuccess extends FiltersEffectsState {
  const FiltersEffectsOperationSuccess(this.message, this.data);

  final String message;
  final FiltersEffectsLoaded data;

  @override
  List<Object?> get props => [message, data];
}
