import 'package:bimo_bond_dashboard/features/users/domain/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/api_error_messages.dart';
import '../../domain/entities/admin_bulk_users_result_entity.dart';
import '../../domain/usecases/bulk_activate_users.dart';
import '../../domain/usecases/bulk_delete_users.dart';
import '../../domain/usecases/bulk_demote_users.dart';
import '../../domain/usecases/bulk_promote_users.dart';
import '../../domain/usecases/bulk_suspend_users.dart';
import '../../domain/usecases/ban_user.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/demote_user.dart';
import '../../domain/usecases/get_users.dart';
import '../../domain/usecases/promote_to_admin.dart';
import '../../domain/usecases/reset_user_password_usecase.dart';
import '../../domain/usecases/updte_role.dart';
import '../../domain/usecases/unban_user.dart';
import '../users_ui_filter.dart';
import '../users_location_sort.dart';
import '../utils/user_location_list_utils.dart';
import '../utils/users_export_service.dart';

sealed class UsersEvent {}

class LoadUsersEvent extends UsersEvent {
  LoadUsersEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

class LoadMoreUsersEvent extends UsersEvent {}

class GoToUsersPageEvent extends UsersEvent {
  GoToUsersPageEvent(this.page);
  final int page;
}

class SearchUsersEvent extends UsersEvent {
  SearchUsersEvent(this.query);
  final String query;
}

class FilterUsersEvent extends UsersEvent {
  FilterUsersEvent(this.filter);
  final UsersUiFilter filter;
}

/// Applies username/email search, location filter, role, and date range filters together.
class ApplyUsersListFiltersEvent extends UsersEvent {
  ApplyUsersListFiltersEvent({
    required this.search,
    required this.location,
    this.role,
    this.createdFrom,
    this.createdTo,
  });

  final String search;
  final String location;
  final String? role;
  final DateTime? createdFrom;
  final DateTime? createdTo;
}

/// Triggers user list export to Excel or CSV formats.
class ExportUsersEvent extends UsersEvent {
  ExportUsersEvent({
    required this.format,
  });

  final UsersExportFormat format;
}

class ClearUsersExportFeedbackEvent extends UsersEvent {}

class FilterUsersByLocationEvent extends UsersEvent {
  FilterUsersByLocationEvent(this.query);
  final String query;
}

/// Clears search, location, and status filters and reloads the full list.
class ClearUsersListFiltersEvent extends UsersEvent {}

class SortUsersLocationEvent extends UsersEvent {}

class SetUsersLocationSortEvent extends UsersEvent {
  SetUsersLocationSortEvent(this.order);
  final UsersLocationSortOrder order;
}

class ToggleBanUserEvent extends UsersEvent {
  ToggleBanUserEvent(this.userId);
  final String userId;
}

class PromoteUserEvent extends UsersEvent {
  PromoteUserEvent(this.userId);
  final String userId;
}

class DemoteUserEvent extends UsersEvent {
  DemoteUserEvent(this.userId);
  final String userId;
}

class SetUserRoleEvent extends UsersEvent {
  SetUserRoleEvent({required this.userId, required this.role});
  final String userId;
  final UserRole role;
}

class DeleteUserEvent extends UsersEvent {
  DeleteUserEvent(this.userId);
  final String userId;
}

class ToggleUserSelectionEvent extends UsersEvent {
  ToggleUserSelectionEvent(this.userId);
  final String userId;
}

class SelectAllUsersEvent extends UsersEvent {}

class ClearUserSelectionEvent extends UsersEvent {}

class BulkSuspendUsersEvent extends UsersEvent {}

class BulkActivateUsersEvent extends UsersEvent {}

class BulkDeleteUsersEvent extends UsersEvent {}

class BulkPromoteUsersEvent extends UsersEvent {}

class BulkDemoteUsersEvent extends UsersEvent {}

class ClearUsersBulkFeedbackEvent extends UsersEvent {}

class ResetUserPasswordEvent extends UsersEvent {
  ResetUserPasswordEvent({required this.userId, required this.newPassword});

