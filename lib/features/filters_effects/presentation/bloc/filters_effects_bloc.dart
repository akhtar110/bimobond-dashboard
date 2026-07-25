import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import '../utils/fe_api_errors.dart';
import 'filters_effects_event.dart';
import 'filters_effects_state.dart';

class FiltersEffectsBloc
    extends Bloc<FiltersEffectsEvent, FiltersEffectsState> {
  FiltersEffectsBloc({
    required GetFiltersEffectsOverviewUseCase getOverview,
    required GetFiltersEffectsCatalogUseCase getCatalog,
    required GetCameraFiltersUseCase getFilters,
    required CreateCameraFilterUseCase createFilter,
    required UpdateCameraFilterUseCase updateFilter,
    required DeleteCameraFilterUseCase deleteFilter,
    required BulkCameraFiltersUseCase bulkFilters,
    BulkUpdateCameraFiltersUseCase? bulkUpdateFilters,
    required ActivateCameraFilterUseCase activateFilter,
    required DeactivateCameraFilterUseCase deactivateFilter,
    required GetCameraFilterCategoriesUseCase getFilterCategories,
    required CreateCameraFilterCategoryUseCase createFilterCategory,
    required UpdateCameraFilterCategoryUseCase updateFilterCategory,
    required DeleteCameraFilterCategoryUseCase deleteFilterCategory,
    required ReorderCameraFilterCategoriesUseCase reorderFilterCategories,
    required AssignFiltersToCategoryUseCase assignFiltersToCategory,
    required GetCameraEffectsUseCase getEffects,
    required CreateCameraEffectUseCase createEffect,
    required UpdateCameraEffectUseCase updateEffect,
    required DeleteCameraEffectUseCase deleteEffect,
    required BulkCameraEffectsUseCase bulkEffects,
    required ActivateCameraEffectUseCase activateEffect,
    required DeactivateCameraEffectUseCase deactivateEffect,
    required GetCameraEffectCategoriesUseCase getEffectCategories,
    required CreateCameraEffectCategoryUseCase createEffectCategory,
    required UpdateCameraEffectCategoryUseCase updateEffectCategory,
    required DeleteCameraEffectCategoryUseCase deleteEffectCategory,
    required ReorderCameraEffectCategoriesUseCase reorderEffectCategories,
    required AssignEffectsToCategoryUseCase assignEffectsToCategory,
    required PublishFiltersEffectsCatalogUseCase publishCatalog,
    required SeedFiltersEffectsCatalogUseCase seedCatalog,
  }) : _getOverview = getOverview,
       _getCatalog = getCatalog,
       _getFilters = getFilters,
       _createFilter = createFilter,
       _updateFilter = updateFilter,
       _deleteFilter = deleteFilter,
       _bulkFilters = bulkFilters,
       _bulkUpdateFilters = bulkUpdateFilters,
       _activateFilter = activateFilter,
       _deactivateFilter = deactivateFilter,
       _getFilterCategories = getFilterCategories,
       _createFilterCategory = createFilterCategory,
       _updateFilterCategory = updateFilterCategory,
       _deleteFilterCategory = deleteFilterCategory,
       _reorderFilterCategories = reorderFilterCategories,
       _assignFiltersToCategory = assignFiltersToCategory,
       _getEffects = getEffects,
       _createEffect = createEffect,
       _updateEffect = updateEffect,
       _deleteEffect = deleteEffect,
       _bulkEffects = bulkEffects,
       _activateEffect = activateEffect,
       _deactivateEffect = deactivateEffect,
       _getEffectCategories = getEffectCategories,
       _createEffectCategory = createEffectCategory,
       _updateEffectCategory = updateEffectCategory,
       _deleteEffectCategory = deleteEffectCategory,
       _reorderEffectCategories = reorderEffectCategories,
       _assignEffectsToCategory = assignEffectsToCategory,
       _publishCatalog = publishCatalog,
       _seedCatalog = seedCatalog,
       super(FiltersEffectsInitial()) {
    on<LoadFiltersEffects>(_onLoadAll);
    on<LoadFiltersEffectsOverview>(_onLoadOverview);
    on<LoadFiltersEffectsCatalog>(_onLoadCatalog);
    on<LoadCameraFilters>(_onLoadFilters);
    on<RefreshFilters>((event, emit) => _onLoadAll(const LoadFiltersEffects(), emit));
    on<SearchFilters>((event, emit) => _onSearchChanged(FiltersEffectsSearchChanged(event.query), emit));
    on<FilterByCategory>((event, emit) {
      _query = _query.copyWith(category: event.categorySlug, clearCategory: event.categorySlug == null);
      add(const LoadCameraFilters());
    });
    on<FilterByCategoryId>((event, emit) {
      _query = _query.copyWith(categoryId: event.categoryId, clearCategoryId: event.categoryId == null);
      add(const LoadCameraFilters());
    });
    on<FilterByStatus>((event, emit) {
      _query = _query.copyWith(status: event.status);
      add(const LoadCameraFilters());
    });
    on<LoadSingleFilter>((event, emit) => _onLoadSingleFilter(event.id, emit));
    on<BulkUpdateFilters>(_onBulkUpdateFilters);
    on<BulkActionFilters>(_onBulkActionFilters);
    on<LoadCameraFilterCategories>(_onLoadFilterCategories);
    on<LoadCameraEffects>(_onLoadEffects);
    on<LoadCameraEffectCategories>(_onLoadEffectCategories);
    on<FiltersEffectsTabChanged>(_onTabChanged);
    on<FiltersEffectsSearchChanged>(_onSearchChanged);
    on<FiltersEffectsFilterChanged>(_onFilterChanged);
    on<CreateCameraFilterEvent>(_onCreateFilter);
    on<UpdateCameraFilterEvent>(_onUpdateFilter);
    on<DeleteCameraFilterEvent>(_onDeleteFilter);
    on<ActivateCameraFilterEvent>(_onActivateFilter);
    on<DeactivateCameraFilterEvent>(_onDeactivateFilter);
    on<CreateCameraFilterCategoryEvent>(_onCreateFilterCategory);
    on<UpdateCameraFilterCategoryEvent>(_onUpdateFilterCategory);
    on<DeleteCameraFilterCategoryEvent>(_onDeleteFilterCategory);
    on<ReorderCameraFilterCategoriesEvent>(_onReorderFilterCategories);
    on<AssignFiltersToCategoryEvent>(_onAssignFilters);
    on<CreateCameraEffectEvent>(_onCreateEffect);
    on<UpdateCameraEffectEvent>(_onUpdateEffect);
    on<DeleteCameraEffectEvent>(_onDeleteEffect);
    on<ActivateCameraEffectEvent>(_onActivateEffect);
    on<DeactivateCameraEffectEvent>(_onDeactivateEffect);
    on<CreateCameraEffectCategoryEvent>(_onCreateEffectCategory);
    on<UpdateCameraEffectCategoryEvent>(_onUpdateEffectCategory);
    on<DeleteCameraEffectCategoryEvent>(_onDeleteEffectCategory);
    on<ReorderCameraEffectCategoriesEvent>(_onReorderEffectCategories);
    on<AssignEffectsToCategoryEvent>(_onAssignEffects);
    on<PublishFiltersEffectsCatalogEvent>(_onPublishCatalog);
    on<SeedFiltersEffectsCatalogEvent>(_onSeedCatalog);
    on<ClearFiltersEffectsMessage>(_onClearMessage);
    on<ToggleFilterSelectionEvent>(_onToggleFilterSelection);
    on<ToggleEffectSelectionEvent>(_onToggleEffectSelection);
    on<SelectAllVisibleFiltersEvent>(_onSelectAllVisibleFilters);
    on<SelectAllVisibleEffectsEvent>(_onSelectAllVisibleEffects);
    on<ClearFilterSelectionEvent>(_onClearFilterSelection);
    on<ClearEffectSelectionEvent>(_onClearEffectSelection);
    on<BulkDeleteSelectedFiltersEvent>(_onBulkDeleteSelectedFilters);
    on<BulkDeleteSelectedEffectsEvent>(_onBulkDeleteSelectedEffects);
  }

  final GetFiltersEffectsOverviewUseCase _getOverview;
  final GetFiltersEffectsCatalogUseCase _getCatalog;
  final GetCameraFiltersUseCase _getFilters;
  final CreateCameraFilterUseCase _createFilter;
  final UpdateCameraFilterUseCase _updateFilter;
  final DeleteCameraFilterUseCase _deleteFilter;
  final BulkCameraFiltersUseCase _bulkFilters;
  final BulkUpdateCameraFiltersUseCase? _bulkUpdateFilters;
  final ActivateCameraFilterUseCase _activateFilter;
  final DeactivateCameraFilterUseCase _deactivateFilter;
  final GetCameraFilterCategoriesUseCase _getFilterCategories;
  final CreateCameraFilterCategoryUseCase _createFilterCategory;
  final UpdateCameraFilterCategoryUseCase _updateFilterCategory;
  final DeleteCameraFilterCategoryUseCase _deleteFilterCategory;
  final ReorderCameraFilterCategoriesUseCase _reorderFilterCategories;
  final AssignFiltersToCategoryUseCase _assignFiltersToCategory;
  final GetCameraEffectsUseCase _getEffects;
  final CreateCameraEffectUseCase _createEffect;
  final UpdateCameraEffectUseCase _updateEffect;
  final DeleteCameraEffectUseCase _deleteEffect;
  final BulkCameraEffectsUseCase _bulkEffects;
  final ActivateCameraEffectUseCase _activateEffect;
  final DeactivateCameraEffectUseCase _deactivateEffect;
  final GetCameraEffectCategoriesUseCase _getEffectCategories;
  final CreateCameraEffectCategoryUseCase _createEffectCategory;
  final UpdateCameraEffectCategoryUseCase _updateEffectCategory;
  final DeleteCameraEffectCategoryUseCase _deleteEffectCategory;
  final ReorderCameraEffectCategoriesUseCase _reorderEffectCategories;
  final AssignEffectsToCategoryUseCase _assignEffectsToCategory;
  final PublishFiltersEffectsCatalogUseCase _publishCatalog;
  final SeedFiltersEffectsCatalogUseCase _seedCatalog;

  FiltersEffectsListQuery _query = const FiltersEffectsListQuery();
  FiltersEffectsTab _activeTab = FiltersEffectsTab.filters;

  static const _pickerQuery = FiltersEffectsListQuery(page: 1, pageSize: 100);

  FiltersEffectsLoaded? _currentLoaded() =>
      state is FiltersEffectsLoaded ? state as FiltersEffectsLoaded : null;

  Future<
    ({
      PaginatedCameraFiltersEntity page,
      PaginatedCameraEffectsEntity effectsPage,
      List<CameraFilterEntity> pickerFilters,
      List<CameraEffectEntity> pickerEffects,
    })
  >
  _fetchListData() async {
    final filtersPage = await _getFilters(_query);
    final effectsPage = await _getEffects(_query);
    final pickerFilters = await _getFilters(_pickerQuery);
    final pickerEffects = await _getEffects(_pickerQuery);
    return (
      page: filtersPage,
      effectsPage: effectsPage,
      pickerFilters: pickerFilters.data,
      pickerEffects: pickerEffects.data,
    );
  }

  Future<void> _onLoadAll(
    LoadFiltersEffects event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    emit(FiltersEffectsLoading());
    try {
      final overview = await _getOverview();
      final catalog = await _getCatalog();
      final listData = await _fetchListData();
      final filterCategories = await _getFilterCategories();
      final effectCategories = await _getEffectCategories();

      emit(
        FiltersEffectsLoaded(
          overview: overview,
          catalog: catalog,
          filters: listData.page.data,
          filtersMeta: listData.page.meta,
          filterCategories: filterCategories,
          effects: listData.effectsPage.data,
          effectsMeta: listData.effectsPage.meta,
          effectCategories: effectCategories,
          allFiltersForPicker: listData.pickerFilters,
          allEffectsForPicker: listData.pickerEffects,
          query: _query,
          activeTab: _activeTab,
        ),
      );
    } catch (e) {
      emit(FiltersEffectsError(e.toString()));
    }
  }

  Future<void> _reloadCore(Emitter<FiltersEffectsState> emit) async {
    final overview = await _getOverview();
    final catalog = await _getCatalog();
    final listData = await _fetchListData();
    final filterCategories = await _getFilterCategories();
    final effectCategories = await _getEffectCategories();
    final current = _currentLoaded();
    emit(
      (current ??
              FiltersEffectsLoaded(
                overview: overview,
                catalog: catalog,
                filters: listData.page.data,
                filtersMeta: listData.page.meta,
                filterCategories: filterCategories,
                effects: listData.effectsPage.data,
                effectsMeta: listData.effectsPage.meta,
                effectCategories: effectCategories,
                allFiltersForPicker: listData.pickerFilters,
                allEffectsForPicker: listData.pickerEffects,
                query: _query,
                activeTab: _activeTab,
              ))
          .copyWith(
            overview: overview,
            catalog: catalog,
            filters: listData.page.data,
            filtersMeta: listData.page.meta,
            filterCategories: filterCategories,
            effects: listData.effectsPage.data,
            effectsMeta: listData.effectsPage.meta,
            effectCategories: effectCategories,
            allFiltersForPicker: listData.pickerFilters,
            allEffectsForPicker: listData.pickerEffects,
            isActioning: false,
            operationSuccess: true,
          ),
    );
  }

  Future<void> _onLoadOverview(
    LoadFiltersEffectsOverview event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final overview = await _getOverview();
      emit(current.copyWith(overview: overview));
    } catch (e) {
      emit(
        current.copyWith(
          message: e.toString(),
          isErrorMessage: true,
          isActioning: false,
        ),
      );
    }
  }

  Future<void> _onLoadCatalog(
    LoadFiltersEffectsCatalog event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final catalog = await _getCatalog();
      emit(current.copyWith(catalog: catalog));
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isErrorMessage: true));
    }
  }

  Future<void> _onLoadSingleFilter(
    String id,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      await _getFilters(FiltersEffectsListQuery(search: id));
      emit(current.copyWith(operationSuccess: true));
    } catch (e) {
      emit(current.copyWith(message: formatFeApiError(e), isErrorMessage: true));
    }
  }

  Future<void> _onBulkUpdateFilters(
    BulkUpdateFilters event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      if (_bulkUpdateFilters != null) {
        await _bulkUpdateFilters(event.request);
      }
      await _reloadCore(emit);
      final updated = _currentLoaded();
      if (updated != null) {
        emit(
          updated.copyWith(
            selectedFilterIds: const {},
            message: 'feBulkUpdateSuccess',
            isErrorMessage: false,
            operationSuccess: true,
          ),
        );
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isActioning: false,
            message: formatFeApiError(e),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _onBulkActionFilters(
    BulkActionFilters event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(
      isActioning: true,
      isBulkDeleting: event.request.action == FiltersEffectsBulkAction.delete,
      clearMessage: true,
    ));
    try {
      await _bulkFilters(event.request);
      await _reloadCore(emit);
      final updated = _currentLoaded();
      if (updated != null) {
        emit(
          updated.copyWith(
            selectedFilterIds: const {},
            isBulkDeleting: false,
            message: 'feBulkActionSuccess',
            isErrorMessage: false,
            operationSuccess: true,
          ),
        );
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isActioning: false,
            isBulkDeleting: false,
            message: formatFeApiError(e),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _onLoadFilters(
    LoadCameraFilters event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final page = await _getFilters(_query);
      final picker = await _getFilters(_pickerQuery);
      emit(
        current.copyWith(
          filters: page.data,
          filtersMeta: page.meta,
          allFiltersForPicker: picker.data,
        ),
      );
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isErrorMessage: true));
    }
  }

  Future<void> _onLoadFilterCategories(
    LoadCameraFilterCategories event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final categories = await _getFilterCategories();
      emit(current.copyWith(filterCategories: categories));
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isErrorMessage: true));
    }
  }

  Future<void> _onLoadEffects(
    LoadCameraEffects event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final page = await _getEffects(_query);
      final picker = await _getEffects(_pickerQuery);
      emit(
        current.copyWith(
          effects: page.data,
          effectsMeta: page.meta,
          allEffectsForPicker: picker.data,
        ),
      );
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isErrorMessage: true));
    }
  }

  Future<void> _onLoadEffectCategories(
    LoadCameraEffectCategories event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final categories = await _getEffectCategories();
      emit(current.copyWith(effectCategories: categories));
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isErrorMessage: true));
    }
  }

  void _onTabChanged(
    FiltersEffectsTabChanged event,
    Emitter<FiltersEffectsState> emit,
  ) {
    _activeTab = event.tab;
    final current = _currentLoaded();
    if (current == null) return;
    emit(
      current.copyWith(
        activeTab: event.tab,
        query: _query.copyWith(page: 1),
        clearFilterSelection: true,
        clearEffectSelection: true,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onSearchChanged(
    FiltersEffectsSearchChanged event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    _query = _query.copyWith(search: event.search, page: 1);
    final current = _currentLoaded();
    if (current == null) return;
    emit(
      current.copyWith(
        query: _query,
        clearFilterSelection: true,
        clearEffectSelection: true,
      ),
    );
    await _refetchLists(emit);
  }

  Future<void> _onFilterChanged(
    FiltersEffectsFilterChanged event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    _query = _query.copyWith(
      status: event.status,
      renderType: event.renderType,
      clearRenderType: event.clearRenderType,
      page: event.page ?? 1,
    );
    final current = _currentLoaded();
    if (current == null) return;
    emit(
      current.copyWith(
        query: _query,
        clearFilterSelection: event.page == null,
        clearEffectSelection: event.page == null,
      ),
    );
    await _refetchLists(emit);
  }

  Future<void> _refetchLists(Emitter<FiltersEffectsState> emit) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final page = await _getFilters(_query);
      final effectsPage = await _getEffects(_query);
      emit(
        current.copyWith(
          query: _query,
          filters: page.data,
          filtersMeta: page.meta,
          effects: effectsPage.data,
          effectsMeta: effectsPage.meta,
        ),
      );
    } catch (e) {
      emit(current.copyWith(message: e.toString(), isErrorMessage: true));
    }
  }

  void _onToggleFilterSelection(
    ToggleFilterSelectionEvent event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null || current.isBulkDeleting) return;
    final next = Set<String>.from(current.selectedFilterIds);
    if (next.contains(event.filterId)) {
      next.remove(event.filterId);
    } else {
      next.add(event.filterId);
    }
    emit(current.copyWith(selectedFilterIds: next, clearMessage: true));
  }

  void _onToggleEffectSelection(
    ToggleEffectSelectionEvent event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null || current.isBulkDeleting) return;
    final next = Set<String>.from(current.selectedEffectIds);
    if (next.contains(event.effectId)) {
      next.remove(event.effectId);
    } else {
      next.add(event.effectId);
    }
    emit(current.copyWith(selectedEffectIds: next, clearMessage: true));
  }

  void _onSelectAllVisibleFilters(
    SelectAllVisibleFiltersEvent event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null || current.isBulkDeleting) return;
    final visibleIds = current.filteredFilters.map((f) => f.id).toSet();
    if (current.allVisibleFiltersSelected) {
      emit(
        current.copyWith(
          selectedFilterIds: current.selectedFilterIds.difference(visibleIds),
          clearMessage: true,
        ),
      );
      return;
    }
    emit(
      current.copyWith(
        selectedFilterIds: {...current.selectedFilterIds, ...visibleIds},
        clearMessage: true,
      ),
    );
  }

  void _onSelectAllVisibleEffects(
    SelectAllVisibleEffectsEvent event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null || current.isBulkDeleting) return;
    final visibleIds = current.filteredEffects.map((e) => e.id).toSet();
    if (current.allVisibleEffectsSelected) {
      emit(
        current.copyWith(
          selectedEffectIds: current.selectedEffectIds.difference(visibleIds),
          clearMessage: true,
        ),
      );
      return;
    }
    emit(
      current.copyWith(
        selectedEffectIds: {...current.selectedEffectIds, ...visibleIds},
        clearMessage: true,
      ),
    );
  }

  void _onClearFilterSelection(
    ClearFilterSelectionEvent event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null || !current.hasFilterSelection) return;
    emit(current.copyWith(clearFilterSelection: true, clearMessage: true));
  }

  void _onClearEffectSelection(
    ClearEffectSelectionEvent event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null || !current.hasEffectSelection) return;
    emit(current.copyWith(clearEffectSelection: true, clearMessage: true));
  }

  Future<void> _onBulkDeleteSelectedFilters(
    BulkDeleteSelectedFiltersEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _bulkDeleteItems(
    emit,
    ids: _currentLoaded()?.selectedFilterIds ?? const {},
    isFilter: true,
    successKey: 'feFiltersBulkDeletedSuccess',
  );

  Future<void> _onBulkDeleteSelectedEffects(
    BulkDeleteSelectedEffectsEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _bulkDeleteItems(
    emit,
    ids: _currentLoaded()?.selectedEffectIds ?? const {},
    isFilter: false,
    successKey: 'feEffectsBulkDeletedSuccess',
  );

  Future<void> _bulkDeleteItems(
    Emitter<FiltersEffectsState> emit, {
    required Set<String> ids,
    required String successKey,
    required bool isFilter,
  }) async {
    final current = _currentLoaded();
    if (current == null || ids.isEmpty) return;

    emit(current.copyWith(isBulkDeleting: true, clearMessage: true));

    final targetIds = ids.toList(growable: false);
    String? lastError;
    BulkCameraFiltersResult? filterResult;
    BulkCameraEffectsResult? effectResult;

    try {
      if (isFilter) {
        filterResult = await _bulkFilters(
          BulkCameraFiltersRequest(
            filterIds: targetIds,
            action: FiltersEffectsBulkAction.delete,
          ),
        );
      } else {
        effectResult = await _bulkEffects(
          BulkCameraEffectsRequest(
            effectIds: targetIds,
            action: FiltersEffectsBulkAction.delete,
          ),
        );
      }
    } catch (e) {
      lastError = formatFeApiError(e);
    }

    try {
      await _reloadCore(emit);
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isBulkDeleting: false,
            message: formatFeApiError(e),
            isErrorMessage: true,
          ),
        );
      }
      return;
    }

    final after = _currentLoaded();
    if (after == null) return;

    final succeeded = isFilter
        ? filterResult?.successCount ?? 0
        : effectResult?.successCount ?? 0;
    final failed = isFilter
        ? (filterResult?.notFoundCount ?? targetIds.length)
        : (effectResult?.notFoundCount ?? targetIds.length);
    final succeededIds = isFilter
        ? (filterResult?.filterIds ?? const [])
        : (effectResult?.effectIds ?? const []);

    final remainingFilterIds = Set<String>.from(after.selectedFilterIds)
      ..removeAll(succeededIds);
    final remainingEffectIds = Set<String>.from(after.selectedEffectIds)
      ..removeAll(succeededIds);

    String message;
    Map<String, String>? messageParams;
    var isError = false;

    if (lastError != null) {
      message = lastError;
      isError = true;
    } else if (failed == 0) {
      message = successKey;
      messageParams = {'count': '$succeeded'};
    } else if (succeeded == 0) {
      message = 'feBulkDeleteFailed';
      isError = true;
    } else {
      message = 'feBulkDeletePartialSuccess';
      messageParams = {'success': '$succeeded', 'failed': '$failed'};
      isError = true;
    }

    emit(
      after.copyWith(
        isBulkDeleting: false,
        selectedFilterIds: isFilter
            ? remainingFilterIds
            : after.selectedFilterIds,
        selectedEffectIds: isFilter
            ? after.selectedEffectIds
            : remainingEffectIds,
        message: message,
        messageParams: messageParams,
        isErrorMessage: isError,
        operationSuccess: lastError == null && failed == 0,
      ),
    );
  }

  Future<void> _runAction(
    Emitter<FiltersEffectsState> emit,
    Future<void> Function() action, {
    String? successMessage,
    String conflictKey = 'feSlugAlreadyExists',
  }) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await action();
      await _reloadCore(emit);
      final updated = _currentLoaded();
      if (updated != null) {
        emit(
          updated.copyWith(
            message: successMessage ?? 'feActionSuccess',
            isErrorMessage: false,
            operationSuccess: true,
          ),
        );
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isActioning: false,
            message: formatFeApiError(e, conflictKey: conflictKey),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _onCreateFilter(
    CreateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _createFilter(event.request),
    successMessage: 'feFilterCreatedSuccess',
  );

  Future<void> _onUpdateFilter(
    UpdateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      final updatedFilter = await _updateFilter(event.id, event.request);
      await _reloadCore(emit);
      final after = _currentLoaded();
      if (after != null) {
        final filters = after.filters
            .map((f) => f.id == updatedFilter.id ? updatedFilter : f)
            .toList();
        emit(
          after.copyWith(
            filters: filters,
            message: 'feFilterUpdatedSuccess',
            isErrorMessage: false,
            operationSuccess: true,
          ),
        );
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isActioning: false,
            message: formatFeApiError(e),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _onDeleteFilter(
    DeleteCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _deleteFilter(event.id),
    successMessage: 'feFilterDeletedSuccess',
  );

  Future<void> _onActivateFilter(
    ActivateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _activateFilter(event.id),
    successMessage: 'feFilterActivatedSuccess',
  );

  Future<void> _onDeactivateFilter(
    DeactivateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _deactivateFilter(event.id),
    successMessage: 'feFilterDeactivatedSuccess',
  );

  Future<void> _onCreateFilterCategory(
    CreateCameraFilterCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _createFilterCategory(event.request),
    successMessage: 'feFilterCategoryCreatedSuccess',
  );

  Future<void> _onUpdateFilterCategory(
    UpdateCameraFilterCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _updateFilterCategory(event.id, event.request),
    successMessage: 'feFilterCategoryUpdatedSuccess',
  );

  Future<void> _onDeleteFilterCategory(
    DeleteCameraFilterCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _deleteFilterCategory(event.id),
    successMessage: 'feFilterCategoryDeletedSuccess',
  );

  Future<void> _onReorderFilterCategories(
    ReorderCameraFilterCategoriesEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _reorderFilterCategories(event.items),
    successMessage: 'feFilterCategoriesReorderedSuccess',
  );

  Future<void> _onAssignFilters(
    AssignFiltersToCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _assignFiltersToCategory(event.categoryId, event.filters),
    successMessage: 'feFiltersAssignedSuccess',
  );

  Future<void> _onCreateEffect(
    CreateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _createEffect(event.request),
    successMessage: 'feEffectCreatedSuccess',
  );

  Future<void> _onUpdateEffect(
    UpdateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      final updatedEffect = await _updateEffect(event.id, event.request);
      await _reloadCore(emit);
      final after = _currentLoaded();
      if (after != null) {
        final effects = after.effects
            .map((e) => e.id == updatedEffect.id ? updatedEffect : e)
            .toList();
        emit(
          after.copyWith(
            effects: effects,
            message: 'feEffectUpdatedSuccess',
            isErrorMessage: false,
            operationSuccess: true,
          ),
        );
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isActioning: false,
            message: formatFeApiError(e),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  Future<void> _onDeleteEffect(
    DeleteCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _deleteEffect(event.id),
    successMessage: 'feEffectDeletedSuccess',
  );

  Future<void> _onActivateEffect(
    ActivateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _activateEffect(event.id),
    successMessage: 'feEffectActivatedSuccess',
  );

  Future<void> _onDeactivateEffect(
    DeactivateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _deactivateEffect(event.id),
    successMessage: 'feEffectDeactivatedSuccess',
  );

  Future<void> _onCreateEffectCategory(
    CreateCameraEffectCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _createEffectCategory(event.request),
    successMessage: 'feEffectCategoryCreatedSuccess',
  );

  Future<void> _onUpdateEffectCategory(
    UpdateCameraEffectCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _updateEffectCategory(event.id, event.request),
    successMessage: 'feEffectCategoryUpdatedSuccess',
  );

  Future<void> _onDeleteEffectCategory(
    DeleteCameraEffectCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _deleteEffectCategory(event.id),
    successMessage: 'feEffectCategoryDeletedSuccess',
  );

  Future<void> _onReorderEffectCategories(
    ReorderCameraEffectCategoriesEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _reorderEffectCategories(event.items),
    successMessage: 'feEffectCategoriesReorderedSuccess',
  );

  Future<void> _onAssignEffects(
    AssignEffectsToCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) => _runAction(
    emit,
    () => _assignEffectsToCategory(event.categoryId, event.effects),
    successMessage: 'feEffectsAssignedSuccess',
  );

  Future<void> _onPublishCatalog(
    PublishFiltersEffectsCatalogEvent event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    await _runAction(
      emit,
      () => _publishCatalog(event.request),
      successMessage: 'feCatalogPublishedSuccess',
      conflictKey: 'feVersionAlreadyPublished',
    );
    add(const LoadFiltersEffectsOverview());
  }

  Future<void> _onSeedCatalog(
    SeedFiltersEffectsCatalogEvent event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      final result = await _seedCatalog();
      await _reloadCore(emit);
      final updated = _currentLoaded();
      if (updated != null) {
        emit(
          updated.copyWith(
            message:
                (result.message != null && result.message!.trim().isNotEmpty)
                ? result.message
                : 'feCatalogSeededSuccess',
            isErrorMessage: false,
            operationSuccess: true,
          ),
        );
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(
          after.copyWith(
            isActioning: false,
            message: formatFeApiError(e),
            isErrorMessage: true,
          ),
        );
      }
    }
  }

  void _onClearMessage(
    ClearFiltersEffectsMessage event,
    Emitter<FiltersEffectsState> emit,
  ) {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(clearMessage: true, operationSuccess: false));
  }
}
