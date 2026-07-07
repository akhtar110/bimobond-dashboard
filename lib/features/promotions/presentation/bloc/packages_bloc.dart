import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/promotion_entities.dart';
import '../../domain/usecases/promotion_usecases.dart';

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

class SearchPackagesEvent extends PackagesEvent {
  SearchPackagesEvent(this.query);
  final String query;
}

class ClearPackageSearchEvent extends PackagesEvent {}

abstract class PackagesState {}

class PackagesInitial extends PackagesState {}

class PackagesLoading extends PackagesState {}

class PackagesLoaded extends PackagesState {
  PackagesLoaded({
    required this.packages,
    this.search = '',
    this.isSaving = false,
    this.isRefreshing = false,
    this.message,
    this.isError = false,
  });

  final List<PromotionPackageEntity> packages;
  final String search;
  final bool isSaving;
  final bool isRefreshing;
  final String? message;
  final bool isError;

  PackagesLoaded copyWith({
    List<PromotionPackageEntity>? packages,
    String? search,
    bool? isSaving,
    bool? isRefreshing,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return PackagesLoaded(
      packages: packages ?? this.packages,
      search: search ?? this.search,
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
  })  : _getPackages = getPackages,
        _createPackage = createPackage,
        _updatePackage = updatePackage,
        _toggleStatus = toggleStatus,
        super(PackagesInitial()) {
    on<LoadPackagesEvent>(_onLoad);
    on<CreatePackageEvent>(_onCreate);
    on<UpdatePackageEvent>(_onUpdate);
    on<TogglePackageActiveEvent>(_onToggle);
    on<SearchPackagesEvent>(_onSearch);
    on<ClearPackageSearchEvent>(_onClearSearch);
  }

  final GetPackagesUseCase _getPackages;
  final CreatePackageUseCase _createPackage;
  final UpdatePackageUseCase _updatePackage;
  final TogglePackageStatusUseCase _toggleStatus;
  Timer? _searchDebounce;
  PackagesQuery _query = const PackagesQuery();

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onLoad(LoadPackagesEvent event, Emitter<PackagesState> emit) async {
    final current = state;
    if (current is PackagesLoaded) {
      emit(current.copyWith(isRefreshing: true, clearMessage: true));
    } else if (current is! PackagesLoaded) {
      emit(PackagesLoading());
    }

    try {
      final packages = await _getPackages(query: _query);
      emit(
        PackagesLoaded(
          packages: packages,
          search: _query.search ?? '',
        ),
      );
    } catch (e) {
      if (current is PackagesLoaded) {
        emit(current.copyWith(
          isRefreshing: false,
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
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final term = event.query.trim();
      _query = _query.copyWith(
        search: term,
        clearSearch: term.isEmpty,
      );
      add(LoadPackagesEvent());
    });
  }

  void _onClearSearch(
    ClearPackageSearchEvent event,
    Emitter<PackagesState> emit,
  ) {
    _searchDebounce?.cancel();
    _query = const PackagesQuery();
    add(LoadPackagesEvent());
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
      add(LoadPackagesEvent());
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
      add(LoadPackagesEvent());
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
      add(LoadPackagesEvent());
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }
}