  final String userId;
  final String newPassword;
}

//
// STATES
//
sealed class UsersState {}

class UsersLoading extends UsersState {}

class UsersEmpty extends UsersState {}

class UsersError extends UsersState {
  UsersError(this.message);
  final String message;
}

class UsersLoaded extends UsersState {
  UsersLoaded({
    required this.users,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.filter,
    required this.query,
    this.locationQuery = '',
    this.role,
    this.createdFrom,
    this.createdTo,
    this.locationSort = UsersLocationSortOrder.none,
    this.selectedUserIds = const {},
    this.isBulkActionLoading = false,
    this.bulkActionMessage,
    this.bulkActionIsError = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isExporting = false,
    this.exportMessage,
    this.exportIsError = false,
  });

  final List<UserEntity> users;
  final int currentPage;
  final int lastPage;
  final int total;
  final UsersUiFilter filter;
  final String query;
  final String locationQuery;
  final String? role;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final UsersLocationSortOrder locationSort;
  final Set<String> selectedUserIds;
  final bool isBulkActionLoading;
  final String? bulkActionMessage;
  final bool bulkActionIsError;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isExporting;
  final String? exportMessage;
  final bool exportIsError;

  int get selectedCount => selectedUserIds.length;
  bool get hasSelection => selectedUserIds.isNotEmpty;
  bool get hasReachedMax => currentPage >= lastPage;

  bool allVisibleSelected(List<UserEntity> visibleUsers) {
    if (visibleUsers.isEmpty) return false;
    return visibleUsers.every((u) => selectedUserIds.contains(u.id));
  }

  bool someVisibleSelected(List<UserEntity> visibleUsers) {
    return visibleUsers.any((u) => selectedUserIds.contains(u.id)) &&
        !allVisibleSelected(visibleUsers);
  }

  UsersLoaded copyWith({
    List<UserEntity>? users,
    int? currentPage,
    int? lastPage,
    int? total,
    UsersUiFilter? filter,
    String? query,
    String? locationQuery,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
    UsersLocationSortOrder? locationSort,
    Set<String>? selectedUserIds,
    bool? isBulkActionLoading,
    String? bulkActionMessage,
    bool? bulkActionIsError,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isExporting,
    String? exportMessage,
    bool? exportIsError,
    bool clearBulkActionMessage = false,
    bool clearExportMessage = false,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      locationQuery: locationQuery ?? this.locationQuery,
      role: role ?? this.role,
      createdFrom: createdFrom ?? this.createdFrom,
      createdTo: createdTo ?? this.createdTo,
      locationSort: locationSort ?? this.locationSort,
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
      isBulkActionLoading: isBulkActionLoading ?? this.isBulkActionLoading,
      bulkActionMessage: clearBulkActionMessage
          ? null
          : (bulkActionMessage ?? this.bulkActionMessage),
      bulkActionIsError: bulkActionIsError ?? this.bulkActionIsError,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isExporting: isExporting ?? this.isExporting,
      exportMessage: clearExportMessage
          ? null
          : (exportMessage ?? this.exportMessage),
      exportIsError: exportIsError ?? this.exportIsError,
    );
  }
}

class ResetUserPasswordLoading extends UsersState {}

class ResetUserPasswordSuccess extends UsersState {}

class ResetUserPasswordFailure extends UsersState {
  ResetUserPasswordFailure(this.message);
  final String message;
}

//
// BLOC
//
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({
    required this.getUsers,
    required this.banUser,
    required this.unbanUser,
    required this.promoteUser,
    required this.demoteUser,
    required this.updateUserRoles,
    required this.deleteUser,
    required this.bulkSuspendUsers,
    required this.bulkActivateUsers,
    required this.bulkDeleteUsers,
    required this.bulkPromoteUsers,
    required this.bulkDemoteUsers,
    required this.resetUserPassword,
  }) : super(UsersLoading()) {
    on<LoadUsersEvent>(_onLoad);
    on<LoadMoreUsersEvent>(_onLoadMore);
    on<GoToUsersPageEvent>(_onGoToPage);
    on<SearchUsersEvent>(_onSearch);
    on<ApplyUsersListFiltersEvent>(_onApplyListFilters);
    on<FilterUsersByLocationEvent>(_onLocationFilter);
    on<ClearUsersListFiltersEvent>(_onClearListFilters);
    on<SortUsersLocationEvent>(_onLocationSort);
    on<SetUsersLocationSortEvent>(_onSetLocationSort);
    on<FilterUsersEvent>(_onFilter);
    on<ToggleBanUserEvent>(_onToggleBan);
    on<PromoteUserEvent>(_onPromote);
    on<DemoteUserEvent>(_onDemote);
    on<SetUserRoleEvent>(_onSetUserRole);
    on<DeleteUserEvent>(_onDeleteUser);
    on<ToggleUserSelectionEvent>(_onToggleSelection);
    on<SelectAllUsersEvent>(_onSelectAll);
    on<ClearUserSelectionEvent>(_onClearSelection);
    on<BulkSuspendUsersEvent>(_onBulkSuspend);
    on<BulkActivateUsersEvent>(_onBulkActivate);
    on<BulkDeleteUsersEvent>(_onBulkDelete);
    on<BulkPromoteUsersEvent>(_onBulkPromote);
    on<BulkDemoteUsersEvent>(_onBulkDemote);
    on<ClearUsersBulkFeedbackEvent>(_onClearBulkFeedback);
    on<ResetUserPasswordEvent>(_onResetUserPassword);
    on<ExportUsersEvent>(_onExportUsers);
    on<ClearUsersExportFeedbackEvent>(_onClearExportFeedback);
  }

