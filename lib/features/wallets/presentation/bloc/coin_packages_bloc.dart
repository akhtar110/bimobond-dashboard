import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet_entities.dart';
import '../../domain/usecases/wallet_usecases.dart';

abstract class CoinPackagesEvent {}

class LoadCoinPackagesEvent extends CoinPackagesEvent {}

class CreateCoinPackageEvent extends CoinPackagesEvent {
  CreateCoinPackageEvent(this.data);
  final CreateCoinPackageData data;
}

class UpdateCoinPackageEvent extends CoinPackagesEvent {
  UpdateCoinPackageEvent(this.packageId, this.data);
  final String packageId;
  final UpdateCoinPackageData data;
}

class DeleteCoinPackageEvent extends CoinPackagesEvent {
  DeleteCoinPackageEvent(this.packageId);
  final String packageId;
}

abstract class CoinPackagesState {}

class CoinPackagesInitial extends CoinPackagesState {}

class CoinPackagesLoading extends CoinPackagesState {}

class CoinPackagesLoaded extends CoinPackagesState {
  CoinPackagesLoaded({
    required this.packages,
    this.isSaving = false,
    this.isRefreshing = false,
    this.message,
    this.isError = false,
  });

  final List<CoinPackageEntity> packages;
  final bool isSaving;
  final bool isRefreshing;
  final String? message;
  final bool isError;

  CoinPackagesLoaded copyWith({
    List<CoinPackageEntity>? packages,
    bool? isSaving,
    bool? isRefreshing,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return CoinPackagesLoaded(
      packages: packages ?? this.packages,
      isSaving: isSaving ?? this.isSaving,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }
}

class CoinPackagesError extends CoinPackagesState {
  CoinPackagesError(this.message);
  final String message;
}

class CoinPackagesBloc extends Bloc<CoinPackagesEvent, CoinPackagesState> {
  CoinPackagesBloc({
    required GetCoinPackagesUseCase getPackages,
    required CreateCoinPackageUseCase createPackage,
    required UpdateCoinPackageUseCase updatePackage,
    required DeleteCoinPackageUseCase deletePackage,
  })  : _getPackages = getPackages,
        _createPackage = createPackage,
        _updatePackage = updatePackage,
        _deletePackage = deletePackage,
        super(CoinPackagesInitial()) {
    on<LoadCoinPackagesEvent>(_onLoad);
    on<CreateCoinPackageEvent>(_onCreate);
    on<UpdateCoinPackageEvent>(_onUpdate);
    on<DeleteCoinPackageEvent>(_onDelete);
  }

  final GetCoinPackagesUseCase _getPackages;
  final CreateCoinPackageUseCase _createPackage;
  final UpdateCoinPackageUseCase _updatePackage;
  final DeleteCoinPackageUseCase _deletePackage;

  Future<void> _onLoad(
    LoadCoinPackagesEvent event,
    Emitter<CoinPackagesState> emit,
  ) async {
    final current = state;
    if (current is CoinPackagesLoaded) {
      emit(current.copyWith(isRefreshing: true, clearMessage: true));
    } else {
      emit(CoinPackagesLoading());
    }

    try {
      final packages = await _getPackages();
      emit(CoinPackagesLoaded(packages: packages));
    } catch (e) {
      emit(CoinPackagesError(e.toString()));
    }
  }

  Future<void> _mutate(
    Emitter<CoinPackagesState> emit,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    final current = state;
    if (current is! CoinPackagesLoaded) return;

    emit(current.copyWith(isSaving: true, clearMessage: true));
    try {
      await action();
      final packages = await _getPackages();
      emit(CoinPackagesLoaded(
        packages: packages,
        message: successMessage,
      ));
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onCreate(
    CreateCoinPackageEvent event,
    Emitter<CoinPackagesState> emit,
  ) =>
      _mutate(
        emit,
        () => _createPackage(event.data),
        successMessage: 'Package created',
      );

  Future<void> _onUpdate(
    UpdateCoinPackageEvent event,
    Emitter<CoinPackagesState> emit,
  ) =>
      _mutate(
        emit,
        () => _updatePackage(event.packageId, event.data),
        successMessage: 'Package updated',
      );

  Future<void> _onDelete(
    DeleteCoinPackageEvent event,
    Emitter<CoinPackagesState> emit,
  ) =>
      _mutate(
        emit,
        () => _deletePackage(event.packageId),
        successMessage: 'Package deleted',
      );
}
