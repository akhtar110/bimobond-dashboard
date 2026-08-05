import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../gifts/domain/enums/gifts_view_type.dart';
import '../../domain/entities/ar_overlay_entities.dart';
import '../../domain/usecases/ar_overlays_usecases.dart';
import 'ar_overlays_event.dart';
import 'ar_overlays_state.dart';

class ArOverlaysBloc extends Bloc<ArOverlaysEvent, ArOverlaysState> {
  ArOverlaysBloc({
    required GetAdminOverlaysUseCase getOverlays,
    required GetAdminOverlayByIdUseCase getOverlayById,
    required CreateAdminOverlayUseCase createOverlay,
    required UpdateAdminOverlayUseCase updateOverlay,
    required ActivateAdminOverlayUseCase activateOverlay,
    required DeactivateAdminOverlayUseCase deactivateOverlay,
    required DeleteAdminOverlayUseCase deleteOverlay,
  })  : _getOverlays = getOverlays,
        _getOverlayById = getOverlayById,
        _createOverlay = createOverlay,
        _updateOverlay = updateOverlay,
        _activateOverlay = activateOverlay,
        _deactivateOverlay = deactivateOverlay,
        _deleteOverlay = deleteOverlay,
        super(const ArOverlaysInitial()) {
    on<LoadArOverlaysEvent>(_onLoadOverlays);
    on<RefreshArOverlaysEvent>(_onRefreshOverlays);
    on<LoadArOverlayByIdEvent>(_onLoadOverlayById);
    on<CreateArOverlayEvent>(_onCreateOverlay);
    on<UpdateArOverlayEvent>(_onUpdateOverlay);
    on<ActivateArOverlayEvent>(_onActivateOverlay);
    on<DeactivateArOverlayEvent>(_onDeactivateOverlay);
    on<DeleteArOverlayEvent>(_onDeleteOverlay);
    on<SearchArOverlaysEvent>(_onSearchOverlays);
    on<FilterArOverlaysByStatusEvent>(_onFilterByStatus);
    on<ChangeArOverlaysPageEvent>(_onChangePage);
    on<ChangeArOverlaysViewTypeEvent>(_onChangeViewType);
    on<ClearArOverlaysMessageEvent>(_onClearMessage);
  }

  final GetAdminOverlaysUseCase _getOverlays;
  final GetAdminOverlayByIdUseCase _getOverlayById;
  final CreateAdminOverlayUseCase _createOverlay;
  final UpdateAdminOverlayUseCase _updateOverlay;
  final ActivateAdminOverlayUseCase _activateOverlay;
  final DeactivateAdminOverlayUseCase _deactivateOverlay;
  final DeleteAdminOverlayUseCase _deleteOverlay;

  int _currentPage = 1;
  int _currentLimit = 20;
  GiftsViewType _viewType = GiftsViewType.grid;
  String _searchQuery = '';
  ArOverlayStatusFilter _statusFilter = ArOverlayStatusFilter.active;

  bool? get _isActiveQuery {
    return switch (_statusFilter) {
      ArOverlayStatusFilter.active => true,
      ArOverlayStatusFilter.inactive => false,
      ArOverlayStatusFilter.all => null,
    };
  }

