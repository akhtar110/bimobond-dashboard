import '../../domain/entities/user_entity.dart';

sealed class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final DashboardUserEntity? user;
  AuthUserChanged(this.user);
}

class AuthLogoutRequested extends AuthEvent {}
