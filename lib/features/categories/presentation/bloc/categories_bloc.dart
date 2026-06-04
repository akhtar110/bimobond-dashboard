import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_all_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../../../core/localization/l10n_message.dart';

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum CategoryFilter { all, active, inactive }

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class CategoriesEvent {}

class LoadCategoriesEvent extends CategoriesEvent {}

class ChangeCategoryFilterEvent extends CategoriesEvent {
  ChangeCategoryFilterEvent(this.filter);
  final CategoryFilter filter;
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

// ─── States ───────────────────────────────────────────────────────────────────

sealed class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

/// Primary state — carries the full flat list from the API.
///
/// The UI groups categories by [parentId]:
///   - Root categories  : `parentId == null`
///   - Subcategories    : `parentId != null`
///
/// [isSubmitting] disables dialogs while a CRUD call is in flight.
/// [successMessage] / [failureMessage] are one-shot signals for snackbars.
class CategoriesLoaded extends CategoriesState {
  CategoriesLoaded(
    this.categories, {
    this.filter = CategoryFilter.all,
    this.isSubmitting = false,
    this.successMessage,
    this.failureMessage,
  });

  /// Full flat list — both root categories and subcategories.
  final List<CategoryEntity> categories;
  final CategoryFilter filter;
  final bool isSubmitting;
  final String? successMessage;
  final String? failureMessage;

  // ── Derived helpers used by the UI ─────────────────────────────────────

  /// All root categories (unfiltered).
  List<CategoryEntity> get roots =>
      categories.where((c) => c.isRoot).toList();

  /// Root categories after applying the active [filter].
  List<CategoryEntity> get filteredRoots {
    final all = roots;
    return switch (filter) {
      CategoryFilter.all => all,
      CategoryFilter.active => all.where((c) => c.isActive).toList(),
      CategoryFilter.inactive => all.where((c) => !c.isActive).toList(),
    };
  }

  List<CategoryEntity> childrenOf(String parentId) =>
      categories.where((c) => c.parentId == parentId).toList();

  CategoriesLoaded copyWith({
    List<CategoryEntity>? categories,
    CategoryFilter? filter,
    bool? isSubmitting,
    String? successMessage,
    String? failureMessage,
    bool clearMessages = false,
  }) =>
      CategoriesLoaded(
        categories ?? this.categories,
        filter: filter ?? this.filter,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        successMessage:
            clearMessages ? null : (successMessage ?? this.successMessage),
        failureMessage:
            clearMessages ? null : (failureMessage ?? this.failureMessage),
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
    on<ChangeCategoryFilterEvent>(_onChangeFilter);
    on<CreateCategoryEvent>(_onCreate);
    on<UpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
  }

  final GetAllCategories _getAll;
  final CreateCategory _create;
  final UpdateCategory _update;
  final DeleteCategory _delete;

  // ── helpers ──────────────────────────────────────────────────────────────────

  List<CategoryEntity> _currentList() =>
      state is CategoriesLoaded ? (state as CategoriesLoaded).categories : [];

  CategoryFilter _currentFilter() =>
      state is CategoriesLoaded
          ? (state as CategoriesLoaded).filter
          : CategoryFilter.all;

  /// Sort flat list: roots first (by name), then subcategories (by name within parent).
  List<CategoryEntity> _sorted(List<CategoryEntity> list) {
    final roots = list.where((c) => c.isRoot).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final subs = list.where((c) => !c.isRoot).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...roots, ...subs];
  }

  // ── handlers ─────────────────────────────────────────────────────────────────

  void _onChangeFilter(
    ChangeCategoryFilterEvent event,
    Emitter<CategoriesState> emit,
  ) {
    if (state is CategoriesLoaded) {
      emit((state as CategoriesLoaded).copyWith(filter: event.filter));
    }
  }

  Future<void> _onLoad(
    LoadCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      final list = await _getAll();
      // The admin API returns root categories with children embedded inside
      // their `children` array. We flatten that one level so the BLoC flat
      // list contains all categories (roots + subs) with `parentId` set,
      // which lets `childrenOf()` work correctly.
      emit(CategoriesLoaded(_sorted(_flatten(list))));
    } catch (e) {
      emit(CategoriesError(_msg(e)));
    }
  }

  /// Extracts top-level items + any embedded [CategoryEntity.children] into
  /// a single flat list. Only one level of nesting is supported per the API.
  List<CategoryEntity> _flatten(List<CategoryEntity> list) {
    final result = <CategoryEntity>[];
    for (final cat in list) {
      result.add(cat);
      if (cat.children.isNotEmpty) {
        result.addAll(cat.children);
      }
    }
    return result;
  }

  Future<void> _onCreate(
    CreateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final list = _currentList();
    emit(CategoriesLoaded(list, isSubmitting: true));
    try {
      final created = await _create(event.data);
      final updated = _sorted([...list, created]);
      emit(CategoriesLoaded(
        updated,
        filter: _currentFilter(),
        successMessage: l10nMsg('categoryCreatedSuccess', created.name),
      ));
    } catch (e) {
      emit(CategoriesLoaded(list, failureMessage: _msg(e)));
    }
  }

  Future<void> _onUpdate(
    UpdateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final list = _currentList();
    emit(CategoriesLoaded(list, isSubmitting: true));
    try {
      final updated = await _update(event.id, event.data);
      final newList = _sorted([
        for (final c in list)
          if (c.id == event.id) updated else c,
      ]);
      emit(CategoriesLoaded(
        newList,
        filter: _currentFilter(),
        successMessage: l10nMsg('categoryUpdatedSuccess', updated.name),
      ));
    } catch (e) {
      emit(CategoriesLoaded(list, failureMessage: _msg(e)));
    }
  }

  Future<void> _onDelete(
    DeleteCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final list = _currentList();
    final target = list.where((c) => c.id == event.id).firstOrNull;
    emit(CategoriesLoaded(list, isSubmitting: true));
    try {
      await _delete(event.id);
      // Remove the deleted category AND any orphaned subcategories.
      final newList = list
          .where((c) => c.id != event.id && c.parentId != event.id)
          .toList();
      emit(CategoriesLoaded(
        _sorted(newList),
        filter: _currentFilter(),
        successMessage: l10nMsg('categoryDeletedSuccess', target?.name ?? ''),
      ));
    } catch (e) {
      emit(CategoriesLoaded(list, failureMessage: _msg(e)));
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}
