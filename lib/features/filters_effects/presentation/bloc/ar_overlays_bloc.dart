import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../gifts/domain/enums/gifts_view_type.dart';
import '../../domain/usecases/ar_overlays_usecases.dart';
import 'ar_overlays_event.dart';
import 'ar_overlays_state.dart';

class ArOverlaysBloc extends Bloc<ArOverlaysEvent, ArOverlaysState> {
  ArOverlaysBloc({
    required GetAdminOverlaysUseCase getOverlays,
    required GetAdminOverlayByIdUseCase getOverlayById,
    required CreateAdminOverlayUseCase createOverlay,
    required UpdateAdminOverlayUseCase updateOverlay,
    required DeleteAdminOverlayUseCase deleteOverlay,
  })  : _getOverlays = getOverlays,
        _getOverlayById = getOverlayById,
        _createOverlay = createOverlay,
        _updateOverlay = updateOverlay,
        _deleteOverlay = deleteOverlay,
        super(const ArOverlaysInitial()) {
    on<LoadArOverlaysEvent>(_onLoadOverlays);
    on<RefreshArOverlaysEvent>(_onRefreshOverlays);
    on<LoadArOverlayByIdEvent>(_onLoadOverlayById);
    on<CreateArOverlayEvent>(_onCreateOverlay);
    on<UpdateArOverlayEvent>(_onUpdateOverlay);
    on<DeleteArOverlayEvent>(_onDeleteOverlay);
    on<SearchArOverlaysEvent>(_onSearchOverlays);
    on<ChangeArOverlaysPageEvent>(_onChangePage);
    on<ChangeArOverlaysViewTypeEvent>(_onChangeViewType);
    on<ClearArOverlaysMessageEvent>(_onClearMessage);
  }

  final GetAdminOverlaysUseCase _getOverlays;
  final GetAdminOverlayByIdUseCase _getOverlayById;
  final CreateAdminOverlayUseCase _createOverlay;
  final UpdateAdminOverlayUseCase _updateOverlay;
  final DeleteAdminOverlayUseCase _deleteOverlay;

  int _currentPage = 1;
  int _currentLimit = 20;
  GiftsViewType _viewType = GiftsViewType.grid;
  String _searchQuery = '';

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
      final res = await _getOverlays(page: _currentPage, limit: _currentLimit);
      if (curr is ArOverlaysLoaded) {
        emit(curr.copyWith(
          overlays: res.data,
          meta: res.meta,
          searchQuery: _searchQuery,
          viewType: _viewType,
          isActioning: false,
          clearMessages: true,
        ));
      } else {
        emit(ArOverlaysLoaded(
          overlays: res.data,
          meta: res.meta,
          searchQuery: _searchQuery,
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
      final res = await _getOverlays(page: _currentPage, limit: _currentLimit);
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
      final res = await _getOverlays(page: _currentPage, limit: _currentLimit);
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

  Future<void> _onDeleteOverlay(
    DeleteArOverlayEvent event,
    Emitter<ArOverlaysState> emit,
  ) async {
    final curr = state;
    if (curr is! ArOverlaysLoaded) return;

    emit(curr.copyWith(isActioning: true, clearMessages: true));
    try {
      await _deleteOverlay(event.id);
      final res = await _getOverlays(page: _currentPage, limit: _currentLimit);
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
