import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/categories_admin_list_query.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_filters.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_all_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../../../core/localization/l10n_message.dart';
import '../models/category_ui_state.dart';

export '../../domain/entities/category_filters.dart';
export '../models/category_ui_state.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class CategoriesEvent {}

class LoadCategoriesEvent extends CategoriesEvent {
  LoadCategoriesEvent({this.forCatalog = false});
  final bool forCatalog;
}

class ChangeCategoryFilterEvent extends CategoriesEvent {
  ChangeCategoryFilterEvent(this.filter);
  final CategoryFilter filter;
}

class UpdateCategorySearchEvent extends CategoriesEvent {
  UpdateCategorySearchEvent(this.query);
  final String query;
}

class UpdateCategoryTypeFilterEvent extends CategoriesEvent {
  UpdateCategoryTypeFilterEvent(this.typeFilter);
  final CategoryTypeFilter typeFilter;
}

class CreateCategoryEvent extends CategoriesEvent {
  CreateCategoryEvent(this.data);
  final CreateCategoryData data;
}

class UpdateCategoryEvent extends CategoriesEvent {
  UpdateCategoryEvent({required this.id, required this.data});
  final String id;
  final UpdateCategoryData data;
}

class DeleteCategoryEvent extends CategoriesEvent {
  DeleteCategoryEvent(this.id);
  final String id;
}

// ── Tree / selection (presentation-only) ─────────────────────────────────────

class ToggleCategoryExpandEvent extends CategoriesEvent {
  ToggleCategoryExpandEvent(this.categoryId);
  final String categoryId;
}

class FocusRootCategoryEvent extends CategoriesEvent {
  FocusRootCategoryEvent(this.rootId);
  final String rootId;
}

class ClearFocusedRootEvent extends CategoriesEvent {}

class ToggleCategorySelectionEvent extends CategoriesEvent {
  ToggleCategorySelectionEvent(this.categoryId);
  final String categoryId;
}

class SelectAllVisibleCategoriesEvent extends CategoriesEvent {
  SelectAllVisibleCategoriesEvent({this.toggle = true});

  /// When false (toolbar "Select all" link), only adds visible ids.
  final bool toggle;
}

class ClearCategorySelectionEvent extends CategoriesEvent {}

class UpdateCategorySortEvent extends CategoriesEvent {
  UpdateCategorySortEvent(this.sort);
  final CategorySortOption sort;
}

class UpdateCategoryHasChildrenFilterEvent extends CategoriesEvent {
  UpdateCategoryHasChildrenFilterEvent(this.filter);
  final CategoryHasChildrenFilter filter;
}

class BulkActivateCategoriesEvent extends CategoriesEvent {
  BulkActivateCategoriesEvent(this.ids);
  final List<String> ids;
}

class BulkDeactivateCategoriesEvent extends CategoriesEvent {
  BulkDeactivateCategoriesEvent(this.ids);
  final List<String> ids;
}

class BulkDeleteCategoriesEvent extends CategoriesEvent {
  BulkDeleteCategoriesEvent(this.ids);
  final List<String> ids;
}

class BulkMoveCategoriesEvent extends CategoriesEvent {
  BulkMoveCategoriesEvent({required this.ids, required this.parentId});
  final List<String> ids;
  final String? parentId;
}

class _RefetchCategoriesEvent extends CategoriesEvent {
  _RefetchCategoriesEvent(this.state);
  final CategoriesLoaded state;
}

// ─── Filter result cache ──────────────────────────────────────────────────────

class _CategoryFilterCache {
  const _CategoryFilterCache({
    required this.filteredRoots,
    required this.visibleChildren,
    required this.autoExpandRootIds,
    required this.highlightedIds,
    required this.displayedCount,
  });

  final List<CategoryEntity> filteredRoots;
  final Map<String, List<CategoryEntity>> visibleChildren;
  final Set<String> autoExpandRootIds;
  final Set<String> highlightedIds;
  final int displayedCount;
}

// ─── States ───────────────────────────────────────────────────────────────────

