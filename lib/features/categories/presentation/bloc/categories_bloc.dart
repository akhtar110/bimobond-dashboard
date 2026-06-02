import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_all_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../../../core/localization/l10n_message.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class CategoriesEvent {}

class LoadCategoriesEvent extends CategoriesEvent {}

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

/// Primary state — always carries the full list.
/// [isSubmitting] is true while a CRUD call is in flight (disable dialogs).
/// [successMessage] / [failureMessage] are one-shot signals for UI feedback.
class CategoriesLoaded extends CategoriesState {
  CategoriesLoaded(
    this.categories, {
    this.isSubmitting = false,
    this.successMessage,
    this.failureMessage,
  });

  final List<CategoryEntity> categories;
  final bool isSubmitting;
  final String? successMessage;
  final String? failureMessage;

  CategoriesLoaded copyWith({
    List<CategoryEntity>? categories,
    bool? isSubmitting,
    String? successMessage,
    String? failureMessage,
    bool clearMessages = false,
  }) =>
      CategoriesLoaded(
        categories ?? this.categories,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
        failureMessage: clearMessages ? null : (failureMessage ?? this.failureMessage),
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

  // ── handlers ─────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      final list = await _getAll();
      list.sort((a, b) => a.order.compareTo(b.order));
      emit(CategoriesLoaded(list));
    } catch (e) {
      emit(CategoriesError(_msg(e)));
    }
  }

  Future<void> _onCreate(
    CreateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final list = _currentList();
    emit(CategoriesLoaded(list, isSubmitting: true));
    try {
      final created = await _create(event.data);
      final updated = [...list, created]..sort((a, b) => a.order.compareTo(b.order));
      emit(CategoriesLoaded(
        updated,
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
      final newList = [
        for (final c in list)
          if (c.id == event.id) updated else c,
      ]..sort((a, b) => a.order.compareTo(b.order));
      emit(CategoriesLoaded(
        newList,
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
      final newList = list.where((c) => c.id != event.id).toList();
      emit(CategoriesLoaded(
        newList,
        successMessage: l10nMsg(
          'categoryDeletedSuccess',
          target?.name ?? '',
        ),
      ));
    } catch (e) {
      emit(CategoriesLoaded(list, failureMessage: _msg(e)));
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}
