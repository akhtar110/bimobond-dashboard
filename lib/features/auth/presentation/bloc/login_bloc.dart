import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;

  LoginBloc(
      this.loginUseCase,
      this.loginWithGoogleUseCase,
      ) : super(LoginInitial()) {
    on<LoginSubmitted>(_onEmailLogin);
    on<LoginWithGooglePressed>(_onGoogleLogin);
  }

  /// =========================
  /// EMAIL LOGIN
  /// =========================
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

      emit(LoginSuccess(user));
    } catch (e) {
      emit(LoginFailure(_formatError(e)));
    }
  }

  /// =========================
  /// GOOGLE LOGIN
  /// =========================
  Future<void> _onGoogleLogin(
      LoginWithGooglePressed event,
      Emitter<LoginState> emit,
      ) async {
    emit(LoginLoading());

    try {
      final user = await loginWithGoogleUseCase();

      emit(LoginSuccess(user));
    } catch (e) {
      emit(LoginFailure(_formatError(e)));
    }
  }

  /// =========================
  /// CLEAN ERROR HANDLING
  /// =========================
  String _formatError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}