sealed class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  CategoriesLoaded(
    this.categories, {
    List<CategoryEntity>? catalogCategories,
    this.filter = CategoryFilter.all,
    this.searchQuery = '',
    this.typeFilter = CategoryTypeFilter.all,
    this.isSubmitting = false,
    this.isFetching = false,
    this.successMessage,
    this.failureMessage,
    List<CategoryEntity>? filteredRoots,
    Map<String, List<CategoryEntity>>? visibleChildren,
    Set<String>? autoExpandRootIds,
    Set<String>? highlightedIds,
    int? displayedCount,
    Set<String>? expandedCategoryIds,
    Set<String>? selectedCategoryIds,
    this.focusedRootId,
    this.sortOption = CategorySortOption.name,
    this.hasChildrenFilter = CategoryHasChildrenFilter.all,
  })  : catalogCategories = catalogCategories ?? categories,
        filteredRoots = filteredRoots ?? const [],
        visibleChildren = visibleChildren ?? const {},
        autoExpandRootIds = autoExpandRootIds ?? const {},
        highlightedIds = highlightedIds ?? const {},
        displayedCount = displayedCount ?? categories.length,
        expandedCategoryIds = expandedCategoryIds ?? const {},
        selectedCategoryIds = selectedCategoryIds ?? const {};

  /// Server-filtered list shown on the admin page.
  final List<CategoryEntity> categories;

  /// Full unfiltered catalog for posts, create-post, and tab counts.
  final List<CategoryEntity> catalogCategories;
  final CategoryFilter filter;
  final String searchQuery;
  final CategoryTypeFilter typeFilter;
  final bool isSubmitting;
  final bool isFetching;
  final String? successMessage;
  final String? failureMessage;

  final List<CategoryEntity> filteredRoots;
  final Map<String, List<CategoryEntity>> visibleChildren;
  final Set<String> autoExpandRootIds;
  final Set<String> highlightedIds;
  final int displayedCount;

  final Set<String> expandedCategoryIds;
  final Set<String> selectedCategoryIds;
  final String? focusedRootId;
  final CategorySortOption sortOption;
  final CategoryHasChildrenFilter hasChildrenFilter;

  int get totalCount => categories.length;
  int get selectedCount => selectedCategoryIds.length;
  bool get isSelectionMode => selectedCategoryIds.isNotEmpty;

  bool isCategoryExpanded(String id) => expandedCategoryIds.contains(id);

  bool isCategorySelected(String id) => selectedCategoryIds.contains(id);

  bool isCategoryHighlighted(String id) => highlightedIds.contains(id);

  bool matchesSearch(CategoryEntity category) {
    final query = searchQuery.trim();
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    bool contains(String? value) =>
        value != null && value.toLowerCase().contains(q);

    return contains(category.name) ||
        contains(category.slug) ||
        contains(category.description) ||
        contains(category.id);
  }

  CategoryEntity? get focusedRoot {
    final id = focusedRootId;
    if (id == null) return null;
    for (final root in displayRoots) {
      if (root.id == id) return root;
    }
    for (final root in catalogRoots) {
      if (root.id == id) return root;
    }
    return null;
  }

  /// Roots shown in the left master panel (search scoped when no root focused).
  List<CategoryEntity> get leftPanelRoots {
    final roots = displayRoots;
    if (focusedRootId != null || searchQuery.trim().isEmpty) {
      return roots;
    }
    if (typeFilter == CategoryTypeFilter.subOnly) {
      return roots;
    }
    return roots.where(matchesSearch).toList();
  }

  /// Children for the right detail panel of [rootId], with status + search applied.
  List<CategoryEntity> displayChildrenFor(String rootId) {
    CategoryEntity? root;
    for (final candidate in displayRoots) {
      if (candidate.id == rootId) {
        root = candidate;
        break;
      }
    }
    root ??= catalogRoots.where((r) => r.id == rootId).firstOrNull;
    if (root == null) return const [];

    var children = subcategoriesFor(rootId, root: root);
    children = children.where((c) {
      switch (filter) {
        case CategoryFilter.all:
          return true;
        case CategoryFilter.active:
          return c.isActive;
        case CategoryFilter.inactive:
          return !c.isActive;
      }
    }).toList();

    final query = searchQuery.trim();
    if (query.isNotEmpty) {
      children = children.where(matchesSearch).toList();
    }
    return children;
  }

  int subcategoryCountFor(String rootId) {
    final fromCatalog = catalogCategories
        .where((c) => c.parentId == rootId)
        .length;
    if (fromCatalog > 0) return fromCatalog;
    return childrenOf(rootId).length;
  }

  /// Roots after client-side sort / has-children filters.
  List<CategoryEntity> get displayRoots {
    var roots = List<CategoryEntity>.from(filteredRoots);
    switch (hasChildrenFilter) {
      case CategoryHasChildrenFilter.all:
        break;
      case CategoryHasChildrenFilter.yes:
        roots = roots
            .where((r) => subcategoryCountFor(r.id) > 0)
            .toList();
      case CategoryHasChildrenFilter.no:
        roots = roots
            .where((r) => subcategoryCountFor(r.id) == 0)
            .toList();
    }
    switch (sortOption) {
      case CategorySortOption.name:
        roots.sort(_compareByOrderThenName);
      case CategorySortOption.mostSubcategories:
        roots.sort(
          (a, b) => subcategoryCountFor(b.id)
              .compareTo(subcategoryCountFor(a.id)),
        );
      case CategorySortOption.recentlyCreated:
        roots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case CategorySortOption.recentlyUpdated:
        roots.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return roots;
  }

  /// Category ids matching the current filters (roots + subs as applicable).
  List<String> get visibleSelectableIds {
    switch (typeFilter) {
      case CategoryTypeFilter.rootOnly:
        return leftPanelRoots.map((root) => root.id).toList();
      case CategoryTypeFilter.subOnly:
        final ids = <String>[];
        for (final root in leftPanelRoots) {
          ids.addAll(
            displayChildrenFor(root.id).map((category) => category.id),
          );
        }
        return ids;
      case CategoryTypeFilter.all:
        final ids = <String>[];
        for (final root in leftPanelRoots) {
          ids.add(root.id);
          ids.addAll(
            displayChildrenFor(root.id).map((category) => category.id),
          );
        }
        return ids;
    }
  }

  bool get allVisibleSelected {
    final visible = visibleSelectableIds;
    return visible.isNotEmpty &&
        visible.every(selectedCategoryIds.contains);
  }

  bool get someVisibleSelected =>
      visibleSelectableIds.any(selectedCategoryIds.contains) &&
      !allVisibleSelected;

  static int _compareByOrderThenName(CategoryEntity a, CategoryEntity b) {
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  List<CategoryEntity> get roots {
    final list = categories.where((c) => c.isRoot).toList()
      ..sort(_compareByOrderThenName);
    return list;
  }

  List<CategoryEntity> get catalogRoots {
    final list = catalogCategories.where((c) => c.isRoot).toList()
      ..sort(_compareByOrderThenName);
    return list;
  }

  List<CategoryEntity> childrenOf(String parentId) {
    final children =
        categories.where((c) => c.parentId == parentId).toList();
    children.sort(_compareByOrderThenName);
    return children;
  }

  List<CategoryEntity> visibleChildrenOf(String parentId) =>
      visibleChildren[parentId] ?? childrenOf(parentId);

  /// Resolves subcategories from the filtered list, nested children, or catalog.
  List<CategoryEntity> subcategoriesFor(String parentId, {CategoryEntity? root}) {
    final visible = visibleChildren[parentId];
    if (visible != null && visible.isNotEmpty) return visible;

    final fromList = childrenOf(parentId);
    if (fromList.isNotEmpty) return fromList;

    final nested = root?.children ?? const [];
    if (nested.isNotEmpty) {
      return nested
          .map(
            (c) => c.parentId == null ? c.copyWith(parentId: parentId) : c,
          )
          .toList()
        ..sort(_compareByOrderThenName);
    }

    final fromCatalog = catalogCategories
        .where((c) => c.parentId == parentId)
        .toList()
      ..sort(_compareByOrderThenName);
    return fromCatalog;
  }

  CategoriesLoaded copyWith({
    List<CategoryEntity>? categories,
    List<CategoryEntity>? catalogCategories,
    CategoryFilter? filter,
    String? searchQuery,
    CategoryTypeFilter? typeFilter,
    bool? isSubmitting,
    bool? isFetching,
    String? successMessage,
    String? failureMessage,
    bool clearMessages = false,
    List<CategoryEntity>? filteredRoots,
    Map<String, List<CategoryEntity>>? visibleChildren,
    Set<String>? autoExpandRootIds,
    Set<String>? highlightedIds,
    int? displayedCount,
    Set<String>? expandedCategoryIds,
    Set<String>? selectedCategoryIds,
    String? focusedRootId,
    bool clearFocusedRoot = false,
    CategorySortOption? sortOption,
    CategoryHasChildrenFilter? hasChildrenFilter,
    bool clearSelection = false,
  }) =>
      CategoriesLoaded(
        categories ?? this.categories,
        catalogCategories: catalogCategories ?? this.catalogCategories,
        filter: filter ?? this.filter,
        searchQuery: searchQuery ?? this.searchQuery,
        typeFilter: typeFilter ?? this.typeFilter,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isFetching: isFetching ?? this.isFetching,
        successMessage:
            clearMessages ? null : (successMessage ?? this.successMessage),
        failureMessage:
            clearMessages ? null : (failureMessage ?? this.failureMessage),
        filteredRoots: filteredRoots ?? this.filteredRoots,
        visibleChildren: visibleChildren ?? this.visibleChildren,
        autoExpandRootIds: autoExpandRootIds ?? this.autoExpandRootIds,
        highlightedIds: highlightedIds ?? this.highlightedIds,
        displayedCount: displayedCount ?? this.displayedCount,
        expandedCategoryIds: expandedCategoryIds ?? this.expandedCategoryIds,
        selectedCategoryIds: clearSelection
            ? const {}
            : (selectedCategoryIds ?? this.selectedCategoryIds),
        focusedRootId:
            clearFocusedRoot ? null : (focusedRootId ?? this.focusedRootId),
        sortOption: sortOption ?? this.sortOption,
        hasChildrenFilter: hasChildrenFilter ?? this.hasChildrenFilter,
      );
}

class CategoriesError extends CategoriesState {
  CategoriesError(this.message);
  final String message;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc({
    required GetAllCategories getAllCategories,
    required CreateCategory createCategory,
    required UpdateCategory updateCategory,
    required DeleteCategory deleteCategory,
  })  : _getAll = getAllCategories,
        _create = createCategory,
        _update = updateCategory,
        _delete = deleteCategory,
        super(CategoriesInitial()) {
    on<LoadCategoriesEvent>(_onLoad);
    on<_RefetchCategoriesEvent>(_onRefetch);
    on<ChangeCategoryFilterEvent>(_onChangeFilter);
    on<UpdateCategorySearchEvent>(_onUpdateSearch);
    on<UpdateCategoryTypeFilterEvent>(_onUpdateTypeFilter);
    on<CreateCategoryEvent>(_onCreate);
    on<UpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
    on<ToggleCategoryExpandEvent>(_onToggleExpand);
    on<FocusRootCategoryEvent>(_onFocusRoot);
    on<ClearFocusedRootEvent>(_onClearFocusedRoot);
    on<ToggleCategorySelectionEvent>(_onToggleSelection);
    on<SelectAllVisibleCategoriesEvent>(_onSelectAllVisible);
    on<ClearCategorySelectionEvent>(_onClearSelection);
    on<UpdateCategorySortEvent>(_onUpdateSort);
    on<UpdateCategoryHasChildrenFilterEvent>(_onUpdateHasChildrenFilter);
    on<BulkActivateCategoriesEvent>(_onBulkActivate);
    on<BulkDeactivateCategoriesEvent>(_onBulkDeactivate);
    on<BulkDeleteCategoriesEvent>(_onBulkDelete);
    on<BulkMoveCategoriesEvent>(_onBulkMove);
  }

  final GetAllCategories _getAll;
  final CreateCategory _create;
  final UpdateCategory _update;
  final DeleteCategory _delete;

  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  static const _fullCatalogQuery = CategoriesAdminListQuery(includeInactive: true);

  bool _useLocalCatalog(CategoriesLoaded state) =>
      state.searchQuery.trim().isEmpty &&
      state.filter == CategoryFilter.all &&
      state.typeFilter == CategoryTypeFilter.all;

  bool _matchesStatus(CategoryEntity category, CategoryFilter filter) {
    switch (filter) {
      case CategoryFilter.all:
        return true;
      case CategoryFilter.active:
        return category.isActive;
      case CategoryFilter.inactive:
        return !category.isActive;
    }
  }

  List<CategoryEntity> _filterByStatus(
    List<CategoryEntity> list,
    CategoryFilter filter,
  ) {
    if (filter == CategoryFilter.all) return list;
    return list.where((c) => _matchesStatus(c, filter)).toList();
  }

  List<CategoryEntity> _sorted(List<CategoryEntity> list) {
    final roots = list.where((c) => c.isRoot).toList()
      ..sort(CategoriesLoaded._compareByOrderThenName);
    final subs = list.where((c) => !c.isRoot).toList()
      ..sort(CategoriesLoaded._compareByOrderThenName);
    return [...roots, ...subs];
  }

  CategoriesLoaded _emitWithFilters(CategoriesLoaded state) {
    final cache = _applyFilters(
      categories: state.categories,
      catalogCategories: state.catalogCategories,
      statusFilter: state.filter,
      searchQuery: state.searchQuery,
      typeFilter: state.typeFilter,
    );

    var focusedRootId = state.focusedRootId;
    if (focusedRootId != null &&
        !cache.filteredRoots.any((r) => r.id == focusedRootId)) {
      focusedRootId = null;
    }

    final hasSearch = state.searchQuery.trim().isNotEmpty;
    if (hasSearch && cache.autoExpandRootIds.isNotEmpty && focusedRootId == null) {
      focusedRootId = cache.autoExpandRootIds.first;
    }

    return state.copyWith(
      filteredRoots: cache.filteredRoots,
      visibleChildren: cache.visibleChildren,
      autoExpandRootIds: cache.autoExpandRootIds,
      highlightedIds: cache.highlightedIds,
      displayedCount: cache.displayedCount,
      focusedRootId: focusedRootId,
      expandedCategoryIds: {
        ...state.expandedCategoryIds,
        ...cache.autoExpandRootIds,
        if (focusedRootId != null) focusedRootId,
      },
      clearMessages: true,
    );
  }

  bool _matchesSearch(CategoryEntity category, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    bool contains(String? value) =>
        value != null && value.toLowerCase().contains(q);

    return contains(category.name) ||
        contains(category.slug) ||
        contains(category.description) ||
        contains(category.id);
  }

  CategoriesAdminListQuery _buildQuery(CategoriesLoaded state) {
    final trimmed = state.searchQuery.trim();
    bool? isActive;
    bool? includeInactive;
    switch (state.filter) {
      case CategoryFilter.all:
        includeInactive = true;
      case CategoryFilter.active:
        isActive = true;
      case CategoryFilter.inactive:
        isActive = false;
        includeInactive = true;
    }

    bool? isMain;
    bool? flat;
    switch (state.typeFilter) {
      case CategoryTypeFilter.all:
        break;
      case CategoryTypeFilter.rootOnly:
        isMain = true;
      case CategoryTypeFilter.subOnly:
        isMain = false;
        flat = true;
    }
    if (trimmed.isNotEmpty) {
      flat ??= true;
    }

    return CategoriesAdminListQuery(
      search: trimmed.isEmpty ? null : trimmed,
      includeInactive: includeInactive,
      isActive: isActive,
      isMain: isMain,
      flat: flat,
    );
  }

  Future<void> _refetchAdmin(
    Emitter<CategoriesState> emit,
    CategoriesLoaded state,
  ) async {
    emit(state.copyWith(isFetching: true, clearMessages: true));

    try {
      var list = _useLocalCatalog(state)
          ? state.catalogCategories
          : _sorted(_flatten(await _getAll(query: _buildQuery(state))));

      if (state.typeFilter == CategoryTypeFilter.subOnly &&
          list.where((c) => !c.isRoot).isEmpty) {
        list = _filterByStatus(
          state.catalogCategories.where((c) => !c.isRoot).toList(),
          state.filter,
        );
      }

      emit(_emitWithFilters(state.copyWith(
        categories: list,
        isFetching: false,
      )));
    } catch (e) {
      emit(state.copyWith(
        isFetching: false,
        failureMessage: _msg(e),
      ));
    }
  }

  _CategoryFilterCache _applyFilters({
    required List<CategoryEntity> categories,
    required List<CategoryEntity> catalogCategories,
    required CategoryFilter statusFilter,
    required String searchQuery,
    required CategoryTypeFilter typeFilter,
  }) {
    final query = searchQuery.trim();
    final hasSearch = query.isNotEmpty;
    categories = _filterByStatus(categories, statusFilter);

    if (typeFilter == CategoryTypeFilter.subOnly) {
      return _applySubOnlyFilters(
        categories: categories,
        catalogCategories: catalogCategories,
        statusFilter: statusFilter,
        query: query,
        hasSearch: hasSearch,
      );
    }

    final serverFiltered = !_useLocalCatalog(CategoriesLoaded(
      categories,
      catalogCategories: catalogCategories,
      filter: statusFilter,
      searchQuery: searchQuery,
      typeFilter: typeFilter,
    )) &&
        searchQuery.trim().isEmpty;

    final roots = categories.where((c) => c.isRoot).toList()
      ..sort(CategoriesLoaded._compareByOrderThenName);

    final childrenByParent = <String, List<CategoryEntity>>{};
    void addChild(String parentId, CategoryEntity child) {
      final normalized = child.parentId == null
          ? child.copyWith(parentId: parentId)
          : child;
      final bucket = childrenByParent.putIfAbsent(parentId, () => []);
      if (!bucket.any((c) => c.id == normalized.id)) {
        bucket.add(normalized);
      }
    }

    for (final cat in categories) {
      if (!cat.isRoot && cat.parentId != null) {
        addChild(cat.parentId!, cat);
      }
      for (final child in cat.children) {
        addChild(cat.id, child);
      }
    }
    for (final entry in childrenByParent.entries) {
      entry.value.sort(CategoriesLoaded._compareByOrderThenName);
    }

    final filteredRoots = <CategoryEntity>[];
    final visibleChildren = <String, List<CategoryEntity>>{};
    final autoExpandRootIds = <String>{};
    final highlightedIds = <String>{};
    var displayedCount = 0;

    for (final root in roots) {
      if (!_matchesStatus(root, statusFilter)) continue;

      final allChildren = _filterByStatus(
        childrenByParent[root.id] ?? [],
        statusFilter,
      );
      final rootMatchesSearch = _matchesSearch(root, query);
      final matchingChildren =
          allChildren.where((c) => _matchesSearch(c, query)).toList();

      if (typeFilter == CategoryTypeFilter.rootOnly) {
        if (serverFiltered || !hasSearch || rootMatchesSearch) {
          filteredRoots.add(root);
          displayedCount++;
        }
        continue;
      }

      // CategoryTypeFilter.all — roots only; children load on expand (lazy UI).
      if (!hasSearch) {
        filteredRoots.add(root);
        displayedCount++;
        continue;
      }

      // Search across hierarchy (highlight + expand)
      if (rootMatchesSearch) {
        filteredRoots.add(root);
        highlightedIds.add(root.id);
        displayedCount++;
        if (allChildren.isNotEmpty) {
          visibleChildren[root.id] = allChildren;
          autoExpandRootIds.add(root.id);
          displayedCount += allChildren.length;
        }
        continue;
      }

      final visibleSubs = matchingChildren;
      if (visibleSubs.isEmpty) continue;

      filteredRoots.add(root);
      visibleChildren[root.id] = visibleSubs;
      autoExpandRootIds.add(root.id);
      displayedCount += 1 + visibleSubs.length;
      for (final sub in visibleSubs) {
        highlightedIds.add(sub.id);
      }
    }

    return _CategoryFilterCache(
      filteredRoots: filteredRoots,
      visibleChildren: visibleChildren,
      autoExpandRootIds: autoExpandRootIds,
      highlightedIds: highlightedIds,
      displayedCount: displayedCount,
    );
  }

  _CategoryFilterCache _applySubOnlyFilters({
    required List<CategoryEntity> categories,
    required List<CategoryEntity> catalogCategories,
    required CategoryFilter statusFilter,
    required String query,
    required bool hasSearch,
  }) {
    final catalogById = {
      for (final c in catalogCategories) c.id: c,
    };

    var subs = _filterByStatus(
      categories.where((c) => !c.isRoot).toList(),
      statusFilter,
    );
    if (subs.isEmpty) {
      subs = _filterByStatus(
        catalogCategories.where((c) => !c.isRoot).toList(),
        statusFilter,
      );
    }

    final grouped = <String, List<CategoryEntity>>{};
    for (final sub in subs) {
      if (hasSearch && !_matchesSearch(sub, query)) continue;
      final parentId = sub.parentId;
      if (parentId == null) continue;
      grouped.putIfAbsent(parentId, () => []).add(sub);
    }

    final filteredRoots = <CategoryEntity>[];
    final visibleChildren = <String, List<CategoryEntity>>{};
    final autoExpandRootIds = <String>{};
    final highlightedIds = <String>{};
    var displayedCount = 0;

    for (final entry in grouped.entries) {
      final parent = catalogById[entry.key];
      if (parent == null || !parent.isRoot) continue;
      if (!_matchesStatus(parent, statusFilter)) continue;

      entry.value.sort(CategoriesLoaded._compareByOrderThenName);
      filteredRoots.add(parent);
      visibleChildren[entry.key] = entry.value;
      autoExpandRootIds.add(entry.key);
      displayedCount += entry.value.length;
      if (hasSearch) {
        for (final sub in entry.value) {
          if (_matchesSearch(sub, query)) {
            highlightedIds.add(sub.id);
          }
        }
      }
    }

    filteredRoots.sort(CategoriesLoaded._compareByOrderThenName);

    return _CategoryFilterCache(
      filteredRoots: filteredRoots,
      visibleChildren: visibleChildren,
      autoExpandRootIds: autoExpandRootIds,
      highlightedIds: highlightedIds,
      displayedCount: displayedCount,
    );
  }

  void _onChangeFilter(
    ChangeCategoryFilterEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;
    await _refetchAdmin(
      emit,
      current.copyWith(filter: event.filter, clearMessages: true),
    );
  }

  void _onUpdateSearch(
    UpdateCategorySearchEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;

    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    final next = current.copyWith(
      searchQuery: event.query,
      clearMessages: true,
    );

    if (trimmed.isEmpty) {
      add(_RefetchCategoriesEvent(next));
      return;
    }

    final base = _useLocalCatalog(current)
        ? current.catalogCategories
        : current.categories;
    emit(_emitWithFilters(next.copyWith(
      categories: base,
      isFetching: trimmed.length >= 2,
    )));

    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(_RefetchCategoriesEvent(next)),
    );
  }

  Future<void> _onUpdateTypeFilter(
    UpdateCategoryTypeFilterEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;

    await _refetchAdmin(
      emit,
      current.copyWith(
        typeFilter: event.typeFilter,
        clearMessages: true,
      ),
    );
  }

  Future<void> _onRefetch(
    _RefetchCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    await _refetchAdmin(emit, event.state);
  }

  Future<void> _onLoad(
    LoadCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final existing = state;
    if (event.forCatalog) {
      if (existing is CategoriesLoaded &&
          existing.catalogCategories.isNotEmpty) {
        return;
      }
      try {
        final list = _sorted(_flatten(await _getAll(query: _fullCatalogQuery)));
        if (existing is CategoriesLoaded) {
          emit(_emitWithFilters(existing.copyWith(
            catalogCategories: list,
            categories: existing.categories.isEmpty ? list : existing.categories,
            clearMessages: true,
          )));
        } else {
          final loaded = CategoriesLoaded(list, catalogCategories: list);
          emit(_emitWithFilters(loaded));
        }
      } catch (e) {
        if (existing is! CategoriesLoaded) {
          emit(CategoriesError(_msg(e)));
        }
      }
      return;
    }

    if (existing is! CategoriesLoaded) {
      emit(CategoriesLoading());
    }

    try {
      final catalog = _sorted(_flatten(await _getAll(query: _fullCatalogQuery)));
      final loaded = CategoriesLoaded(catalog, catalogCategories: catalog);
      emit(_emitWithFilters(loaded));
    } catch (e) {
      emit(CategoriesError(_msg(e)));
    }
  }

  List<CategoryEntity> _flatten(List<CategoryEntity> list) {
    final result = <CategoryEntity>[];
    for (final cat in list) {
      result.add(cat);
      for (final child in cat.children) {
        result.add(
          child.parentId == null ? child.copyWith(parentId: cat.id) : child,
        );
      }
    }
    return result;
  }

  Future<void> _onCreate(
    CreateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;
    final list = current.categories;
    emit(current.copyWith(isSubmitting: true, clearMessages: true));
    try {
      final created = await _create(event.data);
      final updatedCatalog = _sorted([...current.catalogCategories, created]);
      emit(_emitWithFilters(current.copyWith(
        categories: _sorted([...list, created]),
        catalogCategories: updatedCatalog,
        isSubmitting: false,
        successMessage: l10nMsg('categoryCreatedSuccess', created.name),
      )));
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        failureMessage: _msg(e),
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;
    final list = current.categories;
    final existing = list.where((c) => c.id == event.id).firstOrNull;
    if (existing == null) return;

    final optimistic = _applyUpdate(existing, event.data);
    emit(_emitWithFilters(current.copyWith(
      categories: _sorted(_replaceInList(list, event.id, optimistic)),
      isSubmitting: true,
      clearMessages: true,
    )));

    try {
      final fromApi = await _update(event.id, event.data);
      final merged = _mergeAfterUpdate(existing, fromApi, event.data);
      final updatedList = _sorted(_replaceInList(list, event.id, merged));
      emit(_emitWithFilters(current.copyWith(
        categories: updatedList,
        catalogCategories: _sorted(
          _replaceInList(current.catalogCategories, event.id, merged),
        ),
        isSubmitting: false,
        successMessage: l10nMsg('categoryUpdatedSuccess', merged.name),
      )));
    } catch (e) {
      emit(_emitWithFilters(current.copyWith(
        categories: list,
        isSubmitting: false,
        failureMessage: _msg(e),
      )));
    }
  }

  Future<void> _onDelete(
    DeleteCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;
    final list = current.categories;
    final target = list.where((c) => c.id == event.id).firstOrNull;

    final optimisticList = list
        .where((c) => c.id != event.id && c.parentId != event.id)
        .toList();
    final optimisticCatalog = current.catalogCategories
        .where((c) => c.id != event.id && c.parentId != event.id)
        .toList();
    emit(_emitWithFilters(current.copyWith(
      categories: _sorted(optimisticList),
      catalogCategories: _sorted(optimisticCatalog),
      isSubmitting: true,
      clearMessages: true,
    )));

    try {
      await _delete(event.id);
      emit(_emitWithFilters(current.copyWith(
        isSubmitting: false,
        successMessage:
            l10nMsg('categoryDeletedSuccess', target?.name ?? ''),
      )));
    } catch (e) {
      emit(_emitWithFilters(current.copyWith(
        categories: list,
        isSubmitting: false,
        failureMessage: _msg(e),
      )));
    }
  }

  List<CategoryEntity> _replaceInList(
    List<CategoryEntity> list,
    String id,
    CategoryEntity replacement,
  ) =>
      [for (final c in list) if (c.id == id) replacement else c];

  CategoryEntity _applyUpdate(CategoryEntity existing, UpdateCategoryData data) {
    return CategoryEntity(
      id: existing.id,
      name: data.name ?? existing.name,
      slug: existing.slug,
      description: _descriptionAfterUpdate(existing, data),
      iconUrl: _iconUrlAfterUpdate(existing, data),
      isActive: data.isActive ?? existing.isActive,
      order: data.order ?? existing.order,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      parentId: data.setParentId ? data.parentId : existing.parentId,
    );
  }

  CategoryEntity _mergeAfterUpdate(
    CategoryEntity previous,
    CategoryEntity fromApi,
    UpdateCategoryData data,
  ) {
    return CategoryEntity(
      id: previous.id,
      name: fromApi.name.isNotEmpty ? fromApi.name : previous.name,
      slug: fromApi.slug.isNotEmpty ? fromApi.slug : previous.slug,
      description: fromApi.description ?? _descriptionAfterUpdate(previous, data),
      iconUrl: fromApi.iconUrl ?? _iconUrlAfterUpdate(previous, data),
      isActive: fromApi.isActive,
      order: fromApi.order,
      createdAt: previous.createdAt,
      updatedAt: fromApi.updatedAt,
      parentId: data.setParentId
          ? (fromApi.parentId ?? data.parentId)
          : (fromApi.parentId ?? previous.parentId),
    );
  }

  String? _descriptionAfterUpdate(
    CategoryEntity existing,
    UpdateCategoryData data,
  ) {
    if (data.name != null) return data.description;
    return existing.description;
  }

  String? _iconUrlAfterUpdate(CategoryEntity existing, UpdateCategoryData data) {
    if (data.setIconUrl) return data.iconUrl;
    return existing.iconUrl;
  }

  void _onToggleExpand(
    ToggleCategoryExpandEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    final expanded = Set<String>.from(current.expandedCategoryIds);
    if (expanded.contains(event.categoryId)) {
      expanded.remove(event.categoryId);
    } else {
      expanded.add(event.categoryId);
    }
    emit(current.copyWith(expandedCategoryIds: expanded, clearMessages: true));
  }

  void _onFocusRoot(
    FocusRootCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    if (current.focusedRootId == event.rootId) {
      emit(current.copyWith(clearFocusedRoot: true, clearMessages: true));
      return;
    }
    emit(current.copyWith(
      focusedRootId: event.rootId,
      clearMessages: true,
    ));
  }

  void _onClearFocusedRoot(
    ClearFocusedRootEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    if (current.focusedRootId == null) return;
    emit(current.copyWith(clearFocusedRoot: true, clearMessages: true));
  }

  void _onToggleSelection(
    ToggleCategorySelectionEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    final selected = Set<String>.from(current.selectedCategoryIds);
    if (selected.contains(event.categoryId)) {
      selected.remove(event.categoryId);
    } else {
      selected.add(event.categoryId);
    }
    emit(current.copyWith(selectedCategoryIds: selected, clearMessages: true));
  }

  void _onSelectAllVisible(
    SelectAllVisibleCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    final visible = current.visibleSelectableIds;
    if (visible.isEmpty) return;

    final selected = Set<String>.from(current.selectedCategoryIds);
    final visibleSet = visible.toSet();
    final allVisibleSelected = current.allVisibleSelected;

    if (event.toggle && allVisibleSelected) {
      selected.removeAll(visibleSet);
    } else {
      selected.addAll(visibleSet);
    }

    emit(current.copyWith(
      selectedCategoryIds: selected,
      clearMessages: true,
    ));
  }

  void _onClearSelection(
    ClearCategorySelectionEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    if (current.selectedCategoryIds.isEmpty) return;
    emit(current.copyWith(clearSelection: true, clearMessages: true));
  }

  void _onUpdateSort(
    UpdateCategorySortEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    emit(current.copyWith(sortOption: event.sort, clearMessages: true));
  }

  void _onUpdateHasChildrenFilter(
    UpdateCategoryHasChildrenFilterEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is! CategoriesLoaded) return;
    emit(current.copyWith(
      hasChildrenFilter: event.filter,
      clearMessages: true,
    ));
  }

  Future<void> _onBulkActivate(
    BulkActivateCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    await _bulkSetActive(event.ids, active: true, emit: emit);
  }

  Future<void> _onBulkDeactivate(
    BulkDeactivateCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    await _bulkSetActive(event.ids, active: false, emit: emit);
  }

  Future<void> _bulkSetActive(
    List<String> ids, {
    required bool active,
    required Emitter<CategoriesState> emit,
  }) async {
    final current = state;
    if (current is! CategoriesLoaded || ids.isEmpty) return;
    emit(current.copyWith(isSubmitting: true, clearMessages: true));
    var working = current;
    var failures = 0;
    for (final id in ids) {
      final existing = working.categories.where((c) => c.id == id).firstOrNull;
      if (existing == null || existing.isActive == active) continue;
      try {
        await _update(id, UpdateCategoryData(isActive: active));
        working = _emitWithFilters(working.copyWith(
          categories: _sorted(_replaceInList(
            working.categories,
            id,
            _applyUpdate(existing, UpdateCategoryData(isActive: active)),
          )),
          catalogCategories: _sorted(_replaceInList(
            working.catalogCategories,
            id,
            _applyUpdate(existing, UpdateCategoryData(isActive: active)),
          )),
        ));
      } catch (_) {
        failures++;
      }
    }
    emit(working.copyWith(
      isSubmitting: false,
      clearSelection: true,
      successMessage: failures == 0
          ? l10nMsg('categoryUpdatedSuccess', '${ids.length}')
          : null,
      failureMessage: failures > 0 ? 'Failed to update $failures categories' : null,
    ));
  }

  Future<void> _onBulkDelete(
    BulkDeleteCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded || event.ids.isEmpty) return;
    emit(current.copyWith(isSubmitting: true, clearMessages: true));
    var working = current;
    var deleted = 0;
    for (final id in event.ids) {
      try {
        await _delete(id);
        final nextList = working.categories
            .where((c) => c.id != id && c.parentId != id)
            .toList();
        final nextCatalog = working.catalogCategories
            .where((c) => c.id != id && c.parentId != id)
            .toList();
        working = _emitWithFilters(working.copyWith(
          categories: _sorted(nextList),
          catalogCategories: _sorted(nextCatalog),
        ));
        deleted++;
      } catch (_) {
        // continue with remaining
      }
    }
    emit(working.copyWith(
      isSubmitting: false,
      clearSelection: true,
      successMessage: deleted > 0
          ? l10nMsg('categoryDeletedSuccess', '$deleted')
          : null,
      failureMessage: deleted < event.ids.length
          ? 'Failed to delete ${event.ids.length - deleted} categories'
          : null,
    ));
  }

  Future<void> _onBulkMove(
    BulkMoveCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded || event.ids.isEmpty) return;
    emit(current.copyWith(isSubmitting: true, clearMessages: true));
    var working = current;
    var moved = 0;
    for (final id in event.ids) {
      final existing = working.categories.where((c) => c.id == id).firstOrNull;
      if (existing == null) continue;
      if (existing.parentId == event.parentId) continue;
      try {
        final data = UpdateCategoryData(
          parentId: event.parentId,
          setParentId: true,
        );
        final fromApi = await _update(id, data);
        final merged = _mergeAfterUpdate(existing, fromApi, data);
        working = _emitWithFilters(working.copyWith(
          categories: _sorted(
            _replaceInList(working.categories, id, merged),
          ),
          catalogCategories: _sorted(
            _replaceInList(working.catalogCategories, id, merged),
          ),
        ));
        moved++;
      } catch (_) {
        // continue
      }
    }
    emit(working.copyWith(
      isSubmitting: false,
      clearSelection: true,
      successMessage: moved > 0
          ? l10nMsg('categoryUpdatedSuccess', '$moved')
          : null,
    ));
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
