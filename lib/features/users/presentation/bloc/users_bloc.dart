import 'dart:async';

import 'package:bimo_bond_dashboard/features/users/domain/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/navigation_persistence_service.dart';
import '../../../../core/utils/api_error_messages.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/users_presence_socket_service.dart';
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

class StartUsersRealtimePresenceListening extends UsersEvent {}

class StopUsersRealtimePresenceListening extends UsersEvent {}

class UserPresenceChangedEvent extends UsersEvent {
  UserPresenceChangedEvent(this.update);
  final UserPresenceChange update;
}

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

/// Applies search, location, role, date range, account status, and presence status filters together.
class ApplyUsersListFiltersEvent extends UsersEvent {
  ApplyUsersListFiltersEvent({
    required this.search,
    required this.location,
    this.role,
    this.createdFrom,
    this.createdTo,
    this.statusFilter,
    this.presenceFilter,
  });

  final String search;
  final String location;
  final String? role;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final UsersUiFilter? statusFilter;
  final UsersPresenceFilter? presenceFilter;
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

class ToggleOnlineCardFilterEvent extends UsersEvent {}
class ToggleVerifiedCardFilterEvent extends UsersEvent {}
class ToggleBannedCardFilterEvent extends UsersEvent {}

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
    this.onlineCount = 0,
    this.verifiedCount = 0,
    this.bannedCount = 0,
    this.isCardOnlineSelected = false,
    this.isCardVerifiedSelected = false,
    this.isCardBannedSelected = false,
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
  /// Live count of currently online users (from backend + WS updates).
  final int onlineCount;
  final int verifiedCount;
  final int bannedCount;
  final bool isCardOnlineSelected;
  final bool isCardVerifiedSelected;
  final bool isCardBannedSelected;