  final GetUsers getUsers;
  final BanUser banUser;
  final UnbanUser unbanUser;
  final PromoteUser promoteUser;
  final DemoteUser demoteUser;
  final UpdateUserRoles updateUserRoles;
  final DeleteUser deleteUser;
  final BulkSuspendUsers bulkSuspendUsers;
  final BulkActivateUsers bulkActivateUsers;
  final BulkDeleteUsers bulkDeleteUsers;
  final BulkPromoteUsers bulkPromoteUsers;
  final BulkDemoteUsers bulkDemoteUsers;
  final ResetUserPasswordUseCase resetUserPassword;

  static const int pageLimit = 20;
  static const int _limit = pageLimit;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loadMoreBusy = false;
  bool _resetPasswordBusy = false;
  UsersState? _stateBeforeResetPassword;
  int _listFetchGeneration = 0;

  String _query = '';
  String _locationQuery = '';
  String? _role;
  DateTime? _createdFrom;
  DateTime? _createdTo;
  UsersLocationSortOrder _locationSort = UsersLocationSortOrder.none;
  UsersUiFilter _filter = UsersUiFilter.all;

  bool _isExporting = false;
  String? _exportMessage;
  bool _exportIsError = false;

  final List<UserEntity> _users = [];
  final Set<String> _selectedUserIds = {};

  String get activeQuery => _query;
  String get activeLocationQuery => _locationQuery;
  String? get activeRole => _role;
  DateTime? get activeCreatedFrom => _createdFrom;
  DateTime? get activeCreatedTo => _createdTo;
  UsersLocationSortOrder get activeLocationSort => _locationSort;
  UsersUiFilter get activeFilter => _filter;

  String? _pendingBulkMessage;
  bool _pendingBulkIsError = false;