  Future<void> _onLoadOverlays(
    LoadArOverlaysEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    _currentPage = event.page;
    _currentLimit = event.limit;
    final curr = state;
    if (curr is! ArOverlaysLoaded) {
      emit(const ArOverlaysLoading());
    }

    try {
      final res = await _getOverlays(
        page: _currentPage,
        limit: _currentLimit,
        isActive: _isActiveQuery,
      );
      if (curr is ArOverlaysLoaded) {
        emit(curr.copyWith(
          overlays: res.data,
          meta: res.meta,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          viewType: _viewType,
          isActioning: false,
          clearMessages: true,
        ));
      } else {
        emit(ArOverlaysLoaded(
          overlays: res.data,
          meta: res.meta,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          viewType: _viewType,
        ));
      }
    } catch (e) {
      emit(ArOverlaysError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRefreshOverlays(
    RefreshArOverlaysEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    add(LoadArOverlaysEvent(page: _currentPage, limit: _currentLimit));
  }

  Future<void> _onLoadOverlayById(
    LoadArOverlayByIdEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    final curr = state;
    if (curr is! ArOverlaysLoaded) return;

    try {
      final overlay = await _getOverlayById(event.id);
      emit(curr.copyWith(selectedOverlay: overlay));
    } catch (e) {
      emit(curr.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onCreateOverlay(
    CreateArOverlayEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    final curr = state;
    if (curr is! ArOverlaysLoaded) return;

    emit(curr.copyWith(isActioning: true, clearMessages: true));
    try {
      await _createOverlay(event.data);
      final res = await _getOverlays(
        page: _currentPage,
        limit: _currentLimit,
        isActive: _isActiveQuery,
      );
      emit(curr.copyWith(
        overlays: res.data,
        meta: res.meta,
        isActioning: false,
        successMessage: 'AR Overlay created successfully',
      ));
    } catch (e) {
      emit(curr.copyWith(
        isActioning: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdateOverlay(
    UpdateArOverlayEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    final curr = state;
    if (curr is! ArOverlaysLoaded) return;

    emit(curr.copyWith(isActioning: true, clearMessages: true));
    try {
      await _updateOverlay(event.id, event.data);
      final res = await _getOverlays(
        page: _currentPage,
        limit: _currentLimit,
        isActive: _isActiveQuery,
      );
      emit(curr.copyWith(
        overlays: res.data,
        meta: res.meta,
        isActioning: false,
        successMessage: 'AR Overlay updated successfully',
      ));
    } catch (e) {
      emit(curr.copyWith(
        isActioning: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onActivateOverlay(
    ActivateArOverlayEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    await _toggleActive(
      emit,
      id: event.id,
      action: () => _activateOverlay(event.id),
      successMessage: 'AR Overlay activated successfully',
    );
  }

  Future<void> _onDeactivateOverlay(
    DeactivateArOverlayEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    await _toggleActive(
      emit,
      id: event.id,
      action: () => _deactivateOverlay(event.id),
      successMessage: 'AR Overlay deactivated successfully',
    );
  }

  Future<void> _toggleActive(
    Emitter<ArOverlaysState> emit, {
    required String id,
    required Future<ArOverlayEntity> Function() action,
    required String successMessage,
  }) async {
    final curr = state;
    if (curr is! ArOverlaysLoaded) return;

    emit(curr.copyWith(isActioning: true, clearMessages: true));
    try {
      final updated = await action();
      final existingIndex = curr.overlays.indexWhere((item) => item.id == id);
      final existing =
          existingIndex >= 0 ? curr.overlays[existingIndex] : null;
      final resolved = updated.id.trim().isNotEmpty
          ? updated
          : (existing?.copyWith(isActive: updated.isActive) ?? updated);
      final nextOverlays = curr.overlays
          .map((item) => item.id == id ? resolved : item)
          .toList(growable: false);
      emit(curr.copyWith(
        overlays: nextOverlays,
        isActioning: false,
        successMessage: successMessage,
      ));
      add(LoadArOverlaysEvent(page: _currentPage, limit: _currentLimit));
    } catch (e) {
      emit(curr.copyWith(
        isActioning: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onDeleteOverlay(
    DeleteArOverlayEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    final curr = state;
    if (curr is! ArOverlaysLoaded) return;

    emit(curr.copyWith(isActioning: true, clearMessages: true));
    try {
      await _deleteOverlay(event.id);
      final res = await _getOverlays(
        page: _currentPage,
        limit: _currentLimit,
        isActive: _isActiveQuery,
      );
      emit(curr.copyWith(
        overlays: res.data,
        meta: res.meta,
        isActioning: false,
        successMessage: 'AR Overlay deleted successfully',
      ));
    } catch (e) {
      emit(curr.copyWith(
        isActioning: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onSearchOverlays(
    SearchArOverlaysEvent event,
    Emitter<ArOverlaysState> emit,
  ) {
    _searchQuery = event.query;
    final curr = state;
    if (curr is ArOverlaysLoaded) {
      emit(curr.copyWith(searchQuery: _searchQuery, clearMessages: true));
    }
  }

  void _onFilterByStatus(
    FilterArOverlaysByStatusEvent event,
    Emitter<ArOverlaysState> emit,
  ) {
    if (_statusFilter == event.statusFilter) return;
    _statusFilter = event.statusFilter;
    _currentPage = 1;
    final curr = state;
    if (curr is ArOverlaysLoaded) {
      emit(curr.copyWith(statusFilter: _statusFilter, clearMessages: true));
    }
    add(LoadArOverlaysEvent(page: _currentPage, limit: _currentLimit));
  }

  void _onChangePage(
    ChangeArOverlaysPageEvent event,
    Emitter<ArOverlaysState> emit,
  ) {
    _currentPage = event.page;
    add(LoadArOverlaysEvent(page: _currentPage, limit: _currentLimit));
  }

  void _onChangeViewType(
    ChangeArOverlaysViewTypeEvent event,
    Emitter<ArOverlaysState> emit,
  ) {
    _viewType = event.viewType;
    final curr = state;
    if (curr is ArOverlaysLoaded) {
      emit(curr.copyWith(viewType: _viewType));
    }
  }

  void _onClearMessage(
    ClearArOverlaysMessageEvent event,
    Emitter<ArOverlaysState> emit,
  ) {
    final curr = state;
    if (curr is ArOverlaysLoaded) {
      emit(curr.copyWith(clearMessages: true));
    }
  }
}