  bool get isCardTotalSelected =>
      !isCardOnlineSelected &&
      !isCardVerifiedSelected &&
      !isCardBannedSelected &&
      filter == UsersUiFilter.all;

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
    int? onlineCount,
    int? verifiedCount,
    int? bannedCount,
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
      onlineCount: onlineCount ?? this.onlineCount,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      bannedCount: bannedCount ?? this.bannedCount,
      isCardOnlineSelected: isCardOnlineSelected,
      isCardVerifiedSelected: isCardVerifiedSelected,
      isCardBannedSelected: isCardBannedSelected,
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
    UsersPresenceSocketService? presenceSocketService,
  })  : _presenceSocketService = presenceSocketService ?? UsersPresenceSocketService(),
        super(UsersLoading()) {
    on<LoadUsersEvent>(_onLoad);
    on<LoadMoreUsersEvent>(_onLoadMore);
    on<GoToUsersPageEvent>(_onGoToPage);
    on<SearchUsersEvent>(_onSearch);
    on<ApplyUsersListFiltersEvent>(_onApplyListFilters);
    on<FilterUsersByLocationEvent>(_onLocationFilter);
    on<ClearUsersListFiltersEvent>(_onClearListFilters);
    on<ToggleOnlineCardFilterEvent>(_onToggleOnlineCardFilter);
    on<ToggleVerifiedCardFilterEvent>(_onToggleVerifiedCardFilter);
    on<ToggleBannedCardFilterEvent>(_onToggleBannedCardFilter);
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
    on<StartUsersRealtimePresenceListening>(_onStartPresenceListening);
    on<StopUsersRealtimePresenceListening>(_onStopPresenceListening);
    on<UserPresenceChangedEvent>(_onUserPresenceChanged);

    _initPresenceSocketSubscription();
  }

  final UsersPresenceSocketService _presenceSocketService;
  StreamSubscription<UserPresenceChange>? _presenceSubscription;

  void _initPresenceSocketSubscription() {
    _presenceSubscription =
        _presenceSocketService.onUserPresenceChanged.listen((update) {
      if (!isClosed) {
        add(UserPresenceChangedEvent(update));
      }
    });
  }

  void _onStartPresenceListening(
    StartUsersRealtimePresenceListening event,
    Emitter<UsersState> emit,
  ) {
    _presenceSocketService.connect();
  }

  void _onStopPresenceListening(
    StopUsersRealtimePresenceListening event,
    Emitter<UsersState> emit,
  ) {
    _presenceSocketService.disconnect();
  }

  void _onUserPresenceChanged(
    UserPresenceChangedEvent event,
    Emitter<UsersState> emit,
  ) {
    final update = event.update;
    final index = _users.indexWhere((u) => u.id == update.userId);

    if (index != -1) {
      final oldUser = _users[index];
      final updatedUser = oldUser.copyWith(
        isOnlineOverride: update.isOnline,
        lastActive: update.lastSeenAt ??
            (update.isOnline ? DateTime.now() : oldUser.lastActive),
      );
      _users[index] = updatedUser;
    }

    if (update.isOnline) {
      if (_onlineUserIds.add(update.userId)) {
        _onlineCount = (_onlineCount + 1).clamp(0, 9999999);
      }
    } else {
      if (_onlineUserIds.remove(update.userId)) {
        _onlineCount = (_onlineCount - 1).clamp(0, 9999999);
      }
    }

    _emitLoaded(emit);
  }

  @override
  Future<void> close() {
    _presenceSubscription?.cancel();
    _presenceSocketService.dispose();
    return super.close();
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
  int _onlineCount = 0;
  int _verifiedCount = 0;
  int _bannedCount = 0;
  final Set<String> _onlineUserIds = {};
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
  UsersPresenceFilter _presenceFilter = UsersPresenceFilter.all;
  bool _cardOnlineFilter = false;
  bool _cardVerifiedFilter = false;
  bool _cardBannedFilter = false;

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

  void _persistCurrentFilters() {
    try {
      di.sl<NavigationPersistenceService>().saveUsersFilters({
        'query': _query,
        'locationQuery': _locationQuery,
        'role': _role,
        'statusFilter': _filter.name,
        'presenceFilter': _presenceFilter.name,
        'locationSort': _locationSort.name,
        'page': _currentPage,
      });
    } catch (_) {}
  }

  Future<void> _onLoad(LoadUsersEvent event, Emitter<UsersState> emit) async {
    if (event.refresh && event.page == null) {
      try {
        final savedFilters = di.sl<NavigationPersistenceService>().getUsersFilters();
        if (savedFilters != null) {
          _query = (savedFilters['query'] as String?) ?? _query;
          _locationQuery = (savedFilters['locationQuery'] as String?) ?? _locationQuery;
          _role = savedFilters['role'] as String?;
          if (savedFilters['statusFilter'] != null) {
            _filter = UsersUiFilter.values.firstWhere(
              (e) => e.name == savedFilters['statusFilter'],
              orElse: () => UsersUiFilter.all,
            );
          }
          if (savedFilters['presenceFilter'] != null) {
            _presenceFilter = UsersPresenceFilter.values.firstWhere(
              (e) => e.name == savedFilters['presenceFilter'],
              orElse: () => UsersPresenceFilter.all,
            );
          }
          if (savedFilters['locationSort'] != null) {
            _locationSort = UsersLocationSortOrder.values.firstWhere(
              (e) => e.name == savedFilters['locationSort'],
              orElse: () => UsersLocationSortOrder.none,
            );
          }
          _currentPage = (savedFilters['page'] as int?) ?? 1;
        }
      } catch (_) {}
    }
    final page = event.page ?? _currentPage;
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
        final effectiveIsOnline = _cardOnlineFilter
            ? true
            : (_presenceFilter == UsersPresenceFilter.online
                ? true
                : (_presenceFilter == UsersPresenceFilter.offline
                    ? false
                    : (_filter == UsersUiFilter.online
                        ? true
                        : (_filter == UsersUiFilter.offline ? false : null))));

        final effectiveIsVerified = _cardVerifiedFilter
            ? true
            : (_filter == UsersUiFilter.verified ? true : null);

        final effectiveIsBanned = _cardBannedFilter
            ? true
            : (_filter == UsersUiFilter.banned ? true : null);

        final response = await getUsers(
          page: page,
          limit: _limit,
          search: _query,
          location: _locationQuery.isEmpty ? null : _locationQuery,
          isVerified: effectiveIsVerified,
          isBanned: effectiveIsBanned,
          isOnline: effectiveIsOnline,
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
        _onlineCount = response.onlineCount;
        _verifiedCount = response.verifiedCount;
        _bannedCount = response.bannedCount;
        _onlineUserIds
          ..clear()
          ..addAll(
            response.users.where((u) => u.isOnline).map((u) => u.id),
          );
        _applyLocationSort();

        if (_users.isEmpty) {
          emit(UsersEmpty());
        } else {
          _emitLoaded(emit, isLoadingMore: false, isRefreshing: false);
          // Start real-time presence subscription after first page loads.
          add(StartUsersRealtimePresenceListening());
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
        add(StartUsersRealtimePresenceListening());
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

    // 1. Account status filter (Verified / Banned)
    if (_cardVerifiedFilter || _filter == UsersUiFilter.verified) {
      list = list.where((u) => u.isVerified).toList();
    }
    if (_cardBannedFilter || _filter == UsersUiFilter.banned) {
      list = list.where((u) => u.isBanned).toList();
    }

    // 2. Presence status filter (Online / Offline)
    final effectivePresence = _presenceFilter != UsersPresenceFilter.all
        ? _presenceFilter
        : (_filter == UsersUiFilter.online
            ? UsersPresenceFilter.online
            : (_filter == UsersUiFilter.offline
                ? UsersPresenceFilter.offline
                : UsersPresenceFilter.all));

    if (_cardOnlineFilter || effectivePresence == UsersPresenceFilter.online) {
      list = list.where((u) => u.isOnline).toList();
    } else if (effectivePresence == UsersPresenceFilter.offline) {
      list = list.where((u) => !u.isOnline).toList();
    }

    // 3. User Role filter
    if (_role != null && _role!.isNotEmpty) {
      final roleLower = _role!.toLowerCase();
      list = list.where((u) {
        if (roleLower == 'user') {
          return !u.roles.includesStaff;
        } else if (roleLower == 'admin') {
          return u.roles.includesAdmin;
        } else if (roleLower == 'moderator') {
          return u.roles.includesModerator;
        } else if (roleLower == 'superadmin') {
          return u.roles.any((r) => r == UserRole.superAdmin);
        }
        return u.roles.any((r) => r.name.toLowerCase() == roleLower);
      }).toList();
    }

    // 4. Location filter (City, Region, Country)
    if (_locationQuery.trim().isNotEmpty) {
      final locLower = _locationQuery.trim().toLowerCase();
      list = list.where((u) {
        final city = (u.city ?? '').toLowerCase();
        final region = (u.region ?? '').toLowerCase();
        final country = (u.country ?? '').toLowerCase();
        return city.contains(locLower) ||
            region.contains(locLower) ||
            country.contains(locLower);
      }).toList();
    }

    // 5. Registration Date bounds (Full-day inclusive: 00:00:00 to 23:59:59)
    if (_createdFrom != null) {
      final startOfDay = DateTime(
        _createdFrom!.year,
        _createdFrom!.month,
        _createdFrom!.day,
        0,
        0,
        0,
      );
      list = list
          .where((u) =>
              u.createdAt != null &&
              (u.createdAt!.isAfter(startOfDay) ||
                  u.createdAt!.isAtSameMomentAs(startOfDay)))
          .toList();
    }
    if (_createdTo != null) {
      final endOfDay = DateTime(
        _createdTo!.year,
        _createdTo!.month,
        _createdTo!.day,
        23,
        59,
        59,
        999,
      );
      list = list
          .where((u) =>
              u.createdAt != null &&
              (u.createdAt!.isBefore(endOfDay) ||
                  u.createdAt!.isAtSameMomentAs(endOfDay)))
          .toList();
    }

    if (list.isEmpty) {
      emit(UsersEmpty());
      return;
    }

    _persistCurrentFilters();

    emit(
      UsersLoaded(
        users: List.of(list),
        currentPage: _currentPage,
        lastPage: _lastPage,
        total: _total,
        onlineCount: _onlineCount,
        verifiedCount: _verifiedCount,
        bannedCount: _bannedCount,
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
        isCardOnlineSelected: _cardOnlineFilter,
        isCardVerifiedSelected: _cardVerifiedFilter,
        isCardBannedSelected: _cardBannedFilter,
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
    if (event.statusFilter != null) {
      _filter = event.statusFilter!;
    }
    if (event.presenceFilter != null) {
      _presenceFilter = event.presenceFilter!;
    }
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

  Future<void> _onToggleOnlineCardFilter(
    ToggleOnlineCardFilterEvent event,
    Emitter<UsersState> emit,
  ) async {
    _cardOnlineFilter = !_cardOnlineFilter;
    await _fetchPage(emit, page: 1, replace: true);
  }

  Future<void> _onToggleVerifiedCardFilter(
    ToggleVerifiedCardFilterEvent event,
    Emitter<UsersState> emit,
  ) async {
    _cardVerifiedFilter = !_cardVerifiedFilter;
    await _fetchPage(emit, page: 1, replace: true);
  }

  Future<void> _onToggleBannedCardFilter(
    ToggleBannedCardFilterEvent event,
    Emitter<UsersState> emit,
  ) async {
    _cardBannedFilter = !_cardBannedFilter;
    await _fetchPage(emit, page: 1, replace: true);
  }

  void _onClearListFilters(
    ClearUsersListFiltersEvent event,
    Emitter<UsersState> emit,
  ) {
    _query = '';
    _locationQuery = '';
    _role = null;
    _createdFrom = null;
    _createdTo = null;
    _filter = UsersUiFilter.all;
    _presenceFilter = UsersPresenceFilter.all;
    _cardOnlineFilter = false;
    _cardVerifiedFilter = false;
    _cardBannedFilter = false;
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
