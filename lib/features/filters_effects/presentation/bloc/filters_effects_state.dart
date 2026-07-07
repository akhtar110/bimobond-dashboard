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
    this.isActioning = false,
    this.message,
    this.isErrorMessage = false,
    this.operationSuccess = false,
  });

  final FiltersEffectsOverviewEntity? overview;
  final CameraStudioCatalogEntity? catalog;
  final List<CameraFilterEntity> filters;
  final List<CameraFilterCategoryEntity> filterCategories;
  final List<CameraEffectEntity> effects;
  final List<CameraEffectCategoryEntity> effectCategories;
  final FiltersEffectsListQuery query;
  final FiltersEffectsTab activeTab;
  final bool isActioning;
  final String? message;
  final bool isErrorMessage;
  final bool operationSuccess;

  List<CameraFilterEntity> get filteredFilters {
    var items = filters;
    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
      items = items
          .where(
            (f) =>
                f.slug.toLowerCase().contains(search) ||
                f.engineKey.toLowerCase().contains(search) ||
                (f.customLabel?.toLowerCase().contains(search) ?? false) ||
                (f.labelKey?.toLowerCase().contains(search) ?? false),
          )
          .toList();
    }
    if (query.status == FiltersEffectsStatusFilter.active) {
      items = items.where((f) => f.isActive).toList();
    } else if (query.status == FiltersEffectsStatusFilter.inactive) {
      items = items.where((f) => !f.isActive).toList();
    }
    if (query.engineKey != null && query.engineKey!.isNotEmpty) {
      items = items.where((f) => f.engineKey == query.engineKey).toList();
    }
    return items;
  }

  List<CameraEffectEntity> get filteredEffects {
    var items = effects;
    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
      items = items
          .where(
            (e) =>
                e.slug.toLowerCase().contains(search) ||
                e.labelKey.toLowerCase().contains(search) ||
                (e.emoji?.contains(search) ?? false),
          )
          .toList();
    }
    if (query.status == FiltersEffectsStatusFilter.active) {
      items = items.where((e) => e.isActive).toList();
    } else if (query.status == FiltersEffectsStatusFilter.inactive) {
      items = items.where((e) => !e.isActive).toList();
    }
    return items;
  }

  int get filtersTotalPages {
    final total = filteredFilters.length;
    if (total == 0) return 1;
    return (total / query.pageSize).ceil();
  }

  int get effectsTotalPages {
    final total = filteredEffects.length;
    if (total == 0) return 1;
    return (total / query.pageSize).ceil();
  }

  List<CameraFilterEntity> get pagedFilters {
    final items = filteredFilters;
    final start = (query.page - 1) * query.pageSize;
    if (start >= items.length) return const [];
    final end = (start + query.pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  List<CameraEffectEntity> get pagedEffects {
    final items = filteredEffects;
    final start = (query.page - 1) * query.pageSize;
    if (start >= items.length) return const [];
    final end = (start + query.pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  FiltersEffectsLoaded copyWith({
    FiltersEffectsOverviewEntity? overview,
    CameraStudioCatalogEntity? catalog,
    List<CameraFilterEntity>? filters,
    List<CameraFilterCategoryEntity>? filterCategories,
    List<CameraEffectEntity>? effects,
    List<CameraEffectCategoryEntity>? effectCategories,
    FiltersEffectsListQuery? query,
    FiltersEffectsTab? activeTab,
    bool? isActioning,
    String? message,
    bool clearMessage = false,
    bool? isErrorMessage,
    bool? operationSuccess,
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
      isActioning: isActioning ?? this.isActioning,
      message: clearMessage ? null : (message ?? this.message),
      isErrorMessage: isErrorMessage ?? this.isErrorMessage,
      operationSuccess: operationSuccess ?? this.operationSuccess,
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
        isActioning,
        message,
        isErrorMessage,
        operationSuccess,
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
