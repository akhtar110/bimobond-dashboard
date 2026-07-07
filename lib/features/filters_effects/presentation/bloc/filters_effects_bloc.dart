import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import 'filters_effects_event.dart';
import 'filters_effects_state.dart';

class FiltersEffectsBloc extends Bloc<FiltersEffectsEvent, FiltersEffectsState> {
  FiltersEffectsBloc({
    required GetFiltersEffectsOverviewUseCase getOverview,
    required GetFiltersEffectsCatalogUseCase getCatalog,
    required GetCameraFiltersUseCase getFilters,
    required CreateCameraFilterUseCase createFilter,
    required UpdateCameraFilterUseCase updateFilter,
    required DeleteCameraFilterUseCase deleteFilter,
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
  })  : _getOverview = getOverview,
        _getCatalog = getCatalog,
        _getFilters = getFilters,
        _createFilter = createFilter,
        _updateFilter = updateFilter,
        _deleteFilter = deleteFilter,
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
  }

  final GetFiltersEffectsOverviewUseCase _getOverview;
  final GetFiltersEffectsCatalogUseCase _getCatalog;
  final GetCameraFiltersUseCase _getFilters;
  final CreateCameraFilterUseCase _createFilter;
  final UpdateCameraFilterUseCase _updateFilter;
  final DeleteCameraFilterUseCase _deleteFilter;
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
  FiltersEffectsTab _activeTab = FiltersEffectsTab.overview;

  FiltersEffectsLoaded? _currentLoaded() =>
      state is FiltersEffectsLoaded ? state as FiltersEffectsLoaded : null;

  Future<void> _onLoadAll(
    LoadFiltersEffects event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    emit(FiltersEffectsLoading());
    try {
      final overview = await _getOverview();
      final catalog = await _getCatalog();
      final filters = await _getFilters();
      final filterCategories = await _getFilterCategories();
      final effects = await _getEffects();
      final effectCategories = await _getEffectCategories();

      emit(
        FiltersEffectsLoaded(
          overview: overview,
          catalog: catalog,
          filters: filters,
          filterCategories: filterCategories,
          effects: effects,
          effectCategories: effectCategories,
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
    final filters = await _getFilters();
    final filterCategories = await _getFilterCategories();
    final effects = await _getEffects();
    final effectCategories = await _getEffectCategories();
    final current = _currentLoaded();
    emit(
      (current ?? FiltersEffectsLoaded(
        overview: overview,
        catalog: catalog,
        filters: filters,
        filterCategories: filterCategories,
        effects: effects,
        effectCategories: effectCategories,
        query: _query,
        activeTab: _activeTab,
      )).copyWith(
        overview: overview,
        catalog: catalog,
        filters: filters,
        filterCategories: filterCategories,
        effects: effects,
        effectCategories: effectCategories,
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
      emit(current.copyWith(
        message: e.toString(),
        isErrorMessage: true,
        isActioning: false,
      ));
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
      emit(current.copyWith(
        message: e.toString(),
        isErrorMessage: true,
      ));
    }
  }

  Future<void> _onLoadFilters(
    LoadCameraFilters event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    final current = _currentLoaded();
    if (current == null) return;
    try {
      final filters = await _getFilters();
      emit(current.copyWith(filters: filters));
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
      final effects = await _getEffects();
      emit(current.copyWith(effects: effects));
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
    emit(current.copyWith(activeTab: event.tab, query: _query.copyWith(page: 1)));
  }

  void _onSearchChanged(
    FiltersEffectsSearchChanged event,
    Emitter<FiltersEffectsState> emit,
  ) {
    _query = _query.copyWith(search: event.search, page: 1);
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(query: _query));
  }

  void _onFilterChanged(
    FiltersEffectsFilterChanged event,
    Emitter<FiltersEffectsState> emit,
  ) {
    _query = _query.copyWith(
      status: event.status,
      engineKey: event.engineKey,
      clearEngineKey: event.clearEngineKey,
      page: event.page ?? 1,
    );
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(query: _query));
  }

  Future<void> _runAction(
    Emitter<FiltersEffectsState> emit,
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    final current = _currentLoaded();
    if (current == null) return;
    emit(current.copyWith(isActioning: true, clearMessage: true));
    try {
      await action();
      await _reloadCore(emit);
      final updated = _currentLoaded();
      if (updated != null && successMessage != null) {
        emit(updated.copyWith(message: successMessage, operationSuccess: true));
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(after.copyWith(
          isActioning: false,
          message: e.toString(),
          isErrorMessage: true,
        ));
      }
    }
  }

  Future<void> _onCreateFilter(
    CreateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _createFilter(event.request));

  Future<void> _onUpdateFilter(
    UpdateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _updateFilter(event.id, event.request),
      );

  Future<void> _onDeleteFilter(
    DeleteCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _deleteFilter(event.id));

  Future<void> _onActivateFilter(
    ActivateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _activateFilter(event.id));

  Future<void> _onDeactivateFilter(
    DeactivateCameraFilterEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _deactivateFilter(event.id));

  Future<void> _onCreateFilterCategory(
    CreateCameraFilterCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _createFilterCategory(event.request));

  Future<void> _onUpdateFilterCategory(
    UpdateCameraFilterCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _updateFilterCategory(event.id, event.request),
      );

  Future<void> _onDeleteFilterCategory(
    DeleteCameraFilterCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _deleteFilterCategory(event.id));

  Future<void> _onReorderFilterCategories(
    ReorderCameraFilterCategoriesEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _reorderFilterCategories(event.items),
      );

  Future<void> _onAssignFilters(
    AssignFiltersToCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _assignFiltersToCategory(event.categoryId, event.filters),
      );

  Future<void> _onCreateEffect(
    CreateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _createEffect(event.request));

  Future<void> _onUpdateEffect(
    UpdateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _updateEffect(event.id, event.request),
      );

  Future<void> _onDeleteEffect(
    DeleteCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _deleteEffect(event.id));

  Future<void> _onActivateEffect(
    ActivateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _activateEffect(event.id));

  Future<void> _onDeactivateEffect(
    DeactivateCameraEffectEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _deactivateEffect(event.id));

  Future<void> _onCreateEffectCategory(
    CreateCameraEffectCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _createEffectCategory(event.request));

  Future<void> _onUpdateEffectCategory(
    UpdateCameraEffectCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _updateEffectCategory(event.id, event.request),
      );

  Future<void> _onDeleteEffectCategory(
    DeleteCameraEffectCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(emit, () => _deleteEffectCategory(event.id));

  Future<void> _onReorderEffectCategories(
    ReorderCameraEffectCategoriesEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _reorderEffectCategories(event.items),
      );

  Future<void> _onAssignEffects(
    AssignEffectsToCategoryEvent event,
    Emitter<FiltersEffectsState> emit,
  ) =>
      _runAction(
        emit,
        () => _assignEffectsToCategory(event.categoryId, event.effects),
      );

  Future<void> _onPublishCatalog(
    PublishFiltersEffectsCatalogEvent event,
    Emitter<FiltersEffectsState> emit,
  ) async {
    await _runAction(
      emit,
      () => _publishCatalog(event.request),
      successMessage: 'feCatalogPublishedSuccess',
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
      final catalog = await _seedCatalog();
      await _reloadCore(emit);
      final updated = _currentLoaded();
      if (updated != null) {
        emit(updated.copyWith(
          catalog: catalog,
          message: 'feCatalogSeededSuccess',
          operationSuccess: true,
        ));
      }
    } catch (e) {
      final after = _currentLoaded();
      if (after != null) {
        emit(after.copyWith(
          isActioning: false,
          message: e.toString(),
          isErrorMessage: true,
        ));
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
