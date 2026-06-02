import 'package:bimo_bond_dashboard/features/users/domain/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/ban_user.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/demote_user.dart';
import '../../domain/usecases/get_users.dart';
import '../../domain/usecases/promote_to_admin.dart';
import '../../domain/usecases/unban_user.dart';
import '../users_ui_filter.dart';

sealed class UsersEvent {}

class LoadUsersEvent extends UsersEvent {
  LoadUsersEvent({this.refresh = false, this.page});
  final bool refresh;
  final int? page;
}

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

class DeleteUserEvent extends UsersEvent {
  DeleteUserEvent(this.userId);
  final String userId;
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
  });

  final List<UserEntity> users;
  final int currentPage;
  final int lastPage;
  final int total;
  final UsersUiFilter filter;
  final String query;

  UsersLoaded copyWith({
    List<UserEntity>? users,
    int? currentPage,
    int? lastPage,
    int? total,
    UsersUiFilter? filter,
    String? query,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }
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
    required this.deleteUser,
  }) : super(UsersLoading()) {
    on<LoadUsersEvent>(_onLoad);
    on<GoToUsersPageEvent>(_onGoToPage);
    on<SearchUsersEvent>(_onSearch);
    on<FilterUsersEvent>(_onFilter);
    on<ToggleBanUserEvent>(_onToggleBan);
    on<PromoteUserEvent>(_onPromote);
    on<DemoteUserEvent>(_onDemote);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  final GetUsers getUsers;
  final BanUser banUser;
  final UnbanUser unbanUser;
  final PromoteUser promoteUser;
  final DemoteUser demoteUser;
  final DeleteUser deleteUser;

  static const int _limit = 20;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _busy = false;

  String _query = '';
  UsersUiFilter _filter = UsersUiFilter.all;

  final List<UserEntity> _users = [];

  Future<void> _onLoad(LoadUsersEvent event, Emitter<UsersState> emit) async {
    final page = event.refresh ? 1 : (event.page ?? _currentPage);
    await _fetchPage(emit, page: page);
  }

  Future<void> _onGoToPage(
    GoToUsersPageEvent event,
    Emitter<UsersState> emit,
  ) async {
    await _fetchPage(emit, page: event.page);
  }

  Future<void> _fetchPage(Emitter<UsersState> emit, {required int page}) async {
    if (_busy) return;
    if (page < 1) return;

    _busy = true;
    emit(UsersLoading());

    try {
      final response = await getUsers(
        page: page,
        limit: _limit,
        search: _query,
        isVerified: _filter == UsersUiFilter.verified ? true : null,
        isBanned: _filter == UsersUiFilter.banned ? true : null,
      );

      _users
        ..clear()
        ..addAll(response.users);
      _currentPage = response.page;
      _lastPage = response.lastPage;
      _total = response.total;

      if (_users.isEmpty) {
        emit(UsersEmpty());
      } else {
        emit(
          UsersLoaded(
            users: List.of(_users),
            currentPage: _currentPage,
            lastPage: _lastPage,
            total: _total,
            filter: _filter,
            query: _query,
          ),
        );
      }
    } catch (e) {
      emit(UsersError(e.toString()));
    } finally {
      _busy = false;
    }
  }

  //
  // SEARCH
  //
  void _onSearch(SearchUsersEvent event, Emitter<UsersState> emit) {
    _query = event.query;
    add(LoadUsersEvent(refresh: true));
  }

  //
  // FILTER
  //
  void _onFilter(FilterUsersEvent event, Emitter<UsersState> emit) {
    _filter = event.filter;
    add(LoadUsersEvent(refresh: true));
  }

  //
  // BAN / UNBAN
  //
  Future<void> _onToggleBan(
    ToggleBanUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    final user = _users.firstWhere((u) => u.id == event.userId);

    if (user.isBanned) {
      await unbanUser(event.userId);
    } else {
      await banUser(reason: '', until: DateTime.now(), userId: event.userId);
    }
    add(LoadUsersEvent(page: _currentPage));
  }

  //Delete user

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await deleteUser(event.userId);

      _users.removeWhere((u) => u.id == event.userId);

      if (_users.isEmpty) {
        emit(UsersEmpty());
      } else {
        emit(
          UsersLoaded(
            users: List.of(_users),
            currentPage: _currentPage,
            lastPage: _lastPage,
            total: _total,
            filter: _filter,
            query: _query,
          ),
        );
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
}
