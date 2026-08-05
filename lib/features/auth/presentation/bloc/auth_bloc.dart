import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/navigation_persistence_service.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/utils/admin_access.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.getSession();
      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      if (!isDashboardStaff(user)) {
        await _repository.logout();
        await di.sl<NavigationPersistenceService>().clearLastPage();
        emit(Unauthenticated());
        return;
      }

      emit(Authenticated(user));
    } catch (_) {
      await _repository.logout();
      await di.sl<NavigationPersistenceService>().clearLastPage();
      emit(Unauthenticated());
    }
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      emit(Unauthenticated());
      return;
    }

    if (!isDashboardStaff(user)) {
      await _repository.logout();
      await di.sl<NavigationPersistenceService>().clearLastPage();
      emit(Unauthenticated());
      return;
    }

    emit(Authenticated(user));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _repository.logout();
    await di.sl<NavigationPersistenceService>().clearLastPage();
    emit(Unauthenticated());
  }
}