  Future<void> _onLoad(LoadUsersEvent event, Emitter<UsersState> emit) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    await _fetchPage(emit, page: page, replace: true);
  }

  Future<void> _onLoadMore(
    LoadMoreUsersEvent event,
    Emitter<UsersState> emit,
  ) async {
    final current = state;
    if (current is! UsersLoaded) return;
    if (current.hasReachedMax || current.isLoadingMore || _loadMoreBusy) {
      return;
    }
    await _fetchPage(emit, page: _currentPage + 1, replace: false);
  }

  Future<void> _onGoToPage(
    GoToUsersPageEvent event,
    Emitter<UsersState> emit,
  ) async {
    await _fetchPage(emit, page: event.page, replace: true);
  }

  Future<void> _fetchPage(
    Emitter<UsersState> emit, {
    required int page,
    required bool replace,
  }) async {
    if (page < 1) return;

    if (replace) {
      final generation = ++_listFetchGeneration;
      final prior = state;
      if (prior is UsersLoaded) {
        emit(prior.copyWith(isRefreshing: true));
      } else {
        emit(UsersLoading());
      }

      try {
        final response = await getUsers(
          page: page,
          limit: _limit,
          search: _query,
          location: _locationQuery.isEmpty ? null : _locationQuery,
          isVerified: _filter == UsersUiFilter.verified ? true : null,
          isBanned: _filter == UsersUiFilter.banned ? true : null,
          // online/offline are client-side only; no backend param needed
          role: _role,
          createdFrom: _createdFrom,
          createdTo: _createdTo,
        );

        if (generation != _listFetchGeneration) return;

        _users
          ..clear()
          ..addAll(response.users);
        _currentPage = response.page;
        _lastPage = response.lastPage;
        _total = response.total;
        _applyLocationSort();

        if (_users.isEmpty) {
          emit(UsersEmpty());
        } else {
          _emitLoaded(emit, isLoadingMore: false, isRefreshing: false);
        }
      } catch (e) {
        if (generation != _listFetchGeneration) return;
        emit(UsersError(e.toString()));
      }
      return;
    }

    if (_loadMoreBusy) return;
    _loadMoreBusy = true;
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(isLoadingMore: true));
    }

    try {
      final response = await getUsers(
        page: page,
        limit: _limit,
        search: _query,
        location: _locationQuery.isEmpty ? null : _locationQuery,
        isVerified: _filter == UsersUiFilter.verified ? true : null,
        isBanned: _filter == UsersUiFilter.banned ? true : null,
        // online/offline are client-side only; no backend param needed
        role: _role,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
      );

      final existingIds = _users.map((u) => u.id).toSet();
      for (final user in response.users) {
        if (!existingIds.contains(user.id)) {
          _users.add(user);
        }
      }
      _currentPage = response.page;
      _lastPage = response.lastPage;
      _total = response.total;
      _applyLocationSort();

      if (_users.isEmpty) {
        emit(UsersEmpty());
      } else {
        _emitLoaded(emit, isLoadingMore: false);
      }
    } catch (e) {
      final current = state;
      if (current is UsersLoaded) {
        emit(current.copyWith(isLoadingMore: false));
      }
    } finally {
      _loadMoreBusy = false;
    }
  }

  void _emitLoaded(
    Emitter<UsersState> emit, {
    List<UserEntity>? users,
    bool? isBulkActionLoading,
    String? bulkActionMessage,
    bool? bulkActionIsError,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isExporting,
    String? exportMessage,
    bool? exportIsError,
    bool clearBulkActionMessage = false,
    bool clearExportMessage = false,
  }) {
    var list = users ?? _users;
    // Apply client-side online / offline filter
    if (_filter == UsersUiFilter.online) {
      list = list.where((u) => u.isOnline).toList();
    } else if (_filter == UsersUiFilter.offline) {
      list = list.where((u) => !u.isOnline).toList();
    }
    if (list.isEmpty) {
      emit(UsersEmpty());
      return;
    }

    emit(
      UsersLoaded(
        users: List.of(list),
        currentPage: _currentPage,
        lastPage: _lastPage,
        total: _total,
        filter: _filter,
        query: _query,
        locationQuery: _locationQuery,
        role: _role,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
        locationSort: _locationSort,
        selectedUserIds: Set.of(_selectedUserIds),
        isBulkActionLoading: isBulkActionLoading ?? false,
        bulkActionMessage: clearBulkActionMessage
            ? null
            : (bulkActionMessage ?? _pendingBulkMessage),
        bulkActionIsError: bulkActionIsError ?? _pendingBulkIsError,
        isLoadingMore: isLoadingMore ?? false,
        isRefreshing: isRefreshing ?? false,
        isExporting: isExporting ?? _isExporting,
        exportMessage: clearExportMessage
            ? null
            : (exportMessage ?? _exportMessage),
        exportIsError: exportIsError ?? _exportIsError,
      ),
    );

    _pendingBulkMessage = null;
    _pendingBulkIsError = false;
    _exportMessage = null;
    _exportIsError = false;
  }

  void _onSearch(SearchUsersEvent event, Emitter<UsersState> emit) {
    _applyListFilters(
      search: event.query.trim(),
      location: _locationQuery,
      role: _role,
      createdFrom: _createdFrom,
      createdTo: _createdTo,
      emit: emit,
    );
  }

  void _onApplyListFilters(
    ApplyUsersListFiltersEvent event,
    Emitter<UsersState> emit,
  ) {
    _applyListFilters(
      search: event.search.trim(),
      location: event.location.trim(),
      role: event.role,
      createdFrom: event.createdFrom,
      createdTo: event.createdTo,
      emit: emit,
    );
  }

  void _applyListFilters({
    required String search,
    required String location,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
    required Emitter<UsersState> emit,
  }) {
    if (search == _query &&
        location == _locationQuery &&
        role == _role &&
        createdFrom == _createdFrom &&
        createdTo == _createdTo) {
      return;
    }
    _query = search;
    _locationQuery = location;
    _role = role;
    _createdFrom = createdFrom;
    _createdTo = createdTo;
    add(LoadUsersEvent(refresh: true));
  }

  void _onLocationFilter(
    FilterUsersByLocationEvent event,
    Emitter<UsersState> emit,
  ) {
    _applyListFilters(
      search: _query,
      location: event.query.trim(),
      role: _role,
      createdFrom: _createdFrom,
      createdTo: _createdTo,
      emit: emit,
    );
  }

  void _onClearListFilters(
    ClearUsersListFiltersEvent event,
    Emitter<UsersState> emit,
  ) {
    final hadFilters = _query.isNotEmpty ||
        _locationQuery.isNotEmpty ||
        _role != null ||
        _createdFrom != null ||
        _createdTo != null ||
        _filter != UsersUiFilter.all ||
        _locationSort != UsersLocationSortOrder.none;

    if (!hadFilters) return;

    _query = '';
    _locationQuery = '';
    _role = null;
    _createdFrom = null;
    _createdTo = null;
    _filter = UsersUiFilter.all;
    _locationSort = UsersLocationSortOrder.none;

    if (_selectedUserIds.isNotEmpty) {
      _selectedUserIds.clear();
    }

    add(LoadUsersEvent(refresh: true));
  }

  Future<void> _onExportUsers(
    ExportUsersEvent event,
    Emitter<UsersState> emit,
  ) async {
    final current = state;
    if (current is! UsersLoaded || _isExporting) return;

    _isExporting = true;
    _emitLoaded(emit, isExporting: true, clearExportMessage: true);

    try {
      final allUsers = <UserEntity>[];
      final seenIds = <String>{};
      int page = 1;
      int lastPage = 1;

      do {
        final res = await getUsers(
          page: page,
          limit: 100, // fetch in larger chunks for export efficiency
          search: _query,
          location: _locationQuery.isEmpty ? null : _locationQuery,
          isVerified: _filter == UsersUiFilter.verified ? true : null,
          isBanned: _filter == UsersUiFilter.banned ? true : null,
          role: _role,
          createdFrom: _createdFrom,
          createdTo: _createdTo,
        );

        for (final user in res.users) {
          if (seenIds.add(user.id)) {
            allUsers.add(user);
          }
        }
        lastPage = res.lastPage < 1 ? 1 : res.lastPage;
        page++;
      } while (page <= lastPage && page <= 50); // safety cap: max 50 pages (5,000 users)

      final exportList = allUsers.isNotEmpty ? allUsers : _users;

      final params = UsersExportParams(
        users: exportList,
        filter: _filter,
        searchQuery: _query,
        locationQuery: _locationQuery,
        role: _role,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
      );

      await UsersExportService.exportUsers(
        params: params,
        format: event.format,
      );

      _isExporting = false;
      _exportMessage =
          'Export generated successfully (${exportList.length} users)';
      _exportIsError = false;
      _emitLoaded(emit, isExporting: false);
    } catch (e) {
      _isExporting = false;
      _exportMessage =
          'Export failed: ${e.toString().replaceFirst('Exception: ', '')}';
      _exportIsError = true;
      _emitLoaded(emit, isExporting: false);
    }
  }

  void _onClearExportFeedback(
    ClearUsersExportFeedbackEvent event,
    Emitter<UsersState> emit,
  ) {
    final current = state;
    if (current is UsersLoaded && current.exportMessage != null) {
      emit(current.copyWith(clearExportMessage: true));
    }
  }

  void _onLocationSort(SortUsersLocationEvent event, Emitter<UsersState> emit) {
    _setLocationSort(_locationSort.next, emit);
  }

  void _onSetLocationSort(
    SetUsersLocationSortEvent event,
    Emitter<UsersState> emit,
  ) {
    if (_locationSort == event.order) return;
    _setLocationSort(event.order, emit);
  }

  void _setLocationSort(
    UsersLocationSortOrder order,
    Emitter<UsersState> emit,
  ) {
    _locationSort = order;
    if (_locationSort == UsersLocationSortOrder.none) {
      add(LoadUsersEvent(refresh: true));
      return;
    }
    _applyLocationSort();
    if (state is UsersLoaded) {
      _emitLoaded(emit);
    }
  }

  void _applyLocationSort() {
    if (_locationSort == UsersLocationSortOrder.none) return;

    int compare(UserEntity a, UserEntity b) {
      final ka = userLocationSortKey(a);
      final kb = userLocationSortKey(b);
      final aEmpty = ka.isEmpty;
      final bEmpty = kb.isEmpty;
      if (aEmpty && bEmpty) return 0;
      if (aEmpty) return 1;
      if (bEmpty) return -1;
      return ka.compareTo(kb);
    }

    _users.sort((a, b) {
      final result = compare(a, b);
      return _locationSort == UsersLocationSortOrder.descending
          ? -result
          : result;
    });
  }

  void _onFilter(FilterUsersEvent event, Emitter<UsersState> emit) {
    _filter = event.filter;
    if (_selectedUserIds.isNotEmpty) {
      _selectedUserIds.clear();
      if (state is UsersLoaded) {
        _emitLoaded(emit, clearBulkActionMessage: true);
      }
    }
    add(LoadUsersEvent(refresh: true));
  }

  void _onToggleSelection(
    ToggleUserSelectionEvent event,
    Emitter<UsersState> emit,
  ) {
    if (_selectedUserIds.contains(event.userId)) {
      _selectedUserIds.remove(event.userId);
    } else {
      _selectedUserIds.add(event.userId);
    }
    if (state is UsersLoaded) {
      _emitLoaded(emit, clearBulkActionMessage: true);
    }
  }

  void _onSelectAll(SelectAllUsersEvent event, Emitter<UsersState> emit) {
    if (state is! UsersLoaded) return;
    final visibleIds = _users.map((u) => u.id).toSet();
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedUserIds.contains);
    if (allSelected) {
      _selectedUserIds.removeAll(visibleIds);
    } else {
      _selectedUserIds.addAll(visibleIds);
    }
    _emitLoaded(emit, clearBulkActionMessage: true);
  }

  void _onClearSelection(
    ClearUserSelectionEvent event,
    Emitter<UsersState> emit,
  ) {
    if (_selectedUserIds.isEmpty) return;
    _selectedUserIds.clear();
    if (state is UsersLoaded) {
      _emitLoaded(emit, clearBulkActionMessage: true);
    }
  }

  void _onClearBulkFeedback(
    ClearUsersBulkFeedbackEvent event,
    Emitter<UsersState> emit,
  ) {
    final current = state;
    if (current is UsersLoaded && current.bulkActionMessage != null) {
      emit(current.copyWith(clearBulkActionMessage: true));
    }
  }

  Future<void> _runBulkAction(
    Emitter<UsersState> emit, {
    required Future<AdminBulkUsersResultEntity> Function(List<String> ids)
    action,
    required String actionLabel,
  }) async {
    if (_selectedUserIds.isEmpty || state is! UsersLoaded) return;

    final ids = _selectedUserIds.toList(growable: false);
    _emitLoaded(emit, isBulkActionLoading: true, clearBulkActionMessage: true);

    try {
      final result = await action(ids);
      _pendingBulkMessage = result.messageFor(actionLabel);
      _pendingBulkIsError = result.isTotalFailure;
      _selectedUserIds.clear();
      await _fetchPage(emit, page: _currentPage, replace: true);
    } catch (e) {
      _emitLoaded(
        emit,
        isBulkActionLoading: false,
        bulkActionMessage: e.toString().replaceFirst('Exception: ', ''),
        bulkActionIsError: true,
      );
    }
  }

  Future<void> _onBulkSuspend(
    BulkSuspendUsersEvent event,
    Emitter<UsersState> emit,
  ) {
    return _runBulkAction(
      emit,
      action: (ids) => bulkSuspendUsers(
        ids,
        reason: 'Bulk admin action',
        until: DateTime.now().add(const Duration(days: 3650)),
      ),
      actionLabel: 'Ban',
    );
  }

  Future<void> _onBulkActivate(
    BulkActivateUsersEvent event,
    Emitter<UsersState> emit,
  ) {
    return _runBulkAction(
      emit,
      action: (ids) => bulkActivateUsers(ids),
      actionLabel: 'Unban',
    );
  }

  Future<void> _onBulkDelete(
    BulkDeleteUsersEvent event,
    Emitter<UsersState> emit,
  ) {
    return _runBulkAction(
      emit,
      action: (ids) => bulkDeleteUsers(ids),
      actionLabel: 'Delete',
    );
  }

  Future<void> _onBulkPromote(
    BulkPromoteUsersEvent event,
    Emitter<UsersState> emit,
  ) {
    return _runBulkAction(
      emit,
      action: (ids) => bulkPromoteUsers(ids),
      actionLabel: 'Promote',
    );
  }

  Future<void> _onBulkDemote(
    BulkDemoteUsersEvent event,
    Emitter<UsersState> emit,
  ) {
    return _runBulkAction(
      emit,
      action: (ids) => bulkDemoteUsers(ids),
      actionLabel: 'Demote',
    );
  }

  Future<void> _onToggleBan(
    ToggleBanUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    final user = _users.firstWhere((u) => u.id == event.userId);

    if (user.isBanned) {
      await unbanUser(event.userId);
    } else {
      await banUser(userId: event.userId, reason: 'Banned by admin');
    }
    add(LoadUsersEvent(page: _currentPage));
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await deleteUser(event.userId);
      _selectedUserIds.remove(event.userId);
      _users.removeWhere((u) => u.id == event.userId);

      if (_users.isEmpty) {
        emit(UsersEmpty());
      } else {
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onPromote(
    PromoteUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    await promoteUser(event.userId);
    add(LoadUsersEvent(page: _currentPage));
  }

  Future<void> _onDemote(
    DemoteUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    await demoteUser(event.userId);
    add(LoadUsersEvent(page: _currentPage));
  }

  Future<void> _onSetUserRole(
    SetUserRoleEvent event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await updateUserRoles(userId: event.userId, roles: [event.role]);
      add(LoadUsersEvent(page: _currentPage));
    } catch (e) {
      if (state is UsersLoaded) {
        _emitLoaded(
          emit,
          bulkActionMessage: e.toString().replaceFirst('Exception: ', ''),
          bulkActionIsError: true,
        );
      } else {
        emit(UsersError(e.toString()));
      }
    }
  }

  Future<void> _onResetUserPassword(
    ResetUserPasswordEvent event,
    Emitter<UsersState> emit,
  ) async {
    if (_resetPasswordBusy) return;

    _resetPasswordBusy = true;
    final previous = state;
    if (previous is UsersLoaded) {
      _stateBeforeResetPassword = previous;
    }

    emit(ResetUserPasswordLoading());

    try {
      await resetUserPassword(
        ResetUserPasswordParams(
          userId: event.userId,
          newPassword: event.newPassword,
        ),
      );
      emit(ResetUserPasswordSuccess());
    } catch (e) {
      emit(ResetUserPasswordFailure(ApiErrorMessages.from(e)));
    } finally {
      _resetPasswordBusy = false;
      _restoreStateAfterResetPassword(emit);
    }
  }

  void _restoreStateAfterResetPassword(Emitter<UsersState> emit) {
    final previous = _stateBeforeResetPassword;
    _stateBeforeResetPassword = null;

    if (previous is UsersLoaded) {
      _emitLoaded(emit);
      return;
    }

    if (_users.isNotEmpty) {
      _emitLoaded(emit);
    } else if (_users.isEmpty && previous is UsersEmpty) {
      emit(UsersEmpty());
    }
  }
}
