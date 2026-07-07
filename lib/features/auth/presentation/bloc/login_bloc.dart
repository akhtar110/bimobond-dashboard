import 'package:firebase_auth/firebase_auth.dart';
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
  LoginBloc({
    required this.loginUseCase,
    required this.loginWithGoogleUseCase,
    required this.saveSessionUseCase,
    required this.logoutUseCase,
    required FirebaseAuth firebaseAuth,
  })  : _firebaseAuth = firebaseAuth,
        super(LoginInitial()) {
    on<LoginSubmitted>(_onEmailLogin);
    on<LoginWithGooglePressed>(_onGoogleLogin);
    on<LoginGoogleSignInAborted>(_onGoogleSignInAborted);
  }

  static const googleSignInCancelledKey = 'googleSignInCancelled';

  final LoginUseCase loginUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final SaveSessionUseCase saveSessionUseCase;
  final LogoutUseCase logoutUseCase;
  final FirebaseAuth _firebaseAuth;

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
    emit(LoginLoading(isGoogle: true));

    try {
      final user = await loginWithGoogleUseCase();
      await _completeLogin(user, emit);
    } catch (e) {
      await _clearPartialGoogleSession();
      emit(LoginFailure(_formatGoogleError(e)));
    }
  }

  Future<void> _onGoogleSignInAborted(
    LoginGoogleSignInAborted event,
    Emitter<LoginState> emit,
  ) async {
    final current = state;
    if (current is! LoginLoading || !current.isGoogle) return;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (state is! LoginLoading || !(state as LoginLoading).isGoogle) return;
    if (_firebaseAuth.currentUser != null) return;

    await _clearPartialGoogleSession();
    emit(LoginFailure(googleSignInCancelledKey));
  }

  Future<void> _clearPartialGoogleSession() async {
    try {
      await logoutUseCase();
    } catch (_) {
      // Ignore cleanup failures; login error is still shown to the user.
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

  String _formatGoogleError(Object e) {
    if (_isGoogleSignInCancelled(e)) {
      return googleSignInCancelledKey;
    }
    return _formatError(e);
  }

  bool _isGoogleSignInCancelled(Object e) {
    if (e is FirebaseAuthException) {
      return _isGoogleSignInCancelledCode(e.code);
    }

    return _isGoogleSignInCancelledCode(e.toString());
  }

  bool _isGoogleSignInCancelledCode(String value) {
    return value.contains('popup-closed-by-user') ||
        value.contains('popup_closed') ||
        value.contains('cancelled-popup-request');
  }

  String _formatError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
