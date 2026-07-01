import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/save_session_usecase.dart';
import '../../domain/utils/admin_access.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final SaveSessionUseCase saveSessionUseCase;
  final LogoutUseCase logoutUseCase;

  LoginBloc({
    required this.loginUseCase,
    required this.loginWithGoogleUseCase,
    required this.saveSessionUseCase,
    required this.logoutUseCase,
  }) : super(LoginInitial()) {
    on<LoginSubmitted>(_onEmailLogin);
    on<LoginWithGooglePressed>(_onGoogleLogin);
  }

  Future<void> _onEmailLogin(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final user = await loginUseCase(
        email: event.email,
        password: event.password,
      );

      await _completeLogin(user, emit);
    } catch (e) {
      emit(LoginFailure(_formatError(e)));
    }
  }

  Future<void> _onGoogleLogin(
    LoginWithGooglePressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final user = await loginWithGoogleUseCase();
      await _completeLogin(user, emit);
    } catch (e) {
      emit(LoginFailure(_formatError(e)));
    }
  }

  Future<void> _completeLogin(
    DashboardUserEntity user,
    Emitter<LoginState> emit,
  ) async {
    if (!isDashboardAdmin(user)) {
      await logoutUseCase();
      emit(LoginAccessDenied());
      return;
    }

    await saveSessionUseCase(user);
    emit(LoginSuccess(user));
  }

  String _formatError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
