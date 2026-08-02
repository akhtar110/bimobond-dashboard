import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/seller_verification_entities.dart';
import '../../domain/usecases/approve_seller_verification.dart';
import '../../domain/usecases/get_seller_verification_applications.dart';
import '../../domain/usecases/reject_seller_verification.dart';

part 'seller_verification_event.dart';
part 'seller_verification_state.dart';

class SellerVerificationBloc
    extends Bloc<SellerVerificationEvent, SellerVerificationState> {
  SellerVerificationBloc({
    required GetSellerVerificationApplications getApplications,
    required ApproveSellerVerification approveApplication,
    required RejectSellerVerification rejectApplication,
  })  : _getApplications = getApplications,
        _approveApplication = approveApplication,
        _rejectApplication = rejectApplication,
        super(const SellerVerificationInitial()) {
    on<LoadSellerVerificationsEvent>(_onLoad);
    on<GoToSellerVerificationPageEvent>(_onGoToPage);
    on<LoadMoreSellerVerificationsEvent>(_onLoadMore);
    on<FilterSellerVerificationsEvent>(_onFilter);
    on<UpdateSellerVerificationSearchEvent>(_onUpdateSearch);
    on<ApproveSellerVerificationEvent>(_onApprove);
    on<RejectSellerVerificationEvent>(_onReject);
    on<ClearSellerVerificationFeedbackEvent>(_onClearFeedback);
  }

  final GetSellerVerificationApplications _getApplications;
  final ApproveSellerVerification _approveApplication;
  final RejectSellerVerification _rejectApplication;

  static const pageLimit = 20;

  Timer? _searchDebounce;
  static const _searchDebounceMs = 300;
  bool _busy = false;
  bool _pendingRefresh = false;
  int _loadToken = 0;

  String? _statusFilter;
  String _searchQuery = '';
  int _currentPage = 1;

  String get activeSearchQuery => _searchQuery;
  String? get activeStatusFilter => _statusFilter;

  AdminSellerVerificationQuery _buildQuery() => AdminSellerVerificationQuery(
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        status: _statusFilter,
      );

  Future<void> _fetchPage(
    Emitter<SellerVerificationState> emit, {
    required int page,
    bool showLoading = true,
    bool append = false,
  }) async {
    if (page < 1) return;
    // If a fetch is already running, cancel it by bumping the token and
    // then wait for _busy to clear before starting the new fetch.
    if (_busy) {
      if (!append) {
        _loadToken++; // cancel the in-flight request
        _pendingRefresh = true;
        return;
      }
      return;
    }

    _busy = true;
    final token = ++_loadToken;
    final query = _buildQuery();
    final previous = state;
    if (showLoading && previous is! SellerVerificationLoaded) {
      emit(const SellerVerificationLoading());
    } else if (previous is SellerVerificationLoaded) {
      emit(
        previous.copyWith(
          statusFilter: _statusFilter,
          clearStatusFilter: _statusFilter == null,
          isFetching: !append,
          isLoadingMore: append,
        ),
      );
    }

    try {
      final response = await _getApplications(
        page: page,
        limit: pageLimit,
        query: query,
      );

      if (token != _loadToken) return;

      _currentPage = response.currentPage;

      List<SellerVerificationApplicationEntity> applications;
      if (append && previous is SellerVerificationLoaded) {
        final existingIds = previous.applications.map((a) => a.id).toSet();
        applications = [
          ...previous.applications,
          for (final item in response.applications)
            if (!existingIds.contains(item.id)) item,
        ];
      } else {
        applications = response.applications;
      }

      emit(
        SellerVerificationLoaded(
          applications: applications,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          total: response.total,
          statusFilter: _statusFilter,
          searchQuery: _searchQuery,
          isFetching: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (token != _loadToken) return;
      if (previous is SellerVerificationLoaded) {
        emit(
          previous.copyWith(isFetching: false, isLoadingMore: false),
        );
      } else {
        emit(SellerVerificationError(e.toString()));
      }
    } finally {
      _busy = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        if (!isClosed) add(const LoadSellerVerificationsEvent(refresh: true));
      }
    }
  }

  Future<void> _onLoad(
    LoadSellerVerificationsEvent event,
    Emitter<SellerVerificationState> emit,
  ) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    final hasData = state is SellerVerificationLoaded;
    await _fetchPage(
      emit,
      page: page,
      showLoading: !hasData,
      append: false,
    );
  }

  Future<void> _onGoToPage(
    GoToSellerVerificationPageEvent event,
    Emitter<SellerVerificationState> emit,
  ) async {
    await _fetchPage(emit, page: event.page, showLoading: false, append: false);
  }

  Future<void> _onLoadMore(
    LoadMoreSellerVerificationsEvent event,
    Emitter<SellerVerificationState> emit,
  ) async {
    final current = state;
    if (current is! SellerVerificationLoaded) return;
    if (current.hasReachedMax || current.isLoadingMore || _busy) return;
    await _fetchPage(
      emit,
      page: current.currentPage + 1,
      showLoading: false,
      append: true,
    );
  }

  Future<void> _onFilter(
    FilterSellerVerificationsEvent event,
    Emitter<SellerVerificationState> emit,
  ) async {
    _statusFilter = event.status;
    // Cancel any in-progress load so the new filter takes effect immediately.
    _loadToken++;
    _busy = false;
    _pendingRefresh = false;
    await _fetchPage(emit, page: 1, showLoading: false, append: false);
  }

  void _onUpdateSearch(
    UpdateSellerVerificationSearchEvent event,
    Emitter<SellerVerificationState> emit,
  ) {
    _searchQuery = event.query;
    _searchDebounce?.cancel();

    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      _loadToken++;
      if (_busy) {
        _pendingRefresh = true;
      } else {
        add(const LoadSellerVerificationsEvent(refresh: true));
      }
      return;
    }
    if (trimmed.length < 2) return;

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () {
        if (_busy) {
          _pendingRefresh = true;
        } else {
          add(const LoadSellerVerificationsEvent(refresh: true));
        }
      },
    );
  }

  Future<void> _onApprove(
    ApproveSellerVerificationEvent event,
    Emitter<SellerVerificationState> emit,
  ) async {
    final current = state;
    if (current is! SellerVerificationLoaded) return;
    final targetId = event.applicationId.trim();
    if (targetId.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'sellerVerificationMissingId',
          feedbackIsError: true,
        ),
      );
      return;
    }
    emit(current.copyWith(isMutating: true, clearFeedback: true));
    try {
      await _approveApplication(targetId);
      await _fetchPage(emit, page: 1, showLoading: false, append: false);
      final refreshed = state;
      if (refreshed is SellerVerificationLoaded) {
        emit(
          refreshed.copyWith(
            isMutating: false,
            feedbackMessage: 'sellerVerificationApproved',
          ),
        );
      }
    } catch (e) {
      emit(
        current.copyWith(
          isMutating: false,
          feedbackMessage: _formatReviewError(e),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onReject(
    RejectSellerVerificationEvent event,
    Emitter<SellerVerificationState> emit,
  ) async {
    final current = state;
    if (current is! SellerVerificationLoaded) return;
    final targetId = event.applicationId.trim();
    if (targetId.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'sellerVerificationMissingId',
          feedbackIsError: true,
        ),
      );
      return;
    }
    emit(current.copyWith(isMutating: true, clearFeedback: true));
    try {
      await _rejectApplication(
        targetId,
        rejectionReason: event.rejectionReason,
      );
      await _fetchPage(emit, page: 1, showLoading: false, append: false);
      final refreshed = state;
      if (refreshed is SellerVerificationLoaded) {
        emit(
          refreshed.copyWith(
            isMutating: false,
            feedbackMessage: 'sellerVerificationRejected',
          ),
        );
      }
    } catch (e) {
      emit(
        current.copyWith(
          isMutating: false,
          feedbackMessage: _formatReviewError(e),
          feedbackIsError: true,
        ),
      );
    }
  }

  String _formatReviewError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      if (status == 404) {
        return 'Seller verification application not found.';
      }
    }
    return error.toString();
  }

  void _onClearFeedback(
    ClearSellerVerificationFeedbackEvent event,
    Emitter<SellerVerificationState> emit,
  ) {
    final current = state;
    if (current is SellerVerificationLoaded) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
